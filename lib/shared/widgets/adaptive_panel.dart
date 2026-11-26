import 'package:flutter/material.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 自适应弹层：`< 720dp` 走底部抽屉（`showModalBottomSheet`），
/// `≥ 720dp` 走桌面居中对话框（`showDialog`，支持 Esc 与点击遮罩关闭）。
Future<T?> showAdaptivePanel<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxWidth = 420,
  double maxHeightFactor = 0.85,
  bool isScrollControlled = true,
  bool showDragHandle = false,
}) {
  final Size size = MediaQuery.sizeOf(context);
  final bool desktop = size.width >= AppBreakpoints.compactMax;
  final TiebananaTokens tokens = TiebananaTokens.of(context);

  if (desktop) {
    return showDialog<T>(
      context: context,
      barrierColor: tokens.imageScrim.withValues(alpha: 0.42),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: tokens.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 16,
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: tokens.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: size.height * maxHeightFactor,
            ),
            child: builder(dialogContext),
          ),
        );
      },
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    backgroundColor: tokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(TiebananaMetrics.radiusXl),
      ),
    ),
    builder: builder,
  );
}
