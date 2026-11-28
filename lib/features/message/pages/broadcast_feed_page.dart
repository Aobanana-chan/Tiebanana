import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:tiebanana/features/message/state/notification_reminder.dart';
import 'package:tiebanana/features/message/state/notification_time.dart';
import 'package:tiebanana/features/message/widgets/broadcast_feed_card.dart';
import 'package:tiebanana/features/message/widgets/reminder_sheet.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/layout/page_wrap.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/avatar_image.dart';
import 'package:tiebanana/shared/widgets/broadcast_image_lightbox.dart';
import 'package:tiebanana/shared/widgets/desktop_panel.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';
import 'package:tiebanana/shared/widgets/tiebanana_refresh_indicator.dart';

/// 聚合「吧广播」信息流。
///
/// 移动端保持紧凑单列流；桌面宽屏（`>= 720dp`）纳入 [DesktopShellFrame] 与
/// [PageWrap]，提供来源吧筛选、按日快速定位、纯公告原地展开与配图灯箱预览。
class BroadcastFeedPage extends StatefulWidget {
  const BroadcastFeedPage({super.key});

  @override
  State<BroadcastFeedPage> createState() => _BroadcastFeedPageState();
}

class _BroadcastFeedPageState extends State<BroadcastFeedPage> {
  final List<TiebaBroadcastItem> _items = <TiebaBroadcastItem>[];
  final Map<String, GlobalKey> _dayKeys = <String, GlobalKey>{};
  final GlobalKey _reminderBtnKey = GlobalKey();
  final ScrollController _desktopScroll = ScrollController();

  bool _loading = true;
  bool _refreshing = false;
  Object? _error;
  String? _selectedForumKey;
  String? _flashedDayKey;
  Timer? _flashTimer;

  TiebaNotificationApi? get _api {
    try {
      final TiebaApi api = Global.tiebaAPI;
      return api is TiebaNotificationApi ? api as TiebaNotificationApi : null;
    } catch (_) {
      return null;
    }
  }

  bool get _unsupported => _api == null;

  bool get _loggedIn {
    try {
      return Global.tiebaAPI.isLogin;
    } catch (_) {
      return false;
    }
  }

