// 吧广播历史页：列表、阅读数、配额面板、空/错状态与宽屏双栏布局。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/features/forum/pages/forum_broadcast_page.dart';
import 'package:tiebanana/features/forum/state/forum_state.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';

Widget _app(Widget child) {
  return MultiProvider(
    providers: <ChangeNotifierProvider<dynamic>>[
      ChangeNotifierProvider<APPSettingProvider>(
        create: (_) => APPSettingProvider(),
      ),
      ChangeNotifierProvider<User>(create: (_) => User()),
      ChangeNotifierProvider<ForumState>(create: (_) => ForumState()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: child,
      routes: <String, WidgetBuilder>{
        PageRouter.threadPage: (_) => const Scaffold(body: Text('帖子详情')),
        PageRouter.forumHome: (_) => const Scaffold(body: Text('吧主页')),
      },
    ),
  );
}

class _EmptyBroadcastApi extends DemoTiebaApi {
  _EmptyBroadcastApi() : super(latency: Duration.zero);

  @override
  Future<TiebaBroadcastPage> getBroadcastHistory({
    required String forumId,
    int cursor = 0,
    int count = 15,
  }) async {
    return TiebaBroadcastPage.empty;
  }
}

class _BrokenBroadcastApi extends DemoTiebaApi {
  _BrokenBroadcastApi() : super(latency: Duration.zero);

  @override
  Future<TiebaBroadcastPage> getBroadcastHistory({
    required String forumId,
    int cursor = 0,
    int count = 15,
  }) async {
    throw Exception('history failed');
  }
}

class _ReadonlyBroadcastApi extends DemoTiebaApi {
  _ReadonlyBroadcastApi() : super(latency: Duration.zero);

  @override
  Future<TiebaBroadcastQuota?> getBroadcastQuota(String forumId) async => null;
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
  });

  testWidgets('历史列表展示协议字段，配额面板只读', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const ForumBroadcastPage(
      data: ForumBroadcastRouteData(
        forumId: '101',
        forumName: '校园吧',
      ),
    )));
    await tester.pump();
    await tester.pump();

    expect(find.text('关于期末考试安排的通知'), findsOneWidget);
    expect(find.text('吧规更新：禁止发布交易信息'), findsOneWidget);
    expect(find.text('推送给 12,480 人'), findsNWidgets(2));
    expect(find.text('查看帖子'), findsOneWidget);
    expect(find.text('剩余 2 次'), findsOneWidget);

    await tester.tap(find.text('发吧广播'));
    await tester.pumpAndSettle();
    expect(find.text('本月吧广播'), findsOneWidget);
    expect(find.text('去发布'), findsOneWidget);
    expect(find.text('已用 3 次'), findsOneWidget);
    expect(find.text('共 5 次'), findsOneWidget);

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('本月吧广播'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('空态不补假内容，仍有额度时提供发布入口', (WidgetTester tester) async {
    Global.tiebaAPI = _EmptyBroadcastApi();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const ForumBroadcastPage(
      data: ForumBroadcastRouteData(
        forumId: '101',
        forumName: '校园吧',
      ),
    )));
    await tester.pump();
    await tester.pump();

    expect(find.text('这个吧还没有吧广播'), findsOneWidget);
    expect(find.text('吧务发布后会出现在这里'), findsOneWidget);
    expect(find.text('发吧广播'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('首次加载失败走错误态，不装成空列表', (WidgetTester tester) async {
    Global.tiebaAPI = _BrokenBroadcastApi();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const ForumBroadcastPage(
      data: ForumBroadcastRouteData(
        forumId: '101',
        forumName: '校园吧',
      ),
    )));
    await tester.pump();
    await tester.pump();

    expect(find.text('广播没有加载出来'), findsOneWidget);
    expect(find.text('这个吧还没有吧广播'), findsNothing);
    expect(find.text('重试'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('宽屏 1280px 渲染桌面壳层、停靠配额卡与居中配额弹窗', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const ForumBroadcastPage(
      data: ForumBroadcastRouteData(
        forumId: '101',
        forumName: '校园吧',
      ),
    )));
    await tester.pump();
    await tester.pump();

    expect(find.byType(DesktopShellFrame), findsOneWidget);
    expect(find.text('本月吧广播'), findsOneWidget);
    expect(find.text('去网页版发布'), findsOneWidget);
    expect(find.text('查看配额详情'), findsOneWidget);
    expect(find.text('已加载条数'), findsOneWidget);
    expect(find.text('进入吧主页'), findsOneWidget);

    await tester.tap(find.text('查看配额详情'));
    await tester.pumpAndSettle();
    expect(find.text('去发布'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('去发布'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('宽屏无吧务配额时展示只读浏览模式，820px 半屏无溢出', (WidgetTester tester) async {
    Global.tiebaAPI = _ReadonlyBroadcastApi();
    for (final Size size in const <Size>[Size(1280, 800), Size(820, 760)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_app(const ForumBroadcastPage(
        data: ForumBroadcastRouteData(
          forumId: '101',
          forumName: '校园吧',
        ),
      )));
      await tester.pump();
      await tester.pump();

      expect(find.byType(DesktopShellFrame), findsOneWidget);
      expect(find.text('去网页版发布'), findsNothing);
      if (size.width >= 900) {
        expect(find.text('只读浏览模式'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
