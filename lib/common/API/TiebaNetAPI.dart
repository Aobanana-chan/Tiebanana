///百度贴吧API
///作者：Aobanana

import 'dart:ui';

import 'dart:io';
import "dart:math";
import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:dio/dio.dart';
import 'package:dio/adapter.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:encrypt/encrypt.dart';
import 'package:json5/json5.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/common/API/LG_DV_ARG.dart';
import 'package:tiebanana/common/API/TBSManager.dart';
import 'package:tiebanana/common/API/UserInfo.dart';
import 'package:tiebanana/common/API/Authverify.dart';
import 'package:tiebanana/common/API/FUID.dart';
import 'package:tiebanana/common/API/PassMachine.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:uuid/uuid.dart';
import 'Constants.dart';

class TiebaAPI {
  static Dio dio = new Dio(BaseOptions(
    headers: {
      "User-Agent": ChromeUA,

      // "Connection": "keep-alive",
    },
    // receiveTimeout: 0x7FFFFFFFF
  ));
  late PersistCookieJar cookieJar;

  bool _isLogin = false;
  bool get isLogin {
    return _isLogin;
  }

  set isLogin(bool val) {
    _isLogin = val;
    if (val == true) {
      //登陆后加载用户信息
      cookieJar.loadForRequest(Uri.parse(BAIDU_URL)).then((value) {
        for (var i in value) {
          if (i.name == "BDUSS") {
            bduss = i.value;
            break;
          }
        }
        userInfomation.init(bduss);
      });
      cookieJar.loadForRequest(Uri.parse(BAIDU_PASSPORT_URL)).then((value) {
        for (var i in value) {
          if (i.name == "STOKEN") {
            stoken = i.value;
            break;
          }
        }
        userInfomation.init(bduss);
      });
    }
  }

  //budss简单加密，考虑可能在本地保存
  // ignore: non_constant_identifier_names
  // late String _bduss_encrypt;
  // set bduss(String str) {
  //   _bduss_encrypt = Encrypter(AES(
  //           Key.fromUtf8("d7c2dbf638964f50018b1161e174d8ba"),
  //           mode: AESMode.ecb))
  //       .encrypt(str, iv: IV.fromLength(0))
  //       .base64;
  // }

  // String get bduss {
  //   return Encrypter(AES(Key.fromUtf8("d7c2dbf638964f50018b1161e174d8ba"),
  //           mode: AESMode.ecb))
  //       .decrypt(Encrypted.fromBase64(_bduss_encrypt), iv: IV.fromLength(0));
  // }
  late String bduss;
  late String stoken;

  ///token值可能为空，不建议直接使用,建议使用_getToken获取token
  String token = "";

  String _traceID = "";

  String _gid = "";

  WindowsDv windowsDv = WindowsDv();
  PassMachine passMachine = PassMachine(dio);
  FingerPrint fuid = FingerPrint();
  AuthVerifyManager authVerifyManager = AuthVerifyManager(dio);
  TBSMagager tbsMagager = TBSMagager(dio);
  UserInfomation userInfomation = UserInfomation(dio);

  ///类在用之前先初始化
  Future init() async {
    //设置cookie保存目录
    Directory? cookiedir = await getApplicationDocumentsDirectory();
    cookieJar =
        PersistCookieJar(storage: FileStorage(cookiedir.path + "/cookies/"));
    dio.interceptors.add(CookieManager(cookieJar));

    //Debug模式下设置抓包调试
    if (!Global.isRelease) {
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
          (client) {
        client.findProxy = (uri) {
          return "PROXY 10.0.2.2:8888";
        };
        //代理工具会提供一个抓包的自签名证书，会通不过证书校验，所以我们禁用证书校验
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return null;
      };
    }
    //判断是否已经登陆
    if (await checkLogin()) {
      isLogin = true;
    } else {
      isLogin = false;

      ///登陆之前需要初始化
      await passMachine.init();
    }
  }

  ///检查是否登录
  Future<bool> checkLogin() async {
    Response res = await dio.get(TBS_URL);
    var resJson = TBS.fromJson(jsonDecode(res.data));
    if (resJson.isLogin == 1) {
      return true;
    } else {
      return false;
    }
  }

  ///模拟web入口的账号密码登陆
  Future<LoginErrCode> loginByPassword(String username, String password) async {
    if (isLogin) {
      //删除cookie和token
      await cookieJar.deleteAll();
      token = "";
      isLogin = false;
    }
    var cookies =
        (await cookieJar.loadForRequest(Uri.parse(BAIDU_URL))).toString();
    //没有BAIDUID就浏览百度首页,以设置BAIDUID等Cookie
    if (!cookies.contains("BAIDUID")) {
      await dio.get(BAIDU_URL);
    }
    //获取token
    var _token = await _getToken();
    //获取RSA加密公钥
    RSAKEY rsaKey = await _getRSAKey();
    var passwdEncrypted = Encrypter(RSA(
            publicKey: (RSAKeyParser().parse("${rsaKey.pubkey}") as dynamic)))
        .encrypt(password)
        .base64;
    //提交登陆POST
    var gid = _guideRandom();
    var time = DateTime.now().millisecondsSinceEpoch;
    var ppuiLogintime = Random().nextInt(88888) + 15000; //从界面到登陆的的时间，简单用随机数代替一下
    var sigParams = {
      "staticpage": "https://www.baidu.com/cache/user/html/v3Jump.html",
      "charset": "UTF-8",
      "token": _token,
      "tpl": "mn",
      "subpro": "",
      "apiver": "v3",
      "tt": time,
      "codestring": "",
      "safeflg": "0",
      "u": BAIDU_URL,
      "isPhone": "",
      "detect": "1",
      "gid": gid,
      "quick_user": "0",
      "logintype": "dialogLogin",
      "logLoginType": "pc_loginDialog",
      "idc": "",
      "loginmerge": "true",
      "mkey": "",
      "splogin": "rate",
      "username": username,
      "password": passwdEncrypted,
      "mem_pass": "on",
      "rsakey": rsaKey.key,
      "crypttype": 12,
      "ppui_logintime": ppuiLogintime,
      "countrycode": "",
      "fp_uid": "",
      "fp_info": "",
      "loginversion": "v4",
      "supportdv": "1",
      "ds": passMachine.ds,
      "tk": passMachine.tk,
      "dv": windowsDv.dv,
      "fuid": fuid.fuid, //fuid是由fingerprint2js算出来的浏览器唯一标识
      "alg": "v3",
      "time": time ~/ 1000,
    };

    var loginRes = await dio.post(LOGIN_POST_URL,
        data: {
          "staticpage": "https://www.baidu.com/cache/user/html/v3Jump.html",
          "charset": " UTF-8",
          "token": _token,
          "tpl": "mn",
          "subpro": "",
          "apiver": "v3",
          "tt": time,
          "codestring": "",
          "safeflg": 0,
          "u": BAIDU_URL,
          "isPhone": "",
          "detect": 1,
          "gid": gid,
          "quick_user": 0,
          "logintype": "dialogLogin",
          "logLoginType": "pc_loginDialog",
          "idc": "",
          "loginmerge": true,
          "mkey": "",
          "splogin": "rate",
          "username": username,
          "password": passwdEncrypted,
          "mem_pass": "on",
          "rsakey": rsaKey.key,
          "crypttype": 12,
          "ppui_logintime": ppuiLogintime,
          "countrycode": "",
          "fp_uid": "",
          "fp_info": "",
          "loginversion": "v4",
          "supportdv": 1,
          "ds": passMachine.ds,
          "tk": passMachine.tk,
          "dv": windowsDv.dv,
          "fuid": fuid.fuid,
          "traceid": _getTraceID(),
          //"callback":
          "time": time ~/ 1000,
          "alg": "v3",
          "sig": _getSig(_mapSrot(sigParams)),
          "shaOne": _getshaOne(time),
          "elapsed": DateTime.now().millisecondsSinceEpoch - time,
          "rinfo": {
            "fuid": "${md5.convert(utf8.encode(fuid.fuid)).toString()}"
          } //这里的fuid是上面的fuid的md5值
        },
        options: Options(headers: {
          "Referer": BAIDU_URL,
          "Content-Type": "application/x-www-form-urlencoded"
        }, responseType: ResponseType.plain));
    var errNo = RegExp(r"(?<=err_no=)(.+?)(?=&)").firstMatch(loginRes.data)![0];
    //需要安全验证时，初始化安全验证类
    if (errNo == "120021") {
      authVerifyManager.init(loginRes.data);
    }
    if (errNo == "0") {
      isLogin = true;
    }
    return BaiduErroNo.parse(errNo!);
  }

