import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/features/message/state/chat_content.dart';
import 'package:tiebanana/features/message/widgets/chat_notice_card.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

void main() {
  testWidgets('官方通知独立卡片显示标题正文和全文入口，点击打开目标', (tester) async {
    Uri? opened;
    final Uri url = Uri.parse('https://example.test/member');
    await tester.pumpWidget(MaterialApp(
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        home: Scaffold(
            body: ChatNoticeCard(
                data: ChatNoticeCardData(
                    title: '贴吧超级会员即将到期', text: '到期时间：2026-11-10', link: url),
                onOpen: (value) => opened = value))));
    expect(find.text('贴吧超级会员即将到期'), findsOneWidget);
    expect(find.text('到期时间：2026-11-10'), findsOneWidget);
    expect(find.text('查看全文'), findsOneWidget);
    await tester.tap(find.text('查看全文'));
    expect(opened, url);
  });
  test('卡片保留横幅且拒绝非 HTTP(S) 的图片和跳转', () {
    final cards = chatNoticeCards(
        '[{"title":"会员","text":"提醒","src":"https://example.test/banner.jpg","url":"https://example.test/member"}]');
    expect(cards.single.imageUrl, 'https://example.test/banner.jpg');
    expect(cards.single.link?.host, 'example.test');
    expect(chatNoticeUri('javascript:alert(1)'), isNull);
    expect(chatNoticeUri('file:///data/test'), isNull);
    expect(
        chatNoticeCards('[{"title":"通知","url":"javascript:alert(1)"}]')
            .single
            .link,
        isNull);
    expect(chatNoticeCards('invalid'), isEmpty);
  });
}
