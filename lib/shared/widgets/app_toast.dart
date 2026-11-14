import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart' as native;
import 'package:tiebanana/core/platform/platform_capabilities.dart';

/// 桌面提示不依赖移动端原生 Toast 通道。
class Fluttertoast {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static Future<bool?> showToast({required String msg}) async {
    if (!isDesktop) return native.Fluttertoast.showToast(msg: msg);
    final messenger = messengerKey.currentState;
    if (messenger == null) return false;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
    return true;
  }
}
