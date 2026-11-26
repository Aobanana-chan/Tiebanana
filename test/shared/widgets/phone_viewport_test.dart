import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/phone_viewport.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  for (final platform in [TargetPlatform.windows, TargetPlatform.android]) {
    testWidgets('$platform 透传原生约束与 MediaQuery', (tester) async {
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

      expect(mediaSize, const Size(900, 800));
      expect(contentConstraints!.maxWidth, 900);
      expect(contentConstraints!.maxHeight, 800);
      expect(pixelRatio, 1);
      expect(textScaler!.scale(10), 13);
      expect(tester.getTopLeft(find.byKey(contentKey)), Offset.zero);

      tester.view.physicalSize = const Size(640, 800);
      await tester.pump();
      expect(mediaSize, const Size(640, 800));
      expect(contentConstraints!.maxWidth, 640);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('Windows 弹窗按窗口居中', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
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
                return const AlertDialog(content: Text('桌面宽度弹窗'));
              },
            ),
            child: const Text('打开'),
          ),
        );
      }),
    ));
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(dialogMediaSize, const Size(1280, 800));
    final dialog = tester.getRect(find.byType(AlertDialog));
    expect(dialog.left, greaterThanOrEqualTo(0));
    expect(dialog.right, lessThanOrEqualTo(1280));
    expect(dialog.center.dx, closeTo(640, .001));
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

  testWidgets('原生纹理在透传视口下保持 1:1 尺寸和 DPI', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(2560, 1600);
    addTearDown(tester.view.reset);
    MediaQueryData? actual;
    BoxConstraints? nativeConstraints;
    var taps = 0;
    const nativeKey = Key('native');
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => PhoneViewport(child: child!),
      home: Column(children: [
        const SizedBox(height: 56),
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

    expect(actual!.devicePixelRatio, 2);
    expect(actual!.size.width, closeTo(1280, .001));
    expect(actual!.size.height, closeTo(800 - 56, .001));
    expect(nativeConstraints!.maxWidth, closeTo(1280, .001));
    expect(nativeConstraints!.maxHeight, closeTo(800 - 56, .001));
    final box = tester.renderObject<RenderBox>(find.byKey(nativeKey));
    final point = box.localToGlobal(const Offset(640, 400));
    await tester.tapAt(point);
    expect(taps, 1);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
