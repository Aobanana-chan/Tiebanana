import 'package:flutter/material.dart';
import 'package:json5/json5.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/common/API/net.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiebanana/common/DefaultConfig.dart';

///主体颜色常量
const _themes = <MaterialColor>[
  Colors.blue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.yellow,
];

class Global {
  static TiebaAPI tiebaAPI = TiebaAPI();
  //判断是否是Release版
  static bool get isRelease => bool.fromEnvironment("dart.vm.product");

  // 可选的主题列表
  static List<MaterialColor> get themes => _themes;
  //APP配置信息
  static late SharedPreferences profile;
  static late APPSetting setting;
  //Global类初始化
  static Future init() async {
    profile = await SharedPreferences.getInstance();
    var _settingload = profile.getString("APPSetting");
    //读取APP设置
    if (_settingload == null) {
      //没有存储过的设置就设置默认设置
      setting = APPSetting.fromJson(defaultAPPSetting);
    } else {
      setting = APPSetting.fromJson(json5Decode(_settingload));
    }
  }

  ///保持用户APP设置
  static void saveProfile() {
    profile.setString("APPSetting", json5Encode(setting.toJson()));
  }
}
