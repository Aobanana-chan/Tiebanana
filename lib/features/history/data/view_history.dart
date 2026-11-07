import 'package:objectbox/objectbox.dart';

///历史记录数据库实体

@Entity()
class ViewHistoryDatabase {
  int id = 0;

  late String tid;

  /// 所属账号。空串表示旧版无法确定归属的记录。
  @Index()
  String uid;

  @Property(type: PropertyType.date)
  late DateTime latestViewTime;

  late String title;

  late String forumName;

  /// 是否在首页隐藏。隐藏只影响首页「最近浏览」，浏览历史页仍会显示，
  /// 并可在那里取消隐藏。默认 false，老数据迁移后即为 false。
  bool hidden = false;

  ViewHistoryDatabase({
    required this.tid,
    required this.forumName,
    required this.latestViewTime,
    required this.title,
    this.hidden = false,
    this.uid = '',
  });
}
