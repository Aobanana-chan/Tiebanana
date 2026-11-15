import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// 自动更新提示和更新页共用的 Release 更新日志。
class UpdateReleaseNotes extends StatelessWidget {
  const UpdateReleaseNotes({super.key, required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final String content = notes.trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('更新日志', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (content.isEmpty)
          const Text('此版本暂未提供更新日志，可前往发布页查看。')
        else
          MarkdownBody(
            data: content,
            shrinkWrap: true,
            selectable: true,
          ),
      ],
    );
  }
}