  ///模拟web端的短信登陆
  Future<LoginErrCode> loginByPhone(String phoneNumber, String verifyCode,
      {String? smsvcodesign, String? smsvcodestr}) async {
    if (isLogin) {
      //删除cookie和token
      await cookieJar.deleteAll();
      token = "";
      isLogin = false;
    }
    var cookies =
        (await cookieJar.loadForRequest(Uri.parse(BAIDU_URL))).toString();
    //没有BAIDUID就浏览百度首页,以设置BAIDUID等Cookie
    if (!cookies.contains("BAIDUID")) {
      await dio.get(BAIDU_URL);
    }
    //获取token
    var _token = await _getToken();
    //提交登陆POST
    var gid = _guideRandom();
    var time = DateTime.now().millisecondsSinceEpoch;
    var sigParams = {
      "staticpage": "https://www.baidu.com/cache/user/html/v3Jump.html",
      "charset": "UTF-8",
      "token": _token,
      "tpl": "mn",
      "subpro": "",
      "apiver": "v3",
      "tt": time,
      "smscodestring": "",
      "u": BAIDU_URL,
      "gid": gid,
      "idc": "",
      "mkey": "",
      "username": phoneNumber,
      "password": verifyCode,
      "countrycode": "",
      "fp_uid": "",
      "fp_info": "",
      "loginversion": "v4",
      "dv": windowsDv.dv,
      "fuid": fuid.fuid, //fuid是由fingerprint2js算出来的浏览器唯一标识
      "alg": "v3",
      "time": time ~/ 1000,
      "isdpass": 1,
      "switchuname": "",
      "is_voice_sms": 0,
      "voice_sms_flag": 0,
      "client": "",
      "isupsms": "",
      "channelid": "",
      "smsvcodesign": smsvcodesign,
      "smsvcodestr": smsvcodestr,
    };

    var data = {
      "staticpage": "https://www.baidu.com/cache/user/html/v3Jump.html",
      "charset": "UTF-8",
      "token": _token,
      "tpl": "mn",
      "subpro": "",
      "apiver": "v3",
      "tt": time,
      "smscodestring": "",
      "u": BAIDU_URL,
      "gid": gid,
      "idc": "",
      "mkey": "",
      "username": phoneNumber,
      "password": verifyCode,
      "countrycode": "",
      "fp_uid": "",
      "fp_info": "",
      "loginversion": "v4",
      "dv": windowsDv.dv,
      "fuid": fuid.fuid,
      "traceid": _getTraceID(),
      "time": time ~/ 1000,
      "alg": "v3",
      "sig": _getSig(_mapSrot(sigParams)),
      "shaOne": _getshaOne(time),
      "elapsed": DateTime.now().millisecondsSinceEpoch - time,
      "rinfo": {
        "fuid": "${md5.convert(utf8.encode(fuid.fuid)).toString()}"
      } //这里的fuid是上面的fuid的md5值
      ,
      "isdpass": 1,
      "switchuname": "",
      "is_voice_sms": 0,
      "voice_sms_flag": 0,
      "client": "",
      "isupsms": "",
      "channelid": "",
      "smsvcodesign": smsvcodesign,
      "smsvcodestr": smsvcodestr,
    };

    var loginRes = await dio.post(LOGIN_POST_URL,
        data: data,
        options: Options(headers: {
          "Referer": BAIDU_URL,
          "Content-Type": "application/x-www-form-urlencoded"
        }, responseType: ResponseType.plain));
    var errNo = RegExp(r"(?<=err_no=)(.+?)(?=&)").firstMatch(loginRes.data)![0];
    //需要安全验证时，初始化安全验证类
    if (errNo == "120021") {
      authVerifyManager.init(loginRes.data);
    }
    if (errNo == "0") {
      isLogin = true;
    }
    return BaiduErroNo.parse(errNo!);
  }

