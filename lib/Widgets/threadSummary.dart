import 'package:animate_do/animate_do.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/VIdeoPlayer.dart';
import 'package:tiebanana/Widgets/ImgExplorer.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/routes.dart';
import 'package:uuid/uuid.dart';

///帖子气泡-小部件
class ThreadSummary extends StatelessWidget {
  final ThreadRecommendSummary info;
  const ThreadSummary({Key? key, required this.info}) : super(key: key);
  List<Widget> buildBody(BuildContext context) {
    List<Widget> body = [];
    List<Widget> bodyMedia = [];
    List<String> imgs = [];
    List<String>? imgsOriginSrc = [];
    List<String> videos = [];
    String text = "";
    //统计与格式化
    for (FirstPostContent elem in info.firstPostContent ?? []) {
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
        if (info.videoInfo?.videoUrl == null) {
          //TODO:外链视频
        } else {
          videos.add(info.videoInfo!.videoUrl!);
        }
      }
    }

    //生成widget
    //文字内容
    body.add(
      Text(
        text,
        style: TextStyle(fontSize: 16),
        overflow: TextOverflow.ellipsis,
        softWrap: true,
        maxLines: 12,
      ),
    );

    //图片
    int index = 0;
    Widget imgLeft = Container(
      height: 0,
      width: 0,
    );
    for (var img in imgs) {
      ExtendedPageController controller =
          ExtendedPageController(initialPage: index);
      //最多一次显示三张图片
      if (index >= 3) {
        imgLeft = Container(
          padding: EdgeInsets.all(5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(color: Color(0x8E8E8E8E)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_size_select_actual_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  Text(
                    "${imgs.length}",
                    style: TextStyle(color: Colors.white),
                  )
                ],
              ),
            ),
          ),
        );
        break;
      }
      // String heroTagSalt = Uuid().v4();
      bodyMedia.add(Expanded(
              child: Thumbnail(
        imgs: imgs,
        controller: controller,
        img: img,
        imgsOriginSrc: imgsOriginSrc,
      ))
          // Expanded(child: Builder(
          //   builder: (context) {
          //     String salt = heroTagSalt;
          //     return GestureDetector(
          //         onTap: () {
          //           Navigator.push(context, MaterialPageRoute(builder: (builder) {
          //             return ZoomedImgExplorer(
          //               imgUrls: imgs,
          //               highQualityUrls: imgsOriginSrc,
          //               pageController: controller,
          //               heroTagSalt: salt,
          //             );
          //           }));
          //         },
          //         child: Padding(
          //           padding: EdgeInsets.only(left: 2.5, right: 2.5),
          //           child: ClipRRect(
          //             borderRadius: BorderRadius.circular(5),
          //             child: FadeIn(
          //                 child: Hero(
          //               tag: img + salt,
          //               child: LayoutBuilder(
          //                 builder:
          //                     (BuildContext context, BoxConstraints constraints) {
          //                   return Container(
          //                     height: constraints.maxHeight,
          //                     width: constraints.maxWidth,
          //                     child: ExtendedImage.network(
          //                       img,
          //                       fit: BoxFit.cover,
          //                       cache: true,
          //                     ),
          //                   );
          //                 },
          //               ),
          //             )),
          //           ),
          //         ));
          //   },
          // )),
          );
      index++;
    }
    //视频
    for (var video in videos) {
      bodyMedia.add(Expanded(
          child: VideoPlayer(
        cover: info.videoInfo!.thumbnailUrl!,
        url: video,
      )));
    }

    // for (FirstPostContent elem in info.firstPostContent ?? []) {
    //   if (elem.type == "0") //文字内容
    //   {
    //     body.add(LimitedBox(
    //       maxHeight: 260,
    //       child: Text(
    //         elem.text!,
    //         style: TextStyle(fontSize: 16),
    //         overflow: TextOverflow.ellipsis,
    //       ),
    //     ));
    //   } else if (elem.type == "4" || elem.type == "3") {
    //     //图片
    //     switch (Global.setting.pictureLoadSetting) {
    //       case 0:
    //         bodyMedia.add(Expanded(
    //             child: Padding(
    //           padding: EdgeInsets.only(left: 2.5, right: 2.5),
    //           child: ClipRRect(
    //             borderRadius: BorderRadius.circular(5),
    //             child: FadeIn(
    //                 child: Hero(
    //                     tag: elem.originSrc!,
    //                     child: ExtendedImage.network(
    //                       elem.bigCdnSrc!,
    //                       fit: BoxFit.cover,
    //                       cache: true,
    //                     ))),
    //           ),
    //         )));
    //         break;
    //       case 1:
    //         if (int.parse(elem.bsize!.replaceAll(",", "")) < 0x100000) {
    //           //小于1mb就加载
    //           bodyMedia.add(GestureDetector(
    //             onTap: () {},
    //             child: Expanded(
    //                 child: Padding(
    //                     padding: EdgeInsets.only(left: 2.5, right: 2.5),
    //                     child: ClipRRect(
    //                         borderRadius: BorderRadius.circular(5),
    //                         child: FadeIn(
    //                             child: Hero(
    //                                 tag: elem.originSrc!,
    //                                 child: ExtendedImage.network(
    //                                   elem.bigCdnSrc!,
    //                                   fit: BoxFit.cover,
    //                                   cache: true,
    //                                 )))))),
    //           ));
    //         }
    //         break;
    //       case 2:
    //         bodyMedia.add(Expanded(
    //             child: Padding(
    //                 padding: EdgeInsets.only(left: 2.5, right: 2.5),
    //                 child: ClipRRect(
    //                   borderRadius: BorderRadius.circular(5),
    //                   child: FadeIn(
    //                       child: Hero(
    //                           tag: elem.originSrc!,
    //                           child: ExtendedImage.network(
    //                             elem.originSrc!,
    //                             fit: BoxFit.cover,
    //                             cache: true,
    //                           ))),
    //                 ))));
    //         break;

    //       default:
    //     }
    //   } else if (elem.type == "5") {
    //     //视频
    //     print("find vedio");
    //     print(elem);
    //   }
    // }

    body.add(LimitedBox(
        maxHeight: 160,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: bodyMedia,
                ),
              ] +
              [imgLeft],
        )));
    return body;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? icons = info.author?.iconinfo?.map((e) {
      return FadeIn(
          child: ExtendedImage.network(
        e.icon!,
        width: 16,
        height: 16,
        cache: true,
      ));
    }).toList();
    var create = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(
        int.parse(info.createTime!) * 1000));
    Map timeGranularity = {0: "天", 1: "小时", 2: "分钟", 3: "秒"};
    var f = 0;
    late String createText;
    if (create.inDays > 30) {
      var date = DateTime.fromMillisecondsSinceEpoch(
          int.parse(info.createTime!) * 1000);
      createText = "${date.year}年${date.month}月${date.day}日";
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

    var lastPost = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(
            int.parse(info.lastTimeInt!) * 1000));
    f = 0;
    late String postText;
    if (lastPost.inDays > 30) {
      var date = DateTime.fromMillisecondsSinceEpoch(
          int.parse(info.lastTimeInt!) * 1000);
      postText = "${date.year}年${date.month}月${date.day}日";
    } else {
      for (var t in [
        lastPost.inDays,
        lastPost.inHours,
        lastPost.inMinutes,
        lastPost.inSeconds
      ]) {
        if (t != 0) {
          postText = "最近回复$t${timeGranularity[f]}前";
          break;
        }
        f++;
      }
      if (f == 4) {
        postText = "最近回复0秒前";
      }
    }

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
          border: Border.all(width: 0.05)),
      // padding: EdgeInsets.all(5),
      margin: EdgeInsets.only(top: 3, bottom: 3),
      child: MaterialButton(
        onPressed: () async {
          Navigator.pushNamed(context, PageRouter.threadPage,
              arguments: info.tid!);
          // await Global.tiebaAPI.getThreadPage(info.tid!);
        },
        padding: EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //作者
            Row(
              children: [
                Avatar(
                  imgUrl: AUTHOR_AVATAR + info.author!.portrait!,
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
                              child: Text("${info.author!.nameShow}"),
                            ),
                          ] +
                          (icons ?? <Widget>[]),
                    ),
                    Row(
                      children: [
                        Text(
                          createText,
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Text(
                          postText,
                          style: TextStyle(color: Colors.grey),
                        )
                      ],
                    )
                  ],
                ),
                Spacer(),
                Container(
                  child: IconButton(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onPressed: () {
                        //TODO:不感兴趣
                      },
                      icon: Icon(
                        Icons.close,
                        size: 16,
                      )),
                )
              ],
            ),
            //标题
            Container(
              padding: EdgeInsets.all(5),
              child: Column(
                children: [
                  Text(
                    info.title!,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  )
                ],
              ),
            ),
            //正文
            Container(
              padding: EdgeInsets.all(5),
              child: Wrap(
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: buildBody(context),
              ),
            ),
            //底部
            Container(
              padding: EdgeInsets.all(5),
              child: Row(
                children: [
                  Expanded(
                      child: Visibility(
                    visible: info.fname != null && info.fname != "",
                    child: Text(
                      "${info.fname}吧",
                      style: TextStyle(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                  // Spacer(),
                  Icon(Icons.remove_red_eye),
                  SizedBox(width: 2),
                  Text(info.viewNum ?? "0"),
                  SizedBox(width: 5),
                  Icon(Icons.thumb_up),
                  SizedBox(width: 2),
                  Text(info.agree?.agreeNum ?? "0"),
                  SizedBox(width: 5),
                  Icon(Icons.thumb_down),
                  SizedBox(width: 2),
                  Text(info.agree?.disagreeNum ?? "0"),
                  SizedBox(width: 5),
                  Icon(Icons.speaker_notes),
                  SizedBox(width: 2),
                  Text(info.replyNum!)
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class Avatar extends StatefulWidget {
  final String imgUrl;
  final double? height;
  final double? width;
  final void Function()? onTap;
  const Avatar(
      {Key? key, required this.imgUrl, this.height, this.width, this.onTap})
      : super(key: key);

  @override
  _AvatarState createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  String heroTagSalt = Uuid().v4();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ??
          () {
            Navigator.push(context, MaterialPageRoute(builder: (builder) {
              return ImgExplorer(
                imgUrl: widget.imgUrl,
                heroTagSalt: heroTagSalt,
              );
            }));
          },
      child: Container(
        height: widget.height,
        width: widget.width,
        margin: EdgeInsets.only(right: 5),
        child: ClipOval(
          child: Hero(
            tag: widget.imgUrl + heroTagSalt,
            child: ExtendedImage.network(
              widget.imgUrl,
              cache: true,
            ),
            // child: FadeInImage(
            //     placeholder:
            //         NetworkImage("http://placehold.it/200&text=Avatar"),
            //     image: NetworkImage(imgUrl)),
          ),
        ),
      ),
    );
  }
}

class Thumbnail extends StatefulWidget {
  final List<String> imgs;
  final List<String?>? imgsOriginSrc;
  final ExtendedPageController controller;
  final String img;
  final BoxFit fit;
  Thumbnail(
      {Key? key,
      required this.imgs,
      this.imgsOriginSrc,
      required this.controller,
      required this.img,
      this.fit = BoxFit.cover})
      : super(key: key);

  @override
  _ThumbnailState createState() => _ThumbnailState();
}

class _ThumbnailState extends State<Thumbnail> {
  String heroTagSalt = Uuid().v4();
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (builder) {
                return ZoomedImgExplorer(
                  imgUrls: widget.imgs,
                  highQualityUrls: widget.imgsOriginSrc,
                  pageController: widget.controller,
                  heroTagSalt: heroTagSalt,
                );
              }));
            },
            child: Padding(
              padding: EdgeInsets.only(left: 2.5, right: 2.5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: FadeIn(
                    child: Hero(
                  tag: widget.img + heroTagSalt,
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return Container(
                        constraints: constraints,
                        // height: constraints.maxHeight,
                        // width: constraints.maxWidth,
                        child: ExtendedImage.network(
                          widget.img,
                          fit: widget.fit,
                          cache: true,
                        ),
                      );
                    },
                  ),
                )),
              ),
            ));
      },
    );
  }
}
