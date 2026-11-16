import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 返回键走到「退出」这一步时的统一出口。
///
/// 根路由不能再交给 `Navigator.pop`：它会把唯一的路由弹掉，但进程仍然活着，
/// 用户看到的就是黑屏。这里先判断能否正常返回，只有确实在根路由时才按平台退出。
abstract final class AppExit {
  /// 处理一次已经确认要退出的返回。
  ///
  /// 有上层路由时正常 pop；已经在根路由时：
  /// - Android：退出当前任务，回到桌面。
  /// - Windows / Linux / macOS：走引擎的标准退出流程（等同关闭窗口）。
  /// - iOS：系统不允许应用主动退出，保持页面不动。
  static Future<void> handleRootBack(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    await _exitApplication();
  }

  static Future<void> _exitApplication() async {
    if (kIsWeb) {
      return;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        await SystemNavigator.pop();
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        // 与 ServicesBinding.exitApplication(AppExitType.required) 同一协议：
        // 让引擎走正常的退出流程，而不是直接杀进程。
        await SystemChannels.platform.invokeMethod<Map<String, Object?>>(
            'System.exitApplication',
            <String, Object?>{'type': 'required', 'exitCode': 0});
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        // iOS 上主动退出会被系统视为崩溃，根路由返回不做事。
        break;
    }
  }
}