  ///模拟WAP端的手机短信登陆
  Future<LoginErrCode> wapLoginByPhone(String phoneNumber, String vCode) async {
    if (isLogin) {
      //删除cookie和token
      await cookieJar.deleteAll();
      token = "";
      isLogin = false;
    }
    var cookies =
        (await cookieJar.loadForRequest(Uri.parse(BAIDU_URL))).toString();
    //没有BAIDUID就浏览百度首页,以设置BAIDUID等Cookie
    if (!cookies.contains("BAIDUID")) {
      await dio.get(BAIDU_URL);
    }
    String baiduID = "";
    for (var cookie in (await cookieJar.loadForRequest(Uri.parse(BAIDU_URL)))) {
      if (cookie.name.toUpperCase() == "BAIDUID") {
        baiduID = cookie.value;
        break;
      }
    }
    //获取uid
    var check = await checkAccount(phoneNumber, baiduID);
    if (check.errno != 110000) {
      throw Exception(check.errmsg ?? "登陆失败");
    }
    //提交登陆POST
    var gid = _guideRandom();
    var time = DateTime.now().millisecondsSinceEpoch;
    var sigArgs = {
      "adapter": "",
      "alg": "v3",
      "autoExecute": 0,
      "baiduId": baiduID,
      "client": "",
      "clientfrom": ",",
      "countrycode": "",
      "encryptedId": check.data!.uid!,
      "encryptedType": "living",
      "extrajson": "",
      "from": "sms",
      "fuid": fuid.fuid,
      "gid": gid,
      "isVoiceSmsLogin": 0,
      "lang": "zh-cn",
      "liveAbility": "",
      "loginFrom": "",
      "loginmerge": "",
      "passAppHash": "",
      "passAppVersion": "",
      "regfrom": "page",
      "session_id": "$gid-v2-$time-insert_account",
      "sms": 1,
      "smsvc": vCode,
      "subpro": "",
      "supFaceLogin": "",
      "suppWapFace": 1,
      "suppcheck": "",
      "supportCheck": "",
      "time": time ~/ 1000,
      "tpl": "pp_demo",
      "tt": time,
      "u": WAP_URL,
      "username": phoneNumber,
    };
    var args = {
      "adapter": "",
      "alg": "v3",
      "autoExecute": 0,
      "baiduId": baiduID,
      "client": "",
      "clientfrom": ",",
      "countrycode": "",
      "elapsed": DateTime.now().millisecondsSinceEpoch - time,
      "encryptedId": check.data!.uid!,
      "encryptedType": "living",
      "extrajson": "",
      "from": "sms",
      "fuid": fuid.fuid,
      "gid": gid,
      "isVoiceSmsLogin": 0,
      "lang": "zh-cn",
      "liveAbility": "",
      "loginFrom": "",
      "loginmerge": "",
      "passAppHash": "",
      "passAppVersion": "",
      "regfrom": "page",
      "rinfo": {"fuid": "${md5.convert(utf8.encode(fuid.fuid)).toString()}"},
      "session_id": "$gid-v2-$time-insert_account",
      "shaOne": _getshaOne(time),
      "sig": _getSig(_mapSrot(sigArgs)),
      "sms": 1,
      "smsvc": vCode,
      "subpro": "",
      "supFaceLogin": "",
      "suppWapFace": 1,
      "suppcheck": "",
      "supportCheck": "",
      "time": time ~/ 1000,
      "tpl": "pp_demo",
      "tt": time,
      "u": WAP_URL,
      "username": phoneNumber,
    };
    var res = await dio.post(WAP_LOGIN_URL,
        data: args,
        options: Options(
            responseType: ResponseType.plain,
            contentType: "application/x-www-form-urlencoded"));
    var resJson = json5Decode(res.data);
    return LoginErrCode(
        errcode: resJson["errInfo"]["no"], msg: resJson["errInfo"]["msg"]);
  }

  ///wap端account加密
  ///逆向于app.099ff655.js:formatted:761 B = function(e){}
  ///vendor.4be91022.js:formatted: 13486 encrypt: function(t, e, n, r) {}
  String _encryptedAccount(String phoneNumber) {
    String front = ""; //加密向量
    // var wordList = [
    //   1298692218,
    //   1265134637,
    //   1885434739,
    //   762343541,
    //   1764583013,
    //   761357683,
    //   762013049,
    //   758132785
    // ];
    var passWord = "MhxzKhl-pass-ppui-fe-aes-key-001"; //密码，由WordList转化
    var n = "0123456789abcdef".split("");
    for (var i = 0; i < 16; i++) {
      front += n[Random().nextInt(15)];
    }
    var randomIV = IV.fromUtf8(front);
    var phoneNumberEncrypted =
        Encrypter(AES(Key.fromUtf8(passWord), mode: AESMode.ctr, padding: null))
            .encrypt(phoneNumber, iv: randomIV)
            .base64;
    return base64Encode(utf8.encode(front + phoneNumberEncrypted));
  }

  ///WAP端，检查账号状态
  Future<WapAccountCheck> checkAccount(String account, String baiduID) async {
    var time = DateTime.now().millisecondsSinceEpoch;
    var gid = _guideRandom();
    var sigParams = {
      "account": _encryptedAccount(account),
      "acct_crypt": 20,
      "adapter": "",
      "alg": "v3",
      "baiduId": baiduID,
      "client": "",
      "clientfrom": "",
      "codeMobile": "",
      "countryCode": "",
      "extrajson": "",
      "fuid": fuid.fuid,
      "gid": gid,
      "lang": "zh-cn",
      "liveAbility": "",
      "session_id": "$gid-v2-$time-insert_account",
      "subpro": "",
      "supFaceLogin": "",
      "suppWapFace": 1,
      "suppcheck": "",
      "supportCheck": "",
      "time": time ~/ 1000,
      "tpl": "pp_demo",
      "tt": time,
      "u": WAP_URL
    };
    var args = {
      "account": _encryptedAccount(account),
      "acct_crypt": 20,
      "adapter": "",
      "alg": "v3",
      "baiduId": baiduID,
      "client": "",
      "clientfrom": "",
      "codeMobile": "",
      "countryCode": "",
      "elapsed": DateTime.now().millisecondsSinceEpoch - time,
      "extrajson": "",
      "fuid": fuid.fuid,
      "gid": gid,
      "lang": "zh-cn",
      "liveAbility": "",
      "rinfo": {"fuid": "${md5.convert(utf8.encode(fuid.fuid)).toString()}"},
      "session_id": "$gid-v2-$time-insert_account",
      "shaOne": _getshaOne(time),
      "sig": _getSig(_mapSrot(sigParams)),
      "subpro": "",
      "supFaceLogin": "",
      "suppWapFace": 1,
      "suppcheck": "",
      "supportCheck": "",
      "time": time ~/ 1000,
      "tpl": "pp_demo",
      "tt": time,
      "u": WAP_URL
    };
    var res = await dio.post(WAP_ACCOUNT_CHECK,
        data: args, options: Options(responseType: ResponseType.plain));
    return WapAccountCheck.fromJson(json5Decode(res.data));
  }

  ///获取手机号码的状态(是否已经注册)
  Future<PhoneNumberStatus> checkRegPhone(String phoneNumber) async {
    var time = DateTime.now().millisecondsSinceEpoch;
    var gid = _guideRandom();
    //签名的参数
    var sigParams = {
      "token": await _getToken(),
      "tpl": "mn",
      "subpro": "",
      "apiver": "v3",
      "tt": time,
      "gid": gid,
      "phone": phoneNumber,
      "loginversion": "v4",
      "countrycode": "",
      "mobileencryption": "",
      "alg": "v3",
      "time": time ~/ 1000
    };

    var args = {
      "token": await _getToken(),
      "tpl": "mn",
      "subpro": "",
      "apiver": "v3",
      "tt": time,
      "gid": gid,
      "phone": phoneNumber,
      "loginversion": "v4",
      "countrycode": "",
      "mobileencryption": "",
      "traceid": "",
      "time": time ~/ 1000,
      "alg": "v3",
      "sig": _getSig(_mapSrot(sigParams)),
      "elapsed": DateTime.now().millisecondsSinceEpoch - time,
      "shaOne": _getshaOne(time),
      "rinfo": {"fuid": "${md5.convert(utf8.encode(fuid.fuid)).toString()}"}
    };
    var res = await dio.get(GET_PHONE_NUMBER_STATUS,
        queryParameters: args,
        options: Options(responseType: ResponseType.plain));
    var data = PhoneNumberStatus.fromJson(json5Decode(res.data));
    return data;
  }

