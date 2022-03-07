library json_model;

import 'dart:convert';

part 'Json/ThreadRecommendSummary.dart';
part 'Json/ReplyMe.dart';
part 'Json/AtMe.dart';
part 'Json/Message.dart';
part './Json/MyUserInfo.dart';
part './Json/ForumHomeInfo.dart';
part './Json/ForumPageData.dart';
part './Json/PhoneNumberStatus.dart';
part './Json/SendDPass.dart';
part './Json/WapAccountCheck.dart';
part './Json/SearchForumModel.dart';
part './Json/SearchThreadModel.dart';
part './Json/InnerFloorModel.dart';
part './Json/UploadImage.dart';
//TODO:拆分

class WAPTiebaBase {
  String? errcode;
  String? msg;

  WAPTiebaBase({this.errcode, this.msg});

  WAPTiebaBase.fromJson(Map<String, dynamic> json) {
    errcode = json['error_code'];
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['errcode'] = this.errcode;
    data['msg'] = this.msg;
    return data;
  }
}

///TBS随机参数
class TBS {
  String? tbs;
  int? isLogin;

  TBS({this.tbs, this.isLogin});

  TBS.fromJson(Map<String, dynamic> json) {
    tbs = json['tbs'];
    isLogin = (json['is_login'] as num).toInt();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tbs'] = this.tbs;
    data['is_login'] = this.isLogin;
    return data;
  }
}

///服务器返回的rsakey
class RSAKEY {
  String? errno;
  String? msg;
  String? pubkey;
  String? key;
  String? traceid;

  RSAKEY({this.errno, this.msg, this.pubkey, this.key, this.traceid});

  RSAKEY.fromJson(Map<String, dynamic> json) {
    errno = json['errno'];
    msg = json['msg'];
    pubkey = json['pubkey'];
    key = json['key'];
    traceid = json['traceid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['errno'] = this.errno;
    data['msg'] = this.msg;
    data['pubkey'] = this.pubkey;
    data['key'] = this.key;
    data['traceid'] = this.traceid;
    return data;
  }
}

///初始化时候viewlog返回的数据
class ViewlogData {
  int? code;
  Data? data;

  ViewlogData({this.code, this.data});

  ViewlogData.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = this.code;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? tk;
  String? as;
  String? ds;
  Feedback? feedback;

  Data({this.tk, this.as, this.ds, this.feedback});

