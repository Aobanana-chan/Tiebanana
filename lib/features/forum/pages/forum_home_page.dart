import 'package:tiebanana/features/compose/models/thread_compose_route_data.dart';
import 'dart:math';

import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/shared/controllers/app_bar_title.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/extended_nested_scroll_view_wrapper.dart';
import 'package:tiebanana/shared/widgets/keep_alive_wrapper.dart';
import 'package:tiebanana/shared/widgets/pull_to_refresh_notification.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';
import 'package:tiebanana/features/forum/widgets/forum_control_bar.dart';
import 'package:tiebanana/features/forum/widgets/forum_feed_card.dart';
import 'package:tiebanana/features/forum/widgets/forum_header.dart';
import 'package:tiebanana/features/forum/widgets/forum_tab_bar.dart';
import 'package:tiebanana/shared/widgets/glow_notification_widget.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/features/forum/widgets/top_thread.dart';

///吧页面。
///
/// 页签是数据驱动的：服务端下发几个（`frs_main_tab_list`，实现方已筛成可用项）
/// 就排几个，看帖 / 热门 / 精品由协议数据决定。每个页签各自持有列表 / 页码 / 状态，
/// 切页签不重拉，下拉只刷当前页签。
class ForumHomePage extends StatefulWidget {
  ///吧名
  final String kw;
  const ForumHomePage({super.key, required this.kw});

  @override
  State<ForumHomePage> createState() => _ForumHomePageState();
}

///一个页签的独立状态。
class _ForumTabState {
  _ForumTabState(this.tab) : sortValue = _defaultSort(tab);

  final TiebaForumTab tab;
  List<TiebaThreadInfo> threads = <TiebaThreadInfo>[];
  bool isCardFeed = false;
  int pn = 1;
  bool hasMore = true;
  bool loading = false;
  bool loaded = false;
  Object? error;
  int sortValue;
  int partitionValue = 0;
  String? subTab;

  static int _defaultSort(TiebaForumTab tab) =>
      tab.sortMenu.isEmpty ? 0 : tab.sortMenu.first.value;
}

