// 吧广播历史页：列表、阅读数、配额面板与空/错状态的可见部分。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/forum/pages/forum_broadcast_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

Widget _app(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: TiebananaTheme.light(seedOf('blue'), 16),
    home: child,
    routes: <String, WidgetBuilder>{
      PageRouter.threadPage: (_) => const Scaffold(body: Text('帖子详情')),
    },
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

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
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
}
