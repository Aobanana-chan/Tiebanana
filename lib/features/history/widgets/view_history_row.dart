import 'package:flutter/material.dart';
import 'package:tiebanana/features/history/models/view_history_page_model.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';

/// 浏览历史的一行。
///
/// 与收藏页的 `StoredThreadWidget` 同构：标题最多两行 + 一行元信息 + 右侧箭头。
/// 外层的卡片投影与左滑操作由 `view_history_page.dart` 负责，这样同一个行组件
/// 既能放进左滑容器，也能在骨架 / 空态里单独渲染。
///
/// 元信息只用真实数据：吧名 + 最近浏览时间。隐藏状态只影响首页，
/// 本页仍会显示对应条目，并在行内标注「已隐藏」。
class ViewHistoryRow extends StatelessWidget {
  const ViewHistoryRow({
    super.key,
    required this.info,
    this.onTap,
  });

  final ViewHistoryPageModel info;
  final VoidCallback? onTap;

  String get _meta {
    final String time = TiebaParser.getPostTime(dateTime: info.latestViewTime);
    if (info.forumName.isEmpty) {
      return "浏览于 $time";
    }
    return "${info.forumName}吧 · 浏览于 $time";
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: tokens.surface,
      borderRadius: TiebananaMetrics.brLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: TiebananaMetrics.brLg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      info.title.isEmpty ? "（无标题）" : info.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall
                          ?.copyWith(color: tokens.textPrimary),
                    ),
                    const SizedBox(height: TiebananaMetrics.gapXs + 2),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall
                                ?.copyWith(color: tokens.textTertiary),
                          ),
                        ),
                        if (info.hidden) ...<Widget>[
                          const SizedBox(width: TiebananaMetrics.gapSm),
                          const _HiddenBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TiebananaMetrics.gapXs),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: tokens.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 「已隐藏」标记：隐藏只影响首页，浏览历史页始终能看得到。
class _HiddenBadge extends StatelessWidget {
  const _HiddenBadge();

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Tooltip(
      message: "只在首页隐藏，左滑可恢复",
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TiebananaMetrics.gapXs + 2,
          vertical: 1,
        ),
        decoration: BoxDecoration(
          color: tokens.fill,
          borderRadius: TiebananaMetrics.brXs,
        ),
        child: Text(
          "已隐藏",
          maxLines: 1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
