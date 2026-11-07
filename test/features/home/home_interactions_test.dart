// 首页新增交互的回归测试：缩略吧标签 / 展开按钮 / 左滑操作行 / 搜索历史下拉。
import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/floating_search_app_bar.dart';
import 'package:tiebanana/shared/widgets/swipe_action_row.dart';
import 'package:tiebanana/features/home/widgets/forum_tag.dart';
import 'package:tiebanana/features/search/widgets/search_bar.dart';

/// 搜索栏里的确认弹窗（TiebaAlterDialog）需要 APPSettingProvider + Global.setting。
Widget _searchApp(Widget child,
    {List<NavigatorObserver>? observers,
    Map<String, WidgetBuilder>? routes,
    Widget? bottomNavigationBar}) {
  return MultiProvider(
    providers: <ChangeNotifierProvider<APPSettingProvider>>[
      ChangeNotifierProvider<APPSettingProvider>(
          create: (BuildContext context) => APPSettingProvider()),
    ],
    child: MaterialApp(
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      navigatorObservers: observers ?? <NavigatorObserver>[],
      routes: routes ?? <String, WidgetBuilder>{},
      home: Scaffold(body: child, bottomNavigationBar: bottomNavigationBar),
    ),
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: TiebananaTheme.light(seedOf('blue'), 16),
    home: Scaffold(body: child),
  );
}

LikeForumInfo _forum(String name, String level, bool signed) => LikeForumInfo(
      forumId: name,
      avatar: '',
      forumName: name,
      isSign: signed ? '1' : '0',
      levelId: level,
    );

class _RecordingObserver extends NavigatorObserver {
  final List<String?> pushed = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}

