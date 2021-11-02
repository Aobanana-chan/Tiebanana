import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  static FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();
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

    //通知栏消息插件初始化
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings();
    final MacOSInitializationSettings initializationSettingsMacOS =
        MacOSInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsMacOS);
    await localNotifications.initialize(initializationSettings);
  }

  ///保持用户APP设置
  static void saveProfile() {
    profile.setString("APPSetting", json5Encode(setting.toJson()));
  }

  //
  static Future<void> showNotification(
      int id, String title, String body) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(id.toString(), 'Tiebanana',
            channelDescription: 'Tiebanana notification', playSound: false);
    IOSNotificationDetails iOSPlatformChannelSpecifics =
        IOSNotificationDetails();
    NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    await Global.localNotifications
        .show(id, title, body, platformChannelSpecifics);
  }
}
