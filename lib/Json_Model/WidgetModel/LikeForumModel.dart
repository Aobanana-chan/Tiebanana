import '../json.dart';

///关注的吧Tag数据Model
class LikeFormWidgetModel {
  late String forumId;
  late String avatar;
  late String isSign;
  late String isTop;
  late String forumName;
  late String levelId;

  LikeFormWidgetModel(
      {required this.forumId,
      required this.avatar,
      required this.forumName,
      required this.isSign,
      required this.isTop,
      required this.levelId});

  LikeFormWidgetModel.fromLikeForumData(LikeForumInfo info) {
    forumId = info.forumId!;
    avatar = info.avatar!;
    isSign = info.isSign!;
    isTop = info.isTop!;
    forumName = info.forumName!;
    levelId = info.levelId!;
  }
}
