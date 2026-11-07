import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';

class TiebaAlterDialog extends StatelessWidget {
  final String title;
  final Widget? content;
  const TiebaAlterDialog({super.key, required this.title, this.content});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title,
          style: TextStyle(
              fontSize: Provider.of<APPSettingProvider>(context, listen: false)
                  .fontSize)),
      content: content,
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            // borderRadius: BorderRadius.circular(64),
            child: const Text(
              "否",
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
        TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            // borderRadius: BorderRadius.circular(64),
            child:
                const Text("是", style: TextStyle(fontWeight: FontWeight.bold)))
      ],
    );
  }
}

/// 一个选项。点击后对话框以 [value] 关闭。
class TiebaDialogAction<T> {
  const TiebaDialogAction(this.label, this.value);

  final String label;
  final T value;
}

/// 多选项对话框。用于需要“更新 / 稍后 / 跳过此版本”这类三选一的场景。
class TiebaActionDialog<T> extends StatelessWidget {
  const TiebaActionDialog({
    super.key,
    required this.title,
    required this.actions,
    this.content,
  });

  final String title;
  final Widget? content;
  final List<TiebaDialogAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: TextStyle(
          fontSize:
              Provider.of<APPSettingProvider>(context, listen: false).fontSize,
        ),
      ),
      content: content,
      actions: <Widget>[
        for (final TiebaDialogAction<T> action in actions)
          TextButton(
            onPressed: () => Navigator.pop(context, action.value),
            child: Text(
              action.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