class _ForumHomePageState extends State<ForumHomePage>
    with SingleTickerProviderStateMixin {
  late ScrollController innerController;
  late ScrollController outerController;
  TabController? tabbarController;

  ///页面标题（滚动到吧头卡片消失后才出现）。
  final APPBarTitle _appBarTitle = APPBarTitle();

  ///用于量出吧头卡片的实际高度（会随用户字号变化），据此决定标题何时淡入。
  final GlobalKey _headerKey = GlobalKey();
  bool _outerListenerAttached = false;
  late RenderBox overlay;

  Future<ForumPage>? initForum;
  ForumPage? _forumPage;
  List<_ForumTabState> _tabs = <_ForumTabState>[];
  int _tabIndex = 0;

  ///服务端上下文，翻页 / 切页签时回传。
  String _frsCommonInfo = '';
  String _topCardId = '';

  final double maxDragOffset = 80.0;

  void init() {
    initForum = Global.tiebaAPI.getForumPage(kw: widget.kw, pn: 1);
  }

  @override
  void initState() {
    super.initState();
    overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    init();
  }

  @override
  void dispose() {
    if (_outerListenerAttached) {
      outerController.removeListener(_onOuterScroll);
    }
    tabbarController?.dispose();
    super.dispose();
  }

  // ── 数据 ────────────────────────────────────────────────────────────────

  /// 首屏数据到达：建页签状态、选默认页签（首屏列表直接复用）。
  void _bootstrap(ForumPage data) {
    _forumPage = data;
    _frsCommonInfo = data.frsCommonInfo;
    _topCardId = data.topCardId;
    _tabs = <_ForumTabState>[
      for (final TiebaForumTab t in data.tabs) _ForumTabState(t),
    ];
    if (_tabs.isEmpty) {
      tabbarController = TabController(length: 0, vsync: this);
      return;
    }

    // 首屏响应带的是「服务端默认页签」的列表，未必是下面要选中的那个页签。
    // 列表填默认页签，TabController 的起点与 _tabIndex 保持一致，
    // 避免停在另一个页签的空状态。
    int defaultIndex = _tabs.indexWhere((_ForumTabState s) => s.tab.isDefault);
    if (defaultIndex < 0) defaultIndex = 0;

    // 选中页签：上次停留的页签 → 服务端默认页签 → 第一项。
    final String savedTab = Global.profile.getString(_lastTabKey) ?? '';
    int index = defaultIndex;
    if (savedTab.isNotEmpty) {
      final int saved =
          _tabs.indexWhere((_ForumTabState s) => s.tab.id == savedTab);
      if (saved >= 0) index = saved;
    }
    _tabIndex = index;

    for (final _ForumTabState s in _tabs) {
      final int? savedSort = Global.profile.getInt(_sortKey(s.tab));
      if (savedSort != null) s.sortValue = savedSort;
    }

    final bool hasInitialThreads = data.threads.isNotEmpty;
    final _ForumTabState initial = _tabs[defaultIndex];
    initial
      ..threads = data.threads
      ..isCardFeed = data.isCardFeed
      ..pn = data.page.currentPage
      ..hasMore = data.page.hasMore
      // 空列表暂不视为已加载：部分吧的首屏请求需要带上页签才会返回帖子，
      // 先显示骨架，待补拉完成后再展示。
      ..loaded = hasInitialThreads;

    tabbarController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: index,
    )..addListener(_onTabTick);

    // 首屏只填了默认页签；上次停留的页签 / 空首屏都要在进页面后补拉。
    final Set<int> pending = <int>{
      if (index != defaultIndex) index,
      if (!hasInitialThreads) defaultIndex,
    };
    if (pending.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final int i in pending) {
          _ensureTab(i);
        }
      });
    }
  }

  void _onTabTick() {
    final TabController? controller = tabbarController;
    if (controller == null) return;
    final int index = controller.index;
    if (index == _tabIndex) return;
    setState(() => _tabIndex = index);
    _ensureTab(index);
    Global.profile.setString(_lastTabKey, _tabs[index].tab.id);
  }

  void _ensureTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    final _ForumTabState s = _tabs[index];
    if (!s.loaded && !s.loading) {
      _fetch(index, refresh: true);
    }
  }

  /// 拉取一个页签。[refresh] 重新从第 1 页拉（替换），否则按 `pn + 1` 追加。
  Future<void> _fetch(int index, {bool refresh = false}) async {
    if (index < 0 || index >= _tabs.length) return;
    final _ForumTabState s = _tabs[index];
    if (s.loading) return;
    final int pn = refresh ? 1 : s.pn + 1;
    if (!refresh && !s.hasMore && s.loaded) return;

    setState(() {
      s.loading = true;
      s.error = null;
    });
    try {
      final ForumPage page = await Global.tiebaAPI.getForumPage(
        kw: widget.kw,
        pn: pn,
        rn: 30,
        sortType: s.sortValue,
        isgood: s.tab.isGoodTab,
        cid: int.tryParse(s.subTab ?? '') ?? 0,
        tab: s.tab,
        partitionType: s.partitionValue,
        frsCommonInfo: _frsCommonInfo,
        topCardId: _topCardId,
      );
      if (page.frsCommonInfo.isNotEmpty) _frsCommonInfo = page.frsCommonInfo;
      if (page.topCardId.isNotEmpty) _topCardId = page.topCardId;
      if (!mounted) return;
      setState(() {
        s.threads = (refresh || !s.loaded)
            ? page.threads
            : <TiebaThreadInfo>[...s.threads, ...page.threads];
        s.isCardFeed = page.isCardFeed;
        s.pn = page.page.currentPage;
        s.hasMore = page.page.hasMore;
        s.loaded = true;
        s.loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        s.loading = false;
        s.error = e;
      });
    }
  }

  void _onSortChange(int value) {
    final _ForumTabState s = _tabs[_tabIndex];
    setState(() => s.sortValue = value);
    Global.profile.setInt(_sortKey(s.tab), value);
    _fetch(_tabIndex, refresh: true);
  }

  void _onPartitionChange(int value) {
    final _ForumTabState s = _tabs[_tabIndex];
    setState(() => s.partitionValue = value);
    _fetch(_tabIndex, refresh: true);
  }

  void _onSubTabChange(String classId) {
    final _ForumTabState s = _tabs[_tabIndex];
    setState(() => s.subTab = classId);
    _fetch(_tabIndex, refresh: true);
  }

  String _sortKey(TiebaForumTab tab) =>
      'forumSort.${_forumPage?.forum.fid ?? widget.kw}.${tab.id}';

  String get _lastTabKey => 'forumTab.${_forumPage?.forum.fid ?? widget.kw}';

  List<Widget> buildAction() {
    return <Widget>[
      IconButton(
          tooltip: "吧内搜索",
          onPressed: () => Navigator.pushNamed(context, PageRouter.forumSearch,
              arguments: widget.kw),
          icon: const Icon(Icons.search)),
      IconButton(
          onPressed: () {
            final ForumPage? page = _forumPage;
            if (page == null) return;
            showMenu(
                context: context,
                position: RelativeRect.fromLTRB(overlay.size.width - 100, 0,
                    overlay.size.width, overlay.size.height),
                shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                items: <PopupMenuEntry<Object>>[
                  PopupMenuItem(
                    onTap: () async {
                      if (page.forum.isLike) {
                        Global.tiebaAPI.unfavoForum(
                            fid: page.forum.fid, forumName: page.forum.name);
                      } else {
                        Global.tiebaAPI.favoForum(
                            page.forum.fid, page.forum.name);
                      }
                    },
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(page.forum.isLike ? "取消关注" : "关注"),
                    ),
                  ),
                  const PopupMenuItem(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("分享"),
                    ),
                  ),
                ]);
          },
          icon: const Icon(Icons.more_vert)),
    ];
  }

  ///滚动到吧头卡片差不多消失时，标题栏才淡入。
  void _onOuterScroll() {
    if (!outerController.hasClients) {
      return;
    }
    final double headerHeight =
        _headerKey.currentContext?.size?.height ?? 108;
    final bool scrolledAway =
        outerController.offset > headerHeight - TiebananaMetrics.gapXXl - 8;
    _appBarTitle.title = scrolledAway ? "${widget.kw}吧" : "";
  }

  AppBar _appBar(TiebananaTokens tokens, {List<Widget>? actions}) {
    return AppBar(
      backgroundColor: tokens.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: tokens.textPrimary,
      actions: actions ?? buildAction(),
      title: Consumer<APPBarTitle>(
        builder: (context, value, child) {
          return AnimatedOpacity(
            alwaysIncludeSemantics: true,
            opacity: value.getTitle == "" ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
                onTap: () {
                  outerController.animateTo(0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeIn);
                },
                child: Text("${widget.kw}吧",
                    overflow: TextOverflow.ellipsis)),
          );
        },
      ),
    );
  }

  Widget _shell(BuildContext context,
      {required Widget body, PreferredSizeWidget? appBar, Widget? fab}) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: appBar,
      floatingActionButton: fab,
      body: body,
    );
  }

  Widget _fab(TiebananaTokens tokens) {
    return FloatingActionButton(
      tooltip: '发帖',
      onPressed: _forumPage == null ? null : () async {
        if (!Global.tiebaAPI.isLogin) {
          await Navigator.pushNamed(context, PageRouter.login);
          if (!mounted || !Global.tiebaAPI.isLogin) return;
        }
        if (!mounted) return;
        final page = _forumPage;
        if (page == null) return;
        await Navigator.pushNamed(context, PageRouter.threadCompose,
          arguments: ThreadComposeRouteData(fid: page.forum.fid,
              forumName: widget.kw));
      },
      backgroundColor: tokens.primaryContainer,
      foregroundColor: tokens.onPrimaryContainer,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: TiebananaMetrics.brLg),
      child: const Icon(Icons.edit_outlined),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return ChangeNotifierProvider.value(
      value: _appBarTitle,
      child: FutureBuilder<ForumPage>(
        future: initForum,
        initialData: null,
        builder: (BuildContext context, AsyncSnapshot<ForumPage?> snapshot) {
          if (snapshot.hasError) {
            return _shell(context,
                appBar: _appBar(tokens, actions: const <Widget>[]),
                body: Center(
                  child: StateView(
                    icon: Icons.wifi_off_rounded,
                    title: "进不去这个吧",
                    body: "检查一下网络，或者稍后再试",
                    primaryLabel: "重试",
                    primaryIcon: Icons.refresh,
                    onPrimary: () => setState(init),
                  ),
                ));
          }
          if (!snapshot.hasData) {
            return _shell(context,
                appBar: _appBar(tokens, actions: const <Widget>[]),
                fab: _fab(tokens),
                body: const ForumSkeleton());
          }
          if (_forumPage == null) {
            _bootstrap(snapshot.data!);
          }
          if (_tabs.isEmpty) {
            return _shell(context,
                appBar: _appBar(tokens),
                fab: _fab(tokens),
                body: const Center(
                  child: StateView(
                    icon: Icons.forum_outlined,
                    title: "这个吧还没有页签",
                    body: "过一会儿再来看看",
                  ),
                ));
          }
          return _shell(context,
              appBar: _appBar(tokens), fab: _fab(tokens), body: _body(context));
        },
      ),
    );
  }

  Widget _body(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final ForumPage page = _forumPage!;
    final _ForumTabState current = _tabs[_tabIndex];
    return Container(
      color: tokens.bg,
      child: KeepAliveWrapper(
        child: ExtendedNestedScrollView(
          onlyOneScrollInBody: true,
          floatHeaderSlivers: false,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverToBoxAdapter(
                child: ForumHeader(
                  key: _headerKey,
                  avatar: page.forum.avatar,
                  fName: page.forum.name,
                  levelupScore: page.forum.levelupScore,
                  curScore: page.forum.curScore,
                  isLike: page.forum.isLike,
                  isSigned: page.forum.isSigned,
                  fid: page.forum.fid,
                  levelId: page.forum.levelId,
                  levelName: page.forum.levelName,
                  memberNum: page.forum.memberNum,
                  postNum: page.forum.postNum,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedTabsDelegate(
                  extent: ForumTabBar.height +
                      ForumControlBar.heightOf(current.tab),
                  child: Container(
                    color: tokens.bg,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ForumTabBar(
                          tabs: <TiebaForumTab>[
                            for (final _ForumTabState s in _tabs) s.tab,
                          ],
                          index: _tabIndex,
                          onSelect: (int i) => tabbarController?.animateTo(i),
                        ),
                        ForumControlBar(
                          sortMenu: current.tab.sortMenu,
                          sortValue: current.sortValue,
                          onSortChange: _onSortChange,
                          partitionMenu: current.tab.partitionMenu,
                          partitionValue: current.partitionValue,
                          onPartitionChange: _onPartitionChange,
                          subTabs:
                              current.tab.isGoodTab ? current.tab.subTabs : const [],
                          subTab: current.subTab,
                          onSubTabChange: _onSubTabChange,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: ExtendedNestedScrollViewInject(
            initCallback: (state) {
              innerController = state.innerController;
              if (_outerListenerAttached) {
                outerController.removeListener(_onOuterScroll);
              }
              outerController = state.outerController;
              outerController.addListener(_onOuterScroll);
              _outerListenerAttached = true;
            },
            child: TabBarView(
              controller: tabbarController,
              children: <Widget>[
                for (int i = 0; i < _tabs.length; i++) _tabView(i),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabView(int index) {
    final _ForumTabState s = _tabs[index];
    return KeepAliveWrapper(
      child: PullToRefreshNotification(
        onRefresh: () async {
          await _fetch(index, refresh: true);
          return true;
        },
        maxDragOffset: maxDragOffset,
        child: GlowNotificationWidget(Column(
          children: <Widget>[
            PullToRefreshContainer((info) {
              final double offset = info?.dragOffset ?? 0.0;
              double width = min(48, offset);
              return SizedBox(
                height: offset,
                width: width,
                child: Center(
                  child: RefreshProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        TiebananaTokens.of(context).primary),
                    strokeWidth: 2.0,
                  ),
                ),
              );
            }),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  if (notification.metrics.axis != Axis.vertical) return false;
                  final ScrollMetrics m = notification.metrics;
                  if (m.maxScrollExtent > 0 &&
                      m.pixels >= m.maxScrollExtent - m.viewportDimension) {
                    _fetch(index);
                  }
                  return false;
                },
                child: CustomScrollView(
                  key: PageStorageKey<String>('forum-tab-${s.tab.id}'),
                  slivers: _tabSlivers(index),
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }

  List<Widget> _tabSlivers(int index) {
    final _ForumTabState s = _tabs[index];
    if (s.error != null && s.threads.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: StateView(
            icon: Icons.wifi_off_rounded,
            title: "这个页签没加载出来",
            body: "检查一下网络，或者稍后再试",
            primaryLabel: "重试",
            primaryIcon: Icons.refresh,
            onPrimary: () => _fetch(index, refresh: true),
          ),
        ),
      ];
    }
    if (!s.loaded) {
      return const <Widget>[
        SliverToBoxAdapter(child: _ThreadSkeletonList()),
      ];
    }
    if (s.threads.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: StateView(
            icon: s.tab.isGoodTab
                ? Icons.star_border_rounded
                : Icons.forum_outlined,
            title: s.tab.isGoodTab ? "还没有精品帖" : "这个吧还没有帖子",
            body: s.tab.isGoodTab ? "这个吧的精品区还是空的" : "换个页签逛逛，或者过一会儿再来",
          ),
        ),
      ];
    }
    final List<TiebaThreadInfo> items = s.threads;
    return <Widget>[
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int i) => _threadItem(items[i], s),
          childCount: items.length,
        ),
      ),
      SliverToBoxAdapter(child: _listFooter(s)),
    ];
  }

  /// 同一张卡按列表形态分派：卡片流用 [ForumFeedCard]，帖子流用 [ThreadSummary]。
  Widget _threadItem(TiebaThreadInfo item, _ForumTabState s) {
    if (item.isTop) {
      return TopThread(tid: item.id, title: item.title);
    }
    if (s.isCardFeed) {
      return ForumFeedCard(item: item);
    }
    return ThreadSummary(
      firstPostContent: item.firstPostContent,
      author: item.author,
      createTime: item.createTime,
      latestTime: item.lastTimeInt,
      tid: item.id,
      fname: item.fname,
      viewNum: item.viewNum,
      title: item.title,
      agreeNum: item.agreeNum,
      disagreeNum: item.disagreeNum,
      replyNum: item.replyNum,
    );
  }

  Widget _listFooter(_ForumTabState s) {
    if (s.loading) {
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
    if (!s.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(
            vertical: TiebananaMetrics.gapLg, horizontal: 12),
        child: Center(
          child: Text(
            "没有更多了",
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: TiebananaTokens.of(context).textTertiary),
          ),
        ),
      );
    }
    return const SizedBox(height: TiebananaMetrics.gapXl);
  }
}

/// 吸顶的「页签 + 控件」两行头。
class _PinnedTabsDelegate extends SliverPersistentHeaderDelegate {
  _PinnedTabsDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox(height: extent, child: child);

  @override
  bool shouldRebuild(covariant _PinnedTabsDelegate old) => true;
}

///吧页首屏骨架。
///
///与真实页面同构（吧头卡 → 页签条 → 控件行 → 置顶行 → 帖子卡），间距 /
///圆角 / 卡片形状保持一致。
class ForumSkeleton extends StatelessWidget {
  const ForumSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: TiebananaMetrics.gapMd),
      children: const <Widget>[
        _HeaderSkeleton(),
        _ControlBarSkeleton(),
        _TopThreadSkeleton(),
        _ThreadSkeletonList(),
      ],
    );
  }
}

///吧头卡骨架：方形吧头像 + 吧名 / 计数 / 进度 / 等级四行 + 右侧药丸按钮。
class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(TiebananaMetrics.pageGutter,
          TiebananaMetrics.gapMd, TiebananaMetrics.pageGutter, 0),
      padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brXl,
        boxShadow: tokens.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const <Widget>[
          SkeletonBox(
              width: 52, height: 52, radius: TiebananaMetrics.radiusCtl),
          SizedBox(width: TiebananaMetrics.gapMd),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SkeletonLine(lineHeight: 26, barHeight: 14, width: 96),
                SizedBox(height: 3),
                _SkeletonLine(lineHeight: 17, barHeight: 11, width: 152),
                SizedBox(height: 7),
                SkeletonBox(height: 6, radius: TiebananaMetrics.radiusPill),
                SizedBox(height: 5),
                _SkeletonLine(lineHeight: 17, barHeight: 11, width: 128),
              ],
            ),
          ),
          SizedBox(width: TiebananaMetrics.gapMd),
          SkeletonBox(
              width: 54, height: 32, radius: TiebananaMetrics.radiusPill),
        ],
      ),
    );
  }
}

