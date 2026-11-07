import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tiebanana/core/cache/avatar_image_cache.dart';
import 'package:tiebanana/shared/widgets/avatar_image.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tieba_contract/tieba_contract.dart';

Uint8List picture(int red) => Uint8List.fromList(img
    .encodePng(img.Image(width: 2, height: 2)..setPixelRgb(0, 0, red, 0, 0)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('演示头像离线解码，不读取磁盘、不请求网络、不写缓存', () async {
    final api = DemoTiebaApi(latency: Duration.zero);
    final me = await api.getMyInfo();
    final recommend = await api.getRecommThread(15, 1);
    final messages = await api.getReply(1);
    final urls = <String>{
      me.portraitUrl,
      for (final thread in recommend.threads) thread.author.portrait,
      for (final message in messages.items) message.portrait,
    };
    final cache = AvatarImageCache(
      read: (_) async => fail('内置头像不读磁盘'),
      fetch: (_) async => fail('内置头像不访问网络'),
      write: (_, __) async => fail('内置头像不写缓存'),
    );
    for (final url in urls) {
      expect(resolveAvatarUrl(url), url);
      final bytes = await cache.watch(url).single;
      expect(img.decodePng(bytes)?.width, 128);
    }
  });

  test('无效 data URI 不产生图片，也不回退到网络', () async {
    final cache = AvatarImageCache(
      fetch: (_) async => fail('无效内置数据不能发往网络'),
    );
    for (final url in [
      'data:image/png;base64,***',
      'data:image/png;base64,${base64Encode([1, 2, 3])}',
      'data:text/plain;base64,aGVsbG8=',
    ]) {
      expect(await cache.watch(url).toList(), isEmpty);
    }
  });

  testWidgets('演示头像通过共享组件显示', (tester) async {
    final api = DemoTiebaApi(latency: Duration.zero);
    final me = await api.getMyInfo();
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 56,
        height: 56,
        child: AvatarImage(url: me.portraitUrl),
      ),
    ));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<MemoryImage>());
    expect(image.fit, BoxFit.cover);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('缓存先返回，服务器新图随后覆盖并写盘，完整版本参数传给网络', () async {
    final old = picture(10);
    final fresh = picture(20);
    final network = Completer<Uint8List?>();
    final seenCache = Completer<void>();
    final values = <Uint8List>[];
    final writes = <Uint8List>[];
    const url = 'https://example.test/avatar?t=2';
    final cache = AvatarImageCache(
      read: (_) async => old,
      fetch: (requested) {
        expect(requested, url);
        return network.future;
      },
      write: (requested, bytes) async {
        expect(requested, url);
        writes.add(bytes);
      },
    );
    final done = cache.watch(url).forEach((bytes) {
      values.add(bytes);
      if (!seenCache.isCompleted) seenCache.complete();
    });
    await seenCache.future;
    expect(values, [old]);
    network.complete(fresh);
    await done;
    expect(values, [old, fresh]);
    expect(writes, [fresh]);
  });

  test('离线或无效服务器图片不替换缓存，也不污染磁盘', () async {
    final old = picture(10);
    for (final invalid in [false, true]) {
      final cache = AvatarImageCache(
        read: (_) async => old,
        fetch: (_) async {
          if (invalid) return Uint8List.fromList([1, 2, 3]);
          throw StateError('offline');
        },
        write: (_, __) async => fail('不能写入失败响应'),
      );
      expect(await cache.watch('https://example.test/avatar').toList(), [old]);
    }
  });

  test('无缓存时显示网络图片，缓存损坏或写盘失败不阻断网络图片', () async {
    final fresh = picture(20);
    for (final cached in [
      null,
      Uint8List.fromList([1, 2, 3])
    ]) {
      final cache = AvatarImageCache(
        read: (_) async => cached,
        fetch: (_) async => fresh,
        write: (_, __) async => throw StateError('disk full'),
      );
      expect(
          await cache.watch('https://example.test/avatar').toList(), [fresh]);
    }
  });

  test('同 URL 并发头像合并网络请求，完成后再次打开仍重新检查服务器', () async {
    final network = Completer<Uint8List?>();
    final started = Completer<void>();
    int requests = 0;
    final cache = AvatarImageCache(
      read: (_) async => null,
      fetch: (_) {
        requests++;
        if (!started.isCompleted) started.complete();
        return network.future;
      },
      write: (_, __) async {},
    );
    final first = cache.watch('url').toList();
    final second = cache.watch('url').toList();
    await started.future;
    network.complete(picture(20));
    await Future.wait([first, second]);
    expect(requests, 1);
    await cache.watch('url').toList();
    expect(requests, 2);
  });

  testWidgets('重建不重复下载，切换 URL 不显示旧请求迟到结果', (tester) async {
    final old = Completer<Uint8List?>();
    final fresh = Completer<Uint8List?>();
    final urls = <String>[];
    final cache = AvatarImageCache(
      read: (_) async => null,
      fetch: (url) {
        urls.add(url);
        return url == 'old' ? old.future : fresh.future;
      },
      write: (_, __) async {},
    );
    Widget host(String url) => MaterialApp(
        home: SizedBox(
            width: 40, height: 40, child: AvatarImage(url: url, cache: cache)));
    await tester.pumpWidget(host('old'));
    await tester.pumpWidget(host('old'));
    expect(urls, ['old']);
    await tester.pumpWidget(host('new'));
    final newBytes = picture(20);
    await tester.runAsync(() async {
      fresh.complete(newBytes);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(
        (tester.widget<Image>(find.byType(Image)).image as MemoryImage).bytes,
        newBytes);
    await tester.runAsync(() async {
      old.complete(picture(10));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(
        (tester.widget<Image>(find.byType(Image)).image as MemoryImage).bytes,
        newBytes);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
