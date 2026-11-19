import 'package:flutter/material.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 搜索栏右侧的铃铛：常驻的提醒入口。
///
/// 不带数字；红点只表示「有隐藏的未读 / 新广播」。
class ReminderBell extends StatelessWidget {
  const ReminderBell({
    super.key,
    required this.showDot,
    required this.onTap,
  });

  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Semantics(
      button: true,
      label: showDot ? '消息提醒，有隐藏的新提醒' : '消息提醒',
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Material(
            color: tokens.surface,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Center(
                      child: Icon(Icons.notifications_none_rounded,
                          size: 21, color: tokens.textSecondary),
                    ),
                    if (showDot)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: tokens.danger,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: tokens.surface, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
