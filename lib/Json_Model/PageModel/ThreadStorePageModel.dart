import 'package:tiebanana/Json_Model/PageModel/commonModel.dart';
import 'package:tiebanana/Json_Model/json.dart';

///收藏的贴
class StoredThread implements User {
  @override
  String portrait;

  @override
  String uid;
  bool isFollowed;
  bool isDeleted;
  String? postNo;
  String? postNoMsg;
  String title;
  String? nameShow;
  String? username;
  List<Media>? media;
  String? count;

  StoredThread(
      {required this.title,
      required this.isDeleted,
      required this.isFollowed,
      required this.portrait,
      required this.postNo,
      required this.postNoMsg,
      required this.uid,
      required this.username,
      required this.nameShow,
      required this.media,
      required this.count});

  @override
  String get name {
    if (nameShow != null || nameShow != "") {
      return nameShow!;
    } else {
      return username!;
    }
  }

  String? get getImage {
    for (Media i in media ?? []) {
      if (i.type == "pic") {
        return i.bigPic;
      }
      //视频
      else if (i.type == "flash") {
        return i.vpic;
      }
    }
    return null;
  }

  ///是否有新楼层更新
  bool get haveNew => count != "0";

  ///底部消息
  String get bottomMsg {
    if (isDeleted) {
      return "该贴子已被删除";
    } else {
      return postNoMsg ?? "";
    }
  }

  ///底部消息可见性
  bool get bottomVisiable {
    if (haveNew) {
      return true;
    }
    if (isDeleted) {
      return true;
    }
    return false;
  }
}
