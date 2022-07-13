import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/API/TiebaParser.dart';

import '../routes/routes.dart';

///用户界面Post Widget
class UserPostWidget extends StatelessWidget {
  final String? username;
  final UserPostPostList info;
  const UserPostWidget({Key? key, required this.info, this.username})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var allImgs = <String>[], allOrgImgs = <String>[];

    for (Media i in info.media ?? []) {
      //忽略视频
      if (i.type != "5") {
        allImgs.add(i.bigPic!);
        allOrgImgs.add(i.originPic!);
      }
    }
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Theme.of(context).backgroundColor,
          border: Border.all(width: 0.05)),
      // padding: EdgeInsets.all(5),
      margin: const EdgeInsets.only(top: 3, bottom: 3),
      child: MaterialButton(
        onPressed: () async {
          Navigator.pushNamed(context, PageRouter.threadPage,
              arguments: ThreadPageRouterData(kz: info.threadId!, pid: null));
          // await Global.tiebaAPI.getThreadPage(info.tid!);
        },
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //作者
            Row(
              children: [
                Avatar(
                  onTap: () {
                    Navigator.pushNamed(context, PageRouter.user,
                        arguments: info.userId!);
                  },
                  imgUrl: AUTHOR_AVATAR + info.userPortrait!,
                  height: 45,
                  width: 45,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            "${info.nameShow != "" ? (info.nameShow ?? info.userName ?? username) : info.userName ?? username}"),
                      ),
                    ]),
                    Row(
                      children: [
                        Text(
                          TiebaParser.getPostTime(strTime: info.createTime),
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                        )
                      ],
                    )
                  ],
                ),
                const Spacer(),
                IconButton(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onPressed: () {
                      //TODO:不感兴趣
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                    ))
              ],
            ),
            //标题
            Visibility(
                visible: info.isThread == "1",
                child: Container(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    children: [
                      Text(
                        info.title!,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      )
                    ],
                  ),
                )),
            //正文
            Container(
              padding: const EdgeInsets.all(5),
              child: Wrap(
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: info.isThread == "1"
                    ? TiebaParser.parseContent(
                        context, info.content, allImgs, allOrgImgs,
                        mediaLimit: 1, videoInfo: info.videoInfo)
                    : TiebaParser.parseReplyContent(context, info.quota,
                        info.content, info.title!, allImgs, allOrgImgs),
              ),
            ),
            //底部
            Container(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Expanded(
                      child: Visibility(
                    visible: info.forumName != null && info.forumName != "",
                    child: Text(
                      "${info.forumName}吧",
                      style: TextStyle(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                  // Spacer(),
                  // const Icon(Icons.remove_red_eye),
                  // const SizedBox(width: 2),
                  // Text(info.viewNum ?? "0"),
                  // const SizedBox(width: 5),
                  const Icon(Icons.thumb_up),
                  const SizedBox(width: 2),
                  Text(info.agreeNum ?? "0"),
                  const SizedBox(width: 5),
                  Visibility(
                    visible: info.agree?.disagreeNum != null,
                    child: const Icon(Icons.thumb_down),
                  ),
                  Visibility(
                      visible: info.agree?.disagreeNum != null,
                      child: const SizedBox(width: 2)),
                  Visibility(
                      visible: info.agree?.disagreeNum != null,
                      child: Text(info.agree?.disagreeNum ?? "0")),
                  const SizedBox(width: 5),
                  const Icon(Icons.speaker_notes),
                  const SizedBox(width: 2),
                  Text(info.replyNum!),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
