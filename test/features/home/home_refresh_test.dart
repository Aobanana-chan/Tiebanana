// 首页数据刷新回归：
// - 从吧页面返回时重读浏览历史并刷新关注吧（签到 / 关注可能已变）；
// - 从贴子页返回时只重读浏览历史，不白白再请求关注列表；
// - 关闭对话框这类非页面路由不触发刷新。
//
// 背景：首页（TagPan）用 KeepAlive 常驻，去看贴子 / 吧页面再返回时不会重建，
// 之前只在 initState 与下拉刷新里读一次历史，导致新浏览记录与签到状态不更新。
import 'package:flutter/material.dart' hide SearchBar;
import 'package:tiebanana/features/history/models/view_history_page_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiebanana/app/navigation/app_route_observer.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/forum/state/forum_state.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/features/home/widgets/forum_tag.dart';

/// 只统计 refresh 次数，不发网络请求（ForumState 构造函数会调用 refresh）。
class _FakeForumState extends ForumState {
  static int refreshes = 0;

  final List<LikeForumInfo> _fakeForums = <LikeForumInfo>[
    LikeForumInfo(
      forumId: '1',
      avatar: '',
      forumName: '测试吧',
      isSign: '0',
      levelId: '1',
    ),
  ];

  @override
  List<LikeForumInfo> get forums => _fakeForums;

  @override
  Future<void> refresh() async {
    refreshes++;
  }
}

/// 统计取数次数并返回当次应显示的历史。
class _HistorySource {
  final List<List<ViewHistoryPageModel>> pages;
  int loads = 0;

  _HistorySource(this.pages);

  List<ViewHistoryPageModel> load() {
    final List<ViewHistoryPageModel> result =
        pages[loads.clamp(0, pages.length - 1)];
    loads++;
    return result;
  }
}

ViewHistoryPageModel _history(String title, int id) => ViewHistoryPageModel(
      id: id,
      tid: '$id',
      title: title,
      forumName: '测试吧',
      latestViewTime: DateTime.now(),
    );

Widget _app(ForumState forumState, TagPan tagPan) {
  return MultiProvider(
    providers: <ChangeNotifierProvider<APPSettingProvider>>[
      ChangeNotifierProvider<APPSettingProvider>(
          create: (BuildContext context) => APPSettingProvider()),
    ],
    child: ChangeNotifierProvider<ForumState>.value(
      value: forumState,
      child: MaterialApp(
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        navigatorObservers: <NavigatorObserver>[appRouteObserver],
        home: Scaffold(body: tagPan),
      ),
    ),
  );
}

/// 推一个带名字的页面路由并立刻返回，模拟「进 X 页面再回来」。
Future<void> _visitAndReturn(
    WidgetTester tester, BuildContext context, String pageName) async {
  Navigator.of(context).push<void>(MaterialPageRoute<void>(
    settings: RouteSettings(name: pageName),
    builder: (BuildContext context) => const Scaffold(body: Text('上层页面')),
  ));
  await tester.pumpAndSettle();
  expect(find.text('上层页面'), findsOneWidget);

  Navigator.of(context).pop();
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    _FakeForumState.refreshes = 0;
  });

  testWidgets('最近浏览默认显示 15 条，修改设置后立即更新上限', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    final forumState = _FakeForumState();
    addTearDown(forumState.dispose);
    final source = _HistorySource(<List<ViewHistoryPageModel>>[
      List.generate(25, (i) => _history('记录 $i', i + 1)),
    ]);
    await tester
        .pumpWidget(_app(forumState, TagPan(historyLoader: source.load)));
    await tester.pumpAndSettle();

    int count() => tester
        .widget<SliverList>(find.byType(SliverList))
        .delegate
        .estimatedChildCount!;
    expect(count(), 15);
    final context = tester.element(find.byType(TagPan));
    context.read<APPSettingProvider>().homeHistoryMaxCount = 20;
    await tester.pumpAndSettle();
    expect(count(), 20);
    context.read<APPSettingProvider>().homeHistoryMaxCount = 5;
    await tester.pumpAndSettle();
    expect(count(), 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('没有关注吧也显示最近浏览，记录不足时按实际数量显示', (tester) async {
    final forumState = _FakeForumState()..forums.clear();
    addTearDown(forumState.dispose);
    await tester.pumpWidget(_app(
        forumState,
        TagPan(
          historyLoader: () => <ViewHistoryPageModel>[_history('历史记录', 1)],
        )));
    await tester.pumpAndSettle();
    expect(find.text('还没有关注的吧'), findsOneWidget);
    expect(find.text('最近浏览'), findsOneWidget);
    expect(find.text('历史记录'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('从吧页面返回：重读浏览历史并刷新关注吧', (WidgetTester tester) async {
    final _FakeForumState forumState = _FakeForumState();
    final _HistorySource source = _HistorySource(<List<ViewHistoryPageModel>>[
      <ViewHistoryPageModel>[_history('旧记录', 1)],
      <ViewHistoryPageModel>[_history('新记录', 2), _history('旧记录', 1)],
    ]);

    await tester
        .pumpWidget(_app(forumState, TagPan(historyLoader: source.load)));
    await tester.pumpAndSettle();

    expect(source.loads, 1);
    expect(find.text('旧记录'), findsOneWidget);
    expect(find.text('新记录'), findsNothing);
    _FakeForumState.refreshes = 0;

    await _visitAndReturn(
        tester, tester.element(find.byType(TagPan)), PageRouter.forumHome);

    expect(source.loads, 2);
    expect(_FakeForumState.refreshes, 1);
    expect(find.text('新记录'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('从贴子页返回：重读浏览历史，不重复拉关注吧', (WidgetTester tester) async {
    final _FakeForumState forumState = _FakeForumState();
    final _HistorySource source = _HistorySource(<List<ViewHistoryPageModel>>[
      <ViewHistoryPageModel>[_history('旧记录', 1)],
      <ViewHistoryPageModel>[_history('新记录', 2)],
    ]);

    await tester
        .pumpWidget(_app(forumState, TagPan(historyLoader: source.load)));
    await tester.pumpAndSettle();
    _FakeForumState.refreshes = 0;

    await _visitAndReturn(
        tester, tester.element(find.byType(TagPan)), PageRouter.threadPage);

    expect(source.loads, 2);
    expect(_FakeForumState.refreshes, 0);
    expect(find.text('新记录'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('关闭对话框：不触发首页刷新', (WidgetTester tester) async {
    final _FakeForumState forumState = _FakeForumState();
    final _HistorySource source = _HistorySource(<List<ViewHistoryPageModel>>[
      <ViewHistoryPageModel>[_history('记录', 1)],
    ]);

    await tester
        .pumpWidget(_app(forumState, TagPan(historyLoader: source.load)));
    await tester.pumpAndSettle();
    _FakeForumState.refreshes = 0;

    final BuildContext context = tester.element(find.byType(TagPan));
    showDialog<void>(
      context: context,
      builder: (BuildContext context) =>
          const AlertDialog(title: Text('确认清空首页的浏览历史？')),
    );
    await tester.pumpAndSettle();
    expect(find.text('确认清空首页的浏览历史？'), findsOneWidget);

    Navigator.of(context).pop();
    await tester.pumpAndSettle();

    expect(source.loads, 1);
    expect(_FakeForumState.refreshes, 0);
    expect(tester.takeException(), isNull);
  });
}
