import 'dart:async';

import 'package:flutter/material.dart' hide SearchBar;
import 'package:tiebanana/app/navigation/app_route_observer.dart';
import 'package:tiebanana/shared/widgets/tiebanana_refresh_indicator.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:tiebanana/features/message/state/message_reminder.dart';
import 'package:tiebanana/features/message/state/notify_entry.dart';
import 'package:tiebanana/features/message/state/notification_reminder.dart';
import 'package:tiebanana/features/message/pages/private_message_panel.dart';
import 'package:tiebanana/features/message/services/official_notify_pages.dart';
import 'package:tiebanana/features/message/widgets/notify_entry_row.dart';
import 'package:tiebanana/features/message/widgets/notify_section_header.dart';
import 'package:tiebanana/features/message/widgets/reminder_bell.dart';
import 'package:tiebanana/features/message/widgets/reminder_sheet.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/floating_search_app_bar.dart';
import 'package:tiebanana/shared/widgets/keep_alive_wrapper.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';
import 'package:tiebanana/features/message/widgets/message_card.dart';
import 'package:tiebanana/features/search/widgets/search_bar.dart';
import 'package:tiebanana/shared/widgets/tiebanana_tab_indicator.dart';

/// 拉一页消息。[pn] 是页码，从 1 开始。
typedef MessageLoader = Future<MessagePageResult> Function(int pn);

/// 一页消息：条目 + 该分类的未读数 + 是否还有下一页。
class MessagePageResult {
  const MessagePageResult({
    required this.items,
    required this.hasMore,
    this.unread,
  });

  final List<TiebaMessage> items;

  /// 列表响应携带的历史字段；角标以独立的 c/s/msg 提醒快照为准。
  final int? unread;

  final bool hasMore;
}

/// 页签元信息：顺序即页签顺序，空态文案也挂在这里，三个页签共用。
///
///对测试公开：展示层（`MessageFeed`）的用例要自己造一个 meta 出来。
class MessageTabMeta {
  const MessageTabMeta({
    required this.kind,
    required this.label,
    required this.emptyTitle,
    required this.emptyBody,
    required this.emptyIcon,
  });

  /// 私信页签没有 [TiebaMessageKind]（未读来自本地会话表）。
  final TiebaMessageKind? kind;
  final String label;
  final String emptyTitle;
  final String emptyBody;
  final IconData emptyIcon;
}

const List<MessageTabMeta> messageTabMetas = <MessageTabMeta>[
  MessageTabMeta(
    kind: null,
    label: "私信",
    emptyTitle: "还没有私信",
    emptyBody: "在用户主页点「发私信」\n开始第一段对话",
    emptyIcon: Icons.chat_bubble_outline,
  ),
  MessageTabMeta(
    kind: TiebaMessageKind.reply,
    label: "回复",
    emptyTitle: "还没有人回复你",
    emptyBody: "去关注的吧逛逛，或者发个贴子\n说不定就有人来搭话了",
    emptyIcon: Icons.inbox_outlined,
  ),
  MessageTabMeta(
    kind: TiebaMessageKind.at,
    label: "@我",
    emptyTitle: "还没有人 @ 你",
    emptyBody: "有人在贴子里 @ 到你时，会出现在这里",
    emptyIcon: Icons.alternate_email,
  ),
  MessageTabMeta(
    kind: TiebaMessageKind.like,
    label: "给我点赞",
    emptyTitle: "还没有人给你点赞",
    emptyBody: "去关注的吧逛逛，或者发个贴子\n说不定就有人路过点一下",
    emptyIcon: Icons.thumb_up_outlined,
  ),
];

/// 消息页
///
///对应概念图 `design/mockups/message.html`（方向 A）：
///搜索栏 → 三个页签（回复 / @我 / 给我点赞）+ 未读数 → 消息列表。
///三个页签各有一套独立的分页 / 加载 / 错误状态，第一次切过去才发请求。
class MessagePan extends StatefulWidget {
  final FloatingSearchBarController controller;

  /// 三个页签的取数实现。不传就走 [Global.tiebaAPI]（测试里注入假数据）。
  final Map<TiebaMessageKind, MessageLoader>? loaders;

  /// 空态「去逛逛」：切到首页页签。消息页嵌在首页的 PageView 里，
  /// 用一个回调比自己去 push 一个首页路由干净。
  final VoidCallback? onBrowse;

