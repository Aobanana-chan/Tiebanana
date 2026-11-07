import 'package:flutter/material.dart';
import 'package:tiebanana/features/history/models/view_history_page_model.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

  /// 是否已向 [appRouteObserver] 订阅，didChangeDependencies 中按此判断是否注册。
  bool _routeSubscribed = false;

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

  void _reorder(ForumState forumState, int from, int to) {
    if (from == to) {
      return;
    }
    final List<LikeForumInfo> ordered =
        List<LikeForumInfo>.of(forumState.forums);
    final LikeForumInfo item = ordered.removeAt(from);
    ordered.insert(to, item);
    forumState.saveForumOrder(ordered);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: _refresh,
      child: Consumer<ForumState>(builder: (context, forumState, _) {
        final List<LikeForumInfo> forums = forumState.forums;
        final int maxCount =
            Provider.of<APPSettingProvider>(context).homeForumMaxCount;
        final bool showAll = _expanded;
        final List<LikeForumInfo> visible =
            showAll ? forums : forums.take(maxCount).toList(growable: false);
        final bool canExpand = forums.length > maxCount;
        // 缩略与展开都用同一套 3 列网格：展开只是显示全部，一行数量不变。
        final double cellWidth = (MediaQuery.sizeOf(context).width -
                TiebananaMetrics.pageGutter * 2 -
                14) /
            3;
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
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisExtent: 38,
                      mainAxisSpacing: 7,
                      crossAxisSpacing: 7),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) => _ReorderableForumTag(
                      index: index,
                      info: visible[index],
                      cellWidth: cellWidth,
                      onReorder: (int from, int to) =>
                          _reorder(forumState, from, to),
                    ),
                    childCount: visible.length,
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

/// 首页吧标签：长按直接拖动，落到目标格即重排并按账号保存。
class _ReorderableForumTag extends StatelessWidget {
  const _ReorderableForumTag({
    required this.index,
    required this.info,
    required this.cellWidth,
    required this.onReorder,
  });

  final int index;
  final LikeForumInfo info;
  final double cellWidth;
  final void Function(int from, int to) onReorder;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (DragTargetDetails<int> details) =>
          details.data != index,
      onAcceptWithDetails: (DragTargetDetails<int> details) =>
          onReorder(details.data, index),
      builder:
          (BuildContext context, List<int?> candidate, List<dynamic> rejected) {
        return LongPressDraggable<int>(
          data: index,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: cellWidth,
              height: 38,
              child: ForumTag(
                info: info,
                compact: true,
                showGrip: true,
                dragging: true,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: ForumTag(
              info: info,
              compact: true,
            ),
          ),
          child: ForumTag(
            info: info,
            compact: true,
            highlighted: candidate.isNotEmpty,
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

  /// 排序模式：显示拖动手柄。
  final bool showGrip;

  /// 正在被拖动：轻微放大 + 主色描边。
  final bool dragging;

  /// 拖到目标格上：主色描边高亮。
  final bool highlighted;

  /// 长按进入排序模式。
  final VoidCallback? onLongPress;

  /// 覆盖默认的「进吧」点击行为（排序模式里用来禁用跳转）。
  final VoidCallback? onTap;

  const ForumTag({
    super.key,
    required this.info,
    this.compact = false,
    this.showGrip = false,
    this.dragging = false,
    this.highlighted = false,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextStyle? nameStyle = compact
        ? Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(fontWeight: FontWeight.w500, color: tokens.textPrimary)
        : Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w500);

    final Border? border = highlighted || dragging
        ? Border.all(color: tokens.primary, width: 1.4)
        : null;

    Widget tag = DecoratedBox(
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
        onLongPress: onLongPress,
        shape: RoundedRectangleBorder(borderRadius: TiebananaMetrics.brLg),
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
        child: Row(
          children: <Widget>[
            if (showGrip) ...<Widget>[
              Icon(Icons.drag_indicator, size: 14, color: tokens.textTertiary),
              const SizedBox(width: 2),
            ],
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

    if (dragging) {
      tag = Transform.rotate(
          angle: -0.028, child: Transform.scale(scale: 1.06, child: tag));
    }
    return tag;
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
