import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/features/forum/state/forum_state.dart';
import 'package:tiebanana/features/home/widgets/forum_tag.dart';
import 'package:tiebanana/features/profile/pages/user_profile_page.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/shared/layout/page_wrap.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';

class _UserProfileTestApi extends DemoTiebaApi {
  _UserProfileTestApi({this.hidePosts = false, this.emptyReplies = false})
      : super(latency: Duration.zero);

  final bool hidePosts;
  final bool emptyReplies;

  @override
  Future<TiebaUserPostPage> getUserPost({
    required String uid,
    int pn = 1,
    int rn = 20,
  }) async {
    if (hidePosts) {
      return const TiebaUserPostPage(hidePost: true, posts: <TiebaUserPost>[]);
    }
    return super.getUserPost(uid: uid, pn: pn, rn: rn);
  }

  @override
  Future<TiebaUserPostPage> getUserPostLowVersion({
    required String uid,
    int pn = 1,
    int rn = 20,
  }) async {
    if (emptyReplies) {
      return const TiebaUserPostPage(hidePost: false, posts: <TiebaUserPost>[]);
    }
    return super.getUserPostLowVersion(uid: uid, pn: pn, rn: rn);
  }
}

Widget _wrapHost(
  Widget child, {
  String seedKey = 'blue',
  bool dark = false,
  double fontSize = 16,
}) {
  final TiebananaSeed seed = seedOf(seedKey);
  return MultiProvider(
    providers: <ChangeNotifierProvider<dynamic>>[
      ChangeNotifierProvider<APPSettingProvider>(
        create: (_) => APPSettingProvider(),
      ),
      ChangeNotifierProvider<User>(create: (_) => User()),
      ChangeNotifierProvider<ForumState>(create: (_) => ForumState()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark
          ? TiebananaTheme.dark(seed, fontSize)
          : TiebananaTheme.light(seed, fontSize),
      home: child,
    ),
  );
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{'uid': '10001'});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    Global.tiebaAPI = _UserProfileTestApi();
  });

  void setWindowSize(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  testWidgets('1280 宽屏访客态：桌面壳层、左档右流、三页签切换与锚定菜单', (tester) async {
    setWindowSize(tester, const Size(1280, 800));

    await tester.pumpWidget(_wrapHost(const UserVisitor(uid: '20002')));
    await _pumpFrames(tester);

    expect(find.byType(DesktopShellFrame), findsOneWidget);
    expect(find.byType(PageWrap), findsOneWidget);
    expect(find.text('用户主页'), findsWidgets);
    expect(find.text('私信'), findsOneWidget);
    expect(find.text('＋ 关注'), findsOneWidget);
    expect(find.text('贴吧 ID'), findsOneWidget);
    expect(find.text('复制'), findsOneWidget);
    expect(find.byType(ThreadSummary), findsWidgets);

    // 打开锚定用户管理菜单
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await _pumpFrames(tester);
    expect(find.text('举报用户'), findsOneWidget);
    expect(find.text('拉黑范围'), findsOneWidget);

    // 关闭菜单后切到「回复」与「关注的吧」
    await tester.tapAt(const Offset(10, 10));
    await _pumpFrames(tester);

    await tester.tap(find.byWidgetPredicate(
        (Widget w) => w is Text && (w.data?.startsWith('回复 ') ?? false)));
    await _pumpFrames(tester);
    expect(find.byType(ThreadSummary), findsWidgets);

    await tester.tap(find.byWidgetPredicate(
        (Widget w) => w is Text && (w.data?.startsWith('关注的吧 ') ?? false)));
    await _pumpFrames(tester);
    expect(find.byType(ForumTagMedium), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1280 宽屏本人态：显示本人徽标、编辑资料与返回个人与设置', (tester) async {
    setWindowSize(tester, const Size(1280, 800));

    await tester.pumpWidget(_wrapHost(const UserVisitor(uid: '10001')));
    await _pumpFrames(tester);

    expect(find.text('我的主页'), findsWidgets);
    expect(find.text('本人'), findsOneWidget);
    expect(find.text('编辑资料'), findsOneWidget);
    expect(find.text('返回个人与设置'), findsOneWidget);
    expect(find.text('私信'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('隐藏状态与空状态在桌面工作台明确区分', (tester) async {
    setWindowSize(tester, const Size(1280, 800));
    Global.tiebaAPI = _UserProfileTestApi(hidePosts: true, emptyReplies: true);

    await tester.pumpWidget(_wrapHost(const UserVisitor(uid: '20002')));
    await _pumpFrames(tester);

    expect(find.text('这位老铁已将贴设为隐藏'), findsOneWidget);

    await tester.tap(find.byWidgetPredicate(
        (Widget w) => w is Text && (w.data?.startsWith('回复 ') ?? false)));
    await _pumpFrames(tester);
    expect(find.text('还没有回复过'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('720 / 820 / 1080 / 1280 与 640 窄屏断点及极端字号主题切换无溢出', (tester) async {
    for (final ({Size size, String seed, bool dark, double font}) c in <({
      Size size,
      String seed,
      bool dark,
      double font,
    })>[
      (size: const Size(1280, 800), seed: 'blue', dark: false, font: 12),
      (size: const Size(1080, 800), seed: 'blue', dark: true, font: 20),
      (size: const Size(820, 720), seed: 'white', dark: true, font: 20),
      (size: const Size(720, 700), seed: 'white', dark: false, font: 20),
    ]) {
      setWindowSize(tester, c.size);
      await tester.pumpWidget(_wrapHost(
        UserVisitor(
            key: ValueKey<String>('${c.size}-${c.seed}-${c.dark}'),
            uid: '20002'),
        seedKey: c.seed,
        dark: c.dark,
        fontSize: c.font,
      ));
      await _pumpFrames(tester);
      expect(find.byType(DesktopShellFrame), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    // 640 窄屏：回落到移动端单列 Scaffold
    setWindowSize(tester, const Size(640, 800));
    await tester.pumpWidget(
      _wrapHost(const UserVisitor(key: ValueKey<int>(640), uid: '20002')),
    );
    await _pumpFrames(tester);
    expect(find.byType(DesktopShellFrame), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
