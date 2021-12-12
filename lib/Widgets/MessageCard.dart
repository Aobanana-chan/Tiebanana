import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/threadSummary.dart';
import 'package:tiebanana/common/API/Constants.dart';

///消息Widget
class MessageCard extends StatelessWidget {
  final ReplyMe replyMe;
  const MessageCard({Key? key, required this.replyMe}) : super(key: key);
  String getReplyTime() {
    var time = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(int.parse(replyMe.time!) * 1000));
    List<String> timeGranularity = ["天", "小时", "分钟", "秒"];
    var f = 0;
    late String text;
    if (time.inDays > 30) {
      var date =
          DateTime.fromMillisecondsSinceEpoch(int.parse(replyMe.time!) * 1000);
      return "${date.year}年${date.month}月${date.day}日";
    }
    for (var t in [time.inDays, time.inHours, time.inMinutes, time.inSeconds]) {
      if (t != 0) {
        text = "$t${timeGranularity[f]}前";
        break;
      }
      f++;
    }
    if (f == 4) {
      text = "0秒前";
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
          border: Border.all(width: 0.05)),
      padding: EdgeInsets.all(5),
      margin: EdgeInsets.only(top: 3, bottom: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(
                imgUrl: AUTHOR_AVATAR + replyMe.replyer!.portrait!,
                height: 45,
                width: 45,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("${replyMe.replyer!.name}"),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        getReplyTime(),
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  )
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
