import 'package:flutter/material.dart';
import 'package:tiebanana/features/message/state/notification_reminder.dart';
import 'package:tiebanana/features/message/state/notification_time.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 吧广播入口。
///
/// 红点始终不带数字；没有 IM 数据时保留入口并显示固定副标题。
class BroadcastEntryCard extends StatelessWidget {
  const BroadcastEntryCard({
    super.key,
    required this.onOpen,
    this.vertical = false,
  });

  final VoidCallback onOpen;

  /// 宽屏展开态用纵向变体：底部多一行「查看吧广播」。
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final NotificationReminder reminder = NotificationReminder.instance;
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String summary = _summary(reminder);
    final String time = reminderTimeLabel(reminder.broadcast.latestTime);
    final Widget head = Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tokens.primaryContainer,
            borderRadius: BorderRadius.circular(TiebananaMetrics.radiusSm),
          ),
          child: Icon(Icons.campaign_outlined,
              size: 20, color: tokens.onPrimaryContainer),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    '吧广播',
                    style: textTheme.titleSmall?.copyWith(
                      color: tokens.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (time.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: tokens.textTertiary,
                          fontSize: 11,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (reminder.broadcastDot) ...<Widget>[
                    const SizedBox(width: 7),
                    _BroadcastDot(),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: tokens.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        if (!vertical) ...<Widget>[
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded,
              size: 16, color: tokens.textTertiary),
        ],
      ],
    );

    return Semantics(
      button: true,
      label: reminder.broadcastDot ? '吧广播，有新公告' : '吧广播',
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: TiebananaMetrics.brLg,
          boxShadow: tokens.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: TiebananaMetrics.brLg,
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(TiebananaMetrics.gapMd),
              child: vertical
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        head,
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Text(
                              '查看吧广播',
                              style: textTheme.labelSmall?.copyWith(
                                color: tokens.primary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded,
                                size: 13, color: tokens.primary),
                          ],
                        ),
                      ],
                    )
                  : head,
            ),
          ),
        ),
      ),
    );
  }

  String _summary(NotificationReminder reminder) {
    if (!reminder.broadcastHasData) return '查看各吧官方公告与吧务通知';
    final String text = reminder.broadcast.displaySummary.trim();
    return text.isEmpty ? '查看各吧官方公告' : text;
  }
}

class _BroadcastDot extends StatelessWidget {
  const _BroadcastDot();

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Semantics(
      label: '有新的吧广播',
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
}
