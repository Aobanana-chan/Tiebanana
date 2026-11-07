import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiebanana/features/compose/models/thread_compose_draft.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 投票独立编辑，取消时保留外层草稿。
class ComposePollEditor extends StatefulWidget {
  const ComposePollEditor({super.key, this.initial});
  final ComposePoll? initial;

  @override
  State<ComposePollEditor> createState() => _ComposePollEditorState();
}

class _ComposePollEditorState extends State<ComposePollEditor> {
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _options = (widget.initial?.options ?? ['', ''])
      .map((value) => TextEditingController(text: value))
      .toList();
  late bool _multiple = widget.initial?.multiple ?? false;
  late int _days = widget.initial?.days ?? -1;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    for (final controller in _options) {
      controller.dispose();
    }
    super.dispose();
  }

  void _finish() {
    final values = _options.map((c) => c.text.trim()).toList();
    final error = ComposePoll.validate(_title.text, values);
    setState(() => _error = error);
    if (error == null) {
      Navigator.pop(
          context,
          ComposePoll(
              title: _title.text.trim(),
              options: values,
              multiple: _multiple,
              days: _days));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TiebananaTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(title: const Text('编辑投票'), actions: [
        TextButton(onPressed: _finish, child: const Text('完成')),
        const SizedBox(width: 8),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _label('投票标题'),
        TextField(
            key: const ValueKey('poll-title'),
            controller: _title,
            minLines: 1,
            maxLines: 3,
            decoration: _decoration('问一个大家都想参与的问题')),
        const SizedBox(height: 24),
        _label('选项 · 每项最多 14 个字，不可重复'),
        for (int i = 0; i < _options.length; i++)
          Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Expanded(
                    child: TextField(
                  key: ValueKey(_options[i]),
                  controller: _options[i],
                  inputFormatters: [LengthLimitingTextInputFormatter(14)],
                  decoration: _decoration('选项 ${i + 1}'),
                )),
                if (_options.length > 2)
                  IconButton(
                      tooltip: '删除选项 ${i + 1}',
                      onPressed: () {
                        final removed = _options[i];
                        setState(() => _options.removeAt(i));
                        // 等旧 EditableText 卸载后再释放控制器。
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) => removed.dispose());
                      },
                      icon: const Icon(Icons.remove_circle_outline)),
              ])),
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
                onPressed: () =>
                    setState(() => _options.add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: const Text('添加选项'))),
        const SizedBox(height: 16),
        _label('投票类型'),
        Wrap(spacing: 8, children: [
          ChoiceChip(
              label: const Text('单选'),
              selected: !_multiple,
              onSelected: (_) => setState(() => _multiple = false)),
          ChoiceChip(
              label: const Text('多选'),
              selected: _multiple,
              onSelected: (_) => setState(() => _multiple = true)),
        ]),
        const SizedBox(height: 24),
        _label('投票有效期'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final value in [-1, 1, 7, 30])
            ChoiceChip(
                label: Text(value == -1 ? '不限时' : '$value 天'),
                selected: _days == value,
                onSelected: (_) => setState(() => _days = value)),
        ]),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(_error!, style: TextStyle(color: tokens.danger))),
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('投票随帖子一同发布。数量上限与发起资格由贴吧校验，发布失败会保留草稿。',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: tokens.textTertiary))),
      ]),
    );
  }

  Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium));

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: TiebananaTokens.of(context).surface,
        border: OutlineInputBorder(
            borderRadius: TiebananaMetrics.brCtl, borderSide: BorderSide.none),
      );
}
