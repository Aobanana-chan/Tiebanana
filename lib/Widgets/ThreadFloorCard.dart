import 'package:animate_do/animate_do.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/ThreadFirstComment.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/Widgets/VIdeoPlayer.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/HomePage.dart';

///帖子-楼层组件
class ThreadFloorComment extends StatelessWidget {
  final PostList postMain;
  // final SubPostList? subPostList;
  final UserList author;
  final VideoInfo? videoInfo;
  final List<String> allImgs;
  final List<String> allOrgImgs;
  final Map<String, UserList> userList;
  const ThreadFloorComment({
    Key? key,
    required this.author,
    this.videoInfo,
    required this.allImgs,
    required this.allOrgImgs,
    required this.postMain,
    required this.userList,
  }) : super(key: key);

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
          createText = "$t${timeGranularity[f]}前";
          break;
        }
        f++;
      }
      if (f == 4) {
        createText = "0秒前";
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
    List<Widget> bodyMedia = [];
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
    int index = 0;
    int offset = 0;
    if (imgs.length > 0) {
      offset = getImgIndex(imgs[0]);
    }
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
      body.add(VideoPlayer(
        cover: videoInfo!.thumbnailUrl!,
        url: video,
      ));
    }
    return body;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      padding: EdgeInsets.only(left: 8, right: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //作者
              Container(
                padding: EdgeInsets.all(5),
                child: Avatar(
                  imgUrl: AUTHOR_AVATAR + author.portrait!,
                  height: 35,
                  width: 35,
                ),
              ),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(5),
                    child: Row(
                      children: [
                        Column(
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
                                  width: 20,
                                ),
                                //发帖时间
                                Text(
                                  getPostTime(strTime: postMain.time),
                                  style: TextStyle(color: Colors.grey),
                                )
                              ],
                            )
                          ],
                        ),
                        Spacer(),
                        AgreeAndDisagreeBar(
                          agreeNum: int.parse(postMain.agree!.agreeNum!),
                          disagreeNum: int.parse(postMain.agree!.disagreeNum!),
                          agreeType: int.parse(postMain.agree!.agreeType!),
                        )
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //正文
                      Container(
                        padding: EdgeInsets.all(5),
                        child: Wrap(
                          children: buildBody(context),
                        ),
                      ),
                      Visibility(
                          visible: postMain.subPostList != null,
                          child: Row(
                            children: [
                              Expanded(
                                  child: Container(
                                child: InnerFloor(
                                  subPostList: postMain.subPostList ?? [],
                                  userlist: userList,
                                ),
                              ))
                            ],
                          )),
                      Divider()
                    ],
                  )
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }
}

///楼中楼
class InnerFloor extends StatelessWidget {
  final Map<String, UserList> userlist;
  final List<SubPostList> subPostList;
  const InnerFloor(
      {Key? key, required this.subPostList, required this.userlist})
      : super(key: key);

  List<Widget> buildSubPost() {
    List<Widget> subposts = <Widget>[];
    for (var i = 0; i < subPostList.length; i++) {
      if (i > 5) break;
      var post = subPostList[i];
      if (post.isVoice == "1") {
        print("音频回复");
      }
      subposts.add(
          InnerPost(author: userlist[post.authorId!]!, posts: post.content!));
    }
    if (subPostList.length > 5) {
      subposts.add(Container(
        padding: EdgeInsets.all(5),
        child: Text(
          "查看剩余${subPostList.length - 5}条回复",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
      ));
    }
    return subposts;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Color(0xFFF0F1F2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: buildSubPost(),
      ),
    );
  }
}

class InnerPost extends StatelessWidget {
  final Author author;
  final List<Content> posts;
  const InnerPost({Key? key, required this.author, required this.posts})
      : super(key: key);
  List<Widget> buildContent() {
    List<Widget> w = [];
    for (Content content in posts) {
      //用户
      if ((content.uid != null || content.uid != null) && content.type == "0") {
        w.add(Text(
          "${content.text}",
          style: TextStyle(color: Colors.blue),
        ));
      } else if (content.type == "0") {
        w.add(Text(
          "${content.text}",
          softWrap: true,
          maxLines: 100,
        ));
      } else if (content.type == "2") {
        //TODO:表情包
      }
    }
    return w;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3),
      child: Wrap(
        children: <Widget>[
              Text(
                "${author.nameShow}: ",
                style: TextStyle(color: Colors.blue),
              ),
            ] +
            buildContent(),
      ),
    );
  }
}
