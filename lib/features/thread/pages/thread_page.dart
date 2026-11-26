import 'dart:async';
import 'dart:math' as math;

import 'package:extended_image/extended_image.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/core/platform/official_tieba.dart';
import 'package:tiebanana/features/media/state/image_upload.dart';
import 'package:tiebanana/shared/content/emoji_panel.dart';
import 'package:tiebanana/shared/content/posting_risk_warning.dart';
import 'package:tiebanana/shared/content/special_span.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/layout/page_wrap.dart';
import 'package:tiebanana/shared/widgets/app_toast.dart';
import 'package:tiebanana/shared/widgets/desktop_panel.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';

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
import 'package:tiebanana/features/share/models/share_content.dart';
import 'package:tiebanana/features/share/widgets/share_sheet.dart';

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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final bool desktop = width >= AppBreakpoints.compactMax;

        if (data != null) {
          final Widget main = ThreadPageMain(
            key: _mainKey,
            kz: widget.kz,
            pid: widget.pid,
            pn: data.page.currentPage,
            page: data,
            initPost: data.posts,
            session: _session,
            cacheUid: _uid,
          );
          if (desktop) return main;
          return Scaffold(body: main);
        }

        final Widget body = _showLoadError
            ? _ThreadLoadError(loading: _loading, onRetry: _retry)
            : const Center(child: CircularProgressIndicator());
        if (desktop) {
          return DesktopShellFrame(
            title: '帖子详情',
            activeTab: -1,
            onRefresh: _retry,
            child: body,
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('帖子')),
          body: body,
        );
      },
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