  Data.fromJson(Map<String, dynamic> json) {
    tk = json['tk'];
    as = json['as'];
    ds = json['ds'];
    feedback = json['feedback'] != null
        ? new Feedback.fromJson(json['feedback'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tk'] = this.tk;
    data['as'] = this.as;
    data['ds'] = this.ds;
    if (this.feedback != null) {
      data['feedback'] = this.feedback!.toJson();
    }
    return data;
  }
}

class Feedback {
  String? wap;
  String? pc;

  Feedback({this.wap, this.pc});

  Feedback.fromJson(Map<String, dynamic> json) {
    wap = json['wap'];
    pc = json['pc'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['wap'] = this.wap;
    data['pc'] = this.pc;
    return data;
  }
}

//用户操作记录
class ClickActionData {
  int? x;
  int? y;
  int? t;

  ClickActionData({this.x, this.y, this.t});

  ClickActionData.fromJson(Map<String, dynamic> json) {
    x = json['x'];
    y = json['y'];
    t = json['t'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['x'] = this.x;
    data['y'] = this.y;
    data['t'] = this.t;
    return data;
  }
}

class MoveActionData {
  int? fx;
  int? fy;
  int? t;

  MoveActionData({this.fx, this.fy, this.t});

  MoveActionData.fromJson(Map<String, dynamic> json) {
    fx = json['fx'];
    fy = json['fy'];
    t = json['t'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['fx'] = this.fx;
    data['fy'] = this.fy;
    data['t'] = this.t;
    return data;
  }
}

///getstyle请求返回的数据
class Getstyle {
  int? code;
  GetstyleData? getstyleData;

  Getstyle({this.code, this.getstyleData});

  Getstyle.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    getstyleData =
        json['data'] != null ? new GetstyleData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = this.code;
    if (this.getstyleData != null) {
      data['data'] = this.getstyleData!.toJson();
    }
    return data;
  }
}

class GetstyleData {
  String? type;
  String? backstr;
  Ext? ext;

  GetstyleData({this.type, this.backstr, this.ext});

  GetstyleData.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    backstr = json['backstr'];
    ext = json['ext'] != null ? new Ext.fromJson(json['ext']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['backstr'] = this.backstr;
    if (this.ext != null) {
      data['ext'] = this.ext!.toJson();
    }
    return data;
  }
}

class Ext {
  String? img;
  String? info;
  int? sup;

  Ext({this.img, this.info, this.sup});

  Ext.fromJson(Map<String, dynamic> json) {
    img = json['img'];
    info = json['info'];
    sup = (json['sup'] as double).toInt();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['img'] = this.img;
    data['info'] = this.info;
    data['sup'] = this.sup;
    return data;
  }
}

class ViewlogVerify {
  int? code;
  Dsdata? dsdata;

  ViewlogVerify({this.code, this.dsdata});

  ViewlogVerify.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    dsdata = json['data'] != null ? new Dsdata.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = this.code;
    if (this.dsdata != null) {
      data['data'] = this.dsdata!.toJson();
    }
    return data;
  }
}

class Dsdata {
  String? tk;
  String? as;
  String? ds;
  int? op;

  Dsdata({this.tk, this.as, this.ds, this.op});

  Dsdata.fromJson(Map<String, dynamic> json) {
    tk = json['tk'];
    as = json['as'];
    ds = json['ds'];
    op = json['op'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tk'] = this.tk;
    data['as'] = this.as;
    data['ds'] = this.ds;
    data['op'] = this.op;
    return data;
  }
}

class LoginErrCode {
  String? errcode;
  String? msg;

  LoginErrCode({this.errcode, this.msg});

  LoginErrCode.fromJson(Map<String, dynamic> json) {
    errcode = json['errcode'];
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['errcode'] = this.errcode;
    data['msg'] = this.msg;
    return data;
  }
}

///APP设置Model类
class APPSetting {
  ///主题，对应theme颜色的Hex
  int? theme;

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

  APPSetting(
      {this.theme,
      this.pictureLoadSetting,
      this.markedCache,
      this.darkModel,
      this.signAllsinceOpen,
      this.useBuildinBrowser,
      this.checkUpdateAutomaticlly,
      this.usePostTail,
      this.postTail});

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
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['theme'] = this.theme;
    data['pictureLoadSetting'] = this.pictureLoadSetting;
    data['MarkedCache'] = this.markedCache;
    data['darkModel'] = this.darkModel;
    data['signAllsinceOpen'] = this.signAllsinceOpen;
    data['useBuildinBrowser'] = this.useBuildinBrowser;
    data['checkUpdateAutomaticlly'] = this.checkUpdateAutomaticlly;
    data['usePostTail'] = this.usePostTail;
    data['postTail'] = this.postTail;
    return data;
  }
}

//WAP端登陆服务器返回json
class WAPLoginResponse {
  ErrInfo? errInfo;
  WAPData? data;

  WAPLoginResponse({this.errInfo, this.data});

  WAPLoginResponse.fromJson(Map<String, dynamic> json) {
    errInfo =
        json['errInfo'] != null ? new ErrInfo.fromJson(json['errInfo']) : null;
    data = (json['data'] != null ? new Data.fromJson(json['data']) : null)
        as WAPData?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.errInfo != null) {
      data['errInfo'] = this.errInfo!.toJson();
    }
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class ErrInfo {
  String? no;
  String? msg;

  ErrInfo({this.no, this.msg});

  ErrInfo.fromJson(Map<String, dynamic> json) {
    no = json['no'];
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['no'] = this.no;
    data['msg'] = this.msg;
    return data;
  }
}

class WAPData {
  String? u;
  int? serverTime;
  String? codeString;
  String? bduss;
  String? ptoken;
  String? bcsn;
  String? bcsync;
  String? bcchecksum;
  String? bctime;
  String? gotoUrl;
  String? userid;
  String? phone;
  String? appealurl;
  String? secondU;
  String? ppU;
  String? realnameswitch;
  String? appealcode;
  String? ppDatau;
  String? livinguname;
  String? liveSecurity;
  String? xml;
  String? username;
  String? realName;
  String? bdstoken;
  String? bdstokenback;
  String? authsid;
  String? authsidback;
  String? authtoken;
  String? lstr;
  String? ltoken;
  String? isChangePwd;
  String? isSilenceAccount;
  String? jumpset;
  String? secstate;
  String? oriU;
  String? showType;
  String? email;
  String? realnameverifyemail;
  String? mobile;
  String? mobileHidden;
  String? countrycode;
  String? idcard;
  String? liveUsername;
  String? loginProxy;
  String? verifyUrl;
  String? hasGuideFaceLogin;
  String? guideFaceAuthsid;
  String? isFinanceTpl;
  String? openSwitchType;
  String? authtokenFaceLogin;
  String? guidefrom;
  String? isFinance;
  String? headImage;
  String? defaultUserName;
  String? isslide;
  String? ppIsUpgradeMobile;
  String? ppEncryptUserid;
  String? hasRealName;
  String? scscene;
  String? scnewuser;
  int? degradeUpSms;
  String? needDelayHint;
  String? portraitSign;
  String? portrait;
  String? isReg;
  String? guideSetPwdUname;
  String? secauthsid;
  String? secbdstoken;
  bool? switchJsonSec;
  bool? switchJsonRealName;
  String? target;

  WAPData(
      {this.u,
      this.serverTime,
      this.codeString,
      this.bduss,
      this.ptoken,
      this.bcsn,
      this.bcsync,
      this.bcchecksum,
      this.bctime,
      this.gotoUrl,
      this.userid,
      this.phone,
      this.appealurl,
      this.secondU,
      this.ppU,
      this.realnameswitch,
      this.appealcode,
      this.ppDatau,
      this.livinguname,
      this.liveSecurity,
      this.xml,
      this.username,
      this.realName,
      this.bdstoken,
      this.bdstokenback,
      this.authsid,
      this.authsidback,
      this.authtoken,
      this.lstr,
      this.ltoken,
      this.isChangePwd,
      this.isSilenceAccount,
      this.jumpset,
      this.secstate,
      this.oriU,
      this.showType,
      this.email,
      this.realnameverifyemail,
      this.mobile,
      this.mobileHidden,
      this.countrycode,
      this.idcard,
      this.liveUsername,
      this.loginProxy,
      this.verifyUrl,
      this.hasGuideFaceLogin,
      this.guideFaceAuthsid,
      this.isFinanceTpl,
      this.openSwitchType,
      this.authtokenFaceLogin,
      this.guidefrom,
      this.isFinance,
      this.headImage,
      this.defaultUserName,
      this.isslide,
      this.ppIsUpgradeMobile,
      this.ppEncryptUserid,
      this.hasRealName,
      this.scscene,
      this.scnewuser,
      this.degradeUpSms,
      this.needDelayHint,
      this.portraitSign,
      this.portrait,
      this.isReg,
      this.guideSetPwdUname,
      this.secauthsid,
      this.secbdstoken,
      this.switchJsonSec,
      this.switchJsonRealName,
      this.target});

  WAPData.fromJson(Map<String, dynamic> json) {
    u = json['u'];
    serverTime = json['serverTime'];
    codeString = json['codeString'];
    bduss = json['bduss'];
    ptoken = json['ptoken'];
    bcsn = json['bcsn'];
    bcsync = json['bcsync'];
    bcchecksum = json['bcchecksum'];
    bctime = json['bctime'];
    gotoUrl = json['gotoUrl'];
    userid = json['userid'];
    phone = json['phone'];
    appealurl = json['appealurl'];
    secondU = json['second_u'];
    ppU = json['ppU'];
    realnameswitch = json['realnameswitch'];
    appealcode = json['appealcode'];
    ppDatau = json['ppDatau'];
    livinguname = json['livinguname'];
    liveSecurity = json['liveSecurity'];
    xml = json['xml'];
    username = json['username'];
    realName = json['realName'];
    bdstoken = json['bdstoken'];
    bdstokenback = json['bdstokenback'];
    authsid = json['authsid'];
    authsidback = json['authsidback'];
    authtoken = json['authtoken'];
    lstr = json['lstr'];
    ltoken = json['ltoken'];
    isChangePwd = json['isChangePwd'];
    isSilenceAccount = json['isSilenceAccount'];
    jumpset = json['jumpset'];
    secstate = json['secstate'];
    oriU = json['ori_u'];
    showType = json['showType'];
    email = json['email'];
    realnameverifyemail = json['realnameverifyemail'];
    mobile = json['mobile'];
    mobileHidden = json['mobileHidden'];
    countrycode = json['countrycode'];
    idcard = json['idcard'];
    liveUsername = json['liveUsername'];
    loginProxy = json['loginProxy'];
    verifyUrl = json['verifyUrl'];
    hasGuideFaceLogin = json['hasGuideFaceLogin'];
    guideFaceAuthsid = json['guideFaceAuthsid'];
    isFinanceTpl = json['isFinanceTpl'];
    openSwitchType = json['openSwitchType'];
    authtokenFaceLogin = json['authtokenFaceLogin'];
    guidefrom = json['guidefrom'];
    isFinance = json['isFinance'];
    headImage = json['headImage'];
    defaultUserName = json['defaultUserName'];
    isslide = json['isslide'];
    ppIsUpgradeMobile = json['ppIsUpgradeMobile'];
    ppEncryptUserid = json['ppEncryptUserid'];
    hasRealName = json['hasRealName'];
    scscene = json['scscene'];
    scnewuser = json['scnewuser'];
    degradeUpSms = json['degradeUpSms'];
    needDelayHint = json['needDelayHint'];
    portraitSign = json['portraitSign'];
    portrait = json['portrait'];
    isReg = json['isReg'];
    guideSetPwdUname = json['guide_set_pwd_uname'];
    secauthsid = json['secauthsid'];
    secbdstoken = json['secbdstoken'];
    switchJsonSec = json['switchJsonSec'];
    switchJsonRealName = json['switchJsonRealName'];
    target = json['target'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['u'] = this.u;
    data['serverTime'] = this.serverTime;
    data['codeString'] = this.codeString;
    data['bduss'] = this.bduss;
    data['ptoken'] = this.ptoken;
    data['bcsn'] = this.bcsn;
    data['bcsync'] = this.bcsync;
    data['bcchecksum'] = this.bcchecksum;
    data['bctime'] = this.bctime;
    data['gotoUrl'] = this.gotoUrl;
    data['userid'] = this.userid;
    data['phone'] = this.phone;
    data['appealurl'] = this.appealurl;
    data['second_u'] = this.secondU;
    data['ppU'] = this.ppU;
    data['realnameswitch'] = this.realnameswitch;
    data['appealcode'] = this.appealcode;
    data['ppDatau'] = this.ppDatau;
    data['livinguname'] = this.livinguname;
    data['liveSecurity'] = this.liveSecurity;
    data['xml'] = this.xml;
    data['username'] = this.username;
    data['realName'] = this.realName;
    data['bdstoken'] = this.bdstoken;
    data['bdstokenback'] = this.bdstokenback;
    data['authsid'] = this.authsid;
    data['authsidback'] = this.authsidback;
    data['authtoken'] = this.authtoken;
    data['lstr'] = this.lstr;
    data['ltoken'] = this.ltoken;
    data['isChangePwd'] = this.isChangePwd;
    data['isSilenceAccount'] = this.isSilenceAccount;
    data['jumpset'] = this.jumpset;
    data['secstate'] = this.secstate;
    data['ori_u'] = this.oriU;
    data['showType'] = this.showType;
    data['email'] = this.email;
    data['realnameverifyemail'] = this.realnameverifyemail;
    data['mobile'] = this.mobile;
    data['mobileHidden'] = this.mobileHidden;
    data['countrycode'] = this.countrycode;
    data['idcard'] = this.idcard;
    data['liveUsername'] = this.liveUsername;
    data['loginProxy'] = this.loginProxy;
    data['verifyUrl'] = this.verifyUrl;
    data['hasGuideFaceLogin'] = this.hasGuideFaceLogin;
    data['guideFaceAuthsid'] = this.guideFaceAuthsid;
    data['isFinanceTpl'] = this.isFinanceTpl;
    data['openSwitchType'] = this.openSwitchType;
    data['authtokenFaceLogin'] = this.authtokenFaceLogin;
    data['guidefrom'] = this.guidefrom;
    data['isFinance'] = this.isFinance;
    data['headImage'] = this.headImage;
    data['defaultUserName'] = this.defaultUserName;
    data['isslide'] = this.isslide;
    data['ppIsUpgradeMobile'] = this.ppIsUpgradeMobile;
    data['ppEncryptUserid'] = this.ppEncryptUserid;
    data['hasRealName'] = this.hasRealName;
    data['scscene'] = this.scscene;
    data['scnewuser'] = this.scnewuser;
    data['degradeUpSms'] = this.degradeUpSms;
    data['needDelayHint'] = this.needDelayHint;
    data['portraitSign'] = this.portraitSign;
    data['portrait'] = this.portrait;
    data['isReg'] = this.isReg;
    data['guide_set_pwd_uname'] = this.guideSetPwdUname;
    data['secauthsid'] = this.secauthsid;
    data['secbdstoken'] = this.secbdstoken;
    data['switchJsonSec'] = this.switchJsonSec;
    data['switchJsonRealName'] = this.switchJsonRealName;
    data['target'] = this.target;
    return data;
  }
}

///手机安全验证服务器返回
class AuthwidgetverifyRespone {
  String? errno;
  String? msg;
  String? forgot;
  String? ppEncryptuid;
  String? ppAuthName;
  String? ppNewAuthName;
  String? ppBindAction;
  AuthwidgetverifyResponeData? data;
  String? countrycode;
  String? traceid;

  AuthwidgetverifyRespone(
      {this.errno,
      this.msg,
      this.forgot,
      this.ppEncryptuid,
      this.ppAuthName,
      this.ppNewAuthName,
      this.ppBindAction,
      this.data,
      this.countrycode,
      this.traceid});

  AuthwidgetverifyRespone.fromJson(Map<String, dynamic> json) {
    errno = json['errno'];
    msg = json['msg'];
    forgot = json['forgot'];
    ppEncryptuid = json['ppEncryptuid'];
    ppAuthName = json['ppAuthName'];
    ppNewAuthName = json['ppNewAuthName'];
    ppBindAction = json['ppBindAction'];
    data = json['data'] != null
        ? new AuthwidgetverifyResponeData.fromJson(json['data'])
        : null;
    countrycode = json['countrycode'];
    traceid = json['traceid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['errno'] = this.errno;
    data['msg'] = this.msg;
    data['forgot'] = this.forgot;
    data['ppEncryptuid'] = this.ppEncryptuid;
    data['ppAuthName'] = this.ppAuthName;
    data['ppNewAuthName'] = this.ppNewAuthName;
    data['ppBindAction'] = this.ppBindAction;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['countrycode'] = this.countrycode;
    data['traceid'] = this.traceid;
    return data;
  }
}

class AuthwidgetverifyResponeData {
  String? mobile; //手机-验证六位数短信验证码
  String? verifymobile;
  String? email; //密保邮箱
  String? softtoken; //百度帐号管家
  String? password; //登录密码
  String? isUc; //暂时不明确
  String? historyPassword;
  String? originalMobile; //当前手机
  List? originalBankcard; //银行卡号
  String? originalIdcard; //当前身份证号
  String? username; //用户名
  String? originalEmail; //当前邮箱

  AuthwidgetverifyResponeData(
      {this.mobile,
      this.verifymobile,
      this.email,
      this.softtoken,
      this.password,
      this.isUc,
      this.historyPassword,
      this.originalMobile,
      this.originalBankcard,
      this.originalIdcard,
      this.username,
      this.originalEmail});

  AuthwidgetverifyResponeData.fromJson(Map<String, dynamic> json) {
    mobile = json['mobile'];
    verifymobile = json['verifymobile'];
    email = json['email'];
    softtoken = json['softtoken'];
    password = json['password'];
    isUc = json['isUc'];
    historyPassword = json['history_password'];
    originalMobile = json['original_mobile'];
    if (json['original_bankcard'] != null) {
      originalBankcard = [];
      json['original_bankcard'].forEach((v) {
        originalBankcard!.add(v);
      });
    }
    originalIdcard = json['original_idcard'];
    username = json['username'];
    originalEmail = json['original_email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['mobile'] = this.mobile;
    data['verifymobile'] = this.verifymobile;
    data['email'] = this.email;
    data['softtoken'] = this.softtoken;
    data['password'] = this.password;
    data['isUc'] = this.isUc;
    data['history_password'] = this.historyPassword;
    data['original_mobile'] = this.originalMobile;
    if (this.originalBankcard != null) {
      data['original_bankcard'] =
          this.originalBankcard!.map((v) => v.toJson()).toList();
    }
    data['original_idcard'] = this.originalIdcard;
    data['username'] = this.username;
    data['original_email'] = this.originalEmail;
    return data;
  }
}

///GetForumHome数据Model
class GetForumHomeData {
  GetForumHomeMainData? data;
  String? errmsg;
  int? errno;
  String? logid;
  int? serverTime;
  String? time;

  GetForumHomeData(
      {this.data,
      this.errmsg,
      this.errno,
      this.logid,
      this.serverTime,
      this.time});

  GetForumHomeData.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null
        ? new GetForumHomeMainData.fromJson(json['data'])
        : null;
    errmsg = json['errmsg'];
    errno = json['errno'];
    logid = json['logid'];
    serverTime = json['server_time'];
    time = json['time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['errmsg'] = this.errmsg;
    data['errno'] = this.errno;
    data['logid'] = this.logid;
    data['server_time'] = this.serverTime;
    data['time'] = this.time;
    return data;
  }
}

class GetForumHomeMainData {
  LikeForum? likeForum;
  Tokens? tokens;
  List<UbsAbtestConfig>? ubsAbtestConfig;
  String? ubsSampleIds;
  UserInfo? userInfo;

  GetForumHomeMainData(
      {this.likeForum,
      this.tokens,
      this.ubsAbtestConfig,
      this.ubsSampleIds,
      this.userInfo});

  GetForumHomeMainData.fromJson(Map<String, dynamic> json) {
    likeForum = json['like_forum'] != null
        ? new LikeForum.fromJson(json['like_forum'])
        : null;
    tokens =
        json['tokens'] != null ? new Tokens.fromJson(json['tokens']) : null;
    if (json['ubs_abtest_config'] != null) {
      ubsAbtestConfig = <UbsAbtestConfig>[];
      json['ubs_abtest_config'].forEach((v) {
        ubsAbtestConfig!.add(new UbsAbtestConfig.fromJson(v));
      });
    }
    ubsSampleIds = json['ubs_sample_ids'];
    userInfo = json['user_info'] != null
        ? new UserInfo.fromJson(json['user_info'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.likeForum != null) {
      data['like_forum'] = this.likeForum!.toJson();
    }
    if (this.tokens != null) {
      data['tokens'] = this.tokens!.toJson();
    }
    if (this.ubsAbtestConfig != null) {
      data['ubs_abtest_config'] =
          this.ubsAbtestConfig!.map((v) => v.toJson()).toList();
    }
    data['ubs_sample_ids'] = this.ubsSampleIds;
    if (this.userInfo != null) {
      data['user_info'] = this.userInfo!.toJson();
    }
    return data;
  }
}

class LikeForum {
  List<TiebaList>? list;
  Page? page;

  LikeForum({this.list, this.page});

  LikeForum.fromJson(Map<String, dynamic> json) {
    if (json['list'] != null) {
      list = <TiebaList>[];
      json['list'].forEach((v) {
        list!.add(new TiebaList.fromJson(v));
      });
    }
    page = json['page'] != null ? new Page.fromJson(json['page']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.list != null) {
      data['list'] = this.list!.map((v) => v.toJson()).toList();
    }
    if (this.page != null) {
      data['page'] = this.page!.toJson();
    }
    return data;
  }
}

class TiebaList {
  String? avatar;
  int? forumId;
  String? forumName;
  int? hotNum;
  int? isBrandForum;
  int? levelId;

  TiebaList(
      {this.avatar,
      this.forumId,
      this.forumName,
      this.hotNum,
      this.isBrandForum,
      this.levelId});

  TiebaList.fromJson(Map<String, dynamic> json) {
    avatar = json['avatar'];
    forumId = json['forum_id'];
    forumName = json['forum_name'];
    hotNum = json['hot_num'];
    isBrandForum = json['is_brand_forum'];
    levelId = json['level_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['avatar'] = this.avatar;
    data['forum_id'] = this.forumId;
    data['forum_name'] = this.forumName;
    data['hot_num'] = this.hotNum;
    data['is_brand_forum'] = this.isBrandForum;
    data['level_id'] = this.levelId;
    return data;
  }
}

class Page {
  int? curPage;
  int? totalPage;

  Page({this.curPage, this.totalPage});

  Page.fromJson(Map<String, dynamic> json) {
    curPage = json['cur_page'];
    totalPage = json['total_page'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['cur_page'] = this.curPage;
    data['total_page'] = this.totalPage;
    return data;
  }
}

class Tokens {
  String? bottomBanner;
  String? bottomLayer;
  String? indexFooterClientDown;
  String? indexMessageIcon;

  Tokens(
      {this.bottomBanner,
      this.bottomLayer,
      this.indexFooterClientDown,
      this.indexMessageIcon});

  Tokens.fromJson(Map<String, dynamic> json) {
    bottomBanner = json['bottom_banner'];
    bottomLayer = json['bottom_layer'];
    indexFooterClientDown = json['index_footer_client_down'];
    indexMessageIcon = json['index_message_icon'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['bottom_banner'] = this.bottomBanner;
    data['bottom_layer'] = this.bottomLayer;
    data['index_footer_client_down'] = this.indexFooterClientDown;
    data['index_message_icon'] = this.indexMessageIcon;
    return data;
  }
}

class UbsAbtestConfig {
  String? sid;

  UbsAbtestConfig({this.sid});

  UbsAbtestConfig.fromJson(Map<String, dynamic> json) {
    sid = json['sid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sid'] = this.sid;
    return data;
  }
}

class UserInfo {
  int? id;
  int? isLogin;

  UserInfo({this.id, this.isLogin});

  UserInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    isLogin = json['is_login'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['is_login'] = this.isLogin;
    return data;
  }
}

class LikeForumInfo {
  String? forumId;
  String? avatar;
  String? isSign;
  String? isTop;
  String? inTime;
  String? forumName;
  String? levelId;
  String? isBrandForum;
  // ThemeColor themeColor;
  String? content;
  String? needTrans;
  List? tabInfo;

  LikeForumInfo(
      {this.forumId,
      this.avatar,
      this.isSign,
      this.isTop,
      this.inTime,
      this.forumName,
      this.levelId,
      this.isBrandForum,
      // this.themeColor,
      this.content,
      this.needTrans,
      this.tabInfo});

  LikeForumInfo.fromJson(Map<String, dynamic> json) {
    forumId = (json['forum_id'] as num).toInt().toString();
    avatar = json['avatar'];
    isSign = (json['is_sign'] as num).toInt().toString();
    isTop = (json['is_top'] as num).toInt().toString();
    inTime = (json['in_time'] as num).toInt().toString();
    forumName = json['forum_name'];
    levelId = json['level_id'];
    isBrandForum = (json['is_brand_forum'] as num).toInt().toString();
    // themeColor = json['theme_color'] != null
    //     ? new ThemeColor.fromJson(json['theme_color'])
    //     : null;
    content = json['content'];
    needTrans = (json['need_trans'] as num).toInt().toString();
    if (json['tab_info'] != null) {
      tabInfo = [];
      json['tab_info'].forEach((v) {
        tabInfo!.add(v);
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['forum_id'] = this.forumId;
    data['avatar'] = this.avatar;
    data['is_sign'] = this.isSign;
    data['is_top'] = this.isTop;
    data['in_time'] = this.inTime;
    data['forum_name'] = this.forumName;
    data['level_id'] = this.levelId;
    data['is_brand_forum'] = this.isBrandForum;
    // if (this.themeColor != null) {
    //   data['theme_color'] = this.themeColor.toJson();
    // }
    data['content'] = this.content;
    data['need_trans'] = this.needTrans;
    if (this.tabInfo != null) {
      data['tab_info'] = this.tabInfo!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
