import 'package:flutter/material.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 统一内容居中容器：最大宽度 [maxWidth]（默认 1060dp）并统一水平留白，
/// 同时包裹页面标题与下方卡片网格，保证左右边界严格对齐。
class PageWrap extends StatelessWidget {
  const PageWrap({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.pageMaxWidth,
    this.padding,
    this.topPadding = 20,
    this.bottomPadding = 26,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final double hPad = AppBreakpoints.pagePaddingFor(width);
        final double vTop = width < AppBreakpoints.compactMax
            ? 12
            : (width < AppBreakpoints.mediumMax ? 16 : topPadding);
        final double vBottom = width < AppBreakpoints.compactMax
            ? 18
            : (width < AppBreakpoints.mediumMax ? 22 : bottomPadding);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding:
                  padding ?? EdgeInsets.fromLTRB(hPad, vTop, hPad, vBottom),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// 桌面端页面标题行（`.pagehead`）：左侧主副标题，右侧可选工具控件。
class DesktopPageHeader extends StatelessWidget {
  const DesktopPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.tools = const <Widget>[],
  });

  final String title;
  final String? subtitle;
  final List<Widget> tools;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool compact =
        MediaQuery.sizeOf(context).width < AppBreakpoints.mediumMax;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: compact ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (tools.isNotEmpty) ...<Widget>[
            const SizedBox(width: 16),
            Wrap(
              spacing: 7,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: tools,
            ),
          ],
        ],
      ),
    );
  }
}
