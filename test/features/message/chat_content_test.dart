import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/features/message/state/chat_content.dart';

void main() {
  test('图文卡片显示标题/正文，列表使用正文摘要', () {
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
    // 官方 ChatMessage.getType 把 35 也映射到多图文。
    expect(chatDisplayText(35, content), '会员到期提醒\n到期时间：2026-11-10');
  });

  test('富文本 text 不把 TextContent JSON 暴露成正文', () {
    final String content = jsonEncode([
      {
        'title': '吧广播',
        'text': jsonEncode({
          'layout': 'layout_station_premise_message_style_1',
          'thread_title': '一条吧内热帖',
          'forum_name': '贴吧吧',
          'reply': '回复内容',
          'src': 'https://example.test/inner.jpg',
          'pic_url': 'https://example.test/pic.jpg',
        }),
      }
    ]);
    expect(chatDisplayText(7, content), '吧广播\n一条吧内热帖');
    expect(chatDisplayText(7, content), isNot(contains('thread_title')));
    final cards = chatNoticeCards(content);
    expect(cards.single.imageUrl, 'https://example.test/pic.jpg');
  });

  test('卡片支持单对象、jump_url 回退且拒绝危险 scheme', () {
    final cards = chatNoticeCards(jsonEncode({
      'title': '通知',
      'text': '正文',
      'src': 'https://example.test/banner.jpg',
      'jump_url': 'https://example.test/detail',
    }));
    expect(cards, hasLength(1));
    expect(cards.single.link?.toString(), 'https://example.test/detail');
    expect(chatNoticeUri('javascript:alert(1)'), isNull);
    expect(chatNoticeUri('file:///data/test'), isNull);
    expect(
        chatNoticeCards('[{"title":"通知","url":"javascript:alert(1)"}]')
            .single
            .link,
        isNull);
    expect(chatNoticeCards('invalid'), isEmpty);
  });

  test('损坏/未知卡片不暴露原始 JSON，普通文本保持不变', () {
    for (final String content in ['broken', '{}', '[]', '[{"text":3}]']) {
      expect(chatDisplayText(7, content), '图文消息');
    }
    expect(chatDisplayText(99, 'raw'), '暂不支持的消息');
    expect(chatDisplayText(1, '你好 #(开心)'), '你好 #(开心)');
  });

  test('官方媒体/卡片/系统类型都有可读降级文案', () {
    final Map<int, String> labels = <int, String>{
      2: '[图片]',
      3: '[语音]',
      4: '[表情]',
      5: '[群邀请]',
      6: '[活动]',
      23: '[回复卡片]',
      25: '[直播]',
      30: '[破冰互动]',
      32: '[分享帖子]',
      33: '[分享吧]',
      34: '[订单消息]',
      37: '[分享聊天室]',
      38: '[分享卡片]',
      40: '[游戏邀请]',
      7002: '[消息已撤回]',
      7009: '[分享吧]',
      7010: '[分享帖子]',
      7015: '[消息已撤回]',
      7020: '[分享聊天室]',
      7021: '[分享卡片]',
      7022: '[活动]',
      7023: '[消息已撤回]',
      7025: '[消息已删除]',
      20000: '[表情回复]',
    };
    labels.forEach((int type, String label) {
      expect(chatDisplayText(type, ''), label, reason: 'type=$type');
    });
    expect(chatDisplayText(8001, '对方还不是你的好友'), '对方还不是你的好友');
  });

  test('语音时长、图片地址与已读回执过滤', () {
    expect(chatVoiceSeconds('12'), 12);
    expect(chatVoiceSeconds('«{"during_time":"7","voice_url":"x"}»'), 7);
    expect(chatDisplayText(3, '{"during_time":"7"}'), '[语音] 7″');

    expect(
      chatImageUrl(
          2,
          '{"big_src":"https://example.test/big.jpg",'
          '"src":"https://example.test/small.jpg"}'),
      'https://example.test/big.jpg',
    );
    expect(
      chatImageUrl(4, '{"src":"https://example.test/meme.png"}'),
      'https://example.test/meme.png',
    );
    expect(chatImageUrl(2, '{"big_src":"javascript:alert(1)"}'), '');
    expect(chatImageUrl(1, 'https://example.test/not-image.jpg'), '');

    expect(chatMessageVisible(1), isTrue);
    expect(chatMessageVisible(22), isFalse);
    expect(chatDisplayText(22, ''), '');
    // 103 是 TTS 文本消息，正文仍按文本展示。
    expect(chatDisplayText(103, '朗读文本'), '朗读文本');
    expect(chatDisplayText(-7013, ''), '[系统消息]');
  });
}