///控制栏骨架：页签药丸 + 右侧「更多」+ 一行排序药丸。
class _ControlBarSkeleton extends StatelessWidget {
  const _ControlBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(TiebananaMetrics.pageGutter, 10,
          TiebananaMetrics.pageGutter, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SkeletonBox(
                  width: 58, height: 31, radius: TiebananaMetrics.radiusPill),
              SizedBox(width: 6),
              SkeletonBox(
                  width: 52, height: 31, radius: TiebananaMetrics.radiusPill),
              SizedBox(width: 6),
              SkeletonBox(
                  width: 52, height: 31, radius: TiebananaMetrics.radiusPill),
              SizedBox(width: 6),
              SkeletonBox(
                  width: 72, height: 31, radius: TiebananaMetrics.radiusPill),
              Spacer(),
              SkeletonBox(
                  width: 32, height: 32, radius: TiebananaMetrics.radiusPill),
            ],
          ),
          SizedBox(height: 8),
          SkeletonBox(
              width: 96, height: 26, radius: TiebananaMetrics.radiusPill),
        ],
      ),
    );
  }
}

///置顶帖骨架：实心「置顶」标签 + 两行标题，与 [TopThread] 同构。
class _TopThreadSkeleton extends StatelessWidget {
  const _TopThreadSkeleton();

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          SkeletonBox(width: 34, height: 18, radius: TiebananaMetrics.radiusXs),
          SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SkeletonLine(lineHeight: 24, barHeight: 14),
                _SkeletonLine(lineHeight: 24, barHeight: 14, widthFactor: 0.58),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

///帖子卡骨架列表（首屏 / 页签加载中共用）。
class _ThreadSkeletonList extends StatelessWidget {
  const _ThreadSkeletonList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ThreadSkeletonCard(),
        _ThreadSkeletonCard(),
        _ThreadSkeletonCard(),
      ],
    );
  }
}