class ThreadPageMainState extends State<ThreadPageMain>
    with TickerProviderStateMixin {
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

  /// 桌面端右侧停靠回复框目标楼层（null 表示回复主题）。
  TiebaThreadPagePost? _replyTargetFloor;
  final TextEditingController _jumpInput = TextEditingController();

  bool _loading = false;
  bool _replyRefreshPending = false;
  String? _replyFloorId;
  bool _loadingPrevious = false;
  bool _previousFailed = false;
  bool _nextFailed = false;

  /// 内容和底部提示共享同一位移；松手后回弹到提示高度，完成后才收起。
  late final AnimationController _bottomPull =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _newFloorFade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 360), value: 1);
  final Set<String> _newBottomFloorIds = <String>{};
  bool _bottomNoNewContent = false;
  Timer? _bottomResultTimer;

  /// 正在执行底部刷新 / 末页重载。
  bool _bottomRefreshing = false;
  bool _bottomRefreshFailed = false;

  /// 本次下拉手势是否已经触发过刷新，保证一次手势只请求一次。
  bool _bottomPullTriggered = false;
  DateTime? _lastBottomRefreshAt;
  static const double _bottomRefreshThreshold = 56;

  static const Duration _bottomRefreshThrottle = Duration(milliseconds: 1500);
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
    if (_loading || _manualRefreshing || _bottomRefreshing) return;
    _bottomResultTimer?.cancel();
    _bottomNoNewContent = false;
    _collapseBottomPull();
    session.retry();
    _nextFailed = false;
    _previousFailed = false;
    _bottomRefreshFailed = false;
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

  /// 底部下拉手势。
  ///
  /// 底部阻止系统回弹，用 overscroll 累积位移；同时兼容 offset 越界的通知。
  bool _onBottomScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification.metrics.axis != Axis.vertical) return false;
    if (_bottomRefreshing || _manualRefreshing) return false;

    if (notification is ScrollStartNotification) {
      // 回弹 / 惯性滚动也会发 Start，只把用户手势开始算作新的一次下拉。
      if (notification.dragDetails == null) return false;
      _bottomResultTimer?.cancel();
      _bottomPull.stop();
      _bottomNoNewContent = false;
      _bottomPullTriggered = _bottomPull.value >= _bottomRefreshThreshold;
      // 离开底部开始新的阅读手势时收起刷新失败提示。
      if (_bottomRefreshFailed && notification.metrics.extentAfter > 0) {
        setState(() => _bottomRefreshFailed = false);
      }
      return false;
    }
    if (notification is ScrollUpdateNotification) {
      final double over = notification.metrics.extentAfter > 0
          ? 0
          : notification.metrics.pixels - notification.metrics.maxScrollExtent;
      if (notification.dragDetails == null) {
        return false;
      }
      if (over > 0) {
        _setBottomPull(over);
      } else if (_bottomPull.value > 0 &&
          notification.metrics.extentAfter == 0) {
        _setBottomPull(_bottomPull.value + (notification.scrollDelta ?? 0));
      } else {
        _setBottomPull(0);
      }
      _bottomPullTriggered = _bottomPull.value >= _bottomRefreshThreshold;
      return false;
    }
    if (notification is OverscrollNotification) {
      // 惯性触底不算下拉手势。
      if (notification.dragDetails == null) return false;
      // 往回拖时先逐像素消耗展开距离，再恢复正常列表滚动。
      if (notification.overscroll < 0 && _bottomPull.value > 0) {
        _setBottomPull(_bottomPull.value + notification.overscroll);
        _bottomPullTriggered = _bottomPull.value >= _bottomRefreshThreshold;
        return false;
      }
      if (notification.metrics.extentAfter > 0 ||
          notification.overscroll <= 0) {
        _bottomPullTriggered = false;
        _setBottomPull(0);
        return false;
      }
      // 阻力随展开距离增大，但没有硬上限。积分映射使大步 / 小步拖动手感一致。
      final scale =
          math.max(120.0, notification.metrics.viewportDimension * .3);
      final distance = _bottomPull.value / scale + 1;
      _setBottomPull(scale *
          (math.sqrt(
                  distance * distance + 2 * notification.overscroll / scale) -
              1));
      _bottomPullTriggered = _bottomPull.value >= _bottomRefreshThreshold;
      // Clamping 在边界不改变 offset，不会调用控制器的预取监听。
      if (info.hasMore && !_nextFailed && !session.paused) nextPage();
      return false;
    }
    if (notification is ScrollEndNotification) {
      _releaseBottomPull();
      return false;
    }
    return false;
  }

  void _setBottomPull(double value) {
    final double next = math.max(0.0, value);
    if (next != _bottomPull.value) _bottomPull.value = next;
  }

  /// 松手：越过阈值才触发，并且同一手势、节流窗口内只触发一次。
  void _releaseBottomPull() {
    final bool triggered = _bottomPullTriggered;
    _bottomPullTriggered = false;
    if (!triggered || _loading || _manualRefreshing || _bottomRefreshing) {
      if (!_bottomRefreshing) _collapseBottomPull();
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime? last = _lastBottomRefreshAt;
    // 失败后的重试不受节流限制，方便用户马上再拉一次。
    final bool retry = _nextFailed || _bottomRefreshFailed;
    if (!retry &&
        last != null &&
        now.difference(last) < _bottomRefreshThrottle) {
      _collapseBottomPull();
      return;
    }
    _lastBottomRefreshAt = now;
    _triggerBottomRefresh();
  }

  void _collapseBottomPull() {
    _bottomPull.animateTo(0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic);
  }

  /// 有下一页时优先续接 / 重试下一页，已经是最后一页才刷新末页。
  Future<void> _triggerBottomRefresh() async {
    if (_bottomRefreshing || _loading || _manualRefreshing) return;
    if (info.hasMore) {
      _retryNextPage();
      _collapseBottomPull();
      return;
    }
    await _refreshAtBottom();
  }

  /// 重新请求下一页；失败过的请求会先恢复自动请求。
  void _retryNextPage() {
    if (_bottomRefreshing || _loading || _manualRefreshing) return;
    session.retry();
    _nextFailed = false;
    _bottomRefreshFailed = false;
    nextPage();
  }

  /// 重新请求末页；如果服务端因为新回复多出了新页，顺带加载（最多 3 页）。
  ///
  /// 复用同一页 key 合并楼层，已经读过的内容不会消失，也不会跳回顶部。
  Future<void> _refreshAtBottom() async {
    if (_bottomRefreshing || _loading || _manualRefreshing) return;
    final int firstPn = math.max(1, info.bottomPn ?? 1);
    final Set<String> knownIds = <String>{
      for (final TiebaThreadPagePost post in _currentPosts) post.id,
    };
    session.retry();
    _bottomResultTimer?.cancel();
    _bottomNoNewContent = false;
    // 从实际松手位置平滑回弹，只留足文字可见的高度，不直接归零或钉在远处。
    _bottomPull.animateTo(_bottomRefreshThreshold,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic);
    setState(() {
      _bottomRefreshing = true;
      _bottomRefreshFailed = false;
    });
    try {
      int pn = firstPn;
      for (int i = 0; i < 3; i++) {
        final TiebaThreadPage page =
            await Global.tiebaAPI.getThreadPage(widget.kz, pn: pn, onlyLz: lz);
        if (!mounted) return;
        if (cacheUid != (AccountStore.currentUid ?? '')) return;
        await Global.threadCache.savePage(cacheUid, page,
            onlyLz: lz,
            stored: isStored && (Global.setting.markedCache ?? true));
        if (!mounted) return;
        _applyReloadedPage(pn, page);
        if (!page.page.hasMore) break;
        pn += 1;
      }
      if (!mounted) return;
      final added = _currentPosts
          .where((post) => !knownIds.contains(post.id))
          .map((post) => post.id)
          .toSet();
      setState(() {
        collectImages();
        _threadAgree ??= _createThreadAgree();
        _newBottomFloorIds
          ..clear()
          ..addAll(added);
        _bottomNoNewContent = added.isEmpty;
        if (added.isNotEmpty) _newFloorFade.value = 0;
      });
      if (added.isEmpty) {
        _bottomResultTimer = Timer(const Duration(milliseconds: 850), () {
          if (mounted) _collapseBottomPull();
        });
      } else {
        // 先挂载透明的新楼层，下一帧开始淡入；保持阅读位置，不跳到新末尾。
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _newFloorFade.forward();
          _collapseBottomPull();
        });
      }
    } catch (e) {
      if (!mounted) return;
      session.fail(e);
      setState(() => _bottomRefreshFailed = true);
    } finally {
      if (mounted) {
        setState(() => _bottomRefreshing = false);
        if (_replyRefreshPending) _refreshAfterReply();
      }
    }
  }

  /// 把重载后的整页合并进当前模式，并同步页码 / hasMore。
  void _applyReloadedPage(int pn, TiebaThreadPage page) {
    final int key = pn * (lz ? -1 : 1);
    info.postPage[key] = ThreadCache.mergePosts(
        info.postPage[key] ?? [], page.posts,
        markMissingDeleted: true, aliveIds: _aliveFloorIds(key));
    info.userListSet.addAll(page.userListSet);
    if (lz) {
      if (pn >= _lzBottomPn) _lzHasMore = page.page.hasMore;
      _lzTopPn = math.min(_lzTopPn, pn);
      _lzBottomPn = math.max(_lzBottomPn, pn);
    } else {
      if (pn >= _normalBottomPn) _normalHasMore = page.page.hasMore;
      _normalTopPn = math.min(_normalTopPn, pn);
      _normalBottomPn = math.max(_normalBottomPn, pn);
    }
    info.hasMore = lz ? _lzHasMore : _normalHasMore;
    info.hasPrev = lz ? _lzHasPrev : _normalHasPrev;
    info.topPn = lz ? _lzTopPn : _normalTopPn;
    info.bottomPn = lz ? _lzBottomPn : _normalBottomPn;
    // 非首页响应通常不带帖元数据（tid 为 0），避免覆盖投票 / 收藏数。
    if (page.tid == info.tid && page.title.isNotEmpty) {
      info.thread = page.thread;
    }
  }

  void _onReplySent() {
    if (replyEvents.threadId != widget.kz) return;
    _replyFloorId = replyEvents.floorId;
    _replyRefreshPending = true;
    _refreshAfterReply();
  }

  Future<void> _refreshAfterReply() async {
    if (_loading || _bottomRefreshing || !_replyRefreshPending) return;
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
    if (_loading ||
        _manualRefreshing ||
        _bottomRefreshing ||
        session.paused ||
        pn < 1) {
      return;
    }
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
    if (_loading || _bottomRefreshing) return;
    _bottomResultTimer?.cancel();
    _bottomNoNewContent = false;
    _newBottomFloorIds.clear();
    _bottomPull.value = 0;
    setState(() {
      _previousFailed = false;
      _nextFailed = false;
      _bottomRefreshFailed = false;
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

  List<Widget> buildFloor({bool desktop = false}) {
    final String ownerUid = info.thread.authorUid.isNotEmpty
        ? info.thread.authorUid
        : (_firstPost?.uid ?? '');
    final List<Widget> widgets = <Widget>[];
    for (final TiebaThreadPagePost floor in _sortedFloors()) {
      final card = ThreadFloorComment(
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
        desktop: desktop,
        onDesktopReply: desktop
            ? () => setState(() => _replyTargetFloor = floor)
            : null,
      );
      // 所有楼层保留相同的包裹结构和原来的 GlobalKey，旧楼层不重建 State。
      widgets.add(FadeTransition(
        key: ValueKey('bottom-floor-${floor.id}'),
        opacity: _newBottomFloorIds.contains(floor.id)
            ? _newFloorFade
            : const AlwaysStoppedAnimation<double>(1),
        child: card,
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
      await showShareSheet(
        context,
        ShareContent(
          title: info.title.trim().isEmpty ? '贴吧帖子' : info.title,
          url: 'https://tieba.baidu.com/p/${info.tid}',
          source: info.forumName.isEmpty ? '帖子' : '${info.forumName}吧',
          icon: Icons.article_outlined,
        ),
      );
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

  Widget _bottomEndCaption(TiebananaTokens tokens) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 24, height: 1, color: tokens.line),
        const SizedBox(width: 12),
        Text('苏格拉也有底',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: tokens.textTertiary, letterSpacing: 2)),
        const SizedBox(width: 12),
        Container(width: 24, height: 1, color: tokens.line),
      ],
    );
  }

  Widget _listFooter(TiebananaTokens tokens) {
    return AnimatedBuilder(
      animation: _bottomPull,
      builder: (BuildContext context, Widget? child) {
        final double pull = _bottomPull.value;
        return ClipRect(
          child: SizedBox(
            key: const ValueKey('thread-bottom-refresh-space'),
            height: pull,
            child: OverflowBox(
              alignment: Alignment.bottomCenter,
              minHeight: _bottomRefreshThreshold,
              maxHeight: _bottomRefreshThreshold,
              child: Opacity(
                opacity: (pull / 48).clamp(0.0, 1.0),
                child: Semantics(
                  liveRegion: true,
                  child: Center(child: _footerCaption(tokens, pull)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _footerCaption(TiebananaTokens tokens, double pull) {
    if (_bottomNoNewContent) return _bottomEndCaption(tokens);
    if (_bottomRefreshing) {
      return _LoadingCaption(label: '正在刷新…', color: tokens.primary);
    }
    if (_bottomRefreshFailed) {
      return TextButton.icon(
        onPressed: _refreshAtBottom,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('刷新失败，点击重试'),
      );
    }
    if (_newBottomFloorIds.isNotEmpty && _newFloorFade.value < 1) {
      return const SizedBox.shrink();
    }
    final bool ready = pull >= _bottomRefreshThreshold;
    if (info.hasMore) {
      if (_nextFailed) {
        return _footerHint(
          tokens,
          Icons.refresh_rounded,
          ready ? '松开重试' : '下拉重试',
          ready ? tokens.primary : tokens.textSecondary,
        );
      }
      return TickerMode(
        enabled: pull > 0,
        child: _LoadingCaption(label: '正在全力加载中', color: tokens.primary),
      );
    }
    if (pull > 0) {
      return _footerHint(
        tokens,
        ready ? Icons.refresh_rounded : Icons.keyboard_arrow_down_rounded,
        ready ? '松开刷新' : '下拉刷新',
        ready ? tokens.primary : tokens.textTertiary,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _footerHint(
      TiebananaTokens tokens, IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: color)),
      ],
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
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          if (width >= AppBreakpoints.compactMax) {
            return _buildDesktopShell(context, tokens, first, width);
          }
          return Column(
            children: <Widget>[
              Expanded(
                child: ClipRect(
                    child: Stack(
                  children: <Widget>[
                    AnimatedBuilder(
                      animation: _bottomPull,
                      builder: (context, child) => Transform.translate(
                          offset: Offset(0, -_bottomPull.value), child: child),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _onBottomScrollNotification,
                        child: CustomScrollView(
                          controller: _controller,
                          physics: _ThreadScrollPhysics(
                              bottomPull: () => _bottomPull.value,
                              parent: const AlwaysScrollableScrollPhysics()),
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
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
                                title: Text(session.paused
                                    ? '正在浏览缓存，自动请求已暂停'
                                    : '正在更新帖子…'),
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
                                    onPressed: _loading ? null : _retryNextPage,
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 16),
                                    label: const Text('加载失败，点击重试'),
                                  ),
                                ),
                              ),
                            const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        ignoring: !_bottomRefreshFailed,
                        child: _listFooter(tokens),
                      ),
                    ),
                  ],
                )),
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
          );
        },
      ),
    );
  }

  Future<void> _toggleStoreDesktop() async {
    final bool next = !_stored.value;
    try {
      if (next) {
        await Global.tiebaAPI.threadAddStore(info.tid, pid);
      } else {
        await Global.tiebaAPI.threadRemoveStore(info.tid);
      }
      await Global.threadCache.setStored(cacheUid, info.tid, next,
          keepLongTerm: Global.setting.markedCache ?? true);
      if (!mounted) return;
      _stored.value = next;
      Fluttertoast.showToast(msg: next ? '收藏成功' : '取消收藏');
    } catch (e) {
      if (mounted) Fluttertoast.showToast(msg: e.toString());
    }
  }

  Future<void> _jumpToPageInput() async {
    final int? p = int.tryParse(_jumpInput.text.trim());
    if (p == null || p < 1) {
      Fluttertoast.showToast(msg: '请输入有效页码');
      return;
    }
    await _fetchPage(p, refresh: true);
    if (_controller.hasClients) _controller.jumpTo(0);
  }

  Widget _buildDesktopShell(
    BuildContext context,
    TiebananaTokens tokens,
    TiebaThreadPagePost? first,
    double width,
  ) {
    final bool twoCol = width >= AppBreakpoints.mediumMax;
    final double sideWidth = width >= 1100 ? 288 : 268;
    final List<Widget> floors = buildFloor(desktop: true);
    final int currentPage = info.page.currentPage;

    final Widget mainFeed = ClipRect(
      child: Stack(
        children: <Widget>[
          AnimatedBuilder(
            animation: _bottomPull,
            builder: (BuildContext context, Widget? child) =>
                Transform.translate(
              offset: Offset(0, -_bottomPull.value),
              child: child,
            ),
            child: NotificationListener<ScrollNotification>(
              onNotification: _onBottomScrollNotification,
              child: CustomScrollView(
                controller: _controller,
                physics: _ThreadScrollPhysics(
                  bottomPull: () => _bottomPull.value,
                  parent: const AlwaysScrollableScrollPhysics(),
                ),
                slivers: <Widget>[
                  if (!twoCol)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DesktopPanel(
                          borderRadius: BorderRadius.circular(14),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: <Widget>[
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => Navigator.pushNamed(
                                    context, PageRouter.forumHome,
                                    arguments: info.forumName),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(Icons.tag_rounded,
                                        size: 15, color: tokens.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${info.forumName}吧',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: tokens.textPrimary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '只看楼主',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: tokens.textSecondary,
                                    ),
                              ),
                              const SizedBox(width: 6),
                              Switch(
                                value: lz,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (_) => onlyLz(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
                        desktop: true,
                        agreeController: _threadAgree,
                        onToggleStore: _toggleStoreDesktop,
                        onShare: () => _handleMenu('share'),
                        replyCount: floors.length,
                      ),
                    ),
                  SliverToBoxAdapter(
                      child: _desktopSortRow(tokens, floors.length)),
                  if (session.paused || _manualRefreshing)
                    SliverToBoxAdapter(
                      child: DesktopPanel(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              session.paused
                                  ? Icons.offline_bolt_outlined
                                  : Icons.sync_rounded,
                              size: 16,
                              color: tokens.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                session.paused
                                    ? '正在浏览缓存，自动请求已暂停'
                                    : '正在更新帖子…',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            if (session.paused)
                              TextButton(
                                onPressed: _manualRefresh,
                                child: const Text('刷新'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (_hasPrevious || (_loading && _loadingPrevious))
                    SliverToBoxAdapter(child: _previousPageEntry(tokens)),
                  SliverList(delegate: SliverChildListDelegate(floors)),
                  if (_nextFailed && !session.paused)
                    SliverToBoxAdapter(
                      child: Center(
                        child: TextButton.icon(
                          onPressed: _loading ? null : _retryNextPage,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('加载失败，点击重试'),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed:
                                _manualRefreshing ? null : _manualRefresh,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: tokens.textSecondary,
                              side: BorderSide(color: tokens.line),
                              minimumSize: const Size(0, 28),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              textStyle: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 14),
                            label: const Text('刷新最新回复'),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '第 $currentPage 页',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontSize: 11,
                                  color: tokens.textTertiary,
                                ),
                          ),
                          if (info.hasMore) ...<Widget>[
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: _loading ? null : nextPage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: tokens.textSecondary,
                                side: BorderSide(color: tokens.line),
                                minimumSize: const Size(0, 28),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                textStyle: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              child: const Text('下一页'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !_bottomRefreshFailed,
              child: _listFooter(tokens),
            ),
          ),
        ],
      ),
    );

    final Widget bodyContent = Column(
      children: <Widget>[
        Expanded(
          child: PageWrap(
            bottomPadding: 0,
            child: twoCol
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: mainFeed),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: sideWidth,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _desktopSideColumn(tokens),
                        ),
                      ),
                    ],
                  )
                : mainFeed,
          ),
        ),
        if (!twoCol)
          ThreadReplyBar(
            fid: info.fid,
            tid: info.tid,
            kw: info.forumName,
            replyText: info.title,
            storedNotifier: _stored,
            agreeController: _threadAgree,
            storeCount: info.thread.storeCount,
            initiallyStored: info.isStored,
          ),
      ],
    );

    return DesktopShellFrame(
      title: '帖子详情',
      subtitle: '${info.forumName}吧 · ${info.title}',
      activeTab: -1,
      onRefresh: _manualRefresh,
      child: bodyContent,
    );
  }

  Widget _desktopSortRow(TiebananaTokens tokens, int loadedCount) {
    const List<String> labels = <String>['热门排序', '正序', '倒序'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 10),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < labels.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 6),
            Material(
              color: _sortMode == i ? tokens.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _sortMode = i),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    labels[i],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 11.5,
                          fontWeight:
                              _sortMode == i ? FontWeight.w700 : FontWeight.w500,
                          color: _sortMode == i
                              ? tokens.textPrimary
                              : tokens.textSecondary,
                        ),
                  ),
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            '已加载 $loadedCount 条回复',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: tokens.textTertiary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _desktopSideColumn(TiebananaTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // 所属吧卡片
        DesktopPanel(
          borderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.tag_rounded, size: 13, color: tokens.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    '所属吧',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.textTertiary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => Navigator.pushNamed(context, PageRouter.forumHome,
                    arguments: info.forumName),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: SizedBox(
                          width: 34,
                          height: 34,
                          child: info.avatar.isEmpty
                              ? Container(
                                  color: tokens.fill,
                                  child: Icon(Icons.forum_outlined,
                                      size: 18, color: tokens.textTertiary),
                                )
                              : ExtendedImage.network(info.avatar,
                                  fit: BoxFit.cover, cache: true),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '${info.forumName}吧',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textPrimary,
                                  ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 15, color: tokens.textTertiary),
                    ],
                  ),
                ),
              ),
              const Divider(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(
                    context, PageRouter.forumHome,
                    arguments: info.forumName),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.textSecondary,
                  side: BorderSide(color: tokens.line),
                  minimumSize: const Size(double.infinity, 30),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                child: const Text('进入吧主页'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 互动统计卡
        DesktopPanel(
          borderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.favorite_border_rounded,
                      size: 13, color: tokens.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    '互动',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.textTertiary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _threadAgree == null
                        ? const _SideStatBtn(
                            icon: Icons.thumb_up_alt_outlined,
                            count: '0',
                            label: '赞',
                            active: false,
                          )
                        : AnimatedBuilder(
                            animation: _threadAgree!,
                            builder: (BuildContext context, _) => _SideStatBtn(
                              icon: _threadAgree!.liked
                                  ? Icons.thumb_up_alt_rounded
                                  : Icons.thumb_up_alt_outlined,
                              count: threadCountText(_threadAgree!.agreeNum),
                              label: '赞',
                              active: _threadAgree!.liked,
                              onTap: _threadAgree!.busy
                                  ? null
                                  : () => _threadAgree!.toggleLike(),
                            ),
                          ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: _threadAgree == null
                        ? const _SideStatBtn(
                            icon: Icons.thumb_down_alt_outlined,
                            count: '0',
                            label: '踩',
                            active: false,
                          )
                        : AnimatedBuilder(
                            animation: _threadAgree!,
                            builder: (BuildContext context, _) => _SideStatBtn(
                              icon: _threadAgree!.disliked
                                  ? Icons.thumb_down_alt_rounded
                                  : Icons.thumb_down_alt_outlined,
                              count: threadCountText(_threadAgree!.disagreeNum),
                              label: '踩',
                              active: _threadAgree!.disliked,
                              onTap: _threadAgree!.busy
                                  ? null
                                  : () => _threadAgree!.toggleDislike(),
                            ),
                          ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _stored,
                      builder: (BuildContext context, bool stored, _) {
                        final int count = (info.thread.storeCount +
                                (stored ? 1 : 0) -
                                (info.isStored ? 1 : 0))
                            .clamp(0, 1 << 53);
                        return _SideStatBtn(
                          icon: stored
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          count: threadCountText(count),
                          label: stored ? '已收藏' : '收藏',
                          active: stored,
                          onTap: _toggleStoreDesktop,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 阅读控制卡
        DesktopPanel(
          borderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.tune_rounded,
                      size: 13, color: tokens.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    '阅读控制',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.textTertiary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '只看楼主',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: tokens.textSecondary,
                          ),
                    ),
                  ),
                  Switch(
                    value: lz,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (_) => onlyLz(),
                  ),
                ],
              ),
              Divider(height: 12, color: tokens.line),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '跳转页码',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: tokens.textSecondary,
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 26,
                    child: TextField(
                      controller: _jumpInput,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onSubmitted: (_) => _jumpToPageInput(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            color: tokens.textPrimary,
                          ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: tokens.fill,
                        hintText: '${info.page.currentPage}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: tokens.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: tokens.line),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  SizedBox(
                    height: 26,
                    child: OutlinedButton(
                      onPressed: _jumpToPageInput,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tokens.textSecondary,
                        side: BorderSide(color: tokens.line),
                        minimumSize: const Size(34, 26),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        textStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Go'),
                    ),
                  ),
                ],
              ),
              Divider(height: 12, color: tokens.line),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '刷新 / 分享 / 举报',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: tokens.textSecondary,
                          ),
                    ),
                  ),
                  _SmallCtrlIcon(
                    icon: Icons.refresh_rounded,
                    tooltip: '刷新',
                    onTap: _manualRefresh,
                  ),
                  _SmallCtrlIcon(
                    icon: Icons.share_outlined,
                    tooltip: '分享',
                    onTap: () => _handleMenu('share'),
                  ),
                  if ((int.tryParse(info.tid) ?? 0) > 0)
                    _SmallCtrlIcon(
                      icon: Icons.flag_outlined,
                      tooltip: '举报',
                      onTap: () => _handleMenu('report'),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 停靠回复框
        _DesktopDockedReplyBox(
          kw: info.forumName,
          fid: info.fid,
          tid: info.tid,
          targetFloor: _replyTargetFloor,
          targetAuthorName: _replyTargetFloor == null
              ? null
              : _authorOf(_replyTargetFloor!).name,
          onClearTarget: () => setState(() => _replyTargetFloor = null),
        ),
      ],
    );
  }

  @override
  void dispose() {
    replyEvents.removeListener(_onReplySent);
    _controller.removeListener(_onScrollNext);
    _controller.removeListener(_onScrollPrev);
    _controller.dispose();
    _bottomResultTimer?.cancel();
    _bottomPull.dispose();
    _newFloorFade.dispose();
    _stored.removeListener(_storeChanged);
    _stored.dispose();
    _jumpInput.dispose();
    session.removeListener(_sessionChanged);
    if (widget.session == null) session.dispose();
    _threadAgree?.dispose();
    super.dispose();
  }
}

/// 顶部保留原来的回弹；底部位移由刷新动画统一接管，避免松手后系统先回弹。
class _ThreadScrollPhysics extends BouncingScrollPhysics {
  const _ThreadScrollPhysics({required this.bottomPull, super.parent});

  final double Function() bottomPull;

  @override
  _ThreadScrollPhysics applyTo(ScrollPhysics? ancestor) => _ThreadScrollPhysics(
      bottomPull: bottomPull, parent: buildParent(ancestor));

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final double delta = value - position.pixels;
    if (delta < 0 && bottomPull() > 0 && position.extentAfter == 0) {
      // 负向 overscroll 交给刷新区收起，不能先滚动内容再把展开距离清零。
      return delta;
    }
    if (value > position.maxScrollExtent) {
      return value - math.max(position.pixels, position.maxScrollExtent);
    }
    return super.applyBoundaryConditions(position, value);
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

class _SideStatBtn extends StatelessWidget {
  const _SideStatBtn({
    required this.icon,
    required this.count,
    required this.label,
    required this.active,
    this.onTap,
  });

  final IconData icon;
  final String count;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Color bg = active ? tokens.primaryContainer : Colors.transparent;
    final Color fg = active ? tokens.onPrimaryContainer : tokens.textSecondary;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 17, color: fg),
              const SizedBox(height: 3),
              Text(
                count,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9.5,
                      color: fg,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallCtrlIcon extends StatelessWidget {
  const _SmallCtrlIcon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 16, color: tokens.textSecondary),
        ),
      ),
    );
  }
}

