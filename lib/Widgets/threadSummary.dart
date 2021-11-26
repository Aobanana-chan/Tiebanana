import 'dart:math';

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
    for (var elem in info.firstPostContent!) {
      if (elem.type == "0") //文字内容
      {
        body.add(Text(elem.text!));
      } else if (elem.type == "4") {
        switch (Global.setting.pictureLoadSetting) {
          case 0:
            body.add(Expanded(
                child: FadeIn(
                    child: Hero(
                        tag: elem.originSrc!,
                        child: ExtendedImage.network(
                          elem.bigCdnSrc!,
                        )))));
            break;
          case 1:
            if (int.parse(elem.bsize!.replaceAll(",", "")) < 0x100000) {
              //小于1mb就加载
              body.add(Expanded(
                  child: FadeIn(
                      child: Hero(
                          tag: elem.originSrc!,
                          child: ExtendedImage.network(
                            elem.bigCdnSrc!,
                          )))));
            }
            break;
          case 2:
            body.add(Expanded(
                child: FadeIn(
                    child: Hero(
                        tag: elem.originSrc!,
                        child: ExtendedImage.network(
                          elem.originSrc!,
                        )))));
            break;

          default:
        }
      }
    }
    return body;
  }

  @override
  Widget build(BuildContext context) {
    var icons = info.author!.iconinfo!.map((e) {
      return FadeIn(child: Image.network(e.icon!));
    }).toList();
    var create = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(int.parse(info.createTime!)));
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
        DateTime.fromMillisecondsSinceEpoch(int.parse(info.lastTimeInt!)));
    f = 0;
    late String postText;
    for (var t in [
      lastPost.inDays,
      lastPost.inHours,
      lastPost.inMinutes,
      lastPost.inSeconds
    ]) {
      if (t != 0) {
        postText = "创建于$t${timeGranularity[f]}前";
        break;
      }
      f++;
    }
    if (f == 4) {
      postText = "创建于0秒前";
    }

    return Container(
      padding: EdgeInsets.all(5),
      margin: EdgeInsets.only(top: 5, bottom: 5),
      child: Column(
        children: [
          Row(
            children: [
              Avatar(imgUrl: AUTHOR_AVATAR + info.author!.portrait!),
              Column(
                children: [
                  Row(
                    children: <Widget>[
                          Text("${info.author!.nameShow}"),
                        ] +
                        icons,
                  ),
                  Row(
                    children: [
                      Text(createText),
                      SizedBox(
                        width: 5,
                      ),
                      Text(postText)
                    ],
                  )
                ],
              ),
              Spacer(),
              IconButton(
                  onPressed: () {
                    //TODO:不感兴趣
                  },
                  icon: Icon(Icons.close))
            ],
          ),
          //标题
          Row(
            children: [Text(info.title!)],
          ),
          //正文
          Row(
            children: buildBody(),
          ),
          //底部
          Row(
            children: [
              Text(info.fname!),
              Spacer(),
              Icon(Icons.thumb_up),
              Text(info.agree!.agreeNum!),
              Icon(Icons.thumb_down),
              Text(info.agree!.disagreeNum!),
              Icon(Icons.remove_red_eye),
              Text(info.viewNum!),
              Icon(Icons.speaker_notes),
              Text(info.replyNum!)
            ],
          )
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String imgUrl;
  const Avatar({Key? key, required this.imgUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        margin: EdgeInsets.only(right: 5),
        child: FadeInImage(
            placeholder: NetworkImage("http://placehold.it/200&text=Avatar"),
            image: NetworkImage(imgUrl)),
      ),
    );
  }
}
