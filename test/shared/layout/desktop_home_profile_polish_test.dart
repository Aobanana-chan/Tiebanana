import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/features/forum/state/forum_state.dart';
import 'package:tiebanana/features/history/data/dao_api.dart';
import 'package:tiebanana/features/history/data/view_history.dart';
import 'package:tiebanana/features/history/models/view_history_page_model.dart';
import 'package:tiebanana/features/home/pages/home_page.dart';
import 'package:tiebanana/features/home/widgets/forum_tag.dart';
import 'package:tiebanana/features/message/state/message_reminder.dart';
import 'package:tiebanana/features/profile/pages/my_profile_page.dart';
import 'package:tiebanana/features/search/widgets/search_bar.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/splash/splash_tips.dart';
import 'package:tiebanana/features/thread/data/thread_cache.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/floating_search_app_bar.dart';

class _ForumsWithData extends ForumState {
  _ForumsWithData([this.count = 4]);

  final int count;

  @override
  List<LikeForumInfo> get forums => <LikeForumInfo>[
        for (int i = 0; i < count; i++)
          LikeForumInfo(
            forumId: '$i',
            avatar: '',
            forumName: '测试$i',
            isSign: '0',
            levelId: '${i + 1}',
          ),
      ];

  @override
  Future<void> refresh() async {}
}

class _FakeDao extends DAOAPI {
  @override
  List<ViewHistoryDatabase> getHistoryList({
    int? offset,
    int? limit,
    bool includeHidden = true,
  }) =>
      <ViewHistoryDatabase>[
        ViewHistoryDatabase(
          uid: '10001',
          tid: '8301124590',
          title: '这是一条测试浏览历史记录标题',
          forumName: '测试吧',
          latestViewTime: DateTime(2026, 11, 20, 12),
          hidden: true,
        )..id = 1,
      ];
}

