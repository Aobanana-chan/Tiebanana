import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'package:tiebanana/app/lifecycle/app_lifecycle_hook.dart';
import 'package:tiebanana/app/global.dart';

///监听网络状态变化
class ListenNetStatus extends APPStateCallback {
  @override
  void afterInit() {}

  @override
  void onRoute(RouteSettings settings) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    Global.netStatus = connectivityResult;
  }

  @override
  void onHomeFormPageCreate(BuildContext context) {}
}