  bool get _notLoggedIn {
    final Object? error = _error;
    return error != null && error.toString().contains('未登录');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _desktopScroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!refresh && _items.isEmpty && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final TiebaNotificationApi? api = _api;
    if (api == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = StateError('当前后端不支持吧广播');
        });
      }
      _refreshing = false;
      return;
    }
    try {
      final List<TiebaBroadcastItem> items =
          await api.getBroadcastFeed(limit: 80);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        if (_selectedForumKey != null &&
            !_items.any((TiebaBroadcastItem e) =>
                _forumKeyOf(e) == _selectedForumKey)) {
          _selectedForumKey = null;
        }
        _loading = false;
        _error = null;
      });
    } catch (error, stack) {
      AppLog.shared.error('message.broadcast_feed_failed', error, stack);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    } finally {
      _refreshing = false;
    }
  }

  static String _forumKeyOf(TiebaBroadcastItem item) {
    final String id = item.forumId.trim();
    if (id.isNotEmpty) return 'id:$id';
    final String name = item.forumName.trim();
    if (name.isNotEmpty) return 'name:$name';
    return 'unknown';
  }

  static String _forumLabelOf(String rawName) {
    final String trimmed = rawName.trim();
    if (trimmed.isEmpty) return '未知贴吧';
    return trimmed.endsWith('吧') ? trimmed : '$trimmed吧';
  }

  static String _desktopDayDisplay(DateTime time) {
    final DateTime local = time.toLocal();
    final DateTime now = DateTime.now();
    final String date = broadcastDayLabel(local);
    if (isSameReminderDay(local, now)) return '今天 · $date';
    final DateTime yesterday = now.subtract(const Duration(days: 1));
    if (isSameReminderDay(local, yesterday)) return '昨天 · $date';
    return date;
  }

  void _openItem(TiebaBroadcastItem item) {
    final String? threadId = item.threadId;
    if (threadId == null || threadId.isEmpty) return;
    Navigator.pushNamed(
      context,
      PageRouter.threadPage,
      arguments: ThreadPageRouterData(kz: threadId, pid: null),
    );
  }

  void _openForum(TiebaBroadcastItem item) {
    final String name = item.forumName.trim();
    if (name.isEmpty) return;
    Navigator.pushNamed(context, PageRouter.forumHome, arguments: name);
  }

  void _openForumHistory(TiebaBroadcastItem item) {
    if (item.forumId.trim().isEmpty) return;
    Navigator.pushNamed(
      context,
      PageRouter.forumBroadcast,
      arguments: ForumBroadcastRouteData(
        forumId: item.forumId,
        forumName: item.forumName.trim(),
        forumAvatar: item.forumAvatar,
      ),
    );
  }

  void _openZoom(TiebaBroadcastItem item, {bool desktop = false}) {
    showBroadcastImageLightbox(
      context,
      url: item.picUrl,
      title: item.title,
      forumName: item.forumName,
      desktop: desktop,
    );
  }

  void _openReminderSheet() {
    final RenderBox? box =
        _reminderBtnKey.currentContext?.findRenderObject() as RenderBox?;
    Rect? anchor;
    if (box != null && box.attached) {
      anchor = box.localToGlobal(Offset.zero) & box.size;
    }
    showReminderSheet(context, anchorRect: anchor);
  }

  void _jumpToDay(String dayKey) {
    final BuildContext? target = _dayKeys[dayKey]?.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.04,
      );
    }
    _flashTimer?.cancel();
    setState(() => _flashedDayKey = dayKey);
    _flashTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _flashedDayKey = null);
    });
  }

  List<_ForumBucket> _buildForumBuckets() {
    final Map<String, _ForumBucket> map = <String, _ForumBucket>{};
    for (final TiebaBroadcastItem item in _items) {
      final String key = _forumKeyOf(item);
      final _ForumBucket? existing = map[key];
      if (existing != null) {
        existing.count++;
      } else {
        map[key] = _ForumBucket(
          key: key,
          sample: item,
          label: _forumLabelOf(item.forumName),
          count: 1,
        );
      }
    }
    return map.values.toList(growable: false);
  }

  List<_DayGroup> _buildDayGroups(List<TiebaBroadcastItem> items) {
    final List<_DayGroup> groups = <_DayGroup>[];
    final Map<String, _DayGroup> map = <String, _DayGroup>{};
    for (final TiebaBroadcastItem item in items) {
      final DateTime? time = item.publishTime;
      final String key = time != null ? broadcastDayLabel(time) : 'earlier';
      final String label = time != null ? _desktopDayDisplay(time) : '更早发布';
      final _DayGroup? existing = map[key];
      if (existing != null) {
        existing.items.add(item);
      } else {
        final _DayGroup created = _DayGroup(
          key: key,
          label: label,
          items: <TiebaBroadcastItem>[item],
        );
        map[key] = created;
        groups.add(created);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        if (width >= AppBreakpoints.compactMax) {
          return _buildDesktop(context, width);
        }
        final TiebananaTokens tokens = TiebananaTokens.of(context);
        return Scaffold(
          backgroundColor: tokens.bg,
          appBar: AppBar(
            backgroundColor: tokens.bg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            foregroundColor: tokens.textPrimary,
            title: const Text('吧广播'),
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: _mobileBody(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktop(BuildContext context, double width) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final List<_ForumBucket> forums = _buildForumBuckets();
    final List<TiebaBroadcastItem> filtered = _selectedForumKey == null
        ? _items
        : _items
            .where(
                (TiebaBroadcastItem e) => _forumKeyOf(e) == _selectedForumKey)
            .toList(growable: false);
    final _ForumBucket? activeForum = _selectedForumKey == null
        ? null
        : forums
            .where((_ForumBucket b) => b.key == _selectedForumKey)
            .firstOrNull;

    final String headerSubtitle;
    if (_items.isNotEmpty && _loggedIn && !_unsupported) {
      if (activeForum != null) {
        headerSubtitle =
            '正在筛选「${activeForum.label}」的 ${filtered.length} 条广播 · 互动数据只读';
      } else {
        headerSubtitle =
            '已加载 ${_items.length} 条跨吧公告，来自 ${forums.length} 个关注的吧 · 互动数据只读';
      }
    } else {
      headerSubtitle = '按发布日期分组 · 互动数据只读';
    }

    final bool showReminderBtn = NotificationReminder.instance.bellVisible;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_selectedForumKey != null) {
            setState(() => _selectedForumKey = null);
          }
        },
      },
      child: DesktopShellFrame(
        title: '吧广播',
        subtitle: '消息中心 · 跨吧官方公告',
        activeTab: 2,
        onRefresh: () => _load(refresh: true),
        child: PageWrap(
          maxWidth: AppBreakpoints.pageMaxWidth,
          bottomPadding: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DesktopPageHeader(
                title: '吧广播',
                subtitle: headerSubtitle,
                tools: <Widget>[
                  if (activeForum != null)
                    OutlinedButton(
                      onPressed: () => setState(() => _selectedForumKey = null),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tokens.textSecondary,
                        side: BorderSide(color: tokens.line),
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('显示全部'),
                    ),
                  if (showReminderBtn)
                    OutlinedButton.icon(
                      key: _reminderBtnKey,
                      onPressed: _openReminderSheet,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tokens.textSecondary,
                        side: BorderSide(color: tokens.line),
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      icon: const Icon(Icons.notifications_none_rounded,
                          size: 14),
                      label: const Text('提醒设置'),
                    ),
                ],
              ),
              Expanded(
                child: _desktopBody(
                  context,
                  width: width,
                  forums: forums,
                  filtered: filtered,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopBody(
    BuildContext context, {
    required double width,
    required List<_ForumBucket> forums,
    required List<TiebaBroadcastItem> filtered,
  }) {
    final Widget? state = _stateWidget(context, desktop: true);
    if (state != null) return state;

    final List<_DayGroup> days = _buildDayGroups(filtered);
    final bool twoCol = width >= AppBreakpoints.mediumMax;
    final double ctxWidth = width >= 1100 ? 296 : 268;
    final double colGap = width >= 1100 ? 16 : 14;

    final Widget feedList = TiebananaRefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        controller: _desktopScroll,
        padding: const EdgeInsets.only(bottom: 26),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: days.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == days.length) {
            return _DesktopFeedFooter(count: filtered.length);
          }
          final _DayGroup group = days[index];
          final GlobalKey dayKey = _dayKeys.putIfAbsent(
            group.key,
            () => GlobalKey(),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _DesktopDayHeader(
                key: dayKey,
                label: group.label,
                count: group.items.length,
                flashed: _flashedDayKey == group.key,
              ),
              for (final TiebaBroadcastItem item in group.items)
                BroadcastFeedCard(
                  item: item,
                  desktop: true,
                  onTap: () => _openItem(item),
                  onOpenForum: () => _openForum(item),
                  onOpenForumHistory: () => _openForumHistory(item),
                  onZoomImage: () => _openZoom(item, desktop: true),
                ),
            ],
          );
        },
      ),
    );

    if (!twoCol) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _CompactForumFilterBar(
            forums: forums,
            totalCount: _items.length,
            selectedKey: _selectedForumKey,
            onSelect: (String? key) => setState(() => _selectedForumKey = key),
          ),
          const SizedBox(height: 10),
          Expanded(child: feedList),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: feedList),
        SizedBox(width: colGap),
        SizedBox(
          width: ctxWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: _ContextSidebar(
              forums: forums,
              days: days,
              totalCount: _items.length,
              selectedForumKey: _selectedForumKey,
              onSelectForum: (String? key) =>
                  setState(() => _selectedForumKey = key),
              onOpenForum: _openForum,
              onOpenForumHistory: _openForumHistory,
              onJumpDay: _jumpToDay,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _stateWidget(BuildContext context, {required bool desktop}) {
    if (_unsupported) {
      return _wrapState(
        desktop,
        const StateView(
          icon: Icons.campaign_outlined,
          title: '当前版本暂不支持吧广播',
          body: '切换到支持吧广播的贴吧后端后再试',
        ),
      );
    }
    if (_notLoggedIn || !_loggedIn) {
      return _wrapState(
        desktop,
        StateView(
          icon: Icons.person_outline,
          title: '登录后才能看吧广播',
          body: '吧广播需要登录后同步',
          primaryLabel: '去登录',
          onPrimary: () => Navigator.pushNamed(context, PageRouter.login),
        ),
      );
    }
    if (_loading && _items.isEmpty) {
      return _FeedSkeleton(desktop: desktop);
    }
    if (_error != null && _items.isEmpty) {
      return _wrapState(
        desktop,
        StateView(
          icon: Icons.wifi_off_outlined,
          title: '广播没有加载出来',
          body: '检查网络后重试',
          primaryLabel: '重试',
          primaryIcon: Icons.refresh,
          onPrimary: () => _load(),
        ),
      );
    }
    if (_items.isEmpty) {
      return _wrapState(
        desktop,
        StateView(
          icon: Icons.campaign_outlined,
          title: '还没有吧广播',
          body: '关注的吧发布广播后会出现在这里',
          primaryLabel: '刷新',
          primaryIcon: Icons.refresh,
          onPrimary: () => _load(refresh: true),
        ),
      );
    }
    return null;
  }

  Widget _wrapState(bool desktop, Widget child) {
    if (!desktop) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: DesktopPanel(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: child,
      ),
    );
  }

  Widget _mobileBody(BuildContext context) {
    final Widget? state = _stateWidget(context, desktop: false);
    if (state != null) return state;

    final List<Object> rows = <Object>[];
    String? lastDay;
    for (final TiebaBroadcastItem item in _items) {
      final DateTime? time = item.publishTime;
      if (time != null) {
        final String day = broadcastDayLabel(time);
        if (day != lastDay) {
          rows.add(day);
          lastDay = day;
        }
      }
      rows.add(item);
    }

    return TiebananaRefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: TiebananaMetrics.gapMd),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: rows.length,
        itemBuilder: (BuildContext context, int index) {
          final Object row = rows[index];
          if (row is String) return _DayHeader(day: row);
          final TiebaBroadcastItem item = row as TiebaBroadcastItem;
          return BroadcastFeedCard(
            item: item,
            onTap: () => _openItem(item),
            onZoomImage: () => _openZoom(item),
          );
        },
      ),
    );
  }
}

