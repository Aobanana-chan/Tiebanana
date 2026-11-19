import 'package:extended_text/extended_text.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/message/models/chat_route_data.dart';
import 'package:tiebanana/features/message/pages/chat_page.dart';
import 'package:tiebanana/features/message/pages/private_message_panel.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/app/navigation/route_names.dart';

Widget _app(Widget child) {
  return ChangeNotifierProvider<APPSettingProvider>(
    create: (BuildContext context) => APPSettingProvider(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: Scaffold(body: child),
      routes: <String, WidgetBuilder>{
        PageRouter.chat: (BuildContext context) => ChatPage(
              data: ModalRoute.of(context)!.settings.arguments as ChatRouteData,
            ),
      },
    ),
  );
}

void main() {
  testWidgets('初始化失败后点击重试会再次调用后端', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{'uid': '10001'});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    final _RetryChatApi api = _RetryChatApi();
    Global.tiebaAPI = api;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const PrivateMessagePanel()));
    await tester.pumpAndSettle();
    expect(api.attempts, 1);
    expect(find.text('网络似乎有点问题'), findsOneWidget);
    expect(find.textContaining('已经加载过的会话仍可离线查看'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(api.attempts, 2);
    expect(find.text('青葉ナナ'), findsOneWidget);
    expect(find.text('网络似乎有点问题'), findsNothing);
  });

  testWidgets('会话列表进入聊天并发送文字', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{'uid': '10001'});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    Global.tiebaAPI = DemoTiebaApi(latency: Duration.zero);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const PrivateMessagePanel()));
    await tester.pump();
    await tester.pump();

    expect(find.text('青葉ナナ'), findsOneWidget);

    await tester.tap(find.text('青葉ナナ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.byType(ChatPage), findsOneWidget);
    expect(find.text('发消息…'), findsOneWidget);

    tester
        .widget<ExtendedTextField>(find.byType(ExtendedTextField))
        .controller!
        .text = '测试一条消息';
    await tester.pump();
    expect(
        tester
            .widget<ExtendedTextField>(find.byType(ExtendedTextField))
            .controller!
            .text,
        '测试一条消息');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byWidgetPredicate(
          (Widget widget) => widget is ExtendedText && widget.data == '测试一条消息'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('发送失败保留气泡，点状态文字用同一 recordId 重发', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{'uid': '10001'});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    final _FailOnceChatApi api = _FailOnceChatApi();
    Global.tiebaAPI = api;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const ChatView(
      data: ChatRouteData(
        conversationId: '20001',
        peerUid: '20001',
        title: '青葉ナナ',
      ),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    tester
        .widget<ExtendedTextField>(find.byType(ExtendedTextField))
        .controller!
        .text = '发不出去的消息';
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('未发送 · 点此重发'), findsOneWidget);
    expect(api.recordIds, hasLength(1));

    await tester.tap(find.text('未发送 · 点此重发'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(api.recordIds, hasLength(2));
    expect(api.recordIds.last, api.recordIds.first);
    expect(find.text('未发送 · 点此重发'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('收到刷新信号后重新读取会话列表', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{'uid': '10001'});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    final _RefreshChatApi api = _RefreshChatApi();
    Global.tiebaAPI = api;
    final ValueNotifier<int> refresh = ValueNotifier<int>(0);
    addTearDown(refresh.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(PrivateMessagePanel(refreshSignal: refresh)));
    await tester.pump();
    await tester.pump();

    expect(find.text('新消息会话'), findsNothing);

    api.hasNewConversation = true;
    refresh.value++;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('新消息会话'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _RetryChatApi extends DemoTiebaApi {
  _RetryChatApi() : super(latency: Duration.zero);

  int attempts = 0;

  @override
  Future<List<TiebaConversation>> getConversations() async {
    attempts++;
    if (attempts == 1) throw StateError('test initialization failure');
    return super.getConversations();
  }
}

/// 收到刷新信号后多返回一条会话，用来验证列表会被重新读取。
class _RefreshChatApi extends DemoTiebaApi {
  _RefreshChatApi() : super(latency: Duration.zero);

  bool hasNewConversation = false;

  @override
  Future<List<TiebaConversation>> getConversations() async {
    final List<TiebaConversation> items = await super.getConversations();
    if (!hasNewConversation) return items;
    return <TiebaConversation>[
      TiebaConversation(
        id: '29999',
        peerUid: '29999',
        title: '新消息会话',
        groupType: 6,
        lastMessage: '刚发来的一条',
        lastTime: DateTime(2026, 11, 20, 12),
        unread: 1,
      ),
      ...items,
    ];
  }
}

class _FailOnceChatApi extends DemoTiebaApi {
  _FailOnceChatApi() : super(latency: Duration.zero);

  final List<String> recordIds = <String>[];

  @override
  Future<ChatSendResult> sendChatMessage(
    String conversationId,
    ChatDraft draft,
  ) {
    recordIds.add(draft.recordId);
    if (recordIds.length == 1) {
      throw StateError('test network failure');
    }
    return super.sendChatMessage(conversationId, draft);
  }
}
