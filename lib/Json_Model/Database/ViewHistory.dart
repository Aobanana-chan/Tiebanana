import 'package:objectbox/objectbox.dart';

///历史记录数据库实体

@Entity()
class ViewHistoryDatabase {
  int id = 0;

  @Unique(onConflict: ConflictStrategy.replace)
  late String tid;

  @Property(type: PropertyType.date)
  late DateTime latestViewTime;

  late String title;

  late String forumName;

  ViewHistoryDatabase({
    required this.tid,
    required this.forumName,
    required this.latestViewTime,
    required this.title,
  });
}