  ///短信登录发送密码短信
  Future<SendDPass> sendPass(String phoneNumber,
      {bool needVerify = false,
      String? vcodesign,
      String? vcodestr,
      String? verifycode}) async {
    var gid = _guideRandom();
    var time = DateTime.now().millisecondsSinceEpoch;
    var moonshadow =
        md5.convert(utf8.encode(phoneNumber + "Moonshadow")).toString();
    moonshadow = moonshadow
        .replaceFirst("o", "ow")
        .replaceFirst("d", "do")
        .replaceFirst("a", "ad");
    moonshadow = moonshadow
        .replaceFirst("h", "ha")
        .replaceFirst("s", "sh")
        .replaceFirst("n", "ns")
        .replaceFirst("m", "mo");
    //验证码
    var verify = {
      "vcodesign": vcodesign,
      "vcodestr": vcodestr,
      "verifycode": verifycode
    };

    //签名的参数
    var sigParams = {
      "apiver": "v3",
      "bdstoken": await _getToken(),
      "client": "",
      "countrycode": "",
      "ds": passMachine.ds,
      "dv": windowsDv.dv,
      "flag_code": "0",
      "gid": gid,
      "loginVersion": "v4",
      "mkey": "",
      "moonshad": moonshadow,
      "supportdv": "1",
      "tk": passMachine.tk,
      "tpl": "mn",
      "traceid": "",
      "tt": time,
      "username": phoneNumber,
    };
    if (needVerify) {
      verify.forEach(((key, value) {
        sigParams[key] = value!;
      }));
    }
    var args = {
      "gid": gid,
      "username": phoneNumber,
      "countrycode": "",
      "bdstoken": await _getToken(),
      "tpl": "mn",
      "loginVersion": "v4",
      "flag_code": "0",
      "client": "",
      "mkey": "",
      "moonshad": moonshadow,
      "ds": passMachine.ds,
      "tk": passMachine.tk,
      "supportdv": "1",
      "dv": windowsDv.dv,
      "apiver": "v3",
      "tt": time,
      "traceid": "",
      "time": time ~/ 1000,
      "alg": "v3",
      "sig": _getSig(_mapSrot(sigParams)),
      "elapsed": DateTime.now().millisecondsSinceEpoch - time,
      "shaOne": _getshaOne(time),
      "rinfo": {"fuid": "${md5.convert(utf8.encode(fuid.fuid)).toString()}"}
    };
    if (needVerify) {
      verify.forEach(((key, value) {
        args[key] = value!;
      }));
    }
    var res = await dio.get(LOGIN_SEND_PASS,
        queryParameters: args,
        options: Options(responseType: ResponseType.plain));
    //数据外围会多一对括号...
    var resJson = SendDPass.fromJson(
        json5Decode((res.data as String).substring(1, res.data.length - 1)));
    return resJson;
  }

  ///获取连接的token
  Future<String> _getToken() async {
    if (token != "") {
      return token;
    }
    var time = new DateTime.now().millisecondsSinceEpoch;
    var gid = _guideRandom();
    var shaOne = _getshaOne(time);
    //参数的顺序要按照字典顺序排列
    var signParams = {
      'alg': 'v3',
      'apiver': 'v3',
      'gid': gid,
      'loginversion': 'v4',
      'subpro': '',
      'time': (time / 1000).ceil(),
      'token': '',
      'tpl': 'mn',
      'tt': time
    };
    Response res = await dio.get(TOKEN_GET_URL,
        queryParameters: {
          'token': '',
          'subpro': '',
          'traceid': '',
          'tpl': 'mn',
          'tt': time,
          'apiver': 'v3',
          'class': 'login',
          'gid': gid,
          'loginversion': 'v4',
          'logintype': 'dialogLogin',
          'time': (time / 1000).ceil(),
          'alg': 'v3',
          'sig': _getSig(signParams),
          'shaOne': shaOne,
          'elapsed':
              (new DateTime.now().millisecondsSinceEpoch - time).toString(),
          //'callback': 加上callback参数会返回jsonp格式的数据，不加直接返回json格式(用了单引号，不标准)的数据，这里不需要
        },
        options: Options(headers: {
          'Referer': BAIDU_URL,
        }, responseType: ResponseType.plain));
    var resJson = JSON5.parse(res.data);
    token = resJson['data']['token'];
    return resJson['data']['token'];
  }

  //获取随机的gid
  String _guideRandom() {
    if (_gid != "") {
      return _gid;
    }
    String gid = "xxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx";
    gid = gid.replaceAllMapped(RegExp(r"[xy]"), (Match m) {
      final t = Random().nextInt(15);
      final n = "x" == m[0] ? t : 3 & t | 8;
      return n.toRadixString(16).toUpperCase();
    });
    _gid = gid;
    return _gid;
  }

  String _getshaOne(int time) {
    dynamic result = time;
    do {
      result = _encryptDecode(_baiduSha1(_shaOneEncrypt1(
          md5.convert(utf8.encode(result.toString())).toString())));
    } while (result.toString().substring(0, 2) != "00");
    return result;
  }

  //百度moonshad.js逆向出来的算法 function _0x51bb0b(_0x61f75a)
  List<int> _shaOneEncrypt1(String str) {
    var len = (str.length + 0x8 >> 0x6) + 0x1,
        result = List<int>.filled(len * 0x10, 0);
    int pos;
    for (pos = 0x0; pos < str.length; pos++) {
      result[pos >> 0x2] |= str.codeUnitAt(pos) << 0x18 - (pos & 0x3) * 0x8;
    }
    result[pos >> 0x2] |= (0x80 << 0x18).toSigned(32) - (pos & 0x3) * 0x8;

    result[len * 0x10 - 0x1] = str.length * 0x8;
    return result;
  }

  //百度moonshad.js逆向出来的算法 function _0x51aec1(_0x7281fc)
  //感觉像是一个魔改过的sha1,不是标准的sha1
  List<int> _baiduSha1(List<int> arg) {
    var A = arg,
        B = List<int>.filled(0x50, 0),
        C = 0x67452301,
        D = -0x10325477,
        E = -0x67452302,
        F = 0x10325476,
        G = -0x3c2d1e10;
    for (var i = 0x0; i < A.length; i += 0x10) {
      var H = C, I = D, J = E, K = F, L = G;
      for (var j = 0x0; j < 0x50; j++) {
        if (j < 0x10)
          B[j] = A[i + j];
        else
          B[j] = _baiduSha1Dependence1(
              B[j - 0x3] ^ B[j - 0x8] ^ B[j - 0xe] ^ B[j - 0x10], 0x1);
        var M = _baiduSha1Dependence2(
            _baiduSha1Dependence2(_baiduSha1Dependence1(C, 0x5),
                _baiduSha1Dependence3(j, D, E, F)),
            _baiduSha1Dependence2(
                _baiduSha1Dependence2(G, B[j]), _baiduSha1Dependence4(j)));
        G = F;
        F = E;
        E = _baiduSha1Dependence1(D, 0x1e);
        D = C;
        C = M;
      }
      C = _baiduSha1Dependence2(C, H);
      D = _baiduSha1Dependence2(D, I);
      E = _baiduSha1Dependence2(E, J);
      F = _baiduSha1Dependence2(F, K);
      G = _baiduSha1Dependence2(G, L);
    }
    return [C, D, E, F, G];
  }

