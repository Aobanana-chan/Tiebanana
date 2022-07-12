import 'package:flutter/src/widgets/navigator.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tiebanana/Callback/LifeTimeCallback.dart';
import 'package:tiebanana/common/Global.dart';

class ClearCache extends APPStateCallback {
  @override
  void afterInit() {
    PhotoManager.clearFileCache();

    done = true;
  }

  @override
  void onRoute(RouteSettings settings) {}
}
