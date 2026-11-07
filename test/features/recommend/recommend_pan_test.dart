// 动态页数据行为回归：刷新后续读条出现在「新一页」与「旧内容」的交界处。
import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/recommend/pages/recommend_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/floating_search_app_bar.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';

import '../../support/fake_thread.dart';

const String resumeLabel = '上次读到这里，点击刷新';

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
  setUp(() {
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
  });

  testWidgets('首屏没有续读条，刷新后才标在「新一页」下沿', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();

    int calls = 0;
    final FloatingSearchBarController search = FloatingSearchBarController();
    addTearDown(search.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(RecommendPan(
      controller: search,
      loader: (int pageThreadCount, int pn) async {
        calls++;
        // 翻页返回空：让列表停在「首屏 10 条」，本节只关心续读条的位置。
        if (pn > 1) {
          return RecommendPage(threads: const []);
        }
        return fakeRecommendPage(List<TiebaThreadInfo>.generate(
            10, (int i) => _thread('第$calls次-$i')));
      },
    )));
    await tester.pump();

    // 首屏是「第一次打开」，没有上一次读到哪
    expect(calls, 1);
    expect(find.text('第1次-0'), findsOneWidget);
    expect(find.text(resumeLabel), findsNothing);

    // 下拉刷新：这一次刷新把「上次读到这里」标出来
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1200);
    // 不用 pumpAndSettle：动态流里随时可能有在转的加载指示，settle 不会停。
    for (int i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(calls, 2, reason: '刷新是重新拉第 1 页');
    expect(find.text('第2次-0'), findsOneWidget, reason: '新一页在上面');

    // 滚到交界处：让「新一页最后一条 / 续读条 / 旧内容第一条」同屏，才好比顺序。
    // （List 是懒构建的，没进视口的那几条找不到。）
    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pump();

    final double lastNew = tester.getTopLeft(find.text('第2次-9')).dy;
    final double resume = tester.getTopLeft(find.text(resumeLabel)).dy;
    final double firstOld = tester.getTopLeft(find.text('第1次-0')).dy;
    expect(lastNew, lessThan(resume));
    expect(resume, lessThan(firstOld));

    // 排版：续读条夹在两条帖子中间，上下留白要一样，且紧凑但不贴住卡片
    // （原来上 16 下 2，看着是「偏下」的）。
    final Rect bar = tester.getRect(find
        .ancestor(of: find.text(resumeLabel), matching: find.byType(InkWell))
        .first);
    final int cardCount = find.byType(ThreadSummary).evaluate().length;
    final List<Rect> cards = <Rect>[
      for (int i = 0; i < cardCount; i++)
        tester.getRect(find.byType(ThreadSummary).at(i)),
    ];
    // 懒构建：只拿「离续读条最近」的上下两张卡
    final Rect above = cards
        .where((Rect r) => r.bottom <= bar.top + 1)
        .reduce((Rect a, Rect b) => a.bottom > b.bottom ? a : b);
    final Rect below = cards
        .where((Rect r) => r.top >= bar.bottom - 1)
        .reduce((Rect a, Rect b) => a.top < b.top ? a : b);

    expect(bar.height, 36, reason: '比普通按钮矮一点，别把留白撑大');
    // 帖子卡片的盒子含它自己的 gapSm 下边距 —— 那就是上面的留白，不该再加一份
    expect(bar.top - above.bottom, moreOrLessEquals(0, epsilon: .5),
        reason: '续读条上方只保留卡片自己的下边距');
    expect(below.top - bar.bottom, moreOrLessEquals(TiebananaMetrics.gapSm, epsilon: .5),
        reason: '下方留白与卡片间距一致，上下才对称');
    expect(tester.takeException(), isNull);

    // 翻页节流是 2s 冷却计时器，跑完它再结束。
    await tester.pump(const Duration(seconds: 3));
  });
}
