import 'package:animate_do/animate_do.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/LikeButtonEx.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/Widgets/VIdeoPlayer.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/Global.dart';

///帖子组件-楼主
class ThreadFirstComment extends StatelessWidget {
  final PostList postMain;
  final UserList author;
  final VideoInfo? videoInfo;
  final List<String> allImgs;
  final List<String> allOrgImgs;
  final String threadID;
  final Thread thread;
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

  List<Widget>? processIcon() {
    List<Widget>? icons = author.iconinfo?.map((e) {
      return FadeIn(
          child: ExtendedImage.network(
        e.icon!,
        width: 16,
        height: 16,
        cache: true,
      ));
    }).toList();
    return icons;
  }

  String getPostTime({String? strTime, int? intTime}) {
    DateTime time;
    if (strTime != null) {
      time = DateTime.fromMillisecondsSinceEpoch(int.parse(strTime) * 1000);
    } else if (intTime != null) {
      time = DateTime.fromMillisecondsSinceEpoch(intTime * 1000);
    } else {
      throw Exception("至少要有一个参数不为null");
    }
    var create = DateTime.now().difference(time);
    Map timeGranularity = {0: "天", 1: "小时", 2: "分钟", 3: "秒"};
    var f = 0;
    late String createText;
    if (create.inDays > 30) {
      createText = "${time.year}年${time.month}月${time.day}日";
    } else {
      for (var t in [
        create.inDays,
        create.inHours,
        create.inMinutes,
        create.inSeconds
      ]) {
        if (t != 0) {
          createText = "创建于$t${timeGranularity[f]}前";
          break;
        }
        f++;
      }
      if (f == 4) {
        createText = "创建于0秒前";
      }
    }
    return createText;
  }

  //获取图片的index
  int getImgIndex(String img) {
    if (allImgs.length == 0) {
      return 0;
    }
    for (var i = 0; i < allImgs.length; i++) {
      if (img == allImgs[i]) {
        return i;
      }
    }
    return 0;
  }

