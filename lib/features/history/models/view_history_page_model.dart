import 'package:tiebanana/features/history/data/view_history.dart';

class ViewHistoryPageModel implements ViewHistoryDatabase {
  @override
  late String forumName;

  @override
  late int id;

  @override
  late DateTime latestViewTime;

  @override
  late String tid;

  @override
  late String title;

  @override
  String uid = '';

  /// 是否在首页隐藏（浏览历史页始终显示）。
  @override
  bool hidden = false;

  ViewHistoryPageModel({
    required this.forumName,
    required this.latestViewTime,
    required this.id,
    required this.tid,
    required this.title,
    this.hidden = false,
    this.uid = '',
  });

  ViewHistoryPageModel.fromViewHistoryDatabase(ViewHistoryDatabase data) {
    forumName = data.forumName;
    id = data.id;
    latestViewTime = data.latestViewTime;
    tid = data.tid;
    title = data.title;
    hidden = data.hidden;
    uid = data.uid;
  }
}
