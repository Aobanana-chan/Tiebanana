import 'package:tiebanana/Json_Model/Database/ViewHistory.dart';

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

  ViewHistoryPageModel({
    required this.forumName,
    required this.latestViewTime,
    required this.id,
    required this.tid,
    required this.title,
  });

  ViewHistoryPageModel.fromViewHistoryDatabase(ViewHistoryDatabase data) {
    forumName = data.forumName;
    id = data.id;
    latestViewTime = data.latestViewTime;
    tid = data.tid;
    title = data.title;
  }
}
