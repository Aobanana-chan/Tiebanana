import 'dart:async';

import 'package:flutter/material.dart' hide SearchBar;
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:tiebanana/shared/controllers/back_to_top_controller.dart';
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


///拉取一页推荐贴的实现。默认走 [Global.tiebaAPI]，测试里注入假数据。
typedef RecommendLoader = Future<RecommendPage> Function(
    int pageThreadCount, int pn);

class RecommendPan extends StatefulWidget {
  final FloatingSearchBarController controller;

  /// 返回键的「先回顶」协作对象。主界面按下返回时先问它，再走退出流程。
  final BackToTopController? backController;
  final RecommendLoader? loader;
  const RecommendPan(
      {super.key,
      required this.controller,
      this.backController,
      this.loader});

  @override
  _RecommendPanState createState() => _RecommendPanState();
}

class _RecommendPanState extends State<RecommendPan> {
  static const int _pageSize = 15;

  ///列表里的 `null` 是「上次读到这里」的续读条占位；广告位（lego_card）单独处理。
  final List<TiebaThreadInfo?> recommend = <TiebaThreadInfo?>[];
  ScrollController controller = ScrollController();
  int pn = 1;

  ///首屏（含下拉刷新）加载中。已有内容时交给 RefreshIndicator。
  bool _loading = true;
  bool _loadingMore = false;

  ///首屏错误 / 翻页错误。首屏错误占满内容区，翻页错误只在列表底部给重试口。
  Object? _error;
  Object? _moreError;
  bool _refreshing = false;

  RecommendLoader get _loader => widget.loader ?? Global.tiebaAPI.getRecommThread;

  @override
  void initState() {
    super.initState();
    refresh();

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

  @override
  void dispose() {
    widget.backController?.detach(this);
    controller.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    if (_refreshing) {
      return;
    }
    _refreshing = true;
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
      final List<TiebaThreadInfo> fresh =
          (await _loader(_pageSize, 1)).threads;
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
      _refreshing = false;
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
    await refresh();
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
                      notLoggedIn: _error != null &&
                          _error.toString().contains("未登录"),
                      loadingMore: _loadingMore,
                      moreError: _moreError,
                      scrollController: controller,
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
  });

  ///`null` 元素是续读条占位。
  final List<TiebaThreadInfo?> items;
  final bool loading;
  final Object? error;
  final bool notLoggedIn;
  final bool loadingMore;
  final Object? moreError;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onResumeTap;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) {
      return _sheet(context, const _RecommendSkeletonList(), center: false);
    }    if (error != null && items.isEmpty) {
      return _sheet(context, _errorView(context));
    }
    if (items.isEmpty) {
      return _sheet(context, _emptyView());
    }
    final bool showFooter = loadingMore || moreError != null;
    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(
            top: TiebananaMetrics.gapSm, bottom: TiebananaMetrics.gapMd),
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + (showFooter ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index >= items.length) {
            return _footer(context);
          }
          final TiebaThreadInfo? item = items[index];
          return item == null
              ? _ResumeBar(onTap: onResumeTap)
              : _threadCard(context, item);
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
    );
  }
}

///「上次读到这里」续读条。
///
///使用 primaryContainer 作为位置标记，视觉层级低于帖子卡片。
class _ResumeBar extends StatelessWidget {
  const _ResumeBar({required this.onTap});

  /// 续读条高度。比普通按钮矮一点，夹在两条帖子中间时不至于把留白撑大。
  static const double _height = 36;

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Padding(
      // 上一张帖子自带 gapSm 下边距，这里上边留 0、下边留 gapSm，
      // 保持两段间距均匀。
      padding: const EdgeInsets.fromLTRB(TiebananaMetrics.pageGutter, 0,
          TiebananaMetrics.pageGutter, TiebananaMetrics.gapSm),
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
  const _RecommendSkeletonList();

  @override
  Widget build(BuildContext context) {
    //用 Column 排版，外层 _sheet 已是滚动容器。
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
