import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/features/thread/widgets/thread_floor_card.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';

void main() {
  for (final isSubPost in [false, true]) {
    testWidgets('楼中楼面板${isSubPost ? '回复' : '父楼层'}头像打开用户资料', (tester) async {
      Global.setting = APPSetting.fromJson(defaultAPPSetting);
      final api = DemoTiebaApi(latency: Duration.zero);
      Global.tiebaAPI = api;
      final page = await api.getThreadPage('123');
      final floor = await api.getInnerFloor('123', '3');
      final post = isSubPost ? floor.subposts.first : floor.post;
      final author = floor.authors[post.uid]!;
      RouteSettings? openedRoute;

      await tester.pumpWidget(MaterialApp(
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        onGenerateRoute: (settings) {
          openedRoute = settings;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('用户资料')),
          );
        },
        home: Scaffold(
          body: InnerFloorCard(
            author: author,
            postMain: post,
            threadID: '123',
            isSpid: false,
            forum: page,
            floorId: '3',
          ),
        ),
      ));

      await tester.tap(find.byType(Avatar));
      await tester.pumpAndSettle();

      expect(openedRoute?.name, PageRouter.user);
      expect(openedRoute?.arguments, author.id);
      expect(find.text('用户资料'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
