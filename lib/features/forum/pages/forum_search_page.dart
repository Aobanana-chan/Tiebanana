import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';

import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';
import 'package:tiebanana/features/forum/widgets/forum_control_bar.dart';
import 'package:tiebanana/features/search/widgets/search_result_card.dart';

/// 吧内搜索的排序项。值与接口 `st` 一一对应（见 `TiebaApi.searchPost` 的 `order`）。
const List<TiebaForumMenuItem> kForumSearchSorts = <TiebaForumMenuItem>[
  TiebaForumMenuItem(text: "相关度", value: 2),
  TiebaForumMenuItem(text: "最新", value: 1),
  TiebaForumMenuItem(text: "最早", value: 0),
];

/// 拉取一页吧内搜索结果的实现。默认走 [Global.tiebaAPI]，测试里注入假数据。
typedef ForumSearchLoader = Future<SearchPostPage> Function({
  required String keyword,
  required int pn,
  required int order,
  required int filter,
});

/// 吧内搜索页。
///
/// 对应概念图 `design/mockups/forum_search.html`（方向 A）：顶栏一条搜索框，
/// 下面一行「排序 + 只看主题帖」工具条，再下面是结果列表。
/// 与全站搜索（`search.dart`）的区别只有一处：请求带上 `fname`，结果限定在当前吧。
class ForumSearchPage extends StatefulWidget {
  /// 吧名（不含「吧」字），与 `ForumHomePage.kw` 同源。
  final String forumName;

  /// 打开时预填的关键词。为空时停在「输入关键词」的引导态。
  final String initialKeyword;

  /// 数据源；测试注入。
  final ForumSearchLoader? loader;

  const ForumSearchPage({
    super.key,
    required this.forumName,
    this.initialKeyword = "",
    this.loader,
  });

  @override
  State<ForumSearchPage> createState() => _ForumSearchPageState();
}

class _ForumSearchPageState extends State<ForumSearchPage> {
  late final TextEditingController _input =
      TextEditingController(text: widget.initialKeyword);
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();

  /// 已经发起搜索的关键词。为空表示还没搜过（引导态）。
  String _keyword = "";
  List<TiebaSearchPost> _posts = <TiebaSearchPost>[];
  int _pn = 1;
  bool _hasMore = false;

  /// 当前排序（接口 `order`）与范围（接口 `filter`：1 只看主题帖 / 0 全部）。
  int _order = kForumSearchSorts.first.value;
  int _filter = 1;

  bool _loading = false;
  bool _refreshing = false;
  bool _loadingMore = false;
  Object? _error;
  Object? _moreError;

  /// 请求序号：换关键词 / 换排序后，旧请求回来时直接丢弃。
  int _requestSeq = 0;

  ForumSearchLoader get _loader =>
      widget.loader ??
      ({
        required String keyword,
        required int pn,
        required int order,
        required int filter,
      }) =>
          Global.tiebaAPI.searchPost(keyword,
              pn: pn, order: order, filter: filter, fname: widget.forumName);

