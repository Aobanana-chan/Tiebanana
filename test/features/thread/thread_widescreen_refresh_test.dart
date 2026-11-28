import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/features/message/state/message_reminder.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/thread/data/thread_cache.dart';
import 'package:tiebanana/features/thread/pages/thread_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/app_toast.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';

TiebaThreadPagePost _post(int floor) => TiebaThreadPagePost(
      id: '$floor',
      title: floor == 1 ? '宽屏刷新测试帖' : '',
      floor: '$floor',
      lbsInfo: '',
      subPostList: const <TiebaSubPost>[],
      subPostNumber: '0',
      agreeNum: '3',
      content: <TiebaPostContent>[TiebaTextContent(text: '第 $floor 楼内容')],
      createTime: '1700000000',
      isFirstFloor: floor == 1,
      isInnerFloor: false,
      portrait: '',
      uid: '7',
      nameShow: '测试用户',
      username: 'test',
    );

TiebaThreadPage _page() => TiebaThreadPage(
      posts: <TiebaThreadPagePost>[_post(1), _post(2)],
      page: TiebaPageInfo(currentPage: 1, hasMore: false, hasPrev: false),
      thread: TiebaThreadData(agreeType: '0'),
      userListSet: <String, TiebaAuthor>{
        '7': TiebaAuthor(
          icons: const <String>[],
          levelID: '5',
          nameShow: '测试用户',
          portrait: '',
          uid: '7',
          username: 'test',
        ),
      },
      videoInfo: null,
      isStored: false,
      tid: '123',
      title: '宽屏刷新测试帖',
      fid: '1',
      forumName: '测试',
      avatar: '',
    );

class _ControlledThreadApi extends DemoTiebaApi {
  _ControlledThreadApi() : super(latency: Duration.zero);

  int calls = 0;
  Completer<TiebaThreadPage>? pending;

  @override
  Future<TiebaThreadPage> getThreadPage(
    String kz, {
    String? pid,
    int pn = 1,
    int rn = 30,
    bool onlyLz = false,
  }) {
    calls++;
    final Completer<TiebaThreadPage> c = Completer<TiebaThreadPage>();
    pending = c;
    return c.future;
  }
}

Future<void> _mountWidescreenThread(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 800);
  addTearDown(tester.view.reset);

  final TiebaThreadPage page = _page();
  await tester.pumpWidget(
    MultiProvider(
      providers: <ChangeNotifierProvider<dynamic>>[
        ChangeNotifierProvider<APPSettingProvider>(
          create: (_) => APPSettingProvider(),
        ),
        ChangeNotifierProvider<User>(
          create: (_) => User(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: Fluttertoast.messengerKey,
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        home: ThreadPageMain(
          kz: '123',
          page: page,
          pid: null,
          pn: 1,
          initPost: page.posts,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _ControlledThreadApi api;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'uid': '10001',
      'userName': '烤面包边',
    });
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    Global.threadCache = ThreadCache();
    api = _ControlledThreadApi();
    Global.tiebaAPI = api;
    MessageReminder.reset();
  });

  tearDown(() => Global.tiebaAPI = DemoTiebaApi());

  testWidgets('宽屏帖子详情页点击右侧栏刷新按钮：顶栏与页面内按钮均有加载动画并屏蔽重复点击', (
    WidgetTester tester,
  ) async {
    await _mountWidescreenThread(tester);

    expect(find.byType(DesktopShellFrame), findsOneWidget);
    expect(find.byTooltip('刷新 (F5)'), findsOneWidget);
    expect(find.byTooltip('刷新'), findsOneWidget);
    expect(find.text('刷新最新回复'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    final Finder sidebarRefreshBtn = find.byTooltip('刷新');
    await tester.tap(sidebarRefreshBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(api.calls, 1);
    // 顶栏与侧栏按钮均进入旋转动画态（Tooltip 变为「正在刷新…」）且顶部进度条出现
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byTooltip('正在刷新…'), findsNWidgets(2));
    // 更新提示条与底部刷新按钮均显示加载动画
    expect(find.text('正在更新帖子…'), findsOneWidget);
    expect(find.text('正在刷新…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

    // 确认刷新图标的 RotationTransition 正在旋转（turns > 0）
    final Iterable<RotationTransition> rotations = tester
        .widgetList<RotationTransition>(find.byType(RotationTransition))
        .where((RotationTransition r) => r.turns.value > 0);
    expect(rotations.length, greaterThanOrEqualTo(2));

    // 刷新中再次点击侧栏或顶栏刷新按钮不会重复触发请求
    await tester.tap(find.byTooltip('正在刷新…').first);
    await tester.tap(find.byTooltip('正在刷新…').last);
    await tester.pump();
    expect(api.calls, 1);

    api.pending!.complete(_page());
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byTooltip('刷新 (F5)'), findsOneWidget);
    expect(find.byTooltip('刷新'), findsOneWidget);
    expect(find.text('刷新最新回复'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('宽屏帖子详情页点击底部「刷新最新回复」与顶栏刷新均同步展示加载动画', (
    WidgetTester tester,
  ) async {
    await _mountWidescreenThread(tester);

    // 1. 点击底部「刷新最新回复」
    final Finder bottomRefreshBtn = find.text('刷新最新回复');
    await tester.ensureVisible(bottomRefreshBtn);
    await tester.tap(bottomRefreshBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(api.calls, 1);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byTooltip('正在刷新…'), findsNWidgets(2));
    expect(find.text('正在刷新…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

    api.pending!.complete(_page());
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // 2. 点击顶栏刷新按钮，页面内侧栏与底部按钮同样同步进入加载动画态
    await tester.tap(find.byTooltip('刷新 (F5)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(api.calls, 2);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byTooltip('正在刷新…'), findsNWidgets(2));
    expect(find.text('正在刷新…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

    api.pending!.complete(_page());
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
