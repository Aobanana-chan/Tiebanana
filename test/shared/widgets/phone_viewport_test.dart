import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/phone_viewport.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  for (final platform in [TargetPlatform.windows, TargetPlatform.android]) {
    testWidgets('$platform 的内容约束与 MediaQuery 保持一致', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 800);
      addTearDown(tester.view.reset);
      Size? mediaSize;
      BoxConstraints? contentConstraints;
      TextScaler? textScaler;
      double? pixelRatio;
      const contentKey = Key('content');

      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.3),
          ),
          child: PhoneViewport(child: child!),
        ),
        home: LayoutBuilder(builder: (context, constraints) {
          mediaSize = MediaQuery.sizeOf(context);
          textScaler = MediaQuery.textScalerOf(context);
          pixelRatio = MediaQuery.devicePixelRatioOf(context);
          contentConstraints = constraints;
          return const SizedBox.expand(key: contentKey);
        }),
      ));

      final width = platform == TargetPlatform.windows ? 400.0 : 900.0;
      final scale = 900 / width;
      expect(mediaSize, Size(width, 800 / scale));
      expect(contentConstraints!.maxWidth, width);
      expect(contentConstraints!.maxHeight, 800 / scale);
      expect(pixelRatio, scale);
      expect(textScaler!.scale(10), 13);
      expect(tester.getTopLeft(find.byKey(contentKey)), Offset.zero);
      final box = tester.renderObject<RenderBox>(find.byKey(contentKey));
      final bottomRight = box.localToGlobal(box.size.bottomRight(Offset.zero));
      expect(bottomRight.dx, closeTo(900, .001));
      expect(bottomRight.dy, closeTo(800, .001));

      tester.view.physicalSize = const Size(320, 600);
      await tester.pump();
      final narrowWidth = platform == TargetPlatform.windows ? 400.0 : 320.0;
      expect(mediaSize, Size(narrowWidth, 600 / (320 / narrowWidth)));
      expect(contentConstraints!.maxWidth, narrowWidth);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('Windows 弹窗仍位于手机内容区内', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 800);
    addTearDown(tester.view.reset);
    Size? dialogMediaSize;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => PhoneViewport(child: child!),
      home: Builder(builder: (context) {
        return Center(
          child: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) {
                dialogMediaSize = MediaQuery.sizeOf(context);
                return const AlertDialog(content: Text('手机宽度弹窗'));
              },
            ),
            child: const Text('打开'),
          ),
        );
      }),
    ));
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(dialogMediaSize, const Size(400, 800 / 2.25));
    final dialog = tester.getRect(find.byType(AlertDialog));
    expect(dialog.left, greaterThanOrEqualTo(0));
    expect(dialog.right, lessThanOrEqualTo(900));
    expect(dialog.center.dx, closeTo(450, .001));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Windows 在高 DPI 下整体缩放并换算系统边距', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(1500, 2668);
    addTearDown(tester.view.reset);
    MediaQueryData? actual;
    var taps = 0;
    const targetKey = Key('target');

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 30),
          viewPadding: const EdgeInsets.only(top: 30),
          viewInsets: const EdgeInsets.only(bottom: 300),
          systemGestureInsets: const EdgeInsets.only(left: 15),
        ),
        child: PhoneViewport(child: child!),
      ),
      home: Builder(builder: (context) {
        actual = MediaQuery.of(context);
        return Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onTap: () => taps++,
            child: const SizedBox(
              key: targetKey,
              width: 100,
              height: 50,
              child: ColoredBox(color: Colors.blue),
            ),
          ),
        );
      }),
    ));

    const scale = 750 / 400;
    expect(actual!.size, const Size(400, 1334 / scale));
    expect(actual!.devicePixelRatio, 2 * scale);
    expect(actual!.padding.top, 30 / scale);
    expect(actual!.viewPadding.top, 30 / scale);
    expect(actual!.viewInsets.bottom, 300 / scale);
    expect(actual!.systemGestureInsets.left, 15 / scale);
    final box = tester.renderObject<RenderBox>(find.byKey(targetKey));
    expect(box.localToGlobal(const Offset(100, 50)),
        const Offset(100 * scale, 50 * scale));
    await tester.tapAt(const Offset(90 * scale, 40 * scale));
    expect(taps, 1);
    debugDefaultTargetPlatformOverride = null;
  });

  test('Windows 主题使用与 Android 相同的控件密度及点击区域', () {
    final seed = seedOf('blue');
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final android = TiebananaTheme.light(seed, 16);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final windows = TiebananaTheme.light(seed, 16);
    expect(windows.visualDensity, android.visualDensity);
    expect(windows.materialTapTargetSize, android.materialTapTargetSize);
  });

  testWidgets('原生纹理使用实际显示尺寸和 DPI，缩放后点击坐标正确', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(1500, 2668);
    addTearDown(tester.view.reset);
    MediaQueryData? actual;
    BoxConstraints? nativeConstraints;
    var taps = 0;
    const nativeKey = Key('native');
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => PhoneViewport(child: child!),
      home: Column(children: [
        const SizedBox(height: 54),
        Expanded(
          child: NativeResolutionViewport(
            child: LayoutBuilder(builder: (context, constraints) {
              actual = MediaQuery.of(context);
              nativeConstraints = constraints;
              return GestureDetector(
                onTap: () => taps++,
                child: const ColoredBox(key: nativeKey, color: Colors.blue),
              );
            }),
          ),
        ),
      ]),
    ));

    const scale = 750 / 400;
    const actualSize = Size(750, 1334 - 54 * scale);
    expect(actual!.devicePixelRatio, 2);
    expect(actual!.size.width, closeTo(actualSize.width, .001));
    expect(actual!.size.height, closeTo(actualSize.height, .001));
    expect(nativeConstraints!.maxWidth, closeTo(actualSize.width, .001));
    expect(nativeConstraints!.maxHeight, closeTo(actualSize.height, .001));
    final box = tester.renderObject<RenderBox>(find.byKey(nativeKey));
    final origin = box.localToGlobal(Offset.zero);
    final point = box.localToGlobal(const Offset(700, 1000));
    expect(origin.dy, closeTo(54 * scale, .001));
    expect(point.dx - origin.dx, closeTo(700, .001));
    expect(point.dy - origin.dy, closeTo(1000, .001));
    await tester.tapAt(point);
    expect(taps, 1);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
