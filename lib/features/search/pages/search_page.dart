import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';

import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/alert_dialog.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';
import 'package:tiebanana/features/forum/widgets/forum_control_bar.dart';
import 'package:tiebanana/shared/widgets/highlight_text.dart';
import 'package:tiebanana/features/search/widgets/search_bar.dart' show searchHistoryKey;
import 'package:tiebanana/features/search/widgets/search_result_card.dart';
import 'package:tiebanana/shared/content/thread_summary.dart' show Avatar;
import 'package:tiebanana/shared/content/tieba_parser.dart';
import 'package:tiebanana/shared/widgets/tiebanana_tab_indicator.dart';

/// 全站搜索的排序项。值与接口 `st` 一一对应（见 `TiebaApi.searchPost` 的 `order`）。
const List<TiebaForumMenuItem> kSearchSorts = <TiebaForumMenuItem>[
  TiebaForumMenuItem(text: "相关度", value: 2),
  TiebaForumMenuItem(text: "最新", value: 1),
  TiebaForumMenuItem(text: "最早", value: 0),
];

/// 搜索吧。默认走 [Global.tiebaAPI]，测试 / 预览可注入。
typedef SearchForumLoader = Future<SearchForumResult> Function(
    String keyword, int pn);

/// 搜索贴。参数与 [TiebaApi.searchPost] 对齐（全站搜索不带 `fname`）。
typedef SearchPostLoader = Future<SearchPostPage> Function({
  required String keyword,
  required int pn,
  required int order,
  required int filter,
});

/// 搜索用户。
typedef SearchUserLoader = Future<SearchUserResult> Function(String keyword);

/// 综合搜索（吧卡 + 贴卡混排）。
typedef SearchMixedLoader = Future<SearchMixedPage> Function(
    String keyword, int pn);

/// 全站搜索页：综合 / 贴 / 吧 / 人四个页签 + 搜索历史。
///
/// 对应概念图 `design/mockups/search.html`（方向 A）。从首页搜索栏进入，
/// `searchWords` 是首页已经提交的关键词。与吧内搜索（`forum_search.dart`）共用
/// 顶栏与结果卡，差别是这里没有 `fname`，结果跨吧，所以贴卡底部要标来源吧名。
class SearchPage extends StatefulWidget {
  /// 页面打开时预填并立即搜索的关键词。
  final String searchWords;

  /// 初始页签：0 综合 / 1 贴 / 2 吧 / 3 人。默认进入综合。
  final int initialTab;

  final SearchForumLoader? forumLoader;
  final SearchPostLoader? postLoader;
  final SearchUserLoader? userLoader;
  final SearchMixedLoader? mixedLoader;

