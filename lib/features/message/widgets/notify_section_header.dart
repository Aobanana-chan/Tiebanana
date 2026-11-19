import 'package:flutter/material.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 通知区分组头：未读统计 + 折叠 + 隐藏。
///
/// 折叠只影响本机的展开状态，不持久化；隐藏会写入本机可见性。
class NotifySectionHeader extends StatelessWidget {
  const NotifySectionHeader({
    super.key,
    required this.title,
    required this.meta,
    required this.expanded,
    required this.onToggle,
    required this.onHide,
    this.showDot = false,
  });

  final String title;
  final String meta;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onHide;

  /// 广播有新公告但未计入数字时，在统计后面加一颗红点。
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 34,
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              color: tokens.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: .3,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: tokens.textTertiary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures()
                      ],
                    ),
                  ),
                ),
                if (showDot) ...<Widget>[
                  const SizedBox(width: 6),
                  Semantics(
                    label: '有新公告',
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: tokens.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _HeaderButton(
            label: expanded ? '收起通知' : '展开通知',
            icon: expanded ? Icons.expand_less : Icons.expand_more,
            tokens: tokens,
            onTap: onToggle,
          ),
          _HeaderButton(
            label: '隐藏通知',
            icon: Icons.close,
            tokens: tokens,
            onTap: onHide,
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
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
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: tokens.textTertiary),
        ),
      ),
    );
  }
}
