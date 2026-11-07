import 'PostContentModel.dart';

abstract class User {
  late String portrait;

  String? nameShow;
  String? username;

  String get name;

  late String uid;
}

abstract class Post implements User {
  ///创建时间
  late String createTime;

  ///内容
  late List<PostContentBaseWidgetModel> content;

  ///是否为一楼
  late bool isFirstFloor;

  ///是否为楼中楼
  late bool isInnerFloor;

  ///点赞数
  String? agreeNum;

  ///反对数
  String? disagreeNum;

  ///是否点赞
  String? hasAgree;

  ///点赞类型
  String? agreeType;

  Post(
      {this.agreeNum,
      this.disagreeNum,
      required this.content,
      required this.createTime,
      required this.isFirstFloor,
      required this.isInnerFloor});
}

abstract class Forum {
  ///吧id
  late String fid;

  ///吧名
  late String forumName;

  ///吧头像
  late String avatar;
}

abstract class UserIconData {
  late List<String> icons;
}
