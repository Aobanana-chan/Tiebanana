import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/shared/widgets/tiebanana_refresh_indicator.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:tiebanana/features/history/models/view_history_page_model.dart';
import 'package:tiebanana/shared/widgets/app_toast.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/app/navigation/app_route_observer.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/forum/state/forum_state.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/alert_dialog.dart';
import 'package:tiebanana/shared/widgets/swipe_action_row.dart';
import 'package:tiebanana/shared/widgets/section_header.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/layout/page_wrap.dart';
import 'package:tiebanana/shared/widgets/avatar_image.dart';
import 'package:tiebanana/shared/widgets/dashed_border.dart';
import 'package:tiebanana/shared/widgets/desktop_panel.dart';
import 'package:tiebanana/shared/widgets/hover_actions.dart';
import 'package:tieba_contract/tieba_contract.dart';

///主页贴合集
class TagPan extends StatefulWidget {
  const TagPan({super.key, this.historyLoader});

  ///最近浏览的取数入口。默认读本地历史库，测试可注入假数据。
  final List<ViewHistoryPageModel> Function()? historyLoader;

  @override
  _TagPanState createState() => _TagPanState();
}

class _TagPanState extends State<TagPan> with RouteAware {
  /// 最近浏览（来自本地历史库，未隐藏的前 N 条，数量由设置决定）。
  List<ViewHistoryPageModel> _history = <ViewHistoryPageModel>[];
  int? _historyLimit;

  /// 展开全部吧（默认缩略，只显示设置里的数量）。
  bool _expanded = false;

  /// 桌面端排序模式。
  bool _reorderMode = false;

  /// 桌面端本地筛选关注的吧。
  final TextEditingController _filterController = TextEditingController();
  String _filterQuery = '';

  /// 是否已向 [appRouteObserver] 订阅，didChangeDependencies 中按此判断是否注册。
  bool _routeSubscribed = false;

  @override
  void initState() {
    super.initState();
    Global.desktopRefreshTick.addListener(_onDesktopRefresh);
  }

