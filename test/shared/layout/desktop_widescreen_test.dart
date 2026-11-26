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
import 'package:tiebanana/features/history/models/view_history_page_model.dart';
import 'package:tiebanana/features/message/pages/message_page.dart';
import 'package:tiebanana/features/message/pages/private_message_panel.dart';
import 'package:tiebanana/features/message/state/message_reminder.dart';
import 'package:tiebanana/features/message/state/notification_reminder.dart';
import 'package:tiebanana/features/profile/pages/my_profile_page.dart';
import 'package:tiebanana/features/profile/widgets/user_card.dart';
import 'package:tiebanana/features/search/pages/search_page.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/thread/pages/thread_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';
import 'package:tiebanana/shared/widgets/floating_search_app_bar.dart';

class _TestMessageApi extends DemoTiebaApi {
  _TestMessageApi() : super(latency: Duration.zero);

  @override
  Future<TiebaNotificationOverview> getNotificationOverview() async =>
      TiebaNotificationOverview(
        mutualHelp: TiebaMutualHelpNotice(
          visible: true,
          unread: 2,
          latestTime: DateTime(2026, 11, 20, 19, 40),
        ),
        broadcast: TiebaBroadcastNotice(
          unread: true,
          title: '吧广播',
          summary: '11 月公告更新',
          latestTime: DateTime(2026, 11, 20, 18, 15),
        ),
      );
}

Widget _wrapApp(
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
      ChangeNotifierProvider<User>(
        create: (_) => User(),
      ),
      ChangeNotifierProvider<ForumState>(
        create: (_) => ForumState(),
      ),
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

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'uid': '10001',
      'userName': '烤面包边',
    });
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    Global.tiebaAPI = _TestMessageApi();
    MessageReminder.reset();
  });

  testWidgets('桌面端四档宽度（640 / 820 / 1080 / 1280）与双主题字号切换无溢出', (
    WidgetTester tester,
  ) async {
    const List<double> widths = <double>[640, 820, 1080, 1280];
    const List<({String seed, bool dark, double font})> themes =
        <({String seed, bool dark, double font})>[
      (seed: 'blue', dark: false, font: 12),
      (seed: 'blue', dark: true, font: 20),
      (seed: 'white', dark: false, font: 16),
      (seed: 'white', dark: true, font: 20),
    ];

    Widget responsiveShell() {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final Widget body = TagPan(
            historyLoader: () => <ViewHistoryPageModel>[],
          );
          if (width < 720) {
            return Scaffold(
              bottomNavigationBar: NavigationBar(
                selectedIndex: 0,
                destinations: const <NavigationDestination>[
                  NavigationDestination(icon: Icon(Icons.home), label: '首页'),
                  NavigationDestination(icon: Icon(Icons.explore), label: '动态'),
                  NavigationDestination(
                      icon: Icon(Icons.notifications), label: '消息'),
                  NavigationDestination(icon: Icon(Icons.person), label: '个人'),
                ],
              ),
              body: body,
            );
          }
          return DesktopShellFrame(
            title: '首页',
            subtitle: '轻一点，逛贴吧',
            activeTab: 0,
            onSelectTab: (_) {},
            child: body,
          );
        },
      );
    }

    for (final double w in widths) {
      await tester.binding.setSurfaceSize(Size(w, 800));
      await tester.pumpWidget(_wrapApp(responsiveShell()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      if (w < 720) {
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(DesktopShellFrame), findsNothing);
      } else {
        expect(find.byType(DesktopShellFrame), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      }
    }

    for (final t in themes) {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(_wrapApp(
        responsiveShell(),
        seedKey: t.seed,
        dark: t.dark,
        fontSize: t.font,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.byType(DesktopShellFrame), findsOneWidget);
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('消息中心桌面端：私信全高分栏无通知横幅，切到回复页签显示完整通知区', (
    WidgetTester tester,
  ) async {
    await NotificationReminder.instance.refresh(syncMask: false);
    final FloatingSearchBarController search = FloatingSearchBarController();
    addTearDown(search.dispose);
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrapApp(
      Scaffold(
        body: MessagePan(
          controller: search,
          loaders: <TiebaMessageKind, MessageLoader>{
            TiebaMessageKind.reply: (_) async => const MessagePageResult(
                  items: <TiebaMessage>[],
                  hasMore: false,
                ),
          },
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byType(PrivateMessagePanel), findsOneWidget);
    expect(find.text('选择一个对话'), findsOneWidget);
    // 私信页签顶栏内联胶囊可见，但不渲染完整的「通知」分组头横幅。
    expect(find.text('吧友互助'), findsOneWidget);
    expect(find.text('通知'), findsNothing);

    await tester.tap(find.text('回复'));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('通知'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('个人与设置桌面端：顶置通栏 UserCard + 等高菜单与 7 列主题色板', (
    WidgetTester tester,
  ) async {
    final FloatingSearchBarController search = FloatingSearchBarController();
    addTearDown(search.dispose);
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrapApp(
      Scaffold(body: UserPage(controller: search)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byType(UserCard), findsOneWidget);
    expect(find.text('我的空间'), findsOneWidget);
    expect(find.text('外观与主题'), findsWidgets);
    expect(find.text('实时预览'), findsOneWidget);
    for (final String label in <String>[
      '宝石蓝',
      '石青金',
      '玛瑙绿',
      '早苗绿',
      '咸蛋黄',
      '胭脂粉',
      '简洁白',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('阅读与通用'));
    await tester.pump();
    expect(find.text('图片浏览模式'), findsOneWidget);
    expect(find.text('长期缓存收藏贴'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('全站搜索桌面端：相关的吧分组面板与仅「贴」页签显示排序', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrapApp(
      SearchPage(
        searchWords: 'flutter',
        mixedLoader: (String keyword, int pn) async => SearchMixedPage(
          cards: <SearchMixedCard>[
            SearchMixedCard.forum(TiebaSearchForum(
              name: keyword,
              img: 'tb.1.forum',
              brief: '跨平台 UI 框架',
              member: 1000,
              post: 5000,
              isLike: true,
            )),
            SearchMixedCard.thread(TiebaSearchPost(
              type: 1,
              tid: '3001',
              userAvatar: 'tb.1.avatar',
              username: '作者',
              title: '综合帖子',
              forumName: keyword,
              time: '0',
              content: '摘要',
            )),
          ],
          hasMore: false,
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('相关的吧'), findsOneWidget);
    expect(find.text('只看主题帖'), findsNothing);

    await tester.tap(find.text('贴'));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('只看主题帖'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('帖子详情桌面端：右侧 288dp 所属吧/互动/阅读控制/停靠回复框', (
    WidgetTester tester,
  ) async {
    final TiebaThreadPage page =
        await Global.tiebaAPI.getThreadPage('8301124590');
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrapApp(
      ThreadPageMain(
        kz: '8301124590',
        pid: null,
        pn: page.page.currentPage,
        page: page,
        initPost: page.posts,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('所属吧'), findsOneWidget);
    expect(find.text('进入吧主页'), findsOneWidget);
    expect(find.text('阅读控制'), findsOneWidget);
    expect(find.text('回复帖子'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
