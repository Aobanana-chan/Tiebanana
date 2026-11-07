import '../json.dart';

///搜索贴Model

class SearchPostWidgetModel {
  late int type;
  late String tid;
  late String userAvatar;
  late String username;
  late String title;
  late String forumName;
  late String time;
  late String content;

  SearchPostWidgetModel(
      {required this.content,
      required this.forumName,
      required this.tid,
      required this.time,
      required this.title,
      required this.type,
      required this.userAvatar,
      required this.username});

  SearchPostWidgetModel.fromPostList(SearchPostModelPostList post) {
    content = post.mainPost?.content ?? post.content ?? "";
    forumName = post.forumName!;
    type = post.type!;
    tid = post.tid!;
    userAvatar = post.user?.portrait ?? post.user!.portraith!;
    username = post.user?.showNickname ?? post.user!.userName!;
    time = post.time!;
    title = post.title!;
  }
}
