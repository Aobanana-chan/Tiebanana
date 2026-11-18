// 吧广播聚合流：按日期分组、跨吧卡片、互动数只读。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/message/pages/broadcast_feed_page.dart';
import 'package:tiebanana/features/message/widgets/broadcast_feed_card.dart';
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

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    Global.tiebaAPI = DemoTiebaApi(latency: Duration.zero);
  });

  testWidgets('跨吧卡片按日期分组，点击进入关联帖子', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const BroadcastFeedPage()));
    await tester.pump();
    await tester.pump();

    expect(find.text('吧广播'), findsOneWidget);
    expect(find.byType(BroadcastFeedCard), findsAtLeastNWidgets(5));
    expect(find.text('今天的晚霞好像被打翻了'), findsOneWidget);
    expect(find.text('孙笑川吧'), findsWidgets);
    expect(find.text('分享'), findsOneWidget);
    expect(find.text('153'), findsOneWidget);
    expect(find.text('247'), findsOneWidget);

    await tester.tap(find.text('今天的晚霞好像被打翻了'));
    await tester.pumpAndSettle();
    expect(find.text('帖子详情'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('未登录显示登录态，不装成空列表', (WidgetTester tester) async {
    Global.tiebaAPI = DemoTiebaApi(loggedIn: false, latency: Duration.zero);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const BroadcastFeedPage()));
    await tester.pump();
    await tester.pump();

    expect(find.text('登录后才能看吧广播'), findsOneWidget);
    expect(find.byType(BroadcastFeedCard), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
