import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/thread/state/reply_events.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/content/emoji_panel.dart';
import 'package:tiebanana/features/thread/widgets/thread_reply_bar.dart';

class _ReplyApi extends DemoTiebaApi {
  _ReplyApi() : super(latency: Duration.zero);
  bool fail = false;

  @override
  Future<String> replyThread(String content, String kw, String fid, String tid,
      {List<String>? photos}) async {
    if (fail) throw StateError('发送失败');
    return '发送成功';
  }

  @override
  Future<String> replyFloor(
      String content, String kw, String fid, String tid, String pid,
      {String? replyUID, List<String>? photos}) async {
    if (fail) throw StateError('发送失败');
    return '发送成功';
  }
}

Future<void> _open(WidgetTester tester,
    {bool thread = false,
    Brightness brightness = Brightness.light,
    double fontSize = 16,
    String? replyText,
    Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  final theme = brightness == Brightness.light
      ? TiebananaTheme.light(seedOf('blue'), fontSize)
      : TiebananaTheme.dark(seedOf('blue'), fontSize);
  await tester.pumpWidget(MaterialApp(
    theme: theme,
    home: Scaffold(
      body: Builder(builder: (context) {
        return TextButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => ReplyBottomSheet(
              replyText: replyText ?? '感谢整理。第 3 步的分组迁移顺序很关键。' * 10,
              targetName: '路人甲',
              targetMeta: '2楼 · 1小时前 · IP属地：上海',
              threadTitle: 'Flutter 升级记录',
              kw: 'Flutter',
              fid: '1',
              tid: '2',
              floorId: thread ? null : '3',
              isReplyThread: thread,
            ),
          ),
          child: const Text('打开'),
        );
      }),
    ),
  ));
  await tester.tap(find.text('打开'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting)
      ..showPostingRiskWarning = false;
  });

  for (final thread in [false, true]) {
    testWidgets('打开回复立即提醒且不自动聚焦 thread=$thread', (tester) async {
      Global.setting.showPostingRiskWarning = true;
      await _open(tester, thread: thread);
      expect(find.text('发帖 / 回帖风险提醒'), findsOneWidget);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(find.textContaining('甚至封号'), findsOneWidget);
      await tester.tap(find.text('无视警告，继续'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(Global.setting.showPostingRiskWarning, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
    });
  }

  for (final thread in [false, true]) {
    testWidgets('仅发送成功广播刷新 thread=$thread，失败保留输入', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('PonnamKarthik/fluttertoast'), (_) async => true);
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('PonnamKarthik/fluttertoast'), null));
      final api = _ReplyApi();
      Global.tiebaAPI = api;
      int events = 0;
      void listener() => events++;
      replyEvents.addListener(listener);
      addTearDown(() => replyEvents.removeListener(listener));
      await _open(tester, thread: thread);
      tester.testTextInput.enterText('测试成功回调');
      await tester.pump();
      api.fail = true;
      await tester.tap(find.text('发送'));
      await tester.pumpAndSettle();
      expect(events, 0);
      expect(find.byType(ReplyBottomSheet), findsOneWidget);
      api.fail = false;
      await tester.tap(find.text('发送'));
      await tester.pumpAndSettle();
      expect(events, 1);
      expect(replyEvents.threadId, '2');
      expect(replyEvents.floorId, thread ? isNull : '3');
      expect(find.byType(ReplyBottomSheet), findsNothing);
      await tester.pump(const Duration(seconds: 2));
    });
  }

  for (final brightness in Brightness.values) {
    for (final thread in [false, true]) {
      testWidgets('回复弹层紧凑布局 $brightness thread=$thread', (tester) async {
        await _open(tester, thread: thread, brightness: brightness);
        final field = find.byType(ExtendedTextField);
        expect(tester.getSize(field).height, lessThan(100));
        expect(find.text('原回复 · 2楼'), thread ? findsNothing : findsOneWidget);
        expect(find.text('发送').hitTestable(), findsOneWidget);
        expect(find.byType(EmojiPanel), findsNothing);
        expect(find.byType(ImagePanel), findsNothing);
        tester.testTextInput.enterText('测试回复');
        await tester.pump();
        expect(find.text('4 / 2000'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final width in [320.0, 390.0, 800.0]) {
    testWidgets('短引用横向撑满回复弹层内容区 width=$width', (tester) async {
      await _open(tester, replyText: '好', size: Size(width, 844));
      final quote = find.ancestor(
        of: find.text('原回复 · 2楼'),
        matching: find.byType(Container),
      ).first;
      final sheetRect = tester.getRect(find.byType(ReplyBottomSheet));
      final quoteRect = tester.getRect(find.descendant(
        of: quote,
        matching: find.byType(DecoratedBox),
      ).first);
      expect(quoteRect.left, closeTo(sheetRect.left + 16, 0.01));
      expect(quoteRect.right, closeTo(sheetRect.right - 16, 0.01));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('系统键盘上方完整显示发送按钮', (tester) async {
    await _open(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(find.text('发送')).dy, lessThan(544));
    expect(find.text('发送').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('表情与图片面板切换不挤掉发送按钮', (tester) async {
    await _open(tester);
    await tester.tap(find.byIcon(Icons.emoji_emotions_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(EmojiPanel), findsOneWidget);
    expect(find.text('发送').hitTestable(), findsOneWidget);
    await tester.tap(find.byIcon(Icons.image_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(EmojiPanel), findsNothing);
    expect(find.byType(ImagePanel), findsOneWidget);
    expect(find.text('发送').hitTestable(), findsOneWidget);
    await tester.tap(find.byIcon(Icons.image_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(ImagePanel), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('小屏大字号与键盘不溢出', (tester) async {
    await _open(tester, fontSize: 24, size: const Size(320, 568));
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('发送'));
    expect(find.text('发送').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('键盘收起过程保留面板，重新弹出时关闭面板', (tester) async {
    await _open(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.emoji_emotions_outlined));
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 150);
    await tester.pump();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();
    expect(find.byType(EmojiPanel), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(find.byType(EmojiPanel), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('切换面板后立即关闭不会触发异步 setState', (tester) async {
    await _open(tester);
    await tester.tap(find.byIcon(Icons.emoji_emotions_outlined));
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(ReplyBottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
