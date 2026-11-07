import 'package:flutter/material.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 列表页的状态族版式：空态 / 错误态 / 未登录。
///
/// 对应概念图 `design/mockups/states.html`：图标容器 + 标题 + 说明 + 最多两个操作。
/// 各页只需提供文案与按钮，居中排版由这里统一处理。
/// 加载中用 [SkeletonBox] 画骨架，不走这里。
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.primaryLabel,
    this.primaryIcon,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String body;

  /// 主操作（实心）。为空时只显示说明文字。
  final String? primaryLabel;
  final IconData? primaryIcon;
  final VoidCallback? onPrimary;

  /// 次操作（描边）。
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool hasActions = primaryLabel != null || secondaryLabel != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 46),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: tokens.fill,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 30, color: tokens.textTertiary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: tokens.textTertiary),
          ),
          if (hasActions) ...<Widget>[
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (primaryLabel != null)
                  _StateButton(
                    label: primaryLabel!,
                    icon: primaryIcon,
                    onTap: onPrimary,
                    filled: true,
                  ),
                if (primaryLabel != null && secondaryLabel != null)
                  const SizedBox(width: 10),
                if (secondaryLabel != null)
                  _StateButton(
                    label: secondaryLabel!,
                    onTap: onSecondary,
                    filled: false,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StateButton extends StatelessWidget {
  const _StateButton({
    required this.label,
    this.icon,
    this.onTap,
    required this.filled,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Color foreground = filled ? tokens.accentOn : tokens.textSecondary;
    return Material(
      color: filled ? tokens.accentFill : Colors.transparent,
      borderRadius: TiebananaMetrics.brSm,
      child: InkWell(
        borderRadius: TiebananaMetrics.brSm,
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: TiebananaMetrics.brSm,
            border: filled
                ? null
                : Border.all(color: tokens.lineStrong, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
