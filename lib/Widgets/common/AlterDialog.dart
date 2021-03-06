import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/provider.dart';

class TiebaAlterDialog extends StatelessWidget {
  final String title;
  final Widget? content;
  const TiebaAlterDialog({Key? key, required this.title, this.content})
      : super(key: key);

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
