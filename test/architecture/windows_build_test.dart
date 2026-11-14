import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows 打包媒体库、通知配置与竖屏窗口', () {
    expect(File('pubspec.yaml').readAsStringSync(),
        contains('media_kit_libs_windows_video:'));
    expect(File('lib/app/global.dart').readAsStringSync(),
        contains('WindowsInitializationSettings('));
    final main = File('windows/runner/main.cpp').readAsStringSync();
    expect(main, contains('Size size(750, 1334)'));
    expect(main.indexOf('window.Destroy();'),
        lessThan(main.indexOf('::CoUninitialize();')));
    final window = File('windows/runner/win32_window.cpp').readAsStringSync();
    expect(window, contains('case WM_SIZING:'));
    expect(window, contains('750.0 / 1334.0'));
    expect(window, contains('~WS_MAXIMIZEBOX'));
    final cmake = File('windows/CMakeLists.txt').readAsStringSync();
    expect(cmake, contains('webview_plugin_shutdown.cpp'));
    expect(cmake, contains('WEBVIEW_ORDER_POSITION EQUAL -1'));
    expect(File('windows/runner/flutter_window.cpp').readAsStringSync(),
        contains('if (message == WM_CLOSE)'));
  });
}
