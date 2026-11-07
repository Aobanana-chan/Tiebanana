import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';

///剪切板进入帖子Widget

class ClipBordEnterThread extends StatelessWidget {
  final String originUrl;
  final String tid;
  const ClipBordEnterThread(
      {super.key, required this.tid, required this.originUrl});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Global.tiebaAPI.getThreadPage(tid),
      initialData: originUrl,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          var data = snapshot.data as TiebaThreadPage;
          return Text(
            data.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          );
        }
        return Text(
          originUrl,
          style: const TextStyle(fontWeight: FontWeight.bold),
        );
      },
    );
  }
}
