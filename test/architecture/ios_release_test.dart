import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS 原生依赖和最低版本配置一致，Podfile 仅引用现有 target', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('media_kit_libs_ios_video:'));
    final project =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = 15\.0;').allMatches(project),
        hasLength(3));
    expect(project, isNot(contains('com.example.')));
    final podfile = File('ios/Podfile').readAsStringSync();
    expect(podfile, contains("platform :ios, '15.0'"));
    expect(podfile, contains("target 'Runner' do"));
    expect(podfile, isNot(contains('RunnerTests')));
    for (final mode in ['Debug', 'Release']) {
      expect(File('ios/Flutter/$mode.xcconfig').readAsStringSync(),
          contains('Pods-Runner.${mode.toLowerCase()}.xcconfig'));
    }
  });

  test('iOS 使用 scene 生命周期和专属 scheme，不抢占官方客户端 scheme', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<key>UIApplicationSceneManifest</key>'));
    expect(plist, contains(r'$(PRODUCT_MODULE_NAME).SceneDelegate'));
    expect(plist, contains('<string>tiebanana</string>'));
    expect(plist, contains('<string>tbpb</string>'));
    expect(plist, contains('<string>tbfrs</string>'));
    expect(plist, isNot(contains('<string>com.baidu.tieba</string>')));
    expect(plist, contains('<key>FlutterDeepLinkingEnabled</key>\n\t<false/>'));
    final delegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(delegate, contains('FlutterImplicitEngineDelegate'));
    expect(delegate, contains('class SceneDelegate: FlutterSceneDelegate'));
    expect(delegate,
        contains('UNUserNotificationCenter.current().delegate = self'));
  });

  test('发布流程等待三平台构建，上传带 unsigned 标记的 IPA', () {
    final workflow = File('.github/workflows/main.yml').readAsStringSync();
    expect(workflow, contains('runs-on: macos-26'));
    expect(workflow, contains('--no-codesign'));
    expect(workflow, contains('ios-unsigned.ipa'));
    // Release 资源名会被 GitHub 丢掉非 ASCII 字符，IPA 文件名必须保持纯 ASCII。
    final ipa = RegExp(r'zip -qry "([^"]+)"').firstMatch(workflow)![1]!;
    expect(ipa, matches(RegExp(r'^[\x20-\x7e]+$')));
    expect(workflow, contains('Payload/Runner.app'));
    expect(workflow, contains('needs: [android, ios, windows]'));
    expect(workflow, contains('release/*.apk,release/*.ipa'));
  });
}
