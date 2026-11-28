import 'package:flutter/material.dart';
import 'package:tiebanana/features/update/state/update_reminder.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 可叠在入口图标上，也可单独作为设置行的尾部红点。
class UpdateBadge extends StatelessWidget {
  const UpdateBadge({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: UpdateReminder.showDot,
      child: child,
      builder: (BuildContext context, bool showDot, Widget? child) {
        if (!showDot) return child ?? const SizedBox.shrink();
        return Semantics(
          label: '有新版本',
          child: Badge(
            backgroundColor: TiebananaTokens.of(context).danger,
            smallSize: 8,
            child: child,
          ),
        );
      },
    );
  }
}
