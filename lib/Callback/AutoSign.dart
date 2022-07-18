import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Callback/LifeTimeCallback.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/common/Global.dart';

///自动签到
class AutoSign extends APPStateCallback {
  @override
  void afterInit() {
    if (Global.setting.signAllsinceOpen == true &&
        Global.tiebaAPI.isLogin &&
        !isSigned()) {
      LifeTimeCallback().regist(SignRefresh(Global.tiebaAPI.signAll()));
      Global.profile
          .setInt("latestAutoSigned", DateTime.now().millisecondsSinceEpoch);
    }

    done = true;
  }

  @override
  void onRoute(RouteSettings settings) {}

  @override
  void onHomeFormPageCreate(BuildContext context) {}
  bool isSigned() {
    var time = Global.profile.getInt("latestAutoSigned");
    if (time != null) {
      var date = DateTime.fromMillisecondsSinceEpoch(time);
      var now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return true;
      }
    }
    return false;
  }
}

///签到后刷新页面回调
class SignRefresh extends APPStateCallback {
  Future signState;
  SignRefresh(this.signState);
  @override
  void afterInit() {}

  @override
  void onRoute(RouteSettings settings) {}

  @override
  void onHomeFormPageCreate(BuildContext context) {
    signState.then(
        (value) => Provider.of<ForumState>(context, listen: false).refresh());

    done = true;
  }
}
