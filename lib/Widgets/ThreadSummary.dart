import 'package:animate_do/animate_do.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/ImgExplorer.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/API/TiebaParser.dart';
import 'package:tiebanana/routes/routes.dart';
import 'package:uuid/uuid.dart';

import '../Json_Model/WidgetModel/PostContentModel.dart';
import '../Json_Model/WidgetModel/ThreadCommentModel.dart';

///帖子气泡(主页推荐贴)-小部件
class ThreadSummary extends StatelessWidget {
  // final ThreadRecommendSummary info;
  final List<PostContentBaseWidgetModel> firstPostContent; //一楼Content
  final AuthorWidgetModel author;
  final String createTime;
  final String latestTime; //最近回复时间
  final String tid;
  final String fname;
  final String viewNum;
  final String title;
  final String agreeNum;
  final String disagreeNum;
  final String replyNum;
  const ThreadSummary(
      {Key? key,
      required this.firstPostContent,
      required this.author,
      required this.createTime,
      required this.latestTime,
      required this.tid,
      required this.fname,
      required this.viewNum,
      required this.title,
      required this.agreeNum,
      required this.disagreeNum,
      required this.replyNum})
      : super(key: key);

  List<String> _imgCollect() {
    List<String> l = [];
    for (PostContentBaseWidgetModel content in firstPostContent) {
      if (content is ImageContentWidgetModel) {
        l.add(content.bigCdnSrc!);
      }
    }
    return l;
  }

  List<String> _originImgCollect() {
    List<String> l = [];
    for (PostContentBaseWidgetModel content in firstPostContent) {
      if (content is ImageContentWidgetModel) {
        l.add(content.originSrc!);
      }
    }
    return l;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? icons = TiebaParser.processIcon(author);
    var create = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(int.parse(createTime) * 1000));
    Map timeGranularity = {0: "天", 1: "小时", 2: "分钟", 3: "秒"};
    var f = 0;
    late String createText;
    if (create.inDays > 30) {
      var date =
          DateTime.fromMillisecondsSinceEpoch(int.parse(createTime) * 1000);
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
        DateTime.fromMillisecondsSinceEpoch(int.parse(latestTime) * 1000));
    f = 0;
    late String postText;
    if (lastPost.inDays > 30) {
      var date =
          DateTime.fromMillisecondsSinceEpoch(int.parse(latestTime) * 1000);
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
          // color: Colors.white,
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Theme.of(context).colorScheme.background,
          border: Border.all(width: 0.05)),
      // padding: EdgeInsets.all(5),
      margin: const EdgeInsets.only(top: 3, bottom: 3),
      child: MaterialButton(
        onPressed: () async {
          Navigator.pushNamed(context, PageRouter.threadPage,
              arguments: ThreadPageRouterData(kz: tid, pid: null));
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
                        arguments: author.id);
                  },
                  imgUrl: AUTHOR_AVATAR + author.portrait,
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
                              child: Text(author.name),
                            ),
                          ] +
                          (icons ?? <Widget>[]),
                    ),
                    Row(
                      children: [
                        Text(
                          createText,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Text(
                          postText,
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
            Container(
              padding: const EdgeInsets.all(5),
              child: Column(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize:
                            Provider.of<APPSettingProvider>(context).fontSize,
                        fontWeight: FontWeight.w600),
                  )
                ],
              ),
            ),
            //正文
            Container(
              padding: const EdgeInsets.all(5),
              child: Wrap(
                // crossAxisAlignment: CrossAxisAlignment.start,
                // children: buildBody(context),
                children: TiebaParser.parseContent(context, firstPostContent,
                    _imgCollect(), _originImgCollect(),
                    mediaLimit: 3, isRecommend: true),
              ),
            ),
            //底部
            Container(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Expanded(
                      child: Visibility(
                    visible: fname != "",
                    child: Text(
                      "$fname吧",
                      style: TextStyle(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                  // Spacer(),
                  const Icon(Icons.remove_red_eye),
                  const SizedBox(width: 2),
                  Text(viewNum),
                  const SizedBox(width: 5),
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
                  Text(replyNum)
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
  String heroTagSalt = const Uuid().v4();
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
        margin: const EdgeInsets.only(right: 5),
        child: ClipOval(
          child: Hero(
            tag: widget.imgUrl + heroTagSalt,
            child: ExtendedImage.network(
              widget.imgUrl,
              cache: true,
            ),
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
  const Thumbnail(
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
  String heroTagSalt = const Uuid().v4();
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
              padding: const EdgeInsets.only(left: 2.5, right: 2.5),
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
