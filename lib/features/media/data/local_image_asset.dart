import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:photo_manager/photo_manager.dart';
import 'package:tiebanana/core/platform/platform_capabilities.dart';

/// 文件选择器的图片也遵守现有上传/草稿的资源接口，不调用相册原生通道。
class LocalImageAsset extends AssetEntity {
  LocalImageAsset._(this.localFile, int width, int height)
      : super(
            id: localFile.uri.toString(),
            typeInt: 1,
            width: width,
            height: height);

  final File localFile;

  static Future<LocalImageAsset> fromFile(File file) async {
    final buffer = await ui.ImmutableBuffer.fromFilePath(file.path);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        return LocalImageAsset._(file, descriptor.width, descriptor.height);
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
  }

  @override
  Future<File?> get file async => await localFile.exists() ? localFile : null;
  @override
  Future<File?> get originFile => file;

  @override
  Future<Uint8List?> thumbnailDataWithSize(
    ThumbnailSize size, {
    ThumbnailFormat format = ThumbnailFormat.jpeg,
    int quality = 100,
    PMProgressHandler? progressHandler,
    PMCancelToken? cancelToken,
    int frame = 0,
  }) async {
    final codec = await ui.instantiateImageCodec(await localFile.readAsBytes(),
        targetWidth: size.width,
        targetHeight: size.height,
        allowUpscaling: false);
    try {
      final image = (await codec.getNextFrame()).image;
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}

Future<AssetEntity?> restoreImageAsset(String id) async {
  final uri = Uri.tryParse(id);
  if (uri?.scheme == 'file') {
    final file = File.fromUri(uri!);
    return await file.exists() ? LocalImageAsset.fromFile(file) : null;
  }
  if (isDesktop) return null;
  return AssetEntity.fromId(id);
}
