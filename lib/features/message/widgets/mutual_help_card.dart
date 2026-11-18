import 'package:flutter/material.dart';
import 'package:tiebanana/features/message/state/notification_reminder.dart';
import 'package:tiebanana/features/message/state/notification_time.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 吧友互助卡片。
///
/// 只消费可见标记、未读数、最近时间和屏蔽开关；不显示提问者、问题标题或
/// 逐条未读，这些字段原生协议没有给。
class MutualHelpCard extends StatelessWidget {
  const MutualHelpCard({
    super.key,
    required this.onOpen,
    required this.onMaskChanged,
  });

  final VoidCallback onOpen;
  final ValueChanged<bool> onMaskChanged;

  @override
  Widget build(BuildContext context) {
    final NotificationReminder reminder = NotificationReminder.instance;
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool masked = reminder.masked;
    final int unread = reminder.mutualUnreadRaw;
    final bool hasUnread = unread > 0 && !masked;

    final String subtitle;
    if (masked) {
      subtitle = '卡片保留，不再显示未读数字';
    } else if (unread > 0) {
      final String time = reminderTimeLabel(reminder.mutual.latestTime);
      subtitle = time.isEmpty ? '$unread 个新问题' : '$unread 个新问题 · 最近 $time';
    } else {
      subtitle = '暂时没有新求助';
    }

    final String action = masked ? '打开互助' : (unread > 0 ? '去帮忙' : '进入');

    return Semantics(
      button: true,
      label: masked ? '吧友互助，已屏蔽，打开互助' : '吧友互助，$unread 个新求助，打开互助',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: masked ? tokens.fill : tokens.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.help_outline_rounded,
                          size: 20,
                          color: masked
                              ? tokens.textTertiary
                              : tokens.onPrimaryContainer,
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
                                    '吧友互助',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.titleSmall?.copyWith(
                                      color: tokens.textPrimary,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (hasUnread) ...<Widget>[
                                  const SizedBox(width: 7),
                                  _CountBadge(count: unread),
                                ],
                                if (masked) ...<Widget>[
                                  const SizedBox(width: 7),
                                  _MaskedChip(),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
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
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              height: 24,
                              child: Transform.scale(
                                scale: 0.78,
                                child: Switch(
                                  value: !masked,
                                  onChanged: reminder.maskedBusy
                                      ? null
                                      : (bool value) => onMaskChanged(!value),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '接收提醒',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelSmall?.copyWith(
                                  color: tokens.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _HelpAction(
                        label: action,
                        tonal: masked || unread == 0,
                        onTap: onOpen,
                      ),
                    ],
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

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
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
        count > 99 ? '99+' : '$count',
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

class _MaskedChip extends StatelessWidget {
  const _MaskedChip();

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      height: 19,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: tokens.fill,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '已屏蔽',
        style: TextStyle(
          color: tokens.textTertiary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HelpAction extends StatelessWidget {
  const _HelpAction({
    required this.label,
    required this.tonal,
    required this.onTap,
  });

  final String label;
  final bool tonal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: tonal ? tokens.fill : tokens.accentFill,
        borderRadius: TiebananaMetrics.brPill,
        child: InkWell(
          borderRadius: TiebananaMetrics.brPill,
          onTap: onTap,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    color: tonal ? tokens.textSecondary : tokens.accentOn,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!tonal) ...<Widget>[
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14, color: tokens.accentOn),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
