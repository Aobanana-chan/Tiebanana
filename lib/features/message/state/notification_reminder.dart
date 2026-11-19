import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/features/message/state/notify_entry.dart';

/// 提醒区被隐藏前的可见性，供 SnackBar 撤销。
class ReminderVisibilitySnapshot {
  const ReminderVisibilitySnapshot({
    required this.mutual,
    required this.broadcast,
  });

  final bool mutual;
  final bool broadcast;
}

/// 吧友互助与吧广播的提醒状态。
///
/// 数据边界：
/// - 互助未读 / 时间 / 可见标记来自本地（由 IM 写入，见协议文档 §3.2）；
/// - 广播红点 / 摘要 / 时间来自合并会话，没有 IM 时为空；
/// - 通知行的显示与隐藏只是本机 UI 偏好，不清未读、不改开关。
///
/// 展示层统一读 [entries]：每一行都由数据生成，不再区分「专用卡」。
class NotificationReminder extends ChangeNotifier {
  NotificationReminder._();

  static final NotificationReminder instance = NotificationReminder._();

  static const String mutualVisibleKey = 'msg_reminder_mutual_visible';
  static const String broadcastVisibleKey = 'msg_reminder_broadcast_visible';
  static const String mutualSeenKey = 'msg_tab_entrance_invitation_answer';
  static const String mutualUnreadKey =
      'msg_tab_entrance_invitation_answer_unread_num';
  static const String mutualLatestKey =
      'msg_tab_invitation_answer_latest_msg_time';
  static const String mutualMaskKey = 'mutual_help_switch';
  static const String mutualReadAtKey = 'msg_mutual_read_at';
  static const String mutualReadUnreadKey = 'msg_mutual_read_unread';
  static const String broadcastReadAtKey = 'msg_broadcast_read_at';
  static const String broadcastUnreadKey = 'msg_broadcast_unread';
  static const String broadcastTimeKey = 'msg_broadcast_time';
  static const String broadcastTitleKey = 'msg_broadcast_title';
  static const String broadcastSummaryKey = 'msg_broadcast_summary';

  TiebaMutualHelpNotice _mutual = TiebaMutualHelpNotice.empty;
  TiebaBroadcastNotice _broadcast = TiebaBroadcastNotice.empty;
  DateTime? _mutualReadAt;
  int _mutualReadUnread = 0;
  DateTime? _broadcastReadAt;
  bool _systemNotificationsEnabled = true;
  bool _mutualVisible = true;
  bool _broadcastVisible = true;
  bool _maskedBusy = false;
  bool _loggedIn = false;
  bool _loaded = false;
  String? _uid;

  bool get loaded => _loaded;
  bool get loggedIn => _loggedIn;
  bool get maskedBusy => _maskedBusy;

  TiebaMutualHelpNotice get mutual => _mutual;
  TiebaBroadcastNotice get broadcast => _broadcast;

  bool get hasMutualHelp => _mutual.visible;
  bool get masked => _mutual.masked;
  bool get mutualVisible => _mutualVisible;
  bool get broadcastVisible => _broadcastVisible;

  /// 互助未读；已屏蔽时不计入消息总数。
  int get mutualUnread => masked ? 0 : _mutual.unread;

  /// 互助原始未读（已屏蔽时仍可能非 0，只用于状态文案）。
  int get mutualUnreadRaw => _mutual.unread;

  bool get broadcastDot => _broadcast.unread && _systemNotificationsEnabled;

  /// 广播入口在登录后始终保留，即使没有 IM 数据。
  bool get hasBroadcastEntry => _loggedIn;

  // ── 通知行 ────────────────────────────────────────────────────────────────

  /// 当前可用的所有行，不按本机可见性过滤。
  ///
  /// 顺序固定为「互助 → 广播」：这两类数据来自不同链路，按时间混排会让行
  /// 在刷新时来回跳。以后接入系统会话时再按「未读优先、时间倒序」统一排序。
  List<NotifyEntry> get entries {
    final List<NotifyEntry> list = <NotifyEntry>[];
    if (hasMutualHelp) {
      list.add(
        NotifyEntry(
          kind: NotifyEntryKind.mutualHelp,
          title: '吧友互助',
          summary: _mutualSummary,
          time: _mutual.latestTime,
          badge: !masked && _mutual.unread > 0
              ? NotifyBadgeKind.count
              : NotifyBadgeKind.none,
          count: _mutual.unread,
          muted: masked,
        ),
      );
    }
    if (hasBroadcastEntry) {
      list.add(
        NotifyEntry(
          kind: NotifyEntryKind.broadcast,
          title: '吧广播',
          summary: _broadcastSummary,
          time: _broadcast.latestTime,
          badge: broadcastDot ? NotifyBadgeKind.dot : NotifyBadgeKind.none,
          muted: !_broadcast.hasData,
        ),
      );
    }
    return list;
  }

