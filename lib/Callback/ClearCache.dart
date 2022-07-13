import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/navigator.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tiebanana/Callback/LifeTimeCallback.dart';
import 'package:tiebanana/common/Global.dart';

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
