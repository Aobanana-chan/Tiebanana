import 'dart:async';

import 'package:flutter/material.dart' hide SearchBar;
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/features/forum/state/forum_state.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';
import 'package:tiebanana/shared/controllers/back_to_top_controller.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/layout/page_wrap.dart';
import 'package:tiebanana/shared/widgets/avatar_image.dart';
import 'package:tiebanana/shared/widgets/desktop_panel.dart';
import 'package:tiebanana/shared/widgets/floating_search_app_bar.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';
import 'package:tiebanana/features/search/widgets/search_bar.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/tiebanana_refresh_indicator.dart';

///拉取一页推荐贴的实现。默认走 [Global.tiebaAPI]，测试里注入假数据。
typedef RecommendLoader = Future<RecommendPage> Function(
    int pageThreadCount, int pn);

class RecommendPan extends StatefulWidget {
  final FloatingSearchBarController controller;

  /// 返回键的「先回顶」协作对象。主界面按下返回时先问它，再走退出流程。
  final BackToTopController? backController;
  final RecommendLoader? loader;
  const RecommendPan(
      {super.key, required this.controller, this.backController, this.loader});

  @override
  _RecommendPanState createState() => _RecommendPanState();
}

class _RecommendPanState extends State<RecommendPan> {
  static const int _pageSize = 15;

  ///列表里的 `null` 是「上次读到这里」的续读条占位；广告位（lego_card）单独处理。
  final List<TiebaThreadInfo?> recommend = <TiebaThreadInfo?>[];
  ScrollController controller = ScrollController();
  int pn = 1;

  ///首屏（含下拉刷新）加载中。已有内容时交给下拉指示器。
  bool _loading = true;
  bool _loadingMore = false;

  ///首屏错误 / 翻页错误。首屏错误占满内容区，翻页错误只在列表底部给重试口。
  Object? _error;
  Object? _moreError;

  /// 代码触发下拉刷新（返回键回顶时显示转圈）。
  final TiebananaRefreshController _refreshController =
      TiebananaRefreshController();

  Future<void>? _refreshTask;

  /// 桌面端分栏看帖开关与当前选中帖子。
  bool _splitMode = false;
  String? _selectedThreadId;

  RecommendLoader get _loader =>
      widget.loader ?? Global.tiebaAPI.getRecommThread;

  @override
  void initState() {
    super.initState();
    refresh();
    Global.desktopRefreshTick.addListener(_onDesktopRefresh);

    widget.backController?.attach(
      this,
      isScrolled: _isScrolled,
      onBackToTop: _backToTop,
    );

    controller.addListener(() {
      if (controller.position.pixels >
          controller.position.maxScrollExtent -
              controller.position.viewportDimension) {
        Throttle.seconds(2, nextPage);
      }
    });
  }

  void _onDesktopRefresh() {
    if (mounted) refresh();
  }

  @override
  void dispose() {
    Global.desktopRefreshTick.removeListener(_onDesktopRefresh);
    widget.backController?.detach(this);
    controller.dispose();
    super.dispose();
  }

  /// 刷新第一页。并发调用复用同一个 Future，避免下拉指示器提前收起。
  Future<void> refresh() => _refreshTask ??= _refresh();