  List<NotifyEntry> get visibleEntries => entries
      .where((NotifyEntry entry) => isEntryVisible(entry.kind))
      .toList(growable: false);

  bool isEntryVisible(NotifyEntryKind kind) => switch (kind) {
        NotifyEntryKind.mutualHelp => _mutualVisible,
        NotifyEntryKind.broadcast => _broadcastVisible,
      };

  /// 是否有真正的通知数据（互助或广播会话）。
  bool get hasNotifyData =>
      hasMutualHelp || _broadcast.hasData || _broadcast.unread;

  /// 可见行里的数字角标之和（不含广播红点）。
  int get visibleUnreadCount => visibleEntries
      .where((NotifyEntry entry) => entry.badge == NotifyBadgeKind.count)
      .fold(0, (int sum, NotifyEntry entry) => sum + entry.count);

  bool get visibleBroadcastDot => visibleEntries
      .any((NotifyEntry entry) => entry.badge == NotifyBadgeKind.dot);

  /// 分组头右侧的状态文案。
  String get sectionMeta {
    if (visibleUnreadCount > 0) return '$visibleUnreadCount 条未读';
    if (visibleBroadcastDot) return '有新公告';
    return '暂无未读';
  }

  String get _mutualSummary {
    if (masked) return '已屏蔽，不再计入未读';
    if (_mutual.unread > 0) return '${_mutual.unread} 个新问题';
    return '暂时没有新求助';
  }

  String get _broadcastSummary {
    if (!_broadcast.hasData) return '查看各吧官方公告';
    final String text = _broadcast.displaySummary.trim();
    return text.isEmpty ? '查看各吧官方公告' : text;
  }

  /// 提醒区是否有可见的**真实通知**。
  ///
  /// 提醒区是否有可见的**真实通知**。
  ///
  /// 只有功能入口、没有任何通知数据时整块不渲染：不画占位、不写「未连接」，
  /// 避免用户把「没有这类通知」误读成「IM 连不上」。铃铛仍保留在搜索栏，
  /// 面板里可以打开广播页。
  bool get reminderVisible => _loggedIn && _hasVisibleNotifyRow;

  bool get _hasVisibleNotifyRow => visibleEntries.any((NotifyEntry entry) =>
      entry.kind == NotifyEntryKind.mutualHelp ||
      (entry.kind == NotifyEntryKind.broadcast &&
          (_broadcast.hasData || _broadcast.unread)));

  /// 铃铛在消息页常驻（登录后），随时可以查看或恢复提醒区。
  ///
  /// 以前它只在「有卡被隐藏」时出现，隐藏一张后再想改主意就得先恢复；
  /// 现在不依赖隐藏状态，避免出现「关掉就找不回来」的死角。
  /// 未登录仍不显示：此时没有可管理的提醒，面板会是空的。
  bool get bellVisible => _loggedIn;

  /// 铃铛红点：被本机隐藏的行里还有未读或新广播。
  bool get bellDot => entries.any((NotifyEntry entry) =>
      !isEntryVisible(entry.kind) &&
      (entry.badge == NotifyBadgeKind.count ||
          entry.badge == NotifyBadgeKind.dot));

  /// 是否已有广播摘要/时间；没有时入口显示固定副标题。
  bool get broadcastHasData => _broadcast.hasData;

  /// 保证当前账号的本地状态已读取；重复调用不会重复请求。
  Future<void> ensureLoaded() async {
    final String? uid = _currentUid();
    if (_loaded && uid == _uid) return;
    await load();
  }

  /// 切号 / 启动时按 uid 重新读取本地状态，再拉一次远端。
  Future<void> load() async {
    _uid = _currentUid();
    _restoreLocal();
    _loaded = true;
    try {
      final TiebaApi api = Global.tiebaAPI;
      _loggedIn = api.isLogin;
    } catch (_) {
      _loggedIn = false;
    }
    notifyListeners();
    if (_loggedIn) {
      await refresh();
    }
  }

