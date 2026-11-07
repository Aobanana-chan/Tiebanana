import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tiebanana/features/profile/state/profile_events.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';

void main() {
  Uint8List picture(int red, int blue) => Uint8List.fromList(img.encodePng(
      img.Image(width: 2, height: 2)..setPixelRgb(0, 0, red, 0, blue)));

  test('头像更新保留内置图片数据，网络头像追加版本号', () {
    final events = ProfileEvents();
    addTearDown(events.dispose);
    final data = 'data:image/png;base64,${base64Encode(picture(255, 0))}';
    events.avatarSaved('demo');
    expect(events.avatarUrl('demo', data), data);
    expect(UriData.parse(events.avatarUrl('demo', data)).contentAsBytes(),
        picture(255, 0));
    final url = Uri.parse(
        events.avatarUrl('demo', 'https://example.test/avatar?v=2'));
    expect(url.queryParameters['v'], '2');
    expect(url.queryParameters['_avatar_v'], isNotEmpty);
  });

  testWidgets('资料始终返回旧URL时，其他页面实际使用新图片而非旧网络头像', (tester) async {
    addTearDown(() => profileEvents.clearAvatar('avatar-test'));
    await tester.pumpWidget(const MaterialApp(
      home:
          Avatar(userId: 'avatar-test', imgUrl: 'https://example.test/old.png'),
    ));
    final bytes = picture(255, 0);
    profileEvents.avatarSaved('avatar-test', preview: bytes);
    await tester.pump();
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<MemoryImage>());
    expect((image.image as MemoryImage).bytes, orderedEquals(bytes));
    expect(find.byTooltip('已提交的头像预览，网络展示可能尚未同步'), findsOneWidget);
    // 晚到的旧资料、重复重建不能切回旧网络图片。
    await tester.pumpWidget(const MaterialApp(
      home: Avatar(
          userId: 'avatar-test', imgUrl: 'https://example.test/stale.png'),
    ));
    expect(
        (tester.widget<Image>(find.byType(Image)).image as MemoryImage).bytes,
        orderedEquals(bytes));
    final newer = picture(0, 255);
    profileEvents.avatarSaved('avatar-test', preview: newer);
    await tester.pump();
    expect(
        (tester.widget<Image>(find.byType(Image)).image as MemoryImage).bytes,
        orderedEquals(newer));
    expect(profileEvents.avatarPreview('another-account'), isNull);
    await tester.pumpWidget(const SizedBox());
    profileEvents.clearAvatar('avatar-test');
  });

  testWidgets('头像确认读取有上限，连续上传取消上一轮通知', (tester) async {
    final events = ProfileEvents();
    addTearDown(events.dispose);
    int reads = 0;
    events.addListener(() => reads++);
    events.avatarSaved('u', preview: picture(255, 0));
    expect(reads, 1);
    await tester.pump(const Duration(seconds: 1));
    events.avatarSaved('u', preview: picture(0, 255));
    expect(reads, 2);
    await tester.pump(const Duration(seconds: 1));
    expect(reads, 2); // 前一次的2秒通知已取消。
    await tester.pump(const Duration(seconds: 1));
    expect(reads, 3);
    await tester.pump(const Duration(seconds: 20));
    expect(reads, 5);
    await tester.pump(const Duration(minutes: 2));
    expect(reads, 5);
  });
}
