import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json5/json5.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/platform/official_tieba.dart';
import 'package:tiebanana/shared/content/posting_risk_warning.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('tiebanana/official_tieba');
  const target = OfficialTiebaTarget(forumName: 'Flutter & Dart 中文');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (context) {
        return TextButton(
          onPressed: () => showPostingRiskWarning(context, target),
          child: const Text('编辑'),
        );
      })),
    ));
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
  }

  test('新旧设置默认开启并可持久化关闭', () {
    final legacy = Map<String, dynamic>.of(defaultAPPSetting)
      ..remove('showPostingRiskWarning');
    expect(APPSetting.fromJson(legacy).showPostingRiskWarning, isTrue);
    final setting = APPSetting.fromJson(defaultAPPSetting)
      ..showPostingRiskWarning = false;
    expect(
        APPSetting.fromJson(setting.toJson()).showPostingRiskWarning, isFalse);
  });

  test('官方链接正确编码吧名及帖子 / 楼层位置', () {
    expect(Uri.parse(target.uri.toString()).queryParameters['kw'],
        'Flutter & Dart 中文');
    const thread =
        OfficialTiebaTarget(forumName: 'Flutter', tid: '123', pid: '456');
    expect(thread.uri.scheme, 'com.baidu.tieba');
    expect(thread.uri.host, 'unidispatch');
    expect(thread.uri.path, '/pb');
    expect(thread.uri.queryParameters, {'tid': '123', 'pid': '456'});
    expect(target.uri.path, '/frs');
  });

  testWidgets('明确忽略仅本次生效，点击遮罩不能绕过警告', (tester) async {
    await open(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('无视警告，继续'));
    await tester.pumpAndSettle();
    expect(Global.setting.showPostingRiskWarning, isTrue);
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('不再提醒保存设置，重新开启后恢复提醒', (tester) async {
    await open(tester);
    await tester.tap(find.text('不再提醒'));
    await tester.pumpAndSettle();
    expect(Global.setting.showPostingRiskWarning, isFalse);
    final saved = json5Decode(Global.profile.getString('APPSetting')!);
    expect(saved['showPostingRiskWarning'], isFalse);
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    Global.setting.showPostingRiskWarning = true;
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  for (final success in [true, false]) {
    testWidgets('官方客户端跳转 success=$success，不解除风险提醒', (tester) async {
      MethodCall? sent;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
          (call) async {
        sent = call;
        return success;
      });
      await open(tester);
      await tester.tap(find.text('前往官方客户端'));
      await tester.pumpAndSettle();
      expect(sent!.method, 'open');
      expect(sent!.arguments, {'url': target.uri.toString()});
      expect(
          find.textContaining(success ? '已请求打开' : '无法打开官方客户端'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(Global.setting.showPostingRiskWarning, isTrue);
    });
  }

  testWidgets('插件不可用时提示失败而不是跳回本应用', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel, (_) async => throw MissingPluginException());
    await open(tester);
    await tester.tap(find.text('前往官方客户端'));
    await tester.pumpAndSettle();
    expect(find.textContaining('无法打开官方客户端'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
