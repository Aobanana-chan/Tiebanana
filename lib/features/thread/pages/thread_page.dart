import 'dart:async';
import 'dart:math' as math;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/thread/state/reply_events.dart';
import 'package:tiebanana/features/thread/data/thread_cache.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/alert_dialog.dart';
import 'package:tiebanana/features/thread/widgets/thread_common.dart';
import 'package:tiebanana/features/thread/widgets/thread_first_comment.dart';
import 'package:tiebanana/features/thread/widgets/thread_floor_card.dart';
import 'package:tiebanana/features/thread/widgets/thread_reply_bar.dart';
import 'package:tiebanana/features/moderation/widgets/moderation_actions.dart';

///贴页面

class ThreadPageRoute extends StatefulWidget {
  final String kz;
  final String? pid;
  const ThreadPageRoute({super.key, required this.kz, this.pid});

  @override
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPageRoute> {
  final _mainKey = GlobalKey<ThreadPageMainState>();
  final _session = ThreadReadSession();
  late final String _uid;
  TiebaThreadPage? _page;
  bool _loading = true;
  bool _showLoadError = false;

  Future<void> _load() async {
    final cached = await Global.threadCache.read(_uid, widget.kz);
    if (!mounted) return;
    if (cached != null) setState(() => _page = cached);
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_session.paused) return;
    try {
      final data =
          await Global.tiebaAPI.getThreadPage(widget.kz, pid: widget.pid);
      if (!mounted || _uid != (AccountStore.currentUid ?? '')) return;
      await Global.threadCache.savePage(_uid, data,
          stored: data.isStored && (Global.setting.markedCache ?? true),
          completePage: widget.pid == null);
      if (!mounted) return;
      Global.daoapi.storeViewHistory(data.tid, data.title, data.forumName);
      if (_mainKey.currentState != null) {
        _mainKey.currentState!
            .applyFreshPage(data, completePage: widget.pid == null);
      } else {
        final merged = await Global.threadCache.read(_uid, widget.kz);
        if (!mounted) return;
        setState(() => _page = merged ?? data);
      }
    } catch (e) {
      if (mounted) {
        _session.fail(e);
        if (_page == null) {
          _showLoadError = true;
          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('加载失败，请稍后重试'),
              duration: Duration(seconds: 2),
            ));
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _retry() {
    if (_loading) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    _session.retry();
    setState(() => _loading = true);
    _refresh();
  }

  @override
  void initState() {
    super.initState();
    _uid = AccountStore.currentUid ?? '';
    _load();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _page;
    if (data != null) {
      return Scaffold(
          body: ThreadPageMain(
        key: _mainKey,
        kz: widget.kz,
        pid: widget.pid,
        pn: data.page.currentPage,
        page: data,
        initPost: data.posts,
        session: _session,
        cacheUid: _uid,
      ));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('帖子')),
      body: _showLoadError
          ? _ThreadLoadError(loading: _loading, onRetry: _retry)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

/// 无缓存时在页内显示加载和重试状态。
class _ThreadLoadError extends StatelessWidget {
  const _ThreadLoadError({required this.loading, required this.onRetry});

  final bool loading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = TiebananaTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(TiebananaMetrics.gapXXl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(TiebananaMetrics.gapLg),
                        decoration: BoxDecoration(
                          color: tokens.fill,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.article_outlined,
                            size: 32, color: tokens.textTertiary),
                      ),
                      const SizedBox(height: TiebananaMetrics.gapXl),
                      Text('帖子暂时打不开',
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium
                              ?.copyWith(color: tokens.textPrimary)),
                      const SizedBox(height: TiebananaMetrics.gapSm),
                      Text('请稍后重试，当前暂无可用缓存',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: tokens.textSecondary)),
                      const SizedBox(height: TiebananaMetrics.gapXl),
                      FilledButton.icon(
                        onPressed: loading ? null : onRetry,
                        icon: loading
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(loading ? '正在重试…' : '重试'),
                      ),
                      if (Navigator.of(context).canPop()) ...[
                        const SizedBox(height: TiebananaMetrics.gapSm),
                        TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Text('返回'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class ThreadPageMain extends StatefulWidget {
  /// 帖子 id。
  final String kz;

  /// 首次响应的帖子页（含帖/吧/作者/视频等信息）。
  final TiebaThreadPage page;

  /// 定位楼层 / 页码。
  final String? pid;
  final int? pn;

  /// 首屏楼层（等于 `page.posts`，这里显式传入便于阅读）。
  final List<TiebaThreadPagePost> initPost;
  final ThreadReadSession? session;
  final String? cacheUid;

  const ThreadPageMain({
    super.key,
    required this.kz,
    required this.page,
    required this.pid,
    required this.pn,
    required this.initPost,
    this.session,
    this.cacheUid,
  });

  @override
  ThreadPageMainState createState() => ThreadPageMainState();
}

class ThreadPageMainState extends State<ThreadPageMain> {
  late TiebaThreadPage info;
  late final ThreadReadSession session;
  late final String cacheUid;
  bool _manualRefreshing = false;

  final ScrollController _controller = ScrollController();

  ///只看楼主
  bool lz = false;

  ///目前滑到的pid（收藏 / 续读用）。
  String pid = '';

  ///收藏状态。底部条与卡片菜单共用，退出时的续读弹窗也读这里。
  late final ValueNotifier<bool> _stored;

  ///主题赞 / 踩，仅在底部回复条显示。
  ThreadAgreeController? _threadAgree;

  ///0 = 热门排序，1 = 正序，2 = 倒序。
  int _sortMode = 1;

  bool _loading = false;
  bool _replyRefreshPending = false;
  String? _replyFloorId;
  bool _loadingPrevious = false;
  bool _previousFailed = false;
  bool _nextFailed = false;
  // pid 响应可能只包含目标楼层之后的内容，先补全所在页再向前翻。
  bool _needsFullLocatedPage = false;
  final Map<String, GlobalKey> _floorKeys = <String, GlobalKey>{};

  // 两种模式各自记录页码和是否有更多，切换时保留各自的翻页进度。
  int _normalTopPn = 1;
  int _normalBottomPn = 1;
  int _lzTopPn = 1;
  int _lzBottomPn = 1;
  bool _normalHasMore = false;
  bool _lzHasMore = true;
  bool _normalHasPrev = false;
  bool _lzHasPrev = false;

  bool get isStored => _stored.value;
  set isStored(bool value) => _stored.value = value;

  @override
  void initState() {
    super.initState();
    session = widget.session ?? ThreadReadSession();
    cacheUid = widget.cacheUid ?? AccountStore.currentUid ?? '';
    session.addListener(_sessionChanged);

    final int pn = math.max(1, widget.pn ?? 1);
    _needsFullLocatedPage = widget.pid != null;
    pid = widget.pid ?? '';
    info = widget.page
      ..initPid = widget.pid
      ..topPn = pn
      ..bottomPn = pn;
    info.postPage.putIfAbsent(pn, () => widget.initPost);
    final normal = info.postPage.keys.where((k) => k > 0).toList()..sort();
    final owner = info.postPage.keys.where((k) => k < 0).map((k) => -k).toList()
      ..sort();
    _normalTopPn = normal.isEmpty ? pn : normal.first;
    _normalBottomPn = normal.isEmpty ? pn : normal.last;
    _lzTopPn = owner.isEmpty ? 1 : owner.first;
    _lzBottomPn = owner.isEmpty ? 1 : owner.last;
    info.topPn = _normalTopPn;
    info.bottomPn = _normalBottomPn;
    _normalHasMore = widget.page.postPage.length > 1
        ? widget.page.hasMore
        : widget.page.page.hasMore;
    _normalHasPrev = widget.page.hasPrev || _normalTopPn > 1;
    info.hasMore = _normalHasMore;
    info.hasPrev = _normalHasPrev;

    _stored = ValueNotifier<bool>(info.isStored);
    _stored.addListener(_storeChanged);
    _threadAgree = _createThreadAgree();

    collectImages();

    _controller.addListener(_onScrollNext);
    _controller.addListener(_onScrollPrev);
    replyEvents.addListener(_onReplySent);
  }

  void _sessionChanged() {
    if (mounted) setState(() {});
  }

  void _storeChanged() {
    info.isStored = isStored;
    unawaited(_persistStored());
  }

  Future<void> _persistStored() async {
    await Global.threadCache.setStored(cacheUid, info.tid, isStored,
        keepLongTerm: Global.setting.markedCache ?? true);
  }

  /// 后台更新不替换 State / 滚动控制器，保留旧楼层与已经展开的内容。
  void applyFreshPage(TiebaThreadPage page,
      {bool onlyLz = false, bool completePage = false}) {
    final pn = page.page.currentPage;
    final key = onlyLz ? -pn : pn;
    info.postPage[key] = ThreadCache.mergePosts(
        info.postPage[key] ?? [], page.posts,
        markMissingDeleted: completePage, aliveIds: _aliveFloorIds(key));
    info.userListSet.addAll(page.userListSet);
    info.title = page.title;
    info.thread = page.thread;
    info.videoInfo = page.videoInfo ?? info.videoInfo;
    info.page = page.page;
    info.fid = page.fid;
    info.forumName = page.forumName;
    info.avatar = page.avatar;
    // 收藏状态只由成功的主帖响应更新。
    info.isStored = page.isStored;
    _stored.value = page.isStored;
    if (onlyLz) {
      if (pn >= _lzBottomPn) _lzHasMore = page.page.hasMore;
      if (pn <= _lzTopPn) _lzHasPrev = page.page.hasPrev;
      _lzTopPn = math.min(_lzTopPn, pn);
      _lzBottomPn = math.max(_lzBottomPn, pn);
    } else {
      if (pn >= _normalBottomPn) _normalHasMore = page.page.hasMore;
      if (pn <= _normalTopPn) _normalHasPrev = page.page.hasPrev;
      _normalTopPn = math.min(_normalTopPn, pn);
      _normalBottomPn = math.max(_normalBottomPn, pn);
    }
    info.topPn = lz ? _lzTopPn : _normalTopPn;
    info.bottomPn = lz ? _lzBottomPn : _normalBottomPn;
    info.hasMore = lz ? _lzHasMore : _normalHasMore;
    info.hasPrev = lz ? _lzHasPrev : _normalHasPrev;
    collectImages();
    _threadAgree ??= _createThreadAgree();
    if (mounted) setState(() {});
  }

  /// 同一模式下其它已加载页里的楼层 id。
  ///
  /// 删除楼层会让后面的楼层前移，同一楼层可能暂时只出现在相邻页的旧缓存里；
  /// 这些 id 视为边界楼层，翻页时保持原状态。
  Set<String> _aliveFloorIds(int key) => <String>{
        for (final MapEntry<int, List<TiebaThreadPagePost>> entry
            in info.postPage.entries)
          if (entry.key != key && (entry.key < 0) == (key < 0))
            for (final TiebaThreadPagePost p in entry.value) p.id,
      };

  Future<void> _manualRefresh() async {
    if (_loading || _manualRefreshing) return;
    session.retry();
    _nextFailed = false;
    _previousFailed = false;
    setState(() => _manualRefreshing = true);
    try {
      final page = await Global.tiebaAPI
          .getThreadPage(widget.kz, pn: info.topPn ?? 1, onlyLz: lz);
      if (!mounted || cacheUid != (AccountStore.currentUid ?? '')) return;
      await Global.threadCache.savePage(cacheUid, page,
          onlyLz: lz,
          stored: page.isStored && (Global.setting.markedCache ?? true));
      if (mounted) applyFreshPage(page, onlyLz: lz, completePage: true);
    } catch (e) {
      if (mounted) session.fail(e);
    } finally {
      if (mounted) setState(() => _manualRefreshing = false);
    }
  }

  void _onReplySent() {
    if (replyEvents.threadId != widget.kz) return;
    _replyFloorId = replyEvents.floorId;
    _replyRefreshPending = true;
    _refreshAfterReply();
  }

  Future<void> _refreshAfterReply() async {
    if (_loading || !_replyRefreshPending) return;
    _replyRefreshPending = false;
    final String? floorId = _replyFloorId;
    final int bottom = info.bottomPn ?? 1;
    final bool wasLastPage = !info.hasMore;
    final pages = info.postPage.entries
        .where((entry) => (entry.key < 0) == lz)
        .where((entry) => floorId == null
            ? entry.key.abs() == bottom
            : entry.value.any((post) => post.id == floorId))
        .map((entry) => entry.key.abs())
        .toList();
    for (final page in pages) {
      if (!mounted) return;
      await _fetchPage(page, reload: true);
    }
    // 末页满页时新回复会进入下一页。
    if (mounted && floorId == null && wasLastPage && info.hasMore) {
      await _fetchPage(bottom + 1);
    }
  }

  ThreadAgreeController? _createThreadAgree() {
    final TiebaThreadPagePost? first = _firstPost;
    if (first == null) {
      return null;
    }
    return ThreadAgreeController(
      postId: first.id,
      threadId: info.tid,
      objType: 3,
      forumId: info.fid,
      agreeNum: int.tryParse(first.agreeNum) ?? 0,
      disagreeNum: int.tryParse(first.disagreeNum) ?? 0,
      hasAgree: first.hasAgree,
      agreeType: int.tryParse(
            (info.thread.agreeType?.isNotEmpty ?? false)
                ? info.thread.agreeType!
                : first.agreeType,
          ) ??
          0,
    );
  }

  ///当前模式（全部 / 只看楼主）的楼层。
  List<TiebaThreadPagePost> get _currentPosts {
    final Set<String> seen = <String>{};
    final first = info.postList.where((p) => p.floor == '1').firstOrNull;
    final owner = first?.uid;
    return (lz
            ? ThreadCache.mergePosts(
                info.postList
                    .where((p) => owner != null && p.uid == owner)
                    .toList(),
                info.lzPostList)
            : info.postList)
        .where((TiebaThreadPagePost post) => seen.add(post.id))
        .toList();
  }

  ///首楼。深页或定位楼层进入时可能不在当前响应里，此时返回 null。
  TiebaThreadPagePost? get _firstPost {
    for (final TiebaThreadPagePost post in _currentPosts) {
      if (post.floor == '1') return post;
    }
    for (final TiebaThreadPagePost post in info.postList) {
      if (post.floor == '1') return post;
    }
    return null;
  }

  //快滑到页面底部加载下一页
  void _onScrollNext() {
    if (!_controller.hasClients || _loading || _nextFailed) return;
    if (_controller.position.userScrollDirection != ScrollDirection.reverse) {
      return;
    }
    final ScrollPosition position = _controller.position;
    // 提前约一屏预取，网络请求与用户继续阅读同时进行。
    if (position.extentAfter <=
        math.max(480, position.viewportDimension * 1.2)) {
      nextPage();
    }
  }

  //快滑到页面顶部加载前一页
  void _onScrollPrev() {
    if (!_controller.hasClients || _loading || _previousFailed) return;
    if (_controller.position.userScrollDirection != ScrollDirection.forward) {
      return;
    }
    if (_controller.position.pixels < _controller.position.viewportDimension) {
      prevPage();
    }
  }

  bool get _hasPrevious => info.hasPrev || (!lz && _needsFullLocatedPage);

  /// 参与主楼投票；成功后刷新第一页的帖元数据以拿到最新票数与已投状态。
  Future<void> _voteThreadPoll(Set<int> optionIds) async {
    await Global.tiebaAPI.voteThreadPoll(info.tid, info.fid, optionIds);
    if (!mounted) return;
    try {
      final TiebaThreadPage page =
          await Global.tiebaAPI.getThreadPage(widget.kz, pn: 1, onlyLz: lz);
      if (!mounted || cacheUid != (AccountStore.currentUid ?? '')) return;
      await Global.threadCache.savePage(cacheUid, page,
          onlyLz: lz, stored: isStored && (Global.setting.markedCache ?? true));
      if (!mounted) return;
      // 只更新帖元数据（投票状态 / 票数），不动已读楼层与滚动位置。
      setState(() => info.thread = page.thread);
    } catch (_) {
      // 投票已经成功；刷新失败时保留旧卡片，下次手动刷新会补上。
    }
  }

  Future<void> _fetchPage(int pn,
      {bool refresh = false,
      bool previous = false,
      bool reload = false}) async {
    if (_loading || _manualRefreshing || session.paused || pn < 1) return;
    if (!refresh && !reload && !(previous ? _hasPrevious : info.hasMore)) {
      return;
    }
    setState(() {
      _loading = true;
      _loadingPrevious = previous;
      if (previous) {
        _previousFailed = false;
      } else {
        _nextFailed = false;
      }
    });
    try {
      final TiebaThreadPage page =
          await Global.tiebaAPI.getThreadPage(widget.kz, pn: pn, onlyLz: lz);
      if (!mounted) return;
      if (cacheUid != (AccountStore.currentUid ?? '')) return;
      await Global.threadCache.savePage(cacheUid, page,
          onlyLz: lz, stored: isStored && (Global.setting.markedCache ?? true));
      if (!mounted) return;
      // 记录仍可见的楼层；补入前页后按同一楼层校正滚动位置。
      GlobalKey? anchor;
      double? anchorY;
      final double oldExtent =
          _controller.hasClients ? _controller.position.maxScrollExtent : 0;
      final double oldOffset = _controller.hasClients ? _controller.offset : 0;
      if (previous) {
        for (final TiebaThreadPagePost post in _sortedFloors()) {
          final GlobalKey? key = _floorKeys[post.id];
          final RenderObject? render = key?.currentContext?.findRenderObject();
          if (render is RenderBox && render.attached) {
            final double y = render.localToGlobal(Offset.zero).dy;
            if (y + render.size.height > kToolbarHeight &&
                y < MediaQuery.sizeOf(context).height) {
              anchor = key;
              anchorY = y;
              break;
            }
          }
        }
      }
      final key = pn * (lz ? -1 : 1);
      info.postPage[key] = ThreadCache.mergePosts(
          info.postPage[key] ?? [], page.posts,
          markMissingDeleted: true, aliveIds: _aliveFloorIds(key));
      if (lz) {
        if (pn >= _lzBottomPn) _lzHasMore = page.page.hasMore;
        if (pn <= _lzTopPn) _lzHasPrev = page.page.hasPrev;
        _lzTopPn = math.min(_lzTopPn, pn);
        _lzBottomPn = math.max(_lzBottomPn, pn);
      } else {
        if (pn >= _normalBottomPn) {
          _normalHasMore = page.page.hasMore;
        }
        if (pn <= _normalTopPn) {
          _normalHasPrev = page.page.hasPrev;
        }
        if (refresh || previous) _needsFullLocatedPage = false;
        _normalTopPn = math.min(_normalTopPn, pn);
        _normalBottomPn = math.max(_normalBottomPn, pn);
      }
      info.hasMore = lz ? _lzHasMore : _normalHasMore;
      info.hasPrev = lz ? _lzHasPrev : _normalHasPrev;
      info.topPn = lz ? _lzTopPn : _normalTopPn;
      info.bottomPn = lz ? _lzBottomPn : _normalBottomPn;
      info.userListSet.addAll(page.userListSet);
      setState(() {
        _loading = false;
        collectImages();
        _threadAgree ??= _createThreadAgree();
      });
      if (previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_controller.hasClients) return;
          final RenderObject? render =
              anchor?.currentContext?.findRenderObject();
          final double delta =
              render is RenderBox && render.attached && anchorY != null
                  ? render.localToGlobal(Offset.zero).dy - anchorY
                  : _controller.position.maxScrollExtent - oldExtent;
          _controller.jumpTo((oldOffset + delta).clamp(
              _controller.position.minScrollExtent,
              _controller.position.maxScrollExtent));
        });
      }
    } catch (e) {
      if (!mounted) return;
      session.fail(e);
      setState(() {
        _loading = false;
        if (previous) {
          _previousFailed = true;
        } else {
          _nextFailed = true;
        }
      });
    } finally {
      if (mounted && _loading) setState(() => _loading = false);
      if (mounted && _replyRefreshPending) _refreshAfterReply();
    }
  }

  //下一页
  void nextPage() {
    _fetchPage((info.bottomPn ?? 1) + 1);
  }

  //上一页
  void prevPage() {
    _fetchPage((info.topPn ?? 1) - (!lz && _needsFullLocatedPage ? 0 : 1),
        previous: true);
  }

  ///只看楼主。两种模式各自缓存页数据，来回切换时复用。
  void onlyLz() {
    if (_loading) return;
    setState(() {
      _previousFailed = false;
      _nextFailed = false;
      lz = !lz;
      info.topPn = lz ? _lzTopPn : _normalTopPn;
      info.bottomPn = lz ? _lzBottomPn : _normalBottomPn;
      info.hasMore = lz ? _lzHasMore : _normalHasMore;
      info.hasPrev = lz ? _lzHasPrev : _normalHasPrev;
    });
    if (_currentPosts.isEmpty) {
      _fetchPage(1, refresh: true);
    }
  }

  void collectImages() {
    info.imgs.clear();
    info.imgsOrgSrc.clear();
    for (final List<TiebaThreadPagePost> page in info.postPage.values) {
      for (final TiebaThreadPagePost post in page) {
        for (final TiebaPostContent content in post.content) {
          if (content is TiebaImageContent) {
            info.imgs.add(content.displaySrc);
            info.imgsOrgSrc.add(content.originalSrc);
          }
        }
      }
    }
  }

  TiebaAuthor _authorOf(TiebaPost post) {
    return info.userListSet[post.uid] ??
        TiebaAuthor(
          icons: const <String>[],
          levelID: null,
          nameShow: post.nameShow,
          portrait: post.portrait,
          uid: post.uid,
          username: post.username,
        );
  }

  int _floorOf(TiebaThreadPagePost post) => int.tryParse(post.floor ?? '') ?? 0;

  ///排序只作用于已加载的楼层。热门 = 赞数降序，同赞按楼层正序。
  List<TiebaThreadPagePost> _sortedFloors() {
    final List<TiebaThreadPagePost> floors = _currentPosts
        .where((TiebaThreadPagePost post) => post.floor != '1')
        .toList();
    switch (_sortMode) {
      case 1:
        floors.sort((TiebaThreadPagePost a, TiebaThreadPagePost b) =>
            _floorOf(a).compareTo(_floorOf(b)));
        break;
      case 2:
        floors.sort((TiebaThreadPagePost a, TiebaThreadPagePost b) =>
            _floorOf(b).compareTo(_floorOf(a)));
        break;
      default:
        floors.sort((TiebaThreadPagePost a, TiebaThreadPagePost b) {
          final int byAgree = (int.tryParse(b.agreeNum) ?? 0)
              .compareTo(int.tryParse(a.agreeNum) ?? 0);
          return byAgree != 0 ? byAgree : _floorOf(a).compareTo(_floorOf(b));
        });
    }
    return floors;
  }

  List<Widget> buildFloor() {
    final String ownerUid = info.thread.authorUid.isNotEmpty
        ? info.thread.authorUid
        : (_firstPost?.uid ?? '');
    final List<Widget> widgets = <Widget>[];
    for (final TiebaThreadPagePost floor in _sortedFloors()) {
      widgets.add(ThreadFloorComment(
        key: _floorKeys.putIfAbsent(floor.id, GlobalKey.new),
        allImgs: info.imgs,
        allOrgImgs: info.imgsOrgSrc,
        author: _authorOf(floor),
        postMain: floor,
        userList: info.userListSet,
        threadID: info.tid,
        threadTitle: info.title,
        forum: info,
        isOp: ownerUid.isNotEmpty && floor.uid == ownerUid,
        threadOwnerUid: ownerUid,
        storedNotifier: _stored,
      ));
    }
    return widgets;
  }

  Future<void> _handleMenu(String value) async {
    if (value == 'refresh') {
      await _manualRefresh();
      return;
    }
    if (value == 'report') {
      final post = _firstPost;
      final author = post == null ? null : _authorOf(post);
      await openReportPage(
          context,
          TiebaReportTarget(
              kind: TiebaReportKind.thread,
              userId: author?.id ?? '',
              name: author?.name ?? '',
              portrait: author?.portrait ?? '',
              threadId: info.tid,
              postId: post?.id ?? '',
              summary: info.title));
      return;
    }
    if (value == 'jump') {
      final int? page = await showDialog<int>(
        context: context,
        builder: (BuildContext context) => _JumpPageDialog(
          currentPage: info.page.currentPage,
        ),
      );
      if (page != null && mounted) {
        await _fetchPage(page, refresh: true);
        if (_controller.hasClients) {
          _controller.jumpTo(0);
        }
      }
      return;
    }
    if (value == 'share') {
      await Clipboard.setData(
        ClipboardData(text: 'https://tieba.baidu.com/p/${info.tid}'),
      );
      if (!mounted) return;
      Fluttertoast.showToast(msg: '链接已复制');
    }
  }

  List<Widget> _appBarActions(TiebananaTokens tokens) {
    return <Widget>[
      Tooltip(
        message: lz ? '看全部楼层' : '只看楼主',
        child: Material(
          color: lz ? tokens.primaryContainer : tokens.fill,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onlyLz,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: Text(
                  '楼',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: lz
                            ? tokens.onPrimaryContainer
                            : tokens.textSecondary,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
      PopupMenuButton<String>(
        tooltip: '更多',
        position: PopupMenuPosition.under,
        color: tokens.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: TiebananaMetrics.brLg),
        onSelected: _handleMenu,
        icon: Icon(Icons.more_vert_rounded, color: tokens.textSecondary),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          _appMenuItem(context, 'refresh', Icons.refresh_rounded, '刷新帖子'),
          _appMenuItem(
              context, 'jump', Icons.format_list_numbered_rounded, '跳页'),
          _appMenuItem(context, 'share', Icons.ios_share_rounded, '分享'),
          if ((int.tryParse(info.tid) ?? 0) > 0)
            _appMenuItem(context, 'report', Icons.flag_outlined, '举报帖子'),
        ],
      ),
      const SizedBox(width: 4),
    ];
  }

  PopupMenuItem<String> _appMenuItem(
    BuildContext context,
    String value,
    IconData icon,
    String label,
  ) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: tokens.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: tokens.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _sortBar(TiebananaTokens tokens) {
    const List<String> labels = <String>['热门排序', '正序', '倒序'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TiebananaMetrics.pageGutter,
        TiebananaMetrics.gapSm,
        TiebananaMetrics.pageGutter,
        TiebananaMetrics.gapSm,
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < labels.length; i++) ...<Widget>[
            if (i != 0) const SizedBox(width: 6),
            Expanded(
              child: _SortButton(
                label: labels[i],
                active: _sortMode == i,
                onTap: () => setState(() => _sortMode = i),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _listFooter(TiebananaTokens tokens) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double pull =
            _controller.hasClients && _controller.position.hasContentDimensions
                ? (_controller.offset - _controller.position.maxScrollExtent)
                    .clamp(0.0, 80.0)
                : 0;
        return ClipRect(
          child: SizedBox(
            height: pull,
            child: OverflowBox(
              alignment: Alignment.bottomCenter,
              minHeight: 64,
              maxHeight: 64,
              child: Opacity(
                opacity: (pull / 48).clamp(0.0, 1.0),
                child: Semantics(
                  liveRegion: true,
                  child: Center(
                    child: info.hasMore
                        ? TickerMode(
                            enabled: pull > 0,
                            child: _LoadingCaption(
                                label: '正在全力加载中', color: tokens.primary),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                  width: 24, height: 1, color: tokens.line),
                              const SizedBox(width: 12),
                              Text('苏格拉也有底',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                          color: tokens.textTertiary,
                                          letterSpacing: 2)),
                              const SizedBox(width: 12),
                              Container(
                                  width: 24, height: 1, color: tokens.line),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _previousPageEntry(TiebananaTokens tokens) {
    final bool loading = _loading && _loadingPrevious;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 4, 28, 12),
        child: Row(
          children: <Widget>[
            Expanded(child: Divider(color: tokens.line)),
            const SizedBox(width: 12),
            Material(
              color: tokens.surface,
              borderRadius: TiebananaMetrics.brPill,
              child: InkWell(
                borderRadius: TiebananaMetrics.brPill,
                onTap: _loading ? null : prevPage,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: loading
                      ? _LoadingCaption(
                          label: '正在加载前面的楼层…', color: tokens.primary)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                                _previousFailed
                                    ? Icons.refresh_rounded
                                    : Icons.keyboard_double_arrow_up_rounded,
                                size: 16,
                                color: tokens.primary),
                            const SizedBox(width: 6),
                            Text(_previousFailed ? '加载失败，点击重试' : '查看更早的楼层',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(color: tokens.textSecondary)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: tokens.line)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TiebaThreadPagePost? first = _firstPost;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        if (isStored && !session.paused) {
          final bool? q = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => const TiebaAlterDialog(
              title: '本次阅读到这里，是否更新收藏楼层?',
            ),
          );
          if (q == null) {
            //取消弹窗，留在当前页
            return;
          } else if (q == true) {
            try {
              await Global.tiebaAPI.threadAddStore(info.tid, pid);
            } catch (e) {
              if (mounted) session.fail(e);
            }
          }
        }
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                CustomScrollView(
                  controller: _controller,
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  slivers: <Widget>[
                    SliverAppBar(
                      //issue：#32563，expandedHeight要大于collapsedHeight，不然可能会无法滑动
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      backgroundColor: tokens.bg,
                      surfaceTintColor: Colors.transparent,
                      foregroundColor: tokens.textPrimary,
                      pinned: true,
                      snap: true,
                      floating: true,
                      centerTitle: true,
                      actions: _appBarActions(tokens),
                      title: GestureDetector(
                        onTap: () {
                          _controller.animateTo(
                            0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeIn,
                          );
                        },
                        child: Text(
                          info.title,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: tokens.textPrimary,
                                  ),
                        ),
                      ),
                    ),

                    //一楼
                    if (first != null)
                      SliverToBoxAdapter(
                        child: ThreadFirstComment(
                          postMain: first,
                          author: _authorOf(first),
                          videoInfo: info.videoInfo,
                          allImgs: info.imgs,
                          allOrgImgs: info.imgsOrgSrc,
                          threadID: info.tid,
                          threadTitle: info.title,
                          storedNotifier: _stored,
                          poll: info.thread.poll,
                          hasPoll: info.thread.hasPoll,
                          fid: info.fid,
                          forumName: info.forumName,
                          onVote: _voteThreadPoll,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: FourmBar(
                        avatar: info.avatar,
                        name: info.forumName,
                      ),
                    ),
                    SliverToBoxAdapter(child: _sortBar(tokens)),
                    if (session.paused || _manualRefreshing)
                      SliverToBoxAdapter(
                          child: ListTile(
                        dense: true,
                        leading: Icon(session.paused
                            ? Icons.offline_bolt_outlined
                            : Icons.sync),
                        title:
                            Text(session.paused ? '正在浏览缓存，自动请求已暂停' : '正在更新帖子…'),
                        subtitle: session.paused
                            ? const Text('服务器暂时无法访问，已保留加载内容')
                            : null,
                        trailing: session.paused
                            ? TextButton(
                                onPressed: _manualRefresh,
                                child: const Text('刷新'))
                            : null,
                      )),
                    if (_hasPrevious || (_loading && _loadingPrevious))
                      SliverToBoxAdapter(
                        child: _previousPageEntry(tokens),
                      ),

                    //其他楼
                    SliverList(
                      delegate: SliverChildListDelegate(buildFloor()),
                    ),
                    if (_nextFailed && !session.paused)
                      SliverToBoxAdapter(
                        child: Center(
                          child: TextButton.icon(
                            onPressed: _loading ? null : nextPage,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('加载失败，点击重试'),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(child: _listFooter(tokens)),
                ),
              ],
            ),
          ),
          //回复条
          ThreadReplyBar(
            fid: info.fid,
            tid: info.tid,
            kw: info.forumName,
            replyText: info.title,
            storedNotifier: _stored,
            agreeController: _threadAgree,
            storeCount: info.thread.storeCount,
            initiallyStored: info.isStored,
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    replyEvents.removeListener(_onReplySent);
    _controller.removeListener(_onScrollNext);
    _controller.removeListener(_onScrollPrev);
    _controller.dispose();
    _stored.removeListener(_storeChanged);
    _stored.dispose();
    session.removeListener(_sessionChanged);
    if (widget.session == null) session.dispose();
    _threadAgree?.dispose();
    super.dispose();
  }
}

/// 三个错峰跃动的小点；减少动态效果时使用静态点。
class _LoadingCaption extends StatefulWidget {
  const _LoadingCaption({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  State<_LoadingCaption> createState() => _LoadingCaptionState();
}

class _LoadingCaptionState extends State<_LoadingCaption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _animation.stop();
    } else {
      _animation.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (BuildContext context, Widget? child) => Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < 3; i++)
                  Transform.translate(
                    offset: Offset(
                        0,
                        -3 *
                            math.max(
                                0,
                                math.sin((_animation.value * 2 * math.pi) -
                                    i * 0.9))),
                    child: Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                          color: widget.color, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(widget.label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: widget.color)),
      ],
    );
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }
}

/// 吧导航卡：进吧入口。
class FourmBar extends StatelessWidget {
  final String name;
  final String avatar;
  const FourmBar({super.key, required this.name, required this.avatar});

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        TiebananaMetrics.pageGutter,
        TiebananaMetrics.gapSm,
        TiebananaMetrics.pageGutter,
        TiebananaMetrics.gapSm,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: TiebananaMetrics.brLg,
        child: InkWell(
          borderRadius: TiebananaMetrics.brLg,
          onTap: () {
            Navigator.pushNamed(
              context,
              PageRouter.forumHome,
              arguments: name,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: avatar.isEmpty
                        ? Container(
                            color: tokens.fill,
                            child: Icon(
                              Icons.forum_outlined,
                              size: 18,
                              color: tokens.textTertiary,
                            ),
                          )
                        : ExtendedImage.network(
                            avatar,
                            fit: BoxFit.cover,
                            cache: true,
                          ),
                  ),
                ),
                const SizedBox(width: TiebananaMetrics.gapSm),
                Expanded(
                  child: Text(
                    '$name吧',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge
                        ?.copyWith(color: tokens.textPrimary),
                  ),
                ),
                Text(
                  '进吧',
                  style: textTheme.labelMedium?.copyWith(
                    color: tokens.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: tokens.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Material(
      color: active ? tokens.primaryContainer : tokens.fill,
      borderRadius: TiebananaMetrics.brPill,
      child: InkWell(
        borderRadius: TiebananaMetrics.brPill,
        onTap: onTap,
        child: SizedBox(
          height: 36,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? tokens.onPrimaryContainer
                        : tokens.textSecondary,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JumpPageDialog extends StatefulWidget {
  const _JumpPageDialog({required this.currentPage});

  final int currentPage;

  @override
  State<_JumpPageDialog> createState() => _JumpPageDialogState();
}

class _JumpPageDialogState extends State<_JumpPageDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final int? page = int.tryParse(_controller.text.trim());
    if (page == null || page < 1) {
      Fluttertoast.showToast(msg: '请输入正确的页码');
      return;
    }
    Navigator.pop(context, page);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: TiebananaMetrics.brLg),
      title: const Text('跳页'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: '当前第 ${widget.currentPage} 页',
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('跳转'),
        ),
      ],
    );
  }
}
