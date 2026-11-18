import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/share/models/share_content.dart';
import 'package:tiebanana/features/share/widgets/share_sheet.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

const ShareContent _content = ShareContent(
  title: '测试帖子',
  url: 'https://tieba.baidu.com/p/1',
  source: '抗压背锅吧',
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{'uid': '10001'});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    Global.tiebaAPI = _RecordingApi();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('PonnamKarthik/fluttertoast'),
      (MethodCall call) async => true,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('PonnamKarthik/fluttertoast'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('分享面板按好友、其他应用、复制链接排列，复制写入剪贴板', (tester) async {
    String? copied;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform,
            (MethodCall call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });

    await tester.pumpWidget(_app());
    await tester.tap(find.text('打开分享'));
    await tester.pumpAndSettle();

    expect(find.text('分享给好友'), findsOneWidget);
    expect(find.text('其他应用'), findsOneWidget);
    expect(find.text('复制链接'), findsOneWidget);
    expect(find.text('测试帖子'), findsOneWidget);

    final double friendX = tester.getCenter(find.text('分享给好友')).dx;
    final double appsX = tester.getCenter(find.text('其他应用')).dx;
    final double copyX = tester.getCenter(find.text('复制链接')).dx;
    expect(friendX < appsX, isTrue);
    expect(appsX < copyX, isTrue);

    await tester.tap(find.text('复制链接'));
    await tester.pumpAndSettle();

    expect(copied, _content.url);
    expect(find.text('复制链接'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('分享给好友会列出私信会话并发送链接', (tester) async {
    final _RecordingApi api = Global.tiebaAPI as _RecordingApi;
    await tester.pumpWidget(_app());
    await tester.tap(find.text('打开分享'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('分享给好友'));
    await tester.pumpAndSettle();

    expect(find.text('选择一位好友，链接会以私信发送'), findsOneWidget);
    expect(find.text('青葉ナナ'), findsOneWidget);

    await tester.tap(find.text('青葉ナナ'));
    await tester.pumpAndSettle();

    expect(api.sent, hasLength(1));
    expect(api.sent.single, contains('测试帖子'));
    expect(api.sent.single, contains(_content.url));
    expect(find.text('分享给好友'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}

class _RecordingApi extends DemoTiebaApi {
  _RecordingApi() : super(latency: Duration.zero);

  final List<String> sent = <String>[];

  @override
  Future<ChatSendResult> sendChatMessage(
    String conversationId,
    ChatDraft draft,
  ) {
    sent.add('$conversationId:${draft.text}');
    return super.sendChatMessage(conversationId, draft);
  }
}

Widget _app() {
  return MaterialApp(
    theme: TiebananaTheme.light(seedOf('blue'), 16),
    home: Scaffold(
      body: Builder(
        builder: (BuildContext context) => Center(
          child: TextButton(
            onPressed: () => showShareSheet(context, _content),
            child: const Text('打开分享'),
          ),
        ),
      ),
    ),
  );
}