  List<Widget> buildBody(BuildContext context) {
    List<Widget> body = [];
    List<String> imgs = [];
    List<String>? imgsOriginSrc = [];
    List<String> videos = [];
    String text = "";
    //统计与格式化
    for (Content elem in postMain.content ?? []) {
      if (elem.type == "0") //文字内容
      {
        text += elem.text!;
      } else if (elem.type == "4" || elem.type == "3") {
        //图片
        switch (Global.setting.pictureLoadSetting) {
          case 0:
            if (elem.type == "4" && elem.originSrc == null) {
              //@用户
              body.add(Text(
                elem.text!,
                style: TextStyle(color: Colors.blue),
              ));
              break;
            }
            imgs.add(elem.bigCdnSrc ?? elem.originSrc!);
            imgsOriginSrc!.add(elem.originSrc!);
            break;
          case 1:
            if (elem.type == "4" && elem.originSrc == null) {
              //@用户
              body.add(Text(
                elem.text!,
                style: TextStyle(color: Colors.blue),
              ));
              break;
            }
            if (int.parse(elem.bsize!.replaceAll(",", "")) < 0x100000) {
              //小于1mb就加载
              imgs.add(elem.bigCdnSrc!);
              imgsOriginSrc!.add(elem.originSrc!);
            }
            break;
          case 2:
            if (elem.type == "4" && elem.originSrc == null) {
              //@用户
              body.add(Text(
                elem.text!,
                style: TextStyle(color: Colors.blue),
              ));
              break;
            }
            imgs.add(elem.originSrc!);
            imgsOriginSrc = null;
            break;

          default:
        }
      } else if (elem.type == "5") {
        //视频
        // print("find vedio");
        if (videoInfo?.videoUrl == null) {
          //TODO:外链视频
        } else {
          videos.add(videoInfo!.videoUrl!);
        }
      }
    }

    //生成widget
    //文字内容
    if (text != "") {
      body.add(
        SelectableText(
          text,
          style: TextStyle(fontSize: 16),
          // softWrap: true,
          maxLines: null,
        ),
      );
    }

    //图片
    int offset = 0;
    if (imgs.length > 0) {
      offset = getImgIndex(imgs[0]);
    }
    int index = 0;
    for (var img in imgs) {
      ExtendedPageController controller =
          ExtendedPageController(initialPage: index + offset);
      body.add(Container(
        margin: EdgeInsets.only(top: 3, bottom: 3),
        child: Thumbnail(
          imgs: allImgs,
          controller: controller,
          img: img,
          imgsOriginSrc: allOrgImgs,
          fit: BoxFit.fitWidth,
        ),
      ));
      index++;
    }
    //视频
    for (var video in videos) {
      body.add(Container(
        constraints: BoxConstraints(maxHeight: 200),
        child: VideoPlayer(
          cover: videoInfo!.thumbnailUrl!,
          url: video,
        ),
      ));
    }
    return body;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //标题
          Container(
            margin: EdgeInsets.only(top: 5),
            padding: EdgeInsets.all(5),
            child: Column(
              children: [
                SelectableText(
                  postMain.title!,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                )
              ],
            ),
          ),
          //作者
          Container(
            padding: EdgeInsets.all(5),
            child: Row(
              children: [
                Avatar(
                  imgUrl: AUTHOR_AVATAR + author.portrait!,
                  height: 45,
                  width: 45,
                ),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("${author.nameShow}"),
                            ),
                          ] +
                          (processIcon() ?? <Widget>[]) +
                          [
                            Container(
                              margin: EdgeInsets.only(left: 5),
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
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        //发帖时间
                        Text(
                          getPostTime(strTime: postMain.time),
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(
                          width: 10,
                        ),

                        Expanded(
                            child: Container(
                          constraints:
                              BoxConstraints(maxHeight: 1000, maxWidth: 1000),
                          child: Visibility(
                              visible: postMain.lbsInfo != null,
                              child: Text("${postMain.lbsInfo?.name}",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey))),
                        ))
                      ],
                    )
                  ],
                )),
                AgreeAndDisagreeBar(
                  agreeNum: int.parse(postMain.agree!.agreeNum!),
                  disagreeNum: int.parse(postMain.agree!.disagreeNum!),
                  agreeType: int.parse(thread.agree!.agreeType!),
                  postID: postMain.id!,
                  threadID: threadID,
                  objType: 3,
                )
              ],
            ),
          ),
          //正文
          Container(
            padding: EdgeInsets.all(5),
            child: Wrap(
              children: buildBody(context),
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
  AgreeAndDisagreeBar(
      {Key? key,
      this.agreeNum = 0,
      this.disagreeNum = 0,
      this.agreeType = 0,
      required this.postID,
      required this.threadID,
      required this.objType})
      : super(key: key);

  @override
  _AgreeAndDisagreeBarState createState() => _AgreeAndDisagreeBarState();
}

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
    if (widget.agreeType == 2) {
      like = true;
    } else if (widget.agreeType == 5) {
      dislike = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
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
              }

              if (!isLiked && dislike) {
                dislikeKey.currentState?.onTap();
              }
              return !isLiked;
            },
            likeBuilder: (isLiked) {
              if (!isLiked) {
                return Icon(
                  Icons.thumb_up_alt_outlined,
                  color: Colors.black,
                );
              } else {
                return Icon(Icons.thumb_up_alt, color: Colors.blue);
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
              }

              if (!isLiked && like) {
                likeKey.currentState?.onTap();
              }
              return !isLiked;
            },
            likeBuilder: (isLiked) {
              if (!isLiked) {
                return Icon(
                  Icons.thumb_down_alt_outlined,
                  color: Colors.black,
                );
              } else {
                return Icon(Icons.thumb_down_alt, color: Colors.blue);
              }
            },
            likeCount: disagreeNum,
            isLiked: dislike,
          )
        ],
      ),
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
    [Color(0xFFFFFFFF), Color(0xFFFFCCE2)],
    [Color(0xFFFFFFFF), Color(0xFF6F6F6F)],
    [Color(0xFF3AFF44), Color(0xFF553626)],
    [Color(0xFF281DCF), Color(0xFFFFE7B8)],
    [Color(0xFF753771), Color(0xFFFDE9D6)],
    [Color(0xFFFF8E31), Color(0xFF3D3B02)],
  ];
  List<Color> setColor() {
    if (rank != null) {
      int r = int.parse(rank!);
      return _rankColor[r ~/ 3];
    } else {
      return _rankColor[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 5, right: 5),
      decoration: BoxDecoration(
          color: setColor()[1], borderRadius: BorderRadius.circular(10)),
      child: ClipRRect(
        // borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Text(
              rank ?? "0",
              style: TextStyle(color: setColor()[0]),
            ),
          ],
        ),
      ),
    );
  }
}
