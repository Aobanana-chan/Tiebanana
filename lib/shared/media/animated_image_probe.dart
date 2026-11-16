import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tieba_contract/tieba_contract.dart';

/// 动图探测结果。
enum AnimatedImageState {
  /// 动图（GIF / 动态 WebP）。
  animated,

  /// 已确认的静态图。
  static,

  /// 文件头不可读，暂时无法判断。
  unknown,
}

/// 判断图片文件头是否为动图。
///
/// 与官方客户端解码后得到的图片格式一致：只认 GIF87a / GIF89a 和带
/// animation flag 的动态 WebP。普通的静态 WebP、JPEG、PNG 都不会命中。
bool isAnimatedImageHeader(Uint8List bytes) {
  if (bytes.length >= 6 &&
      bytes[0] == 0x47 && // G
      bytes[1] == 0x49 && // I
      bytes[2] == 0x46 && // F
      bytes[3] == 0x38 && // 8
      (bytes[4] == 0x37 || bytes[4] == 0x39) && // 7 / 9
      bytes[5] == 0x61) {
    return true;
  }
  // RIFF....WEBPVP8X，VP8X 的 flag 第 1 位（0x02）表示有动画。
  if (bytes.length >= 21 &&
      bytes[0] == 0x52 && // R
      bytes[1] == 0x49 && // I
      bytes[2] == 0x46 && // F
      bytes[3] == 0x46 && // F
      bytes[8] == 0x57 && // W
      bytes[9] == 0x45 && // E
      bytes[10] == 0x42 && // B
      bytes[11] == 0x50 && // P
      bytes[12] == 0x56 && // V
      bytes[13] == 0x50 && // P
      bytes[14] == 0x38 && // 8
      bytes[15] == 0x58) {
    return (bytes[20] & 0x02) != 0;
  }
  return false;
}

/// 读取图片响应头里的源文件类型；测试可注入。
typedef AnimatedImageHeaderFetcher = Future<String?> Function(Uri url);

/// 从 ExtendedImage 落盘的原始文件里读取文件头，识别 `.jpg` 地址下的动图。
///
/// 对齐官方客户端：`FeedTbImage` 的 GIF 角标只在实际图片格式为 GIF /
/// 动态 WebP，或该 URL 已被 `Src-Content-Type: image/gif` 标记时显示；
/// `GridImageLayout` 另外只把 `origin_src` 里的明确 `.gif` 当作预判。
///
/// 省流量缩略图常被 CDN 转成 JPEG 首帧（`Content-Type: image/jpeg`），
/// 但响应头仍会保留 `Src-Content-Type: image/gif`。因此先读已落盘的原始
/// 文件头，再补一次 HEAD 读取源类型；HEAD 失败或离线时宁可漏掉角标。
/// 结果按 URL 缓存，同一张图只探测一次。
class AnimatedImageProbe {
  AnimatedImageProbe({
    Future<Directory> Function()? directory,
    AnimatedImageHeaderFetcher? headerFetcher,
  })  : _directory = directory ?? _defaultDirectory,
        _headerFetcher = headerFetcher ?? _fetchSourceContentType;

  static final AnimatedImageProbe shared = AnimatedImageProbe();

  static const int _headerLength = 64;

  final Future<Directory> Function() _directory;
  final AnimatedImageHeaderFetcher _headerFetcher;
  final Map<String, AnimatedImageState> _cache = <String, AnimatedImageState>{};
  final Map<String, Future<AnimatedImageState>> _pending =
      <String, Future<AnimatedImageState>>{};

  /// 已缓存的结果；未知时返回 null。
  AnimatedImageState? peek(String url) {
    final String key = url.trim();
    if (key.isEmpty) return AnimatedImageState.static;
    if (TiebaImageContent.isAnimatedUrl(key)) {
      return AnimatedImageState.animated;
    }
    return _cache[key];
  }

  /// 读取图片磁盘缓存的文件头；同一 URL 只读取一次。
  Future<AnimatedImageState> resolve(String url) {
    final String key = url.trim();
    if (key.isEmpty) {
      return Future<AnimatedImageState>.value(AnimatedImageState.static);
    }
    final AnimatedImageState? known = peek(key);
    if (known != null) return Future<AnimatedImageState>.value(known);
    final Future<AnimatedImageState>? pending = _pending[key];
    if (pending != null) return pending;
    final Future<AnimatedImageState> future =
        _resolve(key).then((AnimatedImageState state) {
      if (state != AnimatedImageState.unknown) _cache[key] = state;
      return state;
    }).whenComplete(() {
      _pending.remove(key);
    });
    _pending[key] = future;
    return future;
  }

  Future<AnimatedImageState> _resolve(String url) async {
    final Uint8List? header = await _readCacheHeader(url);
    if (header != null && isAnimatedImageHeader(header)) {
      return AnimatedImageState.animated;
    }
    final Uri? uri = Uri.tryParse(url);
    final String? sourceType = uri == null ? null : await _headerFetcher(uri);
    if (sourceType == 'image/gif') return AnimatedImageState.animated;
    // 已拿到首帧文件头且响应头没有源类型标记，按静态图处理。
    if (header != null) return AnimatedImageState.static;
    return AnimatedImageState.unknown;
  }

  Future<Uint8List?> _readCacheHeader(String url) async {
    RandomAccessFile? file;
    try {
      final Directory directory = await _directory();
      final String key = md5.convert(utf8.encode(url)).toString();
      final File cached =
          File('${directory.path}${Platform.pathSeparator}$key');
      if (!await cached.exists()) return null;
      file = await cached.open();
      return await file.read(_headerLength);
    } catch (_) {
      // 缓存目录不可用或文件正在写入时保持 unknown，下次再试。
      return null;
    } finally {
      await file?.close();
    }
  }

  static Future<Directory> _defaultDirectory() async =>
      Directory('${(await getTemporaryDirectory()).path}/cacheimage');

  /// HEAD 请求只取响应头，不下载图片主体。
  static Future<String?> _fetchSourceContentType(Uri url) async {
    if (!url.isScheme('http') && !url.isScheme('https')) return null;
    final HttpClient client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    try {
      final HttpClientRequest request =
          await client.headUrl(url).timeout(const Duration(seconds: 5));
      request.headers.set(HttpHeaders.acceptHeader, 'image/*');
      final HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 5));
      final String? sourceType = response.headers.value('src-content-type');
      final String? contentType =
          response.headers.value(HttpHeaders.contentTypeHeader);
      try {
        await response.drain<void>().timeout(const Duration(seconds: 5));
      } catch (_) {
        // 只关心响应头，读取残留响应体失败不影响结果。
      }
      return (sourceType ?? contentType)?.split(';').first.trim().toLowerCase();
    } catch (_) {
      // 离线、HEAD 被拒绝或超时：保持未知，不猜成动图。
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// 测试用：清空内存结果。
  void clear() => _cache.clear();
}
