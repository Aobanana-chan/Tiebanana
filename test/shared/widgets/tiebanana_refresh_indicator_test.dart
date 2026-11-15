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

  testWidgets('下拉过阈值后往回拉，指示器完全收起且不触发刷新',
      (WidgetTester tester) async {
    int calls = 0;
    await pumpIndicator(tester, onRefresh: () async => calls++);

    final TestGesture gesture =
        await tester.startGesture(const Offset(195, 300));
    // 越过触发距离（默认 80），再用同样距离拉回起点。
    await gesture.moveBy(const Offset(0, 160));
    await tester.pump();
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);
    expect(calls, 0);

    await gesture.moveBy(const Offset(0, -160));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(RefreshProgressIndicator), findsNothing,
        reason: '手指回到起点，指示器也应完全缩回去');
    expect(calls, 0, reason: '没有拉到阈值就松手不该刷新');
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
