const defaultAPPSetting = {
  "theme": "blue",
  "pictureLoadSetting": 0,
  "MarkedCache": true,
  "darkModel": 0,
  "signAllsinceOpen": true,
  "useBuildinBrowser": true,
  "checkUpdateAutomaticlly": true,
  "usePostTail": false,
  "showPostingRiskWarning": true,
  "postTail": null,
  "fontSize": 16.0,
  "homeForumMaxCount": 12,
  "homeHistoryMaxCount": 15,
  "protocolSignUpperHex": true,
  "protocolEnableSig": false
};

///APP设置Model类
class APPSetting {
  static const int defaultHomeHistoryMaxCount = 15;
  static const int minHomeHistoryMaxCount = 1;
  static const int maxHomeHistoryMaxCount = 50;

  ///主题颜色
  String? theme;

  ///图片加载设置
  ///0-智能省流量
  ///1-智能无图
  ///2-始终高质量
  ///3-始终无图
  int? pictureLoadSetting;

  ///收藏贴浏览后自动缓存，便于帖子被删后继续查看
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

  /// 打开发帖 / 回帖界面时提醒第三方客户端的账号风险。
  bool showPostingRiskWarning;

  ///小尾巴内容
  String? postTail;

  double fontSize = 16;

  /// 首页「我关注的吧」缩略状态下同时显示的吧数量（默认 12，范围 3–30）。
  ///
  /// UI 入口待补充，这里提供数据与读写。
  int? homeForumMaxCount;

  /// 首页最近浏览的显示数量（默认 15，范围 1–50）。
  int? homeHistoryMaxCount;

  ///协议层 `sign` 十六进制是否大写（官方为大写）。
  bool? protocolSignUpperHex;

  ///协议层是否附加 sig（云控，默认关闭）。
  bool? protocolEnableSig;

  APPSetting(
      {this.theme,
      this.pictureLoadSetting,
      this.markedCache,
      this.darkModel,
      this.signAllsinceOpen,
      this.useBuildinBrowser,
      this.checkUpdateAutomaticlly,
      this.usePostTail,
      this.showPostingRiskWarning = true,
      this.postTail,
      this.homeForumMaxCount,
      this.homeHistoryMaxCount,
      this.protocolSignUpperHex,
      this.protocolEnableSig,
      required this.fontSize});

  APPSetting.fromJson(Map<String, dynamic> json)
      : showPostingRiskWarning = json['showPostingRiskWarning'] ?? true {
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
    homeForumMaxCount = json['homeForumMaxCount'] ?? _defaultHomeForumMaxCount;
    homeHistoryMaxCount =
        json['homeHistoryMaxCount'] ?? defaultHomeHistoryMaxCount;
    protocolSignUpperHex = json['protocolSignUpperHex'] ?? true;
    protocolEnableSig = json['protocolEnableSig'] ?? false;
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
    data['showPostingRiskWarning'] = showPostingRiskWarning;
    data['postTail'] = postTail;
    data['fontSize'] = fontSize;
    data['homeForumMaxCount'] = homeForumMaxCount;
    data['homeHistoryMaxCount'] = homeHistoryMaxCount;
    data['protocolSignUpperHex'] = protocolSignUpperHex;
    data['protocolEnableSig'] = protocolEnableSig;
    return data;
  }

  String get pictureLoadMode {
    return _pictureLoadType[pictureLoadSetting!]!;
  }

  /// 首页缩略状态显示数量的安全值：3–30，缺省 12。
  int get homeForumMaxCountSafe =>
      (homeForumMaxCount ?? _defaultHomeForumMaxCount)
          .clamp(_minHomeForumMaxCount, _maxHomeForumMaxCount);

  int get homeHistoryMaxCountSafe =>
      (homeHistoryMaxCount ?? defaultHomeHistoryMaxCount)
          .clamp(minHomeHistoryMaxCount, maxHomeHistoryMaxCount);
}

const int _defaultHomeForumMaxCount = 12;
const int _minHomeForumMaxCount = 3;
const int _maxHomeForumMaxCount = 30;

const Map<String, String> themeName = {
  "blue": "宝石蓝",
  "cyan": "石青金",
  "teal": "玛瑙绿",
  "green": "早苗绿",
  "yellow": "咸蛋黄",
  "pink": "胭脂粉",
  "white": "简洁白"
};

const Map<int, String> _pictureLoadType = {
  0: "智能省流量",
  1: "智能无图",
  2: "始终高质量",
  3: "始终无图"
};