///帖子卡骨架：与 [ThreadSummary] 同构。
class _ThreadSkeletonCard extends StatelessWidget {
  const _ThreadSkeletonCard();

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
        children: const <Widget>[
          Row(
            children: <Widget>[
              SkeletonBox(
                  width: TiebananaMetrics.avatarSm,
                  height: TiebananaMetrics.avatarSm,
                  radius: TiebananaMetrics.avatarSm / 2),
              SizedBox(width: TiebananaMetrics.gapSm),
              SkeletonBox(width: 78, height: 13),
              SizedBox(width: TiebananaMetrics.gapSm),
              SkeletonBox(width: 44, height: 11),
            ],
          ),
          SizedBox(height: TiebananaMetrics.gapSm),
          _SkeletonLine(lineHeight: 24, barHeight: 14),
          _SkeletonLine(lineHeight: 24, barHeight: 14, widthFactor: 0.62),
          SizedBox(height: TiebananaMetrics.gapXs),
          _SkeletonLine(lineHeight: 23, barHeight: 11),
          _SkeletonLine(lineHeight: 23, barHeight: 11, widthFactor: 0.74),
          SizedBox(height: TiebananaMetrics.gapSm),
          SizedBox(
            height: 70,
            child: Row(
              children: <Widget>[
                Expanded(
                    child: SkeletonBox(
                        height: 70, radius: TiebananaMetrics.radiusSm)),
                SizedBox(width: 5),
                Expanded(
                    child: SkeletonBox(
                        height: 70, radius: TiebananaMetrics.radiusSm)),
                SizedBox(width: 5),
                Expanded(
                    child: SkeletonBox(
                        height: 70, radius: TiebananaMetrics.radiusSm)),
              ],
            ),
          ),
          SizedBox(height: TiebananaMetrics.gapSm),
          Row(
            children: <Widget>[
              SkeletonBox(width: 54, height: 11),
              Spacer(),
              SkeletonBox(width: 32, height: 11),
              SizedBox(width: TiebananaMetrics.gapMd),
              SkeletonBox(width: 32, height: 11),
              SizedBox(width: TiebananaMetrics.gapMd),
              SkeletonBox(width: 32, height: 11),
            ],
          ),
        ],
      ),
    );
  }
}

///一行文字骨架：[lineHeight] 是真实字阶的行盒高度，[barHeight] 是条本身的高度。
class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.lineHeight,
    required this.barHeight,
    this.width,
    this.widthFactor,
  });

  final double lineHeight;
  final double barHeight;
  final double? width;
  final double? widthFactor;

  @override
  Widget build(BuildContext context) {
    const double radius = TiebananaMetrics.radiusXs;
    final Widget bar = widthFactor != null
        ? FractionallySizedBox(
            widthFactor: widthFactor,
            alignment: Alignment.centerLeft,
            child: SkeletonBox(height: barHeight, radius: radius),
          )
        : SkeletonBox(width: width, height: barHeight, radius: radius);
    return SizedBox(
      height: lineHeight,
      child: Align(alignment: Alignment.centerLeft, child: bar),
    );
  }
}
