import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/core/platform/app_exit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> calls = <MethodCall>[];

  /// 只关心真正让应用退出的调用；主题、音效等框架消息不参与断言。
  List<MethodCall> exitCalls() => calls
      .where((MethodCall call) =>
          call.method == 'SystemNavigator.pop' ||
          call.method == 'System.exitApplication')
      .toList();

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      if (call.method == 'System.exitApplication') {
        return <String, Object?>{'response': 'exit'};
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget rootPage({
    required Future<void> Function(BuildContext context) onBack,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => Column(
            children: <Widget>[
              const Text('根页面'),
              TextButton(
                onPressed: () => onBack(context),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('根路由返回：Android 不弹出根路由，改为退出任务', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(rootPage(onBack: AppExit.handleRootBack));

      await tester.tap(find.text('返回'));
      await tester.pumpAndSettle();

      expect(exitCalls().map((MethodCall call) => call.method), <String>[
        'SystemNavigator.pop',
      ]);
      expect(find.text('根页面'), findsOneWidget, reason: '根路由必须保留，不能黑屏');
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('根路由返回：Windows 走引擎的标准退出流程', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(rootPage(onBack: AppExit.handleRootBack));

      await tester.tap(find.text('返回'));
      await tester.pumpAndSettle();

      expect(exitCalls().map((MethodCall call) => call.method), <String>[
        'System.exitApplication',
      ]);
      expect(exitCalls().single.arguments, <String, Object?>{
        'type': 'required',
        'exitCode': 0,
      });
      expect(find.text('根页面'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('有上层路由时正常返回，不触发退出', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final GlobalKey<NavigatorState> navigatorKey =
          GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('根页面')),
      ));
      navigatorKey.currentState!.push<void>(MaterialPageRoute<void>(
        builder: (BuildContext context) => Scaffold(
          body: TextButton(
            onPressed: () => AppExit.handleRootBack(context),
            child: const Text('返回'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('返回'));
      await tester.pumpAndSettle();

      expect(find.text('根页面'), findsOneWidget);
      expect(find.text('返回'), findsNothing);
      expect(exitCalls(), isEmpty, reason: '有上层路由时只 pop，不应退出应用');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('iOS 根路由返回不主动退出', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(rootPage(onBack: AppExit.handleRootBack));

      await tester.tap(find.text('返回'));
      await tester.pumpAndSettle();

      expect(exitCalls(), isEmpty);
      expect(find.text('根页面'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
