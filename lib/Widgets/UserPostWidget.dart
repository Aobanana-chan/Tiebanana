import 'package:flutter/material.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/API/TiebaParser.dart';

import '../Json_Model/WidgetModel/MediaModel.dart';
import '../Json_Model/WidgetModel/PostContentModel.dart';
import '../Json_Model/WidgetModel/QuotaModel.dart';
import '../Json_Model/WidgetModel/ThreadCommentModel.dart';
import '../routes/routes.dart';

///用户界面Post Widget
class UserPostWidget extends StatelessWidget {
  final String username;
  // final UserPostPostList info;
  final List<PostContentBaseWidgetModel> content;
  final List<MediaModel> images;
  final String threadId;
  final String userId;
  final String userPortrait;
  final bool isThread;
  final String title;
  final String createTime;
  final QuotaModel? quota;
  final String? postId;
  final VedioInfoWidgetModel? videoInfo;
  final String forumName;
  final String agreeNum;
  final String disagreeNum;
  final String replyNum;
  const UserPostWidget(
      {Key? key,
      required this.username,
      required this.content,
      required this.images,
      required this.threadId,
      required this.userId,
      required this.userPortrait,
      required this.isThread,
      required this.title,
      required this.createTime,
      required this.quota,
      required this.videoInfo,
      required this.forumName,
      required this.agreeNum,
      required this.disagreeNum,
      required this.replyNum,
      required this.postId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var allImgs = <String>[], allOrgImgs = <String>[];

    for (MediaModel i in images) {
      allImgs.add(i.bigPic);
      allOrgImgs.add(i.originPic);
    }
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Theme.of(context).colorScheme.background,
          border: Border.all(width: 0.05)),
      // padding: EdgeInsets.all(5),
      margin: const EdgeInsets.only(top: 3, bottom: 3),
      child: MaterialButton(
        onPressed: () async {
          Navigator.pushNamed(context, PageRouter.threadPage,
              arguments: ThreadPageRouterData(kz: threadId, pid: null));
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
                        arguments: userId);
                  },
                  imgUrl: AUTHOR_AVATAR + userPortrait,
                  height: 45,
                  width: 45,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(username),
                      ),
                    ]),
                    Row(
                      children: [
                        Text(
                          TiebaParser.getPostTime(strTime: createTime),
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
                visible: isThread,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    children: [
                      Text(
                        title,
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
                children: isThread
                    ? TiebaParser.parseContent(
                        context, content, allImgs, allOrgImgs,
                        mediaLimit: 1, videoInfo: videoInfo)
                    : TiebaParser.parseReplyContent(context, quota, content,
                        title, postId, threadId, allImgs, allOrgImgs),
              ),
            ),
            //底部
            Container(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Expanded(
                      child: Visibility(
                    visible: forumName != "",
                    child: Text(
                      "$forumName吧",
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
                  Text(agreeNum),
                  const SizedBox(width: 5),
                  Visibility(
                    visible: disagreeNum != "",
                    child: const Icon(Icons.thumb_down),
                  ),
                  Visibility(
                      visible: disagreeNum != "",
                      child: const SizedBox(width: 2)),
                  Visibility(
                      visible: disagreeNum != "", child: Text(disagreeNum)),
                  const SizedBox(width: 5),
                  const Icon(Icons.speaker_notes),
                  const SizedBox(width: 2),
                  Text(replyNum),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
