import '../json.dart';

/// 搜索信息Model
class SearchForumWidgetModel {
  late String name;
  late String img;
  late String brief;
  late int member;
  late int post;
  late bool isLike;

  SearchForumWidgetModel(
      {required this.brief,
      required this.img,
      required this.isLike,
      required this.member,
      required this.name,
      required this.post});

  SearchForumWidgetModel.fromSearch(SearchForumModelForum info) {
    name = info.name!;
    img = info.img!;
    brief = info.brief!;
    member = info.member!;
    post = info.post!;
    isLike = info.isLike!;
  }
}
