import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:extended_image/extended_image.dart';
import 'package:path_provider/path_provider.dart';

/// 头像采用 stale-while-revalidate：缓存先展示，网络成功后更新。
/// 缓存键为含服务端版本参数的完整 URL，接口下发新地址后自动切换。
class AvatarImageCache {
  AvatarImageCache({
    Future<Uint8List?> Function(String)? read,
    Future<Uint8List?> Function(String)? fetch,
    Future<void> Function(String, Uint8List)? write,
  })  : _read = read ?? _readDisk,
        _fetch = fetch ?? _fetchNetwork,
        _write = write ?? _writeDisk;

  static final shared = AvatarImageCache();
  final Future<Uint8List?> Function(String) _read;
  final Future<Uint8List?> Function(String) _fetch;
  final Future<void> Function(String, Uint8List) _write;
  final Map<String, Future<Uint8List?>> _pending = {};

  Stream<Uint8List> watch(String url) async* {
    if (url.isEmpty) return;
    // 内置头像从 data URI 解码。
    if (url.startsWith('data:')) {
      try {
        final data = UriData.parse(url);
        if (!data.mimeType.startsWith('image/')) return;
        final bytes = data.contentAsBytes();
        if (await _valid(bytes)) yield bytes;
      } catch (_) {
        // 无效的内置图片与网络加载失败一样保留占位。
      }
      return;
    }
    try {
      final cached = await _read(url);
      if (cached != null && await _valid(cached)) yield cached;
    } catch (_) {
      // 磁盘缓存损坏或不可读时仍尝试网络。
    }
    final fresh = await (_pending[url] ??= _refresh(url));
    if (fresh != null) yield fresh;
  }

  Future<Uint8List?> _refresh(String url) async {
    try {
      final fresh = await _fetch(url);
      if (fresh == null || !await _valid(fresh)) return null;
      try {
        await _write(url, fresh);
        // 图片浏览器等入口的已解码缓存也一并清理。
        await ExtendedNetworkImageProvider(url, cache: true).evict();
      } catch (_) {
        // 磁盘写入失败时仍展示已取得的服务器图片。
      }
      return fresh;
    } catch (_) {
      // 离线、超时或错误响应时保留当前缓存。
      return null;
    } finally {
      _pending.remove(url);
    }
  }

  static Future<bool> _valid(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      codec.dispose();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<File> _file(String url) async {
    final root = await getTemporaryDirectory();
    // 与 ExtendedImage 共用磁盘键，升级后已有缓存仍可立即展示。
    final key = md5.convert(utf8.encode(url));
    return File('${root.path}/cacheimage/$key');
  }

  static Future<Uint8List?> _readDisk(String url) async {
    final file = await _file(url);
    return await file.exists() ? file.readAsBytes() : null;
  }

  static Future<void> _writeDisk(String url, Uint8List bytes) async {
    final file = await _file(url);
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.refresh');
    await temporary.writeAsBytes(bytes, flush: true);
    await temporary.rename(file.path);
  }

  static Future<Uint8List?> _fetchNetwork(String url) =>
      ExtendedNetworkImageProvider(url,
              cache: false, retries: 0, timeLimit: const Duration(seconds: 15))
          .getNetworkImageData();
}
