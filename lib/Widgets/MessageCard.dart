import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/SpecialSpan.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/API/TiebaParser.dart';

///消息Widget
class MessageCard extends StatelessWidget {
  final ReplyMe? replyMe;
  final AtMe? atME;
  const MessageCard({Key? key, this.replyMe, this.atME}) : super(key: key);

  Widget _buildBody() {
    String text = replyMe?.quoteContent ?? atME!.quoteContent!;
    if (replyMe != null && replyMe!.quoteContent! == "") {
      text = "回复我的主题: ${replyMe!.title!}";
    }
    if (atME != null && atME!.quoteContent == "") {
      text = "回复我的主题: ${atME!.title!}";
    }
    return ExtendedText(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: Colors.grey[600], fontSize: 16),
      specialTextSpanBuilder: TiebaSpanBuilder(),
    );
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
                          TiebaParser.getPostTime(strTime: replyMe!.time!),
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
              width: double.infinity,
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
              child: ExtendedText(replyMe?.content ?? atME!.content!,
                  specialTextSpanBuilder: TiebaSpanBuilder(),
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
