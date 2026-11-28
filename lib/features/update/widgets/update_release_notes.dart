import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 自动更新提示和更新页共用的 Release 更新日志。
class UpdateReleaseNotes extends StatelessWidget {
  const UpdateReleaseNotes({
    super.key,
    required this.notes,
    this.showHeader = true,
  });

  final String notes;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final String content = notes.trim();
    final ThemeData theme = Theme.of(context);
    final TiebananaTokens? tokens = theme.extension<TiebananaTokens>();
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    final Color textPrimary = tokens?.textPrimary ?? scheme.onSurface;
    final Color textSecondary =
        tokens?.textSecondary ?? scheme.onSurfaceVariant;
    final Color primary = tokens?.primary ?? scheme.primary;
    final Color fill = tokens?.fill ?? scheme.surfaceContainerHighest;
    final Color quoteBackground =
        tokens?.quoteBackground ?? scheme.surfaceContainerLow;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (showHeader) ...<Widget>[
          Text(
            '更新日志',
            style: textTheme.titleSmall?.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TiebananaMetrics.gapSm),
        ],
        if (content.isEmpty)
          Text(
            '此版本暂未提供更新日志，可前往发布页查看。',
            style: textTheme.bodySmall?.copyWith(
              color: textSecondary,
              height: 1.6,
            ),
          )
        else
          MarkdownBody(
            data: content,
            shrinkWrap: true,
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: textTheme.bodyMedium?.copyWith(
                color: textSecondary,
                height: 1.65,
              ),
              h2: textTheme.titleSmall?.copyWith(
                color: primary,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
              h3: textTheme.titleSmall?.copyWith(
                color: primary,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
              listBullet: textTheme.bodyMedium?.copyWith(
                color: primary,
              ),
              code: textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: textPrimary,
                backgroundColor: fill,
              ),
              codeblockDecoration: BoxDecoration(
                color: fill,
                borderRadius: TiebananaMetrics.brSm,
              ),
              blockquoteDecoration: BoxDecoration(
                color: quoteBackground,
                border: Border(
                  left: BorderSide(color: primary, width: 3),
                ),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(TiebananaMetrics.radiusXs),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
