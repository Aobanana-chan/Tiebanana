import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:provider/provider.dart';

import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/alert_dialog.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';
import 'package:tiebanana/shared/widgets/swipe_action_row.dart';
import 'package:tiebanana/features/favorites/widgets/stored_thread_widget.dart';

/// 拉取一页收藏贴。默认走 [Global.tiebaAPI]，测试里可以注入假数据。
typedef ThreadStoreLoader = Future<ThreadStorePage>
    Function(int offset, String uid, {int rn});

/// 取消一条收藏。与 [ThreadStoreLoader] 一样可注入，便于单独测页面行为。
typedef ThreadStoreRemover = Future<void> Function(String tid);

/// 我的收藏页面。
///
/// 对应概念图 `design/mockups/thread_store.html`（方向 A）：
/// 顶栏文字动作（编辑 / 全选）+ 卡片式收藏行 + 左滑取消收藏 + 编辑态批量删除。
/// 加载 / 空 / 网络错误 / 未登录四种状态由 [ThreadStoreFeed] 统一承担。
class ThreadStorePageRoute extends StatefulWidget {
  final ThreadStoreLoader? loader;
  final ThreadStoreRemover? remover;

  const ThreadStorePageRoute({super.key, this.loader, this.remover});

  @override
  State<ThreadStorePageRoute> createState() => _ThreadStorePageState();
}

class _ThreadStorePageState extends State<ThreadStorePageRoute> {
  static const int _pageSize = 20;

  final List<TiebaStoredThread> _threads = <TiebaStoredThread>[];
  final Set<String> _selected = <String>{};
  final ScrollController _controller = ScrollController();

  int _offset = 0;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  bool _refreshing = false;
  bool _deleting = false;
  bool _deleteMode = false;
  bool _loggedIn = true;
  Object? _error;
  Object? _moreError;
  String _uid = "";
  int? _loadedPageSize;

  ThreadStoreLoader get _loader => widget.loader ?? _loadStored;

  Future<ThreadStorePage> _loadStored(int offset, String uid,
      {int rn = 20}) async {
    try {
      final remote = await Global.tiebaAPI.getThreadStore(offset, uid, rn: rn);
      _loadedPageSize = remote.threads.length;
      final local = offset == 0
          ? await Global.threadCache.storedThreads(uid)
          : <TiebaStoredThread>[];
      final ids = remote.threads.map((e) => e.id).toSet();
      return ThreadStorePage(threads: [
        ...remote.threads,
        ...local.where((e) => !ids.contains(e.id))
      ]);
    } catch (_) {
      final local = await Global.threadCache.storedThreads(uid);
      if (local.isEmpty) rethrow;
      final slice = local.skip(offset).take(rn).toList();
      _loadedPageSize = slice.length;
      return ThreadStorePage(threads: slice);
    }
  }

  ThreadStoreRemover get _remover => widget.remover ?? _removeStored;

  Future<void> _removeStored(String tid) async {
    final uid = AccountStore.currentUid ?? '';
    await Global.tiebaAPI.threadRemoveStore(tid);
    await Global.threadCache.setStored(uid, tid, false);
  }

