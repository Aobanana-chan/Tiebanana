import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/moderation/pages/report_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/features/moderation/widgets/moderation_actions.dart';
import 'package:tiebanana/features/thread/widgets/thread_common.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/features/thread/widgets/thread_floor_card.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/core/config/default_config.dart';

const _other = TiebaReportReason(id: 9, groupId: 1, title: '其他', fields: [
  TiebaReportField(component: 'content-input', title: '详细原因', required: true)
]);
const _avatar = TiebaReportReason(id: 9, groupId: 1, title: '头像违规');

class _Api extends DemoTiebaApi {
  TiebaReportTarget? openedTarget;
  int submits = 0;
  Object? failure;
  @override
  Future<TiebaReportForm> getReportForm(TiebaReportTarget target) async {
    openedTarget = target;
    return TiebaReportForm(
        url: Uri.parse('https://tieba.baidu.com/tpl/wise-bawu-core/report'),
        objectType: target.isUser ? 3 : 2,
        threadId: '1',
        postId: '2',
        portrait: 'portrait',
        groups: [
          TiebaReportGroup(
              title: '请选择举报原因',
              reasons: target.isUser ? [_avatar, _other] : [_other])
        ]);
  }

  @override
  Future<void> submitReport(
      TiebaReportForm form, TiebaReportInput input) async {
    submits++;
    if (failure != null) throw failure!;
  }

  @override
  Future<TiebaBlockSettings> getBlockSettings(String uid) async =>
      const TiebaBlockSettings(
          extended: false, follow: false, interact: true, chat: false);
}