/// 桌面端右侧栏停靠回复框：支持回复楼层目标、贴吧表情 Popover、图片上传与 Ctrl+Enter 发送。
class _DesktopDockedReplyBox extends StatefulWidget {
  const _DesktopDockedReplyBox({
    required this.kw,
    required this.fid,
    required this.tid,
    required this.targetFloor,
    required this.targetAuthorName,
    required this.onClearTarget,
  });

  final String kw;
  final String fid;
  final String tid;
  final TiebaThreadPagePost? targetFloor;
  final String? targetAuthorName;
  final VoidCallback onClearTarget;

  @override
  State<_DesktopDockedReplyBox> createState() => _DesktopDockedReplyBoxState();
}

class _DesktopDockedReplyBoxState extends State<_DesktopDockedReplyBox> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();
  final GlobalKey _emojiKey = GlobalKey();
  late final ImageUploadProviderModel _uploads =
      ImageUploadProviderModel(widget.kw);
  bool _sending = false;
  bool _riskAcked = false;

  @override
  void initState() {
    super.initState();
    _riskAcked = !Global.setting.showPostingRiskWarning;
    _input.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _input.removeListener(_onChanged);
    _input.dispose();
    _focus.dispose();
    _uploads.dispose();
    super.dispose();
  }

  Future<bool> _ensureRiskAcked() async {
    if (_riskAcked) return true;
    await showPostingRiskWarning(
      context,
      OfficialTiebaTarget(
        forumName: widget.kw,
        tid: widget.tid,
        pid: widget.targetFloor?.id,
      ),
    );
    if (!mounted) return false;
    setState(() => _riskAcked = true);
    return true;
  }

  Future<void> _pickImage() async {
    if (!await _ensureRiskAcked()) return;
    if (!mounted) return;
    final dynamic data =
        await Navigator.pushNamed(context, PageRouter.imagePicker);
    if (!mounted || data == null) return;
    final Set<AssetEntity> pic = (data as List)[0] as Set<AssetEntity>;
    final bool saveOrigin = data[1] as bool;
    for (final AssetEntity p in pic) {
      final ImageUploadTask task = _uploads.enqueue(p, saveOrigin);
      final TiebaUploadedImage? image = await _uploads.upload(task);
      if (!mounted || image == null) continue;
      final String token =
          TiebaParser.contentBuilder(ContentBuilderType.Picture, image: image);
      final String cur = _input.text;
      _input.text = cur.isEmpty ? token : '$cur\n$token';
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    if (!await _ensureRiskAcked()) return;
    if (!mounted) return;
    if (_uploads.hasPending) {
      Fluttertoast.showToast(msg: '请等待图片上传完成，或重试/移除失败图片');
      return;
    }
    final String text = _input.text.trim();
    if (text.isEmpty) {
      Fluttertoast.showToast(msg: '说点什么吧');
      return;
    }
    if (text.length > 2000) {
      Fluttertoast.showToast(msg: '回复最多 2000 字');
      return;
    }
    final List<String> photos = _uploads.pictures.keys
        .where((TiebaUploadedImage image) => text.contains(
            TiebaParser.contentBuilder(ContentBuilderType.Picture,
                image: image)))
        .map((TiebaUploadedImage image) => image.picId)
        .toList();
    setState(() => _sending = true);
    try {
      final TiebaThreadPagePost? floor = widget.targetFloor;
      final String msg = floor == null
          ? await Global.tiebaAPI.replyThread(
              text,
              widget.kw,
              widget.fid,
              widget.tid,
              photos: photos,
            )
          : await Global.tiebaAPI.replyFloor(
              text,
              widget.kw,
              widget.fid,
              widget.tid,
              floor.id,
              photos: photos,
            );
      if (!mounted) return;
      _input.clear();
      _uploads.tasks.clear();
      _uploads.pictures.clear();
      Fluttertoast.showToast(msg: msg.isNotEmpty ? msg : '发送成功');
      replyEvents.sent(widget.tid, pid: floor?.id);
      if (floor != null) widget.onClearTarget();
    } catch (e) {
      if (mounted) Fluttertoast.showToast(msg: e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TiebaThreadPagePost? floor = widget.targetFloor;
    final bool hasText = _input.text.trim().isNotEmpty;

    return DesktopPanel(
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: ChangeNotifierProvider<ImageUploadProviderModel>.value(
        value: _uploads,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '回复帖子',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            if (floor != null) ...<Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: widget.onClearTarget,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: tokens.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            '回复 @${widget.targetAuthorName ?? ''}（#${floor.floor ?? ''}）',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.onPrimaryContainer,
                                ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.close_rounded,
                            size: 11, color: tokens.onPrimaryContainer),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
            ],
            CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.enter, control: true):
                    _send,
                const SingleActivator(LogicalKeyboardKey.numpadEnter,
                    control: true): _send,
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                decoration: BoxDecoration(
                  color: tokens.fill,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minHeight: 62, maxHeight: 132),
                child: Consumer<ImageUploadProviderModel>(
                  builder: (BuildContext context,
                      ImageUploadProviderModel value, _) {
                    return ExtendedTextField(
                      specialTextSpanBuilder:
                          TiebaSpanBuilder(uploadImages: value),
                      controller: _input,
                      focusNode: _focus,
                      minLines: 3,
                      maxLines: 5,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            height: 1.55,
                            color: tokens.textPrimary,
                          ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: '写回复…支持贴吧表情与图片',
                        hintStyle:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 11.5,
                                  color: tokens.textTertiary,
                                ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_uploads.tasks.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: <Widget>[
                  for (final ImageUploadTask t in _uploads.tasks)
                    Chip(
                      label: Text(
                        t.uploading
                            ? '上传中'
                            : (t.error != null ? '失败' : '已传图'),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      deleteIcon: const Icon(Icons.close, size: 13),
                      onDeleted: t.uploading ? null : () => _uploads.remove(t),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 7),
            Row(
              children: <Widget>[
                _SmallCtrlIcon(
                  key: _emojiKey,
                  icon: Icons.emoji_emotions_outlined,
                  tooltip: '贴吧表情',
                  onTap: () => showEmojiPopover(
                    context: context,
                    anchorKey: _emojiKey,
                    controller: _input,
                    onInserted: () => setState(() {}),
                  ),
                ),
                _SmallCtrlIcon(
                  icon: Icons.image_outlined,
                  tooltip: '选择图片',
                  onTap: _pickImage,
                ),
                const Spacer(),
                SizedBox(
                  height: 26,
                  child: FilledButton(
                    onPressed: (_sending || !hasText) ? null : _send,
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.accentFill,
                      foregroundColor: tokens.accentOn,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    child: Text(_sending ? '发送中' : '发送'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Ctrl + Enter 发送',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
                        color: tokens.textTertiary,
                      ),
                ),
                Text(
                  '纯文本 · 表情 · 图片',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
                        color: tokens.textTertiary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
