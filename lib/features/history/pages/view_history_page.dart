import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_throttle_it/just_throttle_it.dart';

import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/history/models/view_history_page_model.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/alert_dialog.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';
import 'package:tiebanana/shared/widgets/swipe_action_row.dart';
import 'package:tiebanana/features/history/widgets/view_history_row.dart';

/// 拉取一页浏览历史。`offset` / `limit` 都为 null 时取全量，
/// 搜索需要跨分页匹配时就用这种形式。默认读本地历史库，测试可注入假数据。
typedef ViewHistoryLoader = Future<List<ViewHistoryPageModel>> Function({
  int? offset,
  int? limit,
});

/// 删除一条历史记录。
typedef ViewHistoryRemover = Future<void> Function(int id);

/// 清空全部历史记录（包含已隐藏的条目）。
typedef ViewHistoryClearer = Future<void> Function();

/// 设置一条记录是否只在首页隐藏。
typedef ViewHistoryHider = Future<void> Function(int id, bool hidden);

/// 浏览历史页。
///
/// 对应概念图 `design/mockups/view_history.html`（方向 A）：
/// 顶栏「清空」+ 卡片式历史行 + 左滑删除 / 取消隐藏。
/// 在概念图基础上补了本地搜索：标题与吧名都参与匹配，多关键词按空格拆分。
/// 普通浏览按 20 条分页；进入搜索时一次读取全部历史，搜索覆盖全部分页。
class ViewHistoryPage extends StatefulWidget {
  final ViewHistoryLoader? loader;
  final ViewHistoryRemover? remover;
  final ViewHistoryClearer? clearer;
  final ViewHistoryHider? hider;

  const ViewHistoryPage({
    super.key,
    this.loader,
    this.remover,
    this.clearer,
    this.hider,
  });

  @override
  State<ViewHistoryPage> createState() => _ViewHistoryPageState();
}

class _ViewHistoryPageState extends State<ViewHistoryPage> {
  static const int _pageSize = 20;

  final List<ViewHistoryPageModel> _items = <ViewHistoryPageModel>[];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  /// 搜索开始时的全量快照。删除 / 取消隐藏时同步维护，搜索直接使用内存数据。
  List<ViewHistoryPageModel>? _searchSource;

  String _query = "";
  int _offset = 0;

  /// 请求序号：搜索、刷新、翻页互相打断时，旧结果直接丢弃。
  int _requestToken = 0;

  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _refreshing = false;
  bool _refreshQueued = false;
  bool _deleting = false;
  bool _clearing = false;
  bool _updatingHidden = false;

  Object? _error;
  Object? _moreError;

