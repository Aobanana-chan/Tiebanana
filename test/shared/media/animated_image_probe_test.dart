import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/shared/media/animated_image_probe.dart';

void main() {
  group('动图文件头', () {
    Uint8List bytes(List<int> value) => Uint8List.fromList(value);

    test('识别 GIF87a / GIF89a', () {
      expect(isAnimatedImageHeader(bytes('GIF87a'.codeUnits)), isTrue);
      expect(isAnimatedImageHeader(bytes('GIF89a'.codeUnits)), isTrue);
      expect(isAnimatedImageHeader(bytes('GIF90a'.codeUnits)), isFalse);
      expect(isAnimatedImageHeader(bytes('JFIF'.codeUnits)), isFalse);
    });

    test('识别动态 WebP，普通 WebP 不算', () {
      Uint8List webp({required int flags}) {
        final value = Uint8List(32);
        value.setAll(0, 'RIFF'.codeUnits);
        value.setAll(8, 'WEBP'.codeUnits);
        value.setAll(12, 'VP8X'.codeUnits);
        value[20] = flags;
        return value;
      }

      expect(isAnimatedImageHeader(webp(flags: 0x02)), isTrue);
      expect(isAnimatedImageHeader(webp(flags: 0x00)), isFalse);
    });

    test('短数据和空数据不崩溃', () {
      expect(isAnimatedImageHeader(Uint8List(0)), isFalse);
      expect(isAnimatedImageHeader(Uint8List.fromList([0x47, 0x49])), isFalse);
    });
  });

  group('从图片磁盘缓存探测', () {
    late Directory directory;
    late AnimatedImageProbe probe;
    String? sourceType;
    int headerRequests = 0;

    File cacheFile(String url) {
      final key = md5.convert(utf8.encode(url)).toString();
      return File('${directory.path}${Platform.pathSeparator}$key');
    }

    Future<void> write(String url, List<int> data) async {
      await cacheFile(url).writeAsBytes(data, flush: true);
    }

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('animated_probe_test');
      sourceType = null;
      headerRequests = 0;
      probe = AnimatedImageProbe(
        directory: () async => directory,
        headerFetcher: (url) async {
          headerRequests++;
          return sourceType;
        },
      );
    });

    tearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    test('.jpg 地址下的真实 GIF 也能识别', () async {
      await write('https://example.com/anim.jpg', 'GIF89a......'.codeUnits);
      final state = await probe.resolve('https://example.com/anim.jpg');
      expect(state, AnimatedImageState.animated);
      expect(probe.peek('https://example.com/anim.jpg'),
          AnimatedImageState.animated);
      expect(headerRequests, 0);
    });

    test('CDN 把缩略图转成 JPEG 首帧时按 Src-Content-Type 识别', () async {
      // 省流量缩略图：文件头是 JPEG，但响应头保留源文件类型。
      await write('https://example.com/thumb.jpg',
          <int>[0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
      sourceType = 'image/gif';
      final state = await probe.resolve('https://example.com/thumb.jpg');
      expect(state, AnimatedImageState.animated);
      expect(headerRequests, 1);
    });

    test('静态 JPEG 首帧和静态源类型不误判', () async {
      await write(
          'https://example.com/static.jpg', <int>[0xFF, 0xD8, 0xFF, 0xE0]);
      sourceType = 'image/jpeg';
      expect(await probe.resolve('https://example.com/static.jpg'),
          AnimatedImageState.static);
      expect(probe.peek('https://example.com/static.jpg'),
          AnimatedImageState.static);
      expect(headerRequests, 1);
    });

    test('没有文件头但源类型是 GIF 也算动图', () async {
      sourceType = 'image/gif';
      expect(await probe.resolve('https://example.com/no-cache.jpg'),
          AnimatedImageState.animated);
    });

    test('静态 JPG / PNG 不误判', () async {
      await write('https://example.com/photo.jpg', [0xFF, 0xD8, 0xFF, 0xE0]);
      await write('https://example.com/shot.png', [0x89, 0x50, 0x4E, 0x47]);
      expect(await probe.resolve('https://example.com/photo.jpg'),
          AnimatedImageState.static);
      expect(await probe.resolve('https://example.com/shot.png'),
          AnimatedImageState.static);
      expect(probe.peek('https://example.com/photo.jpg'),
          AnimatedImageState.static);
    });

    test('缓存文件缺失时返回 unknown 且不写入否定结果', () async {
      expect(await probe.resolve('https://example.com/missing.jpg'),
          AnimatedImageState.unknown);
      expect(probe.peek('https://example.com/missing.jpg'), isNull);

      await write('https://example.com/missing.jpg', 'GIF87a'.codeUnits);
      expect(await probe.resolve('https://example.com/missing.jpg'),
          AnimatedImageState.animated);
    });

    test('地址已带明确 GIF 标记时无需读文件', () async {
      expect(await probe.resolve('https://example.com/anim.gif'),
          AnimatedImageState.animated);
      expect(
          await probe
              .resolve('https://example.com/c/p/img?src=a.jpg&first_gif=1'),
          AnimatedImageState.animated);
    });

    test('同一地址只读一次磁盘', () async {
      await write('https://example.com/once.jpg', 'GIF89a'.codeUnits);
      expect(await probe.resolve('https://example.com/once.jpg'),
          AnimatedImageState.animated);
      await cacheFile('https://example.com/once.jpg').delete();
      expect(await probe.resolve('https://example.com/once.jpg'),
          AnimatedImageState.animated);
    });
  });
}
