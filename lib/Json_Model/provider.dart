import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/common/Global.dart';

///用户信息Model类
class User with ChangeNotifier {
  //登陆状态
  bool _islogin = Global.tiebaAPI.isLogin;
  bool get isLogin => Global.tiebaAPI.isLogin;

  String _name = "";
  String get name {
    return _name;
  }

  set name(String n) {
    if (_name != n) {
      _name = n;
      notifyListeners();
    }
  }

  String? _uid;
  String get uid {
    if (_uid != null) {
      return _uid!;
    } else {
      _uid = Global.profile.getString("uid");
      return _uid!;
    }
  }

  //Login状态改变则通知其依赖项
  void login() {
    if (Global.tiebaAPI.isLogin != _islogin) {
      _islogin = Global.tiebaAPI.isLogin;
      notifyListeners();
    }
  }
}

///应用设置Provider
class APPSettingProvider with ChangeNotifier {
  // 获取当前主题，如果未设置主题，则默认使用蓝色主题
  String get theme {
    return Global.setting.theme!;
  }

  Color get themeColor {
    return Global.themes[theme]!;
  }

  MaterialColor get materialTheme {
    if (Global.setting.theme == "white") {
      return Global.themes["blue"]!;
    }
    return Global.themes[Global.setting.theme]!;
  }

  // 主题改变后，通知其依赖项
  set theme(String color) {
    if (color != theme) {
      // theme = color;
      //保存APP配置项
      Global.setting.theme = color;
      Global.saveProfile();

      notifyListeners();
    }
  }

  AppBarTheme get appBarTheme {
    if (theme == "white") {
      return const AppBarTheme(
          backgroundColor: Colors.white, foregroundColor: Colors.black);
    }
    return AppBarTheme(
        backgroundColor:
            ColorScheme.fromSwatch(primarySwatch: materialTheme).onPrimary);
  }

  //字号大小
  double get fontSize {
    return Global.setting.fontSize;
  }

  set fontSize(double size) {
    Global.setting.fontSize = size;
    Global.saveProfile();
    notifyListeners();
  }
}

///吧状态Model
class ForumState with ChangeNotifier {
  List<LikeForumInfo> _forums = [];
  List<LikeForumInfo> get forums {
    return _forums;
  }

  ForumState() {
    refresh();
  }
  Future<void> refresh() async {
    if (Global.tiebaAPI.isLogin) {
      await Global.tiebaAPI.userInfomation.refresh();
      _forums = (await Global.tiebaAPI.userInfomation.likes)!;
      notifyListeners();
    }
  }
}

///页面标题Model
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

///精品贴列表Provider
class ThreadListProviderModel with ChangeNotifier {
  List<ForumThreadList>? _threadList;
  int goodpn = 1;
  set setList(List<ForumThreadList>? list) {
    _threadList = list;
    notifyListeners();
  }

  List<ForumThreadList>? get threadList => _threadList;
}

///精品贴控制栏Provider
class GoodClassifyProviderModel with ChangeNotifier {
  int _goodClassify = 0;
  bool _showClassidy = false;
  int get goodClassify => _goodClassify;
  bool get shouldShow => _showClassidy;

  ///设置精品贴分类可见性
  set show(bool show) {
    _showClassidy = show;
    notifyListeners();
  }

  ///修改精品贴分类
  set changeClassify(int c) {
    _goodClassify = c;
    notifyListeners();
  }
}

///图片上传notify
class ImageUploadProviderModel with ChangeNotifier {
  ImageUploadProviderModel(this._forumnName);
  late final String _forumnName;
  final Map<UploadImageModel, AssetEntity> _picture = {};
  void addPicture(AssetEntity file, UploadImageModel pic) {
    _picture[pic] = file;
    notifyListeners();
  }

  Map<UploadImageModel, AssetEntity> get pictures => _picture;

  Future<List<dynamic>?> uploadPicture(AssetEntity pic, bool saveOrigin) {
    return Global.tiebaAPI
        .uploadPicture(_forumnName, saveOrigin, pic)
        .then((value) {
      if (value.errorCode == "0") {
        addPicture(pic, value);
        return [pic, value];
      }
      return null;
    });
  }
}

const String frontSizeSetting = "AppSettingFrontSize";

///应用设置Provider
// class APPSettingProvider with ChangeNotifier {
//   APPSettingProvider() {
//     _frontSize = Global.profile.getInt(frontSizeSetting);
//   }

//   ///字号大小
//   int _frontSize = 20;

//   int get frontSize {
//     return _frontSize;
//   }

//   set frontSize(int size) {
//     _frontSize = size;
//     notifyListeners();
//   }
// }