  /// 拉取通知概览与互助屏蔽开关。
  Future<void> refresh() async {
    final TiebaApi api;
    try {
      api = Global.tiebaAPI;
    } catch (_) {
      _notifyIfChanged(() {
        _loggedIn = false;
        _mutual = TiebaMutualHelpNotice.empty;
        _broadcast = TiebaBroadcastNotice.empty;
      });
      return;
    }
    if (!api.isLogin) {
      _notifyIfChanged(() {
        _loggedIn = false;
        _mutual = TiebaMutualHelpNotice.empty;
        _broadcast = TiebaBroadcastNotice.empty;
      });
      return;
    }
    _loggedIn = true;

    TiebaNotificationOverview? overview;
    bool? maskedRemote;
    if (api is TiebaNotificationApi) {
      final TiebaNotificationApi notifyApi = api as TiebaNotificationApi;
      try {
        overview = await notifyApi.getNotificationOverview();
      } catch (error, stack) {
        AppLog.shared.error('notification.overview_failed', error, stack);
      }
      try {
        maskedRemote = await notifyApi.getMutualHelpMasked();
      } catch (error, stack) {
        AppLog.shared.error('notification.mutual_switch_failed', error, stack);
      }
    }

    _notifyIfChanged(() {
      if (overview != null) {
        _systemNotificationsEnabled = overview.systemNotificationsEnabled;
        final TiebaBroadcastNotice remoteBroadcast = overview.broadcast;
        // 远端为空时保留本地缓存：IM 暂时没同步到，不应把已经显示过的
        // 广播通知清空；只有远端真的给出会话/摘要时才覆盖。
        if (remoteBroadcast.hasData || remoteBroadcast.unread) {
          _broadcast = TiebaBroadcastNotice(
            unread: remoteBroadcast.unread &&
                _isNewerThanRead(remoteBroadcast.latestTime, _broadcastReadAt),
            latestTime: remoteBroadcast.latestTime,
            title: remoteBroadcast.title,
            summary: remoteBroadcast.summary,
          );
        }
        final TiebaMutualHelpNotice remote = overview.mutualHelp;
        _mutual = TiebaMutualHelpNotice(
          visible: remote.visible || _mutual.visible,
          unread: remote.visible
              ? (_isNewerThanRead(remote.latestTime, _mutualReadAt) ||
                      remote.unread > _mutualReadUnread
                  ? remote.unread
                  : 0)
              : _mutual.unread,
          latestTime: remote.visible ? remote.latestTime : _mutual.latestTime,
          masked: maskedRemote ?? remote.masked,
        );
      } else if (maskedRemote != null) {
        _mutual = _mutual.copyWith(masked: maskedRemote);
      }
    });
    _persistMutual();
    _persistBroadcast();
  }

  /// 远端时间晚于上次阅读时间，才把未读重新亮起来。
  ///
  /// 官方只在本地记录消费位置；IM 概览会继续返回同一个未读，不能每次刷新
  /// 都把刚看过的提醒重新点亮。新消息的 `latestTime` 更新后自然恢复。
  static bool _isNewerThanRead(DateTime? remoteTime, DateTime? readAt) {
    if (readAt == null) return true;
    if (remoteTime == null) return false;
    return remoteTime.isAfter(readAt);
  }

  /// 打开互助 H5 时清本地未读（协议只观察到本地清零，没有服务端已读接口）。
  void markMutualRead() {
    if (_mutual.unread == 0) return;
    _mutualReadAt = _mutual.latestTime ?? DateTime.now();
    _mutualReadUnread = _mutual.unread;
    _mutual = _mutual.copyWith(unread: 0);
    _persistMutual();
    _persistReadAt();
    notifyListeners();
  }

  /// 打开吧广播时清合并会话红点；只有更新的广播才会再次亮起。
  void markBroadcastRead() {
    if (!_broadcast.unread) return;
    _broadcastReadAt = _broadcast.latestTime ?? DateTime.now();
    _broadcast = _broadcast.copyWith(unread: false);
    _persistBroadcast();
    _persistReadAt();
    notifyListeners();
  }

