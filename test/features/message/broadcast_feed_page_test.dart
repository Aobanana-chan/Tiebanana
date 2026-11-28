// 吧广播聚合流：按日期分组、跨吧卡片、互动数只读与宽屏交互。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/features/forum/state/forum_state.dart';
import 'package:tiebanana/features/message/pages/broadcast_feed_page.dart';
import 'package:tiebanana/features/message/widgets/broadcast_feed_card.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';

Widget _app(Widget child) {
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
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: child,
      routes: <String, WidgetBuilder>{
        PageRouter.threadPage: (_) => const Scaffold(body: Text('帖子详情')),
        PageRouter.forumHome: (_) => const Scaffold(body: Text('吧主页')),
      },
    ),
  );
}

class _LongPureNoticeApi extends DemoTiebaApi {
  _LongPureNoticeApi() : super(latency: Duration.zero);

  @override
  Future<List<TiebaBroadcastItem>> getBroadcastFeed({int limit = 80}) async {
    final List<TiebaBroadcastItem> base =
        await super.getBroadcastFeed(limit: limit);
    return <TiebaBroadcastItem>[
      ...base,
      TiebaBroadcastItem(
        id: '910000000000000099',
        title: '纯公告长正文测试',
        content:
            '这是一条没有关联帖子的长文本广播公告，用来验证桌面宽屏模式下纯公告卡片不再点击无响应，而是支持原地平滑展开完整正文并可再次收起。'
            '请各位吧友注意查收最新吧务通知与活动时间安排，如有疑问请在吧内反馈集中贴留言。',
        publishTime: DateTime.now().subtract(const Duration(hours: 3)),
        forumId: '101',
        forumName: '孙笑川',
      ),
    ];
  }
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
  });

  testWidgets('跨吧卡片按日期分组，点击进入关联帖子', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const BroadcastFeedPage()));
    await tester.pump();
    await tester.pump();

    expect(find.text('吧广播'), findsOneWidget);
    expect(find.byType(BroadcastFeedCard), findsAtLeastNWidgets(5));
    expect(find.text('今天的晚霞好像被打翻了'), findsOneWidget);
    expect(find.text('孙笑川吧'), findsWidgets);
    expect(find.text('分享'), findsOneWidget);
    expect(find.text('153'), findsOneWidget);
    expect(find.text('247'), findsOneWidget);

    await tester.tap(find.text('今天的晚霞好像被打翻了'));
    await tester.pumpAndSettle();
    expect(find.text('帖子详情'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('未登录显示登录态，不装成空列表', (WidgetTester tester) async {
    Global.tiebaAPI = DemoTiebaApi(loggedIn: false, latency: Duration.zero);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const BroadcastFeedPage()));
    await tester.pump();
    await tester.pump();

    expect(find.text('登录后才能看吧广播'), findsOneWidget);
    expect(find.byType(BroadcastFeedCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('宽屏 1280px 渲染桌面壳层、来源吧筛选与纯公告展开', (WidgetTester tester) async {
    Global.tiebaAPI = _LongPureNoticeApi();
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const BroadcastFeedPage()));
    await tester.pump();
    await tester.pump();

    expect(find.byType(DesktopShellFrame), findsOneWidget);
    expect(find.text('来源吧'), findsOneWidget);
    expect(find.text('按日定位'), findsOneWidget);
    expect(find.text('关于吧广播'), findsOneWidget);
    expect(find.text('全部广播'), findsOneWidget);
    expect(find.text('关联贴'), findsWidgets);
    expect(find.text('纯公告'), findsWidgets);

    // 原地展开纯公告长正文（滚动至可见后点击）
    await tester.ensureVisible(find.text('纯公告长正文测试'));
    await tester.pumpAndSettle();
    expect(find.text('纯公告长正文测试'), findsOneWidget);
    expect(find.text('展开全文'), findsOneWidget);
    await tester.tap(find.text('纯公告长正文测试'));
    await tester.pumpAndSettle();
    expect(find.text('收起'), findsOneWidget);

    // 按来源吧筛选，然后按 Esc 复位
    final Finder filterItem = find.descendant(
      of: find.byType(DesktopShellFrame),
      matching: find.text('孙笑川吧'),
    );
    await tester.tap(filterItem.last);
    await tester.pumpAndSettle();
    expect(find.text('显示全部'), findsOneWidget);
    expect(find.text('整理了一份新手向的入坑顺序'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('显示全部'), findsNothing);
    expect(find.text('整理了一份新手向的入坑顺序'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('宽屏 820px 半屏与 1080px 切换无溢出', (WidgetTester tester) async {
    for (final Size size in const <Size>[Size(820, 760), Size(1080, 760)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_app(const BroadcastFeedPage()));
      await tester.pump();
      await tester.pump();

      expect(find.byType(DesktopShellFrame), findsOneWidget);
      expect(find.byType(BroadcastFeedCard), findsAtLeastNWidgets(3));
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
