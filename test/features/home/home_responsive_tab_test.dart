import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/features/home/pages/home_page.dart';
import 'package:tiebanana/features/home/widgets/forum_tag.dart';
import 'package:tiebanana/features/message/state/message_reminder.dart';
import 'package:tiebanana/features/profile/pages/my_profile_page.dart';
import 'package:tiebanana/features/recommend/pages/recommend_page.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';

Widget _wrapHome() {
  return MultiProvider(
    providers: <ChangeNotifierProvider<dynamic>>[
      ChangeNotifierProvider<APPSettingProvider>(
        create: (_) => APPSettingProvider(),
      ),
      ChangeNotifierProvider<User>(
        create: (_) => User(),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: const HomePage(),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'uid': '10001',
      'userName': '烤面包边',
    });
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    Global.tiebaAPI = DemoTiebaApi(latency: Duration.zero);
    MessageReminder.reset();
  });

  testWidgets('宽屏切到个人页后缩窄到手机宽度，页签与显示内容仍保持为个人页', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrapHome());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(DesktopShellFrame), findsOneWidget);
    expect(find.byType(TagPan), findsOneWidget);

    // 宽屏下切到「个人与设置」（第 4 个页签，下标 3）
    await tester.tap(find.text('个人与设置').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(UserPage), findsOneWidget);
    expect(
      tester.widget<DesktopShellFrame>(find.byType(DesktopShellFrame)).activeTab,
      3,
    );

    // 缩窄到手机宽度（< 720dp）
    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
    expect(find.byType(UserPage), findsOneWidget);
    expect(find.byType(TagPan), findsNothing);

    // 再切到「动态」（下标 1），然后拉宽回桌面宽度
    await tester.tap(find.text('动态'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.byType(RecommendPan), findsOneWidget);

    tester.view.physicalSize = const Size(1280, 800);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byType(DesktopShellFrame), findsOneWidget);
    expect(
      tester.widget<DesktopShellFrame>(find.byType(DesktopShellFrame)).activeTab,
      1,
    );
    expect(find.byType(RecommendPan), findsOneWidget);
    expect(find.byType(TagPan), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('页签动画切换过程中窗口宽度跨过断点，动画结束后页签与页面仍一致', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrapHome());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 点击「动态」（下标 1），在 200ms 动画进行到一半时缩窄到手机宽度
    await tester.tap(find.text('动态').first);
    await tester.pump(const Duration(milliseconds: 50));

    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.byType(RecommendPan), findsOneWidget);
    expect(find.byType(TagPan), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
