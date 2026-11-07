import 'package:flutter/material.dart';
import 'package:tiebanana/shared/widgets/alert_dialog.dart';
import 'package:tiebanana/shared/widgets/floating_search_app_bar.dart';

import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 搜索历史在 SharedPreferences 里的键名。保持键名不变以兼容老用户的记录。
const String searchHistoryKey = "searchHistory";

/// 搜索历史浮窗的最大高度，超出部分滚动。
const double searchHistoryDropMaxHeight = 280;

///主页搜索栏Widget
///
///与概念图 `design/mockups/home.html` 对齐：
///- 点击展开「搜索历史」浮窗；有搜索记录时展开。
///- 点历史词只把文字填进搜索框；当搜索框内容与该条完全相同时，
///  再点这条会直接搜索，判断依据是**内容匹配**。
///- 每条历史可单独删除，也可整体清空。
class SearchBar extends StatefulWidget {
  final double? maxHeight;
  final FloatingSearchBarController? barController;
  const SearchBar(
      {super.key, this.maxHeight = double.infinity, this.barController});

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late FloatingSearchBarController barController;
  bool showBody = false;
  AnimationController? controller;

  @override
  void initState() {
    super.initState();
    barController = widget.barController ?? FloatingSearchBarController();
  }

  List<String> get _history =>
      Global.profile.getStringList(searchHistoryKey) ?? <String>[];

  Widget? _buildBody() {
    if (!showBody) {
      return null;
    }
    // 58 = 48（搜索栏高）+ 2 / gapSm（上下留白），让历史下拉紧贴药丸下沿
    return const AnimatedDropDown(barHeight: 48 + 2 + TiebananaMetrics.gapSm);
  }

  void search(BuildContext context, String searchText) {
    final String keyword = searchText.trim();
    // 空输入也能进入搜索页查看历史，但不记录空关键词。
    if (keyword.isNotEmpty) {
      final List<String> cache = List<String>.of(_history);
      // 重复搜索将关键词提前。
      cache.remove(keyword);
      cache.insert(0, keyword);
      Global.profile.setStringList(searchHistoryKey, cache);
    }
    Navigator.pushNamed(context, PageRouter.search, arguments: keyword);
    setState(() {});
  }

  /// 清空搜索历史：先二次确认。
  ///
  /// 放在 SearchBar 的 state 上；下拉浮窗在弹窗出现时会被销毁。
  Future<void> confirmClearSearchHistory() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const TiebaAlterDialog(
        title: "确认清空搜索历史？",
        content: Text("搜索过的关键词会全部删除，且无法恢复。"),
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    Global.profile.setStringList(searchHistoryKey, <String>[]);
    setState(() {});
    if (showBody) {
      controller?.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    // 状态栏留白由 FloatingSearchAppBar 内部固定承担，这里保持布局结构稳定。
    return FloatingSearchAppBar(
      color: tokens.surface,
      controller: barController,
      clearQueryOnClose: false,
      height: 48,
      // 胶囊底边到下面内容只留 gapSm：全站都是「搜索栏 → 页签药丸 / 内容」，
      // 14 会空出一大截（消息页的药丸行、首页的吧列表都嫌它松）。
      margin: const EdgeInsets.fromLTRB(16, 2, 16, TiebananaMetrics.gapSm),
      borderRadius: TiebananaMetrics.brPill,
      shadow: tokens.cardShadow,
      onSubmitted: (searchText) => search(context, searchText),
      leadingActions: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 10),
          child: Icon(Icons.search, size: 20, color: tokens.textTertiary),
        ),
      ],
      hint: "搜索吧、贴、用户",
      body: _buildBody(),
      actions: [
        // 原「一键签到」已移到首页「我关注的吧」标题行；这里改为搜索按钮。
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Material(
            color: tokens.primaryContainer,
            borderRadius: TiebananaMetrics.brPill,
            child: InkWell(
              borderRadius: TiebananaMetrics.brPill,
              onTap: () => search(context, barController.query),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                child: Text(
                  "搜索",
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: tokens.onPrimaryContainer),
                ),
              ),
            ),
          ),
        )
      ],
      onFocusChanged: (focused) {
        if (focused == true) {
          // 没有历史记录就直接搜索栏，不弹空浮窗
          showBody = _history.isNotEmpty;
        } else if (showBody) {
          controller?.reverse();
        }
        setState(() {});
      },
    );
  }
}