  ViewHistoryLoader get _loader => widget.loader ?? _loadPage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    AccountStore.changes.addListener(_onAccountChanged);
    _refresh();
  }

  void _onAccountChanged() {
    // 立即移除旧账号的列表与搜索快照，并使在途请求失效。
    ++_requestToken;
    _searchController.clear();
    setState(() {
      _items.clear();
      _searchSource = null;
      _query = '';
      _offset = 0;
      _hasMore = false;
      _loadingMore = false;
      _error = null;
      _moreError = null;
    });
    _refresh();
  }

  @override
  void dispose() {
    AccountStore.changes.removeListener(_onAccountChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ViewHistoryPageModel>> _loadPage({
    int? offset,
    int? limit,
  }) async {
    return Global.daoapi
        .getHistoryList(offset: offset, limit: limit)
        .map(ViewHistoryPageModel.fromViewHistoryDatabase)
        .toList();
  }

  Future<void> _removeRecord(int id) async {
    final ViewHistoryRemover? remover = widget.remover;
    if (remover != null) {
      await remover(id);
      return;
    }
    Global.daoapi.deleteViewHistory(id);
  }

  Future<void> _setRecordHidden(int id, bool hidden) async {
    final ViewHistoryHider? hider = widget.hider;
    if (hider != null) {
      await hider(id, hidden);
      return;
    }
    Global.daoapi.setViewHistoryHidden(id, hidden);
  }

  Future<void> _clearRecords() async {
    final ViewHistoryClearer? clearer = widget.clearer;
    if (clearer != null) {
      await clearer();
      return;
    }
    Global.daoapi.removeAllViewHistory();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final ScrollPosition position = _scrollController.position;
    if (position.pixels >=
        position.maxScrollExtent - position.viewportDimension) {
      Throttle.milliseconds(500, _loadNextPage);
    }
  }

  /// 刷新当前视图。查询串在加载期间变化时，排队再跑一次，
  /// 通过序号丢弃旧结果，搜索 / 清空后展示最新状态。
  Future<void> _refresh() async {
    if (_refreshing) {
      _refreshQueued = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _refreshQueued = false;
        await _refreshOnce();
      } while (_refreshQueued && mounted);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refreshOnce() async {
    final int token = ++_requestToken;
    if (mounted) {
      setState(() {
        _error = null;
        _moreError = null;
        if (_items.isEmpty) {
          _loading = true;
        }
      });
    }

    try {
      if (_query.isNotEmpty) {
        final List<ViewHistoryPageModel> all = await _loader();
        if (!mounted || token != _requestToken) {
          return;
        }
        _searchSource = all;
        final List<ViewHistoryPageModel> matches = _filter(all, _query);
        setState(() {
          _items
            ..clear()
            ..addAll(matches);
          _loading = false;
          _loadingMore = false;
          _hasMore = false;
        });
        return;
      }

      final List<ViewHistoryPageModel> page =
          await _loader(offset: 0, limit: _pageSize);
      if (!mounted || token != _requestToken) {
        return;
      }
      setState(() {
        _searchSource = null;
        _items
          ..clear()
          ..addAll(page);
        _offset = page.length;
        _hasMore = page.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted || token != _requestToken) {
        return;
      }
      setState(() {
        _loading = false;
        _loadingMore = false;
        // 已有内容时刷新失败不清屏，把重试口留在列表底部。
        if (_items.isEmpty) {
          _error = error;
        } else {
          _moreError = error;
        }
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_query.isNotEmpty ||
        _loading ||
        _loadingMore ||
        _refreshing ||
        _deleting ||
        _clearing ||
        !_hasMore) {
      return;
    }
    final int token = _requestToken;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final List<ViewHistoryPageModel> page =
          await _loader(offset: _offset, limit: _pageSize);
      if (!mounted) {
        return;
      }
      if (token != _requestToken) {
        setState(() => _loadingMore = false);
        return;
      }
      setState(() {
        final Set<int> existing =
            _items.map((ViewHistoryPageModel e) => e.id).toSet();
        _items.addAll(
            page.where((ViewHistoryPageModel e) => !existing.contains(e.id)));
        _offset += page.length;
        _hasMore = page.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingMore = false;
        if (token == _requestToken) {
          _moreError = error;
        }
      });
    }
  }

  /// 标题 + 吧名的本地匹配；多个关键词按空格拆分后取交集。
  List<ViewHistoryPageModel> _filter(
    List<ViewHistoryPageModel> source,
    String query,
  ) {
    final List<String> terms = query
        .toLowerCase()
        .split(RegExp(r"\s+"))
        .where((String term) => term.isNotEmpty)
        .toList();
    if (terms.isEmpty) {
      return List<ViewHistoryPageModel>.of(source);
    }
    return source.where((ViewHistoryPageModel item) {
      final String haystack = "${item.title}\n${item.forumName}".toLowerCase();
      return terms.every(haystack.contains);
    }).toList();
  }

  Future<void> _onQueryChanged(String value) async {
    final String query = value.trim();
    if (query == _query) {
      return;
    }
    final int token = ++_requestToken;
    setState(() {
      _query = query;
      _error = null;
      _moreError = null;
      if (query.isNotEmpty && _items.isEmpty) {
        _loading = true;
      }
    });

    if (query.isEmpty) {
      _searchSource = null;
      await _refresh();
      return;
    }

    List<ViewHistoryPageModel>? source = _searchSource;
    if (source == null) {
      try {
        final List<ViewHistoryPageModel> all = await _loader();
        if (!mounted || token != _requestToken) {
          return;
        }
        source = all;
        _searchSource = all;
      } catch (error) {
        if (!mounted || token != _requestToken) {
          return;
        }
        setState(() {
          _loading = false;
          _error = error;
        });
        return;
      }
    }

    final List<ViewHistoryPageModel> matches = _filter(source, query);
    if (!mounted || token != _requestToken) {
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(matches);
      _loading = false;
      _loadingMore = false;
      _hasMore = false;
    });
  }

  void _clearSearch() {
    FocusScope.of(context).unfocus();
    if (_searchController.text.isEmpty) {
      return;
    }
    _searchController.clear();
    _onQueryChanged("");
  }

  void _retry() {
    setState(() {
      _error = null;
      _moreError = null;
    });
    _refresh();
  }

  Future<void> _open(ViewHistoryPageModel item) async {
    FocusScope.of(context).unfocus();
    await Navigator.pushNamed(
      context,
      PageRouter.threadPage,
      arguments: ThreadPageRouterData(kz: item.tid, pid: null),
    );
    // 进贴会刷新这条记录的浏览时间，回来时重新排序。
    if (mounted) {
      await _refresh();
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final bool? sure = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => TiebaAlterDialog(
        title: title,
        content: Text(body),
      ),
    );
    return sure == true;
  }

  Future<void> _removeOne(ViewHistoryPageModel item) async {
    if (_deleting || _clearing) {
      return;
    }
    FocusScope.of(context).unfocus();
    final int revision = AccountStore.changes.value;
    final bool sure = await _confirm(
      "删除这条浏览记录？",
      "删除后不会出现在任何历史列表中，且无法恢复。",
    );
    if (!sure || !mounted || revision != AccountStore.changes.value) {
      return;
    }
    setState(() => _deleting = true);
    try {
      await _removeRecord(item.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _items.removeWhere((ViewHistoryPageModel e) => e.id == item.id);
        _searchSource?.removeWhere((ViewHistoryPageModel e) => e.id == item.id);
        if (_query.isEmpty && _offset > 0) {
          // 当前列表靠 offset 翻页，删掉一条后 offset 也要回退一格，
          // 否则下一页会跳过一条。
          _offset -= 1;
        }
      });
      Fluttertoast.showToast(msg: "已删除记录");
      if (_query.isEmpty && _items.isEmpty && _hasMore) {
        await _refresh();
      }
    } catch (_) {
      if (mounted) {
        Fluttertoast.showToast(msg: "删除失败，请稍后重试");
      }
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  Future<void> _toggleHidden(ViewHistoryPageModel item) async {
    if (_updatingHidden || _deleting || _clearing) {
      return;
    }
    final bool hidden = !item.hidden;
    setState(() => _updatingHidden = true);
    try {
      await _setRecordHidden(item.id, hidden);
      if (!mounted) {
        return;
      }
      setState(() {
        item.hidden = hidden;
        final List<ViewHistoryPageModel>? source = _searchSource;
        if (source != null) {
          for (final ViewHistoryPageModel e in source) {
            if (e.id == item.id) {
              e.hidden = hidden;
            }
          }
        }
      });
      Fluttertoast.showToast(msg: hidden ? "已隐藏，只影响首页显示" : "已取消隐藏");
    } catch (_) {
      if (mounted) {
        Fluttertoast.showToast(msg: "操作失败，请稍后重试");
      }
    } finally {
      if (mounted) {
        setState(() => _updatingHidden = false);
      }
    }
  }

  Future<void> _clearAll() async {
    if (_clearing || !_canClear) {
      return;
    }
    FocusScope.of(context).unfocus();
    final int revision = AccountStore.changes.value;
    final bool sure = await _confirm(
      "清空全部浏览历史？",
      "包含已隐藏的记录，清空后无法恢复。",
    );
    if (!sure || !mounted || revision != AccountStore.changes.value) {
      return;
    }
    setState(() => _clearing = true);
    try {
      await _clearRecords();
      if (!mounted) {
        return;
      }
      _searchController.clear();
      setState(() {
        _query = "";
        _items.clear();
        _searchSource = null;
        _offset = 0;
        _hasMore = false;
        _error = null;
        _moreError = null;
      });
      Fluttertoast.showToast(msg: "已清空浏览历史");
    } catch (_) {
      if (mounted) {
        Fluttertoast.showToast(msg: "清空失败，请稍后重试");
      }
    } finally {
      if (mounted) {
        setState(() => _clearing = false);
      }
    }
  }

  bool get _canClear =>
      !_loading &&
      !_clearing &&
      (_items.isNotEmpty || (_searchSource?.isNotEmpty ?? false));

  bool get _showSearch =>
      _items.isNotEmpty ||
      _query.isNotEmpty ||
      (_searchSource?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: const Text("浏览历史"),
        actions: <Widget>[
          TextButton(
            onPressed: _canClear ? _clearAll : null,
            style: TextButton.styleFrom(
              foregroundColor: tokens.danger,
              disabledForegroundColor: tokens.textTertiary,
              textStyle: Theme.of(context).textTheme.labelLarge,
              padding: const EdgeInsets.symmetric(
                  horizontal: TiebananaMetrics.gapMd),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(_clearing ? "清空中…" : "清空"),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            if (_showSearch) _searchBar(tokens),
            Expanded(
              child: ViewHistoryFeed(
                items: _items,
                loading: _loading,
                error: _error,
                query: _query,
                loadingMore: _loadingMore,
                moreError: _moreError,
                hasMore: _hasMore,
                scrollController: _scrollController,
                onRefresh: _refresh,
                onRetry: _retry,
                onLoadMore: _loadNextPage,
                onOpen: _open,
                onRemove: _removeOne,
                onToggleHidden: _toggleHidden,
                onClearSearch: _clearSearch,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 固定在列表上方的药丸搜索框（概念图 `.sbar` / `.sfield`）。
  Widget _searchBar(TiebananaTokens tokens) {
    final bool hasText = _query.isNotEmpty;
    return Container(
      height: 46,
      margin: const EdgeInsets.fromLTRB(
        TiebananaMetrics.gapLg,
        TiebananaMetrics.gapXXs,
        TiebananaMetrics.gapLg,
        TiebananaMetrics.gapMd,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brPill,
        boxShadow: tokens.cardShadow,
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: TiebananaMetrics.gapLg),
          Icon(
            Icons.search_rounded,
            size: 20,
            color: tokens.textTertiary,
          ),
          const SizedBox(width: TiebananaMetrics.gapSm),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: tokens.textPrimary),
              cursorColor: tokens.primary,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: "搜索标题或吧名",
                hintStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: tokens.textTertiary),
              ),
            ),
          ),
          if (hasText)
            IconButton(
              onPressed: _clearSearch,
              tooltip: "清除搜索",
              icon: const Icon(Icons.close_rounded, size: 18),
              color: tokens.textTertiary,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            )
          else
            const SizedBox(width: TiebananaMetrics.gapLg),
        ],
      ),
    );
  }
}

/// 浏览历史的展示层：骨架 / 空 / 错误 / 搜索无结果 / 列表。
///
/// 纯展示组件，数据和回调由 [ViewHistoryPage] 传入，便于单独渲染与测试。
class ViewHistoryFeed extends StatelessWidget {
  const ViewHistoryFeed({
    super.key,
    required this.items,
    required this.loading,
    required this.error,
    required this.query,
    required this.loadingMore,
    required this.moreError,
    required this.hasMore,
    required this.scrollController,
    required this.onRefresh,
    required this.onRetry,
    required this.onLoadMore,
    required this.onOpen,
    required this.onRemove,
    required this.onToggleHidden,
    required this.onClearSearch,
  });

  final List<ViewHistoryPageModel> items;
  final bool loading;
  final Object? error;
  final String query;
  final bool loadingMore;
  final Object? moreError;
  final bool hasMore;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final ValueChanged<ViewHistoryPageModel> onOpen;
  final ValueChanged<ViewHistoryPageModel> onRemove;
  final ValueChanged<ViewHistoryPageModel> onToggleHidden;
  final VoidCallback onClearSearch;

  bool get _searching => query.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) {
      return _sheet(context, const _HistorySkeletonList(), center: false);
    }
    if (error != null && items.isEmpty) {
      return _sheet(context, _errorView());
    }
    if (items.isEmpty) {
      return _sheet(context, _searching ? _noResultView() : _emptyView());
    }

    final bool showFooter = loadingMore || moreError != null;
    final bool showHint = !_searching && !hasMore && !showFooter;
    final bool showSearchHeader = _searching;
    final int extra = (showFooter || showHint) ? 1 : 0;

    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(
          top: TiebananaMetrics.gapSm,
          bottom: TiebananaMetrics.gapMd,
        ),
        itemCount: items.length + (showSearchHeader ? 1 : 0) + extra,
        itemBuilder: (BuildContext context, int index) {
          int itemIndex = index;
          if (showSearchHeader) {
            if (index == 0) {
              return _searchHeader(context);
            }
            itemIndex = index - 1;
          }
          if (itemIndex >= items.length) {
            return showFooter ? _footer(context) : _hint(context);
          }
          return _row(context, items[itemIndex]);
        },
      ),
    );
  }

  Widget _row(BuildContext context, ViewHistoryPageModel item) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Widget row = ViewHistoryRow(
      info: item,
      onTap: () => onOpen(item),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(
        TiebananaMetrics.pageGutter,
        0,
        TiebananaMetrics.pageGutter,
        TiebananaMetrics.gapSm,
      ),
      decoration: BoxDecoration(
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: SwipeActionRow(
        borderRadius: TiebananaMetrics.radiusLg,
        actions: <SwipeAction>[
          if (item.hidden)
            SwipeAction(
              label: "取消隐藏",
              icon: Icons.visibility_outlined,
              background: tokens.surfaceHigh,
              foreground: tokens.textSecondary,
              onTap: () => onToggleHidden(item),
            ),
          SwipeAction(
            label: "删除",
            icon: Icons.delete_outline_rounded,
            background: tokens.danger,
            foreground: tokens.accentOn,
            onTap: () => onRemove(item),
          ),
        ],
        child: row,
      ),
    );
  }

  /// 搜索结果条数。搜索会跨分页读取全部历史，这里给用户一个明确的范围。
  Widget _searchHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TiebananaMetrics.gapLg,
        0,
        TiebananaMetrics.gapLg,
        TiebananaMetrics.gapSm,
      ),
      child: Text(
        "找到 ${items.length} 条记录",
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: TiebananaTokens.of(context).textTertiary,
            ),
      ),
    );
  }

  /// 状态页也要能下拉刷新：撑满可视高度再居中。
  Widget _sheet(BuildContext context, Widget child, {bool center = true}) {
    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: center ? Center(child: child) : child,
            ),
          );
        },
      ),
    );
  }

  Widget _errorView() {
    return StateView(
      icon: Icons.wifi_off_rounded,
      title: "浏览历史加载失败",
      body: "本地记录读取失败，重试一次看看",
      primaryLabel: "重试",
      primaryIcon: Icons.refresh,
      onPrimary: onRetry,
    );
  }

  Widget _emptyView() {
    return StateView(
      icon: Icons.history_rounded,
      title: "还没有浏览记录",
      body: "看过的贴子会按最近浏览时间倒序出现在这里",
      primaryLabel: "刷新",
      primaryIcon: Icons.refresh,
      onPrimary: onRetry,
    );
  }

  Widget _noResultView() {
    return StateView(
      icon: Icons.search_off_rounded,
      title: "没有找到相关记录",
      body: "标题和吧名都会参与搜索，换个关键词试试",
      primaryLabel: "清除搜索",
      primaryIcon: Icons.close_rounded,
      onPrimary: onClearSearch,
    );
  }

  /// 翻页的加载 / 失败提示，接在列表最下方。
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

  /// 列表末尾的交互提示（概念图 `.hintline`）。
  Widget _hint(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool hasHidden = items.any((ViewHistoryPageModel e) => e.hidden);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TiebananaMetrics.pageGutter,
        TiebananaMetrics.gapSm,
        TiebananaMetrics.pageGutter,
        TiebananaMetrics.gapLg,
      ),
      child: Text(
        hasHidden ? "左滑可删除单条、取消隐藏；右上角「清空」清空全部。" : "左滑可删除单条；右上角「清空」清空全部。",
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: tokens.textTertiary),
      ),
    );
  }
}

/// 首屏骨架：形状与 [ViewHistoryRow] 对齐，数据到达时不整屏重排。
class _HistorySkeletonList extends StatelessWidget {
  const _HistorySkeletonList();

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: TiebananaMetrics.gapSm),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < 4; i++)
            Container(
              margin: const EdgeInsets.fromLTRB(
                TiebananaMetrics.pageGutter,
                0,
                TiebananaMetrics.pageGutter,
                TiebananaMetrics.gapSm,
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
                  const FractionallySizedBox(
                    widthFactor: 0.92,
                    child: SkeletonBox(height: 13),
                  ),
                  const SizedBox(height: TiebananaMetrics.gapXs + 4),
                  const FractionallySizedBox(
                    widthFactor: 0.58,
                    child: SkeletonBox(height: 13),
                  ),
                  const SizedBox(height: TiebananaMetrics.gapMd),
                  const FractionallySizedBox(
                    widthFactor: 0.42,
                    child: SkeletonBox(height: 10),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
