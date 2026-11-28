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
import 'package:tiebanana/features/thread/data/thread_cache_codec.dart';
import 'package:tiebanana/features/thread/pages/thread_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/app_toast.dart';

TiebaThreadPagePost _post(int floor) => TiebaThreadPagePost(
      id: '$floor',
      title: floor == 1 ? '跳页测试帖' : '',
      floor: '$floor',
      lbsInfo: '',
      subPostList: const <TiebaSubPost>[],
      subPostNumber: '0',
      agreeNum: '5',
      content: <TiebaPostContent>[
        TiebaTextContent(text: '楼层内容 $floor\n用于验证页码指示与跳转行为'),
      ],
      createTime: '1700000000',
      isFirstFloor: floor == 1,
      isInnerFloor: false,
      portrait: '',
      uid: '7',
      nameShow: '测试用户',
      username: 'test',
    );

TiebaThreadPage _page(
  int pn, {
  int? totalPage = 5,
  int count = 10,
  bool includeFirst = false,
}) {
  final int base = (pn - 1) * count + 2;
  return TiebaThreadPage(
    posts: <TiebaThreadPagePost>[
      if (pn == 1 && includeFirst) _post(1),
      for (int i = 0; i < count; i++) _post(base + i),
    ],
    page: TiebaPageInfo(
      currentPage: pn,
      totalPage: totalPage,
      hasMore: totalPage != null ? pn < totalPage : pn < 5,
      hasPrev: pn > 1,
    ),
    thread: TiebaThreadData(agreeType: '0', authorUid: '7'),
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
    title: '跳页测试帖',
    fid: '1',
    forumName: '测试',
    avatar: '',
  );
}

class _JumpApi extends DemoTiebaApi {
  _JumpApi() : super(latency: Duration.zero);

  final List<(int pn, bool onlyLz)> calls = <(int pn, bool onlyLz)>[];
  int? totalPageOverride = 5;
  int? lzTotalPageOverride = 2;
  Completer<TiebaThreadPage>? pending;
  bool autoRespond = true;

  @override
  Future<TiebaThreadPage> getThreadPage(
    String kz, {
    String? pid,
    int pn = 1,
    int rn = 30,
    bool onlyLz = false,
  }) async {
    calls.add((pn, onlyLz));
    if (!autoRespond) {
      pending = Completer<TiebaThreadPage>();
      return pending!.future;
    }
    return _page(
      pn,
      totalPage: onlyLz ? lzTotalPageOverride : totalPageOverride,
      includeFirst: pn == 1,
    );
  }
}

