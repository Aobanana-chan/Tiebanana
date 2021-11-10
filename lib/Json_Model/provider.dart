import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/common/Global.dart';

///用户信息Model类
class User with ChangeNotifier {
  //登陆状态
  bool _islogin = Global.tiebaAPI.isLogin;
  bool get isLogin => Global.tiebaAPI.isLogin;

  //Login状态改变则通知其依赖项
  void login() {
    if (Global.tiebaAPI.isLogin != _islogin) {
      _islogin = Global.tiebaAPI.isLogin;
      notifyListeners();
    }
  }
}

///应用主题Model
class APPTheme with ChangeNotifier {
  // 获取当前主题，如果未设置主题，则默认使用蓝色主题
  ColorSwatch get theme =>
      Global.themes.firstWhere((e) => e.value == Global.setting.theme,
          orElse: () => Colors.blue);

  // 主题改变后，通知其依赖项
  set theme(ColorSwatch color) {
    if (color != theme) {
      theme = color;
      //保存APP配置项
      Global.setting.theme = color[500]!.value;
      Global.saveProfile();

      notifyListeners();
    }
  }
}

//吧状态Model
class ForumState with ChangeNotifier {}