  const SearchPage({
    super.key,
    required this.searchWords,
    this.initialTab = 0,
    this.forumLoader,
    this.postLoader,
    this.userLoader,
    this.mixedLoader,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _input =
      TextEditingController(text: widget.searchWords.trim());
  final FocusNode _focus = FocusNode();
  late final TabController _tabs = TabController(
    length: 4,
    vsync: this,
    initialIndex: widget.initialTab.clamp(0, 3).toInt(),
  );
  final ScrollController _mixedScroll = ScrollController();
  final ScrollController _forumScroll = ScrollController();
  final ScrollController _postScroll = ScrollController();
  final ScrollController _userScroll = ScrollController();
  final ScrollController _historyScroll = ScrollController();

  /// 已经发起搜索的关键词。为空表示停在搜索历史 / 引导态。
  String _keyword = "";

  List<SearchMixedCard> _mixed = <SearchMixedCard>[];
  bool _mixedLoading = false;
  bool _mixedLoadingMore = false;
  bool _mixedHasMore = false;
  int _mixedPn = 1;
  Object? _mixedError;
  Object? _mixedMoreError;

  List<TiebaSearchForum> _forums = <TiebaSearchForum>[];
  bool _forumLoading = false;
  Object? _forumError;

  List<TiebaSearchPost> _posts = <TiebaSearchPost>[];
  bool _postLoading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _postPn = 1;
  int _order = 2;
  int _filter = 1;
  Object? _postError;
  Object? _moreError;

  List<TiebaUserMatch> _users = <TiebaUserMatch>[];
  bool _userLoading = false;
  Object? _userError;

  /// 换关键词时递增；旧请求的结果会被丢弃。
  int _querySeq = 0;

  /// 贴结果自己的序号：换排序 / 范围只作废贴请求，不闪掉吧 / 用户。
  int _postSeq = 0;

  SearchForumLoader get _forumLoader =>
      widget.forumLoader ??
      (String keyword, int pn) => Global.tiebaAPI.searchForum(keyword, pn);

  SearchMixedLoader get _mixedLoader =>
      widget.mixedLoader ??
      (String keyword, int pn) => Global.tiebaAPI.searchMixed(keyword, pn: pn);

  SearchPostLoader get _postLoader =>
      widget.postLoader ??
      ({
        required String keyword,
        required int pn,
        required int order,
        required int filter,
      }) =>
          Global.tiebaAPI
              .searchPost(keyword, pn: pn, order: order, filter: filter);

  SearchUserLoader get _userLoader =>
      widget.userLoader ??
      (String keyword) => Global.tiebaAPI.searchUser(keyword);

  @override
  void initState() {
    super.initState();
    _mixedScroll.addListener(_onMixedScroll);
    _postScroll.addListener(_onPostScroll);
    if (_input.text.isNotEmpty) {
      // 首帧之后再发请求，避免在 initState 里 setState。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _search();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _tabs.dispose();
    _mixedScroll.dispose();
    _forumScroll.dispose();
    _postScroll.dispose();
    _userScroll.dispose();
    _historyScroll.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ search flow

  /// 发起一次全站搜索：四个页签并行请求，各自落状态。
  ///
  /// [keepList] 为 true 时保留已有结果（下拉刷新），否则清列表出骨架。
  Future<void> _search(
      {bool keepList = false, bool recordHistory = true}) async {
    final String keyword = _input.text.trim();
    if (keyword.isEmpty) {
      _resetToIdle();
      return;
    }
    keepList = keepList && keyword == _keyword;
    if (recordHistory) {
      _remember(keyword);
    }
    final int seq = ++_querySeq;
    _jumpToTop();
    setState(() {
      _keyword = keyword;
      _forumError = null;
      _userError = null;
      _forumLoading = true;
      _userLoading = true;
      if (!keepList) {
        _forums = <TiebaSearchForum>[];
        _users = <TiebaUserMatch>[];
      }
      _postError = null;
      _moreError = null;
      _loadingMore = false;
      if (!keepList) {
        _posts = <TiebaSearchPost>[];
        _hasMore = false;
        _postPn = 1;
      }
      _postLoading = _posts.isEmpty;
      _mixedError = null;
      _mixedMoreError = null;
      _mixedLoadingMore = false;
      if (!keepList) {
        _mixed = <SearchMixedCard>[];
        _mixedHasMore = false;
        _mixedPn = 1;
      }
      _mixedLoading = true;
    });
    _focus.unfocus();
    await Future.wait(<Future<void>>[
      _loadMixed(seq, clear: !keepList),
      _loadForums(seq),
      _loadPosts(seq, clear: !keepList),
      _loadUsers(seq),
    ]);
  }

  Future<void> _loadMixed(int seq, {required bool clear}) async {
    if (clear) {
      setState(() {
        _mixed = <SearchMixedCard>[];
        _mixedPn = 1;
        _mixedHasMore = false;
      });
    }
    setState(() {
      _mixedError = null;
      _mixedMoreError = null;
      _mixedLoading = true;
    });
    try {
      final SearchMixedPage page = await _mixedLoader(_keyword, 1);
      if (!mounted || seq != _querySeq) return;
      setState(() {
        _mixed = page.cards;
        _mixedHasMore = page.hasMore;
        _mixedPn = 1;
        _mixedLoading = false;
      });
    } catch (error) {
      if (!mounted || seq != _querySeq) return;
      setState(() {
        _mixedLoading = false;
        _mixedError = error;
      });
    }
  }

  Future<void> _loadForums(int seq) async {
    try {
      final SearchForumResult res = await _forumLoader(_keyword, 1);
      if (!mounted || seq != _querySeq) return;
      setState(() {
        _forums = res.forums;
        _forumLoading = false;
      });
    } catch (error) {
      if (!mounted || seq != _querySeq) return;
      setState(() {
        _forumLoading = false;
        _forumError = error;
      });
    }
  }

  Future<void> _loadUsers(int seq) async {
    try {
      final SearchUserResult res = await _userLoader(_keyword);
      if (!mounted || seq != _querySeq) return;
      setState(() {
        _users = res.users;
        _userLoading = false;
      });
    } catch (error) {
      if (!mounted || seq != _querySeq) return;
      setState(() {
        _userLoading = false;
        _userError = error;
      });
    }
  }

  Future<void> _loadPosts(int seq, {required bool clear}) async {
    final int pseq = ++_postSeq;
    if (clear) {
      setState(() {
        _posts = <TiebaSearchPost>[];
        _postPn = 1;
        _hasMore = false;
      });
    }
    setState(() {
      _postError = null;
      _moreError = null;
      _postLoading = true;
      _loadingMore = false;
    });
    try {
      final SearchPostPage page = await _postLoader(
          keyword: _keyword, pn: 1, order: _order, filter: _filter);
      if (!mounted || seq != _querySeq || pseq != _postSeq) return;
      setState(() {
        _posts = page.posts;
        _hasMore = page.hasMore;
        _postPn = 1;
        _postLoading = false;
      });
    } catch (error) {
      if (!mounted || seq != _querySeq || pseq != _postSeq) return;
      setState(() {
        _postLoading = false;
        _postError = error;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_keyword.isEmpty ||
        _postLoading ||
        _loadingMore ||
        !_hasMore ||
        _postError != null) {
      return;
    }
    final int seq = _querySeq;
    final int pseq = _postSeq;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final SearchPostPage page = await _postLoader(
          keyword: _keyword, pn: _postPn + 1, order: _order, filter: _filter);
      if (!mounted || seq != _querySeq || pseq != _postSeq) return;
      setState(() {
        _posts = <TiebaSearchPost>[..._posts, ...page.posts];
        _postPn += 1;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted || seq != _querySeq || pseq != _postSeq) return;
      setState(() {
        _loadingMore = false;
        _moreError = error;
      });
    }
  }

  Future<void> _loadMoreMixed() async {
    if (_keyword.isEmpty ||
        _mixedLoading ||
        _mixedLoadingMore ||
        !_mixedHasMore ||
        _mixedError != null) {
      return;
    }
    final int seq = _querySeq;
    setState(() {
      _mixedLoadingMore = true;
      _mixedMoreError = null;
    });
    try {
      final SearchMixedPage page = await _mixedLoader(_keyword, _mixedPn + 1);
      if (!mounted || seq != _querySeq) return;
      setState(() {
        _mixed = <SearchMixedCard>[..._mixed, ...page.cards];
        _mixedPn += 1;
        _mixedHasMore = page.hasMore;
        _mixedLoadingMore = false;
      });
    } catch (error) {
      if (!mounted || seq != _querySeq) return;
      setState(() {
        _mixedLoadingMore = false;
        _mixedMoreError = error;
      });
    }
  }

  void _onMixedScroll() {
    if (!_mixedScroll.hasClients || _mixedMoreError != null) return;
    final ScrollPosition position = _mixedScroll.position;
    if (position.maxScrollExtent > 0 &&
        position.pixels >= position.maxScrollExtent - 200) {
      _loadMoreMixed();
    }
  }

  void _onPostScroll() {
    if (!_postScroll.hasClients || _moreError != null) return;
    final ScrollPosition position = _postScroll.position;
    if (position.maxScrollExtent > 0 &&
        position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onSortChange(int value) {
    if (value == _order) return;
    setState(() => _order = value);
    if (_keyword.isNotEmpty) {
      _loadPosts(_querySeq, clear: true);
    }
  }

  void _onToggleFilter() {
    setState(() => _filter = _filter == 1 ? 0 : 1);
    if (_keyword.isNotEmpty) {
      _loadPosts(_querySeq, clear: true);
    }
  }

  void _clearInput() {
    _input.clear();
    _resetToIdle();
    _focus.requestFocus();
  }

  void _resetToIdle() {
    ++_querySeq;
    ++_postSeq;
    setState(() {
      _keyword = "";
      _forums = <TiebaSearchForum>[];
      _users = <TiebaUserMatch>[];
      _posts = <TiebaSearchPost>[];
      _postPn = 1;
      _hasMore = false;
      _mixed = <SearchMixedCard>[];
      _mixedPn = 1;
      _mixedHasMore = false;
      _mixedLoading = false;
      _mixedLoadingMore = false;
      _forumLoading = false;
      _userLoading = false;
      _postLoading = false;
      _loadingMore = false;
      _mixedError = null;
      _mixedMoreError = null;
      _forumError = null;
      _userError = null;
      _postError = null;
      _moreError = null;
    });
  }

  void _jumpToTop() {
    for (final ScrollController c in <ScrollController>[
      _mixedScroll,
      _forumScroll,
      _postScroll,
      _userScroll,
    ]) {
      if (c.hasClients) c.jumpTo(0);
    }
  }

  // --------------------------------------------------------------- history

  List<String> get _history =>
      Global.profile.getStringList(searchHistoryKey) ?? <String>[];

  void _remember(String keyword) {
    final List<String> list = List<String>.of(_history);
    list.remove(keyword);
    list.insert(0, keyword);
    Global.profile.setStringList(searchHistoryKey, list);
  }

  void _deleteHistory(String item) {
    final List<String> next = List<String>.of(_history)..remove(item);
    Global.profile.setStringList(searchHistoryKey, next);
    setState(() {});
  }

  Future<void> _clearHistory() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const TiebaAlterDialog(
        title: "确认清空搜索历史？",
        content: Text("搜索过的关键词会全部删除，且无法恢复。"),
      ),
    );
    if (confirmed != true || !mounted) return;
    Global.profile.setStringList(searchHistoryKey, <String>[]);
    setState(() {});
  }

  void _useHistory(String item) {
    _input.text = item;
    _input.selection = TextSelection.collapsed(offset: item.length);
    _search();
  }

  // ---------------------------------------------------------------- navigation

  void _openForum(TiebaSearchForum forum) {
    final String name = forum.name.endsWith("吧")
        ? forum.name.substring(0, forum.name.length - 1)
        : forum.name;
    Navigator.pushNamed(context, PageRouter.forumHome, arguments: name);
  }

  void _openThread(TiebaSearchPost post) {
    Navigator.pushNamed(context, PageRouter.threadPage,
        arguments: ThreadPageRouterData(
            kz: post.tid,
            pid: post.type == 2 && post.pid.isNotEmpty ? post.pid : null));
  }

  void _openUser(TiebaUserMatch user) {
    Navigator.pushNamed(context, PageRouter.user, arguments: user.id);
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: _appBar(tokens),
      body: Column(
        children: <Widget>[
          _tabBar(tokens),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: <Widget>[
                _mixedTab(),
                _threadTab(),
                _forumTab(),
                _userTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar(TiebananaTokens tokens) {
    return AppBar(
      backgroundColor: tokens.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: tokens.textPrimary,
      titleSpacing: 0,
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: tokens.surfaceAlt,
          borderRadius: TiebananaMetrics.brPill,
        ),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(Icons.search, size: 18, color: tokens.textTertiary),
            ),
            Expanded(
              child: TextField(
                controller: _input,
                focusNode: _focus,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: tokens.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: "搜索吧、贴、用户",
                  hintStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: tokens.textTertiary),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _input,
              builder: (BuildContext context, TextEditingValue value, _) {
                if (value.text.isEmpty) return const SizedBox(width: 6);
                return InkWell(
                  borderRadius: TiebananaMetrics.brPill,
                  onTap: _clearInput,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child:
                        Icon(Icons.close, size: 16, color: tokens.textTertiary),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: TextButton(
            onPressed: () => _search(),
            style: TextButton.styleFrom(foregroundColor: tokens.primary),
            child: const Text("搜索"),
          ),
        ),
      ],
    );
  }

  Widget _tabBar(TiebananaTokens tokens) {
    // 概念图 `.stabs`：`padding:2px 12px 8px; gap:6px`。
    // 药丸左右各外扩 14，labelPadding 留 17 → 相邻两颗药丸之间正好剩 6；
    // 外边距取 9 让第一颗药丸的左缘落在 12 上（9 + 17 − 14）。
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: TiebananaMetrics.gapSm),
      child: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        labelPadding: const EdgeInsets.symmetric(horizontal: 17),
        labelColor: tokens.onPrimaryContainer,
        unselectedLabelColor: tokens.textSecondary,
        labelStyle: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w500),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        indicator: TiebananaPillTabIndicator(color: tokens.primaryContainer),
        tabs: const <Widget>[
          Tab(height: TiebananaPillTabIndicator.tabHeight, text: "综合"),
          Tab(height: TiebananaPillTabIndicator.tabHeight, text: "贴"),
          Tab(height: TiebananaPillTabIndicator.tabHeight, text: "吧"),
          Tab(height: TiebananaPillTabIndicator.tabHeight, text: "人"),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ tabs

  Widget _mixedTab() {
    if (_keyword.isEmpty) return _idleView();
    return _withRefresh(_mixedBody());
  }

  Widget _mixedBody() {
    if (_mixedLoading && _mixed.isEmpty) {
      return _sheet(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _ForumSkeletonCard(),
              SearchResultSkeletonCard(),
              SearchResultSkeletonCard(),
            ],
          ),
          center: false);
    }
    if (_mixedError != null && _mixed.isEmpty) {
      return _sheet(_errorView(0), center: true);
    }
    if (_mixed.isEmpty) {
      return _sheet(_emptyView(0), center: true);
    }
    final bool showFooter =
        _mixedLoadingMore || _mixedMoreError != null || !_mixedHasMore;
    final String needle = _keyword.trim().toLowerCase();
    return ListView.builder(
      controller: _mixedScroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
          top: TiebananaMetrics.gapXs, bottom: TiebananaMetrics.gapMd),
      itemCount: _mixed.length + (showFooter ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index >= _mixed.length) {
          return _mixedFooter();
        }
        final SearchMixedCard card = _mixed[index];
        if (card.kind == SearchMixedKind.forum) {
          final TiebaSearchForum forum = card.forum!;
          final String bare = forum.name.endsWith("吧")
              ? forum.name.substring(0, forum.name.length - 1)
              : forum.name;
          return _SearchForumCard(
            forum: forum,
            keyword: _keyword,
            best: bare.toLowerCase() == needle && needle.isNotEmpty,
            onTap: () => _openForum(forum),
          );
        }
        final TiebaSearchPost post = card.post!;
        return SearchResultCard(
          post: post,
          keyword: _keyword,
          showForum: true,
          onTap: () => _openThread(post),
        );
      },
    );
  }

  Widget _forumTab() {
    if (_keyword.isEmpty) return _idleView();
    return _withRefresh(_forumBody());
  }

  Widget _threadTab() {
    if (_keyword.isEmpty) return _idleView();
    return Column(
      children: <Widget>[
        _threadToolbar(),
        Expanded(child: _withRefresh(_threadBody())),
      ],
    );
  }

  Widget _userTab() {
    if (_keyword.isEmpty) return _idleView();
    return _withRefresh(_userBody());
  }

  Widget _withRefresh(Widget child) {
    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () => _search(keepList: true, recordHistory: false),
      child: child,
    );
  }

  Widget _forumBody() {
    if (_forumLoading && _forums.isEmpty) {
      return _sheet(const _ForumSkeletonList(), center: false);
    }
    if (_forumError != null && _forums.isEmpty) {
      return _sheet(_errorView(2), center: true);
    }
    if (_forums.isEmpty) {
      return _sheet(_emptyView(2), center: true);
    }
    final String needle = _keyword.trim().toLowerCase();
    return ListView.builder(
      controller: _forumScroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
          top: TiebananaMetrics.gapXs, bottom: TiebananaMetrics.gapMd),
      itemCount: _forums.length,
      itemBuilder: (BuildContext context, int index) {
        final TiebaSearchForum forum = _forums[index];
        final String bare = forum.name.endsWith("吧")
            ? forum.name.substring(0, forum.name.length - 1)
            : forum.name;
        return _SearchForumCard(
          forum: forum,
          keyword: _keyword,
          best: bare.toLowerCase() == needle && needle.isNotEmpty,
          onTap: () => _openForum(forum),
        );
      },
    );
  }

  Widget _threadToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          TiebananaMetrics.pageGutter, 0, TiebananaMetrics.pageGutter, 8),
      child: Row(
        children: <Widget>[
          ForumMenuPill(
            menu: kSearchSorts,
            value: _order,
            onChanged: _onSortChange,
          ),
          const SizedBox(width: 7),
          ForumClassifyChip(
            label: "只看主题帖",
            selected: _filter == 1,
            onTap: _onToggleFilter,
          ),
        ],
      ),
    );
  }

