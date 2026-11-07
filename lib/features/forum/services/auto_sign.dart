import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/app/lifecycle/app_lifecycle_hook.dart';
import 'package:tiebanana/app/lifecycle/app_lifecycle.dart';
import 'package:tiebanana/features/forum/state/forum_state.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';

///自动签到
class AutoSign extends APPStateCallback {
  AutoSign({void Function(String)? onMessage})
      : _onMessage = onMessage ?? _showMessage;

  final void Function(String) _onMessage;

  static void _showMessage(String message) {
    Fluttertoast.showToast(msg: message);
  }

  @override
  void afterInit() {
    if (Global.setting.signAllsinceOpen == true &&
        Global.tiebaAPI.isLogin &&
        !isSigned()) {
      LifeTimeCallback().regist(SignRefresh(runSign()));
    }

    done = true;
  }

  /// 启动时立即监听后台任务，异常在任务创建时即被接住。
  /// 失败时保留凭证，当天签到状态保持未签到。
  Future<bool> runSign() async {
    try {
      await Global.tiebaAPI.signAll();
      await Global.profile
          .setInt("latestAutoSigned", DateTime.now().millisecondsSinceEpoch);
      return true;
    } catch (error, stackTrace) {
      AppLog.shared.error('sign.failed', error, stackTrace);
      debugPrint('自动签到失败，请检查登录状态后手动重试：$error');
      debugPrintStack(stackTrace: stackTrace);
      _onMessage('自动签到失败，请检查登录状态后手动重试');
      return false;
    }
  }

  @override
  void onRoute(RouteSettings settings) {}

  @override
  void onHomeFormPageCreate(BuildContext context) {}
  bool isSigned() {
    var time = Global.profile.getInt("latestAutoSigned");
    if (time != null) {
      var date = DateTime.fromMillisecondsSinceEpoch(time);
      var now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return true;
      }
    }
    return false;
  }
}

///签到后刷新页面回调
class SignRefresh extends APPStateCallback {
  final Future<bool> signState;
  SignRefresh(this.signState);
  @override
  void afterInit() {}

  @override
  void onRoute(RouteSettings settings) {}

  @override
  void onHomeFormPageCreate(BuildContext context) {
    signState.then((value) {
      if (value && context.mounted) {
        Provider.of<ForumState>(context, listen: false).refresh();
      }
    });

    done = true;
  }
}
