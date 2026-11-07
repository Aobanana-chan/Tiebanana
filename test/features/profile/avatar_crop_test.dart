import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tiebanana/features/profile/pages/avatar_crop_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

Uint8List _fixture({int width = 120, int height = 60}) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgb(
          x, y, x < width / 2 ? 240 : 10, 20, x < width / 2 ? 10 : 240);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('cropAvatarImage', () {
    test('默认生成官方960正方形JPEG', () {
      final bytes = cropAvatarImage(_fixture());
      expect(bytes.take(2), <int>[0xff, 0xd8]);
      final output = img.decodeJpg(bytes)!;
      expect(output.width, 960);
      expect(output.height, 960);
      expect(output.getPixel(20, 320).r, greaterThan(200));
      expect(output.getPixel(620, 320).b, greaterThan(200));
    });

    test('左右越界位置被限制在图片内，缩放使用正确像素范围', () {
      final bytes = _fixture();
      for (final (x, zoom) in <(double, double)>[(-10, 1), (.25, 2)]) {
        final output = img.decodeJpg(
            cropAvatarImage(bytes, centerX: x, zoom: zoom, outputSize: 30))!;
        expect(output.width, 30);
        expect(output.height, 30);
        expect(output.getPixel(15, 15).r, greaterThan(220));
        expect(output.getPixel(29, 15).b, lessThan(40));
      }
      final right = img.decodeJpg(
          cropAvatarImage(bytes, centerX: 10, centerY: -10, outputSize: 30))!;
      expect(right.getPixel(0, 0).b, greaterThan(220));
      expect(right.getPixel(29, 29).b, greaterThan(220));
    });

    test('纵向图片裁切上下边缘', () {
      final image = img.Image(width: 40, height: 100);
      for (var y = 0; y < 100; y++) {
        for (var x = 0; x < 40; x++) {
          image.setPixelRgb(x, y, y < 50 ? 240 : 10, 20, y < 50 ? 10 : 240);
        }
      }
      final bytes = Uint8List.fromList(img.encodePng(image));
      final top =
          img.decodeJpg(cropAvatarImage(bytes, centerY: 0, outputSize: 20))!;
      final bottom =
          img.decodeJpg(cropAvatarImage(bytes, centerY: 1, outputSize: 20))!;
      expect(top.getPixel(10, 19).r, greaterThan(220));
      expect(bottom.getPixel(10, 0).b, greaterThan(220));
    });

    test('EXIF方向在计算裁切坐标前烘焙', () {
      final image = img.decodePng(_fixture())!;
      image.exif.imageIfd.orientation = 6;
      final input = Uint8List.fromList(img.encodeJpg(image, quality: 100));
      final top =
          img.decodeJpg(cropAvatarImage(input, centerY: 0, outputSize: 30))!;
      final bottom =
          img.decodeJpg(cropAvatarImage(input, centerY: 1, outputSize: 30))!;
      expect(top.getPixel(15, 15).r, greaterThan(200));
      expect(bottom.getPixel(15, 15).b, greaterThan(200));
    });

    test('透明区域以白色合成并移除EXIF', () {
      final image = img.Image(width: 4, height: 4, numChannels: 4);
      image.setPixelRgba(0, 0, 240, 0, 0, 0);
      final output = img.decodeJpg(cropAvatarImage(
          Uint8List.fromList(img.encodePng(image)),
          outputSize: 4))!;
      final pixel = output.getPixel(0, 0);
      expect(pixel.r, greaterThan(245));
      expect(pixel.g, greaterThan(245));
      expect(pixel.b, greaterThan(245));
      expect(output.exif.imageIfd.hasOrientation, isFalse);
    });

    test('拒绝非图片、空内容和过大输入', () {
      for (final bytes in <Uint8List>[
        Uint8List(0),
        Uint8List.fromList(<int>[1, 2, 3]),
        Uint8List(20 * 1024 * 1024 + 1),
      ]) {
        expect(() => cropAvatarImage(bytes), throwsFormatException);
      }
      // A valid header with an excessive canvas must fail before pixel decode.
      final oversized =
          Uint8List.fromList(img.encodePng(img.Image(width: 20000, height: 1)));
      expect(
          () => cropAvatarImage(oversized),
          throwsA(isA<FormatException>()
              .having((error) => error.message, 'message', contains('尺寸过大'))));
    });

    test('拒绝不合法输出参数与非有限变换', () {
      final bytes = _fixture();
      expect(() => cropAvatarImage(bytes, outputSize: 0), throwsArgumentError);
      expect(
          () => cropAvatarImage(bytes, outputSize: 4097), throwsArgumentError);
      expect(() => cropAvatarImage(bytes, quality: 101), throwsArgumentError);
      expect(() => cropAvatarImage(bytes, zoom: .5), throwsArgumentError);
      expect(() => cropAvatarImage(bytes, centerX: double.nan),
          throwsArgumentError);
    });
  });

  Future<void> openPage(WidgetTester tester, Uint8List bytes,
      ValueChanged<Uint8List?> onResult) async {
    await tester.pumpWidget(MaterialApp(
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: Builder(
          builder: (context) => Scaffold(
              body: TextButton(
                  onPressed: () async {
                    onResult(await Navigator.push<Uint8List>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AvatarCropPage(
                                imageBytes: bytes, outputSize: 32))));
                  },
                  child: const Text('打开裁切')))),
    ));
    await tester.tap(find.text('打开裁切'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // compute runs in an actual isolate, outside the fake widget-test clock.
    for (var i = 0; i < 100; i++) {
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('无法解码有错误提示，禁止使用头像且可取消', (tester) async {
    var returned = false;
    Uint8List? result;
    await openPage(tester, Uint8List.fromList(<int>[1, 2, 3]), (value) {
      returned = true;
      result = value;
    });
    expect(find.text('无法读取图片，请重新选择'), findsOneWidget);
    expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '使用头像'))
            .onPressed,
        isNull);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(returned, isTrue);
    expect(result, isNull);
  });

  testWidgets('正方形预览可拖动缩放，使用头像返回JPEG', (tester) async {
    Uint8List? result;
    await openPage(tester, _fixture(), (value) => result = value);
    final gesture = find.byKey(const ValueKey('avatar-crop-gesture'));
    expect(gesture, findsOneWidget);
    final size = tester.getSize(gesture);
    expect(size.width, size.height);
    await tester.drag(gesture, const Offset(1000, 0));
    await tester.pump();
    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(2);
    await tester.pump();
    await tester.tap(find.text('使用头像'));
    await tester.pump();
    expect(find.text('处理中…'), findsOneWidget);
    expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '取消'))
            .onPressed,
        isNull);
    expect(
        tester
            .widget<PopScope<Uint8List>>(find.byType(PopScope<Uint8List>))
            .canPop,
        isFalse);
    for (var i = 0; i < 100 && result == null; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    final output = img.decodeJpg(result!)!;
    expect(output.width, 32);
    expect(output.height, 32);
    expect(output.getPixel(16, 16).r, greaterThan(200));
    expect(tester.takeException(), isNull);
  });
}
