import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:tiebanana/Widgets/LikeButtonEx.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/API/TiebaParser.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/routes.dart';

import '../Json_Model/WidgetModel/PostContentModel.dart';
import '../Json_Model/WidgetModel/ThreadCommentModel.dart';
import '../Json_Model/WidgetModel/ThreadPageModel.dart';

///帖子组件-楼主
class ThreadFirstComment extends StatelessWidget {
  // final PostList postMain;
  final ThreadPagePost postMain;
  final AuthorWidgetModel author;
  final VedioInfoWidgetModel? videoInfo;
  final List<String> allImgs;
  final List<String> allOrgImgs;
  final String threadID;
  final ThreadData thread;
  const ThreadFirstComment(
      {Key? key,
      required this.postMain,
      required this.author,
      this.videoInfo,
      required this.allImgs,
      required this.allOrgImgs,
      required this.threadID,
      required this.thread})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Colors.white,
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Theme.of(context).primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //标题
          Container(
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                SelectableText(
                  postMain.title,
                  style: const TextStyle(
                      // color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                )
              ],
            ),
          ),
          //作者
          Container(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Avatar(
                  imgUrl: AUTHOR_AVATAR + author.portrait,
                  height: 45,
                  width: 45,
                  onTap: () {
                    Navigator.pushNamed(context, PageRouter.user,
                        arguments: author.id);
                  },
                ),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(author.name),
                            ),
                          ] +
                          (TiebaParser.processIcon(author) ?? <Widget>[]) +
                          [
                            Container(
                              margin: const EdgeInsets.only(left: 5),
                              child: Rank(
                                rank: author.levelID,
                              ),
                            )
                          ],
                    ),
                    Row(
                      //楼层数
                      children: [
                        Text(
                          "${postMain.floor}楼",
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        //发帖时间
                        Text(
                          TiebaParser.getPostTime(strTime: postMain.createTime),
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                            child: Container(
                          constraints: const BoxConstraints(
                              maxHeight: 1000, maxWidth: 1000),
                          child: Visibility(
                              visible: postMain.lbsInfo != null,
                              child: Text("${postMain.lbsInfo}",
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 14))),
                        ))
                      ],
                    )
                  ],
                )),
                AgreeAndDisagreeBar(
                  agreeNum: int.parse(postMain.agreeNum!),
                  disagreeNum: int.parse(postMain.disagreeNum!),
                  agreeType: int.parse(thread.agreeType!),
                  postID: postMain.id,
                  threadID: threadID,
                  objType: 3,
                  hasAgree: postMain.hasAgree!,
                )
              ],
            ),
          ),
          //正文
          Container(
            padding: const EdgeInsets.all(5),
            child: Wrap(
              children: TiebaParser.parseContent(
                  context, postMain.content, allImgs, allOrgImgs,
                  videoInfo: videoInfo, selectable: true),
            ),
          ),
        ],
      ),
    );
  }
}

class AgreeAndDisagreeBar extends StatefulWidget {
  final int agreeNum;
  final int disagreeNum;
  final int agreeType;
  final String postID;
  final String threadID;
  final int objType;
  final String hasAgree;
  const AgreeAndDisagreeBar(
      {Key? key,
      this.agreeNum = 0,
      this.disagreeNum = 0,
      this.agreeType = 0,
      required this.postID,
      required this.threadID,
      required this.objType,
      required this.hasAgree})
      : super(key: key);

  @override
  _AgreeAndDisagreeBarState createState() => _AgreeAndDisagreeBarState();
}

//TODO:BUG 滑动后点赞状态消失
class _AgreeAndDisagreeBarState extends State<AgreeAndDisagreeBar> {
  late int agreeNum;
  late int disagreeNum;
  bool like = false;
  bool dislike = false;