  Widget _threadBody() {
    if (_postLoading && _posts.isEmpty) {
      return _sheet(const SearchResultSkeletonList(), center: false);
    }
    if (_postError != null && _posts.isEmpty) {
      return _sheet(_errorView(1), center: true);
    }
    if (_posts.isEmpty) {
      return _sheet(_emptyView(1), center: true);
    }
    final bool showFooter = _loadingMore || _moreError != null || !_hasMore;
    return ListView.builder(
      controller: _postScroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
          top: TiebananaMetrics.gapXs, bottom: TiebananaMetrics.gapMd),
      itemCount: _posts.length + (showFooter ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index >= _posts.length) {
          return _postFooter();
        }
        final TiebaSearchPost post = _posts[index];
        return SearchResultCard(
          post: post,
          keyword: _keyword,
          showForum: true,
          onTap: () => _openThread(post),
        );
      },
    );
  }

  Widget _userBody() {
    if (_userLoading && _users.isEmpty) {
      return _sheet(const _UserSkeletonList(), center: false);
    }
    if (_userError != null && _users.isEmpty) {
      return _sheet(_errorView(3), center: true);
    }
    if (_users.isEmpty) {
      return _sheet(_emptyView(3), center: true);
    }
    return ListView.builder(
      controller: _userScroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
          top: TiebananaMetrics.gapXs, bottom: TiebananaMetrics.gapMd),
      itemCount: _users.length,
      itemBuilder: (BuildContext context, int index) {
        final TiebaUserMatch user = _users[index];
        return _SearchUserCard(
          user: user,
          keyword: _keyword,
          onTap: () => _openUser(user),
        );
      },
    );
  }

  // ---------------------------------------------------------------- states

  /// 状态页也要能下拉刷新：撑满可视高度再居中。
  Widget _sheet(Widget child, {required bool center}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: center ? Center(child: child) : child,
          ),
        );
      },
    );
  }

  Widget _idleView() {
    final List<String> history = _history;
    if (history.isEmpty) {
      return Center(
        child: StateView(
          icon: Icons.search,
          title: "搜一搜贴吧、帖子、用户",
          body: "输入关键词后点「搜索」，或直接回车。搜索过的词会留在这里。",
        ),
      );
    }
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return ListView(
      controller: _historyScroll,
      padding: const EdgeInsets.fromLTRB(
          TiebananaMetrics.pageGutter, 4, TiebananaMetrics.pageGutter, 24),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
              TiebananaMetrics.gapXs, 0, TiebananaMetrics.gapXs, 6),
          child: Row(
            children: <Widget>[
              Text(
                "搜索历史",
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: tokens.textSecondary, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _clearHistory,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: TiebananaMetrics.gapXs),
                  child: Text(
                    "清空",
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: tokens.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: TiebananaMetrics.brLg,
            boxShadow: tokens.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              for (int i = 0; i < history.length; i++) ...<Widget>[
                if (i > 0) Divider(height: 1, thickness: 1, color: tokens.line),
                _HistoryRow(
                  text: history[i],
                  tokens: tokens,
                  onTap: () => _useHistory(history[i]),
                  onDelete: () => _deleteHistory(history[i]),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              TiebananaMetrics.gapXs, 10, TiebananaMetrics.gapXs, 0),
          child: Text(
            "只保存在本机。点历史关键词直接搜索，右侧 × 删除单条。",
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: tokens.textTertiary, height: 1.7),
          ),
        ),
      ],
    );
  }

  Widget _emptyView(int tab) {
    switch (tab) {
      case 0:
        return StateView(
          icon: Icons.search_off_rounded,
          title: "没有找到相关内容",
          body: "换个关键词试试，或者切到「贴」「吧」「人」看看",
          primaryLabel: "重新搜索",
          primaryIcon: Icons.refresh,
          onPrimary: () => _search(),
          secondaryLabel: "去看贴子",
          onSecondary: () => _tabs.animateTo(1),
        );
      case 1:
        return StateView(
          icon: Icons.search_off_rounded,
          title: "没有找到相关帖子",
          body: _filter == 1 ? "换个关键词试试，或关掉「只看主题帖」再搜一次" : "换个关键词试试",
          primaryLabel: "重新搜索",
          primaryIcon: Icons.refresh,
          onPrimary: () => _search(),
        );
      case 2:
        return StateView(
          icon: Icons.search_off_rounded,
          title: "没有找到相关吧",
          body: "换个关键词试试，或者切到「贴」看看大家怎么说",
          primaryLabel: "重新搜索",
          primaryIcon: Icons.refresh,
          onPrimary: () => _search(),
          secondaryLabel: "去看贴子",
          onSecondary: () => _tabs.animateTo(1),
        );
      default:
        return StateView(
          icon: Icons.person_search_rounded,
          title: "没有找到相关用户",
          body: "换个昵称或 ID 再试一次",
          primaryLabel: "重新搜索",
          primaryIcon: Icons.refresh,
          onPrimary: () => _search(),
        );
    }
  }

  Widget _errorView(int tab) {
    return StateView(
      icon: Icons.wifi_off_rounded,
      title: "搜索没成功",
      body: "检查一下网络，或者稍后再试",
      primaryLabel: "重试",
      primaryIcon: Icons.refresh,
      onPrimary: () => _search(keepList: false, recordHistory: false),
    );
  }

  Widget _mixedFooter() => _paginationFooter(
      loading: _mixedLoadingMore,
      error: _mixedMoreError,
      retry: _loadMoreMixed);

  Widget _postFooter() => _paginationFooter(
      loading: _loadingMore, error: _moreError, retry: _loadMore);

  Widget _paginationFooter({
    required bool loading,
    required Object? error,
    required VoidCallback retry,
  }) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: TiebananaMetrics.gapMd),
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: retry,
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
    if (loading) {
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TiebananaMetrics.gapLg),
      child: Center(
        child: Text(
          "没有更多了",
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: tokens.textTertiary),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 结果行
// ---------------------------------------------------------------------------

/// 吧搜索结果：整行点进吧，右侧用 chevron 表达「可进入」。
///
/// 契约中没有「关注吧」接口，这里只展示关注状态；`isLike` 用于标出「已关注」。
class _SearchForumCard extends StatelessWidget {
  const _SearchForumCard({
    required this.forum,
    required this.keyword,
    required this.best,
    required this.onTap,
  });

  final TiebaSearchForum forum;
  final String keyword;
  final bool best;
  final VoidCallback onTap;

  String get _displayName =>
      forum.name.endsWith("吧") ? forum.name : "${forum.name}吧";

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(TiebananaMetrics.pageGutter, 0,
          TiebananaMetrics.pageGutter, TiebananaMetrics.gapSm),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: MaterialButton(
        onPressed: onTap,
        color: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minWidth: 0,
        padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
        shape: RoundedRectangleBorder(borderRadius: TiebananaMetrics.brLg),
        child: Row(
          children: <Widget>[
            Avatar(
              onTap: onTap,
              imgUrl: forum.img,
              height: 46,
              width: 46,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: HighlightText(
                          _displayName,
                          keyword: keyword,
                          style: textTheme.titleSmall
                              ?.copyWith(color: tokens.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (best) ...<Widget>[
                        const SizedBox(width: TiebananaMetrics.gapXs + 1),
                        _Badge(
                          label: "最匹配",
                          background: tokens.primaryContainer,
                          foreground: tokens.onPrimaryContainer,
                        ),
                      ],
                      if (forum.isLike) ...<Widget>[
                        const SizedBox(width: TiebananaMetrics.gapXs + 1),
                        Text(
                          "已关注",
                          style: textTheme.labelSmall?.copyWith(
                              color: tokens.textTertiary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                  if (forum.brief.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 3),
                    HighlightText(
                      forum.brief,
                      keyword: keyword,
                      style: textTheme.bodySmall
                          ?.copyWith(color: tokens.textSecondary, height: 1.55),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    "关注 ${TiebaParser.numberConvertString(forum.member)} · "
                    "帖子 ${TiebaParser.numberConvertString(forum.post)}",
                    style: textTheme.labelSmall
                        ?.copyWith(color: tokens.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: tokens.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// 用户搜索结果：昵称 + @用户名 + 签名。
class _SearchUserCard extends StatelessWidget {
  const _SearchUserCard({
    required this.user,
    required this.keyword,
    required this.onTap,
  });

  final TiebaUserMatch user;
  final String keyword;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String displayName = user.displayName;
    final bool showHandle = user.name.isNotEmpty && user.name != displayName;
    return Container(
      margin: const EdgeInsets.fromLTRB(TiebananaMetrics.pageGutter, 0,
          TiebananaMetrics.pageGutter, TiebananaMetrics.gapSm),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: MaterialButton(
        onPressed: onTap,
        color: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minWidth: 0,
        padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
        shape: RoundedRectangleBorder(borderRadius: TiebananaMetrics.brLg),
        child: Row(
          children: <Widget>[
            Avatar(
              onTap: onTap,
              imgUrl: user.portrait,
              height: 46,
              width: 46,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: HighlightText(
                          displayName,
                          keyword: keyword,
                          style: textTheme.titleSmall
                              ?.copyWith(color: tokens.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showHandle) ...<Widget>[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            "@${user.name}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall
                                ?.copyWith(color: tokens.textTertiary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (user.intro.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    HighlightText(
                      user.intro,
                      keyword: keyword,
                      style: textTheme.bodySmall
                          ?.copyWith(color: tokens.textSecondary, height: 1.55),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: tokens.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: TiebananaMetrics.gapXs + 2, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: TiebananaMetrics.brXs,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground, fontWeight: FontWeight.w700, height: 1.3),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.text,
    required this.tokens,
    required this.onTap,
    required this.onDelete,
  });

  final String text;
  final TiebananaTokens tokens;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 46,
        child: Row(
          children: <Widget>[
            const SizedBox(width: 14),
            Icon(Icons.history, size: 17, color: tokens.textTertiary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: tokens.textPrimary),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.close, size: 14, color: tokens.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 骨架
// ---------------------------------------------------------------------------

class _ForumSkeletonList extends StatelessWidget {
  const _ForumSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < 4; i++) const _ForumSkeletonCard(),
      ],
    );
  }
}

class _ForumSkeletonCard extends StatelessWidget {
  const _ForumSkeletonCard();

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
        children: <Widget>[
          const SkeletonBox(width: 46, height: 46, radius: 23),
          const SizedBox(width: TiebananaMetrics.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                SkeletonBox(width: 108, height: 13),
                SizedBox(height: TiebananaMetrics.gapSm),
                SkeletonBox(height: 11),
                SizedBox(height: TiebananaMetrics.gapXs + 2),
                SkeletonBox(width: 96, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserSkeletonList extends StatelessWidget {
  const _UserSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < 4; i++) const _UserSkeletonCard(),
      ],
    );
  }
}

class _UserSkeletonCard extends StatelessWidget {
  const _UserSkeletonCard();

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
        children: <Widget>[
          const SkeletonBox(width: 46, height: 46, radius: 23),
          const SizedBox(width: TiebananaMetrics.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                SkeletonBox(width: 92, height: 13),
                SizedBox(height: TiebananaMetrics.gapSm),
                SkeletonBox(height: 11),
                SizedBox(height: TiebananaMetrics.gapXs + 2),
                SkeletonBox(width: 120, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
