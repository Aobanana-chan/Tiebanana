import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/features/home/pages/home_page.dart';
import 'package:tiebanana/features/message/state/message_reminder.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/app_toast.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';

class _ControlledRefreshApi extends DemoTiebaApi {
  _ControlledRefreshApi() : super(latency: Duration.zero);

  Completer<void>? refreshLikesGate;
  Completer<void>? recommendGate;
  Completer<void>? userInfoGate;
  Completer<void>? conversationsGate;
  bool failNextRefreshLikes = false;
  int refreshLikesCount = 0;
  int recommendCalls = 0;
  int userInfoCalls = 0;
  int conversationCalls = 0;

  @override
  Future<void> refreshLikes() async {
    refreshLikesCount++;
    final Completer<void>? gate = refreshLikesGate;
    if (gate != null) {
      await gate.future;
    }
    if (failNextRefreshLikes) {
      failNextRefreshLikes = false;
      throw StateError('network error');
    }
  }

  @override
  Future<List<LikeForumInfo>> getLikes() async => <LikeForumInfo>[
        const LikeForumInfo(
          forumId: '1',
          avatar: '',
          forumName: '测试',
          isSign: '1',
          levelId: '5',
        ),
      ];

  @override
  Future<RecommendPage> getRecommThread(int pageThreadCount, int pn) async {
    recommendCalls++;
    final Completer<void>? gate = recommendGate;
    if (gate != null) {
      await gate.future;
    }
    return super.getRecommThread(pageThreadCount, pn);
  }

  @override
  Future<TiebaUserProfile> getUserInfo({
    required String uid,
    int pn = 1,
  }) async {
    userInfoCalls++;
    final Completer<void>? gate = userInfoGate;
    if (gate != null) {
      await gate.future;
    }
    return super.getUserInfo(uid: uid, pn: pn);
  }

  @override
  Future<List<TiebaConversation>> getConversations() async {
    conversationCalls++;
    final Completer<void>? gate = conversationsGate;
    if (gate != null) {
      await gate.future;
    }
    return super.getConversations();
  }
}

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
      scaffoldMessengerKey: Fluttertoast.messengerKey,
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: const HomePage(),
    ),
  );
}

void main() {
  late _ControlledRefreshApi api;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'uid': '10001',
      'userName': '烤面包边',
    });
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    api = _ControlledRefreshApi();
    Global.tiebaAPI = api;
    MessageReminder.reset();
  });

  testWidgets('桌面壳层点击刷新按钮时显示旋转图标、顶部进度条并屏蔽重复点击', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    int calls = 0;
    Completer<void> gate = Completer<void>();

    await tester.pumpWidget(
      MultiProvider(
        providers: <ChangeNotifierProvider<dynamic>>[
          ChangeNotifierProvider<APPSettingProvider>(
            create: (_) => APPSettingProvider(),
          ),
          ChangeNotifierProvider<User>(
            create: (_) => User(),
          ),
        ],
        child: MaterialApp(
          theme: TiebananaTheme.light(seedOf('blue'), 16),
          home: DesktopShellFrame(
            title: '首页',
            activeTab: 0,
            onRefresh: () {
              calls++;
              return gate.future;
            },
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byTooltip('刷新 (F5)'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(calls, 1);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byTooltip('正在刷新…'), findsOneWidget);

    // 刷新过程中再次点击不重复触发
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    expect(calls, 1);

    // 完成刷新并跑完收尾旋转动画
    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byTooltip('刷新 (F5)'), findsOneWidget);

    // 收尾后可以再次刷新
    gate = Completer<void>();
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pump();
    expect(calls, 2);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('宽屏主界面点击刷新：顶栏与当前页签均有加载指示，失败时给出提示', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrapHome());
    await tester.pumpAndSettle();

    expect(find.byType(DesktopShellFrame), findsOneWidget);
    final int initialLikesCalls = api.refreshLikesCount;

    // 1. 首页点击刷新：顶栏出现进度条，同时页内拉出刷新指示器
    api.refreshLikesGate = Completer<void>();
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(api.refreshLikesCount, initialLikesCalls + 1);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);
    // 只刷新当前激活页签（首页），不会误触未打开的动态页签
    expect(api.recommendCalls, 0);

    api.refreshLikesGate!.complete();
    api.refreshLikesGate = null;
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(RefreshProgressIndicator), findsNothing);

    // 2. 首页刷新失败但已有数据时，保留列表并弹出错误提示
    api.failNextRefreshLikes = true;
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pumpAndSettle();

    expect(find.text('测试'), findsOneWidget);
    expect(find.text('刷新失败，请稍后重试'), findsOneWidget);

    // 3. 切到动态页签后点击刷新：顶栏进度条与页内刷新指示器同时出现
    await tester.tap(find.text('动态').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final int recommendBefore = api.recommendCalls;

    api.recommendGate = Completer<void>();
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(api.recommendCalls, recommendBefore + 1);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    api.recommendGate!.complete();
    api.recommendGate = null;
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(RefreshProgressIndicator), findsNothing);

    // 4. 切到消息页签后点击刷新：私信列表拉出刷新指示器且顶栏显示进度条
    await tester.tap(find.text('消息').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 50));
    final int convBefore = api.conversationCalls;

    api.conversationsGate = Completer<void>();
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(api.conversationCalls, convBefore + 1);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    api.conversationsGate!.complete();
    api.conversationsGate = null;
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(RefreshProgressIndicator), findsNothing);

    // 5. 切到个人与设置页签后点击刷新：顶栏与页面均显示加载指示
    await tester.tap(find.text('个人与设置').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('我的空间'), findsOneWidget);
    final int userBefore = api.userInfoCalls;

    api.userInfoGate = Completer<void>();
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(api.userInfoCalls, userBefore + 1);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    api.userInfoGate!.complete();
    api.userInfoGate = null;
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