  //百度moonshad.js逆向出来的算法 function _0x3f0903(_0x2f7618, _0x594838)
  int _baiduSha1Dependence1(int n, int k) {
    //js位运算整型会变成32位导致溢出,dart始终是64位不溢出,会导致最终计算结果不一致,需要手动转化为32位整型表示
    return (n << k).toSigned(32) | n.toUnsigned(32) >> 0x20 - k;
  }

  //百度moonshad.js逆向出来的算法 function _0x1a9129(_0x587918, _0x3d32df)
  int _baiduSha1Dependence2(int n, int k) {
    var a = (n & 0xffff) + (k & 0xffff),
        b = (n >> 0x10) + (k >> 0x10) + (a >> 0x10);
    return (b << 0x10).toSigned(32) | a & 0xffff;
  }

  //百度moonshad.js逆向出来的算法 function _0x2b3e4a(_0x50af6f, _0x54fc01, _0x41845a, _0x416802)
  int _baiduSha1Dependence3(int n, int k, int l, int j) {
    if (n < 0x14) return k & l | ~k & j;
    if (n < 0x28) return k ^ l ^ j;
    if (n < 0x3c) return k & l | k & j | l & j;
    return k ^ l ^ j;
  }

  //百度moonshad.js逆向出来的算法 function _0x40ce9e(_0x555c5f)
  int _baiduSha1Dependence4(int n) {
    return n < 0x14
        ? 0x5a827999
        : n < 0x28
            ? 0x6ed9eba1
            : n < 0x3c
                ? -0x70e44324
                : -0x359d3e2a;
  }

  //百度moonshad.js逆向出来的算法 function _0x33bcab(_0x2da4f0)
  String _encryptDecode(List<int> arg) {
    var charTable = "0123456789abcdef";
    var result = '';
    for (var pos = 0x0; pos < arg.length * 0x4; pos++) {
      result +=
          charTable[(arg[pos >> 0x2] >> (0x3 - pos % 0x4) * 0x8 + 0x4 & 0xf)] +
              charTable[(arg[pos >> 0x2] >> (0x3 - pos % 0x4) * 0x8 & 0xf)];
    }
    return result;
  }

  //百度moonshad.js逆向出来的算法 function(_0x48da8a, _0x150142, _0x22f5a6)
  //sig签名算法 params参数要按照字典顺序排序
  String _getSig(Map<String, dynamic> params) {
    final alphaTable = {
      "0": "s",
      "1": "t",
      "2": "r",
      "3": "h",
      "4": "i",
      "5": "j",
      "6": "k",
      "7": "l",
      "8": "m",
      "9": "n",
      "a": "3",
      "b": "4",
      "c": "5",
      "d": "9",
      "e": "8",
      "f": "7",
      "g": "1",
      "h": "2",
      "i": "6",
      "j": "0",
      "k": "a",
      "l": "b",
      "m": "c",
      "n": "d",
      "o": "e",
      "p": "f",
      "q": "g",
      "r": "z",
      "s": "y",
      "t": "x",
      "u": "w",
      "v": "v",
      "w": "u",
      "x": "o",
      "y": "p",
      "z": "q"
    };
    //sig的aes加密key有5个，每天用同一个,根据时间确定用哪个
    final tableAESKey = <String>[
      "moonshad5moonsh2",
      "moonshad3moonsh0",
      "moonshad8moonsh6",
      "moonshad0moonsh1",
      "moonshad1moonsh9"
    ];
    //获取自1970/1/1开始经过的天数
    var daySinceEpoch = (DateTime.now().millisecondsSinceEpoch ~/ 86400000);
    String str = tableAESKey[daySinceEpoch % 5];
    //将参数转化为url链接的形式(用&连接)
    var paramList = <String>[];
    for (var key in params.keys) {
      paramList.add("$key=${params[key]}");
    }
    String urlParams = paramList.join("&");
    //md5加密参数
    var md5Params = md5.convert(utf8.encode(urlParams)).toString();
    //取屏幕宽高映射成用于插入的字符串
    String windowWidthAndHeight = window.physicalSize.width.toInt().toString() +
        window.physicalSize.height.toInt().toString();
    String stringInsert = windowWidthAndHeight.replaceAllMapped(
        RegExp(r"[0-9]"), (match) => "${alphaTable[match[0]]}");
    //插入字符串
    var strInserted = "";
    if (md5Params.length >= stringInsert.length) {
      for (int i = 0; i < stringInsert.length; i++) {
        strInserted += md5Params[i] + stringInsert[i];
      }
      strInserted += md5Params.substring(stringInsert.length);
    } else {
      for (int i = 0; i < md5Params.length; i++) {
        strInserted += md5Params[i] + stringInsert[i];
      }
      strInserted += stringInsert.substring(md5Params.length);
    }
    //加密
    var base64AES = Encrypter(AES(Key.fromUtf8(str), mode: AESMode.ecb))
        .encrypt(strInserted, iv: IV.fromLength(0))
        .base64;
    var sig = base64Encode(utf8.encode(base64AES));
    return sig;
  }

  Future<RSAKEY> _getRSAKey() async {
    var time = new DateTime.now().millisecondsSinceEpoch;
    var gid = _guideRandom();
    var shaOne = _getshaOne(time);
    //参数的顺序要按照字典顺序排列
    var signParams = {
      'alg': 'v3',
      'apiver': 'v3',
      'gid': gid,
      'loginversion': 'v4',
      'subpro': '',
      'time': (time / 1000).ceil(),
      'token': '',
      'tpl': 'mn',
      'tt': time
    };
    Response res = await dio.get(PUB_KEY_URL,
        queryParameters: {
          'token': await _getToken(),
          'subpro': '',
          'traceid': '',
          'tpl': 'mn',
          'tt': time,
          'apiver': 'v3',
          'class': 'login',
          'gid': gid,
          'loginversion': 'v4',
          'logintype': 'dialogLogin',
          'time': (time / 1000).ceil(),
          'alg': 'v3',
          'sig': _getSig(signParams),
          'shaOne': shaOne,
          'elapsed':
              (new DateTime.now().millisecondsSinceEpoch - time).toString(),
          //'callback': 加上callback参数会返回jsonp格式的数据，不加直接返回json格式(用了单引号，不标准)的数据，这里不需要
        },
        options: Options(
            responseType: ResponseType.plain, headers: {"Referer": BAIDU_URL}));
    var key = RSAKEY.fromJson(json5Decode(res.data));
    return key;
  }

//模拟生成百度登陆的traceid
//逆向于loginv5.js
  String _getTraceID() {
    if (_traceID != "") {
      return _traceID;
    }
    String headID =
        (DateTime.now().millisecondsSinceEpoch + (Random().nextInt(9) + 90))
            .toRadixString(16);
    headID = headID.substring(headID.length - 6, headID.length).toUpperCase();
    _traceID = headID + "01";
    return headID + "01"; //登陆结尾为01，注册结尾为02
  }

