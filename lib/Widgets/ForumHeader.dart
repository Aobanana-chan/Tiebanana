import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/common/Global.dart';

///吧页面的头部
class ForumHeader extends StatefulWidget {
  final Forum info;

  ForumHeader({
    Key? key,
    required this.info,
  }) : super(key: key);

  @override
  _ForumHeaderState createState() => _ForumHeaderState();
}

class _ForumHeaderState extends State<ForumHeader> {
  late Forum info;
  @override
  void initState() {
    super.initState();
    info = widget.info;
  }

  Widget buildButton() {
    if (info.isLike == "1") {
      if (info.signInInfo!.userInfo!.isSignIn == "1") {
        return GradientButton(
            borderRadius: BorderRadius.circular(18),
            onPressed: null,
            child: Text("已签到"));
      }
      return GradientButton(
          borderRadius: BorderRadius.circular(18),
          onPressed: () async {
            var msg = await Global.tiebaAPI.signOneForum(widget.info.name!);
            Fluttertoast.showToast(msg: msg["TiebananaMsg"]);
            info.levelupScore = (msg["user_info"]["levelup_score"] as double)
                .toInt()
                .toString();
            info.curScore = (int.parse(info.curScore!) +
                    (msg["user_info"]["sign_bonus_point"]))
                .toInt()
                .toString();
            if (msg["user_info"]["is_sign_in"] == 1) {
              info.signInInfo?.userInfo?.isSignIn = "1";
            }
            setState(() {});
          },
          child: Text("签到"));
    } else {
      return GradientButton(
          borderRadius: BorderRadius.circular(18),
          onPressed: () {
            //TODO:关注吧
          },
          child: Text("关注"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: widget.maxheight,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        color: Colors.white,
        padding: EdgeInsets.all(5),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2),
              child: Avatar(
                imgUrl: widget.info.avatar ?? widget.info.fShareImg!,
                height: 50,
                width: 50,
              ),
            ),
            SizedBox(
              width: 5,
            ),
            SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${widget.info.name}吧",
                    overflow: TextOverflow.ellipsis,
                  ),
                  LimitedBox(
                    maxWidth: 100,
                    child: LinearProgressIndicator(
                      value: int.parse(widget.info.curScore!) /
                          int.parse(widget.info.levelupScore!),
                    ),
                  ),
                  Row(
                    children: [
                      Text("LV${widget.info.levelId}"),
                      SizedBox(width: 5),
                      Text(widget.info.levelName!)
                    ],
                  )
                ],
              ),
            ),
            Spacer(),
            buildButton()
          ],
        ),
      ),
    );
  }
}
