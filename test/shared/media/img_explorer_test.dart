import 'dart:ui' as ui;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/media/img_explorer.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';

void main() {
  setUp(() {
    Global.setting = APPSetting.fromJson(defaultAPPSetting)
      ..pictureLoadSetting = 1;
  });

  Future<void> open(WidgetTester tester, Widget page,
      {bool dark = false, Size size = const Size(390, 844)}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: dark
          ? TiebananaTheme.dark(seedOf('blue'), 16)
          : TiebananaTheme.light(seedOf('blue'), 16),
      home: page,
    ));
    await tester.pump();
  }

  for (final dark in [false, true]) {
    testWidgets('单图共用黑底浏览器且无原图时不显示原图按钮 dark=$dark', (tester) async {
      await open(
          tester,
          const ImgExplorer(
              imgUrl: 'https://test.invalid/avatar.png', heroTagSalt: 'avatar'),
          dark: dark);
      expect(find.text('1 / 1'), findsOneWidget);
      expect(find.byTooltip('保存图片'), findsOneWidget);
      expect(find.text('保存图片'), findsNothing);
      expect(find.text('查看原图'), findsNothing);
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          Colors.black);
      expect(find.bySemanticsLabel('第 1 张图片'), findsNothing);
      expect(find.text('预览'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('初始下标、缩略图切页与滑动同步页码', (tester) async {
    await open(
        tester,
        const ZoomedImgExplorer(
          imgUrls: [
            'https://test.invalid/a.png',
            'https://test.invalid/b.png',
            'https://test.invalid/c.png'
          ],
          highQualityUrls: ['https://test.invalid/a-original.png'],
          index: 1,
          heroTagSalt: 'pages',
        ));
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.bySemanticsLabel('第 1 张图片'), findsNothing);
    await tester.tap(find.byTooltip('展开缩略图'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.bySemanticsLabel('第 1 张图片'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('查看原图'), findsOneWidget);
    expect(find.byTooltip('保存原图'), findsOneWidget);
    await tester.drag(
        find.byType(ExtendedImageGesturePageView), const Offset(-350, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('查看原图'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('预览按需展开收起，保存操作使用半透明胶囊', (tester) async {
    await open(
        tester,
        const ZoomedImgExplorer(
          imgUrls: ['https://test.invalid/a.png', 'https://test.invalid/b.png'],
          heroTagSalt: 'compact',
        ),
        size: const Size(600, 300));
    expect(find.bySemanticsLabel('第 1 张图片'), findsNothing);
    final saveButton = tester.widget<TextButton>(find.ancestor(
        of: find.byIcon(Icons.download_rounded),
        matching: find.byType(TextButton)));
    final color = saveButton.style!.backgroundColor!.resolve({})!;
    expect(color.a, greaterThan(0));
    expect(color.a, lessThan(1));
    expect(saveButton.style!.shape!.resolve({}), isA<StadiumBorder>());
    final savePosition = tester.getRect(find.byTooltip('保存图片'));
    expect(savePosition.center.dx, greaterThan(450));
    expect(savePosition.bottom, lessThan(80));
    expect(find.text('—'), findsOneWidget);
    final togglePosition = tester.getRect(find.text('1 / 2'));
    expect(tester.getCenter(find.byTooltip('展开缩略图')).dx, closeTo(300, .1));
    await tester.tap(find.byTooltip('展开缩略图'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel('第 1 张图片'), findsOneWidget);
    expect(tester.getRect(find.byTooltip('保存图片')), savePosition);
    expect(tester.getRect(find.text('1 / 2')), togglePosition);
    expect(find.text('收起预览'), findsNothing);
    expect(tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
        .5);
    await tester.tap(find.byTooltip('收起缩略图'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel('第 1 张图片'), findsNothing);
    expect(find.byTooltip('展开缩略图'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('单击图片隐藏与恢复控件，不影响看图', (tester) async {
    await open(
        tester,
        const ImgExplorer(
            imgUrl: 'https://test.invalid/toggle.png', heroTagSalt: 'toggle'));
    final center = tester.getCenter(find.byType(ExtendedImageGesturePageView));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
        tester
            .widget<AnimatedOpacity>(find.ancestor(
                of: find.byTooltip('保存图片'),
                matching: find.byType(AnimatedOpacity)))
            .opacity,
        0);
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
        tester
            .widget<AnimatedOpacity>(find.ancestor(
                of: find.byTooltip('保存图片'),
                matching: find.byType(AnimatedOpacity)))
            .opacity,
        1);
    expect(tester.takeException(), isNull);
  });

  for (final systemBack in [false, true]) {
    testWidgets('图片打开与关闭均有 Hero 飞行 systemBack=$systemBack', (tester) async {
      const url = 'https://test.invalid/route.png';
      await open(tester, Builder(builder: (context) {
        return Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(ImageExplorerRoute(
              builder: (_) =>
                  const ImgExplorer(imgUrl: url, heroTagSalt: 'route'),
            )),
            child: const Hero(
              tag: '${url}route',
              child: SizedBox(
                width: 80,
                height: 80,
                child: ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        );
      }));
      final image = find.byWidgetPredicate((widget) =>
          widget is ExtendedImage &&
          widget.image is ExtendedNetworkImageProvider &&
          (widget.image as ExtendedNetworkImageProvider).url == url);
      await tester.tap(find.byType(Hero));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // 飞行图位于 Overlay；宽度介于入口和全屏之间，而非只淡入整页。
      expect(
          tester.getSize(image).width, allOf(greaterThan(80), lessThan(390)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getSize(image).width, closeTo(390, .1));
      if (systemBack) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.byTooltip('返回'));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
          tester.getSize(image).width, allOf(greaterThan(80), lessThan(390)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(ImgExplorer), findsNothing);
      expect(find.byType(Hero), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('缩略图地址不同仍匹配 Hero，切页及切换原图后回到点击入口', (tester) async {
    final controller = ExtendedPageController(initialPage: 0);
    addTearDown(controller.dispose);
    await open(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 80,
            height: 80,
            child: Thumbnail(
              imgs: const [
                'https://test.invalid/a.png',
                'https://test.invalid/b.png'
              ],
              imgsOriginSrc: const [
                null,
                'https://test.invalid/b-original.png'
              ],
              controller: controller,
              img: 'https://test.invalid/low-flow-a.png',
            ),
          ),
        ));
    final sourceTag = tester.widget<Hero>(find.byType(Hero)).tag;
    await tester.tap(find.byType(Thumbnail));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(
        find.byType(ExtendedImageGesturePageView), const Offset(-350, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tap(find.text('查看原图'));
    await tester.pump();
    final viewerHero = find.descendant(
        of: find.byType(ZoomedImgExplorer), matching: find.byType(Hero));
    expect(tester.widgetList<Hero>(viewerHero).map((hero) => hero.tag),
        everyElement(sourceTag));
    await tester.tap(find.byTooltip('返回'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // 返回时当前图片进入 Overlay，目标仍是最初点击的缩略图。
    final flyingImage = find.byWidgetPredicate((widget) =>
        widget is ExtendedImage &&
        widget.image is ExtendedNetworkImageProvider &&
        (widget.image as ExtendedNetworkImageProvider).url ==
            'https://test.invalid/b-original.png');
    expect(tester.getSize(flyingImage).width,
        allOf(greaterThan(80), lessThan(390)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ZoomedImgExplorer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('沿用外部控制器且不销毁调用方控制器', (tester) async {
    final controller = ExtendedPageController(initialPage: 1);
    await open(
        tester,
        ZoomedImgExplorer(
          imgUrls: const [
            'https://test.invalid/a.png',
            'https://test.invalid/b.png'
          ],
          pageController: controller,
          heroTagSalt: 'external',
        ));
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    void listener() {}
    controller.addListener(listener);
    controller.removeListener(listener);
    controller.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('空列表与横屏小尺寸不溢出', (tester) async {
    await open(
        tester, const ZoomedImgExplorer(imgUrls: [], heroTagSalt: 'empty'),
        size: const Size(600, 300));
    expect(find.text('暂无图片'), findsOneWidget);
    expect(find.text('0 / 0'), findsOneWidget);
    expect(find.byTooltip('保存图片'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('原图加载状态与相册权限拒绝反馈', (tester) async {
    const channel = MethodChannel('com.fluttercandies/photo_manager');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'requestPermissionExtend'
            ? PermissionState.denied.index
            : null);
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await open(
        tester,
        const ZoomedImgExplorer(
          imgUrls: ['https://test.invalid/loading.png'],
          highQualityUrls: ['https://test.invalid/loading-original.png'],
          heroTagSalt: 'loading',
        ));
    await tester.tap(find.text('查看原图'));
    await tester.pump();
    expect(find.text('正在加载原图…'), findsOneWidget);
    await tester.tap(find.byTooltip('保存原图'));
    await tester.pump();
    await tester.pump();
    expect(find.text('需要相册权限才能保存图片，请在系统设置中允许'), findsOneWidget);
    expect(find.byTooltip('正在保存…'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('已加载图片双击缩放与还原，横屏不溢出', (tester) async {
    const url = 'https://test.invalid/loaded.png';
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.blue, BlendMode.src);
    final picture = recorder.endRecording();
    final image = await tester.runAsync(() => picture.toImage(80, 80));
    picture.dispose();
    final provider = ExtendedNetworkImageProvider(url, cache: true);
    PaintingBinding.instance.imageCache.putIfAbsent(
        provider,
        () => OneFrameImageStreamCompleter(
            Future.value(ImageInfo(image: image!))));
    await open(tester, const ImgExplorer(imgUrl: url, heroTagSalt: 'zoom'),
        size: const Size(600, 300));
    await tester.pump();
    final gesture = tester
        .state<ExtendedImageGestureState>(find.byType(ExtendedImageGesture));
    final center = tester.getCenter(find.byType(ExtendedImageGesture));
    Future<void> doubleTap() async {
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
    }

    await doubleTap();
    expect(gesture.gestureDetails!.totalScale, closeTo(2.5, .01));
    await doubleTap();
    expect(gesture.gestureDetails!.totalScale, closeTo(1, .01));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets('自动加载原图时保留可缩放预览，中央不覆盖加载框', (tester) async {
    Global.setting.pictureLoadSetting = 2;
    const preview = 'https://test.invalid/cached-preview.png';
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.blue, BlendMode.src);
    final picture = recorder.endRecording();
    final image = await tester.runAsync(() => picture.toImage(80, 80));
    picture.dispose();
    PaintingBinding.instance.imageCache.putIfAbsent(
        ExtendedNetworkImageProvider(preview, cache: true),
        () => OneFrameImageStreamCompleter(
            Future.value(ImageInfo(image: image!))));
    await open(
        tester,
        const ZoomedImgExplorer(
          imgUrls: [preview, 'https://test.invalid/second.png'],
          highQualityUrls: ['https://test.invalid/slow-original.png'],
          heroTagSalt: 'progressive',
        ));
    await tester.pump();
    expect(find.byType(ExtendedImageGesture), findsOneWidget);
    expect(find.text('原图加载中…'), findsNothing);
    expect(find.text('正在加载原图…'), findsOneWidget);
    final progress = find.byType(CircularProgressIndicator);
    expect(progress, findsOneWidget);
    expect(tester.getCenter(progress).dy, greaterThan(750));
    final gesture = tester
        .state<ExtendedImageGestureState>(find.byType(ExtendedImageGesture));
    final center = tester.getCenter(find.byType(ExtendedImageGesture));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(gesture.gestureDetails!.totalScale, closeTo(2.5, .01));
    expect(
        tester
            .widget<TextButton>(find.ancestor(
                of: find.byIcon(Icons.download_rounded),
                matching: find.byType(TextButton)))
            .onPressed,
        isNotNull);
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await tester.drag(
        find.byType(ExtendedImageGesturePageView), const Offset(-350, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('正在加载原图…'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets('右上角只保留图标保存入口，删除复制链接和更多菜单', (tester) async {
    await open(
        tester,
        const ZoomedImgExplorer(
          imgUrls: ['https://test.invalid/a.png'],
          highQualityUrls: ['https://test.invalid/original.png'],
          heroTagSalt: 'copy',
        ));
    expect(find.byTooltip('复制图片链接'), findsNothing);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    expect(find.byTooltip('保存原图'), findsOneWidget);
    expect(find.text('保存原图'), findsNothing);
  });
}
