import 'package:flutter/material.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 桌面端统一卡片面板（`.panel`）：`surface` 底 + `18dp` 圆角 + `cardShadow` + 可选描边。
class DesktopPanel extends StatelessWidget {
  const DesktopPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final BorderRadius radius = borderRadius ?? TiebananaMetrics.brLg;
    return Container(
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: radius,
        boxShadow: tokens.cardShadow,
        border: Border.all(color: borderColor ?? Colors.transparent),
      ),
      clipBehavior: Clip.antiAlias,
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}

/// 面板标题行（`.panel-hd`）：标题 + 可选计数徽章 + 右侧工具控件。
class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    required this.title,
    this.count,
    this.trailing = const <Widget>[],
    this.padding = const EdgeInsets.fromLTRB(15, 13, 15, 9),
  });

  final String title;
  final int? count;
  final List<Widget> trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Widget titleBlock = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
        ),
        if (count != null) ...<Widget>[
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(minWidth: 19),
            height: 19,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: tokens.fill,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: tokens.textSecondary,
                height: 1,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
        ],
      ],
    );

    if (trailing.isEmpty) {
      return Padding(padding: padding, child: titleBlock);
    }

    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          titleBlock,
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: trailing,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
