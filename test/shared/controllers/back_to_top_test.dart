// 返回键的「先回顶再退出」回归：
// 1) BackToTopController 的注册 / 注销语义；
// 2) 动态流滚动后由返回键回顶并刷新，刷新完再轮到「再按一次退出」。
import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiebanana/shared/controllers/back_to_top_controller.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/recommend/pages/recommend_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/floating_search_app_bar.dart';

import '../../support/fake_thread.dart';

TiebaThreadInfo _thread(int i) => fakeRecommendThread(
      tid: '$i',
      title: '第 $i 条推荐贴，标题长一点好撑出可滚动的高度',
      text: '正文摘要，够两行就行',
    );

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
  setUp(() {
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
  });

  test('协作对象：注册者可回顶、注销后不再拦截返回', () async {
    final BackToTopController controller = BackToTopController();
    final Object page = Object();

    expect(controller.needsBackToTop, isFalse, reason: '没人注册时不应拦截');

    bool scrolled = false;
    int tops = 0;
    controller.attach(page,
        isScrolled: () => scrolled, onBackToTop: () async => tops++);

    scrolled = true;
    expect(controller.needsBackToTop, isTrue);
    await controller.backToTop();
    expect(tops, 1);

    // 别人注销不掉当前注册
    controller.detach(Object());
    expect(controller.needsBackToTop, isTrue);

    controller.detach(page);
    expect(controller.needsBackToTop, isFalse);
  });

  testWidgets('动态流滚动后：返回先回顶刷新，再轮到两次退出', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();

    int loads = 0;
    final FloatingSearchBarController search = FloatingSearchBarController();
    final BackToTopController back = BackToTopController();
    addTearDown(search.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(RecommendPan(
      controller: search,
      backController: back,
      loader: (int pageThreadCount, int pn) async {
        loads++;
        return fakeRecommendPage(List<TiebaThreadInfo>.generate(10, _thread));
      },
    )));
    await tester.pump();

    expect(loads, 1);
    expect(back.needsBackToTop, isFalse, reason: '列表在顶部时返回不该被吞掉');

    // 往下滚：此时按返回应该先回顶。
    // 注意滚动到底部会顺带触发翻页（loads 会先涨一次），所以按增量断言。
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(back.needsBackToTop, isTrue);
    final int loadsBeforeBack = loads;

    // 动态流的滚动位置：用它验「平滑回顶」而不是瞬移。
    final ScrollPosition position = tester
        .state<ScrollableState>(find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first)
        .position;
    final double scrolledTo = position.pixels;
    expect(scrolledTo, greaterThan(0));

    await back.backToTop();
    await tester.pump();
    // 走一小段：应该在回去的路上，而不是已经瞬移到 0。
    await tester.pump(const Duration(milliseconds: 60));
    expect(position.pixels, lessThan(scrolledTo));
    expect(position.pixels, greaterThan(0), reason: '回顶要平滑，不能瞬移');

    // 动画跑完（250ms）落到顶部
    await tester.pump(const Duration(milliseconds: 400));
    expect(position.pixels, 0);

    expect(loads, greaterThanOrEqualTo(loadsBeforeBack + 1),
        reason: '回顶同时要刷新推荐流');
    expect(back.needsBackToTop, isFalse, reason: '回顶后应轮到退出流程');
    expect(tester.takeException(), isNull);

    // 翻页节流是 2s 冷却计时器，跑完它再结束，避免 pending timer 断言。
    await tester.pump(const Duration(seconds: 3));
  });
}
