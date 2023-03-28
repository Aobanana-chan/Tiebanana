import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/common/Global.dart';

///吧页面的头部
class ForumHeader extends StatefulWidget {
  final String fName; //吧名
  final String levelupScore; //升级所需经验
  final bool isLike;
  final bool isSigned;
  final String fid;
  final String curScore; //现在的经验
  final String avatar; //吧头像 widget.info.avatar ?? widget.info.fShareImg!
  final String levelId;
  final String levelName;
  // final Forum info;

  const ForumHeader({
    Key? key,
    required this.fName,
    required this.levelupScore,
    required this.isLike,
    required this.isSigned,
    required this.fid,
    required this.curScore,
    required this.avatar,
    required this.levelId,
    required this.levelName,
    // required this.info,
  }) : super(key: key);

  @override
  _ForumHeaderState createState() => _ForumHeaderState();
}

class _ForumHeaderState extends State<ForumHeader> {
  late bool isSignIn;
  late String levelupScore;
  late String curScore;
  late String levelId;
  late String levelName;
  @override
  void initState() {
    super.initState();
    isSignIn = widget.isSigned;
    levelupScore = widget.levelupScore;
    curScore = widget.curScore;
    levelId = widget.levelId;
    levelName = widget.levelName;
  }

  Widget buildButton() {
    if (widget.isLike) {
      if (isSignIn) {
        return GradientButton(
            borderRadius: BorderRadius.circular(18),
            onPressed: null,
            child: const Text("已签到"));
      }
      return GradientButton(
          borderRadius: BorderRadius.circular(18),
          onPressed: () async {
            var msg = await Global.tiebaAPI.signOneForum(widget.fName);
            Fluttertoast.showToast(msg: msg["TiebananaMsg"]);
            levelupScore =
                (msg["user_info"]["levelup_score"] as num).toInt().toString();
            curScore =
                (int.parse(curScore) + (msg["user_info"]["sign_bonus_point"]))
                    .toInt()
                    .toString();
            if (msg["user_info"]["is_sign_in"].toString() == "1") {
              isSignIn = true;
            }

            // TODO:更新levelId和name
            setState(() {});
          },
          child: const Text("签到"));
    } else {
      return GradientButton(
          borderRadius: BorderRadius.circular(18),
          onPressed: () async {
            //TODO:关注吧
            var res = await Global.tiebaAPI.favoForum(widget.fid, widget.fName);
          },
          child: const Text("关注"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Theme.of(context).colorScheme.background,
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            child: Avatar(
              imgUrl: widget.avatar,
              height: 50,
              width: 50,
            ),
          ),
          const SizedBox(
            width: 5,
          ),
          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${widget.fName}吧",
                  overflow: TextOverflow.ellipsis,
                ),
                LimitedBox(
                  maxWidth: 100,
                  child: LinearProgressIndicator(
                    value: int.parse(curScore) / int.parse(levelupScore),
                  ),
                ),
                Row(
                  children: [
                    Text("LV$levelId"),
                    const SizedBox(width: 5),
                    Text(levelName)
                  ],
                )
              ],
            ),
          ),
          const Spacer(),
          buildButton()
        ],
      ),
    );
  }
}
