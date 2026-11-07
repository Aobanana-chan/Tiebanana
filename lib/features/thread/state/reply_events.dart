import 'package:flutter/foundation.dart';

/// 广播已成功的回帖，页面收到通知后重新请求楼层数据。
class ReplyEvents extends ChangeNotifier {
  String? threadId;
  String? floorId;

  void sent(String tid, {String? pid}) {
    threadId = tid;
    floorId = pid;
    notifyListeners();
  }
}

final ReplyEvents replyEvents = ReplyEvents();
