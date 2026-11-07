import 'package:flutter/material.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/app/global.dart';

///用户信息Model类
class User with ChangeNotifier {
  //登陆状态
  bool _islogin = Global.tiebaAPI.isLogin;
  bool get isLogin => Global.tiebaAPI.isLogin;

  String _name = AccountStore.current?.name ?? "";
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
      // 退出登录 / 移除最后一个账号后 `uid` 会被删掉，返回空串，
      // 构建中的收藏、个人页可以安全读取。
      _uid = Global.profile.getString("uid") ?? "";
      return _uid!;
    }
  }

  //Login状态改变则通知其依赖项
  void login() {
    refreshAccount();
  }

  /// 重新读取登录态与当前账号。
  ///
  /// 多账号切换前后 `isLogin` 可能都是 true；切换账号的调用方传 [force]
  /// 让依赖项重建，同时清空 [_uid] 以读取新账号。
  void refreshAccount({bool force = false}) {
    _uid = null;
    _name = AccountStore.current?.name ?? _name;
    final bool now = Global.tiebaAPI.isLogin;
    if (force || now != _islogin) {
      _islogin = now;
      notifyListeners();
    }
  }
}
