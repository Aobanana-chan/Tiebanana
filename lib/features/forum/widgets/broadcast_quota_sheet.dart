import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/message/services/official_notify_pages.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 吧广播本月配额面板。
///
/// 原生只读 `used_cnt / has_cnt`；发布与编辑在网页版完成。
Future<void> showBroadcastQuotaSheet(
  BuildContext context,
  TiebaBroadcastQuota quota,
) async {
  final bool wide = MediaQuery.sizeOf(context).width >= 900;
  if (wide) {
    await showDialog<void>(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.54),
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: _QuotaPanel(quota: quota, hostContext: context, wide: true),
        ),
      ),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) =>
        _QuotaPanel(quota: quota, hostContext: context, wide: false),
  );
}

class _QuotaPanel extends StatelessWidget {
  const _QuotaPanel({
    required this.quota,
    required this.hostContext,
    required this.wide,
  });

  final TiebaBroadcastQuota quota;
  final BuildContext hostContext;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int used = quota.used < 0 ? 0 : quota.used;
    final int total = quota.total < 0 ? 0 : quota.total;
    final double progress =
        total <= 0 ? 0 : (used > total ? 1 : used / total).toDouble();
    final String note =
        total <= 0 ? '当前没有吧广播额度' : (quota.remaining <= 0 ? '本月吧广播次数已用完' : '');

    return Container(
      width: wide ? 360 : double.infinity,
      padding: EdgeInsets.fromLTRB(16, wide ? 20 : 8, 16, wide ? 20 : 24),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: wide
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!wide)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: tokens.lineStrong,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '本月吧广播',
                  style: textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, size: 18, color: tokens.textTertiary),
              ),
            ],
          ),
          Text(
            '发布与编辑在贴吧网页版完成',
            style: textTheme.labelSmall?.copyWith(
              color: tokens.textTertiary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                '${quota.remaining}',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -0.5,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures()
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '次可用',
                style: TextStyle(
                  color: tokens.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (note.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              note,
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('已用 $used 次',
                  style: TextStyle(color: tokens.textTertiary, fontSize: 11)),
              Text('共 $total 次',
                  style: TextStyle(color: tokens.textTertiary, fontSize: 11)),
            ],
          ),
          if (total > 0) ...<Widget>[
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: tokens.fill,
                valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            '发布与编辑在贴吧网页版完成，这里只显示剩余次数。',
            style: TextStyle(
              color: tokens.textTertiary,
              fontSize: 11,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _QuotaButton(
                  label: '关闭',
                  tonal: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              if (quota.canPublish) ...<Widget>[
                const SizedBox(width: 9),
                Expanded(
                  child: _QuotaButton(
                    label: '去发布',
                    tonal: false,
                    onTap: () async {
                      Navigator.of(context).pop();
                      await openBroadcastPublish(hostContext);
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _QuotaButton extends StatelessWidget {
  const _QuotaButton({
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
    return Material(
      color: tonal ? tokens.fill : tokens.accentFill,
      borderRadius: TiebananaMetrics.brPill,
      child: InkWell(
        borderRadius: TiebananaMetrics.brPill,
        onTap: onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: tonal ? tokens.textSecondary : tokens.accentOn,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
