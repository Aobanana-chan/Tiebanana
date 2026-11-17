import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/message/models/chat_route_data.dart';
import 'package:tiebanana/features/moderation/widgets/moderation_actions.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/avatar_image.dart';

/// 会话设置：免打扰 / 屏蔽 / 举报。
///
/// 不提供删除会话、清空记录、置顶——协议没有对应命令。
Future<void> showChatSettings(
  BuildContext context,
  ChatRouteData data, {
  VoidCallback? onChanged,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: TiebananaTokens.of(context).surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(26),
      ),
    ),
    builder: (BuildContext context) => _ChatSettingsSheet(
      data: data,
      onChanged: onChanged,
    ),
  );
}

class _ChatSettingsSheet extends StatefulWidget {
  const _ChatSettingsSheet({required this.data, this.onChanged});

  final ChatRouteData data;
  final VoidCallback? onChanged;

  @override
  State<_ChatSettingsSheet> createState() => _ChatSettingsSheetState();
}

class _ChatSettingsSheetState extends State<_ChatSettingsSheet> {
  TiebaChatApi? get _api {
    try {
      final TiebaApi api = Global.tiebaAPI;
      return api is TiebaChatApi ? api as TiebaChatApi : null;
    } catch (_) {
      return null;
    }
  }

  ChatMaskSettings? _mask;
  bool _muted = false;
  bool _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _muted = widget.data.isMuted;
    _load();
  }

  Future<void> _load() async {
    final TiebaChatApi? api = _api;
    if (api == null) return;
    try {
      final ChatMaskSettings mask =
          await api.getChatMask(widget.data.conversationId);
      if (!mounted) return;
      setState(() {
        _mask = mask;
        _muted = mask.muteNotifications;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _toggleMute(bool value) async {
    final TiebaChatApi? api = _api;
    if (api == null || _busy) return;
    final bool previous = _muted;
    setState(() {
      _muted = value;
      _busy = true;
      _error = null;
    });
    try {
      final ChatMaskSettings mask =
          (_mask ?? ChatMaskSettings(userId: widget.data.conversationId))
              .copyWith(muteNotifications: value);
      await api.updateChatMask(mask);
      if (!mounted) return;
      setState(() => _mask = mask);
      widget.onChanged?.call();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _muted = previous;
        _error = error;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String name = widget.data.title.isEmpty ? '贴吧用户' : widget.data.title;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                _Avatar(url: widget.data.avatar),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(name, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '私信会话',
                        style: textTheme.bodySmall
                            ?.copyWith(color: tokens.textTertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _SettingRow(
              icon: Icons.notifications_off_outlined,
              title: '消息免打扰',
              description: '新消息不再提醒，未读数照常记录',
              trailing: Switch(
                value: _muted,
                onChanged: _busy ? null : _toggleMute,
              ),
            ),
            _SettingRow(
              icon: Icons.shield_outlined,
              title: '屏蔽此人',
              description: '不再接收对方的新消息',
              onTap: () async {
                await showBlockSettings(
                  context,
                  uid: widget.data.effectivePeer,
                  name: name,
                );
                widget.onChanged?.call();
              },
            ),
            _SettingRow(
              icon: Icons.flag_outlined,
              title: '举报用户',
              description: '提交给贴吧审核，不附带聊天记录',
              onTap: () => openReportPage(
                context,
                TiebaReportTarget(
                  kind: TiebaReportKind.user,
                  userId: widget.data.effectivePeer,
                  name: name,
                  portrait: widget.data.avatar,
                  source: '私信会话',
                ),
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                '设置没有保存，请稍后重试',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: tokens.danger),
              ),
            ],
            const SizedBox(height: 12),
            Material(
              color: tokens.fill,
              borderRadius: TiebananaMetrics.brPill,
              child: InkWell(
                borderRadius: TiebananaMetrics.brPill,
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: Text(
                    '关闭',
                    style: textTheme.labelLarge
                        ?.copyWith(color: tokens.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: tokens.fill, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? Icon(Icons.person_outline, color: tokens.textTertiary, size: 22)
          : AvatarImage(url: url),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.description,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: TiebananaMetrics.brMd,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tokens.fill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: tokens.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: textTheme.labelSmall?.copyWith(
                      color: tokens.textTertiary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right, color: tokens.textTertiary),
          ],
        ),
      ),
    );
  }
}