  const MessagePan(
      {super.key, required this.controller, this.loaders, this.onBrowse});

  @override
  _MessagePanState createState() => _MessagePanState();
}

class _MessagePanState extends State<MessagePan>
    with SingleTickerProviderStateMixin, RouteAware {
  /// 消息页可见时补拉私信与通知的间隔。
  ///
  /// IM 推送只负责把新消息写进本地缓存，界面仍需要一次读取才能看到；
  /// 与聊天页的 5 秒轮询保持一致。
  static const Duration _liveRefreshInterval = Duration(seconds: 5);

  late TabController _controller;
  late final List<_TabState> _tabs;
  int _selectedTab = 0;

  /// 提醒区的展开状态只在当前页面会话里有效，每次启动默认展开。
  bool _reminderExpanded = true;

  /// 自动刷新只在页签可见且没有被其它路由盖住时运行。
  Timer? _liveRefresh;
  bool _tabActive = true;
  bool _routeVisible = true;
  bool _routeSubscribed = false;

  /// 通知私信页签重新读取会话列表。
  final ValueNotifier<int> _listRefresh = ValueNotifier<int>(0);
  final GlobalKey _desktopReminderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabs = messageTabMetas.map((MessageTabMeta meta) {
      final _TabState tab = _TabState(meta);
      tab.scroll.addListener(() {
        final ScrollPosition position = tab.scroll.position;
        if (position.pixels >
            position.maxScrollExtent - position.viewportDimension) {
          Throttle.seconds(2, () => _nextPage(tab));
        }
      });
      return tab;
    }).toList();
    _controller = TabController(length: _tabs.length, vsync: this);
    _controller.addListener(_onTabChanged);
    MessageReminder.counts.addListener(_onReminderChanged);
    MessageReminder.chatUnread.addListener(_onReminderChanged);
    NotificationReminder.instance.addListener(_onNotificationChanged);
    Global.desktopRefreshTick.addListener(_onDesktopRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) NotificationReminder.instance.ensureLoaded();
    });
  }

  void _onDesktopRefresh() {
    if (!mounted) return;
    final _TabState tab = _tabs[_selectedTab];
    if (tab.meta.kind == null) {
      _listRefresh.value++;
    } else {
      _refresh(tab);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routeSubscribed) {
      final ModalRoute<void>? route = ModalRoute.of(context);
      if (route != null) {
        appRouteObserver.subscribe(this, route);
        _routeSubscribed = true;
      }
    }
    _tabActive = TickerMode.valuesOf(context).enabled;
    _syncLiveRefresh();
  }

  /// 只有页签可见且当前路由在最上层时才轮询，避免在别的页签或子页面
  /// 后台一直打 IM 同步。
  void _syncLiveRefresh() {
    final bool live = _tabActive && _routeVisible;
    if (live == (_liveRefresh != null)) return;
    _liveRefresh?.cancel();
    _liveRefresh = live
        ? Timer.periodic(_liveRefreshInterval, (_) => unawaited(_refreshLive()))
        : null;
  }

  /// 推送把新消息写进本地缓存后，界面侧主动读一次。
  Future<void> _refreshLive() async {
    if (!mounted) return;
    await MessageReminder.refreshChat();
    if (!mounted) return;
    // 屏蔽开关变化不频繁，周期刷新只取概览，完整刷新留给首页的慢轮询。
    await NotificationReminder.instance.refresh(syncMask: false);
    if (!mounted) return;
    _listRefresh.value++;
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _syncLiveRefresh();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _syncLiveRefresh();
    if (mounted) unawaited(_refreshLive());
  }

  void _onNotificationChanged() {
    if (mounted) setState(() {});
  }

  void _onReminderChanged() {
    if (mounted) setState(() {});
  }

  void _onTabChanged() {
    if (_selectedTab == _controller.index) return;
    // 官方点赞独立页面在销毁时清分类提醒；嵌入式页签以离开分类为边界。
    if (_tabs[_selectedTab].meta.kind == TiebaMessageKind.like) {
      MessageReminder.clear(TiebaMessageKind.like);
    }
    _selectedTab = _controller.index;
    if (_tabs[_selectedTab].meta.kind == null) {
      MessageReminder.refreshChat();
    }
  }

  @override
  void dispose() {
    _liveRefresh?.cancel();
    if (_routeSubscribed) {
      appRouteObserver.unsubscribe(this);
    }
    _listRefresh.dispose();
    Global.desktopRefreshTick.removeListener(_onDesktopRefresh);
    MessageReminder.counts.removeListener(_onReminderChanged);
    MessageReminder.chatUnread.removeListener(_onReminderChanged);
    NotificationReminder.instance.removeListener(_onNotificationChanged);
    if (_tabs[_selectedTab].meta.kind == TiebaMessageKind.like) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => MessageReminder.clear(TiebaMessageKind.like));
    }
    _controller.dispose();
    for (final _TabState tab in _tabs) {
      tab.scroll.dispose();
    }
    super.dispose();
  }

  MessageLoader? _loaderOf(_TabState tab) {
    final TiebaMessageKind? kind = tab.meta.kind;
    if (kind == null) return null;
    final MessageLoader? injected = widget.loaders?[kind];
    if (injected != null) {
      return injected;
    }
    switch (kind) {
      case TiebaMessageKind.reply:
        return _loadReply;
      case TiebaMessageKind.at:
        return _loadAt;
      case TiebaMessageKind.like:
        return _loadLike;
    }
  }

  /// `c/u/feed/replyme`
  Future<MessagePageResult> _loadReply(int pn) async =>
      _result(await Global.tiebaAPI.getReply(pn));

  /// `c/u/feed/atme`
  Future<MessagePageResult> _loadAt(int pn) async =>
      _result(await Global.tiebaAPI.getAtMe(pn));

  /// 官方 `c/u/feed/agreeme`，底层按 id 游标翻页。
  Future<MessagePageResult> _loadLike(int pn) async =>
      _result(await Global.tiebaAPI.getLike(pn));

  static MessagePageResult _result(MessagePage page) => MessagePageResult(
        items: page.items,
        hasMore: page.hasMore,
        unread: page.unread,
      );

  /// 第一次显示这个页签才开始请求（三个页签不该在进消息页时一起打出去）。
  void _ensureStarted(_TabState tab) {
    if (tab.started) {
      return;
    }
    tab.started = true;
    if (tab.meta.kind == null) {
      MessageReminder.refreshChat();
      return;
    }
    if (tab.meta.kind == TiebaMessageKind.like) {
      MessageReminder.likeOpened = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refresh(tab);
      }
    });
  }

  /// 下拉刷新 / 首次加载。已有内容时保留列表，错误显示在底部。
  Future<void> _refresh(_TabState tab) async {
    final MessageLoader? loader = _loaderOf(tab);
    if (loader == null || tab.refreshing) {
      return;
    }
    tab.refreshing = true;
    if (tab.items.isEmpty && mounted) {
      setState(() {
        tab.loading = true;
        tab.error = null;
      });
    }
    try {
      final MessagePageResult page = await loader(1);
      if (!mounted) {
        return;
      }
      setState(() {
        tab.items
          ..clear()
          ..addAll(page.items);
        tab.hasMore = page.hasMore;
        tab.pn = 1;
        tab.loading = false;
        tab.error = null;
        tab.moreError = null;
      });
      final TiebaMessageKind? kind = tab.meta.kind;
      if (kind != null && kind != TiebaMessageKind.like) {
        MessageReminder.clear(kind);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        tab.loading = false;
        tab.error = error;
      });
    } finally {
      tab.refreshing = false;
    }
  }

  void _markRead(_TabState tab, TiebaMessage message) {
    if (!message.unread) return;
    // 对齐官方 vyb.Q(false)：只更新当前列表对象，刷新后服从接口。
    setState(() => message.unread = false);
  }

  Future<void> _nextPage(_TabState tab) async {
    final MessageLoader? loader = _loaderOf(tab);
    if (loader == null ||
        tab.loading ||
        tab.loadingMore ||
        !tab.hasMore ||
        !tab.started) {
      return;
    }
    final int next = tab.pn + 1;
    setState(() {
      tab.loadingMore = true;
      tab.moreError = null;
    });
    try {
      final MessagePageResult page = await loader(next);
      if (!mounted) {
        return;
      }
      setState(() {
        tab.items.addAll(page.items);
        tab.pn = next;
        tab.hasMore = page.hasMore;
        tab.loadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        tab.loadingMore = false;
        tab.moreError = error;
      });
    }
  }

  void _retry(_TabState tab) {
    setState(() {
      tab.error = null;
      tab.moreError = null;
    });
    _refresh(tab);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints topConstraints) {
        final double width = topConstraints.maxWidth.isFinite
            ? topConstraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        if (width >= AppBreakpoints.compactMax) {
          return _buildDesktop(context, width);
        }
        return Column(
          children: <Widget>[
            SearchBar(
              maxHeight: topConstraints.maxHeight,
              barController: widget.controller,
              trailing: _bell(),
            ),
            _reminderArea(),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => widget.controller.close(),
                child: Column(
                  children: <Widget>[
                    _tabHeader(context),
                    Expanded(
                      child: NotificationListener<
                          OverscrollIndicatorNotification>(
                        onNotification:
                            (OverscrollIndicatorNotification? overscroll) {
                          overscroll!.disallowIndicator();
                          return true;
                        },
                        child: TabBarView(
                          controller: _controller,
                          physics: const ClampingScrollPhysics(),
                          children: _tabs
                              .map((_TabState tab) => KeepAliveWrapper(
                                    child: _TabPage(
                                      onStart: () => _ensureStarted(tab),
                                      child: _body(tab),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktop(BuildContext context, double width) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final double hPad = width >= AppBreakpoints.mediumMax ? 24 : 12;
    return Column(
      children: <Widget>[
        _desktopTabHeader(context, tokens, width),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => widget.controller.close(),
            child: TabBarView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              children: _tabs
                  .map((_TabState tab) => KeepAliveWrapper(
                        child: _TabPage(
                          onStart: () => _ensureStarted(tab),
                          child: _body(
                            tab,
                            desktop: true,
                            horizontalPadding: hPad,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _openDesktopReminderSheet() {
    final RenderBox? box =
        _desktopReminderKey.currentContext?.findRenderObject() as RenderBox?;
    Rect? anchor;
    if (box != null && box.attached) {
      anchor = box.localToGlobal(Offset.zero) & box.size;
    }
    showReminderSheet(context, anchorRect: anchor);
  }

  Widget _desktopTabHeader(
    BuildContext context,
    TiebananaTokens tokens,
    double width,
  ) {
    final NotificationReminder reminder = NotificationReminder.instance;
    final List<NotifyEntry> entries = reminder.visibleEntries;
    final double hPad = width >= AppBreakpoints.mediumMax ? 16 : 12;

    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: hPad),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.line)),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          return Row(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int i = 0; i < _tabs.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(width: 6),
                        _DesktopMsgTabPill(
                          label: _tabs[i].meta.label,
                          unreadCount: _tabs[i].unreadCount,
                          selected: _controller.index == i,
                          onTap: () => _controller.animateTo(i),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (entries.isNotEmpty) ...<Widget>[
                const SizedBox(width: 8),
                for (int i = 0; i < entries.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 6),
                  _DesktopNotifyPill(
                    entry: entries[i],
                    onTap: () => _openEntry(entries[i]),
                  ),
                ],
              ],
              if (reminder.bellVisible) ...<Widget>[
                const SizedBox(width: 4),
                Tooltip(
                  message: '消息提醒设置',
                  child: InkWell(
                    key: _desktopReminderKey,
                    borderRadius: BorderRadius.circular(9),
                    onTap: _openDesktopReminderSheet,
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: Icon(
                        Icons.settings_outlined,
                        size: 16,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// 铃铛常驻搜索栏右侧；红点只提示被隐藏的未读 / 新广播。
  Widget? _bell() {
    final NotificationReminder reminder = NotificationReminder.instance;
    if (!reminder.bellVisible) return null;
    return ReminderBell(
      showDot: reminder.bellDot,
      onTap: () => showReminderSheet(context),
    );
  }

  /// 提醒区：分组头 + 按数据生成的行；默认展开。
  Widget _reminderArea({bool desktop = false}) {
    final NotificationReminder reminder = NotificationReminder.instance;
    if (!reminder.reminderVisible) return const SizedBox.shrink();
    final List<NotifyEntry> entries = reminder.visibleEntries;

    return Padding(
      padding: desktop
          ? const EdgeInsets.only(bottom: 12)
          : const EdgeInsets.fromLTRB(
              TiebananaMetrics.pageGutter, 0, TiebananaMetrics.pageGutter, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          NotifySectionHeader(
            title: '通知',
            meta: reminder.sectionMeta,
            showDot: reminder.visibleBroadcastDot,
            expanded: _reminderExpanded,
            onToggle: () =>
                setState(() => _reminderExpanded = !_reminderExpanded),
            onHide: _hideReminder,
          ),
          if (_reminderExpanded) ...<Widget>[
            for (final NotifyEntry entry in entries) ...<Widget>[
              NotifyEntryRow(entry: entry, onTap: () => _openEntry(entry)),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  void _openEntry(NotifyEntry entry) {
    switch (entry.kind) {
      case NotifyEntryKind.mutualHelp:
        openMutualHelp(context);
      case NotifyEntryKind.broadcast:
        openBroadcastFeed(context);
    }
  }

  void _hideReminder() {
    final ReminderVisibilitySnapshot snapshot =
        NotificationReminder.instance.hideAll();
    final ScaffoldMessengerState? messenger =
        ScaffoldMessenger.maybeOf(context);
    messenger
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('提醒已隐藏'),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () => NotificationReminder.instance.restore(snapshot),
          ),
        ),
      );
  }

  /// 页签栏：药丸选中态 + 该页签的未读数。
  Widget _tabHeader(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(TiebananaMetrics.gapLg, 0,
          TiebananaMetrics.gapLg, TiebananaMetrics.gapSm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TabBar(
              controller: _controller,
              // 药丸左右各外扩 14、高度由指示器定（32）；页签栏就给药丸那么高，
              // 所以 Tab 传 tabHeight（30 → 页签栏 32，药丸正好填满，一点不多占）。
              // labelPadding 留 17 是为了相邻两颗药丸之间还剩 6 的缝，不至于叠在一起。
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 17),
              indicatorSize: TabBarIndicatorSize.label,
              indicator:
                  TiebananaPillTabIndicator(color: tokens.primaryContainer),
              labelColor: tokens.onPrimaryContainer,
              unselectedLabelColor: tokens.textSecondary,
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              tabs: _tabs
                  .map((_TabState tab) => Tab(
                      height: TiebananaPillTabIndicator.tabHeight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(tab.meta.label),
                          if (tab.unreadCount > 0) ...<Widget>[
                            const SizedBox(width: 4),
                            Badge.count(count: tab.unreadCount, maxCount: 99),
                          ],
                        ],
                      )))
                  .toList(),
            ),
          ),
          // 未读数跟着页签走，所以要跟着 TabController 重建。
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              final int count = _tabs[_controller.index].unreadCount;
              if (count <= 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(left: TiebananaMetrics.gapSm),
                child: Text.rich(
                  TextSpan(
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: tokens.textTertiary),
                    children: <InlineSpan>[
                      const TextSpan(text: "未读 "),
                      TextSpan(
                        text: "$count",
                        style: TextStyle(
                            color: tokens.primary,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures()
                            ]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _body(
    _TabState tab, {
    bool desktop = false,
    double horizontalPadding = TiebananaMetrics.pageGutter,
  }) {
    if (tab.meta.kind == null) {
      return PrivateMessagePanel(
        onBrowse: widget.onBrowse,
        refreshSignal: _listRefresh,
      );
    }
    return MessageFeed(
      meta: tab.meta,
      items: tab.items,
      loading: tab.loading,
      error: tab.error,
      notLoggedIn: tab.error != null && tab.error.toString().contains("未登录"),
      loadingMore: tab.loadingMore,
      moreError: tab.moreError,
      scrollController: tab.scroll,
      onRefresh: () => _refresh(tab),
      onRetry: () => _retry(tab),
      onLoadMore: () => _nextPage(tab),
      onBrowse: widget.onBrowse,
      onRead: (TiebaMessage message) => _markRead(tab, message),
      desktop: desktop,
      horizontalPadding: horizontalPadding,
      header: desktop ? _reminderArea(desktop: true) : null,
    );
  }
}

/// 一页消息。
///
///首次加载放在 `initState`：TabBarView 只会把「当前这一页」真正建出来，
///所以三个页签里只有切过去的那个会发请求（在拼 children 列表时触发就全打出去了）。
class _TabPage extends StatefulWidget {
  const _TabPage({required this.onStart, required this.child});

  final VoidCallback onStart;
  final Widget child;

  @override
  State<_TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<_TabPage> {
  @override
  void initState() {
    super.initState();
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// 一个页签的数据与加载状态。三个页签各持一份，互不干扰。
class _TabState {
  _TabState(this.meta);

  final MessageTabMeta meta;
  final List<TiebaMessage> items = <TiebaMessage>[];
  final ScrollController scroll = ScrollController();

  int pn = 1;
  bool hasMore = false;

  /// 首屏加载中（已有内容时交给 RefreshIndicator）。
  bool loading = true;

  /// 翻页加载中 / 首屏错误 / 翻页错误。
  bool loadingMore = false;
  Object? error;
  Object? moreError;

  bool refreshing = false;

  /// 惰性加载：第一次显示这个页签才发请求。
  bool started = false;

  int get unreadCount => meta.kind == null
      ? MessageReminder.chatUnread.value
      : MessageReminder.counts.value.count(meta.kind!);
}

/// 消息列表的展示层：骨架 / 空 / 错误 / 未登录 / 列表。
///
///纯展示组件，数据和回调由 [MessagePan] 传入，便于单独渲染与测试。
class MessageFeed extends StatelessWidget {
  const MessageFeed({
    super.key,
    required this.meta,
    required this.items,
    required this.loading,
    required this.error,
    required this.notLoggedIn,
    required this.loadingMore,
    required this.moreError,
    required this.scrollController,
    required this.onRefresh,
    required this.onRetry,
    required this.onLoadMore,
    this.onBrowse,
    this.onRead,
    this.desktop = false,
    this.horizontalPadding = TiebananaMetrics.pageGutter,
    this.header,
  });

  final MessageTabMeta meta;
  final List<TiebaMessage> items;
  final bool loading;
  final Object? error;
  final bool notLoggedIn;
  final bool loadingMore;
  final Object? moreError;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  /// 空态的「去逛逛」：切到首页页签。为空时隐藏按钮。
  final VoidCallback? onBrowse;
  final void Function(TiebaMessage message)? onRead;
  final bool desktop;
  final double horizontalPadding;
  final Widget? header;

  Widget _wrapMax(Widget child) {
    if (!desktop) return child;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.feedMaxWidth),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) {
      return _sheet(
        context,
        _MessageSkeletonList(desktop: desktop),
        center: false,
      );
    }
    if (error != null && items.isEmpty) {
      return _sheet(context, _errorView(context));
    }
    if (items.isEmpty) {
      return _sheet(context, _emptyView(context));
    }
    final bool hasHeader = desktop && header != null;
    final bool showFooter = loadingMore || moreError != null;
    final int leading = hasHeader ? 1 : 0;
    return TiebananaRefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: desktop
            ? EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 26)
            : const EdgeInsets.only(bottom: TiebananaMetrics.gapMd),
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: leading + items.length + (showFooter ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (hasHeader && index == 0) {
            return _wrapMax(header!);
          }
          final int itemIndex = index - leading;
          if (itemIndex >= items.length) {
            return _wrapMax(_footer(context));
          }
          final TiebaMessage message = items[itemIndex];
          return _wrapMax(MessageCard(
            message: message,
            desktop: desktop,
            onRead: onRead == null ? null : () => onRead!(message),
          ));
        },
      ),
    );
  }

  ///状态页也要能下拉刷新：撑满可视高度再居中。
  ///
  ///骨架屏不居中（[center] = false）：它模拟列表，从顶部往下铺更贴近内容到达后的样子。
  Widget _sheet(BuildContext context, Widget child, {bool center = true}) {
    final Widget bodyChild = _wrapMax(child);
    return TiebananaRefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: scrollController,
            padding: desktop
                ? EdgeInsets.fromLTRB(
                    horizontalPadding, 16, horizontalPadding, 26)
                : EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - (desktop ? 42 : 0))
                    .clamp(0.0, double.infinity),
              ),
              child: desktop && header != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _wrapMax(header!),
                        center
                            ? Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: bodyChild,
                              )
                            : bodyChild,
                      ],
                    )
                  : (center ? Center(child: bodyChild) : bodyChild),
            ),
          );
        },
      ),
    );
  }

  Widget _errorView(BuildContext context) {
    if (notLoggedIn) {
      return StateView(
        icon: Icons.person_outline,
        title: "登录后才能看消息",
        body: "消息需要登录才返回内容",
        primaryLabel: "去登录",
        onPrimary: () => Navigator.pushNamed(context, PageRouter.login),
      );
    }
    return StateView(
      icon: Icons.wifi_off_rounded,
      title: "网络似乎有点问题",
      body: "检查一下网络连接后重试\n已经加载过的内容仍可离线查看",
      primaryLabel: "重试",
      primaryIcon: Icons.refresh,
      onPrimary: onRetry,
    );
  }

  Widget _emptyView(BuildContext context) {
    return StateView(
      icon: meta.emptyIcon,
      title: meta.emptyTitle,
      body: meta.emptyBody,
      primaryLabel: onBrowse == null ? null : "去逛逛",
      onPrimary: onBrowse,
    );
  }

  ///翻页的加载 / 失败提示，接在列表最下方。
  Widget _footer(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    if (moreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: TiebananaMetrics.gapMd),
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onLoadMore,
            child: Text(
              "加载失败，点击重试",
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: tokens.primary),
            ),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: TiebananaMetrics.gapLg),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

///首屏骨架：三张卡片，形状与 [MessageCard] 对齐。
class _MessageSkeletonList extends StatelessWidget {
  const _MessageSkeletonList({this.desktop = false});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    //用 Column 排版，外层 _sheet 已是滚动容器。
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _MessageSkeletonCard(desktop: desktop),
        _MessageSkeletonCard(desktop: desktop),
        _MessageSkeletonCard(desktop: desktop),
      ],
    );
  }
}

class _MessageSkeletonCard extends StatelessWidget {
  const _MessageSkeletonCard({this.desktop = false});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      margin: EdgeInsets.fromLTRB(
        desktop ? 0 : TiebananaMetrics.pageGutter,
        0,
        desktop ? 0 : TiebananaMetrics.pageGutter,
        desktop ? 10 : TiebananaMetrics.gapSm,
      ),
      padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              SkeletonBox(
                  width: TiebananaMetrics.avatarSm,
                  height: TiebananaMetrics.avatarSm,
                  radius: TiebananaMetrics.avatarSm / 2),
              SizedBox(width: TiebananaMetrics.gapSm),
              SkeletonBox(width: 86),
              SizedBox(width: TiebananaMetrics.gapSm),
              SkeletonBox(width: 50),
            ],
          ),
          const SizedBox(height: TiebananaMetrics.gapMd),
          const SkeletonBox(height: 40, radius: TiebananaMetrics.radiusSm),
          const SizedBox(height: TiebananaMetrics.gapSm),
          const SkeletonBox(height: 11),
          const SizedBox(height: TiebananaMetrics.gapXs + 2),
          const FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.62,
            child: SkeletonBox(height: 11),
          ),
        ],
      ),
    );
  }
}

class _DesktopMsgTabPill extends StatelessWidget {
  const _DesktopMsgTabPill({
    required this.label,
    required this.unreadCount,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int unreadCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Material(
      color: selected ? tokens.primaryContainer : Colors.transparent,
      borderRadius: TiebananaMetrics.brPill,
      child: InkWell(
        borderRadius: TiebananaMetrics.brPill,
        hoverColor: tokens.fill,
        onTap: onTap,
        child: SizedBox(
          height: 30,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? tokens.onPrimaryContainer
                            : tokens.textSecondary,
                      ),
                ),
                if (unreadCount > 0) ...<Widget>[
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: tokens.danger,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: TextStyle(
                        color: tokens.onImage,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopNotifyPill extends StatelessWidget {
  const _DesktopNotifyPill({
    required this.entry,
    required this.onTap,
  });

  final NotifyEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final IconData icon = switch (entry.kind) {
      NotifyEntryKind.mutualHelp => Icons.people_outline_rounded,
      NotifyEntryKind.broadcast => Icons.notifications_none_rounded,
    };
    return Material(
      color: tokens.fill,
      borderRadius: TiebananaMetrics.brPill,
      child: InkWell(
        borderRadius: TiebananaMetrics.brPill,
        onTap: onTap,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: TiebananaMetrics.brPill,
            border: Border.all(color: tokens.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 13, color: tokens.textSecondary),
              const SizedBox(width: 5),
              Text(
                entry.title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tokens.textSecondary,
                    ),
              ),
              if (entry.badge == NotifyBadgeKind.count &&
                  entry.count > 0) ...<Widget>[
                const SizedBox(width: 5),
                Container(
                  constraints: const BoxConstraints(minWidth: 15),
                  height: 15,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: tokens.danger,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.count > 99 ? '99+' : '${entry.count}',
                    style: TextStyle(
                      color: tokens.onImage,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ] else if (entry.badge == NotifyBadgeKind.dot) ...<Widget>[
                const SizedBox(width: 5),
                Semantics(
                  label: '有新公告',
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: tokens.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