const _target = TiebaReportTarget(
    kind: TiebaReportKind.subReply,
    userId: '456',
    name: '回复作者',
    postId: '99',
    summary: '精确到当前楼中楼');
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'uid': '123'});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
  });
  Future<void> pump(WidgetTester tester, _Api api,
      {TiebaReportTarget target = _target,
      bool dark = false,
      double scale = 1}) async {
    Global.tiebaAPI = api;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: dark
            ? TiebananaTheme.dark(tiebananaSeeds.values.first, 14)
            : TiebananaTheme.light(tiebananaSeeds.values.first, 14),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: ReportPage(target: target)));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'other reason requires meaningful explanation; success only after backend confirmation',
      (tester) async {
    final api = _Api();
    await pump(tester, api);
    expect(find.text('使用官方举报页面'), findsNothing);
    await tester.tap(find.text('其他'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '提交举报'))
            .onPressed,
        isNull);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '提交举报'))
            .onPressed,
        isNull);
    await tester.enterText(find.byType(TextField), '具体问题');
    await tester.pump();
    await tester.tap(find.text('提交举报'));
    await tester.pumpAndSettle();
    expect(api.submits, 1);
    expect(find.text('举报已提交'), findsOneWidget);
    expect(find.text('查看举报进度'), findsNothing);
    expect(find.text('完成'), findsOneWidget);
    tester.view.resetPhysicalSize();
  });
  testWidgets('failure retains form; uncertain outcome disables resubmission',
      (tester) async {
    final api = _Api()..failure = const TiebaModerationUncertain('结果尚未确认');
    await pump(tester, api);
    await tester.tap(find.text('其他'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '保留草稿');
    await tester.pump();
    await tester.tap(find.text('提交举报'));
    await tester.pumpAndSettle();
    expect(find.text('保留草稿'), findsOneWidget);
    expect(find.text('举报已提交'), findsNothing);
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '提交举报'))
            .onPressed,
        isNull);
    tester.view.resetPhysicalSize();
  });
  testWidgets(
      'user profile violation has no unnecessary materials; dark and large text no overflow',
      (tester) async {
    final api = _Api();
    await pump(tester, api,
        target: const TiebaReportTarget(
            kind: TiebaReportKind.user, userId: '456', name: '用户'),
        dark: true,
        scale: 1.6);
    await tester.tap(find.text('头像违规'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '提交举报'))
            .onPressed,
        isNotNull);
    tester.view.resetPhysicalSize();
  });
  testWidgets('account switch prevents submitting old form', (tester) async {
    final api = _Api();
    await pump(tester, api);
    await tester.tap(find.text('其他'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '说明');
    await tester.pump();
    Global.tiebaAPI = _Api();
    await tester.tap(find.text('提交举报'));
    await tester.pumpAndSettle();
    expect(api.submits, 0);
    expect(find.text('举报已提交'), findsNothing);
    tester.view.resetPhysicalSize();
  });
  testWidgets('block basic capability only shows comment and chat',
      (tester) async {
    Global.tiebaAPI = _Api();
    await tester.pumpWidget(MaterialApp(
        theme: TiebananaTheme.light(tiebananaSeeds.values.first, 14),
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () =>
                        showBlockSettings(context, uid: '456', name: '用户'),
                    child: const Text('打开'))))));
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.text('禁止 Ta 关注我'), findsNothing);
    expect(find.text('禁止 Ta 评论我'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    expect(find.text('举报与拉黑是独立操作'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('ID 456'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
  });
  testWidgets(
      'preview close opens report action with thread id, never a fabricated post id',
      (tester) async {
    final api = _Api();
    Global.tiebaAPI = api;
    await tester.pumpWidget(MaterialApp(
        theme: TiebananaTheme.light(tiebananaSeeds.values.first, 14),
        home: Scaffold(
            body: ThreadSummary(
                firstPostContent: const [],
                author: TiebaAuthor(
                    icons: const [],
                    levelID: null,
                    nameShow: '作者',
                    portrait: '',
                    uid: '456',
                    username: '作者'),
                createTime: '',
                latestTime: '',
                tid: '11122899147',
                fname: '测试吧',
                viewNum: '0',
                title: '测试帖子',
                agreeNum: '0',
                disagreeNum: '0',
                replyNum: '0'))));
    await tester.tap(find.byTooltip('帖子操作'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('举报帖子'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(api.openedTarget?.threadId, '11122899147');
    expect(api.openedTarget?.postId, '');
    expect(find.byType(ReportPage), findsOneWidget);
  });
  for (final kind in [
    TiebaReportKind.thread,
    TiebaReportKind.reply,
    TiebaReportKind.subReply
  ]) {
    testWidgets('content menu retains report for own content: $kind',
        (tester) async {
      final api = _Api();
      Global.tiebaAPI = api;
      await tester.pumpWidget(MaterialApp(
          theme: TiebananaTheme.light(tiebananaSeeds.values.first, 14),
          home: Scaffold(
              body: ThreadMoreButton(
                  threadId: '77',
                  postId: '998',
                  authorId: '123',
                  authorName: '本人',
                  reportKind: kind))));
      await tester.tap(find.byTooltip('更多'));
      await tester.pumpAndSettle();
      final label = kind == TiebaReportKind.thread ? '举报帖子' : '举报回复';
      expect(find.text(label), findsOneWidget);
      expect(find.text('拉黑作者'), findsNothing);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(api.openedTarget?.postId, '998');
      expect(api.openedTarget?.kind, kind);
    });
  }
  testWidgets(
      'user operations follow design: title, separate rows and cancel without disclaimer',
      (tester) async {
    Global.tiebaAPI = _Api();
    await tester.pumpWidget(MaterialApp(
        theme: TiebananaTheme.light(tiebananaSeeds.values.first, 14),
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () =>
                        showUserModerationMenu(context, uid: '456', name: '用户'),
                    child: const Text('打开'))))));
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.text('用户操作'), findsOneWidget);
    expect(find.text('举报与拉黑是独立操作'), findsNothing);
    expect(find.text('举报用户'), findsOneWidget);
    expect(find.text('拉黑范围'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
  });
  testWidgets(
      'inline subreply report targets the subreply not its parent floor',
      (tester) async {
    final api = _Api();
    Global.tiebaAPI = api;
    final author = TiebaAuthor(
        icons: const [],
        levelID: null,
        nameShow: '作者',
        portrait: '',
        uid: '456',
        username: '作者');
    final post = TiebaSubPost(
        id: '998',
        title: '',
        isVoice: false,
        agreeNum: '0',
        disagreeNum: '0',
        content: [TiebaTextContent(text: '楼中楼正文')],
        createTime: '',
        isInnerFloor: true,
        hasAgree: '0',
        agreeType: '0',
        portrait: '',
        uid: '456',
        nameShow: '作者',
        username: '作者');
    await tester.pumpWidget(ChangeNotifierProvider(create: (_) => APPSettingProvider(), child: MaterialApp(
        theme: TiebananaTheme.light(tiebananaSeeds.values.first, 14),
        home: Scaffold(
            body: InnerFloorEntry(
                subPostList: [post],
                userlist: {'456': author},
                subPostNumber: '1',
                floorNum: '26',
                kz: '77',
                pid: '100',
                forum: TiebaForumData(avatar: '', fid: '1', forumName: '测试吧'),
                threadTitle: '测试',
                threadOwnerUid: '33')))));
    await tester.tap(find.byTooltip('更多'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('举报回复'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(api.openedTarget?.postId, '998');
    expect(api.openedTarget?.threadId, '77');
    expect(api.openedTarget?.kind, TiebaReportKind.subReply);
  });
  testWidgets('block panel fits narrow screen and large text', (tester) async {
    Global.tiebaAPI = _Api();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: TiebananaTheme.dark(tiebananaSeeds.values.first, 14),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!),
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showBlockSettings(context,
                        uid: '456', name: '很长的用户昵称用于验证布局'),
                    child: const Text('打开'))))));
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Dialog), findsOneWidget);
  });
}