class _ForumBucket {
  _ForumBucket({
    required this.key,
    required this.sample,
    required this.label,
    required this.count,
  });

  final String key;
  final TiebaBroadcastItem sample;
  final String label;
  int count;
}

class _DayGroup {
  _DayGroup({
    required this.key,
    required this.label,
    required this.items,
  });

  final String key;
  final String label;
  final List<TiebaBroadcastItem> items;
}

class _DesktopDayHeader extends StatelessWidget {
  const _DesktopDayHeader({
    super.key,
    required this.label,
    required this.count,
    required this.flashed,
  });

  final String label;
  final int count;
  final bool flashed;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
      child: Row(
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: flashed ? tokens.primaryContainer : tokens.fill,
              borderRadius: TiebananaMetrics.brPill,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color:
                    flashed ? tokens.onPrimaryContainer : tokens.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count 条',
            style: TextStyle(
              color: tokens.textTertiary,
              fontSize: 11,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: tokens.line)),
        ],
      ),
    );
  }
}

class _CompactForumFilterBar extends StatelessWidget {
  const _CompactForumFilterBar({
    required this.forums,
    required this.totalCount,
    required this.selectedKey,
    required this.onSelect,
  });

  final List<_ForumBucket> forums;
  final int totalCount;
  final String? selectedKey;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _CompactPill(
            label: '全部 ($totalCount)',
            selected: selectedKey == null,
            tokens: tokens,
            onTap: () => onSelect(null),
          ),
          for (final _ForumBucket f in forums) ...<Widget>[
            const SizedBox(width: 7),
            _CompactPill(
              label: '${f.label} (${f.count})',
              selected: selectedKey == f.key,
              tokens: tokens,
              onTap: () => onSelect(f.key),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactPill extends StatelessWidget {
  const _CompactPill({
    required this.label,
    required this.selected,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final TiebananaTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? tokens.primaryContainer : tokens.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? Colors.transparent : tokens.line,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color:
                    selected ? tokens.onPrimaryContainer : tokens.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContextSidebar extends StatelessWidget {
  const _ContextSidebar({
    required this.forums,
    required this.days,
    required this.totalCount,
    required this.selectedForumKey,
    required this.onSelectForum,
    required this.onOpenForum,
    required this.onOpenForumHistory,
    required this.onJumpDay,
  });

  final List<_ForumBucket> forums;
  final List<_DayGroup> days;
  final int totalCount;
  final String? selectedForumKey;
  final ValueChanged<String?> onSelectForum;
  final ValueChanged<TiebaBroadcastItem> onOpenForum;
  final ValueChanged<TiebaBroadcastItem> onOpenForumHistory;
  final ValueChanged<String> onJumpDay;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DesktopPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PanelHeader(title: '来源吧', count: forums.length),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                child: Column(
                  children: <Widget>[
                    _ForumFilterRow(
                      label: '全部广播',
                      count: totalCount,
                      selected: selectedForumKey == null,
                      leading: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: selectedForumKey == null
                              ? tokens.surface
                              : tokens.fill,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.campaign_outlined,
                          size: 13.5,
                          color: selectedForumKey == null
                              ? tokens.primary
                              : tokens.textSecondary,
                        ),
                      ),
                      onTap: () => onSelectForum(null),
                    ),
                    const SizedBox(height: 2),
                    for (final _ForumBucket f in forums) ...<Widget>[
                      _ForumFilterRow(
                        label: f.label,
                        count: f.count,
                        selected: selectedForumKey == f.key,
                        leading: _MiniForumSquare(
                          name: f.label,
                          url: f.sample.forumAvatar,
                        ),
                        onTap: () => onSelectForum(f.key),
                        onOpenForum: f.sample.forumName.trim().isNotEmpty
                            ? () => onOpenForum(f.sample)
                            : null,
                        onOpenHistory: f.sample.forumId.trim().isNotEmpty
                            ? () => onOpenForumHistory(f.sample)
                            : null,
                      ),
                      const SizedBox(height: 2),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DesktopPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PanelHeader(title: '按日定位', count: days.length),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                child: Column(
                  children: <Widget>[
                    for (final _DayGroup g in days)
                      InkWell(
                        borderRadius: BorderRadius.circular(9),
                        hoverColor: tokens.primary.withValues(alpha: 0.05),
                        onTap: () => onJumpDay(g.key),
                        child: SizedBox(
                          height: 32,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    g.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: tokens.textSecondary,
                                      fontSize: 12,
                                      fontFeatures: const <FontFeature>[
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                                Text(
                                  '${g.items.length} 条',
                                  style: TextStyle(
                                    color: tokens.textTertiary,
                                    fontSize: 11,
                                    fontFeatures: const <FontFeature>[
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DesktopPanel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '关于吧广播',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '吧广播不计入消息数字角标；进入本页即清除顶部红点。\n互动数据来自关联原帖只读快照；发布新广播请前往对应吧内「吧广播」或官方网页版。',
                style: TextStyle(
                  color: tokens.textTertiary,
                  fontSize: 11.5,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ForumFilterRow extends StatefulWidget {
  const _ForumFilterRow({
    required this.label,
    required this.count,
    required this.selected,
    required this.leading,
    required this.onTap,
    this.onOpenForum,
    this.onOpenHistory,
  });

  final String label;
  final int count;
  final bool selected;
  final Widget leading;
  final VoidCallback onTap;
  final VoidCallback? onOpenForum;
  final VoidCallback? onOpenHistory;

  @override
  State<_ForumFilterRow> createState() => _ForumFilterRowState();
}

class _ForumFilterRowState extends State<_ForumFilterRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Color fg =
        widget.selected ? tokens.onPrimaryContainer : tokens.textSecondary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: widget.selected ? tokens.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: tokens.primary.withValues(alpha: 0.05),
          onTap: widget.onTap,
          child: SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Row(
                children: <Widget>[
                  widget.leading,
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontSize: 12.5,
                        fontWeight:
                            widget.selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_hovered && widget.onOpenHistory != null)
                    Tooltip(
                      message: '查看${widget.label}历史广播',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: widget.onOpenHistory,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.history_rounded,
                            size: 13.5,
                            color: tokens.textTertiary,
                          ),
                        ),
                      ),
                    )
                  else if (_hovered && widget.onOpenForum != null)
                    Tooltip(
                      message: '进入${widget.label}',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: widget.onOpenForum,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.open_in_new_rounded,
                            size: 13,
                            color: tokens.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.count}',
                    style: TextStyle(
                      color: widget.selected
                          ? tokens.onPrimaryContainer
                          : tokens.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniForumSquare extends StatelessWidget {
  const _MiniForumSquare({required this.name, required this.url});

  final String name;
  final String url;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final String letter = name.isEmpty ? '吧' : name.substring(0, 1);
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: SizedBox(
        width: 22,
        height: 22,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Container(
              color: tokens.primaryContainer,
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                  color: tokens.onPrimaryContainer,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (url.isNotEmpty) AvatarImage(url: url),
          ],
        ),
      ),
    );
  }
}

class _DesktopFeedFooter extends StatelessWidget {
  const _DesktopFeedFooter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          '已展示最近 $count 条广播',
          style: TextStyle(
            color: tokens.textTertiary,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final String day;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Text(
        day,
        style: TextStyle(
          color: tokens.textTertiary,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton({this.desktop = false});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        Padding(
          padding:
              EdgeInsets.fromLTRB(desktop ? 2 : 16, 8, desktop ? 2 : 16, 10),
          child: const SkeletonBox(width: 92, height: 12),
        ),
        for (int i = 0; i < 3; i++)
          Container(
            margin: EdgeInsets.fromLTRB(
              desktop ? 0 : TiebananaMetrics.pageGutter,
              0,
              desktop ? 0 : TiebananaMetrics.pageGutter,
              10,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: TiebananaMetrics.brLg,
              boxShadow: tokens.cardShadow,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SkeletonBox(width: 210, height: 15),
                SizedBox(height: 10),
                SkeletonBox(height: 12),
                SizedBox(height: 6),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.8,
                  child: SkeletonBox(height: 12),
                ),
                SizedBox(height: 14),
                SkeletonBox(width: 120, height: 11),
              ],
            ),
          ),
      ],
    );
  }
}
