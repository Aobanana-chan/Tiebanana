import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/threadSummary.dart';
import 'package:tiebanana/common/API/Constants.dart';

///消息Widget
class MessageCard extends StatelessWidget {
  final ReplyMe? replyMe;
  final AtMe? atME;
  const MessageCard({Key? key, this.replyMe, this.atME}) : super(key: key);
  String getReplyTime() {
    var time = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(
        int.parse(replyMe?.time ?? atME!.time!) * 1000));
    List<String> timeGranularity = ["天", "小时", "分钟", "秒"];
    var f = 0;
    late String text;
    if (time.inDays > 30) {
      var date = DateTime.fromMillisecondsSinceEpoch(
          int.parse(replyMe?.time ?? atME!.time!) * 1000);
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

  Widget _buildBody() {
    String text = replyMe?.quoteContent ?? atME!.quoteContent!;
    if (replyMe != null && replyMe!.quoteContent! == "") {
      text = "回复我的主题: ${replyMe!.title!}";
    }
    if (atME != null && atME!.quoteContent == "") {
      text = "回复我的主题: ${atME!.title!}";
    }
    return Text(text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[600], fontSize: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
          border: Border.all(width: 0.05)),
      // padding: EdgeInsets.all(5),
      margin: EdgeInsets.only(top: 3, bottom: 3),
      child: MaterialButton(
        padding: EdgeInsets.all(5),
        onPressed: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(
                  imgUrl: AUTHOR_AVATAR +
                      (replyMe?.replyer!.portrait! ?? atME!.replyer!.portrait!),
                  height: 45,
                  width: 45,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //头部
                    Row(
                      children: <Widget>[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              "${replyMe?.replyer!.name ?? atME!.replyer!.name}"),
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
                    ),
                  ],
                ),
              ],
            ),

            //引用信息
            Container(
              margin: EdgeInsets.only(top: 5),
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: Color(0xFFF0F3F5),
                  borderRadius: BorderRadius.circular(3)),
              child: Wrap(
                children: [_buildBody()],
              ),
            ),
            //回复信息
            Container(
              padding: EdgeInsets.all(5),
              child: Text(replyMe?.content ?? atME!.content!,
                  style: TextStyle(fontSize: 16)),
            ),
            //底部
            Container(
              padding: EdgeInsets.all(5),
              child: Text(
                "来自${replyMe?.fname ?? atME!.fname}吧",
                style: TextStyle(
                    color: Colors.grey[600], overflow: TextOverflow.ellipsis),
              ),
            )
          ],
        ),
      ),
    );
  }
}