  String getTraceID() => _getTraceID();

  //map按照key的字典顺序排序
  Map<String, dynamic> _mapSrot(Map<String, dynamic> map) {
    var keys = map.keys.toList();
    // key排序
    keys.sort((a, b) {
      List<int> al = a.codeUnits;
      List<int> bl = b.codeUnits;
      for (int i = 0; i < al.length; i++) {
        if (bl.length <= i) return 1;
        if (al[i] > bl[i]) {
          return 1;
        } else if (al[i] < bl[i]) return -1;
      }
      return 0;
    });
    var sortedMap = Map<String, dynamic>();
    keys.forEach((element) {
      sortedMap[element] = map[element];
    });
    return sortedMap;
  }

  //获取随机参数
  Future<String> _getTBS() async {
    return await tbsMagager.getTBS();
  }

  ///获取关注的贴吧
  Future<List<LikeForumInfo>?> getLikes() async {
    return await userInfomation.likes;
  }

  Future<int?> getUID() async {
    return await userInfomation.uid;
  }

  ///签到所有关注的贴吧
  Future<void> signAll() async {
    if (isLogin == false) {
      throw Exception("未登录");
    }
    //一键签到(7级以上)
    await dio.post(ONE_KEY_SIGN_IN,
        data: {"tbs": await _getTBS(), "ie": "utf-8"},
        options: Options(headers: {
          "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
          "Origin": TIEBA_URL
        }));
    //签到剩下的
    await userInfomation.refresh();
    var forums = await getLikes();
    if (forums != null) {
      //统计已经签到吧的个数
      int totalSigned = 0;
      int totoal = forums.length;
      for (var forum in forums) {
        if (forum.isSign == "1") {
          totalSigned++;
        }
      }
      for (var forum in forums) {
        if (forum.isSign == "0") {
          await Global.showNotification(
              0, "正在一键签到中...($totalSigned/$totoal)", "正在签到${forum.forumName}吧");
          totalSigned++;
          var reslut = await signOneForum(forum.forumName!);
          await Global.showNotification(
              0, "正在一键签到中...($totalSigned/$totoal)", reslut["TiebananaMsg"]);
          await Future.delayed(Duration(seconds: 1));
        }
      }
    }
    Global.localNotifications.cancel(0);
  }

  Future<Map> signOneForum(String kw) async {
    if (isLogin == false) {
      throw Exception("未登录");
    }
    var args = {
      "BDUSS": bduss,
      "kw": kw,
      "net_type": 1,
      "tbs": await _getTBS()
    };
    args["sign"] = _signArgs(args);
    Response res;
    Map<String, dynamic> resJson;
    try {
      res = await dio.post(FORUM_SIGN_IN,
          data: args,
          options: Options(headers: {
            "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
          }, responseType: ResponseType.plain));
      resJson = json5Decode(res.data);
    } catch (e) {
      return {"TiebananaMsg": "$kw吧签到失败"};

      // return "$kw吧签到失败";
    }

    if (resJson["error_code"] == "0") {
      if (resJson.containsKey("error")) {
        // return "${resJson["error"]["usermsg"]},$kw吧签到失败";
        resJson["TiebananaMsg"] = "$kw吧签到失败";
        return resJson;
      }
      if (resJson["user_info"]["is_sign_in"] == 1) {
        resJson["TiebananaMsg"] =
            "签到成功,你是今天第${(resJson["user_info"]["user_sign_rank"] as num).toInt()}个签到的,经验+${(resJson["user_info"]["sign_bonus_point"] as num).toInt()}";
        return resJson;
      }
    }
    resJson["TiebananaMsg"] = "$kw吧签到失败";
    // return "$kw吧签到失败";
    return resJson;
  }

  ///sign签名算法
  String _signArgs(Map<String, dynamic> map) {
    var sortedmap = _mapSrot(map);
    var str = "";
    for (var key in sortedmap.keys) {
      str += "$key=${sortedmap[key]}";
    }
    str += "tiebaclient!!!";
    return md5.convert(utf8.encode(str)).toString();
  }

  ///主页-获取动态贴
  ///
  ///[pageThreadCount]一页有多少帖子
  ///
  ///[pn]第几页
  Future<List<ThreadRecommendSummary>> getRecommThread(
      int pageThreadCount, int pn) async {
    if (isLogin == false) {
      throw Exception("未登录");
    }
    var args = {
      "BDUSS": bduss,
      "page_thread_count": pageThreadCount,
      "pn": pn,
      "pre_ad_thread_count": 0,
      "request_time": DateTime.now().millisecondsSinceEpoch,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "invoke_source": "",
      "load_type": 1,
      "_client_version": "8.0.8.0",
    };
    args['sign'] = _signArgs(args);
    var res = await dio.post(FORUM_DYNMANIC,
        data: args,
        options: Options(
            responseType: ResponseType.plain,
            headers: {"Content-Type": "application/x-www-form-urlencoded"}));
    var resJson = json5Decode(res.data);
    if (resJson['error_code'] != "0") {
      throw Exception("获取失败");
    }
    List<ThreadRecommendSummary> threads = [];
    for (var thread in resJson['thread_list']) {
      if ((thread as Map<String, dynamic>).containsKey("lego_card")) {
        continue;
      }
      var t = ThreadRecommendSummary.fromJson(thread);
      threads.add(t);
    }
    return threads;
  }

  ///主页-获取回复
  ///
  ///[pn]页码
  Future<ReplyMessage> getReply(int pn) async {
    if (isLogin == false) {
      throw Exception("未登录");
    }
    var args = {
      "BDUSS": bduss,
      "pn": pn,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "_client_version": "8.2.2",
    };
    args['sign'] = _signArgs(args);
    var res = await dio.post(GET_REPLY,
        data: args,
        options: Options(
            responseType: ResponseType.plain,
            headers: {"Content-Type": "application/x-www-form-urlencoded"}));
    var resJson = json5Decode(res.data);
    if (resJson['error_code'] != "0") {
      throw Exception("获取失败");
    }
    ReplyMessage replyMessage = ReplyMessage.fromJson(resJson);
    return replyMessage;
  }

  ///主页-获取@
  ///
  ///[pn]页码
  Future<AtMeMessage> getAtMe(int pn) async {
    if (isLogin == false) {
      throw Exception("未登录");
    }
    var args = {
      "BDUSS": bduss,
      "pn": pn,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "_client_version": "8.2.2",
    };
    args['sign'] = _signArgs(args);
    var res = await dio.post(GET_ATME,
        data: args,
        options: Options(
            responseType: ResponseType.plain,
            headers: {"Content-Type": "application/x-www-form-urlencoded"}));
    var resJson = json5Decode(res.data);
    if (resJson['error_code'] != "0") {
      throw Exception("获取失败");
    }
    AtMeMessage replyMessage = AtMeMessage.fromJson(resJson);
    return replyMessage;
  }

