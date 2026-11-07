import 'package:flutter/foundation.dart';

class LoginFailure {
  const LoginFailure(this.code, this.message);

  final int code;
  final String message;
}

/// 可在启动期记录错误；界面就绪后再展示。同一后端会话只提示一次。
class LoginFailureController extends ChangeNotifier {
  LoginFailure? pending;
  bool _reported = false;

  void report(int code, String message) {
    if (_reported) return;
    _reported = true;
    pending = LoginFailure(code, message);
    notifyListeners();
  }

  void acknowledge() {
    pending = null;
  }

  void reset() {
    _reported = false;
    pending = null;
  }
}
