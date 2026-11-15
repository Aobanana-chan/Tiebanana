// 「返回键先回顶并刷新」的可见反馈：回顶时也要像手势下拉那样显示指示器。
import 'dart:async';

import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/recommend/pages/recommend_page.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/controllers/back_to_top_controller.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/floating_search_app_bar.dart';

import '../../support/fake_thread.dart';

TiebaThreadInfo _thread(String title) =>
    fakeRecommendThread(tid: title, title: title, text: '正文摘要');

Widget _app(Widget child) {
  return MultiProvider(
    providers: <ChangeNotifierProvider<APPSettingProvider>>[
      ChangeNotifierProvider<APPSettingProvider>(
          create: (BuildContext context) => APPSettingProvider()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('返回键回顶时显示下拉刷新指示器，刷新完成后收起',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);

    final FloatingSearchBarController search = FloatingSearchBarController();
    addTearDown(search.dispose);
    final BackToTopController back = BackToTopController();

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    int calls = 0;
    await tester.pumpWidget(_app(RecommendPan(
      controller: search,
      backController: back,
      loader: (int pageThreadCount, int pn) async {
        calls++;
        return fakeRecommendPage(List<TiebaThreadInfo>.generate(
            10, (int i) => _thread('第$calls次-$i')));
      },
    )));
    await tester.pump();
    expect(find.text('第1次-0'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    expect(back.needsBackToTop, isTrue);

    final int callsBefore = calls;

    // 第一次按返回：回顶 + 刷新，指示器立即出现（而不是静默刷新）。
    unawaited(back.backToTop());
    await tester.pump();
    expect(find.byType(RefreshProgressIndicator), findsOneWidget,
        reason: '回顶刷新要显示下拉指示器');

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(RefreshProgressIndicator), findsOneWidget,
        reason: '刷新进行中保持转圈');
    expect(calls, callsBefore + 1);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(back.needsBackToTop, isFalse, reason: '列表已经回到顶部');

    // 翻页节流是 2s 冷却计时器，跑完它再结束。
    await tester.pump(const Duration(seconds: 3));
  });
}