/// 搜索历史下拉浮窗。
class AnimatedDropDown extends StatefulWidget {
  final Duration duration;
  final double barHeight;
  const AnimatedDropDown(
      {super.key,
      this.duration = const Duration(milliseconds: 400),
      this.barHeight = 56});

  @override
  _AnimatedDropDownState createState() => _AnimatedDropDownState();
}

class _AnimatedDropDownState extends State<AnimatedDropDown>
    with SingleTickerProviderStateMixin {
  late _SearchBarState? bar;
  List<String> history = <String>[];
  late Animation<double> animation;
  ScrollController scrollController = ScrollController();

  void getHistory() {
    history = Global.profile.getStringList(searchHistoryKey) ?? <String>[];
  }

  @override
  void initState() {
    super.initState();
    getHistory();
    bar = context.findAncestorStateOfType<_SearchBarState>();
    bar!.controller =
        AnimationController(duration: widget.duration, vsync: this);
    animation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: bar!.controller!, curve: Curves.easeOut));
    bar!.controller!.forward();
    bar!.controller!.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        bar!.showBody = false;
        bar!.setState(() {});
        if (scrollController.hasClients) {
          scrollController.jumpTo(0);
        }
        bar!.barController.close();
      }
    });
  }

  @override
  void dispose() {
    if (scrollController.hasClients) {
      scrollController.dispose();
    }
    bar?.controller?.dispose();
    super.dispose();
  }

  /// 删除单条搜索历史。
  void _deleteHistory(String item) {
    final List<String> next = List<String>.of(history)..remove(item);
    Global.profile.setStringList(searchHistoryKey, next);
    setState(() {
      history = next;
    });
    if (next.isEmpty) {
      // 删完最后一条就收起浮窗
      bar!.controller?.reverse();
    }
  }

  /// 清空全部搜索历史：交给 SearchBar 走二次确认。
  void _clearHistory() {
    bar!.confirmClearSearchHistory();
  }

  /// 点历史词：内容不同时填入搜索框，完全相同时直接搜索。
  void _pickHistory(String item) {
    if (bar!.barController.query != item) {
      bar!.barController.query = item;
      setState(() {});
    } else {
      bar!.search(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }
    final double available =
        (bar!.widget.maxHeight ?? double.infinity) - widget.barHeight;
    // 上限：记录再多也不超过 searchHistoryDropMaxHeight，超出部分在列表里滚动；
    // clamp 顺带兜住「无外部高度约束」（available 为 infinity），结果为非负数。
    final double maxHeight =
        available.clamp(0.0, searchHistoryDropMaxHeight).toDouble();
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) =>
          Opacity(opacity: animation.value, child: child),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TiebananaMetrics.gapLg),
        // 只把浮窗实际表面算作内部区域，两侧留白点击仍应收起。
        child: TapRegion(
          groupId: bar!.barController,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: TiebananaMetrics.brLg,
              boxShadow: tokens.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: TiebananaMetrics.brLg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 6),
                    child: Row(
                      children: <Widget>[
                        Text(
                          "搜索历史",
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: tokens.textTertiary),
                        ),
                        const Spacer(),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _clearHistory,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              "清空",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: tokens.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: <Widget>[
                          for (int i = 0; i < history.length; i++) ...<Widget>[
                            if (i > 0)
                              Divider(
                                  height: 1, thickness: 1, color: tokens.line),
                            _buildRow(context, tokens, history[i]),
                          ],
                        ],
                      ),
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

  Widget _buildRow(BuildContext context, TiebananaTokens tokens, String item) {
    final bool match = bar!.barController.query == item;
    final Color fg = match ? tokens.onPrimaryContainer : tokens.textPrimary;
    return InkWell(
      onTap: () => _pickHistory(item),
      child: Container(
        color: match ? tokens.primaryContainer : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: <Widget>[
            Icon(match ? Icons.search : Icons.history,
                size: 16,
                color: match ? tokens.onPrimaryContainer : tokens.textTertiary),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: fg,
                      fontWeight: match ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _deleteHistory(item),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(Icons.close,
                    size: 14,
                    color: match
                        ? tokens.onPrimaryContainer
                        : tokens.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