void main() {
  setUp(() {
    // 确认弹窗（TiebaAlterDialog）会读 Global.setting.fontSize
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
  });

  testWidgets('缩略吧标签与展开按钮：文案正确且不溢出', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(Column(
      children: <Widget>[
        SizedBox(
          width: 110,
          height: 38,
          child: ForumTag(info: _forum('机械键盘', '4', true), compact: true),
        ),
        HomeExpandButton(expanded: false, total: 26, onTap: () {}),
      ],
    )));
    expect(find.text('机械键盘'), findsOneWidget);
    expect(find.text('展开全部 26 个'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
        _wrap(const HomeExpandButton(expanded: true, total: 26, onTap: _noop)));
    expect(find.text('收起'), findsOneWidget);
  });

  testWidgets('左滑操作行：左滑露出按钮并可触发', (WidgetTester tester) async {
    int hidden = 0;
    await tester.pumpWidget(_wrap(
      Center(
        child: SizedBox(
          width: 390,
          child: SwipeActionRow(
            actions: <SwipeAction>[
              SwipeAction(
                label: '隐藏',
                icon: Icons.visibility_off_outlined,
                background: Colors.grey,
                foreground: Colors.white,
                onTap: () => hidden++,
              ),
            ],
            child: Container(
              height: 64,
              color: Colors.white,
              alignment: Alignment.center,
              child: const Text('记录'),
            ),
          ),
        ),
      ),
    ));

    await tester.drag(find.text('记录'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('隐藏'));
    await tester.pumpAndSettle();
    expect(hidden, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('搜索历史：有记录可填入，命中后点击直接搜索', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    await Global.profile
        .setStringList(searchHistoryKey, <String>['flutter', '贴吧']);

    final FloatingSearchBarController controller =
        FloatingSearchBarController();
    addTearDown(controller.dispose);
    final _RecordingObserver observer = _RecordingObserver();

    await tester.pumpWidget(_searchApp(
      SearchBar(barController: controller),
      observers: <NavigatorObserver>[observer],
      routes: <String, WidgetBuilder>{
        PageRouter.search: (BuildContext context) =>
            const Scaffold(body: Text('搜索页')),
      },
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text('搜索历史'), findsOneWidget);
    Finder rowText(String text) => find.descendant(
        of: find.byType(AnimatedDropDown), matching: find.text(text));
    expect(rowText('flutter'), findsOneWidget);

    // 第一次点：只填入搜索框。
    await tester.tap(rowText('flutter'));
    await tester.pumpAndSettle();
    expect(controller.query, 'flutter');
    expect(observer.pushed.contains(PageRouter.search), isFalse);

    // 内容相同后再点：直接搜索（跳搜索页）。
    await tester.tap(rowText('flutter'));
    await tester.pumpAndSettle();
    expect(observer.pushed, contains(PageRouter.search));
  });

  testWidgets('搜索历史：空记录不展开浮窗', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    await Global.profile.setStringList(searchHistoryKey, <String>[]);

    final FloatingSearchBarController controller =
        FloatingSearchBarController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_searchApp(SearchBar(barController: controller)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text('搜索历史'), findsNothing);
  });

  for (final bool tapNavigation in <bool>[false, true]) {
    testWidgets('搜索历史：点击${tapNavigation ? '底部导航' : '页面按钮'}只收起，动画结束后才允许点击',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        searchHistoryKey: <String>['flutter'],
      });
      Global.profile = await SharedPreferences.getInstance();
      final FloatingSearchBarController controller =
          FloatingSearchBarController();
      addTearDown(controller.dispose);
      int pageTaps = 0;
      int navigationTaps = 0;

      await tester.pumpWidget(_searchApp(
        Column(
          children: <Widget>[
            SearchBar(barController: controller),
            Expanded(
              child: Center(
                child: TextButton(
                  onPressed: () => pageTaps++,
                  child: const Text('页面按钮'),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (_) => navigationTaps++,
          destinations: const <NavigationDestination>[
            NavigationDestination(icon: Icon(Icons.home), label: '首页'),
            NavigationDestination(icon: Icon(Icons.person), label: '个人'),
          ],
        ),
      ));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text('搜索历史'), findsOneWidget);

      final Finder target = find.text(tapNavigation ? '个人' : '页面按钮');
      await tester.tap(target);
      await tester.pump();
      expect(controller.isOpen, isFalse);
      expect(pageTaps, 0);
      expect(navigationTaps, 0);
      // 收起动画尚未结束，重复点击也不能穿透。
      expect(find.byType(AnimatedDropDown), findsOneWidget);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(pageTaps, 0);
      expect(navigationTaps, 0);
      expect(find.byType(AnimatedDropDown), findsNothing);

      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(pageTaps, tapNavigation ? 0 : 1);
      expect(navigationTaps, tapNavigation ? 1 : 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('搜索历史：浮窗侧边留白属于外部区域，点击后收起', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      searchHistoryKey: <String>['flutter'],
    });
    Global.profile = await SharedPreferences.getInstance();
    final FloatingSearchBarController controller =
        FloatingSearchBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_searchApp(SearchBar(barController: controller)));
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final Rect drop = tester.getRect(find.byType(AnimatedDropDown));
    await tester.tapAt(Offset(drop.left + 2, drop.center.dy));
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
    expect(find.byType(AnimatedDropDown), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final String input in <String>['', '   ', '  flutter  ']) {
    testWidgets('搜索按钮：当前输入「$input」可进入搜索页', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      Global.profile = await SharedPreferences.getInstance();
      final FloatingSearchBarController controller =
          FloatingSearchBarController();
      addTearDown(controller.dispose);
      String? keyword;

      await tester.pumpWidget(_searchApp(
        SearchBar(barController: controller),
        routes: <String, WidgetBuilder>{
          PageRouter.search: (BuildContext context) {
            keyword = ModalRoute.of(context)!.settings.arguments as String;
            return const Scaffold(body: Text('搜索页'));
          },
        },
      ));
      await tester.enterText(find.byType(TextField), input);
      await tester.tap(find.text('搜索'));
      await tester.pumpAndSettle();

      expect(find.text('搜索页'), findsOneWidget);
      expect(keyword, input.trim());
      expect(Global.profile.getStringList(searchHistoryKey) ?? <String>[],
          input.trim().isEmpty ? <String>[] : <String>[input.trim()]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('搜索按钮：选择历史后使用填入的词而不是旧输入', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      searchHistoryKey: <String>['flutter', '贴吧'],
    });
    Global.profile = await SharedPreferences.getInstance();
    final FloatingSearchBarController controller =
        FloatingSearchBarController();
    addTearDown(controller.dispose);
    String? keyword;

    await tester.pumpWidget(_searchApp(
      SearchBar(barController: controller),
      routes: <String, WidgetBuilder>{
        PageRouter.search: (BuildContext context) {
          keyword = ModalRoute.of(context)!.settings.arguments as String;
          return const Scaffold(body: Text('搜索页'));
        },
      },
    ));
    await tester.enterText(find.byType(TextField), '旧输入');
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(AnimatedDropDown), matching: find.text('贴吧')));
    await tester.pumpAndSettle();
    expect(controller.query, '贴吧');
    expect(find.text('搜索页'), findsNothing);

    await tester.tap(find.text('搜索'));
    await tester.pumpAndSettle();
    expect(keyword, '贴吧');
    expect(Global.profile.getStringList(searchHistoryKey),
        <String>['贴吧', 'flutter']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('搜索历史：清空需二次确认，确认后清空并收起浮窗', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    await Global.profile.setStringList(searchHistoryKey, <String>['flutter']);

    final FloatingSearchBarController controller =
        FloatingSearchBarController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_searchApp(SearchBar(barController: controller)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text('搜索历史'), findsOneWidget);

    // 点「清空」先弹确认框，取消则什么都不做。
    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();
    expect(find.text('确认清空搜索历史？'), findsOneWidget);
    await tester.tap(find.text('否'));
    await tester.pumpAndSettle();
    expect(Global.profile.getStringList(searchHistoryKey), isNotEmpty);

    // 再点「清空」并确认：记录清空、浮窗收起。
    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('是'));
    await tester.pumpAndSettle();
    expect(find.text('搜索历史'), findsNothing);
    expect(Global.profile.getStringList(searchHistoryKey), isEmpty);
  });

  testWidgets('搜索栏：单击任意位置即可聚焦，浮窗不与搜索栏重叠', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    await Global.profile.setStringList(searchHistoryKey, <String>['flutter']);

    final FloatingSearchBarController controller =
        FloatingSearchBarController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_searchApp(SearchBar(barController: controller)));
    await tester.pumpAndSettle();

    // 点左侧搜索图标（不在 TextField 上）也应该一次就聚焦、能直接输入。
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    expect(controller.focusNode.hasFocus, isTrue);
    // 输入法连接已建立（真机上即键盘弹出），说明可以立刻输入。
    expect(tester.testTextInput.hasAnyClients, isTrue);
    await tester.enterText(find.byType(TextField), 'abc');
    expect(controller.query, 'abc');

    await tester.pumpAndSettle();
    expect(find.text('搜索历史'), findsOneWidget);

    final Rect field = tester.getRect(find.byType(TextField));
    final Rect drop = tester.getRect(find.byType(AnimatedDropDown));
    expect(drop.top, greaterThanOrEqualTo(field.bottom - 0.5));
  });

  testWidgets('搜索栏下沿只留 gapSm：别又跟内容空出一大截', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();

    final FloatingSearchBarController controller =
        FloatingSearchBarController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_searchApp(SearchBar(barController: controller)));
    await tester.pump();

    // 整块 = 48（胶囊）+ 2（上留白）+ gapSm（下留白，就是紧挨内容的那一档）。
    expect(tester.getSize(find.byType(FloatingSearchAppBar)).height,
        48 + 2 + TiebananaMetrics.gapSm);
  });

  testWidgets('搜索历史：记录很多时浮窗有最大高度且可滚动', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    await Global.profile.setStringList(
        searchHistoryKey, List<String>.generate(30, (int i) => '关键词 $i'));

    final FloatingSearchBarController controller =
        FloatingSearchBarController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_searchApp(SearchBar(barController: controller)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final Size size = tester.getSize(find.byType(AnimatedDropDown));
    expect(size.height, lessThanOrEqualTo(searchHistoryDropMaxHeight + 0.5));
    expect(
      find.descendant(
          of: find.byType(AnimatedDropDown),
          matching: find.byType(SingleChildScrollView)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
