import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/features/message/state/chat_content.dart';

void main() {
  test('会员通知卡片显示标题/正文，列表使用正文摘要', () {
    final String content = jsonEncode([
      {
        'title': '会员到期提醒',
        'type': 1,
        'text': '到期时间：2026-11-10',
        'src': 'https://example.test/image',
        'url': 'https://example.test/action',
      }
    ]);
    expect(chatDisplayText(7, content), '会员到期提醒\n到期时间：2026-11-10');
    expect(chatDisplayText(7, content, summary: true), '到期时间：2026-11-10');
    expect(chatDisplayText(7, content), isNot(contains('https://')));
  });
  test('损坏/未知卡片不暴露原始 JSON，普通文本保持不变', () {
    for (final String content in ['broken', '{}', '[]', '[{"text":3}]']) {
      expect(chatDisplayText(7, content), '通知消息');
    }
    expect(chatDisplayText(99, 'raw'), '暂不支持的消息');
    expect(chatDisplayText(1, '你好 #(开心)'), '你好 #(开心)');
  });
}
