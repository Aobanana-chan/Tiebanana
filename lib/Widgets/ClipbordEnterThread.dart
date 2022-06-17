import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/common/Global.dart';

///剪切板进入帖子Widget

class ClipBordEnterThread extends StatelessWidget {
  final String originUrl;
  final String tid;
  const ClipBordEnterThread(
      {Key? key, required this.tid, required this.originUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Global.tiebaAPI.getThreadPage(tid),
      initialData: originUrl,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          var data = snapshot.data as ThreadPageData;
          return Text(
            data.thread!.title!,
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