  Future<void> _refresh() async {
    final bool showSkeleton = recommend.isEmpty;
    if (showSkeleton && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    //「上次读到这里」的位置 = 这次刷新拉到的这一页的下沿。
    //首屏没有旧内容，自然也没有续读条；从第二次刷新（下拉 / 返回回顶）开始才会出现。
    final bool hadContent = recommend.any((TiebaThreadInfo? e) => e != null);
    try {
      final List<TiebaThreadInfo> fresh = (await _loader(_pageSize, 1)).threads;
      if (!mounted) {
        return;
      }
      setState(() {
        recommend.removeWhere((TiebaThreadInfo? e) => e == null);
        recommend.insertAll(0, fresh);
        //旧内容整体被这一页压到下面，续读条标在两者交界处。
        if (hadContent) {
          recommend.insert(fresh.length, null);
        }
        pn = 1;
        _error = null;
        _moreError = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        //刷新失败时保留已有内容，错误显示在底部重试口。
        if (recommend.isEmpty) {
          _error = error;
        } else {
          _moreError = error;
        }
      });
    } finally {
      _refreshTask = null;
    }
  }

  Future<void> nextPage() async {
    if (_loadingMore || _loading) {
      return;
    }
    final int next = pn + 1;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final List<TiebaThreadInfo> more =
          (await _loader(_pageSize, next)).threads;
      if (!mounted) {
        return;
      }
      setState(() {
        recommend.addAll(more);
        pn = next;
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

  ///返回键用：列表是否已离开顶部。
  bool _isScrolled() => controller.hasClients && controller.offset > 0;

  ///先平滑回到顶部，同时刷新。返回键与续读条共用同一条路径。
  ///
  ///动画独立运行，刷新与滚动并行，方法立即返回。
  ///（await 动画在测试中会因无人推帧而一直等待。）
  Future<void> _backToTop() async {
    if (_isScrolled()) {
      unawaited(controller.animateTo(0,
          duration: TiebananaMetrics.durationBase,
          curve: TiebananaMetrics.curveStandard));
    }
    // 与手势下拉一致：指示器拉出来转圈，而不是静默刷新。
    // 指示器的拉出 / 收起动画要跟着帧走，所以这里不等它，避免阻塞返回流程。
    if (_refreshController.isAttached) {
      unawaited(_refreshController.show());
    } else {
      await refresh();
    }
  }

  ///点续读条：回到顶部并刷新推荐流。
  Future<void> _onResumeTap() => _backToTop();

  void _retry() {
    setState(() {
      _error = null;
      _moreError = null;
    });
    refresh();
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
        return Column(
          children: [
            SearchBar(
              maxHeight: constraints.maxHeight,
              barController: widget.controller,
            ),
            Expanded(
                child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: (() => widget.controller.close()),
                    child: RecommendFeed(
                      items: recommend,
                      loading: _loading,
                      error: _error,
                      notLoggedIn:
                          _error != null && _error.toString().contains("未登录"),
                      loadingMore: _loadingMore,
                      moreError: _moreError,
                      scrollController: controller,
                      refreshController: _refreshController,
                      onRefresh: refresh,
                      onResumeTap: _onResumeTap,
                      onRetry: _retry,
                      onLoadMore: nextPage,
                    )))
          ],
        );
      },
    );
  }

  TiebaThreadInfo? get _selectedThread {
    final List<TiebaThreadInfo> nonNull =
        recommend.whereType<TiebaThreadInfo>().toList();
    if (nonNull.isEmpty) return null;
    if (_selectedThreadId != null) {
      for (final TiebaThreadInfo item in nonNull) {
        if (item.id == _selectedThreadId) return item;
      }
    }
    return nonNull.first;
  }

  /// 查找 `null` 续读锚点下方紧邻的那条旧帖子（仅当锚点真实存在时返回非空）。
  TiebaThreadInfo? get _resumeAnchorThread {
    final int idx = recommend.indexWhere((TiebaThreadInfo? e) => e == null);
    if (idx < 0) return null;
    for (int i = idx + 1; i < recommend.length; i++) {
      if (recommend[i] != null) return recommend[i];
    }
    for (int i = idx - 1; i >= 0; i--) {
      if (recommend[i] != null) return recommend[i];
    }
    return null;
  }

  Widget _buildDesktop(BuildContext context, double availableWidth) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool twoCol = availableWidth >= AppBreakpoints.mediumMax;
    final bool split = twoCol && _splitMode;
    final double railWidth = availableWidth >= 1100 ? 296 : 268;
    final TiebaThreadInfo? selected = _selectedThread;

    final Widget feed = RecommendFeed(
      items: recommend,
      loading: _loading,
      error: _error,
      notLoggedIn: _error != null && _error.toString().contains('未登录'),
      loadingMore: _loadingMore,
      moreError: _moreError,
      scrollController: controller,
      refreshController: _refreshController,
      onRefresh: refresh,
      onResumeTap: _onResumeTap,
      onRetry: _retry,
      onLoadMore: nextPage,
      desktop: true,
      selectedThreadId: split ? selected?.id : null,
      onSelectThread: split
          ? (TiebaThreadInfo info) =>
              setState(() => _selectedThreadId = info.id)
          : null,
    );

    return PageWrap(
      bottomPadding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DesktopPageHeader(
            title: '正在发生',
            subtitle: '个性化推荐流 · 下滑加载更多',
            tools: <Widget>[
              if (twoCol) ...<Widget>[
                Text(
                  '分栏看帖',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11.5,
                        color: tokens.textSecondary,
                      ),
                ),
                Switch(
                  value: _splitMode,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (bool v) => setState(() => _splitMode = v),
                ),
              ],
            ],
          ),
          Expanded(
            child: !twoCol
                ? feed
                : split
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(width: 380, child: feed),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _DesktopSplitReader(thread: selected),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child: feed),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: railWidth,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _buildDesktopRail(context, tokens),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRail(BuildContext context, TiebananaTokens tokens) {
    final TiebaThreadInfo? anchor = _resumeAnchorThread;
    ForumState? forumState;
    try {
      forumState = Provider.of<ForumState>(context);
    } catch (_) {
      forumState = null;
    }
    final List<LikeForumInfo> quickForums =
        forumState?.forums.take(5).toList() ?? <LikeForumInfo>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (anchor != null) ...<Widget>[
          DesktopPanel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '上次读到这里',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: tokens.textTertiary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  anchor.title.isEmpty ? '${anchor.fname}吧帖子' : anchor.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                        color: tokens.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '列表定位锚点 · 上次刷新的衔接位置',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10.5,
                        color: tokens.textTertiary,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, PageRouter.threadPage,
                          arguments:
                              ThreadPageRouterData(kz: anchor.id, pid: null));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.accentFill,
                      foregroundColor: tokens.accentOn,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      textStyle: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: const Icon(Icons.chevron_right_rounded, size: 15),
                    label: const Text('打开这条帖子'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (quickForums.isNotEmpty) ...<Widget>[
          DesktopPanel(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '快捷跳转',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: tokens.textPrimary,
                            ),
                      ),
                    ),
                    Icon(Icons.tag_rounded,
                        size: 14, color: tokens.textTertiary),
                  ],
                ),
                const SizedBox(height: 7),
                for (final LikeForumInfo f in quickForums)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.pushNamed(
                        context, PageRouter.forumHome,
                        arguments: f.forumName),
                    child: SizedBox(
                      height: 30,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Container(
                                width: 18,
                                height: 18,
                                color: tokens.fill,
                                child: resolveAvatarUrl(f.avatar).isEmpty
                                    ? Icon(Icons.forum_outlined,
                                        size: 11, color: tokens.textTertiary)
                                    : AvatarImage(
                                        url: resolveAvatarUrl(f.avatar)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${f.forumName}吧',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: 11.5,
                                      color: tokens.textSecondary,
                                    ),
                              ),
                            ),
                            Text(
                              'Lv.${f.levelId}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontSize: 10,
                                    color: tokens.textTertiary,
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
          const SizedBox(height: 12),
        ],
        DesktopPanel(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '桌面快捷键',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                          ),
                    ),
                  ),
                  Icon(Icons.keyboard_outlined,
                      size: 14, color: tokens.textTertiary),
                ],
              ),
              const SizedBox(height: 8),
              const _ShortcutRow(label: '全局搜索', keys: 'Ctrl K'),
              const _ShortcutRow(label: '切换四个分区', keys: 'Ctrl 1–4'),
              const _ShortcutRow(label: '返回上一视图', keys: 'Alt ←'),
              const _ShortcutRow(label: '刷新当前列表', keys: 'F5'),
              const _ShortcutRow(label: '关闭弹层', keys: 'Esc', last: true),
            ],
          ),
        ),
      ],
    );
  }
}

