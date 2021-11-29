import 'package:animate_do/animate_do.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/Global.dart';

///帖子气泡-小部件
class ThreadSummary extends StatelessWidget {
  final ThreadRecommendSummary info;
  const ThreadSummary({Key? key, required this.info}) : super(key: key);
  List<Widget> buildBody() {
    List<Widget> body = [];
    List<Widget> bodyMedia = [];
    for (var elem in info.firstPostContent ?? []) {
      if (elem.type == "0") //文字内容
      {
        body.add(LimitedBox(
          maxHeight: 260,
          child: Text(
            elem.text!,
            style: TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ));
      } else if (elem.type == "4" || elem.type == "3") {
        //图片
        switch (Global.setting.pictureLoadSetting) {
          case 0:
            bodyMedia.add(Expanded(
                child: Padding(
              padding: EdgeInsets.only(left: 2.5, right: 2.5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: FadeIn(
                    child: Hero(
                        tag: elem.originSrc!,
                        child: ExtendedImage.network(
                          elem.bigCdnSrc!,
                          fit: BoxFit.cover,
                        ))),
              ),
            )));
            break;
          case 1:
            if (int.parse(elem.bsize!.replaceAll(",", "")) < 0x100000) {
              //小于1mb就加载
              bodyMedia.add(Expanded(
                  child: Padding(
                      padding: EdgeInsets.only(left: 2.5, right: 2.5),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: FadeIn(
                              child: Hero(
                                  tag: elem.originSrc!,
                                  child: ExtendedImage.network(
                                    elem.bigCdnSrc!,
                                    fit: BoxFit.cover,
                                  )))))));
            }
            break;
          case 2:
            bodyMedia.add(Expanded(
                child: Padding(
                    padding: EdgeInsets.only(left: 2.5, right: 2.5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: FadeIn(
                          child: Hero(
                              tag: elem.originSrc!,
                              child: ExtendedImage.network(
                                elem.originSrc!,
                                fit: BoxFit.cover,
                              ))),
                    ))));
            break;

          default:
        }
      } else if (elem.type == "5") {
        //视频
      }
    }
    body.add(LimitedBox(
      maxHeight: 160,
      child: Row(
        children: bodyMedia,
      ),
    ));
    return body;
  }

  @override
  Widget build(BuildContext context) {
    var icons = info.author!.iconinfo!.map((e) {
      return FadeIn(
          child: Image.network(
        e.icon!,
        width: 16,
        height: 16,
      ));
    }).toList();
    var create = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(
        int.parse(info.createTime!) * 1000));
    Map timeGranularity = {0: "天", 1: "小时", 2: "分钟", 3: "秒"};
    var f = 0;
    late String createText;
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
    var lastPost = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(
            int.parse(info.lastTimeInt!) * 1000));
    f = 0;
    late String postText;
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

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
          border: Border.all(width: 0.05)),
      padding: EdgeInsets.all(5),
      margin: EdgeInsets.only(top: 3, bottom: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        icons,
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
            child: Wrap(
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
              children: buildBody(),
            ),
          ),
          //底部
          Container(
            padding: EdgeInsets.all(5),
            child: Row(
              children: [
                Expanded(
                    child: Text(
                  "${info.fname}吧",
                  style: TextStyle(color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                )),
                // Spacer(),
                Icon(Icons.remove_red_eye),
                SizedBox(width: 2),
                Text(info.viewNum!),
                SizedBox(width: 5),
                Icon(Icons.thumb_up),
                SizedBox(width: 2),
                Text(info.agree!.agreeNum!),
                SizedBox(width: 5),
                Icon(Icons.thumb_down),
                SizedBox(width: 2),
                Text(info.agree!.disagreeNum!),
                SizedBox(width: 5),
                Icon(Icons.speaker_notes),
                SizedBox(width: 2),
                Text(info.replyNum!)
              ],
            ),
          )
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String imgUrl;
  final double? height;
  final double? width;
  const Avatar({Key? key, required this.imgUrl, this.height, this.width})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: EdgeInsets.only(right: 5),
      child: ClipOval(
        child: FadeInImage(
            placeholder: NetworkImage("http://placehold.it/200&text=Avatar"),
            image: NetworkImage(imgUrl)),
      ),
    );
  }
}
