import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tiebanana/Callback/LifeTimeCallback.dart';

///开启APP自动清除上次缓存
class ClearCache extends APPStateCallback {
  @override
  void afterInit() {
    PhotoManager.clearFileCache();

    done = true;
  }

  @override
  void onRoute(RouteSettings settings) {}

  @override
  void onHomeFormPageCreate(BuildContext context) {}
}
