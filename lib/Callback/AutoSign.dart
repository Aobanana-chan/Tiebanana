import 'package:flutter/src/widgets/navigator.dart';
import 'package:tiebanana/Callback/LifeTimeCallback.dart';
import 'package:tiebanana/common/Global.dart';

class AutoSign extends APPStateCallback {
  @override
  void afterInit() {
    if (Global.setting.signAllsinceOpen == true) {
      Global.tiebaAPI.signAll();
    }

    done = true;
  }

  @override
  void onRoute(RouteSettings settings) {}
}