Widget _wrapApp(Widget child, {ForumState? forumState}) {
  return MultiProvider(
    providers: <ChangeNotifierProvider<dynamic>>[
      ChangeNotifierProvider<APPSettingProvider>(
        create: (_) => APPSettingProvider(),
      ),
      ChangeNotifierProvider<User>(
        create: (_) => User(),
      ),
      if (forumState != null)
        ChangeNotifierProvider<ForumState>.value(value: forumState)
      else
        ChangeNotifierProvider<ForumState>(create: (_) => ForumState()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: child,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'uid': '10001',
      'userName': '烤面包边',
    });
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    Global.tiebaAPI = DemoTiebaApi(latency: Duration.zero);
    MessageReminder.reset();
  });

  testWidgets('宽屏首页不重复渲染移动端搜索栏，仅保留顶栏搜索；窄屏保留搜索栏', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrapApp(const HomePage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(SearchBar), findsNothing);
    expect(find.text('Ctrl K'), findsOneWidget);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byType(SearchBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('宽屏首页移除管理排序按钮、展示全部关注的吧、去掉最近浏览底部说明，开屏 Tips 包含长按拖动排序', (
    WidgetTester tester,
  ) async {
    // 超过默认的 12 个上限（20 个），宽屏不截断、不显示展开按钮。
    final _ForumsWithData forums = _ForumsWithData(20);
    addTearDown(forums.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrapApp(
      Scaffold(
        body: TagPan(historyLoader: () => <ViewHistoryPageModel>[]),
      ),
      forumState: forums,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('管理排序'), findsNothing);
    expect(find.text('完成排序'), findsNothing);
    expect(find.textContaining('展开全部'), findsNothing);
    expect(find.text('测试0吧'), findsOneWidget);
    expect(find.text('测试19吧'), findsOneWidget);
    expect(find.textContaining('桌面端不再需要'), findsNothing);
    expect(
      SplashTips.all.any(
        (String tip) =>
            tip.contains('长按') && tip.contains('拖动') && tip.contains('排序'),
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('宽屏首页最近浏览条目无论标题长短均占满整行宽度', (
    WidgetTester tester,
  ) async {
    final _ForumsWithData forums = _ForumsWithData();
    addTearDown(forums.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrapApp(
      Scaffold(
        body: TagPan(
          historyLoader: () => <ViewHistoryPageModel>[
            ViewHistoryPageModel(
              id: 1,
              tid: '101',
              title: '短',
              forumName: 'A',
              latestViewTime: DateTime(2026, 11, 20, 12),
            ),
            ViewHistoryPageModel(
              id: 2,
              tid: '102',
              title: '这是一条非常非常长用来撑满宽屏最近浏览卡片宽度的测试标题内容',
              forumName: '测试吧',
              latestViewTime: DateTime(2026, 11, 20, 12),
            ),
          ],
        ),
      ),
      forumState: forums,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    final Finder shortInkWell = find.ancestor(
      of: find.text('短'),
      matching: find.byType(InkWell),
    );
    final Finder longInkWell = find.ancestor(
      of: find.text('这是一条非常非常长用来撑满宽屏最近浏览卡片宽度的测试标题内容'),
      matching: find.byType(InkWell),
    );

    final Size shortSize = tester.getSize(shortInkWell.first);
    final Size longSize = tester.getSize(longInkWell.first);
    expect(shortSize.width, closeTo(longSize.width, 0.5));
    expect(shortSize.width, greaterThan(250));
    expect(tester.takeException(), isNull);
  });

  testWidgets('宽屏个人与设置页：左侧菜单高度与退出/切换位置固定，收藏与历史条目清晰无遮挡', (
    WidgetTester tester,
  ) async {
    final ThreadCache prevCache = Global.threadCache;
    final DAOAPI prevDao = Global.daoapi;
    Global.threadCache = ThreadCache();
    Global.daoapi = _FakeDao();
    addTearDown(() {
      Global.threadCache = prevCache;
      Global.daoapi = prevDao;
    });

    final FloatingSearchBarController search = FloatingSearchBarController();
    addTearDown(search.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrapApp(
      Scaffold(body: UserPage(controller: search)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final Offset switchPosTheme = tester.getTopLeft(find.text('切换账号'));
    final Offset logoutPosTheme = tester.getTopLeft(find.text('退出登录'));

    await tester.tap(find.text('阅读与通用'));
    await tester.pump();
    expect(tester.getTopLeft(find.text('切换账号')), switchPosTheme);
    expect(tester.getTopLeft(find.text('退出登录')), logoutPosTheme);

    await tester.tap(find.text('存储与诊断'));
    await tester.pump();
    expect(tester.getTopLeft(find.text('切换账号')), switchPosTheme);
    expect(tester.getTopLeft(find.text('退出登录')), logoutPosTheme);

    await tester.tap(find.text('我的收藏'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getTopLeft(find.text('切换账号')), switchPosTheme);
    expect(tester.getTopLeft(find.text('退出登录')), logoutPosTheme);

    final Finder unstoreBtn = find.byTooltip('取消收藏').first;
    final Rect unstoreBtnRect = tester.getRect(unstoreBtn);
    // 同行内的主体点击区域在右侧操作按钮左边，互不重叠
    final Finder storeRow = find.ancestor(
      of: unstoreBtn,
      matching: find.byType(Row),
    );
    final Finder storeContentInkWell = find.descendant(
      of: storeRow.first,
      matching: find.byType(InkWell),
    );
    final Rect storeContentRect = tester.getRect(storeContentInkWell.first);
    expect(unstoreBtnRect.left, greaterThanOrEqualTo(storeContentRect.right));

    await tester.tap(find.text('浏览历史'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getTopLeft(find.text('切换账号')), switchPosTheme);
    expect(tester.getTopLeft(find.text('退出登录')), logoutPosTheme);

    final Rect historyContentRect = tester.getRect(
      find.ancestor(
        of: find.text('这是一条测试浏览历史记录标题'),
        matching: find.byType(InkWell),
      ).first,
    );
    final Rect unhideBtnRect = tester.getRect(find.byTooltip('取消在首页隐藏').first);
    final Rect deleteBtnRect = tester.getRect(find.byTooltip('删除记录').first);
    expect(unhideBtnRect.left, greaterThanOrEqualTo(historyContentRect.right));
    expect(deleteBtnRect.left, greaterThanOrEqualTo(unhideBtnRect.right));
    expect(tester.takeException(), isNull);
  });
}
