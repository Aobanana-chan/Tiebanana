/// 稳定的站内路由标识与参数，不依赖具体页面。
abstract class PageRouter {
  static const String home = "/";

  ///参数
  ///String
  static const String forumHome = "forumHome";

  ///参数
  ///ThreadPageRouterData
  static const String threadPage = "threadPage";
  static const String threadCompose = "threadCompose";
  static const String topic = "topic";
  static const String login = "login";
  static const String search = "search";

  ///参数
  ///String（吧名，不含「吧」字）
  static const String forumSearch = "forumSearch";
  static const String imagePicker = "imagePicker";
  static const String user = "user";
  static const String profileEdit = "profileEdit";
  static const String threadStore = "threadStore";
  static const String viewHistory = "viewHistory";
  static const String themeChange = "themeChange";
  static const String serviceCenter = "serviceCenter";
  static const String appSetting = "appSetting";
  static const String about = "about";
  static const String appUpdate = "appUpdate";
}

class LoginRouteOptions {
  const LoginRouteOptions({this.relogin = false});

  final bool relogin;
}

///贴界面路由传值
class ThreadPageRouterData {
  ///帖子的id
  String kz;

  ///没有定位楼层时传 null
  String? pid;
  // bool isStored;
  ThreadPageRouterData({required this.kz, required this.pid});
}

/// 话题页路由传值。
class TopicPageRouterData {
  const TopicPageRouterData({
    required this.name,
    this.topicId = '',
    this.fid = '',
    this.forumName = '',
  });

  final String name;
  final String topicId;
  final String fid;
  final String forumName;
}
