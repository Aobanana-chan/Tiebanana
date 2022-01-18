import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
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
class ForumState with ChangeNotifier {
  List<LikeForumInfo> _forums = [];
  List<LikeForumInfo> get forums {
    return _forums;
  }

  ForumState() {
    refresh();
  }
  Future<void> refresh() async {
    _forums = (await Global.tiebaAPI.userInfomation.likes)!;
    notifyListeners();
  }
}

//页面标题Model
class APPBarTitle with ChangeNotifier {
  String _title = "";
  set title(String title) {
    if (title != _title) {
      _title = title;
      notifyListeners();
    }
  }

  get getTitle {
    return _title;
  }
}

class ThreadListProviderModel with ChangeNotifier {
  List<ForumThreadList>? _threadList;
  set setList(List<ForumThreadList>? list) {
    _threadList = list;
    notifyListeners();
  }

  List<ForumThreadList>? get threadList => _threadList;
}