  void _onDesktopRefresh() {
    if (mounted) _refresh(syncForums: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final int limit = context.watch<APPSettingProvider>().homeHistoryMaxCount;
    if (_historyLimit != limit) {
      _historyLimit = limit;
      _loadHistory();
    }
    if (_routeSubscribed) {
      return;
    }
    final ModalRoute<void>? route = ModalRoute.of(context);
    if (route != null) {
      appRouteObserver.subscribe(this, route);
      _routeSubscribed = true;
    }
  }

  @override
  void dispose() {
    Global.desktopRefreshTick.removeListener(_onDesktopRefresh);
    _filterController.dispose();
    if (_routeSubscribed) {
      appRouteObserver.unsubscribe(this);
    }
    super.dispose();
  }

  /// 从上层页面返回：浏览历史一定重读；吧页面 / 登录页可能改动关注吧
  /// （签到 / 关注 / 取关），此时重新拉取关注列表，其他页面复用现有数据。
  @override
  void didPopNext() {
    final String? name = appRouteObserver.lastPoppedPageName;
    _refresh(
        syncForums: name == PageRouter.forumHome || name == PageRouter.login);
  }

  List<ViewHistoryPageModel> _readHistory() {
    final List<ViewHistoryPageModel> Function()? loader = widget.historyLoader;
    if (loader != null) {
      return loader().take(_historyLimit!).toList();
    }
    try {
      return Global.daoapi
          .getHistoryList(offset: 0, limit: _historyLimit, includeHidden: false)
          .map((e) => ViewHistoryPageModel.fromViewHistoryDatabase(e))
          .toList();
    } catch (_) {
      // 数据库尚未就绪时不影响首页其余部分
      return <ViewHistoryPageModel>[];
    }
  }

  void _loadHistory() {
    _history = _readHistory();
  }

  Future<void> _refresh({bool syncForums = true}) async {
    if (syncForums && mounted) {
      await Provider.of<ForumState>(context, listen: false).refresh();
    }
    _loadHistory();
    if (mounted) {
      setState(() {});
    }
  }

  /// 清空首页可见的历史记录：只删未隐藏的，隐藏记录保留在浏览历史页。
  Future<void> _confirmClearHistory() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const TiebaAlterDialog(
        title: "确认清空首页的浏览历史？",
        content: Text("将清空所有未隐藏的浏览记录，包括超出首页显示数量的记录；已隐藏的记录仍保留在「浏览历史」"),
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    Global.daoapi.removeAllViewHistory(includeHidden: false);
    setState(_loadHistory);
  }

  Future<void> _confirmDeleteHistory(ViewHistoryPageModel info) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const TiebaAlterDialog(
        title: "删除这条浏览记录？",
        content: Text("删除后不会出现在任何历史列表中，且无法恢复。"),
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    Global.daoapi.deleteViewHistory(info.id);
    setState(_loadHistory);
  }

  /// 隐藏只在首页生效，浏览历史页仍能看到并取消隐藏。
  void _hideHistory(ViewHistoryPageModel info) {
    Global.daoapi.setViewHistoryHidden(info.id, true);
    setState(_loadHistory);
    Fluttertoast.showToast(msg: "已隐藏，可在浏览历史中恢复");
  }

  /// 拖动结束：可见区（缩略态只是关注列表的前 N 个）的顺序变了，
  /// 后面的关注吧原样接上，再按账号保存。
  void _saveVisibleOrder(ForumState forumState, List<LikeForumInfo> ordered) {
    final Map<String, LikeForumInfo> latest = <String, LikeForumInfo>{
      for (final LikeForumInfo f in forumState.forums) f.forumId: f
    };
    final Set<String> orderedIds = <String>{
      for (final LikeForumInfo f in ordered) f.forumId
    };
    final List<LikeForumInfo> merged = <LikeForumInfo>[
      for (final LikeForumInfo f in ordered) latest[f.forumId] ?? f,
      ...forumState.forums
          .where((LikeForumInfo f) => !orderedIds.contains(f.forumId)),
    ];
    forumState.saveForumOrder(merged);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        if (availableWidth >= AppBreakpoints.compactMax) {
          return _buildDesktop(context, availableWidth);
        }
        return _buildMobile(context);
      },
    );
  }

  Widget _buildMobile(BuildContext context) {
    return TiebananaRefreshIndicator(
      onRefresh: _refresh,
      child: Consumer<ForumState>(builder: (context, forumState, _) {
        final List<LikeForumInfo> forums = forumState.forums;
        final int maxCount =
            Provider.of<APPSettingProvider>(context).homeForumMaxCount;
        final bool showAll = _expanded;
        final List<LikeForumInfo> visible =
            showAll ? forums : forums.take(maxCount).toList(growable: false);
        final bool canExpand = forums.length > maxCount;
        return CustomScrollView(
          // 内容不足一屏时也要能下拉刷新
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            const HomeSectionHeader(
              title: "我关注的吧",
              trailingChild: SignAllButton(),
            ),
            if (forumState.error != null)
              const SliverToBoxAdapter(
                child: HomeEmptyHint(
                  icon: Icons.error_outline,
                  title: '关注列表加载失败',
                  body: '请检查网络或在账号管理中重新登录，然后下拉刷新',
                ),
              ),
            if (forums.isEmpty && forumState.error == null)
              const SliverToBoxAdapter(
                child: HomeEmptyHint(
                  icon: Icons.add_circle_outline,
                  title: "还没有关注的吧",
                  body: "在搜索里找一个吧并关注，这里就会显示出来",
                ),
              )
            else if (forums.isNotEmpty) ...<Widget>[
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: TiebananaMetrics.pageGutter),
                sliver: SliverToBoxAdapter(
                  child: _ForumReorderGrid(
                    forums: visible,
                    onOrderChanged: (List<LikeForumInfo> ordered) =>
                        _saveVisibleOrder(forumState, ordered),
                  ),
                ),
              ),
              if (canExpand)
                SliverToBoxAdapter(
                  child: HomeExpandButton(
                    expanded: _expanded,
                    total: forums.length,
                    onTap: () => setState(() => _expanded = !_expanded),
                  ),
                ),
            ],
            if (_history.isNotEmpty) ...<Widget>[
              HomeSectionHeader(
                title: "最近浏览",
                trailing: "清空",
                onTapTrailing: _confirmClearHistory,
              ),
              const SliverToBoxAdapter(child: HomeHistoryTip()),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: TiebananaMetrics.pageGutter),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final ViewHistoryPageModel info = _history[index];
                      final TiebananaTokens tokens =
                          TiebananaTokens.of(context);
                      return SwipeActionRow(
                        key: ValueKey<int>(info.id),
                        margin: const EdgeInsets.only(
                            bottom: TiebananaMetrics.gapSm),
                        actions: <SwipeAction>[
                          SwipeAction(
                            label: "隐藏",
                            icon: Icons.visibility_off_outlined,
                            background: tokens.surfaceHigh,
                            foreground: tokens.textSecondary,
                            onTap: () => _hideHistory(info),
                          ),
                          SwipeAction(
                            label: "删除",
                            icon: Icons.delete_outline,
                            background: tokens.danger,
                            foreground: tokens.accentOn,
                            onTap: () => _confirmDeleteHistory(info),
                          ),
                        ],
                        child: HomeHistoryRow(info: info),
                      );
                    },
                    childCount: _history.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(
              child: SizedBox(height: 12),
            ),
          ],
        );
      }),
    );
  }

  String _greeting() {
    final int h = DateTime.now().hour;
    if (h < 12) return '早上好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  Widget _buildDesktop(BuildContext context, double width) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    // 用外层 LayoutBuilder 的实际宽度判断分栏：和断点判断保持同一来源，
    // 避免 MediaQuery 与真实约束不一致时（如被嵌进更窄的容器）错判。
    final bool twoCol = width >= AppBreakpoints.mediumMax;
    final double rightWidth = width >= 1100 ? 336 : 304;

    String userName = '';
    try {
      userName = Provider.of<User>(context).name.trim();
    } catch (_) {
      userName = AccountStore.current?.name ?? '';
    }
    if (userName.isEmpty) {
      userName = AccountStore.current?.name ?? '';
    }

    return Consumer<ForumState>(
      builder: (BuildContext context, ForumState forumState, _) {
        final List<LikeForumInfo> forums = forumState.forums;
        final int maxCount =
            Provider.of<APPSettingProvider>(context).homeForumMaxCount;
        final int signedCount =
            forums.where((LikeForumInfo f) => f.isSign != '0').length;
        final int unsignedCount = forums.length - signedCount;

        final String q = _filterQuery.trim().toLowerCase();
        final List<LikeForumInfo> baseList = (_expanded || q.isNotEmpty)
            ? forums
            : forums.take(maxCount).toList();
        final List<LikeForumInfo> visible = q.isEmpty
            ? baseList
            : baseList
                .where(
                    (LikeForumInfo f) => f.forumName.toLowerCase().contains(q))
                .toList();
        final bool canExpand = forums.length > maxCount && q.isEmpty;

        final Widget recentPanel = _buildDesktopRecentPanel(context, tokens);

        Widget forumsPanel({double? gridWidth}) => _buildDesktopForumsPanel(
              context,
              tokens,
              forumState,
              forums: forums,
              visible: visible,
              maxCount: maxCount,
              signedCount: signedCount,
              canExpand: canExpand,
              gridWidth: gridWidth,
            );

        final String greetingTitle =
            userName.isEmpty ? _greeting() : '${_greeting()}，$userName';
        final String subtitle = forums.isEmpty
            ? '关注几个贴吧，开始浏览'
            : '${forums.length} 个关注的吧 · $signedCount 个今天已签到'
                '${unsignedCount > 0 ? '，还差 $unsignedCount 个' : '，今日已全签'}';

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageWrap(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                DesktopPageHeader(
                  title: greetingTitle,
                  subtitle: subtitle,
                  tools: <Widget>[
                    _DesktopGhostButton(
                      icon: _reorderMode
                          ? Icons.check_rounded
                          : Icons.tune_rounded,
                      label: _reorderMode ? '完成排序' : '管理排序',
                      active: _reorderMode,
                      onTap: forums.isEmpty
                          ? null
                          : () => setState(() => _reorderMode = !_reorderMode),
                    ),
                  ],
                ),
                if (twoCol)
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      // 先把左栏宽度算出来再交给网格：`IntrinsicHeight` 内部
                      // 不能出现 `LayoutBuilder`，否则查询固有高度会抛异常。
                      final double leftWidth =
                          (constraints.maxWidth - 16 - rightWidth)
                              .clamp(0.0, double.infinity);
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(
                              child: forumsPanel(
                                gridWidth: (leftWidth - 30)
                                    .clamp(0.0, double.infinity),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(width: rightWidth, child: recentPanel),
                          ],
                        ),
                      );
                    },
                  )
                else ...<Widget>[
                  forumsPanel(),
                  const SizedBox(height: 16),
                  recentPanel,
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopForumsPanel(
    BuildContext context,
    TiebananaTokens tokens,
    ForumState forumState, {
    required List<LikeForumInfo> forums,
    required List<LikeForumInfo> visible,
    required int maxCount,
    required int signedCount,
    required bool canExpand,
    double? gridWidth,
  }) {
    return DesktopPanel(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PanelHeader(
                title: '我关注的吧',
                count: forums.length,
                trailing: <Widget>[
                  Container(
                    width: 150,
                    height: 29,
                    decoration: BoxDecoration(
                      color: tokens.fill,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.search_rounded,
                            size: 14, color: tokens.textTertiary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _filterController,
                            onChanged: (String v) =>
                                setState(() => _filterQuery = v),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 11.5,
                                      color: tokens.textPrimary,
                                    ),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: '筛选关注的吧',
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 11.5,
                                    color: tokens.textTertiary,
                                  ),
                            ),
                          ),
                        ),
                        if (_filterQuery.isNotEmpty)
                          InkWell(
                            onTap: () {
                              _filterController.clear();
                              setState(() => _filterQuery = '');
                            },
                            child: Icon(Icons.close_rounded,
                                size: 13, color: tokens.textTertiary),
                          ),
                      ],
                    ),
                  ),
                  _DesktopSignAllButton(
                    onDone: () => forumState.refresh(),
                  ),
                  if (canExpand)
                    _DesktopGhostButton(
                      label: _expanded ? '收起' : '展开全部 (${forums.length})',
                      onTap: () => setState(() => _expanded = !_expanded),
                    ),
                ],
              ),
              if (forumState.error != null && forums.isEmpty)
                const HomeEmptyHint(
                  icon: Icons.error_outline,
                  title: '关注列表加载失败',
                  body: '请检查网络或在账号管理中重新登录，然后刷新',
                )
              else if (forums.isEmpty)
                const HomeEmptyHint(
                  icon: Icons.add_circle_outline,
                  title: '还没有关注的吧',
                  body: '在搜索里找一个吧并关注，这里就会显示出来',
                )
              else if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text('没有匹配的吧'),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 4, 15, 14),
                  child: _ForumReorderGrid(
                    forums: visible,
                    desktop: true,
                    reorderMode: _reorderMode,
                    width: gridWidth,
                    onOrderChanged: (List<LikeForumInfo> ordered) =>
                        _saveVisibleOrder(forumState, ordered),
                  ),
                ),
            ],
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: tokens.line)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _expanded
                        ? '已显示全部 ${forums.length} 个（已签 $signedCount）'
                        : '默认显示 ${math.min(maxCount, forums.length)} 个（共 ${forums.length} 个，已签 $signedCount）',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: tokens.textTertiary,
                        ),
                  ),
                ),
                Text(
                  _reorderMode ? '拖动卡片调整顺序，松手自动保存' : '点击「管理排序」后可拖动卡片排序',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: tokens.textTertiary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRecentPanel(
      BuildContext context, TiebananaTokens tokens) {
    return DesktopPanel(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PanelHeader(
                title: '最近浏览',
                count: _history.length,
                trailing: <Widget>[
                  _DesktopGhostButton(
                    label: '清空',
                    onTap: _history.isEmpty ? null : _confirmClearHistory,
                  ),
                ],
              ),
              if (_history.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 28),
                  child: Center(
                    child: Text(
                      '暂无最近浏览记录',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textTertiary,
                          ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final ViewHistoryPageModel info in _history)
                        _DesktopRecentRow(
                          info: info,
                          onHide: () => _hideHistory(info),
                          onDelete: () => _confirmDeleteHistory(info),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: tokens.fill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '桌面端不再需要“左滑隐藏”。鼠标悬停行时右上角出现隐藏 / 删除；'
              '隐藏记录仍在「个人与设置 → 浏览历史」中保留，可随时恢复。',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10.5,
                    height: 1.65,
                    color: tokens.textTertiary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 「我关注的吧」标题行末尾的一键签到按钮（原在搜索栏里）。
class SignAllButton extends StatelessWidget {
  const SignAllButton({super.key});

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Material(
      color: tokens.primaryContainer,
      borderRadius: TiebananaMetrics.brPill,
      child: InkWell(
        borderRadius: TiebananaMetrics.brPill,
        onTap: () async {
          Fluttertoast.showToast(msg: "签到开始，可前往通知栏查看签到进度");
          try {
            await Global.tiebaAPI.signAll();
          } catch (e) {
            // 服务端返回的原因在 NetAPIError.errorMessage 里，优先原样展示。
            final String message =
                e is NetAPIError ? (e.errorMessage ?? "一键签到失败") : "一键签到失败";
            Fluttertoast.showToast(msg: message);
          } finally {
            // 签到失败也重读一次，保持首页状态最新。
            if (context.mounted) {
              await Provider.of<ForumState>(context, listen: false).refresh();
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
          child: Text(
            "签到",
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens.onPrimaryContainer,
                ),
          ),
        ),
      ),
    );
  }
}

/// 吧区块下方的「展开全部 / 收起」按钮；总数未超过显示上限时隐藏。
class HomeExpandButton extends StatelessWidget {
  const HomeExpandButton({
    super.key,
    required this.expanded,
    required this.total,
    required this.onTap,
  });

  final bool expanded;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          TiebananaMetrics.pageGutter, 9, TiebananaMetrics.pageGutter, 0),
      child: Material(
        color: tokens.surfaceAlt,
        borderRadius: TiebananaMetrics.brSm,
        child: InkWell(
          borderRadius: TiebananaMetrics.brSm,
          onTap: onTap,
          child: SizedBox(
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: TiebananaMetrics.durationFast,
                  child: Icon(Icons.keyboard_arrow_down,
                      size: 18, color: tokens.textTertiary),
                ),
                const SizedBox(width: 6),
                Text(
                  expanded ? "收起" : "展开全部 $total 个",
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: tokens.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 最近浏览的滑动操作提示。
class HomeHistoryTip extends StatelessWidget {
  const HomeHistoryTip({super.key});

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(TiebananaMetrics.gapLg, 0,
          TiebananaMetrics.gapLg, TiebananaMetrics.gapSm),
      child: Text(
        "左滑可隐藏 / 删除 · 隐藏仅影响首页",
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: tokens.textTertiary),
      ),
    );
  }
}

/// 首页吧标签网格。
///
/// 交互对齐手机桌面图标：
/// - 长按抬起后卡片跟手移动，其余标签实时让位（换位预览），松手才落库；
/// - 抬起期间其余标签像 iOS 图标一样轻微抖动，换格 / 落位带触感反馈；
/// - 拖到视口上下沿会自动滚动，吧多到超出一屏时也能拖到任意位置；
/// - 松手后卡片落回目标格；没有真的移动时不写存储。
class _ForumReorderGrid extends StatefulWidget {
  const _ForumReorderGrid({
    required this.forums,
    required this.onOrderChanged,
    this.desktop = false,
    this.reorderMode = false,
    this.width,
  });

  /// 当前可见的吧（缩略态只是关注列表的前 N 个）。
  final List<LikeForumInfo> forums;

  /// 拖动结束后的新可见顺序；顺序没变时不会回调。
  final ValueChanged<List<LikeForumInfo>> onOrderChanged;

  final bool desktop;
  final bool reorderMode;

  /// 已知可用宽度时直接使用，避免在 [IntrinsicHeight] 里嵌套 [LayoutBuilder]。
  ///
  /// 首页宽屏左右两栏用 `IntrinsicHeight` 对齐高度，而 `LayoutBuilder`
  /// 不支持被查询固有尺寸；外层已经拿到约束，就把宽度传进来。
  final double? width;

  @override
  State<_ForumReorderGrid> createState() => _ForumReorderGridState();
}

class _ForumReorderGridState extends State<_ForumReorderGrid>
    with TickerProviderStateMixin {
  int get _columns =>
      widget.desktop && MediaQuery.sizeOf(context).width < 720 ? 2 : 3;
  double get _cellHeight => widget.desktop ? 60 : 38;
  double get _spacing => widget.desktop ? 10 : 7;

  /// 长按判定：排序模式下 80ms 即可拖起，普通模式下 400ms 防误触。
  Duration get _longPressDuration => widget.reorderMode
      ? const Duration(milliseconds: 80)
      : const Duration(milliseconds: 400);

  /// 其余标签让位的动画。
  static const Duration _shiftDuration = Duration(milliseconds: 200);
  static const Curve _shiftCurve = Curves.easeOutCubic;

  /// 抬起后卡片上浮的距离，避免手指挡住吧名。
  static const double _liftRise = 12;

  /// 抖动幅度（弧度）与周期。
  static const Duration _wobblePeriod = Duration(milliseconds: 380);

  /// 落位动画时长。
  static const Duration _landingDuration = Duration(milliseconds: 190);

  /// 拖到距视口上 / 下沿这么近时开始自动滚动。
  static const double _autoScrollEdge = 64;

  /// 自动滚动速度（像素 / 秒）：刚进边缘区最慢，贴到边上最快。
  static const double _autoScrollMinSpeed = 140;
  static const double _autoScrollMaxSpeed = 720;

  /// 单帧最多补多少时间，避免掉帧后一下子滚一大截。
  static const Duration _autoScrollMaxStep = Duration(milliseconds: 50);

  final GlobalKey _gridKey = GlobalKey();

  /// 网格里的当前顺序：拖动时是实时预览，松手后再交给上层保存。
  late List<LikeForumInfo> _order = List<LikeForumInfo>.of(widget.forums);

  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: _wobblePeriod,
  );
  late final AnimationController _landing = AnimationController(
    vsync: this,
    duration: _landingDuration,
  );

  /// 边缘自动滚动的逐帧驱动。
  late final Ticker _autoScroll;
  Duration? _autoScrollLastTick;
  double _autoScrollIntensity = 0;
  double _autoScrollDirection = 0;

  OverlayEntry? _overlay;
  String? _draggedId;
  int? _dragIndex;

  /// 手指按下点相对卡片左上角的偏移（overlay 坐标），保证卡片不跳。
  Offset _grabOffset = Offset.zero;

  /// 浮层卡片当前左上角（overlay 坐标）。
  Offset _dragTopLeft = Offset.zero;
  Offset _landingFrom = Offset.zero;
  Offset _landingTo = Offset.zero;
  double _dragCellWidth = 0;

  /// 拖动开始时网格在滚动视口内的原点与滚动偏移。
  ///
  /// 自动滚动时视口里的网格会移动，用这两个值换算卡片落在第几格，
  /// 不依赖还没重新布局的 RenderBox。
  Offset _gridOriginInViewport = Offset.zero;
  double _gridStartPixels = 0;

  /// 手指最新的全局位置与浮层卡片的中心（全局坐标）。
  Offset _pointerGlobal = Offset.zero;
  Offset _dragCenterGlobal = Offset.zero;

  /// 落位动画结束后要提交的顺序。
  List<LikeForumInfo>? _droppedOrder;

  @override
  void initState() {
    super.initState();
    _autoScroll = createTicker(_onAutoScrollTick);
    _landing.addListener(_tickLanding);
    _landing.addStatusListener(_onLandingStatus);
  }

  @override
  void didUpdateWidget(covariant _ForumReorderGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 拖动中（含落位）以本地预览为准，避免外部刷新把手指下的顺序重置。
    if (_draggedId == null) {
      _order = List<LikeForumInfo>.of(widget.forums);
    }
  }

  @override
  void dispose() {
    _autoScroll.dispose();
    _overlay?.remove();
    _overlay = null;
    _wobble.dispose();
    _landing.dispose();
    super.dispose();
  }

  RenderBox? get _gridBox {
    final RenderObject? object = _gridKey.currentContext?.findRenderObject();
    return object is RenderBox && object.attached ? object : null;
  }

  RenderBox? get _overlayBox {
    final RenderObject? object =
        Overlay.maybeOf(context)?.context.findRenderObject();
    return object is RenderBox && object.attached ? object : null;
  }

  /// 首页所在的滚动视图（拖动时用来做边缘自动滚动）。
  ScrollPosition? get _scrollPosition {
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return null;
    final ScrollPosition position = scrollable.position;
    return position.hasPixels ? position : null;
  }

  RenderBox? get _scrollBox {
    final RenderObject? object =
        Scrollable.maybeOf(context)?.context.findRenderObject();
    return object is RenderBox && object.attached ? object : null;
  }

  LikeForumInfo? get _draggedInfo {
    final String? id = _draggedId;
    if (id == null) return null;
    for (final LikeForumInfo info in _order) {
      if (info.forumId == id) return info;
    }
    return null;
  }

  double _cellWidthFor(double width) =>
      (width - _spacing * (_columns - 1)) / _columns;

  Offset _slotOffset(int index, double cellWidth) => Offset(
        (index % _columns) * (cellWidth + _spacing),
        (index ~/ _columns) * (_cellHeight + _spacing),
      );

  @override
  Widget build(BuildContext context) {
    final double? fixedWidth = widget.width;
    if (fixedWidth != null) {
      return _buildGrid(context, fixedWidth);
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) =>
          _buildGrid(context, constraints.maxWidth),
    );
  }

  Widget _buildGrid(BuildContext context, double width) {
    final double cellWidth = _cellWidthFor(width);
    final int rows = (_order.length / _columns).ceil();
    final double height =
        rows <= 0 ? 0 : rows * _cellHeight + (rows - 1) * _spacing;
    return Listener(
      onPointerCancel: _onPointerCancel,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          key: _gridKey,
          clipBehavior: Clip.none,
          children: <Widget>[
            for (int i = 0; i < _order.length; i++) _buildCell(i, cellWidth, i),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(int index, double cellWidth, int slot) {
    final LikeForumInfo info = _order[index];
    // 被拿起的标签留在树里（只做透明）：手势识别器要一直跟踪手指，
    // 移除这一格会让后续的 move / end 回调丢失。
    final bool lifted = info.forumId == _draggedId;
    final Offset offset = _slotOffset(slot, cellWidth);
    return AnimatedPositioned(
      key: ValueKey<String>(info.forumId),
      duration: _shiftDuration,
      curve: _shiftCurve,
      left: offset.dx,
      top: offset.dy,
      width: cellWidth,
      height: _cellHeight,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: <Type, GestureRecognizerFactory>{
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(duration: _longPressDuration),
            (LongPressGestureRecognizer instance) {
              instance.onLongPressStart = (LongPressStartDetails details) {
                _startDrag(index, info, details);
              };
              instance.onLongPressMoveUpdate = _updateDrag;
              instance.onLongPressEnd = _endDrag;
              instance.onLongPressCancel = _cancelDrag;
            },
          ),
        },
        child: _WobbleTile(
          wobble: _wobble,
          active: _draggedId != null && !lifted,
          phase: (info.forumId.hashCode & 0x7fffffff) % 7 * 0.9,
          child: Opacity(
            opacity: lifted ? 0 : 1,
            child: ForumTag(
              info: info,
              compact: !widget.desktop,
              desktopTile: widget.desktop,
              reorderMode: widget.reorderMode,
            ),
          ),
        ),
      ),
    );
  }

  /// 长按抬起：把卡片交给浮层，网格里留出空位。
  void _startDrag(
      int index, LikeForumInfo info, LongPressStartDetails details) {
    if (_draggedId != null) {
      return;
    }
    final RenderBox? grid = _gridBox;
    final RenderBox? overlayBox = _overlayBox;
    if (grid == null || overlayBox == null) {
      return;
    }
    final double cellWidth = _cellWidthFor(grid.size.width);
    final Offset slotOverlay = overlayBox
        .globalToLocal(grid.localToGlobal(_slotOffset(index, cellWidth)));
    final Offset pointerOverlay =
        overlayBox.globalToLocal(details.globalPosition);

    setState(() {
      _draggedId = info.forumId;
      _dragIndex = index;
      _dragCellWidth = cellWidth;
      _grabOffset = pointerOverlay - slotOverlay;
      _dragTopLeft = pointerOverlay - _grabOffset - const Offset(0, _liftRise);
      _gridOriginInViewport = _scrollBox?.globalToLocal(
            grid.localToGlobal(Offset.zero),
          ) ??
          Offset.zero;
      _gridStartPixels = _scrollPosition?.pixels ?? 0;
      _pointerGlobal = details.globalPosition;
      _dragCenterGlobal = overlayBox.localToGlobal(
        _dragTopLeft + Offset(cellWidth / 2, _cellHeight / 2),
      );
    });
    HapticFeedback.mediumImpact();
    _landing.stop();
    _droppedOrder = null;
    _wobble.repeat();

    final OverlayEntry entry = OverlayEntry(builder: _buildDragCard);
    _overlay = entry;
    Overlay.of(context).insert(entry);
    _syncAutoScroll();
  }

  void _updateDrag(LongPressMoveUpdateDetails details) {
    final RenderBox? overlayBox = _overlayBox;
    if (_dragIndex == null || _overlay == null || overlayBox == null) {
      return;
    }
    _pointerGlobal = details.globalPosition;
    _dragTopLeft = overlayBox.globalToLocal(details.globalPosition) -
        _grabOffset -
        const Offset(0, _liftRise);
    _dragCenterGlobal = overlayBox.localToGlobal(
      _dragTopLeft + Offset(_dragCellWidth / 2, _cellHeight / 2),
    );

    _applyDragTarget();
    _overlay?.markNeedsBuild();
    _syncAutoScroll();
  }

  /// 按卡片中心位置更新预览顺序（换格时给一次触感）。
  void _applyDragTarget() {
    final int? index = _dragIndex;
    if (index == null) return;
    // 自动滚动后网格在视口里的位置会变：用滚动偏移换算局部坐标。
    final RenderBox? viewport = _scrollBox;
    final double pixels = _scrollPosition?.pixels ?? _gridStartPixels;
    final Offset gridOrigin =
        _gridOriginInViewport - Offset(0, pixels - _gridStartPixels);
    // globalToLocal 同时消除视口缩放，不能直接用屏幕坐标减布局滚动量。
    final Offset? local = viewport != null
        ? viewport.globalToLocal(_dragCenterGlobal) - gridOrigin
        : _gridBox?.globalToLocal(_dragCenterGlobal);
    if (local == null) return;
    final int target = _targetIndexFor(local);
    if (target == index) {
      return;
    }
    // 直接改预览顺序：其余标签会在 [AnimatedPositioned] 里滑到新格子。
    final LikeForumInfo dragged = _order.removeAt(index);
    _order.insert(target, dragged);
    _dragIndex = target;
    HapticFeedback.selectionClick();
    setState(() {});
  }

  /// 卡片中心落在哪一格：行列都按槽位取整，最后一格按数量收口。
  int _targetIndexFor(Offset local) {
    final int rows = (_order.length / _columns).ceil().clamp(1, 1 << 20);
    final int column =
        (local.dx / (_dragCellWidth + _spacing)).floor().clamp(0, _columns - 1);
    final int row =
        (local.dy / (_cellHeight + _spacing)).floor().clamp(0, rows - 1);
    return (row * _columns + column).clamp(0, _order.length - 1);
  }

  /// 手指贴到视口上 / 下沿时启动自动滚动；离开边缘就停。
  void _syncAutoScroll() {
    final ScrollPosition? position = _scrollPosition;
    final RenderBox? box = _scrollBox;
    if (_dragIndex == null || position == null || box == null) {
      _stopAutoScroll();
      return;
    }
    const double top = 0;
    final double bottom = box.size.height;
    final double y = box.globalToLocal(_pointerGlobal).dy;

    double direction = 0;
    double intensity = 0;
    if (y < top + _autoScrollEdge) {
      direction = -1;
      intensity =
          ((top + _autoScrollEdge - y) / _autoScrollEdge).clamp(0.0, 1.0);
    } else if (y > bottom - _autoScrollEdge) {
      direction = 1;
      intensity =
          ((y - (bottom - _autoScrollEdge)) / _autoScrollEdge).clamp(0.0, 1.0);
    }
    if (direction == 0) {
      _stopAutoScroll();
      return;
    }
    _autoScrollDirection = direction;
    _autoScrollIntensity = intensity;
    if (!_autoScroll.isActive) {
      _autoScrollLastTick = null;
      _autoScroll.start();
    }
  }

  void _stopAutoScroll() {
    if (_autoScroll.isActive) {
      _autoScroll.stop();
    }
    _autoScrollLastTick = null;
    _autoScrollIntensity = 0;
    _autoScrollDirection = 0;
  }

  void _onAutoScrollTick(Duration elapsed) {
    final Duration? last = _autoScrollLastTick;
    _autoScrollLastTick = elapsed;
    if (last == null) {
      return;
    }
    final ScrollPosition? position = _scrollPosition;
    if (position == null || _dragIndex == null) {
      _stopAutoScroll();
      return;
    }
    final Duration step = elapsed - last;
    final double dt =
        (step > _autoScrollMaxStep ? _autoScrollMaxStep : step).inMicroseconds /
            Duration.microsecondsPerSecond;
    if (dt <= 0) {
      return;
    }
    final double speed = _autoScrollMinSpeed +
        (_autoScrollMaxSpeed - _autoScrollMinSpeed) * _autoScrollIntensity;
    final double next = (position.pixels + speed * dt * _autoScrollDirection)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (next == position.pixels) {
      // 已经到顶 / 到底，等下次手指移动再判断。
      _stopAutoScroll();
      return;
    }
    position.jumpTo(next);
    _applyDragTarget();
  }

  void _endDrag(LongPressEndDetails details) {
    _stopAutoScroll();
    final int? index = _dragIndex;
    if (index == null || _overlay == null) {
      _cancelDrag();
      return;
    }
    final RenderBox? grid = _gridBox;
    final RenderBox? overlayBox = _overlayBox;
    if (grid == null || overlayBox == null) {
      _cancelDrag();
      return;
    }

    if (!_sameOrder(widget.forums, _order)) {
      _droppedOrder = List<LikeForumInfo>.of(_order);
    }
    HapticFeedback.lightImpact();

    _landingFrom = _dragTopLeft;
    _landingTo = overlayBox
        .globalToLocal(grid.localToGlobal(_slotOffset(index, _dragCellWidth)));
    _landing.forward(from: 0);
  }

  /// 长按未成立（滑动手势抢先）时收尾，什么都不保存。
  void _cancelDrag() {
    final bool wasDragging = _draggedId != null || _overlay != null;
    if (!wasDragging) {
      return;
    }
    _stopAutoScroll();
    _droppedOrder = null;
    _landing.stop();
    _overlay?.remove();
    _overlay = null;
    _wobble.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _draggedId = null;
      _dragIndex = null;
      if (!_sameOrder(widget.forums, _order)) {
        _order = List<LikeForumInfo>.of(widget.forums);
      }
    });
  }

  /// 系统打断（来电 / 手势被取消）时长按识别器不会回调 end，主动收尾免得浮层卡住。
  void _onPointerCancel(PointerCancelEvent event) {
    if (_draggedId != null) {
      _cancelDrag();
    }
  }

  void _tickLanding() {
    _dragTopLeft = Offset.lerp(
      _landingFrom,
      _landingTo,
      Curves.easeOutCubic.transform(_landing.value),
    )!;
    _overlay?.markNeedsBuild();
  }

  void _onLandingStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    _stopAutoScroll();
    final List<LikeForumInfo>? dropped = _droppedOrder;
    _droppedOrder = null;
    _overlay?.remove();
    _overlay = null;
    _wobble.stop();
    setState(() {
      _draggedId = null;
      _dragIndex = null;
    });
    if (dropped != null) {
      widget.onOrderChanged(dropped);
    }
  }

  static bool _sameOrder(List<LikeForumInfo> a, List<LikeForumInfo> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i].forumId != b[i].forumId) {
        return false;
      }
    }
    return true;
  }

  /// 浮层里的「被拿起来」的卡片：轻微放大 + 投影，跟手但不拦截点击。
  Widget _buildDragCard(BuildContext context) {
    final LikeForumInfo? info = _draggedInfo;
    if (info == null) {
      return const SizedBox.shrink();
    }
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Positioned(
      left: _dragTopLeft.dx,
      top: _dragTopLeft.dy,
      width: _dragCellWidth,
      height: _cellHeight,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double t, Widget? child) =>
              Transform.translate(
            offset: Offset(0, _liftRise * (1 - t)),
            child: Transform.scale(scale: 1 + 0.12 * t, child: child),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: TiebananaMetrics.brLg,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: tokens.shadow,
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: ForumTag(
                info: info,
                compact: !widget.desktop,
                desktopTile: widget.desktop,
                reorderMode: widget.reorderMode,
                dragging: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 拖动期间其余标签的 iOS 风格抖动：振幅缓入缓出，相位按吧名错开。
class _WobbleTile extends StatelessWidget {
  const _WobbleTile({
    required this.wobble,
    required this.active,
    required this.phase,
    required this.child,
  });

  /// 抖动幅度：约 1.3°，比 iOS 图标克制一些，宽标签不会晃得晃眼。
  static const double _amplitude = 0.022;

  final Animation<double> wobble;
  final bool active;

  /// 每个标签的相位偏移，避免整片同频摆动。
  final double phase;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: active ? 1 : 0),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: child,
      builder: (BuildContext context, double amplitude, Widget? child) {
        if (amplitude == 0) {
          return child!;
        }
        return AnimatedBuilder(
          animation: wobble,
          child: child,
          builder: (BuildContext context, Widget? child) => Transform.rotate(
            angle: amplitude *
                _amplitude *
                math.sin(wobble.value * 2 * math.pi + phase),
            child: child,
          ),
        );
      },
    );
  }
}

