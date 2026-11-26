import 'package:flutter/material.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/features/message/state/message_reminder.dart';
import 'package:tiebanana/features/message/state/notification_reminder.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 共享「消息」未读角标：
/// - 数字优先（私信 + 回复 + @ + 赞 + 未屏蔽互助），严格遵守「吧广播不计入数字」；
/// - 仅当数字为 0 且存在未读吧广播时显示红点。
class MessageBadge extends StatelessWidget {
  const MessageBadge({
    super.key,
    this.child,
    this.compactDot = false,
  });

  /// 非空时包裹在图标右上角（用于底栏或折叠图标轨）；为空时渲染独立行内徽章（展开侧边栏）。
  final Widget? child;

  /// 图标轨折叠态使用 8px 纯红点替代数字，避免遮挡图标。
  final bool compactDot;

  static Listenable get listenable => Listenable.merge(<Listenable>[
        AccountStore.changes,
        MessageReminder.counts,
        MessageReminder.chatUnread,
        NotificationReminder.instance,
      ]);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (BuildContext context, _) {
        final int numbers = MessageReminder.totalUnread;
        final bool dot =
            numbers <= 0 && NotificationReminder.instance.broadcastDot;
        final TiebananaTokens tokens = TiebananaTokens.of(context);

        if (child == null) {
          if (numbers > 0) {
            final String label = numbers > 99 ? '99+' : '$numbers';
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
                label,
                style: TextStyle(
                  color: tokens.onImage,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            );
          }
          if (dot) {
            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: tokens.danger,
                shape: BoxShape.circle,
              ),
            );
          }
          return const SizedBox.shrink();
        }

        if (numbers > 0 && !compactDot) {
          return Badge.count(
            maxCount: 99,
            count: numbers,
            backgroundColor: tokens.danger,
            textColor: tokens.onImage,
            child: child!,
          );
        }
        return Badge(
          isLabelVisible: dot || (compactDot && numbers > 0),
          smallSize: 8,
          backgroundColor: tokens.danger,
          child: child!,
        );
      },
    );
  }
}
