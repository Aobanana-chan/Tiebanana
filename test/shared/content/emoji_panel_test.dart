import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tiebanana/shared/content/emoji_panel.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

Future<void> _sendWheel(
  WidgetTester tester,
  Offset position,
  Offset scrollDelta,
) async {
  final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
  tester.binding.handlePointerEvent(pointer.hover(position));
  await tester.pump();
  tester.binding.handlePointerEvent(pointer.scroll(scrollDelta));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('手机版 EmojiPanel 下部紧凑且支持滚轮切页', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: EmojiPanel(controller: controller, height: 267),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Rect panelRect = tester.getRect(find.byType(EmojiPanel));
    final Rect indicatorRect = tester.getRect(find.byType(SmoothPageIndicator));
    // 面板紧凑，下部不留大块空白
    expect(panelRect.height, lessThan(185));
    expect(panelRect.bottom - indicatorRect.bottom, lessThanOrEqualTo(12));
    // 指示器居中
    expect(indicatorRect.center.dx, closeTo(panelRect.center.dx, 0.5));

    final PageView pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller?.page?.round() ?? 0, 0);

    // 向下滚动鼠标滚轮 -> 下一页
    await _sendWheel(tester, panelRect.center, const Offset(0, 100));
    expect(pageView.controller?.page?.round(), 1);

    // 向上滚动鼠标滚轮 -> 上一页
    await _sendWheel(tester, panelRect.center, const Offset(0, -100));
    expect(pageView.controller?.page?.round(), 0);

    // 点击表情插入文本
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    expect(controller.text, '#(呵呵)');
    expect(tester.takeException(), isNull);
  });

  testWidgets('桌面端 DesktopEmojiPopover 布局紧凑，页码与切页按钮位于下方中间且样式对齐手机版',
      (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: 'abc');
    controller.selection = const TextSelection(baseOffset: 3, extentOffset: 1);
    addTearDown(controller.dispose);
    int insertedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        home: Scaffold(
          body: Center(
            child: DesktopEmojiPopover(
              controller: controller,
              onInserted: () => insertedCount++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Rect popRect = tester.getRect(find.byType(DesktopEmojiPopover));
    final Rect gridRect = tester.getRect(find.byType(PageView));
    final Rect dotsRect = tester.getRect(find.byType(SmoothPageIndicator));
    final Rect prevRect =
        tester.getRect(find.byIcon(Icons.chevron_left_rounded));
    final Rect nextRect =
        tester.getRect(find.byIcon(Icons.chevron_right_rounded));

    // 高度紧凑（不再留出 280dp 的大段底部空白）
    expect(popRect.height, lessThan(220));
    expect(popRect.bottom - dotsRect.bottom, lessThanOrEqualTo(20));

    // 页码指示器与切页按钮位于网格下方且水平居中
    expect(dotsRect.top, greaterThan(gridRect.bottom));
    expect(prevRect.top, greaterThan(gridRect.bottom));
    expect(nextRect.top, greaterThan(gridRect.bottom));
    expect(dotsRect.center.dx, closeTo(popRect.center.dx, 0.5));
    expect(prevRect.right, lessThan(dotsRect.left));
    expect(nextRect.left, greaterThan(dotsRect.right));

    // 样式与手机版相同的 WormEffect
    final SmoothPageIndicator indicator =
        tester.widget<SmoothPageIndicator>(find.byType(SmoothPageIndicator));
    expect(indicator.effect, isA<WormEffect>());

    // 不再显示顶部 1 / 6 文本页码
    expect(find.textContaining('/'), findsNothing);

    final PageView pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller?.page?.round() ?? 0, 0);

    // 点击下一页按钮
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(pageView.controller?.page?.round(), 1);

    // 点击上一页按钮
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(pageView.controller?.page?.round(), 0);

    // 滚轮向下切页（两次），向上切页（一次）
    await _sendWheel(tester, popRect.center, const Offset(0, 120));
    expect(pageView.controller?.page?.round(), 1);
    await _sendWheel(tester, popRect.center, const Offset(0, 120));
    expect(pageView.controller?.page?.round(), 2);
    await _sendWheel(tester, popRect.center, const Offset(0, -120));
    expect(pageView.controller?.page?.round(), 1);

    // 小步长触控板增量累加切页
    await _sendWheel(tester, popRect.center, const Offset(0, 10));
    await _sendWheel(tester, popRect.center, const Offset(0, 16));
    expect(pageView.controller?.page?.round(), 2);

    // 反向选区插入表情不会抛 RangeError
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    expect(insertedCount, 1);
    expect(controller.text, startsWith('a#('));
    expect(tester.takeException(), isNull);
  });

  testWidgets('宽屏锚点打开 showEmojiPopover：贴合按钮上方且支持滚轮与点击圆点切页',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    final GlobalKey anchorKey = GlobalKey();
    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        home: Scaffold(
          body: Align(
            alignment: const Alignment(0.7, 0.2),
            child: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  key: anchorKey,
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: () => showEmojiPopover(
                    context: context,
                    anchorKey: anchorKey,
                    controller: controller,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Rect anchorRect = tester.getRect(find.byKey(anchorKey));
    await tester.tap(find.byKey(anchorKey));
    await tester.pumpAndSettle();

    expect(find.byType(DesktopEmojiPopover), findsOneWidget);
    final Rect popRect = tester.getRect(find.byType(DesktopEmojiPopover));
    // Popover 底部紧贴锚点上方（~8dp 间距），不会因预设高度过大而悬空留白
    expect(anchorRect.top - popRect.bottom, inInclusiveRange(4.0, 14.0));

    final PageView pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller?.page?.round() ?? 0, 0);

    await _sendWheel(tester, popRect.center, const Offset(0, 100));
    expect(pageView.controller?.page?.round(), 1);
    expect(tester.takeException(), isNull);
  });
}