  @override
  void initState() {
    super.initState();
    if (widget.initialKeyword.trim().isNotEmpty) {
      // 首帧之后再发请求，避免在 initState 里 setState。
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    } else {
      // 空手进来时直接把光标落进搜索框，省一次点击。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// 发起搜索。[keepList] 为 true 时保留已有结果（下拉刷新），否则清列表出骨架。
  Future<void> _search({bool keepList = false}) async {
    final String keyword = _input.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _keyword = "";
        _posts = <TiebaSearchPost>[];
        _hasMore = false;
        _pn = 1;
        _loading = false;
        _refreshing = false;
        _error = null;
        _moreError = null;
      });
      return;
    }
    final int seq = ++_requestSeq;
    setState(() {
      _keyword = keyword;
      _error = null;
      _moreError = null;
      _pn = 1;
      if (!keepList) {
        _posts = <TiebaSearchPost>[];
        _hasMore = false;
      }
      _loading = _posts.isEmpty;
      _refreshing = true;
    });
    _focus.unfocus();
    try {
      final SearchPostPage page = await _loader(
          keyword: keyword, pn: 1, order: _order, filter: _filter);
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _posts = page.posts;
        _hasMore = page.hasMore;
        _loading = false;
        _refreshing = false;
      });
    } catch (error) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        // 已有内容时保留列表，错误显示在底部重试口。
        if (_posts.isEmpty) {
          _error = error;
        } else {
          _moreError = error;
        }
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _refreshing || _loadingMore || !_hasMore) return;
    if (_keyword.isEmpty) return;
    final int seq = _requestSeq;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final SearchPostPage page = await _loader(
          keyword: _keyword, pn: _pn + 1, order: _order, filter: _filter);
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _posts = <TiebaSearchPost>[..._posts, ...page.posts];
        _pn += 1;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _loadingMore = false;
        _moreError = error;
      });
    }
  }

  void _onSortChange(int value) {
    if (value == _order) return;
    setState(() => _order = value);
    if (_keyword.isNotEmpty) _search();
  }

  void _onToggleFilter() {
    setState(() => _filter = _filter == 1 ? 0 : 1);
    if (_keyword.isNotEmpty) _search();
  }

  void _clearInput() {
    _input.clear();
    if (_keyword.isEmpty) return;
    setState(() {
      _keyword = "";
      _posts = <TiebaSearchPost>[];
      _hasMore = false;
      _pn = 1;
      _error = null;
      _moreError = null;
    });
    _focus.requestFocus();
  }

  void _openThread(TiebaSearchPost post) {
    // 回复（type 2）尽量落到命中楼层；拿不到 pid 时退回主题顶部。
    Navigator.pushNamed(context, PageRouter.threadPage,
        arguments: ThreadPageRouterData(
            kz: post.tid,
            pid: post.type == 2 && post.pid.isNotEmpty ? post.pid : null));
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: _appBar(tokens),
      body: Column(
        children: <Widget>[
          _toolbar(tokens),
          Expanded(child: _content(context)),
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
              child: Icon(Icons.search,
                  size: 18, color: tokens.textTertiary),
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
                  hintText: "在 ${widget.forumName}吧 内搜索",
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
                    child: Icon(Icons.close,
                        size: 16, color: tokens.textTertiary),
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

  /// 工具条：排序药丸 + 「只看主题帖」筛选。
  Widget _toolbar(TiebananaTokens tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          TiebananaMetrics.pageGutter, 4, TiebananaMetrics.pageGutter, 8),
      child: Row(
        children: <Widget>[
          ForumMenuPill(
            menu: kForumSearchSorts,
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

  Widget _content(BuildContext context) {
    if (_keyword.isEmpty) {
      return _sheet(context, _idleView(context), center: true);
    }
    if (_loading && _posts.isEmpty) {
      return _sheet(context, const SearchResultSkeletonList(), center: false);
    }
    if (_error != null && _posts.isEmpty) {
      return _sheet(context, _errorView(context), center: true);
    }
    if (_posts.isEmpty) {
      return _sheet(context, _emptyView(context), center: true);
    }
    final bool showFooter = _loadingMore || _moreError != null || !_hasMore;
    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () => _search(keepList: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification.metrics.axis != Axis.vertical) return false;
          final ScrollMetrics m = notification.metrics;
          if (m.maxScrollExtent > 0 &&
              m.pixels >= m.maxScrollExtent - m.viewportDimension) {
            _loadMore();
          }
          return false;
        },
        child: ListView.builder(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
              top: TiebananaMetrics.gapXs, bottom: TiebananaMetrics.gapMd),
          itemCount: _posts.length + (showFooter ? 1 : 0),
          itemBuilder: (BuildContext context, int index) {
            if (index >= _posts.length) {
              return _footer(context);
            }
            final TiebaSearchPost post = _posts[index];
            return SearchResultCard(
              post: post,
              keyword: _keyword,
              onTap: () => _openThread(post),
            );
          },
        ),
      ),
    );
  }

  /// 状态页也要能下拉刷新：撑满可视高度再居中。
  Widget _sheet(BuildContext context, Widget child, {bool center = true}) {
    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () => _search(keepList: true),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scroll,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: center ? Center(child: child) : child,
            ),
          );
        },
      ),
    );
  }

  Widget _idleView(BuildContext context) {
    return StateView(
      icon: Icons.search,
      title: "搜一搜 ${widget.forumName}吧",
      body: "输入关键词后点「搜索」，或直接回车",
    );
  }

  Widget _emptyView(BuildContext context) {
    return StateView(
      icon: Icons.search_off_rounded,
      title: "没有找到相关帖子",
      body: _filter == 1
          ? "换个关键词试试，或关掉「只看主题帖」再搜一次"
          : "换个关键词试试",
      primaryLabel: "重新搜索",
      primaryIcon: Icons.refresh,
      onPrimary: () => _search(),
    );
  }

  Widget _errorView(BuildContext context) {
    return StateView(
      icon: Icons.wifi_off_rounded,
      title: "搜索没成功",
      body: "检查一下网络，或者稍后再试",
      primaryLabel: "重试",
      primaryIcon: Icons.refresh,
      onPrimary: () => _search(),
    );
  }

  Widget _footer(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    if (_moreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: TiebananaMetrics.gapMd),
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _loadMore,
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
    if (_loadingMore) {
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
