import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/link_router.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/widgets/clipboard_observe.dart';

const String _threadLink = 'https://tieba.baidu.com/p/123';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    Global.tiebaAPI = DemoTiebaApi(latency: Duration.zero);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('恢复时只让最上层页面检查剪贴板', (tester) async {
    _mockClipboard(_threadLink);
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_app(navigatorKey));
    await tester.pumpAndSettle();

    // 页面栈里每层都包着 ClipBordObserver，模拟进入贴子后再进一层。
    navigatorKey.currentState!.pushNamed('/second');
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pushNamed('/third');
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('是否进入剪切板复制的贴?'), findsOneWidget);

    await tester.tap(find.text('否'));
    await tester.pumpAndSettle();
  });

  testWidgets('深链刚打开的链接不再按剪贴板提示', (tester) async {
    _mockClipboard(_threadLink);
    AppUtil.noteDeepLinkOpened(_threadLink);
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_app(navigatorKey));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('是否进入剪切板复制的贴?'), findsNothing);
  });
}

Widget _app(GlobalKey<NavigatorState> navigatorKey) {
  return ChangeNotifierProvider<APPSettingProvider>(
    create: (BuildContext context) => APPSettingProvider(),
    child: MaterialApp(
      navigatorKey: navigatorKey,
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (BuildContext context) => ClipBordObserver(
          child: Scaffold(body: Text(settings.name ?? '')),
        ),
      ),
    ),
  );
}

void _mockClipboard(String text) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform,
          (MethodCall call) async {
    switch (call.method) {
      case 'Clipboard.getData':
        return <String, dynamic>{'text': text};
      case 'Clipboard.setData':
        return null;
    }
    return null;
  });
}
