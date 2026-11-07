import 'app_lifecycle_hook.dart';
import 'package:flutter/cupertino.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tiebanana/features/forum/services/auto_sign.dart';
import 'package:tiebanana/features/update/services/auto_check_update.dart';
import 'package:tiebanana/app/lifecycle/media_cache_cleanup.dart';
import 'package:tiebanana/app/lifecycle/network_status_listener.dart';

///app生命周期回调
class LifeTimeCallback {
  final Lock _lockRW = Lock();
  final List<APPStateCallback> _callbacks = [];
  static final LifeTimeCallback _instance = LifeTimeCallback.init();
  factory LifeTimeCallback() {
    return _instance;
  }
  LifeTimeCallback.init() {
    regist(AutoSign());
    regist(ClearCache());
    regist(ListenNetStatus());
    regist(AutoCheckUpdate());
  }
  //注册回调
  void regist(APPStateCallback callback) {
    _lockRW.synchronized(() => _callbacks.add(callback));
  }

  void afterInit() {
    _lockRW.synchronized(() {
      var tmp = [];
      for (var callback in _callbacks) {
        callback.afterInit();
        if (callback.done) {
          tmp.add(callback);
        }
      }
      _callbacks.removeWhere((element) => tmp.contains(element));
    });
  }

  void route(RouteSettings settings) {
    _lockRW.synchronized(() {
      var tmp = [];
      for (var callback in _callbacks) {
        callback.onRoute(settings);
        if (callback.done) {
          tmp.add(callback);
        }
      }
      _callbacks.removeWhere((element) => tmp.contains(element));
    });
  }

  //主页关注吧页面创建回调
  void onHomeFormPageCreate(BuildContext context) {
    _lockRW.synchronized(() {
      var tmp = [];
      for (var callback in _callbacks) {
        callback.onHomeFormPageCreate(context);
        if (callback.done) {
          tmp.add(callback);
        }
      }
      _callbacks.removeWhere((element) => tmp.contains(element));
    });
  }
}