  Future<MyUserData> getMyInfo() async {
    if (isLogin == false) {
      throw Exception("未登录");
    }
    var res = await dio.get(GET_MY_USER_INFO);
    var resJson = MyUserInfo.fromJson(res.data);
    if (resJson.error == "success") {
      return resJson.data!;
    } else {
      throw Exception("出现异常,errono=${resJson.no},erro=${resJson.error}");
    }
  }

  ///获取吧页面信息
  ///
  ///[sortType] 0 - 回复时间顺序
  ///
  ///1 - 发帖时间
  ///
  ///2 - 关注的人
  ///
  ///[isgood] - 精品贴
  ///[cid] - 精品贴分类
  Future<ForumHomeInfo> getForumPage(
      {required String kw,
      required int pn,
      int rn = 20,
      int sortType = 0,
      bool isgood = false,
      int cid = 0}) async {
    if (isLogin == false) {
      throw Exception("未登录");
    }
    var args = {
      "BDUSS": bduss,
      "kw": kw,
      "pn": pn,
      "rn": rn,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "_client_version": "8.2.2",
      "sort_type": sortType
    };
    if (isgood) {
      args["is_good"] = "1";
      args["cid"] = cid;
    }
    args['sign'] = _signArgs(args);
    var res = await dio.post(GET_FORUM_PAGE,
        data: args,
        options: Options(responseType: ResponseType.bytes, //这个bytes有点故事
            headers: {"Content-Type": "application/x-www-form-urlencoded"}));
    var resJson = json5Decode(String.fromCharCodes(res.data));
    if (resJson['error_code'] != "0") {
      throw Exception("获取失败,${resJson["error_msg"]}");
    }
    return ForumHomeInfo.fromJson(resJson);
  }

  ///获取贴页面
  ///
  ///[kz] - 贴子ID
  ///
  ///[onlyLz] - 只看楼主
  Future<ThreadPageData> getThreadPage(String kz,
      {int pn = 1, int rn = 30, bool onlyLz = false}) async {
    if (isLogin == false) {
      throw Exception("未登录");
    }
    var args = {
      "BDUSS": bduss,
      "_client_id": "",
      "_client_type": "2",
      "_client_version": "9.9.8.32",
      "_phone_imei": "000000000000000",
      "back": "0",
      "cuid": "baidutiebaapp" + Uuid().v4(),
      "cuid_galaxy2": "",
      "cuid_gid": "",
      "floor_rn": "3",
      "kz": kz,
      "lz": onlyLz ? "1" : "0",
      "mark": "0",
      "net_type": "1",
      "pn": pn,
      "rn": rn,
      "st_type": "tb_frslist",
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "with_floor": "1",
    };
    args['sign'] = _signArgs(args);
    var res = await dio.post(F_PAGE,
        data: args,
        options: Options(
            responseType: ResponseType.plain,
            contentType: "application/x-www-form-urlencoded",
            headers: {
              "User-Agent": "bdtb for Android 9.9.8.32",
            }));
    var resJson = json5Decode(res.data);
    if (resJson["error_code"] != "0") {
      throw Exception(resJson["error_msg"]);
    }
    return ThreadPageData.fromJson(resJson);
  }