  GlobalKey<LikeButtonStateEx> likeKey = GlobalKey<LikeButtonStateEx>();
  GlobalKey<LikeButtonStateEx> dislikeKey = GlobalKey<LikeButtonStateEx>();
  @override
  void initState() {
    super.initState();
    agreeNum = widget.agreeNum;
    disagreeNum = widget.disagreeNum;
    if (widget.hasAgree == "1") {
      if (widget.agreeType == 2) {
        like = true;
      } else if (widget.agreeType == 5) {
        dislike = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LikeButtonEx(
          key: likeKey,
          onTap: (isLiked) async {
            like = !isLiked;
            if (!dislike) {
              try {
                if (like) {
                  //点赞
                  await Global.tiebaAPI.agreePost(
                      widget.postID, widget.threadID, widget.objType);
                } else {
                  //取消点赞
                  await Global.tiebaAPI.agreePost(
                      widget.postID, widget.threadID, widget.objType,
                      opType: 1);
                }
              } catch (e) {
                Fluttertoast.showToast(msg: e.toString().substring(11));
              }
            } else {
              await Global.tiebaAPI
                  .agreePost(widget.postID, widget.threadID, widget.objType);
            }

            if (!isLiked && dislike) {
              dislikeKey.currentState?.onTap();
            }
            return !isLiked;
          },
          likeBuilder: (isLiked) {
            if (!isLiked) {
              return const Icon(
                Icons.thumb_up_alt_outlined,
                // color: Colors.black,
              );
            } else {
              return Icon(Icons.thumb_up_alt,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).primaryColor
                      : Colors.white);
            }
          },
          likeCount: agreeNum,
          isLiked: like,
        ),
        LikeButtonEx(
          key: dislikeKey,
          onTap: (isLiked) async {
            dislike = !isLiked;
            if (!like) {
              try {
                if (dislike) {
                  //点踩
                  await Global.tiebaAPI.agreePost(
                      widget.postID, widget.threadID, widget.objType,
                      agreeType: 5);
                } else {
                  //取消点踩
                  await Global.tiebaAPI.agreePost(
                      widget.postID, widget.threadID, widget.objType,
                      opType: 1, agreeType: 5);
                }
              } catch (e) {
                Fluttertoast.showToast(msg: e.toString().substring(11));
              }
            } else {
              await Global.tiebaAPI.agreePost(
                  widget.postID, widget.threadID, widget.objType,
                  agreeType: 5);
            }

            if (!isLiked && like) {
              likeKey.currentState?.onTap();
            }
            return !isLiked;
          },
          likeBuilder: (isLiked) {
            if (!isLiked) {
              return const Icon(
                Icons.thumb_down_alt_outlined,
                // color: Colors.black,
              );
            } else {
              return Icon(Icons.thumb_down_alt,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).primaryColor
                      : Colors.white);
            }
          },
          likeCount: disagreeNum,
          isLiked: dislike,
        )
      ],
    );
  }
}

class Rank extends StatelessWidget {
  final String? rank;
  Rank({
    Key? key,
    this.rank,
  }) : super(key: key);
  //[字体,背景色]
  final List<List<Color>> _rankColor = [
    [const Color(0xFFFFFFFF), const Color(0xFFFFCCE2)],
    [const Color(0xFFFFFFFF), const Color(0xFF6F6F6F)],
    [const Color(0xFF3AFF44), const Color(0xFF553626)],
    [const Color(0xFF281DCF), const Color(0xFFFFE7B8)],
    [const Color(0xFF753771), const Color(0xFFFDE9D6)],
    [const Color(0xFFFF8E31), const Color(0xFF3D3B02)],
  ];
  List<Color> setColor() {
    if (rank != null && rank != "") {
      int r = int.parse(rank!);
      return _rankColor[r ~/ 3];
    } else {
      return _rankColor[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 5, right: 5),
      decoration: BoxDecoration(
          color: setColor()[1], borderRadius: BorderRadius.circular(10)),
      child: ClipRRect(
        // borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Text(
              rank == "" ? "1" : rank!,
              style: TextStyle(color: setColor()[0]),
            ),
          ],
        ),
      ),
    );
  }
}
