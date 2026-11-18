// 下拉刷新指示器的行为回归：跟手回缩 + 代码触发。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/shared/widgets/tiebanana_refresh_indicator.dart';

Widget _app(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: child),
  );
}

Widget _list(ScrollController controller) {
  return ListView.builder(
    controller: controller,
    physics: const AlwaysScrollableScrollPhysics(),
    itemCount: 20,
    itemBuilder: (BuildContext context, int index) =>
        SizedBox(height: 100, child: Text('row $index')),
  );
}

void main() {
  late ScrollController scroll;

  setUp(() {
    scroll = ScrollController();
  });

  tearDown(() {
    scroll.dispose();
  });

  Future<void> pumpIndicator(
    WidgetTester tester, {
    required Future<void> Function() onRefresh,
    TiebananaRefreshController? controller,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(TiebananaRefreshIndicator(
      controller: controller,
      onRefresh: onRefresh,
      child: _list(scroll),
    )));
  }

  testWidgets('指示器到阈值后不再下移，轻微上拉立即回缩并取消刷新',
      (WidgetTester tester) async {
    int calls = 0;
    await pumpIndicator(tester, onRefresh: () async => calls++);

    final TestGesture gesture =
        await tester.startGesture(const Offset(195, 300));
    // 越过触发距离（默认 80），记录完全展开的位置。
    await gesture.moveBy(const Offset(0, 160));
    await tester.pump();
    final Finder indicator = find.byType(RefreshProgressIndicator);
    expect(indicator, findsOneWidget);
    expect(calls, 0);

    final double armedY = tester.getCenter(indicator).dy;
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(tester.getCenter(indicator).dy, armedY);
    final Finder reveal = find.ancestor(
      of: indicator,
      matching: find.byType(SizeTransition),
    );
    await gesture.moveBy(const Offset(0, -8));
    await tester.pump();
    expect(tester.widget<SizeTransition>(reveal).sizeFactor.value, closeTo(0.9, 0.01),
        reason: '超过阈值的位移不应抵消反向拖动');
    await gesture.up();
    await tester.pumpAndSettle();

    expect(indicator, findsNothing);
    expect(calls, 0, reason: '退回阈值以下再松手不该刷新');
  });

  testWidgets('下拉过阈值松手触发刷新，回调结束后指示器收起',
      (WidgetTester tester) async {
    int calls = 0;
    final Completer<void> done = Completer<void>();
    await pumpIndicator(tester, onRefresh: () async {
      calls++;
      await done.future;
    });

    final TestGesture gesture =
        await tester.startGesture(const Offset(195, 300));
    await gesture.moveBy(const Offset(0, 160));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(calls, 1);
    expect(find.byType(RefreshProgressIndicator), findsOneWidget,
        reason: '刷新回调未结束前保持转圈');

    done.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets('控制器 show 从代码拉出指示器并刷新', (WidgetTester tester) async {
    int calls = 0;
    final TiebananaRefreshController controller = TiebananaRefreshController();
    await pumpIndicator(
      tester,
      controller: controller,
      onRefresh: () async => calls++,
    );

    expect(controller.isAttached, isTrue);
    controller.show();
    await tester.pump();
    expect(find.byType(RefreshProgressIndicator), findsOneWidget,
        reason: '代码刷新也要显示指示器，而不是静默刷新');

    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, 1);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });
}
