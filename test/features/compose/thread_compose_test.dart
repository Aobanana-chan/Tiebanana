import 'package:flutter/material.dart';
import 'dart:async';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/compose/models/thread_compose_draft.dart';
import 'package:tiebanana/features/compose/pages/thread_compose_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/features/compose/widgets/compose_poll_editor.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/compose/pages/compose_topic_page.dart';
import 'package:tiebanana/features/compose/pages/compose_score_page.dart';

class _PublishApi extends DemoTiebaApi {
  @override
  Future<TiebaPublisherConfig> getPublisherConfig(
          {required String fid}) async =>
      const TiebaPublisherConfig(statements: ['贴子含AI内容', '贴子原创声明']);
  @override
  bool get isLogin => true;
  int calls = 0;
  Object? error;
  Completer<TiebaPublishResult>? pending;
  String? sentContent;
  TiebaPublishPoll? sentPoll;
  String? sentTopic;
  bool? sentHide;
  String? sentStatement;
  @override
  Future<List<TiebaComposeTopic>> searchComposeTopics(
          {required String fid, String prefix = ''}) async =>
      [const TiebaComposeTopic(id: '99', name: '真实返回的话题')];
  @override
  Future<TiebaPublishResult> publishThread(
      {required String fid,
      required String forumName,
      required String title,
      required String content,
      int imageCount = 0,
      TiebaPublishPoll? poll,
      String? topicId,
      bool? hideFromProfile,
      String? contentStatement,
      TiebaPublishScore? score}) async {
    calls++;
    sentContent = content;
    sentPoll = poll;
    sentTopic = topicId;
    sentHide = hideFromProfile;
    sentStatement = contentStatement;
    if (error != null) throw error!;
    if (pending != null) return await pending!.future;
    return const TiebaPublishResult(tid: '12345', message: '正在审核中');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> bodyText(WidgetTester tester, String value) async {
    final field = tester
        .widget<ExtendedTextField>(find.byKey(const ValueKey('compose-body')));
    field.controller!.text = value;
    await tester.pump();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({'uid': '100'});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    Global.setting.showPostingRiskWarning = false;
    Global.tiebaAPI = _PublishApi();
  });

