import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 吧页页签的二级控件行：排序 / 分区 / 精品分类。
///
/// 数据全部来自当前页签（`sort_menu` / `partition_menu` / `sub_tab_list`）；
/// 三项都为空的页签隐藏整行，[heightOf] 返回 0。
class ForumControlBar extends StatelessWidget {
  final List<TiebaForumMenuItem> sortMenu;
  final int sortValue;
  final ValueChanged<int> onSortChange;

  final List<TiebaForumMenuItem> partitionMenu;
  final int partitionValue;
  final ValueChanged<int> onPartitionChange;

  final List<TiebaGoodPostClassify> subTabs;
  final String? subTab;
  final ValueChanged<String> onSubTabChange;

  const ForumControlBar({
    super.key,
    required this.sortMenu,
    required this.sortValue,
    required this.onSortChange,
    required this.partitionMenu,
    required this.partitionValue,
    required this.onPartitionChange,
    required this.subTabs,
    required this.subTab,
    required this.onSubTabChange,
  });

  /// 该页签控件行的实际高度（吸顶时的 extent 里要算上）。
  static double heightOf(TiebaForumTab tab) {
    final bool hasPills =
        tab.sortMenu.isNotEmpty || tab.partitionMenu.isNotEmpty;
    final bool hasChips = tab.isGoodTab && tab.subTabs.isNotEmpty;
    if (!hasPills && !hasChips) return 0;
    double h = 8;
    if (hasPills) h += 28;
    if (hasPills && hasChips) h += 6;
    if (hasChips) h += 28;
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPills = sortMenu.isNotEmpty || partitionMenu.isNotEmpty;
    final bool hasChips = subTabs.isNotEmpty;
    if (!hasPills && !hasChips) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          TiebananaMetrics.pageGutter, 0, TiebananaMetrics.pageGutter, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (hasPills)
            SizedBox(
              height: 28,
              child: Row(
                children: <Widget>[
                  if (sortMenu.isNotEmpty)
                    ForumMenuPill(
                      menu: sortMenu,
                      value: sortValue,
                      onChanged: onSortChange,
                    ),
                  if (sortMenu.isNotEmpty && partitionMenu.isNotEmpty)
                    const SizedBox(width: 7),
                  if (partitionMenu.isNotEmpty)
                    ForumMenuPill(
                      menu: partitionMenu,
                      value: partitionValue,
                      onChanged: onPartitionChange,
                    ),
                ],
              ),
            ),
          if (hasPills && hasChips) const SizedBox(height: 6),
          if (hasChips)
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: subTabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (BuildContext context, int i) {
                  final TiebaGoodPostClassify c = subTabs[i];
                  return ForumClassifyChip(
                    label: c.className,
                    selected: c.classId == subTab,
                    onTap: () => onSubTabChange(c.classId),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// 排序 / 分区：药丸下拉。
///
/// 吧页控制栏与吧内搜索工具条共用这一份下拉。
class ForumMenuPill extends StatelessWidget {
  const ForumMenuPill({
    super.key,
    required this.menu,
    required this.value,
    required this.onChanged,
  });

  final List<TiebaForumMenuItem> menu;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    int index = menu.indexWhere((TiebaForumMenuItem m) => m.value == value);
    if (index < 0) index = 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: TiebananaMetrics.brPill,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Theme(
          data: Theme.of(context).copyWith(canvasColor: tokens.surface),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              items: <DropdownMenuItem<int>>[
                for (int i = 0; i < menu.length; i++)
                  DropdownMenuItem<int>(
                      value: i, child: Text(menu[i].text)),
              ],
              value: index,
              isDense: true,
              borderRadius: TiebananaMetrics.brLg,
              dropdownColor: tokens.surface,
              icon: Icon(Icons.keyboard_arrow_down,
                  size: 16, color: tokens.textSecondary),
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: tokens.textSecondary),
              onChanged: (int? i) {
                if (i != null) onChanged(menu[i].value);
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 精品分类 chip。
class ForumClassifyChip extends StatelessWidget {
  const ForumClassifyChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Material(
      color: selected ? tokens.primaryContainer : tokens.surfaceAlt,
      borderRadius: TiebananaMetrics.brPill,
      child: InkWell(
        borderRadius: TiebananaMetrics.brPill,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected
                      ? tokens.onPrimaryContainer
                      : tokens.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}
