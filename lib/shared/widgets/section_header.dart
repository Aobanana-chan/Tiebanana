import 'package:flutter/material.dart';

import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 分区标题（概念图 `.shead`）：标题 + 右侧文字动作 / 自定义控件。
///
/// 普通 `ListView` 可以直接使用；首页的 `CustomScrollView`
/// 由 [HomeSectionHeader]（`lib/features/home/widgets/forum_tag.dart`）包一层
/// [SliverToBoxAdapter] 复用这份排版。
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.trailingChild,
    this.onTapTrailing,
  });

  final String title;

  /// 右侧文字动作（如「清空」「7 种」）。
  final String? trailing;

  /// 自定义右侧控件（如一键签到 / 完成）。给定时忽略 [trailing]。
  final Widget? trailingChild;

  final VoidCallback? onTapTrailing;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          TiebananaMetrics.gapLg, 18, TiebananaMetrics.gapLg, 10),
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: tokens.textPrimary),
          ),
          const Spacer(),
          if (trailingChild != null)
            trailingChild!
          else if (trailing != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapTrailing,
              child: Text(
                trailing!,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: tokens.primary),
              ),
            ),
        ],
      ),
    );
  }
}
