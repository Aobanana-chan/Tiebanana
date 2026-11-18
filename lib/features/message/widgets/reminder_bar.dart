import 'package:flutter/material.dart';
import 'package:tiebanana/features/message/state/notification_reminder.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 消息页顶部的 48px 紧凑提醒条 / 44px 展开头部。
///
/// 整条点击只展开或收起，不打开 H5、不清未读；横向甩动只隐藏提醒，
/// 不作用于下面的完整卡片（避免抢页签手势）。
class ReminderBar extends StatelessWidget {
  const ReminderBar({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.onHide,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double height = expanded ? 44 : 48;
    final Widget content = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: TiebananaMetrics.brLg,
        onTap: onToggle,
        child: Container(
          height: height,
          padding: EdgeInsets.only(left: expanded ? 16 : 14, right: 4),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: TiebananaMetrics.brLg,
            boxShadow: tokens.cardShadow,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: expanded
                    ? Text(
                        '收起提醒',
                        style: textTheme.labelLarge?.copyWith(
                          color: tokens.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : _ReminderSummary(tokens: tokens),
              ),
              _BarButton(
                label: expanded ? '收起提醒' : '展开提醒',
                icon: expanded ? Icons.expand_less : Icons.expand_more,
                tokens: tokens,
                onTap: onToggle,
              ),
              _BarButton(
                label: '隐藏提醒',
                icon: Icons.close,
                tokens: tokens,
                onTap: onHide,
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: expanded ? '消息提醒，已展开' : '消息提醒，点击展开',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (DragEndDetails details) {
          final double velocity = details.primaryVelocity ?? 0;
          if (velocity.abs() > 120) onHide();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TiebananaMetrics.pageGutter,
            0,
            TiebananaMetrics.pageGutter,
            TiebananaMetrics.gapSm,
          ),
          child: content,
        ),
      ),
    );
  }
}

class _ReminderSummary extends StatelessWidget {
  const _ReminderSummary({required this.tokens});

  final TiebananaTokens tokens;

  @override
  Widget build(BuildContext context) {
    final NotificationReminder reminder = NotificationReminder.instance;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<InlineSpan> spans = <InlineSpan>[];
    final TextStyle base = textTheme.labelLarge!.copyWith(
      color: tokens.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    final TextStyle nameStyle = base.copyWith(color: tokens.textPrimary);
    final TextStyle numStyle = base.copyWith(
      color: tokens.primary,
      fontWeight: FontWeight.w800,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    final TextStyle mutedStyle = base.copyWith(color: tokens.textTertiary);

    void separator() {
      if (spans.isNotEmpty) {
        spans.add(TextSpan(text: ' · ', style: base));
      }
    }

    if (reminder.mutualCardVisible) {
      separator();
      spans.add(TextSpan(text: '吧友互助', style: nameStyle));
      if (reminder.masked) {
        spans.add(TextSpan(text: ' 已屏蔽', style: mutedStyle));
      } else if (reminder.mutualUnreadRaw > 0) {
        spans.add(
            TextSpan(text: ' ${reminder.mutualUnreadRaw}', style: numStyle));
      }
    }

    if (reminder.broadcastEntryVisible) {
      separator();
      spans.add(TextSpan(text: '吧广播', style: nameStyle));
      if (reminder.broadcastDot) {
        spans.add(TextSpan(text: ' 有新公告', style: mutedStyle));
      } else if (!reminder.broadcastHasData) {
        spans.add(TextSpan(text: ' 查看各吧公告', style: mutedStyle));
      }
    }

    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.label,
    required this.icon,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final TiebananaTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: tokens.textTertiary),
        ),
      ),
    );
  }
}
