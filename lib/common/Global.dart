import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:json5/json5.dart';
import 'package:tiebanana/DAO/DAOApi.dart';
import 'package:tiebanana/Exceptions/NetAPIError.dart';
import 'package:tiebanana/common/API/TiebaNetAPI.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiebanana/common/DefaultConfig.dart';

///主体颜色常量
const _themes = <String, MaterialColor>{
  "blue": Colors.blue,
  "cyan": Colors.cyan,
  "teal": Colors.teal,
  "green": Colors.green,
  "yellow": Colors.yellow,
  "pink": Colors.pink,
  "white": MaterialColor(0xFFFFFFFF, <int, Color>{
    50: Color(0xFFFFFFFF),
    100: Color(0xFFFFFFFF),
    200: Color(0xFFFFFFFF),
    300: Color(0xFFFFFFFF),
    400: Color(0xFFFFFFFF),
    500: Color(0xFFFFFFFF),
    600: Color(0xFFFFFFFF),
    700: Color(0xFFFFFFFF),
    800: Color(0xFFFFFFFF),
    900: Color(0xFFFFFFFF),
  })
};

class Global {
  //网络状态
  static ConnectivityResult netStatus = ConnectivityResult.mobile;

  static TiebaAPI tiebaAPI = TiebaAPI();
  //判断是否是Release版
  // static bool get isRelease => const bool.fromEnvironment("dart.vm.product");

  // 可选的主题列表
  static Map<String, MaterialColor> get themes => _themes;

  //APP配置信息
  static late SharedPreferences profile;
  static late APPSetting setting;
  static FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  //DAOAPI
  static DAOAPI daoapi = DAOAPI();

  //Global类初始化
  static Future init() async {
    profile = await SharedPreferences.getInstance();
    var settingload = profile.getString("APPSetting");

    //读取APP设置
    if (settingload == null) {
      //没有存储过的设置就设置默认设置
      setting = APPSetting.fromJson(defaultAPPSetting);
    } else {
      setting = APPSetting.fromJson(json5Decode(settingload));
    }

    //通知栏消息插件初始化
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await localNotifications.initialize(initializationSettings);

    //初始化贴吧API

    try {
      await tiebaAPI.init().then((value) async {
        //初始化用户uid
        if (value.isLogin) {
          var userInfo = await value.getMyInfo();
          profile.setString("uid", userInfo.id!.toString());
        }
      });
    } catch (e) {
      throw NetAPIError(
          type: NetAPIErrorType.initFailed,
          redoTimes: double.maxFinite.toInt(),
          redoFunction: () async {
            await tiebaAPI.init().then((value) async {
              //初始化用户uid
              if (value.isLogin) {
                var userInfo = await value.getMyInfo();
                profile.setString("uid", userInfo.id!.toString());
              }
            });
          });
    }

    //初始化数据库
    await daoapi.init();
  }

  ///保持用户APP设置
  static void saveProfile() {
    profile.setString("APPSetting", json5Encode(setting.toJson()));
  }

  ///显示通知
  static Future<void> showNotification(
      int id, String title, String body) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(id.toString(), 'Tiebanana',
            channelDescription: 'Tiebanana notification', playSound: false);

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await Global.localNotifications
        .show(id, title, body, platformChannelSpecifics);
  }
}
