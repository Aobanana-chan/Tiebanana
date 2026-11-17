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
    expect(find.text('私信加载失败'), findsOneWidget);
    expect(find.textContaining('初始化或数据处理失败'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(api.attempts, 2);
    expect(find.text('青葉ナナ'), findsOneWidget);
    expect(find.text('私信加载失败'), findsNothing);
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
