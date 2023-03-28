import 'dart:collection';

import 'package:tiebanana/Json_Model/WidgetModel/PostContentModel.dart';
import 'package:tiebanana/Json_Model/WidgetModel/ThreadCommentModel.dart';

import '../json.dart';
import 'commonModel.dart' as common;

///贴页面数据Model

class ThreadPageModel implements common.Forum {
  ///帖子的tid
  String tid;

  ///吧id
  @override
  String fid;

  ///吧名
  @override
  String forumName;

  ///吧头像
  @override
  String avatar;

  ///使用PID进入帖子
  String? initPid;

  ///页管理的Post，正数页面表示正常页面，负数页面表示只看楼主的页面
  SplayTreeMap<int, List<ThreadPagePost>> postPage = SplayTreeMap();

  void merge(int page, ThreadPagePost post, bool lz) {
    int floor = int.parse(post.floor!);
    if (postPage[page]?[floor] == null) {
      postPage[page]?[floor] = post;
    } else {
      postPage[page]?[floor].merge(post.subPostList);
    }
  }

  ///正常页面List
  List<ThreadPagePost> get postList {
    var l = <ThreadPagePost>[];
    for (var i in postPage.keys) {
      if (i > 0) {
        l.addAll(postPage[i]!);
      }
    }

    return l;
  }

  ///只看楼主页面List
  List<ThreadPagePost> get lzPostList {
    var l = <ThreadPagePost>[];
    for (var i in postPage.keys) {
      if (i < 0) {
        l.addAll(postPage[i]!);
      } else {
        break;
      }
    }

    return l;
  }

  ///页面的用户
  Map<String, AuthorWidgetModel> userListSet = {};

  ///两端的页码
  int? topPn;
  int? bottomPn;

  bool hasMore;
  bool hasPrev;

  ///标题
  String title;

  List<String> imgs = []; // 贴中所有图片列表
  List<String> imgsOrgSrc = []; // 贴中所有高清图片列表

  VedioInfoWidgetModel? videoInfo;

  ///只看楼主
  bool onlyLz;

  ///贴是否收藏
  bool isStored;

  ThreadPageModel(
      {required this.title,
      this.initPid,
      this.topPn,
      this.bottomPn,
      required this.videoInfo,
      required this.hasMore,
      required this.hasPrev,
      required this.tid,
      required this.fid,
      required this.forumName,
      required this.avatar,
      this.onlyLz = false,
      required this.isStored})
      : assert(!(initPid == null && (topPn == null || bottomPn == null)));
}

class ThreadPagePost implements common.Post {
  ///pid
  late String id;

  late String title;

  ///是否点赞
  @override
  String? hasAgree;

  ///楼层数
  String? floor;

  String? lbsInfo;

  @override
  String? nameShow;

  @override
  String? username;

  @override
  late String portrait;

  @override
  late String uid;

  @override
  String get name {
    if (nameShow != null || nameShow != "") {
      return nameShow!;
    } else {
      return username!;
    }
  }

  @override
  String? agreeNum;

  @override
  late List<PostContentBaseWidgetModel> content;

  @override
  late String createTime;

  @override
  String? disagreeNum;

  @override
  String? agreeType;

  @override
  late bool isFirstFloor;

  @override
  bool isInnerFloor = false;

  List<SubPost> subPostList = [];

  void merge(List<SubPost> sub) {
    for (var p in sub) {
      if (!subPostList.contains(p)) {
        subPostList.add(p);
      }
    }
    subPostList.sort((l, r) => int.parse(createTime) - int.parse(r.createTime));
  }

  ///楼中楼数
  late String subPostNumber;

  ThreadPagePost({
    required this.title,
    required this.nameShow,
    required this.portrait,
    required this.uid,
    required this.username,
    required this.agreeNum,
    required this.disagreeNum,
    required this.content,
    required this.createTime,
    required this.isFirstFloor,
    required this.isInnerFloor,
    required this.floor,
    required this.lbsInfo,
    required this.id,
    required this.hasAgree,
    required this.agreeType,
    required this.subPostList,
    required this.subPostNumber,
  });

  ThreadPagePost.fromPostList(PostList postList) {
    title = postList.title!;
    uid = postList.authorId!;
    id = postList.id!;
    content = [];
    for (Content element in postList.content ?? []) {
      content.add(createContentModel(element));
    }
    isFirstFloor = postList.floor == "1";
    createTime = postList.time!;
    lbsInfo = postList.lbsInfo?.name ?? "";
    hasAgree = postList.agree?.hasAgree;
    agreeNum = postList.agree?.agreeNum;
    disagreeNum = postList.agree?.disagreeNum;
    agreeType = postList.agree?.agreeType;
    for (SubPostList element in postList.subPostList ?? []) {
      subPostList.add(SubPost.formSubPostList(element));
    }
    subPostNumber = postList.subPostNumber!;
    floor = postList.floor;
  }
}

//楼中楼
class SubPost implements common.Post {
  SubPost({
    required this.nameShow,
    required this.portrait,
    required this.uid,
    required this.username,
    required this.agreeNum,
    required this.disagreeNum,
    required this.content,
    required this.createTime,
    required this.isFirstFloor,
    required this.isInnerFloor,
    required this.hasAgree,
    required this.agreeType,
    required this.isVoice,
    required this.id,
    required this.title,
  });

  ///是否为音频Post
  late bool isVoice;

  ///spid
  late String id;

  late String title;

  @override
  String? agreeNum;

  @override
  String? agreeType;

  @override
  late List<PostContentBaseWidgetModel> content;

  @override
  late String createTime;

  @override
  String? disagreeNum;

  @override
  String? hasAgree;

  @override
  bool isFirstFloor = false;

  @override
  late bool isInnerFloor;

  @override
  String? nameShow;

  @override
  late String portrait;

  @override
  late String uid;

  @override
  String? username;

  @override
  String get name {
    if (nameShow != null || nameShow != "") {
      return nameShow!;
    } else {
      return username!;
    }
  }

  SubPost.formSubPostList(SubPostList subPostList) {
    isVoice = subPostList.isVoice == "1";
    uid = subPostList.authorId!;
    id = subPostList.id!;
    title = subPostList.title!;
    content = [];
    for (var element in subPostList.content!) {
      content.add(createContentModel(element));
    }
    createTime = subPostList.time!;
  }

  @override
  bool operator ==(Object other) {
    if (other is SubPost) {
      return id == other.id;
    } else {
      return false;
    }
  }
}

class ForumData implements common.Forum {
  ForumData({required this.avatar, required this.fid, required this.forumName});
  @override
  late String avatar;

  @override
  late String fid;

  @override
  late String forumName;

  ForumData.fromForm(Forum forum) {
    avatar = forum.avatar!;
    fid = forum.id!;
    forumName = forum.name!;
  }
}

class ThreadData {
  ThreadData({required this.agreeType});
  String? agreeType;

  ThreadData.fromThread(Thread thread) {
    agreeType = thread.agree?.agreeType;
  }
}
