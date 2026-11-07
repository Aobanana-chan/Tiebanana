import '../json.dart';
import 'commonModel.dart';

/// 帖子内容Model

class AuthorWidgetModel implements User, UserIconData {
  String? levelID;
  String get id => uid;
  @override
  late List<String> icons;

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

  AuthorWidgetModel(
      {required this.icons,
      required this.levelID,
      required this.nameShow,
      required this.portrait,
      required this.uid,
      required this.username});

  AuthorWidgetModel.fromData(UserList info) {
    levelID = info.levelID;
    uid = info.id!;
    icons = [];
    for (Iconinfo icon in info.iconinfo ?? []) {
      icons.add(icon.icon!);
    }
    nameShow = info.nameShow;
    username = info.name;
    portrait = info.portrait!;
  }
}

class VedioInfoWidgetModel {
  String? videoUrl;
  late String thumbnailUrl;

  VedioInfoWidgetModel.fromVideoInfo(VideoInfo info) {
    videoUrl = info.videoUrl;
    thumbnailUrl = info.thumbnailUrl!;
  }
}
