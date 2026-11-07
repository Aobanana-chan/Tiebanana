import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android 声明各版本照片权限且不申请其他媒体读取权限', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final permissions = {
      for (final match
          in RegExp(r'<uses-permission\b[^>]*>').allMatches(manifest))
        RegExp(r'android:name="([^"]+)"').firstMatch(match[0]!)![1]!: match[0]!,
    };
    expect(permissions, contains('android.permission.READ_MEDIA_IMAGES'));
    expect(permissions,
        contains('android.permission.READ_MEDIA_VISUAL_USER_SELECTED'));
    expect(permissions['android.permission.READ_EXTERNAL_STORAGE'],
        contains('android:maxSdkVersion="32"'));
    expect(permissions['android.permission.WRITE_EXTERNAL_STORAGE'],
        contains('android:maxSdkVersion="28"'));
    expect(permissions, isNot(contains('android.permission.READ_MEDIA_VIDEO')));
    expect(permissions, isNot(contains('android.permission.READ_MEDIA_AUDIO')));
    expect(permissions,
        isNot(contains('android.permission.MANAGE_EXTERNAL_STORAGE')));
  });

  test('iOS 提供读取与保存照片的权限用途说明', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    for (final key in [
      'NSPhotoLibraryUsageDescription',
      'NSPhotoLibraryAddUsageDescription',
    ]) {
      expect(plist, matches('<key>$key</key>\\s*<string>[^<]+</string>'));
    }
  });
}
