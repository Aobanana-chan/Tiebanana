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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:json5/json5.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/common/API/LG_DV_ARG.dart';
import 'package:tiebanana/common/API/TBSManager.dart';
import 'package:tiebanana/common/API/UserInfo.dart';
import 'package:tiebanana/common/API/authverify.dart';
import 'package:tiebanana/common/API/fuid.dart';
import 'package:tiebanana/common/API/passMachine.dart';
import 'package:tiebanana/common/Global.dart';
import 'Constants.dart';

class TiebaAPI {
  static Dio dio = new Dio(BaseOptions(headers: {
    "User-Agent": ChromeUA,
    "Connection": "keep-alive",
  }));
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
    }
  }

  //budss简单加密，考虑可能在本地保存
  // ignore: non_constant_identifier_names
  late String _bduss_encrypt;
  set bduss(String str) {
    _bduss_encrypt = Encrypter(AES(
            Key.fromUtf8("d7c2dbf638964f50018b1161e174d8ba"),
            mode: AESMode.ecb))
        .encrypt(str, iv: IV.fromLength(0))
        .base64;
  }

  String get bduss {
    return Encrypter(AES(Key.fromUtf8("d7c2dbf638964f50018b1161e174d8ba"),
            mode: AESMode.ecb))
        .decrypt(Encrypted.fromBase64(_bduss_encrypt), iv: IV.fromLength(0));
  }

  String token = "";
  String _traceID = "";
  String _gid = "";

  WindowsDv windowsDv = WindowsDv();
  PassMachine passMachine = PassMachine(dio);
  FingerPrint fuid = FingerPrint();
  AuthVerifyManager authVerifyManager = AuthVerifyManager(dio);
  TBSMagager tbsMagager = TBSMagager(dio);
  UserInfomation userInfomation = UserInfomation(dio);
  //类在用之前先初始化
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
      };
    }
    //判断是否已经登陆
    Response res = await dio.get(TBS_URL);
    var resJson = TBS.fromJson(jsonDecode(res.data));
    if (resJson.isLogin == 1) {
      isLogin = true;
    } else {
      isLogin = false;
    }
    await passMachine.init();
  }

  //模拟web入口的账号密码登陆
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
      "time": time ~/ 1000
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

  //获取连接的token
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
  void signAll() async {
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
              0, "正在一键签到中...($totalSigned/$totoal)", reslut);
          await Future.delayed(Duration(seconds: 1));
        }
      }
    }
    Global.localNotifications.cancel(0);
  }

  Future<String> signOneForum(String kw) async {
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
      return "$kw吧签到失败";
    }
    if (resJson["error_code"] == "0") {
      if (resJson.containsKey("error")) {
        return "${resJson["error"]["usermsg"]},$kw吧签到失败";
      }
      if (resJson["user_info"]["is_sign_in"] == 1) {
        return "签到成功,你是今天第${(resJson["user_info"]["user_sign_rank"] as num).toInt()}个签到的,经验+${(resJson["user_info"]["sign_bonus_point"] as num).toInt()}";
      }
    }
    return "$kw吧签到失败";
  }

  //sign签名算法
  String _signArgs(Map<String, dynamic> map) {
    var sortedmap = _mapSrot(map);
    var str = "";
    for (var key in sortedmap.keys) {
      str += "$key=${sortedmap[key]}";
    }
    str += "tiebaclient!!!";
    return md5.convert(utf8.encode(str)).toString();
  }
}
