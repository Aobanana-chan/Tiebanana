import 'package:flutter/material.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/platform/official_tieba.dart';

/// 每次进入编辑器提醒一次；只有明确选择继续才解除提醒。
Future<void> showPostingRiskWarning(
    BuildContext context, OfficialTiebaTarget target) async {
  if (!Global.setting.showPostingRiskWarning) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PostingRiskDialog(target: target),
  );
}

class _PostingRiskDialog extends StatefulWidget {
  const _PostingRiskDialog({required this.target});
  final OfficialTiebaTarget target;

  @override
  State<_PostingRiskDialog> createState() => _PostingRiskDialogState();
}

class _PostingRiskDialogState extends State<_PostingRiskDialog> {
  bool _opening = false;
  String? _status;

  Future<void> _openOfficial() async {
    setState(() => _opening = true);
    final opened = await widget.target.open();
    if (!mounted) return;
    setState(() {
      _opening = false;
      _status = opened
          ? '已请求打开官方客户端。请在官方客户端中完成操作；本页不会自动发送。'
          : '无法打开官方客户端，请确认已安装百度贴吧。你也可以手动打开官方客户端，搜索对应的贴吧或帖子。';
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('发帖 / 回帖风险提醒'),
          scrollable: true,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tiebanana 是第三方贴吧客户端，并非百度贴吧官方客户端。'
                  '使用本客户端发帖或回帖可能触发官方风控，导致账号被限制，甚至封号。\n\n'
                  '建议前往百度贴吧官方客户端发帖或回帖。'),
              const SizedBox(height: 12),
              Text(widget.target.isThread
                  ? '将尝试打开官方客户端中的当前帖子。楼层定位取决于官方版本；不保证直接进入回复框，请手动选择回复对象。'
                  : '将尝试打开官方客户端中的当前贴吧，请在吧内手动点击发帖。'),
              const SizedBox(height: 8),
              const Text('不会自动带入草稿、图片或登录账号，请确认官方客户端登录的是你要使用的账号。'
                  '选择“不再提醒”后可在「应用设置」中重新开启。'),
              if (_status != null) ...[
                const SizedBox(height: 12),
                Text(_status!, semanticsLabel: _status),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: _opening
                  ? null
                  : () {
                      Global.setting.showPostingRiskWarning = false;
                      Global.saveProfile();
                      Navigator.pop(context);
                    },
              child: const Text('不再提醒'),
            ),
            TextButton(
              onPressed: _opening ? null : () => Navigator.pop(context),
              child: const Text('无视警告，继续'),
            ),
            FilledButton(
              onPressed: _opening ? null : _openOfficial,
              child: Text(_opening ? '正在打开…' : '前往官方客户端'),
            ),
          ],
        ),
      );
}
