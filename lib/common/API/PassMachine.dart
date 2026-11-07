import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:encrypt/encrypt.dart' as ecpt;
import 'package:json5/json5.dart';

import 'Constants.dart';
import 'package:dio/dio.dart';
import 'package:tiebanana/Json_Model/json.dart';

///百度验证码类
class PassMachine {
  Dio dio;
  final ak = "1e3f2dd1c81f2075171a547893391274"; //固定值,该值来自loginv5.js
  String as = "6bffae1c"; //默认值6bffae1c，需要请求一次拿到正确的值
  var _rzdata = {
    //记录操作行为
    "cl": [], //click 鼠标点击
    "mv": [], //move 鼠标移动
    "sc": [], //猜测是scroll 待验证
    "kb": [], //猜测是keybord 待验证
    "sb": [], //猜不出
    "sd": [], //猜不出
    "sm": [], //猜不出
    "cr": {}, //界面宽高参数
    "simu": 0, //window.navigator.webdriver ? 1 : 0,
    "ac_c": 0 //滑条的百分比，应该是最主要判断验证码对不对的参数，对应给图片旋转360*ac_c度
  };
  late String tk; //需要请求一次拿到正确的值
  late String ds; //需要请求一次拿到正确的值
  final _cv = "submit"; //固定值
  late String backstr; //从getstyle请求中获取

  final String _nameR = "appsapi0"; //用于加密sb->fs的密钥的一部分

  PassMachine(this.dio);
  Map<String, int> _setCr() {
    var screenTop = 0;
    var screenLeft = 0;
    var clientWidth = window.physicalSize.width.toInt();
    var clientHeight = window.physicalSize.height.toInt();
    var screenWidth = window.physicalSize.width.toInt();
    var screenHeight = window.physicalSize.height.toInt();
    var availWidth = window.physicalSize.width.toInt();
    var availHeight = window.physicalSize.height.toInt();
    var outerWidth = window.physicalSize.width.toInt();
    var outerHeight = window.physicalSize.height.toInt();
    var scrollWidth = window.physicalSize.width.toInt();
    var scrollHeight = window.physicalSize.height.toInt();
    return {
      "availHeight": availHeight,
      "availWidth": availWidth,
      "clientHeight": clientHeight,
      "clientWidth": clientWidth,
      "outerHeight": outerHeight,
      "outerWidth": outerWidth,
      "screenHeight": screenHeight,
      "screenLeft": screenLeft,
      "screenTop": screenTop,
      "screenWidth": screenWidth,
      "scrollHeight": scrollHeight,
      "scrollWidth": scrollWidth
    };
  }

  Future init() async {
    _rzdata["cr"] = _setCr();
    //第一次请求viewlog,设置as,ds,tk
    Response res = await dio.get(VIEW_LOG_URL,
        queryParameters: {"ak": ak, "_": DateTime.now().millisecondsSinceEpoch},
        options: Options(responseType: ResponseType.plain));
    ViewlogData vlData = ViewlogData.fromJson(json5Decode(res.data));
    as = vlData.data!.as!;
    ds = vlData.data!.ds!;
    tk = vlData.data!.tk!;
  }

  void _clearRzdata() {
    _rzdata = {
      //记录操作行为
      "cl": [], //click 鼠标点击
      "mv": [], //move 鼠标移动
      "sc": [], //猜测是scroll 待验证
      "kb": [], //猜测是keybord 待验证
      "sb": [], //猜不出
      "sd": [], //猜不出
      "sm": [], //猜不出
      "cr": _setCr(), //界面宽高参数
      "simu": 0, //window.navigator.webdriver ? 1 : 0,
      "ac_c": 0 //滑条的百分比，应该是最主要判断验证码对不对的参数，对应给图片旋转360*ac_c度
    };
  }

  //记录
  void recordAction(String actionType, Map<String, dynamic> data) {
    if ((_rzdata[actionType]! as List).length < 10) {
      (_rzdata[actionType]! as List).add(data);
    }
  }

  //获取验证码图片
  Future<String> _getCaptchaImgUrl() async {
    Response res = await dio.get(GETSTYLE_URL,
        queryParameters: {
          "ak": ak,
          "tk": tk,
          "isios": 0,
          "type": "default",
          "_": DateTime.now().millisecondsSinceEpoch
        },
        options: Options(headers: {
          "Referer": BAIDU_URL,
        }, responseType: ResponseType.plain));
    Getstyle getstyleData = Getstyle.fromJson(json5Decode(res.data));
    //设置backstr的值
    backstr = getstyleData.getstyleData!.backstr!;
    return getstyleData.getstyleData!.ext!.img!;
  }

  Future<Uint8List> getCaptchaImg() async {
    var url = Uri.decodeFull(await _getCaptchaImgUrl());
    var res = await dio.get(url,
        options: Options(headers: {
          "Referer": BAIDU_URL,
          "Accept":
              "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8"
        }, responseType: ResponseType.bytes));

    return res.data;
  }

  //发送验证码并获得验证结果结果
  Future<bool> verify() async {
    Map<String, dynamic> sb = _rzdata; //用于请求的rzdata,和backstr等数据
    sb["backstr"] = backstr;
    String fs = _encrypt(sb); //用于存放加密后的sb
    Response res = await dio.get(VIEW_LOG_URL,
        queryParameters: {
          "ak": ak,
          "as": as,
          "fs": fs,
          "sb": jsonEncode(sb),
          "tk": tk,
          "cv": _cv,
          "_": DateTime.now().millisecondsSinceEpoch
        },
        options: Options(headers: {
          "Referer": BAIDU_URL,
          "Connection": "keep-alive",
        }, responseType: ResponseType.plain));
    ViewlogVerify viewlogVerify = ViewlogVerify.fromJson(jsonDecode(res.data));
    //重新设置as,ds,tk
    as = viewlogVerify.dsdata!.as!;
    ds = viewlogVerify.dsdata!.ds!;
    tk = viewlogVerify.dsdata!.tk!;
    //清空操作记录
    _clearRzdata();
    if (viewlogVerify.dsdata!.op == 0) {
      return false;
    } else {
      return true;
    }
  }

  //发送操作记录
  Future sendRecord() async {
    String fs = _encrypt(_rzdata); //用于存放加密后的rzdata
    Map<String, dynamic> sb = _rzdata; //用于请求的rzdata,和backstr等数据
    Response res = await dio.get(VIEW_LOG_URL,
        queryParameters: {
          "ak": ak,
          "as": as,
          "fs": fs,
          "sb": jsonEncode(sb),
          "tk": tk,
          "_": DateTime.now().millisecondsSinceEpoch
        },
        options: Options(headers: {
          "Referer": BAIDU_URL,
          "Connection": "keep-alive",
        }, responseType: ResponseType.plain));
    ViewlogVerify viewlogVerify = ViewlogVerify.fromJson(jsonDecode(res.data));
    //重新设置as,ds,tk
    as = viewlogVerify.dsdata!.as!;
    ds = viewlogVerify.dsdata!.ds!;
    tk = viewlogVerify.dsdata!.tk!;
    //清空操作记录
    _clearRzdata();
  }

  //对数据进行aes加密
  String _encrypt(Map data) {
    var strData = jsonEncode(data);
    var nameL = as;
    var key = nameL + _nameR;
    return ecpt.Encrypter(
            ecpt.AES(ecpt.Key.fromUtf8(key), mode: ecpt.AESMode.ecb))
        .encrypt(strData, iv: ecpt.IV.fromLength(0))
        .base64;
  }

  void setAcc(double value) {
    _rzdata["ac_c"] = value;
  }
}
