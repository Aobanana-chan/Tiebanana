const defaultAPPSetting = {
  "theme": "blue",
  "pictureLoadSetting": 0,
  "MarkedCache": true,
  "darkModel": 0,
  "signAllsinceOpen": true,
  "useBuildinBrowser": true,
  "checkUpdateAutomaticlly": true,
  "usePostTail": false,
  "postTail": "",
  "fontSize": 16.0
};

///APP设置Model类
class APPSetting {
  ///主题颜色
  String? theme;

  ///图片加载设置
  ///0-智能省流量
  ///1-智能无图
  ///2-始终高质量
  ///3-始终无图
  int? pictureLoadSetting;

  ///收藏贴浏览后自动缓存（防止帖子被删后找不到内容）
  bool? markedCache;

  ///夜间模式
  ///0-跟随系统
  ///1-打开
  ///2-关闭
  int? darkModel;

  ///打开APP后自动签到
  bool? signAllsinceOpen;

  ///连接使用内置浏览器打开
  bool? useBuildinBrowser;

  ///自动检查更新
  bool? checkUpdateAutomaticlly;

  ///使用小尾巴
  bool? usePostTail;

  ///小尾巴内容
  String? postTail;

  double fontSize = 16;

  APPSetting(
      {this.theme,
      this.pictureLoadSetting,
      this.markedCache,
      this.darkModel,
      this.signAllsinceOpen,
      this.useBuildinBrowser,
      this.checkUpdateAutomaticlly,
      this.usePostTail,
      this.postTail,
      required this.fontSize});

  APPSetting.fromJson(Map<String, dynamic> json) {
    theme = json['theme'];
    pictureLoadSetting = json['pictureLoadSetting'];
    markedCache = json['MarkedCache'];
    darkModel = json['darkModel'];
    signAllsinceOpen = json['signAllsinceOpen'];
    useBuildinBrowser = json['useBuildinBrowser'];
    checkUpdateAutomaticlly = json['checkUpdateAutomaticlly'];
    usePostTail = json['usePostTail'];
    postTail = json['postTail'];
    fontSize = json['fontSize'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['theme'] = theme;
    data['pictureLoadSetting'] = pictureLoadSetting;
    data['MarkedCache'] = markedCache;
    data['darkModel'] = darkModel;
    data['signAllsinceOpen'] = signAllsinceOpen;
    data['useBuildinBrowser'] = useBuildinBrowser;
    data['checkUpdateAutomaticlly'] = checkUpdateAutomaticlly;
    data['usePostTail'] = usePostTail;
    data['postTail'] = postTail;
    data['fontSize'] = fontSize;
    return data;
  }
}