  @override
  void initState() {
    super.initState();
    // 注入 loader 时按「已登录」运行：页面测试不必初始化 Global 后端与 Provider。
    if (widget.loader != null) {
      _loggedIn = true;
      _uid = "preview";
    } else {
      final User user = Provider.of<User>(context, listen: false);
      _loggedIn = user.isLogin;
      _uid = _loggedIn ? user.uid : "";
    }
    _controller.addListener(_onScroll);
    if (_loggedIn) {
      _refresh();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) {
      return;
    }
    if (_controller.position.pixels >=
        _controller.position.maxScrollExtent -
            _controller.position.viewportDimension) {
      Throttle.milliseconds(500, _loadNextPage);
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) {
      return;
    }
    if (!_loggedIn) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = null;
        });
      }
      return;
    }
    _refreshing = true;
    final bool showSkeleton = _threads.isEmpty;
    if (showSkeleton && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final ThreadStorePage result = await _loader(0, _uid, rn: _pageSize);
      if (!mounted) {
        return;
      }
      setState(() {
        _threads
          ..clear()
          ..addAll(result.threads);
        _offset = _pageSize;
        _hasMore = (_loadedPageSize ?? result.threads.length) >= _pageSize;
        _loading = false;
        _error = null;
        _moreError = null;
        _selected.clear();
        if (_threads.isEmpty) {
          _deleteMode = false;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        // 已有内容时刷新失败不清屏，只把错误留在列表底部重试口。
        if (_threads.isEmpty) {
          _error = error;
        } else {
          _moreError = error;
        }
      });
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _loadNextPage() async {
    if (!mounted ||
        _loading ||
        _loadingMore ||
        _refreshing ||
        _deleting ||
        !_loggedIn ||
        !_hasMore) {
      return;
    }
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final ThreadStorePage result =
          await _loader(_offset, _uid, rn: _pageSize);
      if (!mounted) {
        return;
      }
      setState(() {
        final Set<String> existing =
            _threads.map((TiebaStoredThread e) => e.id).toSet();
        _threads.addAll(result.threads
            .where((TiebaStoredThread e) => !existing.contains(e.id)));
        _offset += _pageSize;
        _hasMore = (_loadedPageSize ?? result.threads.length) >= _pageSize;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingMore = false;
        _moreError = error;
      });
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _moreError = null;
    });
    _refresh();
  }

  Future<void> _onLogin() async {
    await Navigator.pushNamed(context, PageRouter.login);
    if (!mounted) {
      return;
    }
    final User user = Provider.of<User>(context, listen: false);
    final bool loggedIn = user.isLogin;
    setState(() {
      _loggedIn = loggedIn;
      _uid = loggedIn ? user.uid : "";
    });
    if (loggedIn) {
      await _refresh();
    }
  }

  void _toggleEdit() {
    setState(() {
      _deleteMode = !_deleteMode;
      if (!_deleteMode) {
        _selected.clear();
      }
    });
  }

  bool get _allSelected =>
      _threads.isNotEmpty &&
      _threads.every((TiebaStoredThread e) => _selected.contains(e.id));

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected.addAll(_threads.map((TiebaStoredThread e) => e.id));
      }
    });
  }

  void _toggleSelected(TiebaStoredThread item) {
    if (!_deleteMode) {
      return;
    }
    setState(() {
      if (!_selected.remove(item.id)) {
        _selected.add(item.id);
      }
    });
  }

  void _open(TiebaStoredThread item) {
    Navigator.pushNamed(context, PageRouter.threadPage,
        arguments: ThreadPageRouterData(kz: item.id, pid: item.pid));
  }

  Future<bool> _confirm(String title) async {
    final bool? sure = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => TiebaAlterDialog(title: title),
    );
    return sure == true;
  }

  Future<void> _removeOne(TiebaStoredThread item) async {
    if (_deleting) {
      return;
    }
    final bool sure = await _confirm("确认取消收藏?");
    if (!sure || !mounted) {
      return;
    }
    setState(() => _deleting = true);
    try {
      await _remover(item.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _threads.removeWhere((TiebaStoredThread e) => e.id == item.id);
        _selected.remove(item.id);
        if (_threads.isEmpty) {
          _deleteMode = false;
          _selected.clear();
        }
      });
      Fluttertoast.showToast(msg: "已取消收藏");
    } catch (_) {
      if (mounted) {
        Fluttertoast.showToast(msg: "取消收藏失败，请稍后重试");
      }
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  Future<void> _removeSelected() async {
    if (_selected.isEmpty || _deleting) {
      return;
    }
    final int count = _selected.length;
    final bool sure = await _confirm("确认取消收藏选中的 $count 个贴子?");
    if (!sure || !mounted) {
      return;
    }
    setState(() => _deleting = true);
    int success = 0;
    int failed = 0;
    for (final String id in _selected.toList()) {
      try {
        await _remover(id);
        success++;
        if (!mounted) {
          return;
        }
        setState(() {
          _threads.removeWhere((TiebaStoredThread e) => e.id == id);
          _selected.remove(id);
        });
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _deleting = false;
      if (_threads.isEmpty) {
        _deleteMode = false;
        _selected.clear();
      }
    });
    if (failed == 0) {
      Fluttertoast.showToast(msg: "已取消收藏 $success 个贴子");
    } else {
      Fluttertoast.showToast(msg: "$success 个已取消，$failed 个失败");
    }
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool canEdit = _loggedIn && _threads.isNotEmpty;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: const Text("我的收藏"),
        actions: <Widget>[
          if (canEdit && _deleteMode)
            TextButton(
              onPressed: _toggleSelectAll,
              style: _actionStyle(tokens),
              child: Text(_allSelected ? "取消全选" : "全选"),
            ),
          if (canEdit)
            TextButton(
              onPressed: _toggleEdit,
              style: _actionStyle(tokens),
              child: Text(_deleteMode ? "取消" : "编辑"),
            ),
        ],
      ),
      body: ThreadStoreFeed(
        threads: _threads,
        loading: _loading,
        error: _error,
        notLoggedIn:
            !_loggedIn || (_error != null && _error.toString().contains("未登录")),
        loadingMore: _loadingMore,
        moreError: _moreError,
        hasMore: _hasMore,
        deleteMode: _deleteMode,
        selected: _selected,
        scrollController: _controller,
        onRefresh: _refresh,
        onRetry: _retry,
        onLoadMore: _loadNextPage,
        onOpen: _open,
        onToggleSelected: _toggleSelected,
        onRemove: _removeOne,
        onLogin: _onLogin,
      ),
      bottomNavigationBar: _deleteBar(tokens),
    );
  }

  ButtonStyle _actionStyle(TiebananaTokens tokens) {
    return TextButton.styleFrom(
      foregroundColor: tokens.primary,
      textStyle: Theme.of(context).textTheme.labelLarge,
      padding: const EdgeInsets.symmetric(horizontal: TiebananaMetrics.gapMd),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  /// 编辑态底部的「删除所选（n）」条目卡（概念图 `.sgroup` 的危险行）。
  Widget? _deleteBar(TiebananaTokens tokens) {
    if (!_deleteMode || _threads.isEmpty) {
      return null;
    }
    final bool canDelete = _selected.isNotEmpty && !_deleting;
    final Color foreground = canDelete ? tokens.danger : tokens.textTertiary;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          TiebananaMetrics.pageGutter,
          TiebananaMetrics.gapSm,
          TiebananaMetrics.pageGutter,
          TiebananaMetrics.gapSm,
        ),
        decoration: BoxDecoration(
          borderRadius: TiebananaMetrics.brLg,
          boxShadow: tokens.cardShadow,
        ),
        child: Material(
          color: tokens.surface,
          borderRadius: TiebananaMetrics.brLg,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: canDelete ? _removeSelected : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (_deleting)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    )
                  else
                    Icon(Icons.delete_outline_rounded,
                        size: 20, color: foreground),
                  const SizedBox(width: TiebananaMetrics.gapSm),
                  Text(
                    _deleting ? "正在删除…" : "删除所选（${_selected.length}）",
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: foreground),
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

/// 收藏列表的展示层：骨架 / 空 / 错误 / 未登录 / 列表。
///
/// 纯展示组件，数据和回调由 [ThreadStorePageRoute] 传入，便于单独渲染与测试。
class ThreadStoreFeed extends StatelessWidget {
  const ThreadStoreFeed({
    super.key,
    required this.threads,
    required this.loading,
    required this.error,
    required this.notLoggedIn,
    required this.loadingMore,
    required this.moreError,
    required this.hasMore,
    required this.deleteMode,
    required this.selected,
    required this.scrollController,
    required this.onRefresh,
    required this.onRetry,
    required this.onLoadMore,
    required this.onOpen,
    required this.onToggleSelected,
    required this.onRemove,
    required this.onLogin,
  });

  final List<TiebaStoredThread> threads;
  final bool loading;
  final Object? error;
  final bool notLoggedIn;
  final bool loadingMore;
  final Object? moreError;
  final bool hasMore;
  final bool deleteMode;
  final Set<String> selected;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final ValueChanged<TiebaStoredThread> onOpen;
  final ValueChanged<TiebaStoredThread> onToggleSelected;
  final ValueChanged<TiebaStoredThread> onRemove;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    if (notLoggedIn) {
      return _sheet(context, _loginView());
    }
    if (loading && threads.isEmpty) {
      return _sheet(context, const _ThreadStoreSkeletonList(), center: false);
    }
    if (error != null && threads.isEmpty) {
      return _sheet(context, _errorView());
    }
    if (threads.isEmpty) {
      return _sheet(context, _emptyView());
    }

    final bool showFooter = loadingMore || moreError != null;
    final bool showHint = !deleteMode && !hasMore && !showFooter;
    final int extra = (showFooter || showHint) ? 1 : 0;

    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          top: TiebananaMetrics.gapSm,
          bottom: TiebananaMetrics.gapMd,
        ),
        itemCount: threads.length + extra,
        itemBuilder: (BuildContext context, int index) {
          if (index >= threads.length) {
            return showFooter ? _footer(context) : _hint(context);
          }
          final TiebaStoredThread item = threads[index];
          return _row(context, item);
        },
      ),
    );
  }

  Widget _row(BuildContext context, TiebaStoredThread item) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Widget row = StoredThreadWidget(
      info: item,
      deleteMode: deleteMode,
      selected: selected.contains(item.id),
      onTap: () => onOpen(item),
      onToggleSelected: () => onToggleSelected(item),
    );

    return _cardShell(
      tokens,
      child: deleteMode
          ? row
          : SwipeActionRow(
              borderRadius: TiebananaMetrics.radiusLg,
              actions: <SwipeAction>[
                SwipeAction(
                  label: "取消收藏",
                  icon: Icons.star_border_rounded,
                  background: tokens.danger,
                  foreground: tokens.accentOn,
                  onTap: () => onRemove(item),
                ),
              ],
              child: row,
            ),
    );
  }

  /// 行外面的页面留白 + 投影。投影位于左滑容器的圆角裁剪之外。
  Widget _cardShell(TiebananaTokens tokens, {required Widget child}) {
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
      child: child,
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
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: center ? Center(child: child) : child,
            ),
          );
        },
      ),
    );
  }

  Widget _loginView() {
    return StateView(
      icon: Icons.person_outline_rounded,
      title: "登录后才能看收藏",
      body: "收藏列表跟着账号走，登录后就能看到",
      primaryLabel: "去登录",
      onPrimary: onLogin,
    );
  }

  Widget _errorView() {
    return StateView(
      icon: Icons.wifi_off_rounded,
      title: "收藏加载失败",
      body: "检查一下网络连接后重试",
      primaryLabel: "重试",
      primaryIcon: Icons.refresh,
      onPrimary: onRetry,
    );
  }

  Widget _emptyView() {
    return StateView(
      icon: Icons.star_border_rounded,
      title: "还没有收藏",
      body: "进贴后点右下角星标，收藏的帖子会出现在这里",
      primaryLabel: "刷新",
      primaryIcon: Icons.refresh,
      onPrimary: onRetry,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TiebananaMetrics.pageGutter,
        TiebananaMetrics.gapSm,
        TiebananaMetrics.pageGutter,
        TiebananaMetrics.gapLg,
      ),
      child: Text(
        "左滑可删除单条；点右上角「编辑」可批量。",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: TiebananaTokens.of(context).textTertiary,
            ),
      ),
    );
  }
}

/// 首屏骨架：形状与 [StoredThreadWidget] 对齐，数据到达时不整屏重排。
class _ThreadStoreSkeletonList extends StatelessWidget {
  const _ThreadStoreSkeletonList();

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
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const FractionallySizedBox(
                          widthFactor: 0.92,
                          child: SkeletonBox(height: 13),
                        ),
                        const SizedBox(height: TiebananaMetrics.gapSm),
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
                  const SizedBox(width: TiebananaMetrics.gapMd),
                  const SkeletonBox(
                    width: 54,
                    height: 54,
                    radius: TiebananaMetrics.radiusSm,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
