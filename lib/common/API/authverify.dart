import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:json5/json5.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/Global.dart';

///强制安全验证类
class AuthVerifyManager {
  late Dio dio;
  late String authtoken;
  late String lstr;
  late String ltoken;
  String? authsid;
  String? secret;
  AuthVerifyManager(this.dio);

  ///使用前先初始化
  void init(String data) {
    authtoken = RegExp(r"(?<=authtoken=)(.+?)(?=&)").firstMatch(data)![0]!;
    lstr = RegExp(r"(?<=lstr=)(.+?)(?=&)").firstMatch(data)![0]!;
    ltoken = RegExp(r"(?<=ltoken=)(.+?)(?=&)").firstMatch(data)![0]!;
    authsid = RegExp(r"(?<=&authsid=)(.*?)(?=&)").firstMatch(data)![0]!;
    authtoken = Uri.decodeComponent(authtoken);
    lstr = Uri.decodeComponent(lstr);
    ltoken = Uri.decodeComponent(ltoken);
    authsid = authsid != null ? Uri.decodeComponent(authsid!) : null;
  }

  ///获取验证方式信息
  Future<AuthwidgetverifyRespone> getVerifyData() async {
    var res = await dio.get(AUTH_VERIFY_URL,
        queryParameters: {
          "authtoken": authtoken,
          "type": "",
          "jsonp": 1,
          "apiver": "v3",
          "verifychannel": "",
          "action": "getapi",
          "vcode": "",
          "questionAndAnswer": "",
          "needsid": "",
          "rsakey": "",
          "countrycode": "",
          "subpro": "",
          "u": BAIDU_URL,
          "lstr": lstr,
          "ltoken": ltoken,
          "tpl": "mn",
          "winsdk": "",
          "authAction": "",
          "traceid": Global.tiebaAPI.getTraceID()
        },
        options: Options(responseType: ResponseType.plain));
    //jsonp数据预处理
    String resdata = res.data;
    String data = RegExp("(?<=\"data\":)(.*?)(?:})").firstMatch(resdata)![0]!;
    resdata = resdata.replaceFirst(
        RegExp("(?<=\"data\":)(.*?)(?:})"), _processData(data));
    return AuthwidgetverifyRespone.fromJson(json5Decode(resdata));
  }

  ///验证-发送验证码
  ///
  /// type参数为验证方式，猜测验证类型为[AuthwidgetverifyResponeData]中各个项，共12种验证方式，一般使用mobile，即手机短信验证，目前也只保证手机短信验证有效
  Future<void> sendVerify(
    String type,
  ) async {
    await dio.get(AUTH_VERIFY_URL,
        queryParameters: {
          "authtoken": authtoken,
          "type": type,
          "jsonp": 1,
          "apiver": "v3",
          "verifychannel": "",
          "action": "send",
          "vcode": "",
          "questionAndAnswer": "",
          "needsid": "",
          "rsakey": "",
          "countrycode": "",
          "subpro": "",
          "u": BAIDU_URL,
          "lstr": lstr,
          "ltoken": ltoken,
          "tpl": "mn",
          "secret": secret == null ? "" : secret,
          "winsdk": "",
          "authAction": "",
          "traceid": Global.tiebaAPI.getTraceID()
        },
        options: Options(responseType: ResponseType.plain));
  }

  ///验证函数
  ///type参数为验证方式，猜测验证类型为[AuthwidgetverifyResponeData]中各个项，共12种验证方式，一般使用mobile，即手机短信验证，目前也只保证手机短信验证有效
  ///vocde参数是验证码
  Future<LoginErrCode> Verify(String type, String vcode) async {
    var res = await dio.get(AUTH_VERIFY_URL,
        queryParameters: {
          "authtoken": authtoken,
          "type": type,
          "jsonp": 1,
          "apiver": "v3",
          "verifychannel": "",
          "action": "check",
          "vcode": vcode,
          "questionAndAnswer": "",
          "needsid": "",
          "rsakey": "",
          "countrycode": "",
          "subpro": "",
          "u": BAIDU_URL,
          "lstr": lstr,
          "ltoken": ltoken,
          "tpl": "mn",
          "secret": secret == null ? "" : secret,
          "winsdk": "",
          "authAction": "",
          "traceid": Global.tiebaAPI.getTraceID()
        },
        options: Options(responseType: ResponseType.plain));
    var json = json5Decode(res.data);
    var ret = LoginErrCode(errcode: json["errno"], msg: json["msg"]);
    secret = json["secret"];
    authsid = json["authsid"];
    return ret;
  }

  String _processData(String data) {
    var mobile = RegExp("(?<=\"mobile\":')(.*?)(?='.\\|\\|)").firstMatch(data);
    var verifymobile =
        RegExp("(?<=\"verifymobile\":')(.*?)(?='.\\|\\|)").firstMatch(data);
    var email = RegExp("(?<=\"email\":')(.*?)(?='.\\|\\|)").firstMatch(data);
    var softtoken =
        RegExp("(?<=\"softtoken\":')(.*?)(?='.\\|\\|)").firstMatch(data);
    var password =
        RegExp("(?<=\"password\":')(.*?)(?='.\\|\\|)").firstMatch(data);
    var isUc = RegExp("(?<=\"isUc\":')(.*?)(?='.\\|\\|)").firstMatch(data);
    var historyPassword =
        RegExp("(?<=\"history_password\":')(.*?)(?='.\\|\\|)").firstMatch(data);
    var originalMobile =
        RegExp("(?<=\"original_mobile\":')(.*?)(?='.\\|\\|)").firstMatch(data);
    var originalIdcard =
        RegExp("(?<=\"original_idcard\":')(.*?)(?='.\\|\\|)").firstMatch(data);
    var username =
        RegExp("(?<=\"username\":')(.*?)(?='.\\|\\|)").firstMatch(data);
    var originalEmail =
        RegExp("(?<=\"original_email\":')(.*?)(?='.\\|\\|)").firstMatch(data);
    var originalBankcard = [];
    var bankcards =
        RegExp("(?<=\"original_bankcard\":)(.*?)(?=,)").firstMatch(data);
    if (bankcards != null) {
      var bankcard =
          bankcards[0]!.substring(1, bankcards[0]!.length - 1).split(",");
      for (var card in bankcard) {
        if (card.replaceAll(" ", "") != "") {
          originalBankcard.add(card.replaceAll(" ", ""));
        }
      }
    }
    Map r = {
      "mobile": mobile == null ? "" : mobile[0],
      "verifymobile": verifymobile == null ? "" : verifymobile[0],
      "email": email == null ? "" : email[0],
      "softtoken": softtoken == null ? "" : softtoken[0],
      "password": password == null ? "" : password[0],
      "isUc": isUc == null ? "" : isUc[0],
      "history_password": historyPassword == null ? "" : historyPassword[0],
      "original_mobile": originalMobile == null ? "" : originalMobile[0],
      "original_idcard": originalIdcard == null ? "" : originalIdcard[0],
      "username": username == null ? "" : username[0],
      "original_email": originalEmail == null ? "" : originalEmail[0],
      "original_bankcard": originalBankcard
    };
    return jsonEncode(r);
  }
}
