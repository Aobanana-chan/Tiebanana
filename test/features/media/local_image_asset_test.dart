import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tiebanana/features/media/data/local_image_asset.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('桌面图片读取尺寸、缩略图并按文件 URI 恢复草稿', () async {
    final directory = await Directory.systemTemp.createTemp('tiebanana-image-');
    addTearDown(() => directory.delete(recursive: true));
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder);
    final picture = recorder.endRecording();
    final image = await picture.toImage(80, 40);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    image.dispose();
    picture.dispose();
    final file = await File('${directory.path}/图片.png')
        .writeAsBytes(bytes.buffer.asUint8List());
    final asset = await LocalImageAsset.fromFile(file);
    expect(asset.width, 80);
    expect(asset.height, 40);
    expect((await asset.originFile)?.path, file.path);
    expect(await asset.thumbnailDataWithSize(const ThumbnailSize(20, 10)),
        isNotEmpty);
    final restored = await restoreImageAsset(asset.id);
    expect(restored, isA<LocalImageAsset>());
    expect(restored?.id, asset.id);
    await file.delete();
    expect(await restoreImageAsset(asset.id), isNull);
  });

  test('桌面端不会为失效的移动端相册草稿调用原生通道', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(await restoreImageAsset('mobile-asset-id'), isNull);
  });
}