  /// 逐项恢复 / 隐藏互助行（本机可见性）。
  void setMutualVisible(bool visible) {
    if (_mutualVisible == visible) return;
    _mutualVisible = visible;
    _writeBool(mutualVisibleKey, visible);
    notifyListeners();
  }

  /// 逐项恢复 / 隐藏广播行（本机可见性）。
  void setBroadcastVisible(bool visible) {
    if (_broadcastVisible == visible) return;
    _broadcastVisible = visible;
    _writeBool(broadcastVisibleKey, visible);
    notifyListeners();
  }

  /// 按行类型切换本机可见性，供通用面板调用。
  void setEntryVisible(NotifyEntryKind kind, bool visible) {
    if (kind == NotifyEntryKind.mutualHelp) {
      setMutualVisible(visible);
    } else {
      setBroadcastVisible(visible);
    }
  }

  /// 隐藏当前所有可见行，返回隐藏前的状态供撤销。
  ReminderVisibilitySnapshot hideAll() {
    final ReminderVisibilitySnapshot snapshot = ReminderVisibilitySnapshot(
      mutual: _mutualVisible,
      broadcast: _broadcastVisible,
    );
    _mutualVisible = false;
    _broadcastVisible = false;
    _writeBool(mutualVisibleKey, false);
    _writeBool(broadcastVisibleKey, false);
    notifyListeners();
    return snapshot;
  }

  /// 撤销一次「隐藏全部」；不恢复更早前已隐藏的行。
  void restore(ReminderVisibilitySnapshot snapshot) {
    _mutualVisible = snapshot.mutual;
    _broadcastVisible = snapshot.broadcast;
    _writeBool(mutualVisibleKey, _mutualVisible);
    _writeBool(broadcastVisibleKey, _broadcastVisible);
    notifyListeners();
  }

  /// 写入账号级互助屏蔽开关；失败回滚并返回 false。
  Future<bool> setMasked(bool masked) async {
    if (_maskedBusy) return false;
    final TiebaMutualHelpNotice previous = _mutual;
    _maskedBusy = true;
    _mutual = _mutual.copyWith(masked: masked);
    notifyListeners();
    try {
      final TiebaApi api = Global.tiebaAPI;
      if (api is! TiebaNotificationApi) {
        throw StateError('当前后端不支持互助开关');
      }
      await (api as TiebaNotificationApi).setMutualHelpMasked(masked);
      _persistMutual();
      return true;
    } catch (error, stack) {
      AppLog.shared
          .error('notification.mutual_switch_write_failed', error, stack);
      _mutual = previous;
      return false;
    } finally {
      _maskedBusy = false;
      notifyListeners();
    }
  }

  /// 账号切换 / 退出时清空运行时状态；本地偏好保留给原账号。
  void reset() {
    _uid = null;
    _loaded = false;
    _loggedIn = false;
    _mutual = TiebaMutualHelpNotice.empty;
    _broadcast = TiebaBroadcastNotice.empty;
    _mutualReadAt = null;
    _mutualReadUnread = 0;
    _broadcastReadAt = null;
    _systemNotificationsEnabled = true;
    _mutualVisible = true;
    _broadcastVisible = true;
    _maskedBusy = false;
    notifyListeners();
  }

  @visibleForTesting
  void debugSet({
    TiebaMutualHelpNotice? mutual,
    TiebaBroadcastNotice? broadcast,
    bool? loggedIn,
    bool? systemNotificationsEnabled,
    bool? mutualVisible,
    bool? broadcastVisible,
  }) {
    if (mutual != null) _mutual = mutual;
    if (broadcast != null) _broadcast = broadcast;
    if (loggedIn != null) _loggedIn = loggedIn;
    if (systemNotificationsEnabled != null) {
      _systemNotificationsEnabled = systemNotificationsEnabled;
    }
    if (mutualVisible != null) _mutualVisible = mutualVisible;
    if (broadcastVisible != null) _broadcastVisible = broadcastVisible;
    _loaded = true;
    notifyListeners();
  }

  // ── 本地存储 ──────────────────────────────────────────────────────────────

