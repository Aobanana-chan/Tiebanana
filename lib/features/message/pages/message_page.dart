import 'package:flutter/material.dart' hide SearchBar;
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:tiebanana/features/message/state/message_reminder.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
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

  final TiebaMessageKind kind;
  final String label;
  final String emptyTitle;
  final String emptyBody;
  final IconData emptyIcon;
}

const List<MessageTabMeta> messageTabMetas = <MessageTabMeta>[
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
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  late final List<_TabState> _tabs;
  int _selectedTab = 0;

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
  }

  @override
  void dispose() {
    MessageReminder.counts.removeListener(_onReminderChanged);
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

  MessageLoader _loaderOf(_TabState tab) {
    final MessageLoader? injected = widget.loaders?[tab.meta.kind];
    if (injected != null) {
      return injected;
    }
    switch (tab.meta.kind) {
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
    if (tab.refreshing) {
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
      final MessagePageResult page = await _loaderOf(tab).call(1);
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
      if (tab.meta.kind != TiebaMessageKind.like) {
        MessageReminder.clear(tab.meta.kind);
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
    if (tab.loading || tab.loadingMore || !tab.hasMore || !tab.started) {
      return;
    }
    final int next = tab.pn + 1;
    setState(() {
      tab.loadingMore = true;
      tab.moreError = null;
    });
    try {
      final MessagePageResult page = await _loaderOf(tab).call(next);
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
        return Column(
          children: <Widget>[
            SearchBar(
              maxHeight: topConstraints.maxHeight,
              barController: widget.controller,
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => widget.controller.close(),
                child: Column(
                  children: <Widget>[
                    _tabHeader(context),
                    Expanded(
                      child:
                          NotificationListener<OverscrollIndicatorNotification>(
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

  Widget _body(_TabState tab) {
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

  int get unreadCount => MessageReminder.counts.value.count(meta.kind);
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

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) {
      return _sheet(context, const _MessageSkeletonList(), center: false);
    }
    if (error != null && items.isEmpty) {
      return _sheet(context, _errorView(context));
    }
    if (items.isEmpty) {
      return _sheet(context, _emptyView(context));
    }
    final bool showFooter = loadingMore || moreError != null;
    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: TiebananaMetrics.gapMd),
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + (showFooter ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index >= items.length) {
            return _footer(context);
          }
          final TiebaMessage message = items[index];
          return MessageCard(
            message: message,
            onRead: onRead == null ? null : () => onRead!(message),
          );
        },
      ),
    );
  }

  ///状态页也要能下拉刷新：撑满可视高度再居中。
  ///
  ///骨架屏不居中（[center] = false）：它模拟列表，从顶部往下铺更贴近内容到达后的样子。
  Widget _sheet(BuildContext context, Widget child, {bool center = true}) {
    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: center ? Center(child: child) : child,
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
  const _MessageSkeletonList();

  @override
  Widget build(BuildContext context) {
    //用 Column 排版，外层 _sheet 已是滚动容器。
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _MessageSkeletonCard(),
        _MessageSkeletonCard(),
        _MessageSkeletonCard(),
      ],
    );
  }
}

class _MessageSkeletonCard extends StatelessWidget {
  const _MessageSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(TiebananaMetrics.pageGutter, 0,
          TiebananaMetrics.pageGutter, TiebananaMetrics.gapSm),
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
