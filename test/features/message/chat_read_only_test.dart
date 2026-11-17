import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/message/models/chat_route_data.dart';
import 'package:tiebanana/features/message/pages/chat_page.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

Widget _app(Widget child) => ChangeNotifierProvider<APPSettingProvider>(
      create: (BuildContext context) => APPSettingProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        home: Scaffold(body: child),
      ),
    );

Future<void> _pumpChat(WidgetTester tester, {required int userType}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{'uid': '10001'});
  Global.profile = await SharedPreferences.getInstance();
  Global.setting = APPSetting.fromJson(defaultAPPSetting);
  Global.tiebaAPI = DemoTiebaApi(latency: Duration.zero);
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(ChatView(
    data: ChatRouteData(
      conversationId: '20001',
      peerUid: '20001',
      title: '贴吧会员',
      userType: userType,
    ),
  )));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

void main() {
  testWidgets('userType 4 的官方会话只读：没有输入框，只有提示', (WidgetTester tester) async {
    await _pumpChat(tester, userType: 4);
    expect(find.byKey(const Key('chat-read-only-bar')), findsOneWidget);
    expect(find.text('该会话仅接收消息'), findsOneWidget);
    expect(find.byType(ExtendedTextField), findsNothing);
    expect(find.text('发消息…'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('普通用户会话保留输入框', (WidgetTester tester) async {
    await _pumpChat(tester, userType: 1);
    expect(find.byKey(const Key('chat-read-only-bar')), findsNothing);
    expect(find.byType(ExtendedTextField), findsOneWidget);
    expect(find.text('发消息…'), findsOneWidget);
  });

  test('userType 3/4 只读，其余可回复', () {
    expect(
        const ChatRouteData(conversationId: '1', userType: 3).readOnly, isTrue);
    expect(
        const ChatRouteData(conversationId: '1', userType: 4).readOnly, isTrue);
    for (final int type in <int>[0, 1, 2, 5]) {
      expect(ChatRouteData(conversationId: '1', userType: type).readOnly, isFalse,
          reason: 'userType=$type');
    }
  });
}