  void _restoreLocal() {
    final SharedPreferences? prefs = _prefs();
    _mutualVisible = prefs?.getBool(_key(mutualVisibleKey)) ?? true;
    _broadcastVisible = prefs?.getBool(_key(broadcastVisibleKey)) ?? true;
    final bool seen = prefs?.getBool(_key(mutualSeenKey)) ?? false;
    final int unread = prefs?.getInt(_key(mutualUnreadKey)) ?? 0;
    final int latestMs = prefs?.getInt(_key(mutualLatestKey)) ?? 0;
    final bool masked = prefs?.getBool(_key(mutualMaskKey)) ?? false;
    final int mutualReadAtMs = prefs?.getInt(_key(mutualReadAtKey)) ?? 0;
    final int broadcastReadAtMs = prefs?.getInt(_key(broadcastReadAtKey)) ?? 0;
    _mutualReadUnread = prefs?.getInt(_key(mutualReadUnreadKey)) ?? 0;
    _mutualReadAt = mutualReadAtMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(mutualReadAtMs)
        : null;
    _broadcastReadAt = broadcastReadAtMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(broadcastReadAtMs)
        : null;
    _mutual = TiebaMutualHelpNotice(
      visible: seen,
      unread: unread < 0 ? 0 : unread,
      latestTime:
          latestMs > 0 ? DateTime.fromMillisecondsSinceEpoch(latestMs) : null,
      masked: masked,
    );
    final int broadcastMs = prefs?.getInt(_key(broadcastTimeKey)) ?? 0;
    _broadcast = TiebaBroadcastNotice(
      unread: prefs?.getBool(_key(broadcastUnreadKey)) ?? false,
      latestTime: broadcastMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(broadcastMs)
          : null,
      title: prefs?.getString(_key(broadcastTitleKey)) ?? '',
      summary: prefs?.getString(_key(broadcastSummaryKey)) ?? '',
    );
    _systemNotificationsEnabled = true;
  }

  void _persistMutual() {
    final SharedPreferences? prefs = _prefs();
    if (prefs == null) return;
    prefs.setBool(_key(mutualSeenKey), _mutual.visible);
    prefs.setInt(_key(mutualUnreadKey), _mutual.unread);
    prefs.setInt(
        _key(mutualLatestKey), _mutual.latestTime?.millisecondsSinceEpoch ?? 0);
    prefs.setBool(_key(mutualMaskKey), _mutual.masked);
  }

  /// 广播摘要落地，冷启动或 IM 暂时不可用时仍能显示上一次的通知。
  void _persistBroadcast() {
    final SharedPreferences? prefs = _prefs();
    if (prefs == null) return;
    prefs.setBool(_key(broadcastUnreadKey), _broadcast.unread);
    prefs.setInt(_key(broadcastTimeKey),
        _broadcast.latestTime?.millisecondsSinceEpoch ?? 0);
    prefs.setString(_key(broadcastTitleKey), _broadcast.title);
    prefs.setString(_key(broadcastSummaryKey), _broadcast.summary);
  }

  /// 记录已消费到的时间点；按 uid 隔离，换号不串。
  void _persistReadAt() {
    final SharedPreferences? prefs = _prefs();
    if (prefs == null) return;
    prefs.setInt(
        _key(mutualReadAtKey), _mutualReadAt?.millisecondsSinceEpoch ?? 0);
    prefs.setInt(_key(mutualReadUnreadKey), _mutualReadUnread);
    prefs.setInt(_key(broadcastReadAtKey),
        _broadcastReadAt?.millisecondsSinceEpoch ?? 0);
  }

  void _writeBool(String key, bool value) {
    _prefs()?.setBool(_key(key), value);
  }

  SharedPreferences? _prefs() {
    try {
      return Global.profile;
    } catch (_) {
      // widget 测试 / 启动早期可能还没有 SharedPreferences。
      return null;
    }
  }

  String? _currentUid() {
    try {
      return AccountStore.currentUid;
    } catch (_) {
      return null;
    }
  }

  String _key(String base) => _uid == null ? base : '$base.$_uid';

  void _notifyIfChanged(VoidCallback mutate) {
    final TiebaMutualHelpNotice beforeMutual = _mutual;
    final TiebaBroadcastNotice beforeBroadcast = _broadcast;
    final bool beforeSystem = _systemNotificationsEnabled;
    final bool beforeLoggedIn = _loggedIn;
    mutate();
    if (beforeMutual != _mutual ||
        beforeBroadcast != _broadcast ||
        beforeSystem != _systemNotificationsEnabled ||
        beforeLoggedIn != _loggedIn) {
      notifyListeners();
    }
  }
}
