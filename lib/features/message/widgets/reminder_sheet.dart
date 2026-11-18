import 'package:flutter/material.dart';
import 'package:tiebanana/features/message/services/official_notify_pages.dart';
import 'package:tiebanana/features/message/state/notification_reminder.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 打开「消息提醒」面板：移动端 bottom sheet，宽屏居中弹层。
Future<void> showReminderSheet(BuildContext context) async {
  final bool wide = MediaQuery.sizeOf(context).width >= 900;
  if (wide) {
    await showDialog<void>(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.54),
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 640),
          child: _ReminderSheet(wide: true, hostContext: context),
        ),
      ),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82),
      child: _ReminderSheet(wide: false, hostContext: context),
    ),
  );
}

class _ReminderSheet extends StatelessWidget {
  const _ReminderSheet({required this.wide, required this.hostContext});

  final bool wide;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return AnimatedBuilder(
      animation: NotificationReminder.instance,
      builder: (BuildContext context, Widget? child) {
        final NotificationReminder reminder = NotificationReminder.instance;
        final Widget content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (wide) const SizedBox(height: 4) else _Handle(tokens: tokens),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '消息提醒',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 12),
              child: Text(
                '关闭卡片不会清除未读，底部角标仍会提示。',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: tokens.textTertiary,
                      fontSize: 11,
                      height: 1.5,
                    ),
              ),
            ),
            _Note(text: '显示卡片/入口只影响本机；接收提醒是账号开关。'),
            const SizedBox(height: 4),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (reminder.hasMutualHelp)
                      _MutualHelpRow(
                        reminder: reminder,
                        hostContext: hostContext,
                      ),
                    if (reminder.hasBroadcastEntry)
                      _BroadcastRow(
                        reminder: reminder,
                        hostContext: hostContext,
                      ),
                    if (reminder.hasBroadcastEntry)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: _Note(text: '广播红点跟随系统通知权限；这里不提供 switch 17 开关。'),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: wide ? 12 : 8),
          ],
        );
        return Container(
          width: wide ? 360 : double.infinity,
          padding: EdgeInsets.fromLTRB(16, wide ? 12 : 8, 16, wide ? 16 : 20),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: wide
                ? BorderRadius.circular(24)
                : const BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: tokens.shadow,
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: content,
        );
      },
    );
  }
}

class _MutualHelpRow extends StatelessWidget {
  const _MutualHelpRow({required this.reminder, required this.hostContext});

  final NotificationReminder reminder;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String status;
    if (reminder.masked) {
      status = '已屏蔽';
    } else if (reminder.mutualUnreadRaw > 0) {
      status =
          '${reminder.mutualUnreadRaw} 条未读 · ${reminder.mutualVisible ? '显示中' : '已隐藏'}';
    } else {
      status = '暂无新提醒';
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.line)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _RowIcon(icon: Icons.help_outline_rounded, tokens: tokens),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '吧友互助',
                            style: textTheme.titleSmall?.copyWith(
                              color: tokens.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _MiniSwitch(
                          value: reminder.mutualVisible,
                          label: '显示卡片',
                          onChanged: reminder.setMutualVisible,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status,
                      style: textTheme.labelSmall?.copyWith(
                        color: tokens.textTertiary,
                        fontSize: 10.5,
                      ),
                    ),
                    _OpenLink(
                      label: '打开互助',
                      onTap: () async {
                        Navigator.of(context).pop();
                        await openMutualHelp(hostContext);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 47),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '接收提醒（账号）',
                    style: textTheme.labelSmall?.copyWith(
                      color: tokens.textSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ),
                Switch(
                  value: !reminder.masked,
                  onChanged: reminder.maskedBusy
                      ? null
                      : (bool value) async {
                          final bool ok = await reminder.setMasked(!value);
                          if (!ok && hostContext.mounted) {
                            ScaffoldMessenger.maybeOf(hostContext)
                                ?.showSnackBar(
                              const SnackBar(content: Text('设置没有保存，请重试')),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BroadcastRow extends StatelessWidget {
  const _BroadcastRow({required this.reminder, required this.hostContext});

  final NotificationReminder reminder;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String status = reminder.broadcastDot
        ? '有新公告 · ${reminder.broadcastVisible ? '显示中' : '已隐藏'}'
        : '暂无新公告';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _RowIcon(icon: Icons.campaign_outlined, tokens: tokens),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '吧广播',
                        style: textTheme.titleSmall?.copyWith(
                          color: tokens.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _MiniSwitch(
                      value: reminder.broadcastVisible,
                      label: '显示入口',
                      onChanged: reminder.setBroadcastVisible,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  status,
                  style: textTheme.labelSmall?.copyWith(
                    color: tokens.textTertiary,
                    fontSize: 10.5,
                  ),
                ),
                _OpenLink(
                  label: '打开吧广播',
                  onTap: () async {
                    Navigator.of(context).pop();
                    await openBroadcastFeed(hostContext);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  const _RowIcon({required this.icon, required this.tokens});

  final IconData icon;
  final TiebananaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: tokens.primaryContainer,
        borderRadius: BorderRadius.circular(TiebananaMetrics.radiusSm),
      ),
      child: Icon(icon, size: 18, color: tokens.onPrimaryContainer),
    );
  }
}

class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Semantics(
      button: true,
      label: label,
      toggled: value,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 24,
              child: Transform.scale(
                scale: 0.72,
                child: Switch(value: value, onChanged: onChanged),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: tokens.textTertiary,
                fontSize: 9,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenLink extends StatelessWidget {
  const _OpenLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    color: tokens.primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward_rounded,
                    size: 12, color: tokens.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.fill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tokens.textSecondary,
          fontSize: 10.5,
          height: 1.55,
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle({required this.tokens});

  final TiebananaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: tokens.lineStrong,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
