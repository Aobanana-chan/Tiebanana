import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/shared/media/video_fullscreen_route.dart';

/// 视频全屏页不再是统一的左右翻页：整页只淡入淡出，
/// 画面本身的放大由卡片和全屏页之间的 Hero 完成。
void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  Navigator.of(context).push<void>(VideoFullScreenRoute(
                builder: (_) => const Scaffold(body: Text('全屏页')),
              )),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('打开'));
    await tester.pump();
  }

  testWidgets('全屏路由淡入，不做整页翻页', (tester) async {
    await open(tester);
    await tester.pump(const Duration(milliseconds: 120));

    final Finder fade = find.ancestor(
        of: find.text('全屏页'), matching: find.byType(FadeTransition));
    expect(fade, findsWidgets);
    expect(tester.widget<FadeTransition>(fade.first).opacity.value,
        allOf(greaterThan(0), lessThan(1)));
    // 翻页会带着页面横向位移，淡入时页面始终在原位。
    expect(tester.getTopLeft(find.text('全屏页')), const Offset(0, 0));

    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.widget<FadeTransition>(fade.first).opacity.value, 1);
    expect(tester.getTopLeft(find.text('全屏页')), const Offset(0, 0));
  });

  testWidgets('退出全屏同样淡出，系统返回也能收尾', (tester) async {
    await open(tester);
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final Finder fade = find.ancestor(
        of: find.text('全屏页'), matching: find.byType(FadeTransition));
    expect(tester.widget<FadeTransition>(fade.first).opacity.value,
        allOf(greaterThan(0), lessThan(1)));
    expect(tester.getTopLeft(find.text('全屏页')), const Offset(0, 0));

    await tester.pumpAndSettle();
    expect(find.text('全屏页'), findsNothing);
    expect(find.text('打开'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
