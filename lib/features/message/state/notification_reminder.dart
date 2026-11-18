import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:tiebanana/features/account/data/account_store.dart';

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
/// - 提醒条/卡片的显示与隐藏只是本机 UI 偏好，不清未读、不改开关。
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

  TiebaMutualHelpNotice _mutual = TiebaMutualHelpNotice.empty;
  TiebaBroadcastNotice _broadcast = TiebaBroadcastNotice.empty;
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

  bool get mutualCardVisible => hasMutualHelp && _mutualVisible;

  bool get broadcastEntryVisible => hasBroadcastEntry && _broadcastVisible;

  /// 提醒条是否还有可见内容。
  bool get reminderVisible => mutualCardVisible || broadcastEntryVisible;

  /// 铃铛在任一卡被隐藏时出现，用来逐项恢复显示。
  bool get bellVisible => _loggedIn && (mutualHidden || broadcastHidden);

  bool get mutualHidden => hasMutualHelp && !_mutualVisible;

  bool get broadcastHidden => hasBroadcastEntry && !_broadcastVisible;

  /// 铃铛红点：隐藏的互助有未读，或隐藏的广播有新公告。
  bool get bellDot =>
      (mutualHidden && _mutual.unread > 0 && !masked) ||
      (broadcastHidden && broadcastDot);

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
        _broadcast = overview.broadcast;
        final TiebaMutualHelpNotice remote = overview.mutualHelp;
        _mutual = TiebaMutualHelpNotice(
          visible: remote.visible || _mutual.visible,
          unread: remote.visible ? remote.unread : _mutual.unread,
          latestTime: remote.visible ? remote.latestTime : _mutual.latestTime,
          masked: maskedRemote ?? remote.masked,
        );
      } else if (maskedRemote != null) {
        _mutual = _mutual.copyWith(masked: maskedRemote);
      }
    });
    _persistMutual();
  }

  /// 打开互助 H5 时清本地未读（协议只观察到本地清零，没有服务端已读接口）。
  void markMutualRead() {
    if (_mutual.unread == 0) return;
    _mutual = _mutual.copyWith(unread: 0);
    _persistMutual();
    notifyListeners();
  }

  /// 打开吧广播时清合并会话红点；只有更新的广播才会再次亮起。
  void markBroadcastRead() {
    if (!_broadcast.unread) return;
    _broadcast = _broadcast.copyWith(unread: false);
    notifyListeners();
  }

  /// 逐项恢复 / 隐藏互助卡片（本机可见性）。
  void setMutualVisible(bool visible) {
    if (_mutualVisible == visible) return;
    _mutualVisible = visible;
    _writeBool(mutualVisibleKey, visible);
    notifyListeners();
  }

  /// 逐项恢复 / 隐藏广播入口（本机可见性）。
  void setBroadcastVisible(bool visible) {
    if (_broadcastVisible == visible) return;
    _broadcastVisible = visible;
    _writeBool(broadcastVisibleKey, visible);
    notifyListeners();
  }

  /// 隐藏当前所有可见卡，返回隐藏前的状态供撤销。
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

  /// 撤销一次「隐藏全部」；不恢复更早前已隐藏的卡。
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
    _mutual = TiebaMutualHelpNotice(
      visible: seen,
      unread: unread < 0 ? 0 : unread,
      latestTime:
          latestMs > 0 ? DateTime.fromMillisecondsSinceEpoch(latestMs) : null,
      masked: masked,
    );
    _broadcast = TiebaBroadcastNotice.empty;
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