///动态流的展示层：骨架 / 空 / 错误 / 未登录 / 列表。
///
///纯展示组件，数据和回调由 [RecommendPan] 传入，便于单独渲染与测试。
class RecommendFeed extends StatelessWidget {
  const RecommendFeed({
    super.key,
    required this.items,
    required this.loading,
    required this.error,
    required this.notLoggedIn,
    required this.loadingMore,
    required this.moreError,
    required this.scrollController,
    required this.onRefresh,
    required this.onResumeTap,
    required this.onRetry,
    required this.onLoadMore,
    this.refreshController,
    this.desktop = false,
    this.selectedThreadId,
    this.onSelectThread,
  });

  ///`null` 元素是续读条占位。
  final List<TiebaThreadInfo?> items;
  final bool loading;
  final Object? error;
  final bool notLoggedIn;
  final bool loadingMore;
  final Object? moreError;
  final ScrollController scrollController;

  /// 代码触发下拉刷新（返回键回顶）；为空时只响应手势。
  final TiebananaRefreshController? refreshController;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onResumeTap;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final bool desktop;
  final String? selectedThreadId;
  final ValueChanged<TiebaThreadInfo>? onSelectThread;

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) {
      return _sheet(context, _RecommendSkeletonList(desktop: desktop),
          center: false);
    }
    if (error != null && items.isEmpty) {
      return _sheet(context, _errorView(context));
    }
    if (items.isEmpty) {
      return _sheet(context, _emptyView());
    }
    final bool showFooter = loadingMore || moreError != null;
    return TiebananaRefreshIndicator(
      controller: refreshController,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: desktop ? 0 : TiebananaMetrics.gapSm,
          bottom: desktop ? 24 : TiebananaMetrics.gapMd,
        ),
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + (showFooter ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index >= items.length) {
            return _footer(context);
          }
          final TiebaThreadInfo? item = items[index];
          return item == null
              ? _ResumeBar(onTap: onResumeTap, desktop: desktop)
              : _threadCard(context, item);
        },
      ),
    );
  }

  ///状态页也要能下拉刷新：撑满可视高度再居中。
  ///
  ///骨架屏不居中（[center] = false）：它模拟列表，从顶部往下铺更贴近内容到达后的样子。
  Widget _sheet(BuildContext context, Widget child, {bool center = true}) {
    return TiebananaRefreshIndicator(
      controller: refreshController,
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
        title: "登录后才能看动态",
        body: "推荐流需要登录才返回内容",
        primaryLabel: "去登录",
        onPrimary: () => Navigator.pushNamed(context, PageRouter.login),
      );
    }
    return StateView(
      icon: Icons.wifi_off_rounded,
      title: "网络似乎有点问题",
      body: "检查一下网络连接后重试",
      primaryLabel: "重试",
      primaryIcon: Icons.refresh,
      onPrimary: onRetry,
    );
  }

  Widget _emptyView() {
    return StateView(
      icon: Icons.explore_outlined,
      title: "还没有推荐内容",
      body: "逛一逛别的吧，过会儿再来刷新",
      primaryLabel: "重新加载",
      primaryIcon: Icons.refresh,
      onPrimary: onRetry,
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

  Widget _threadCard(BuildContext context, TiebaThreadInfo info) {
    final bool isSelected =
        selectedThreadId != null && selectedThreadId == info.id;
    return ThreadSummary(
      firstPostContent: info.firstPostContent,
      author: info.author,
      createTime: info.createTime,
      latestTime: info.lastTimeInt,
      tid: info.id,
      fname: info.fname,
      viewNum: info.viewNum,
      title: info.title,
      agreeNum: info.agreeNum,
      disagreeNum: info.disagreeNum,
      replyNum: info.replyNum,
      margin: desktop ? const EdgeInsets.only(bottom: 11) : null,
      desktop: desktop,
      showForumChip: desktop,
      selected: isSelected,
      onTap: onSelectThread == null ? null : () => onSelectThread!(info),
    );
  }
}

///「上次读到这里」续读条。
///
///使用 primaryContainer 作为位置标记，视觉层级低于帖子卡片。
class _ResumeBar extends StatelessWidget {
  const _ResumeBar({required this.onTap, this.desktop = false});

  /// 续读条高度。比普通按钮矮一点，夹在两条帖子中间时不至于把留白撑大。
  static const double _height = 36;

  final Future<void> Function() onTap;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Padding(
      // 上一张帖子自带 gapSm 下边距，这里上边留 0、下边留 gapSm，
      // 保持两段间距均匀。
      padding: EdgeInsets.fromLTRB(
          desktop ? 0 : TiebananaMetrics.pageGutter,
          0,
          desktop ? 0 : TiebananaMetrics.pageGutter,
          desktop ? 11 : TiebananaMetrics.gapSm),
      child: Material(
        color: tokens.primaryContainer,
        borderRadius: TiebananaMetrics.brCtl,
        child: InkWell(
          borderRadius: TiebananaMetrics.brCtl,
          onTap: () => onTap(),
          child: SizedBox(
            height: _height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.refresh, size: 18, color: tokens.onPrimaryContainer),
                const SizedBox(width: TiebananaMetrics.gapSm),
                Text(
                  "上次读到这里，点击刷新",
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tokens.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

///首屏骨架：三张卡片，形状与 [ThreadSummary] 对齐。
class _RecommendSkeletonList extends StatelessWidget {
  const _RecommendSkeletonList({this.desktop = false});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    //用 Column 排版，外层 _sheet 已是滚动容器。
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ThreadSkeletonCard(desktop: desktop),
        _ThreadSkeletonCard(desktop: desktop),
        _ThreadSkeletonCard(desktop: desktop),
      ],
    );
  }
}

class _ThreadSkeletonCard extends StatelessWidget {
  const _ThreadSkeletonCard({this.desktop = false});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      margin: EdgeInsets.fromLTRB(
          desktop ? 0 : TiebananaMetrics.pageGutter,
          0,
          desktop ? 0 : TiebananaMetrics.pageGutter,
          desktop ? 11 : TiebananaMetrics.gapSm),
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
          const FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.74,
            child: SkeletonBox(height: 13),
          ),
          const SizedBox(height: TiebananaMetrics.gapSm),
          const SkeletonBox(height: 11),
          const SizedBox(height: TiebananaMetrics.gapXs + 2),
          const FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.62,
            child: SkeletonBox(height: 11),
          ),
          const SizedBox(height: TiebananaMetrics.gapSm + 2),
          const SkeletonBox(height: 70, radius: TiebananaMetrics.radiusSm),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.label,
    required this.keys,
    this.last = false,
  });

  final String label;
  final String keys;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 7),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    color: tokens.textSecondary,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: tokens.fill,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: tokens.line),
            ),
            child: Text(
              keys,
              style: TextStyle(
                fontSize: 10,
                height: 1,
                color: tokens.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 桌面「分栏看帖」右侧阅读器：展示选中贴正文并拉取真实楼层预览。
class _DesktopSplitReader extends StatefulWidget {
  const _DesktopSplitReader({required this.thread});

  final TiebaThreadInfo? thread;

  @override
  State<_DesktopSplitReader> createState() => _DesktopSplitReaderState();
}

class _DesktopSplitReaderState extends State<_DesktopSplitReader> {
  TiebaThreadPage? _page;
  bool _loading = false;
  String? _loadedTid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _DesktopSplitReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thread?.id != widget.thread?.id) {
      _load();
    }
  }

  Future<void> _load() async {
    final TiebaThreadInfo? t = widget.thread;
    if (t == null) return;
    if (_loadedTid == t.id && _page != null) return;
    setState(() {
      _loading = true;
      _page = null;
      _loadedTid = t.id;
    });
    try {
      final TiebaThreadPage res = await Global.tiebaAPI.getThreadPage(t.id);
      if (!mounted || _loadedTid != t.id) return;
      setState(() {
        _page = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || _loadedTid != t.id) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TiebaThreadInfo? t = widget.thread;
    if (t == null) {
      return DesktopPanel(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            '从左侧选择一条帖子查看详情',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: tokens.textTertiary),
          ),
        ),
      );
    }

    final int stamp =
        int.tryParse(t.lastTimeInt) ?? int.tryParse(t.createTime) ?? 0;
    final String when =
        stamp > 0 ? TiebaParser.getPostTime(intTime: stamp) : '';
    final List<TiebaThreadPagePost> replies = _page?.posts
            .where((TiebaThreadPagePost p) => p.floor != '1')
            .take(5)
            .toList() ??
        const <TiebaThreadPagePost>[];

    return DesktopPanel(
      borderRadius: TiebananaMetrics.brXl,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (t.fname.isNotEmpty) ...<Widget>[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: tokens.primaryContainer,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${t.fname}吧',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.onPrimaryContainer,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  when.isEmpty ? t.author.name : '${t.author.name} · $when',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11.5,
                        color: tokens.textTertiary,
                      ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  PageRouter.threadPage,
                  arguments: ThreadPageRouterData(kz: t.id, pid: null),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.textSecondary,
                  side: BorderSide(color: tokens.line),
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 13),
                label: const Text('全屏阅读'),
              ),
            ],
          ),
          if (t.title.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              t.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: tokens.textPrimary,
                  ),
            ),
          ],
          const SizedBox(height: 10),
          ...TiebaParser.parseContent(
            context,
            _page?.posts.firstOrNull?.content ?? t.firstPostContent,
            _page?.imgs ?? const <String>[],
            _page?.imgsOrgSrc ?? const <String>[],
            selectable: true,
            forumName: t.fname,
          ),
          const Divider(height: 22),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (replies.isEmpty)
            Text(
              '暂无回复预览，点击「全屏阅读」查看完整帖子',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: tokens.textTertiary),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final TiebaThreadPagePost floor in replies) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          TextSpan(
                            text:
                                '#${floor.floor ?? ''} ${_page?.userListSet[floor.uid]?.name ?? floor.nameShow}：',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: tokens.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text:
                                TiebaParser.parserContentString(floor.content),
                            style: TextStyle(color: tokens.textSecondary),
                          ),
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(height: 1.65),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
