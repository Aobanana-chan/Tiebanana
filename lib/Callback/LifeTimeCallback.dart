import 'package:flutter/cupertino.dart';
import 'package:tiebanana/Callback/AutoSign.dart';
import 'package:tiebanana/Callback/ClearCache.dart';

///app生命周期回调
class LifeTimeCallback {
  final List<APPStateCallback> _callbacks = [];
  static final LifeTimeCallback _instance = LifeTimeCallback.init();
  factory LifeTimeCallback() {
    return _instance;
  }
  LifeTimeCallback.init() {
    regist(AutoSign());
    regist(ClearCache());
  }

  void regist(APPStateCallback callback) {
    _callbacks.add(callback);
  }

  void afterInit() {
    var tmp = [];
    for (var callback in _callbacks) {
      callback.afterInit();
      if (callback.done) {
        tmp.add(callback);
      }
    }
    _callbacks.removeWhere((element) => tmp.contains(element));
  }

  void route(RouteSettings settings) {
    var tmp = [];
    for (var callback in _callbacks) {
      callback.onRoute(settings);
      if (callback.done) {
        tmp.add(callback);
      }
    }
    _callbacks.removeWhere((element) => tmp.contains(element));
  }
}

abstract class APPStateCallback {
  bool done = false;
  void afterInit();
  void onRoute(RouteSettings settings);
}
