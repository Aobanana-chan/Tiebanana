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
  testWidgets('会员收银台点击被拦截并提示，不打开链接', (tester) async {
    Uri? opened;
    await tester.pumpWidget(MaterialApp(
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        home: Scaffold(
            body: ChatNoticeCard(
                data: ChatNoticeCardData(
                    title: '贴吧超级会员即将到期',
                    text: '到期时间：2026-11-10',
                    link: Uri.parse('https://tieba.baidu.com/mo/q/'
                        'hybrid-business-vip/payPanel?customfullscreen=1')),
                onOpen: (value) => opened = value))));
    await tester.tap(find.text('查看全文'));
    await tester.pumpAndSettle();
    expect(find.text('暂不支持'), findsOneWidget);
    expect(find.textContaining('支付相关页面'), findsOneWidget);
    expect(opened, isNull);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    expect(find.text('暂不支持'), findsNothing);
  });

  test('支付拦截只认路径，不误伤普通吧页和查询参数', () {
    for (final String url in <String>[
      'https://tieba.baidu.com/mo/q/hybrid-business-vip/payPanel?x=1',
      'https://tieba.baidu.com/mo/q/HYBRID-BUSINESS-VIP/tbvip',
      'https://tieba.baidu.com/mo/q/hybrid-business-vip/oneClickSign',
      'https://example.test/payPanel/index',
    ]) {
      expect(chatLinkNeedsPayment(Uri.parse(url)), isTrue, reason: url);
    }
    for (final String url in <String>[
      'http://tieba.baidu.com/f?kw=%E5%9C%A8',
      'https://tieba.baidu.com/p/123456',
      'https://tieba.baidu.com/tb/viprenew_eula_mobile.html',
      'https://example.test/help?next=hybrid-business-vip',
    ]) {
      expect(chatLinkNeedsPayment(Uri.parse(url)), isFalse, reason: url);
    }
  });

  testWidgets('只读会话的卡片点击只弹提示，不打开任何链接', (tester) async {
    Uri? opened;
    await tester.pumpWidget(MaterialApp(
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        home: Scaffold(
            body: ChatNoticeCard(
                blockLinks: true,
                data: ChatNoticeCardData(
                    title: '贴吧会员服务关闭',
                    text: '详情见通知',
                    link: Uri.parse('https://tieba.baidu.com/f?kw=x')),
                onOpen: (value) => opened = value))));
    await tester.tap(find.text('查看全文'));
    await tester.pumpAndSettle();
    expect(find.text('暂不支持'), findsOneWidget);
    expect(find.textContaining('详情暂不支持打开'), findsOneWidget);
    expect(opened, isNull);
    expect(tester.takeException(), isNull);
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
