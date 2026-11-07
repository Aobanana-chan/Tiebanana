
import 'package:tiebanana/Json_Model/json.dart';

import 'commonModel.dart';

///消息页面Model
class MessagePageModel implements User {
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

  late DateTime time;
  late String content;
  late String quoteContent;
  late String fname;
  late String title;
  MessagePageModel(this.content, this.fname, this.nameShow, this.portrait,
      this.quoteContent, this.time, this.uid, this.username);
  MessagePageModel.fromReplyMe(ReplyMe replyMe) {
    portrait = replyMe.replyer?.portrait ?? "";
    nameShow = replyMe.replyer?.nameShow;
    username = replyMe.replyer?.name;
    time = DateTime.fromMillisecondsSinceEpoch(int.parse(replyMe.time!) * 1000);
    content = replyMe.content!;
    fname = replyMe.fname!;
    quoteContent = replyMe.quoteContent!;
    title = replyMe.title ?? "";
  }
  MessagePageModel.fromAtMe(AtMe atMe) {
    portrait = atMe.replyer?.portrait ?? "";
    nameShow = atMe.replyer?.nameShow;
    username = atMe.replyer?.name;
    time = DateTime.fromMillisecondsSinceEpoch(int.parse(atMe.time!) * 1000);
    content = atMe.content!;
    fname = atMe.fname!;
    quoteContent = atMe.quoteContent!;
    title = atMe.title ?? "";
  }
}