  ///点赞API
  ///
  ///[objType] = 1,给楼层点赞/踩
  ///[objType] = 2,给楼中楼点赞/踩
  ///[objType] = 3,给贴点赞/踩
  ///
  ///[opType] = 0,点赞/踩
  ///[opType] = 1,取消点赞/踩
  ///
  ///[agreeType] = 2,点赞
  ///[agreeType] = 5,点踩
  Future<void> agreePost(String postID, String threadID, int objType,
      {int agreeType = 2, int opType = 0}) async {
    if (isLogin == false) {
      throw Exception("未登录");
    }
    var args = {
      "BDUSS": bduss,
      "_client_version": "12.15.1.0",
      "_phone_imei": "000000000000000",
      "agree_type": agreeType,
      "c3_aid": "",
      "cuid": "baidutiebaapp" + Uuid().v4(),
      "cuid_galaxy2": "",
      "cuid_gid": "",
      "obj_type": objType,
      "op_type": opType,
      "post_id": postID,
      "start_scheme": "",
      "stoken": stoken,
      "tbs": await tbsMagager.getTBS(),
      "thread_id": threadID,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    args['sign'] = _signArgs(args);
    var res = await dio.post(AGREE_URL,
        data: args,
        options: Options(
          responseType: ResponseType.plain,
          contentType: "application/x-www-form-urlencoded",
        ));
    var resJson = json5Decode(res.data);
    if (resJson["error_code"] != "0") {
      throw Exception(resJson["error_msg"]);
    }
  }

  ///搜索吧API
  Future<SearchForumModel> searchForum(String keywords, int pn,
      {int rn = 10}) async {
    var params = {"pn": pn, "rn": rn, "is_ajax": 1, "word": keywords};
    var res = await dio.get(SEARCH_FORUM,
        queryParameters: params,
        options: Options(responseType: ResponseType.plain));
    return SearchForumModel.fromJson(json5Decode(res.data));
  }

  @deprecated

  ///网页端,搜索贴API,用起来会有网页的转义字符，author值为null等问题,建议使用searchPost
  Future<SearchThreadModel> searchThread(String keywords, int pn,
      {int rn = 10, int sort = 1}) async {
    var params = {
      "pn": pn,
      "rn": rn,
      "is_ajax": 1,
      "sort": sort,
      "word": keywords
    };
    var res = await dio.get(SEARCH_THREAD,
        queryParameters: params,
        options: Options(responseType: ResponseType.plain));
    return SearchThreadModel.fromJson(json5Decode(res.data));
  }

  ///网页端搜索贴API
  ///[order] = 0，旧贴在前排序, = 1新贴在前排序, = 2 相关度排序
  ///
  ///[filter] = 1,只看主题帖, = 0 查看全部贴
  Future<SearchPostModel> searchPost(String keywords,
      {int pn = 1, int order = 0, int filter = 1, int ct = 2}) async {
    var args = {
      "word": keywords,
      "pn": pn,
      "st": order,
      "tt": filter,
      "ct": ct
    };
    var res = await dio.get(WEB_SEARCH_POST,
        queryParameters: args,
        options: Options(responseType: ResponseType.plain));
    return SearchPostModel.fromJson(json5Decode(res.data));
  }

  ///WAP端-回帖API
  Future<WAPTiebaBase> replyThread(
      String content, String kw, String fid, String tid,
      {List<String>? photos}) async {
    if (isLogin == false) {
      throw Exception("未登录");
    }
    //获取baiduID
    String baiduID = "";
    for (var cookie in (await cookieJar.loadForRequest(Uri.parse(BAIDU_URL)))) {
      if (cookie.name.toUpperCase() == "BAIDUID") {
        baiduID = cookie.value;
        break;
      }
    }
    var args = {
      "BDUSS": bduss,
      "_client_type": "2",
      "_client_version": "12.15.1.0",
      "_phone_imei": "000000000000000",
      "active_timestamp": DateTime.now().millisecondsSinceEpoch,
      "anonymous": "1",
      "authsid": "null",
      "baiduid": baiduID,
      "barrage_time": "0",
      "brand": "Android",
      "c3_aid": "",
      "can_no_forum": "0",
      "cmode": "1",
      "content": content,
      "cuid": "baidutiebaapp" + Uuid().v4(),
      "cuid_galaxy2": "",
      "cuid_gid": "",
      "entrance_type": "0",
      "fid": fid,
      "is_ad": "0",
      "is_barrage": "0",
      "is_feedback": "0",
      "is_teenager": "0",
      "kw": kw,
      "reply_uid": "null",
      "stoken": stoken,
      "takephoto_num": photos == null ? 0 : photos.length,
      "tbs": await tbsMagager.getTBS(),
      "tid": tid,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "v_fid": "",
      "v_fname": "",
    };
    args['sign'] = _signArgs(args);
    var res = await dio.post(WAP_POST_REPLY,
        data: args,
        options: Options(
          responseType: ResponseType.plain,
          contentType: "application/x-www-form-urlencoded",
        ));
    var result = json5Decode(res.data);
    if (result["error_code"] != 0) {
      return WAPTiebaBase(
          errcode: result["error_code"], msg: result["error_msg"]);
    }
    return WAPTiebaBase.fromJson(result);
  }

  ///WAP端-回复楼层API
  ///
  ///[content] 回复用户格式 #(reply, [portrait]-头像地址, [name_show]) 若使用回复用户，必须填写replyUID参数
  ///
  ///表情包 #([emoji])
  ///图片 #(pic,图片ID,宽，高)
  Future<WAPTiebaBase> replyFloor(
      String content, String kw, String fid, String tid, String floorId,
      {List<String>? photos, String replyUID = ""}) async {
    if (isLogin == false) {
      throw Exception("未登录");
    }
    //获取baiduID
    String baiduID = "";
    for (var cookie in (await cookieJar.loadForRequest(Uri.parse(BAIDU_URL)))) {
      if (cookie.name.toUpperCase() == "BAIDUID") {
        baiduID = cookie.value;
        break;
      }
    }
    var args = {
      "BDUSS": bduss,
      "_client_type": "2",
      "_client_version": "12.15.1.0",
      "_phone_imei": "000000000000000",
      "active_timestamp": DateTime.now().millisecondsSinceEpoch,
      "anonymous": "1",
      "authsid": "null",
      "baiduid": baiduID,
      "brand": "Android",
      "c3_aid": "",
      "can_no_forum": "0",
      "cmode": "1",
      "content": content,
      "cuid": "baidutiebaapp" + Uuid().v4(),
      "cuid_galaxy2": "",
      "cuid_gid": "",
      "entrance_type": "0",
      "fid": fid,
      "is_ad": "0",
      "is_twzhibo_thread": "0",
      "is_giftpost": "0",
      "is_addition": "0",
      "is_feedback": "0",
      "is_teenager": "0",
      "kw": kw,
      "reply_uid": replyUID,
      "stoken": stoken,
      "takephoto_num": photos == null ? 0 : photos.length,
      "tbs": await tbsMagager.getTBS(),
      "tid": tid,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "v_fid": "null",
      "v_fname": "null",
      "floor_num": "0",
      "quote_id": floorId,
      "repostid": floorId
    };
    args['sign'] = _signArgs(args);
    var res = await dio.post(WAP_POST_REPLY,
        data: args,
        options: Options(
          responseType: ResponseType.plain,
          contentType: "application/x-www-form-urlencoded",
        ));
    var result = json5Decode(res.data);
    if (result["error_code"] != 0) {
      return WAPTiebaBase(
          errcode: result["error_code"], msg: result["error_msg"]);
    }
    return WAPTiebaBase.fromJson(result);
  }

  ///获取楼中楼内容
  Future<InnerFloorModel> getInnerFloor(String kz, String pid,
      {String spid = "", int pn = 1, int rn = 20}) async {
    var args = {
      "BDUSS": bduss,
      "_client_version": "12.15.1.0",
      "kz": kz,
      "pn": pn,
      "rn": rn,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "pid": pid,
      "spid": spid
    };
    args['sign'] = _signArgs(args);
    var res = await dio.post(FLOOR_POST_URL,
        data: args,
        options: Options(
          responseType: ResponseType.plain,
          contentType: "application/x-www-form-urlencoded",
        ));
    return InnerFloorModel.fromJson(json5Decode(res.data));
  }

  ///上传图片
  Future<UploadImageModel> uploadPicture(
      String forumName, bool saveOrigin, AssetEntity file) async {
    if (isLogin == false) {
      throw Exception("未登录");
    }
    //获取baiduID
    String baiduID = "";
    for (var cookie in (await cookieJar.loadForRequest(Uri.parse(BAIDU_URL)))) {
      if (cookie.name.toUpperCase() == "BAIDUID") {
        baiduID = cookie.value;
        break;
      }
    }
    var args = {
      "BDUSS": bduss,
      "_client_id": "",
      "_client_type": "2",
      "_client_version": "12.15.1.0",
      "_phone_imei": "000000000000000",
      "active_timestamp": DateTime.now().millisecondsSinceEpoch,
      "alt": "json",
      // "android_id": "", //
      "baiduid": baiduID,
      "brand": "Android",
      "c3_aid": "",
      "chunkNo": "1",
      "cmode": "1",
      "cuid": "baidutiebaapp" + Uuid().v4(),
      "cuid_galaxy2": "",
      "cuid_gid": "",
      // "event_day": "", //
      "forum_name": forumName,
      "height": file.height,
      "width": file.width,
      "isFinish": "1",
      "is_bjh": "0",
      "pic_water_type": 2,
      "resourceId": file.id,
      "saveOrigin": saveOrigin ? "1" : "0",
      "size": await (await file.file)!.length(),
      "small_flow_fname": forumName,
      "stoken": stoken,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };
    args['sign'] = _signArgs(args);
    args["chunk"] =
        await MultipartFile.fromFile((await file.file)!.path, filename: "file");
    var data = FormData.fromMap(args);
    var res = await dio.post(WAP_UPLOAD_PICTURE, data: data);

    return UploadImageModel.fromJson(json5Decode(res.data));
  }

  Future<SearchUserModel> searchUser(String keyword) async {
    var args = {
      "_client_version": "12.15.1.0",
      "word": keyword,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    var res = await dio.get(WEB_SEARCH_USER, queryParameters: args);

    return SearchUserModel.fromJson(res.data);
  }
}