Future<GlobalKey<ThreadPageMainState>> _mountThread(
  WidgetTester tester,
  TiebaThreadPage initial, {
  Size size = const Size(390, 640),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  final GlobalKey<ThreadPageMainState> key = GlobalKey<ThreadPageMainState>();
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
        home: Scaffold(
          body: ThreadPageMain(
            key: key,
            kz: '123',
            page: initial,
            pid: null,
            pn: initial.page.currentPage,
            initPost: initial.posts,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

void main() {
  late _JumpApi api;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    Global.threadCache = ThreadCache();
    api = _JumpApi();
    Global.tiebaAPI = api;
    MessageReminder.reset();
  });

  tearDown(() => Global.tiebaAPI = DemoTiebaApi());

  test('ThreadCacheCodec 保留与读取 totalPage', () {
    const TiebaPageInfo info = TiebaPageInfo(
      currentPage: 3,
      totalPage: 12,
      hasMore: true,
      hasPrev: true,
    );
    final TiebaPageInfo restored =
        ThreadCacheCodec.readPageInfo(ThreadCacheCodec.pageInfo(info));
    expect(restored.currentPage, 3);
    expect(restored.totalPage, 12);
    expect(restored.hasMore, isTrue);
    expect(restored.hasPrev, isTrue);

    final TiebaPageInfo legacy = ThreadCacheCodec.readPageInfo(
      <String, dynamic>{'currentPage': 2, 'hasMore': false, 'hasPrev': true},
    );
    expect(legacy.totalPage, isNull);
  });

  testWidgets('移动端展示当前页与总页数，滑入下一页后自动同步当前页', (WidgetTester tester) async {
    await _mountThread(tester, _page(1, includeFirst: true));

    expect(find.text('第 1 / 5 页'), findsOneWidget);

    final ScrollPosition pos =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    // 滚近底部并向上拖动触发第 2 页预取，再滑进第 2 页楼层。
    pos.jumpTo(pos.maxScrollExtent - 300);
    await tester.pump();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(api.calls, <(int, bool)>[(2, false)]);

    pos.jumpTo(pos.maxScrollExtent);
    await tester.pumpAndSettle();

    // 菜单里的跳页项也实时反映当前页 / 总页数。
    await tester.tap(find.descendant(
      of: find.byType(SliverAppBar),
      matching: find.byTooltip('更多'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('跳页（2 / 5）'), findsOneWidget);
  });

  testWidgets('移动端跳页面板支持滑块、边界校验与末页跳转，并清理非连续旧页',
      (WidgetTester tester) async {
    final GlobalKey<ThreadPageMainState> key =
        await _mountThread(tester, _page(1, includeFirst: true));

    await tester.tap(find.text('第 1 / 5 页'));
    await tester.pumpAndSettle();

    expect(find.text('页码跳转'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('末页'), findsOneWidget);

    // 输入越界页码会给出提示且不关闭弹层。
    await tester.enterText(find.byType(TextField), '99');
    await tester.pump();
    expect(find.text('共 5 页，请输入 1–5'), findsOneWidget);

    await tester.tap(find.text('跳转'));
    await tester.pumpAndSettle();
    expect(find.text('页码跳转'), findsOneWidget);
    expect(api.calls, isEmpty);

    // 点击「末页」跳转到第 5 页。
    await tester.tap(find.text('末页'));
    await tester.pumpAndSettle();

    expect(api.calls, <(int, bool)>[(5, false)]);
    expect(find.text('第 5 / 5 页'), findsOneWidget);
    // 非连续跳页后清除第 1 页旧缓存，不会把 1 楼和第 5 页混排在一起。
    expect(key.currentState!.info.postPage.keys, <int>[5]);
    expect(key.currentState!.info.topPn, 5);
    expect(key.currentState!.info.bottomPn, 5);
  });

  testWidgets('正序下跳转到已加载页直接滚动定位，不重复请求网络', (WidgetTester tester) async {
    final GlobalKey<ThreadPageMainState> key =
        await _mountThread(tester, _page(1, includeFirst: true));

    key.currentState!.nextPage();
    await tester.pumpAndSettle();
    expect(api.calls, <(int, bool)>[(2, false)]);

    await tester.tap(find.text('第 1 / 5 页'));
    await tester.pumpAndSettle();
    expect(find.text('已连续加载第 1–2 页'), findsOneWidget);

    await tester.tap(find.text('下一页'));
    await tester.pumpAndSettle();
    expect(api.calls, <(int, bool)>[(2, false)]);

    await tester.tap(find.descendant(
      of: find.byType(SliverAppBar),
      matching: find.byTooltip('更多'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('跳页（2 / 5）'), findsOneWidget);
  });

  testWidgets('总页数未知时隐藏滑块并提示可直接输入页码', (WidgetTester tester) async {
    await _mountThread(
      tester,
      _page(1, totalPage: null, includeFirst: true),
    );

    expect(find.text('第 1 页'), findsOneWidget);
    await tester.tap(find.text('第 1 页'));
    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsNothing);
    expect(find.text('当前第 1 页'), findsOneWidget);
    expect(find.text('暂未获取到总页数，可直接输入页码跳转'), findsOneWidget);
  });

  testWidgets('宽屏右侧栏与列表头尾展示当前/总页数并支持快捷翻页、输入跳转与只看楼主独立计数',
      (WidgetTester tester) async {
    final GlobalKey<ThreadPageMainState> key = await _mountThread(
      tester,
      _page(1, includeFirst: true),
      size: const Size(1280, 800),
    );

    // 排序行与侧栏阅读控制均显示「第 1 / 5 页」。
    expect(find.text('第 1 / 5 页'), findsNWidgets(2));
    expect(find.byTooltip('首页'), findsOneWidget);
    expect(find.byTooltip('末页'), findsOneWidget);

    // 侧栏输入第 4 页并点击 Go。
    await tester.enterText(find.byType(TextField).first, '4');
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    expect(api.calls, <(int, bool)>[(4, false)]);
    expect(find.text('第 4 / 5 页'), findsNWidgets(2));

    // 点击「末页」直达第 5 页。
    await tester.tap(find.byTooltip('末页'));
    await tester.pumpAndSettle();
    expect(api.calls, <(int, bool)>[(4, false), (5, false)]);
    expect(find.text('第 5 / 5 页'), findsNWidgets(2));

    // 滚到底部确认底部栏也显示「第 5 / 5 页」。
    final ScrollPosition pos =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    pos.jumpTo(pos.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('刷新最新回复'), findsOneWidget);
    expect(find.text('第 5 / 5 页'), findsNWidgets(2));

    // 切换到「只看楼主」，使用独立的页码和总页数。
    key.currentState!.onlyLz();
    await tester.pumpAndSettle();
    expect(api.calls.last, (1, true));
    pos.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('第 1 / 2 页'), findsNWidgets(2));
  });
}
