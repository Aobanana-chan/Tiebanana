import 'package:flutter/material.dart';
import 'package:tiebanana/features/message/services/official_notify_pages.dart';
import 'package:tiebanana/features/message/state/notify_entry.dart';
import 'package:tiebanana/features/message/state/notification_reminder.dart';
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
        final List<NotifyEntry> entries = reminder.entries;

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
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (entries.isNotEmpty) ...<Widget>[
                      _SectionLabel(text: '通知', tokens: tokens),
                      for (final NotifyEntry entry in entries)
                        _EntryRow(
                          entry: entry,
                          reminder: reminder,
                          hostContext: hostContext,
                        ),
                    ] else
                      const _Note(text: '暂时没有可管理的提醒。'),
                    if (reminder.hasMutualHelp) ...<Widget>[
                      _SectionLabel(text: '账号', tokens: tokens),
                      _AccountRow(reminder: reminder, hostContext: hostContext),
                    ],
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

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.reminder,
    required this.hostContext,
  });

  final NotifyEntry entry;
  final NotificationReminder reminder;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool visible = reminder.isEntryVisible(entry.kind);

    final String status = switch (entry.kind) {
      NotifyEntryKind.mutualHelp => reminder.masked
          ? '已屏蔽'
          : (entry.count > 0 ? '${entry.count} 条未读' : '暂无新提醒'),
      NotifyEntryKind.broadcast =>
        entry.badge == NotifyBadgeKind.dot ? '有新公告' : '暂无新公告',
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _RowIcon(kind: entry.kind, tokens: tokens, muted: entry.muted),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    entry.title,
                    style: textTheme.titleSmall?.copyWith(
                      color: tokens.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: textTheme.labelSmall?.copyWith(
                    color: tokens.textTertiary,
                    fontSize: 10.5,
                  ),
                ),
                _OpenLink(
                  label: entry.kind == NotifyEntryKind.mutualHelp
                      ? '打开互助'
                      : '打开吧广播',
                  onTap: () async {
                    Navigator.of(context).pop();
                    if (entry.kind == NotifyEntryKind.mutualHelp) {
                      await openMutualHelp(hostContext);
                    } else {
                      await openBroadcastFeed(hostContext);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: _MiniSwitch(
              key: ValueKey<String>('notify-visibility-${entry.kind.name}'),
              value: visible,
              label: visible ? '隐藏${entry.title}' : '显示${entry.title}',
              onChanged: (bool value) =>
                  reminder.setEntryVisible(entry.kind, value),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.reminder, required this.hostContext});

  final NotificationReminder reminder;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          _RowIcon(
            kind: NotifyEntryKind.mutualHelp,
            tokens: tokens,
            muted: true,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '接收互助提醒',
                  style: textTheme.titleSmall?.copyWith(
                    color: tokens.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MiniSwitch(
            key: const ValueKey<String>('mutual-account-toggle'),
            value: !reminder.masked,
            label: '接收互助提醒',
            onChanged: reminder.maskedBusy
                ? null
                : (bool value) async {
                    final bool ok = await reminder.setMasked(!value);
                    if (!ok && hostContext.mounted) {
                      ScaffoldMessenger.maybeOf(hostContext)?.showSnackBar(
                        const SnackBar(content: Text('设置没有保存，请重试')),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}

/// 面板里的紧凑开关。Material `Switch` 在本尺寸下会撑高整行，视觉重心也偏。
class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool enabled = onChanged != null;
    return Semantics(
      button: true,
      toggled: value,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : .45,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? () => onChanged!(!value) : null,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 38,
              height: 22,
              decoration: BoxDecoration(
                color: value ? tokens.primary : tokens.surfaceHigh,
                borderRadius: BorderRadius.circular(11),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 160),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: tokens.shadow,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  const _RowIcon({
    required this.kind,
    required this.tokens,
    required this.muted,
  });

  final NotifyEntryKind kind;
  final TiebananaTokens tokens;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: muted ? tokens.fill : tokens.primaryContainer,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        kind == NotifyEntryKind.mutualHelp
            ? Icons.help_outline_rounded
            : Icons.campaign_outlined,
        size: 18,
        color: muted ? tokens.textTertiary : tokens.onPrimaryContainer,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.tokens});

  final String text;
  final TiebananaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 2),
      child: Text(
        text,
        style: TextStyle(
          color: tokens.textTertiary,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: .8,
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