/// 首页分区标题：「我关注的吧 / 共 12 个」「最近浏览 / 清空」
///
/// 排版复用 [SectionHeader]（放在 `lib/shared/widgets/section_header.dart`），
/// 这里只负责把它塞进 `CustomScrollView` 的 sliver 槽位。
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.trailingChild,
    this.onTapTrailing,
  });

  final String title;
  final String? trailing;

  /// 自定义右侧控件（如一键签到 / 完成）。给定时忽略 [trailing]。
  final Widget? trailingChild;
  final VoidCallback? onTapTrailing;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SectionHeader(
        title: title,
        trailing: trailing,
        trailingChild: trailingChild,
        onTapTrailing: onTapTrailing,
      ),
    );
  }
}

/// 首页空态。改这里时请同步概念图 design/mockups/states.html。
class HomeEmptyHint extends StatelessWidget {
  const HomeEmptyHint({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
      child: Column(
        children: <Widget>[
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: tokens.fill,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 30, color: tokens.textTertiary),
          ),
          const SizedBox(height: 18),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: tokens.textPrimary)),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: tokens.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// 最近浏览条目：进贴 + 显示吧名与浏览时间
///
/// 外边距 / 左滑操作由 [SwipeActionRow] 负责，这里只画卡片本身。
class HomeHistoryRow extends StatelessWidget {
  const HomeHistoryRow({super.key, required this.info});

