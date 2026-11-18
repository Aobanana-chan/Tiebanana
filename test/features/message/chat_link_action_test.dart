import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/message/models/chat_route_data.dart';
import 'package:tiebanana/features/message/pages/chat_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

/// 返回一条带链接的私信，模拟「分享给好友」发出去的文本。
class _LinkChatApi extends DemoTiebaApi {
  _LinkChatApi() : super(latency: Duration.zero);

  @override
  Future<ChatMessagePage> getChatMessages(
    String conversationId, {
    ChatCursor? cursor,
    int limit = 30,
  }) async {
    return ChatMessagePage(
      messages: <TiebaChatMessage>[
        TiebaChatMessage(
          id: '1',
          localId: '100',
          recordId: '100',
          conversationId: conversationId,
          senderUid: '20001',
          content: '测试帖子\nhttps://tieba.baidu.com/p/1',
          time: DateTime(2026, 1, 1),
          type: 1,
          status: TiebaChatMessageStatus.sent,
          isRead: true,
        ),
      ],
    );
  }
}

void main() {
  testWidgets('私信里的分享链接显示打开入口', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{'uid': '10001'});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    Global.tiebaAPI = _LinkChatApi();

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: const Scaffold(
        body: ChatView(
          data: ChatRouteData(
            conversationId: '20001',
            peerUid: '20001',
            title: '分享测试',
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(
      find.byWidgetPredicate((Widget widget) =>
          widget is ExtendedText &&
          widget.data == '测试帖子\nhttps://tieba.baidu.com/p/1'),
      findsOneWidget,
    );
    expect(find.text('打开链接'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
