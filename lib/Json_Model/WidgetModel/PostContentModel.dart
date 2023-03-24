import 'package:flutter/foundation.dart';

import '../json.dart';
import 'ThreadPageModel.dart';

///Content Model

class PostListWidgetModel {
  late String id;
  late int floor;
  late String createTime;
  late String agreeNum;
  late String disagreeNum;
  late String agreeType;
  late String hasAgree;
  late String? lbsInfo;
  late String title;
  late List<PostContentBaseWidgetModel> content;
  late List<SubPost> subPostList;
  late String subPostNumber;

  PostListWidgetModel(
      {required this.agreeNum,
      required this.agreeType,
      required this.content,
      required this.createTime,
      required this.disagreeNum,
      required this.floor,
      required this.hasAgree,
      required this.id,
      required this.lbsInfo,
      required this.subPostList,
      required this.subPostNumber,
      required this.title});
  PostListWidgetModel.fromPostList(PostList post) {
    id = post.id!;
    floor = int.parse(post.floor!);
    createTime = post.time!;
    agreeNum = post.agree!.agreeNum!;
    disagreeNum = post.agree!.disagreeNum!;
    agreeType = post.agree!.agreeType!;
    hasAgree = post.agree!.hasAgree!;
    lbsInfo = post.lbsInfo?.name ?? "";
    title = post.time!;
    content = [];
    for (var element in post.content!) {
      content.add(createContentModel(element));
    }
    subPostList = [];
    for (SubPostList element in post.subPostList ?? []) {
      subPostList.add(SubPost.formSubPostList(element));
    }
    subPostNumber = post.subPostNumber!;
  }

  PostListWidgetModel.fromInnerFloorPost(InnerFloorPost post) {
    id = post.id!;
    floor = int.parse(post.floor!);
    createTime = post.time!;
    agreeNum = post.agree!.agreeNum!;
    disagreeNum = post.agree!.disagreeNum!;
    agreeType = post.agree!.agreeType!;
    hasAgree = post.agree!.hasAgree!;
    lbsInfo = "";
    title = post.time!;
    content = [];
    for (var element in post.content!) {
      content.add(createContentModel(element));
    }
    subPostList = [];
  }

  PostListWidgetModel.fromSubpostList(SubpostList post) {
    id = post.id!;
    floor = int.parse(post.floor!);
    createTime = post.time!;
    agreeNum = post.agree!.agreeNum!;
    disagreeNum = post.agree!.disagreeNum!;
    agreeType = post.agree!.agreeType!;
    hasAgree = post.agree!.hasAgree!;
    lbsInfo = "";
    title = post.time!;
    content = [];
    for (var element in post.content!) {
      content.add(createContentModel(element));
    }
    subPostList = [];
  }
}

class PostContentBaseWidgetModel {
  String type;
  PostContentBaseWidgetModel({required this.type});
}

class TextContentWidgetModel extends PostContentBaseWidgetModel {
  String text;
  String? uid;
  TextContentWidgetModel({required this.text, this.uid}) : super(type: "0");
}

class ImageContentWidgetModel extends PostContentBaseWidgetModel {
  String? bigCdnSrc;
  String? originSrc;
  String? bsize;
  ImageContentWidgetModel({this.bigCdnSrc, this.bsize, this.originSrc})
      : super(type: "3");
}

class AtContentWidgetModel extends PostContentBaseWidgetModel {
  String text;
  String uid;
  AtContentWidgetModel({required this.text, required this.uid})
      : super(type: "4");
}

class EmojiContentWidgetModel extends PostContentBaseWidgetModel {
  String text;
  String c;
  EmojiContentWidgetModel({required this.c, required this.text})
      : super(type: "2");
}

class VideoContentWidgetModel extends PostContentBaseWidgetModel {
  String? link;
  String? cover;
  VideoContentWidgetModel({this.link, this.cover}) : super(type: "5");
}

class LinkContentWidgetModel extends PostContentBaseWidgetModel {
  String link;
  String text;
  LinkContentWidgetModel({required this.link, required this.text})
      : super(type: "1");
}

class PhoneNumberContentWidgetModel extends PostContentBaseWidgetModel {
  String text;
  PhoneNumberContentWidgetModel({required this.text}) : super(type: "9");
}

class VoiceContentWidgetModel extends PostContentBaseWidgetModel {
  String md5;
  int? durantion;
  VoiceContentWidgetModel({required this.md5, required this.durantion})
      : super(type: "10");
}

///吧跳转快速链接
class ForumQuickLinkContentWidgetModel extends PostContentBaseWidgetModel {
  String text;
  ForumQuickLinkContentWidgetModel({required this.text}) : super(type: "27");
}

class UnknownontentWidgetModel extends PostContentBaseWidgetModel {
  String? text;
  UnknownontentWidgetModel({required this.text}) : super(type: "-1");
}

PostContentBaseWidgetModel createContentModel(Content content) {
  switch (content.type) {
    case "0":
      return TextContentWidgetModel(text: content.text!, uid: content.uid);
    case "1":
    case "18":
      return LinkContentWidgetModel(link: content.link!, text: content.text!);
    case "2":
      return EmojiContentWidgetModel(c: content.c!, text: content.text!);
    case "3":
      return ImageContentWidgetModel(
          bigCdnSrc: content.bigCdnSrc,
          bsize: content.bsize,
          originSrc: content.originSrc);
    case "4":
      if (content.originSrc != null) {
        return ImageContentWidgetModel(
            bigCdnSrc: content.bigCdnSrc,
            originSrc: content.originSrc,
            bsize: content.bsize);
      }
      return AtContentWidgetModel(text: content.text!, uid: content.uid!);
    case "5":
      return VideoContentWidgetModel(link: content.link, cover: content.src);

    case "9":
      return PhoneNumberContentWidgetModel(text: content.text!);
    case "10":
      return VoiceContentWidgetModel(
          md5: content.voiceMd5!,
          durantion: int.tryParse(content.duringTime ?? "0"));
    case "27":
      return ForumQuickLinkContentWidgetModel(text: content.text!);
    default:
      if (kDebugMode) {
        throw Exception("未知Type");
      } else {
        return UnknownontentWidgetModel(text: content.text);
      }
  }
}