  Future<void> open(WidgetTester tester,
      {bool dark = false,
      double size = 16,
      String seed = 'blue',
      double width = 390}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      routes: {
        PageRouter.threadPage: (context) => Scaffold(
            body: Text(
                '已进入帖子 ${(ModalRoute.of(context)!.settings.arguments as ThreadPageRouterData).kz}'))
      },
      theme: dark
          ? TiebananaTheme.dark(seedOf(seed), size)
          : TiebananaTheme.light(seedOf(seed), size),
      home: const ThreadComposePage(fid: '123', forumName: '风景摄影'),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('打开发帖立即提醒，未发布任何内容', (tester) async {
    Global.setting.showPostingRiskWarning = true;
    await open(tester);
    expect(find.text('发帖 / 回帖风险提醒'), findsOneWidget);
    expect(find.textContaining('当前贴吧'), findsOneWidget);
    expect((Global.tiebaAPI as _PublishApi).calls, 0);
    await tester.tap(find.text('无视警告，继续'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(Global.setting.showPostingRiskWarning, isTrue);
  });

  test('投票校验、草稿序列化及版本保护', () {
    expect(ComposePoll.validate('', ['a', 'b']), isNotNull);
    expect(ComposePoll.validate('标题', ['a', ' a ']), '选项不能重复');
    expect(ComposePoll.validate('标题', ['a', '']), isNotNull);
    expect(ComposePoll.validate('标题', ['a' * 15, 'b']), isNotNull);
    const draft = ThreadComposeDraft(
        title: '标题',
        body: '正文',
        tail: '尾巴',
        useTail: true,
        poll: ComposePoll(
            title: '选哪个', options: ['山', '海'], multiple: true, days: 7),
        attachments: [ComposeAttachment('image-id', true)]);
    final restored = ThreadComposeDraft.decode(draft.encode());
    expect(restored.encode(), draft.encode());
    expect(restored.hasContent, isTrue);
    expect(restored.poll!.multiple, isTrue);
    expect(() => ThreadComposeDraft.decode('{"version":2}'),
        throwsFormatException);
  });

  for (final dark in [false, true]) {
    for (final size in [16.0, 22.5]) {
      testWidgets('发帖明暗/大字号无溢出 dark=$dark size=$size', (tester) async {
        await open(tester, dark: dark, size: size, width: 360);
        expect(find.text('发帖'), findsOneWidget);
        expect(find.text('添加话题'), findsOneWidget);
        expect(
            tester
                .widget<FilledButton>(find.widgetWithText(FilledButton, '发布'))
                .onPressed,
            isNull);
        await tester.enterText(
            find.byKey(const ValueKey('compose-title')), '周末去山里走走');
        await bodyText(tester, '把一段绿色分享给大家。');
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('内容声明'));
        await tester.tap(find.text('内容声明'));
        await tester.pumpAndSettle();
        expect(find.text('贴子含AI内容'), findsOneWidget);
        expect(find.text('贴子原创声明'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('草稿真实保存并按账号/吧隔离', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const ValueKey('compose-title')), '草稿标题');
    await bodyText(tester, '未发布的正文');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final raw = Global.profile.getString('threadCompose.v1.100.123');
    expect(raw, isNotNull);
    expect(ThreadComposeDraft.decode(raw!).body, '未发布的正文');
    expect(find.text('草稿已暂存 · 仅本机'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await open(tester);
    expect(find.text('草稿标题'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await Global.profile.setString('uid', '200');
    await open(tester);
    expect(find.text('草稿标题'), findsNothing);
    expect(Global.profile.getString('threadCompose.v1.100.123'), raw);
  });

  testWidgets('坏草稿不会被自动保存覆盖', (tester) async {
    await Global.profile.setString('threadCompose.v1.100.123', '{broken');
    await open(tester);
    await tester.enterText(find.byKey(const ValueKey('compose-title')), '新标题');
    await tester.pump(const Duration(seconds: 2));
    expect(Global.profile.getString('threadCompose.v1.100.123'), '{broken');
    expect(find.textContaining('原草稿仍保留'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('投票编辑、校验、保存与恢复', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('互动组件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('投票'));
    await tester.pumpAndSettle();
    expect(find.byType(ComposePollEditor), findsOneWidget);
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(find.text('请填写投票标题'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('poll-title')), '周末去哪儿');
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '去山里');
    await tester.enterText(fields.at(2), '去海边');
    await tester.tap(find.text('多选'));
    await tester.tap(find.text('7 天'));
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(find.byType(ComposePollEditor), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final draft = ThreadComposeDraft.decode(
        Global.profile.getString('threadCompose.v1.100.123')!);
    expect(draft.poll!.options, ['去山里', '去海边']);
    expect(draft.poll!.multiple, isTrue);
    expect(draft.poll!.days, 7);
    await tester.ensureVisible(find.byTooltip('删除投票'));
    await tester.tap(find.byTooltip('删除投票'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('周末去哪儿'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('发布失败保留输入和草稿，预览含真实文字', (tester) async {
    Global.tiebaAPI = _PublishApi()
      ..error = NetAPIError(
          type: NetAPIErrorType.actionFalied,
          redoTimes: 0,
          errorMessage: '禁止发帖');
    await open(tester);
    await tester.enterText(
        find.byKey(const ValueKey('compose-title')), '不能假装成功');
    await bodyText(tester, '保留这些内容');
    await tester.tap(find.text('发布'));
    await tester.pumpAndSettle();
    expect(find.text('禁止发帖'), findsOneWidget);
    expect(find.text('发布成功'), findsNothing);
    expect(Global.profile.getString('threadCompose.v1.100.123'), isNotNull);
    await tester.tap(find.text('预览'));
    await tester.pumpAndSettle();
    expect(find.text('发布前，先看一眼'), findsOneWidget);
    expect(find.textContaining('发布前内容预览'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('真实发布只提交一次，取得 tid 后清草稿并跳转', (tester) async {
    final api = _PublishApi()..pending = Completer<TiebaPublishResult>();
    Global.tiebaAPI = api;
    await open(tester);
    await tester.enterText(
        find.byKey(const ValueKey('compose-title')), '准备发布的标题');
    await bodyText(tester, '这是正文');
    await tester.tap(find.text('发布'));
    await tester.pump();
    expect(find.text('发布中'), findsOneWidget);
    expect(api.calls, 1);
    expect(api.sentContent, '这是正文');
    api.pending!.complete(const TiebaPublishResult(tid: '12345', pid: '5678'));
    await tester.pumpAndSettle();
    expect(find.text('已进入帖子 12345'), findsOneWidget);
    expect(Global.profile.getString('threadCompose.v1.100.123'), isNull);
  });

  testWidgets('结果不确定暂停重发且保留草稿', (tester) async {
    final api = _PublishApi()..error = const TiebaPublishUncertain('请先核对个人主页');
    Global.tiebaAPI = api;
    await open(tester);
    await tester.enterText(
        find.byKey(const ValueKey('compose-title')), '结果待确认');
    await bodyText(tester, '请不要重复发送');
    await tester.tap(find.text('发布'));
    await tester.pumpAndSettle();
    expect(api.calls, 1);
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '发布'))
            .onPressed,
        isNull);
    expect(Global.profile.getString('threadCompose.v1.100.123'), isNotNull);
    expect(Global.profile.getBool('threadCompose.v1.100.123.pending'), isTrue);
    await tester.pumpWidget(const SizedBox());
    await open(tester);
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '发布'))
            .onPressed,
        isNull);
    expect(find.textContaining('上次发布的结果尚未确认'), findsOneWidget);
  });

  testWidgets('真实话题与投票进入发布请求而非静默忽略', (tester) async {
    final api = _PublishApi()..pending = Completer<TiebaPublishResult>();
    Global.tiebaAPI = api;
    await Global.profile.setString(
        'threadCompose.v1.100.123',
        const ThreadComposeDraft(
                title: '周末去哪里',
                body: '来投票',
                topicId: '99',
                topicName: '真实返回的话题',
                poll: ComposePoll(title: '去哪儿', options: ['山', '海'], days: 7))
            .encode());
    await open(tester);
    await tester.tap(find.text('发布'));
    await tester.pump();
    expect(api.calls, 1);
    expect(api.sentTopic, '99');
    expect(api.sentContent, contains('#真实返回的话题#'));
    expect(api.sentPoll!.options, ['山', '海']);
    expect(api.sentPoll!.days, 7);
    api.pending!.complete(const TiebaPublishResult(tid: '12345'));
    await tester.pumpAndSettle();
    expect(find.text('已进入帖子 12345'), findsOneWidget);
  });

  testWidgets('展示范围与声明可选、可取消、持久化并真实传参', (tester) async {
    final api = _PublishApi()..pending = Completer<TiebaPublishResult>();
    Global.tiebaAPI = api;
    await open(tester);
    await tester.ensureVisible(find.text('展示范围'));
    await tester.tap(find.text('展示范围'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('个人主页不可见'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('内容声明'));
    await tester.tap(find.text('内容声明'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('贴子含AI内容'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('内容声明'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('贴子含AI内容').last);
    await tester.pumpAndSettle();
    expect(find.text('不声明'), findsOneWidget);
    await tester.tap(find.text('内容声明'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('贴子原创声明'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('compose-title')));
    await tester.enterText(find.byKey(const ValueKey('compose-title')), '设置测试');
    await bodyText(tester, '测试正文');
    await tester.tap(find.text('发布'));
    await tester.pump();
    expect(api.sentHide, isTrue);
    expect(api.sentStatement, '贴子原创声明');
    final draft = ThreadComposeDraft.decode(
        Global.profile.getString('threadCompose.v1.100.123')!);
    expect(draft.hideFromProfile, isTrue);
    expect(draft.contentStatement, '贴子原创声明');
    api.pending!.complete(const TiebaPublishResult(tid: '12345'));
    await tester.pumpAndSettle();
  });

  test('打分项官方约束和草稿恢复', () {
    const items = [ComposeScoreItem(assetId: '1', title: '山野', content: '很美')];
    expect(ComposeScore.validate(items), isNull);
    expect(
        ComposeScore.validate([
          const ComposeScoreItem(assetId: '1', title: '山 野'),
          const ComposeScoreItem(assetId: '2', title: '山野')
        ]),
        isNotNull);
    expect(
        ComposeScore.validate(
            [const ComposeScoreItem(assetId: '1', title: '🌿')]),
        isNotNull);
    const draft =
        ThreadComposeDraft(score: ComposeScore(items: items, levelLimit: 5));
    final restored = ThreadComposeDraft.decode(draft.encode());
    expect(restored.score!.items.single.title, '山野');
    expect(restored.score!.levelLimit, 5);
  });

  for (final size in [16.0, 22.5]) {
    testWidgets('打分编辑与等级限制，窄屏字号 $size', (tester) async {
      tester.view.physicalSize = const Size(360, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: TiebananaTheme.dark(seedOf('blue'), size),
          home: const ComposeScorePage(
              initial: ComposeScore(items: [
            ComposeScoreItem(assetId: 'test', title: '山野', content: '很美')
          ]))));
      await tester.pumpAndSettle();
      expect(find.text('山野'), findsOneWidget);
      await tester.ensureVisible(find.text('限制吧等级'));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Lv.1 及以上吧友可打分'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('提高等级'));
      await tester.tap(find.byTooltip('提高等级'));
      await tester.pumpAndSettle();
      expect(find.text('Lv.2 及以上吧友可打分'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('键盘上沿保留工具条、关闭时确认草稿', (tester) async {
    await open(tester);
    await bodyText(tester, '还没写完');
    tester.view.viewInsets = const FakeViewPadding(bottom: 290);
    await tester.pumpAndSettle();
    expect(find.byTooltip('收起键盘'), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('关闭发帖'));
    await tester.pumpAndSettle();
    expect(find.text('把这次灵感留下来？'), findsOneWidget);
    await tester.tap(find.text('继续编辑'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ExtendedTextField>(
                find.byKey(const ValueKey('compose-body')))
            .controller!
            .text,
        '还没写完');
    await tester.pumpWidget(const SizedBox());
  });

  for (final decision in ['保存草稿并退出', '不保存，退出']) {
    testWidgets('返回保护 $decision', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ThreadComposePage(
                                fid: '123', forumName: '风景摄影'))),
                    child: const Text('打开发帖')))),
      ));
      await tester.tap(find.text('打开发帖'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('compose-title')), '离开前的草稿');
      await tester.tap(find.byTooltip('关闭发帖'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(decision));
      await tester.pumpAndSettle();
      expect(find.text('打开发帖'), findsOneWidget);
      expect(find.byType(ThreadComposePage), findsNothing);
      final stored = Global.profile.getString('threadCompose.v1.100.123');
      if (decision == '保存草稿并退出') {
        expect(ThreadComposeDraft.decode(stored!).title, '离开前的草稿');
      } else {
        expect(stored, isNull);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('话题走真实接口，打分不使用假数据，取消投票不污染草稿', (tester) async {
    Global.tiebaAPI = _PublishApi();
    await open(tester);
    await tester.tap(find.text('添加话题'));
    await tester.pumpAndSettle();
    expect(find.byType(ComposeTopicPage), findsOneWidget);
    expect(find.text('真实返回的话题'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('互动组件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('打分'));
    await tester.pumpAndSettle();
    expect(find.text('当前吧暂不支持打分'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭面板'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('互动组件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('投票'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('poll-title')), '不保存的投票');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(Global.profile.getString('threadCompose.v1.100.123'), isNull);
    expect(find.byTooltip('编辑投票'), findsNothing);
  });

  for (final seed in ['cyan', 'teal', 'green', 'yellow', 'pink', 'white']) {
    testWidgets('沿用主题 $seed', (tester) async {
      await open(tester, seed: seed);
      expect(find.text('发帖'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
