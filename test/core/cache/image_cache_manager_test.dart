import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiebanana/core/cache/image_cache_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ImageCacheManager manager;
  final now = DateTime(2026, 11, 5);

  Future<File> picture(String name, int bytes, int age) async {
    final file = File('${directory.path}/$name');
    await file.writeAsBytes(List.filled(bytes, 1));
    await file.setLastModified(now.subtract(Duration(days: age)));
    return file;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('image_cache_test_');
    manager = ImageCacheManager(directory: () async => directory);
  });

  tearDown(() async => directory.delete(recursive: true));

  test('只统计图片缓存，不动临时写入文件和其他数据', () async {
    await picture('a' * 32, 12, 0);
    final temporary = await picture('${'b' * 32}.refresh', 7, 0);
    final other = await picture('account.json', 9, 0);
    expect(await manager.sizeBytes(), 12);
    final result = await manager.clean(all: true);
    expect(result.bytes, 12);
    expect(await manager.sizeBytes(), 0);
    expect(await temporary.exists(), isTrue);
    expect(await other.exists(), isTrue);
  });

  test('默认关闭自动清理，手动清理仍生效', () async {
    final file = await picture('a' * 32, 10, 100);
    await manager.clean(now: now);
    expect(await file.exists(), isTrue);
    await manager.clean(all: true);
    expect(await file.exists(), isFalse);
  });

  test('按时间仅删除超过保留天数的文件', () async {
    manager.policy =
        const ImageCachePolicy(enabled: true, days: 7, bySize: false);
    final old = await picture('a' * 32, 10, 8);
    final boundary = await picture('b' * 32, 20, 7);
    final fresh = await picture('c' * 32, 30, 1);
    expect((await manager.clean(now: now)).bytes, 10);
    expect(await old.exists(), isFalse);
    expect(await boundary.exists(), isTrue);
    expect(await fresh.exists(), isTrue);
  });

  test('按大小优先删除最旧的文件，保留上限内的新文件', () async {
    manager.policy =
        const ImageCachePolicy(enabled: true, byAge: false, maxMiB: 1);
    final old = await picture('a' * 32, 700000, 10);
    final fresh = await picture('b' * 32, 700000, 1);
    expect((await manager.clean(now: now)).bytes, 700000);
    expect(await old.exists(), isFalse);
    expect(await fresh.exists(), isTrue);
  });

  test('两种规则同时生效，容量未超限也清理过期文件', () async {
    manager.policy = const ImageCachePolicy(enabled: true, days: 7, maxMiB: 1);
    await picture('a' * 32, 10, 10);
    await picture('b' * 32, 20, 1);
    expect((await manager.clean(now: now)).bytes, 10);
    expect(await manager.sizeBytes(), 20);
  });

  test('规则持久化且不修改其他偏好设置', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('account', 'keep');
    await manager.savePolicy(const ImageCachePolicy(
        enabled: true, byAge: false, days: 14, maxMiB: 256));
    final restored = ImageCacheManager(directory: () async => directory);
    await restored.loadPolicy();
    expect(restored.policy.enabled, isTrue);
    expect(restored.policy.byAge, isFalse);
    expect(restored.policy.days, 14);
    expect(restored.policy.maxMiB, 256);
    expect(prefs.getString('account'), 'keep');
  });

  test('损坏的设置回退默认值，禁止开启没有规则的自动清理', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ImageCacheManager.preferenceKey, 'broken');
    await manager.loadPolicy();
    expect(manager.policy.enabled, isFalse);
    await expectLater(
        manager.savePolicy(
            const ImageCachePolicy(enabled: true, byAge: false, bySize: false)),
        throwsArgumentError);
  });
}
