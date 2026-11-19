import 'package:flutter/material.dart';
import 'package:tiebanana/features/message/state/notify_entry.dart';
import 'package:tiebanana/features/message/state/notification_time.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 通知区的一行。
///
/// 所有通知共用同一套骨架：图标、标题、摘要、时间、尾部状态、箭头。
/// 类型只决定图标与角标，不再为某个功能单独画一张卡。
class NotifyEntryRow extends StatelessWidget {
  const NotifyEntryRow({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final NotifyEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String time = reminderTimeLabel(entry.time);

    final Widget row = Padding(
      padding: const EdgeInsets.all(TiebananaMetrics.gapMd),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: entry.muted ? tokens.fill : tokens.primaryContainer,
              borderRadius: BorderRadius.circular(TiebananaMetrics.radiusSm),
            ),
            child: Icon(
              _iconOf(entry.kind),
              size: 19,
              color:
                  entry.muted ? tokens.textTertiary : tokens.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: tokens.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (time.isNotEmpty) ...<Widget>[
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: textTheme.labelSmall?.copyWith(
                          color: tokens.textTertiary,
                          fontSize: 11,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (entry.summary.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    entry.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: entry.muted
                          ? tokens.textTertiary
                          : tokens.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (entry.badge != NotifyBadgeKind.none) ...<Widget>[
            const SizedBox(width: 8),
            _Badge(entry: entry),
          ],
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded,
              size: 16, color: tokens.textTertiary),
        ],
      ),
    );

    final Widget card = Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: TiebananaMetrics.brLg,
          onTap: onTap,
          child: row,
        ),
      ),
    );

    return Semantics(
      button: true,
      label: _semanticLabel(entry),
      child: card,
    );
  }

  static IconData _iconOf(NotifyEntryKind kind) => switch (kind) {
        NotifyEntryKind.mutualHelp => Icons.help_outline_rounded,
        NotifyEntryKind.broadcast => Icons.campaign_outlined,
      };

  static String _semanticLabel(NotifyEntry entry) {
    final StringBuffer buffer = StringBuffer(entry.title);
    if (entry.summary.isNotEmpty) buffer.write('，${entry.summary}');
    if (entry.badge == NotifyBadgeKind.count) {
      buffer.write('，${entry.count} 条未读');
    } else if (entry.badge == NotifyBadgeKind.dot) {
      buffer.write('，有新公告');
    }
    return buffer.toString();
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.entry});

  final NotifyEntry entry;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    if (entry.badge == NotifyBadgeKind.dot) {
      return Semantics(
        label: '有新公告',
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: tokens.danger,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    final bool light =
        ThemeData.estimateBrightnessForColor(tokens.danger) == Brightness.light;
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: tokens.danger,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        entry.count > 99 ? '99+' : '${entry.count}',
        style: TextStyle(
          color: light ? tokens.bg : tokens.surface,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          height: 1,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
