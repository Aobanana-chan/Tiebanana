import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/app/global.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();
    Global.localNotifications = FlutterLocalNotificationsPlugin();
    calls.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      calls.add(call);
      // 用户拒绝授权时，初始化仍然应正常完成。
      return call.method == 'initialize' ? false : null;
    });
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('iOS 初始化提供 Darwin 配置，授权被拒绝不抛错', () async {
    await Global.initializeNotifications();
    expect(calls.single.method, 'initialize');
    final args = calls.single.arguments as Map;
    expect(args['requestAlertPermission'], isTrue);
    expect(args['requestSoundPermission'], isFalse);
    expect(args['requestBadgePermission'], isFalse);
  });

  test('iOS 签到通知携带静音前台展示配置', () async {
    await Global.initializeNotifications();
    await Global.showNotification(0, '签到', '1/2');
    final call = calls.last;
    expect(call.method, 'show');
    final args = call.arguments as Map;
    expect(args['id'], 0);
    expect(args['title'], '签到');
    final details = args['platformSpecifics'] as Map;
    expect(details['presentAlert'], isTrue);
    expect(details['presentBanner'], isTrue);
    expect(details['presentSound'], isFalse);
    expect(details['presentBadge'], isFalse);
  });

  test('Android 初始化继续使用原有通知图标和频道', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    await Global.initializeNotifications();
    expect(
        (calls.single.arguments as Map)['defaultIcon'], '@mipmap/ic_launcher');
    await Global.showNotification(0, '签到', '1/2');
    final details = (calls.last.arguments as Map)['platformSpecifics'] as Map;
    expect(details['channelId'], '0');
    expect(details['playSound'], isFalse);
  });
}