  final ViewHistoryPageModel info;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Material(
      color: tokens.surface,
      borderRadius: TiebananaMetrics.brLg,
      child: InkWell(
        borderRadius: TiebananaMetrics.brLg,
        onTap: () {
          Navigator.pushNamed(context, PageRouter.threadPage,
              arguments: ThreadPageRouterData(kz: info.tid, pid: null));
        },
        child: Padding(
          padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      info.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: tokens.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Text(
                          "${info.forumName}吧",
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: tokens.textTertiary),
                        ),
                        const Spacer(),
                        Text(
                          TiebaParser.getPostTime(
                              dateTime: info.latestViewTime),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: tokens.textTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

///主页贴吧tag部件。
///
///[compact] 首页缩略态（3 列 × 38）：色调容器、无投影、字号更小；
///详细态沿用卡片 + 投影 + 54 高。
class ForumTag extends StatelessWidget {
  final LikeForumInfo info;

  /// 缩略态。
  final bool compact;

  /// 桌面端 60dp 宽卡形态。
  final bool desktopTile;

  /// 桌面端排序模式（虚线描边）。
  final bool reorderMode;

  /// 正在被拖动：主色描边（抬起放大 / 落位动画由首页网格负责）。
  final bool dragging;

  /// 覆盖默认的「进吧」点击行为（拖动浮层里用来禁用跳转）。
  final VoidCallback? onTap;

  const ForumTag({
    super.key,
    required this.info,
    this.compact = false,
    this.desktopTile = false,
    this.reorderMode = false,
    this.dragging = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    if (desktopTile) {
      return _buildDesktopTile(context, tokens);
    }
    final TextStyle? nameStyle = compact
        ? Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(fontWeight: FontWeight.w500, color: tokens.textPrimary)
        : Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w500);

    final Border? border =
        dragging ? Border.all(color: tokens.primary, width: 1.4) : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: compact ? tokens.surfaceAlt : tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: compact ? null : tokens.cardShadow,
        border: border,
      ),
      child: MaterialButton(
        onPressed: onTap ??
            () {
              Navigator.pushNamed(context, PageRouter.forumHome,
                  arguments: info.forumName);
            },
        shape: RoundedRectangleBorder(borderRadius: TiebananaMetrics.brLg),
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
        child: Row(
          children: <Widget>[
            Expanded(
                child: Text(
              info.forumName,
              overflow: TextOverflow.ellipsis,
              style: nameStyle,
            )),
            SizedBox(width: compact ? 5 : TiebananaMetrics.gapSm),
            _Rank(
              rank: info.levelId,
              isSigned: info.isSign == "0" ? false : true,
              compact: compact,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTile(BuildContext context, TiebananaTokens tokens) {
    final bool signed = info.isSign != '0';
    final String avatarUrl = resolveAvatarUrl(info.avatar);
    final Widget tile = DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brCtl,
        border: dragging
            ? Border.all(color: tokens.primary, width: 1.4)
            : (reorderMode ? null : Border.all(color: tokens.line)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: TiebananaMetrics.brCtl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: TiebananaMetrics.brCtl,
          hoverColor: tokens.primary.withValues(alpha: .04),
          onTap: reorderMode
              ? () {}
              : (onTap ??
                  () {
                    Navigator.pushNamed(context, PageRouter.forumHome,
                        arguments: info.forumName);
                  }),
          child: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      width: 32,
                      height: 32,
                      color: tokens.fill,
                      child: avatarUrl.isEmpty
                          ? Icon(Icons.forum_outlined,
                              size: 18, color: tokens.textTertiary)
                          : AvatarImage(url: avatarUrl),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${info.forumName}吧',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lv.${info.levelId} · ${signed ? '今日已签' : '未签到'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 10.5,
                                    color: tokens.textTertiary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (signed) ...<Widget>[
                    const SizedBox(width: 6),
                    Opacity(
                      opacity: reorderMode ? 0.3 : 1,
                      child: Icon(Icons.check_rounded,
                          size: 14, color: tokens.primary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (reorderMode && !dragging) {
      return CustomPaint(
        foregroundPainter: DashedBorderPainter(
          color: tokens.lineStrong,
          radius: TiebananaMetrics.brCtl,
        ),
        child: tile,
      );
    }
    return tile;
  }
}

///用户界面吧tag部件（用户主页「关注的吧」双列）
///
///对应概念图 `design/mockups/visitor.html` 的 `.fmed`：surface + 投影 + 圆角 18，
///**不画描边**（与首页的吧卡片同一套层级）；行高 66 = 网格 `mainAxisExtent: 72`
///减去上下各 3 的间距。徽章使用紧凑尺寸，两列里的吧名保持完整显示。
class ForumTagMedium extends StatelessWidget {
  final String avatarUrl;
  final String forumName;
  final String member;
  final String level;
  const ForumTagMedium(
      {super.key,
      required this.avatarUrl,
      required this.forumName,
      required this.member,
      required this.level});

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final int? memberCount = int.tryParse(member);
    return DecoratedBox(
      decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: TiebananaMetrics.brLg,
          boxShadow: tokens.cardShadow),
      child: MaterialButton(
        onPressed: () {
          Navigator.pushNamed(context, PageRouter.forumHome,
              arguments: forumName);
        },
        shape: RoundedRectangleBorder(borderRadius: TiebananaMetrics.brLg),
        padding: const EdgeInsets.fromLTRB(
            TiebananaMetrics.gapSm + 3, 0, TiebananaMetrics.gapSm + 3, 0),
        child: Row(
          children: [
            _UserForumAvatar(avatarUrl: avatarUrl, forumName: forumName),
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  forumName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (memberCount != null) ...<Widget>[
                  const SizedBox(height: TiebananaMetrics.gapXXs),
                  Text(
                    "关注 ${TiebaParser.numberConvertString(memberCount)}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: tokens.textTertiary),
                  ),
                ],
              ],
            )),
            if (level.isNotEmpty)
              _Rank(
                rank: level,
                isSigned: false,
                compact: true,
              )
          ],
        ),
      ),
    );
  }
}

/// Profile 的关注吧预览不展示头像，仅为缺少地址的卡片补取吧头信息。
/// Future 保存在 State 中，父组件重建时复用同一个请求。
class _UserForumAvatar extends StatefulWidget {
  const _UserForumAvatar({required this.avatarUrl, required this.forumName});

  final String avatarUrl;
  final String forumName;

  @override
  State<_UserForumAvatar> createState() => _UserForumAvatarState();
}

class _UserForumAvatarState extends State<_UserForumAvatar> {
  late Future<String> _url;

  @override
  void initState() {
    super.initState();
    _url = _load();
  }

  @override
  void didUpdateWidget(covariant _UserForumAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl ||
        oldWidget.forumName != widget.forumName) {
      _url = _load();
    }
  }

  Future<String> _load() async {
    String url = widget.avatarUrl.trim();
    if (url.isEmpty && widget.forumName.isNotEmpty) {
      try {
        final ForumPage page = await Global.tiebaAPI
            .getForumPage(kw: widget.forumName, pn: 1, rn: 1);
        url = page.forum.avatar.trim();
      } catch (_) {
        // 头像加载失败时返回空地址，列表显示占位图。
        return '';
      }
    }
    if (url.startsWith('//')) return 'https:$url';
    if (url.startsWith('http://')) return 'https://${url.substring(7)}';
    final Uri? uri = Uri.tryParse(url);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? url
        : '';
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Widget placeholder = ColoredBox(
      color: tokens.fill,
      child: Icon(Icons.forum_outlined, size: 22, color: tokens.textTertiary),
    );
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: SizedBox(
        width: 40,
        height: 40,
        child: ClipOval(
          child: FutureBuilder<String>(
            future: _url,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              final String url = snapshot.data ?? '';
              if (url.isEmpty) return placeholder;
              return Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder,
                loadingBuilder: (_, Widget child, ImageChunkEvent? progress) =>
                    progress == null ? child : placeholder,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 吧等级徽章，使用统一的色调容器药丸。
class _Rank extends StatelessWidget {
  const _Rank(
      {required this.rank, required this.isSigned, this.compact = false});

  final String rank;
  final bool isSigned;

  /// 缩略态：更小的徽章，适配 3 列网格。
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      constraints: BoxConstraints(minWidth: compact ? 20 : 25),
      height: compact ? 20 : 25,
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 7),
      decoration: BoxDecoration(
        color: tokens.primaryContainer,
        borderRadius: BorderRadius.circular(TiebananaMetrics.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(rank,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 10 : null,
                    color: tokens.onPrimaryContainer,
                  )),
          if (isSigned) ...<Widget>[
            SizedBox(width: compact ? 2 : 4),
            Icon(Icons.check_circle,
                size: compact ? 11 : 13, color: tokens.primary),
          ],
        ],
      ),
    );
  }
}

class _DesktopGhostButton extends StatelessWidget {
  const _DesktopGhostButton({
    required this.label,
    this.icon,
    this.onTap,
    this.active = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Color fg = active
        ? tokens.onPrimaryContainer
        : (onTap == null
            ? tokens.textTertiary.withValues(alpha: 0.5)
            : tokens.textSecondary);
    return Material(
      color: active ? tokens.primaryContainer : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: active ? Colors.transparent : tokens.line,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          height: 27,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 13, color: fg),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopSignAllButton extends StatefulWidget {
  const _DesktopSignAllButton({required this.onDone});

  final Future<void> Function() onDone;

  @override
  State<_DesktopSignAllButton> createState() => _DesktopSignAllButtonState();
}

class _DesktopSignAllButtonState extends State<_DesktopSignAllButton> {
  bool _busy = false;

  Future<void> _tap() async {
    if (_busy) return;
    setState(() => _busy = true);
    Fluttertoast.showToast(msg: '签到开始，可前往通知栏查看签到进度');
    try {
      await Global.tiebaAPI.signAll();
    } catch (e) {
      final String message =
          e is NetAPIError ? (e.errorMessage ?? '一键签到失败') : '一键签到失败';
      Fluttertoast.showToast(msg: message);
    } finally {
      await widget.onDone();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Material(
      color: tokens.accentFill,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _busy ? null : _tap,
        child: SizedBox(
          height: 27,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.check_rounded, size: 13, color: tokens.accentOn),
                const SizedBox(width: 5),
                Text(
                  _busy ? '签到中…' : '签到',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tokens.accentOn,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopRecentRow extends StatelessWidget {
  const _DesktopRecentRow({
    required this.info,
    required this.onHide,
    required this.onDelete,
  });

  final ViewHistoryPageModel info;
  final VoidCallback onHide;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: HoverActions(
        actionsBuilder: (BuildContext context, bool hovered) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _HoverIconBtn(
                icon: Icons.visibility_off_outlined,
                tooltip: '从首页隐藏（可在浏览历史恢复）',
                onTap: onHide,
              ),
              const SizedBox(width: 2),
              _HoverIconBtn(
                icon: Icons.delete_outline_rounded,
                tooltip: '删除这条记录',
                danger: true,
                onTap: onDelete,
              ),
            ],
          );
        },
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            hoverColor: tokens.primary.withValues(alpha: .05),
            onTap: () {
              Navigator.pushNamed(context, PageRouter.threadPage,
                  arguments: ThreadPageRouterData(kz: info.tid, pid: null));
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 64, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    info.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.48,
                          color: tokens.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${info.forumName}吧 · ${TiebaParser.getPostTime(dateTime: info.latestViewTime)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          color: tokens.textTertiary,
                        ),
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

class _HoverIconBtn extends StatelessWidget {
  const _HoverIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(7),
        elevation: 1,
        shadowColor: tokens.shadow,
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: SizedBox(
            width: 24,
            height: 24,
            child: Icon(
              icon,
              size: 13,
              color: danger ? tokens.danger : tokens.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
