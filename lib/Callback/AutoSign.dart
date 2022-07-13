import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/navigator.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Callback/LifeTimeCallback.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/common/Global.dart';

///自动签到
class AutoSign extends APPStateCallback {
  @override
  void afterInit() {
    if (Global.setting.signAllsinceOpen == true) {
      LifeTimeCallback().regist(SignRefresh(Global.tiebaAPI.signAll()));
    }

    done = true;
  }

  @override
  void onRoute(RouteSettings settings) {}

  @override
  void onHomeFormPageCreate(BuildContext context) {}
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
