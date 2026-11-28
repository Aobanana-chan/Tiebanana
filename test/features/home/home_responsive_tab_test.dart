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
import 'package:tiebanana/features/settings/pages/app_setting_page.dart';
import 'package:tiebanana/features/settings/pages/about_page.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/update/data/version.dart';
import 'package:tiebanana/features/update/pages/app_update_page.dart';
import 'package:tiebanana/features/update/state/update_reminder.dart';
import 'package:tiebanana/features/update/widgets/update_badge.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';
import 'package:tiebanana/shared/widgets/setting_group.dart';

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

/// 与 [_wrapHome] 相同，但带「应用设置」命名路由，用于验证窄屏设置页在拉宽后退场。
Widget _wrapHomeWithSettingsRoute({UpdateCheckResult? updateResult}) {
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
      routes: <String, WidgetBuilder>{
        PageRouter.appSetting: (_) => const AppSettingPage(),
        PageRouter.about: (_) => const AboutPage(),
        if (updateResult != null)
          PageRouter.appUpdate: (_) =>
              UpdatePage(checkUpdate: () async => updateResult),
      },
      home: const HomePage(),
    ),
  );
}

/// 显式推帧：页面里有常驻动画（订阅流刷新等），`pumpAndSettle` 会一直等下去。
Future<void> _pumpFrames(WidgetTester tester, [int frames = 10]) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// 从窄屏底栏进「个人」，再点开设置页。
Future<void> _openSettingsFromProfile(WidgetTester tester) async {
  await tester.tap(find.text('个人'));
  await _pumpFrames(tester, 4);

  await tester.tap(find.text('设置'));
  await _pumpFrames(tester);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'uid': '10001',
      'userName': '烤面包边',
    });
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    UpdateReminder.restore();
    Global.tiebaAPI = DemoTiebaApi(latency: Duration.zero);
    MessageReminder.reset();
  });

  testWidgets('窄屏更新红点沿各级入口显示，看到更新页后消失', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const result = UpdateCheckResult(
      status: UpdateStatus.available,
      currentVersion: '1.1.0',
      latestVersion: 'v1.1.1',
    );
    await UpdateReminder.recordCheck(result);
    await tester.pumpWidget(_wrapHomeWithSettingsRoute(updateResult: result));
    await _pumpFrames(tester);

    final dots = find.descendant(
      of: find.byType(UpdateBadge),
      matching: find.byType(Badge),
    );
    expect(dots.hitTestable(), findsWidgets);
    await tester.tap(find.text('个人'));
    await _pumpFrames(tester);
    expect(
        find.descendant(
            of: find.widgetWithText(SettingRow, '设置'), matching: dots),
        findsOneWidget);
    await tester.tap(find.text('设置'));
    await _pumpFrames(tester);
    await tester.scrollUntilVisible(find.text('关于'), 300);
    expect(dots.hitTestable(), findsOneWidget);
    await tester.tap(find.text('关于'));
    await _pumpFrames(tester);
    expect(dots.hitTestable(), findsOneWidget);
    await tester.tap(find.text('检查更新'));
    await _pumpFrames(tester);
    expect(find.text('最新版本：v1.1.1'), findsOneWidget);
    await tester.pageBack();
    await _pumpFrames(tester);
    expect(dots, findsNothing);
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
      tester
          .widget<DesktopShellFrame>(find.byType(DesktopShellFrame))
          .activeTab,
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
      tester
          .widget<DesktopShellFrame>(find.byType(DesktopShellFrame))
          .activeTab,
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

  testWidgets('窄屏打开设置页后拉宽窗口，设置页自动退场并落到宽屏「个人与设置」', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    // 高度给足，窄屏「个人」页的设置分组不用滚动就能点到。
    tester.view.physicalSize = const Size(390, 1600);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrapHomeWithSettingsRoute());
    await _pumpFrames(tester, 3);

    await _openSettingsFromProfile(tester);
    expect(find.text('应用设置'), findsOneWidget);

    tester.view.physicalSize = const Size(1280, 800);
    await _pumpFrames(tester);

    expect(find.text('应用设置'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(DesktopShellFrame), findsOneWidget);
    expect(find.text('我的空间'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('设置页上的弹窗没关时不退场，关掉之后才并入宽屏设置', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1600);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrapHomeWithSettingsRoute());
    await _pumpFrames(tester, 3);

    await _openSettingsFromProfile(tester);

    await tester.tap(find.text('首页历史记录数量'));
    await _pumpFrames(tester, 4);
    expect(find.text('可设置 1–50 条，默认 15 条'), findsOneWidget);

    tester.view.physicalSize = const Size(1280, 800);
    await _pumpFrames(tester);

    // 编辑中的弹窗和设置页都保留，等用户自己关掉。
    expect(find.text('应用设置'), findsOneWidget);
    expect(find.text('可设置 1–50 条，默认 15 条'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await _pumpFrames(tester);

    expect(find.text('应用设置'), findsNothing);
    expect(find.text('我的空间'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
