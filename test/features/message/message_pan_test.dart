// 消息页数据行为回归：三个页签各自惰性加载 / 分页 / 状态，互不干扰。
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/message/pages/message_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/floating_search_app_bar.dart';
import 'package:tiebanana/features/message/widgets/message_card.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/message/state/message_reminder.dart';

TiebaMessage _reply(String text, {bool unread = false}) => TiebaMessage(
      kind: TiebaMessageKind.reply,
      unread: unread,
      likedThread: false,
      time: DateTime.now().subtract(const Duration(minutes: 20)),
      content: text,
      quoteContent: '',
      fname: 'Flutter',
      title: 'Flutter 3.47 升级踩坑记录',
      threadId: '123456',
      postId: '654321',
      portrait: 'tb.1.avatar',
      uid: '7',
      nameShow: '青葉ナナ',
      username: '青葉ナナ',
    );

TiebaMessage _like(String text, {required bool onThread}) => TiebaMessage(
      kind: TiebaMessageKind.like,
      unread: false,
      likedThread: onThread,
      time: DateTime.now().subtract(const Duration(minutes: 30)),
      content: text,
      quoteContent: onThread ? '' : text,
      fname: onThread ? 'Flutter' : '前端',
      title: onThread ? text : '按钮圆角到底该用 8 还是 12？',
      threadId: '123456',
      postId: onThread ? '0' : '654321',
      portrait: 'tb.2.avatar',
      uid: '8',
      nameShow: '路人甲',
      username: '路人甲',
    );

Widget _app(Widget child) {
  return ChangeNotifierProvider<APPSettingProvider>(
    create: (BuildContext context) => APPSettingProvider(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: Scaffold(body: child),
      routes: <String, WidgetBuilder>{
        PageRouter.threadPage: (_) => const Scaffold(body: Text('帖子详情')),
      },
    ),
  );
}

/// 切页签：TabBarView 的翻页动画是 300ms，多推几帧等它走完，
/// 否则目标页还在视口外面（`find` 默认跳过视口外的子树）。
Future<void> _switchTo(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  for (int i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    MessageReminder.reset();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
  });

  testWidgets('三个页签惰性加载：进页面只请求「回复」，切过去才请求对应页签', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();

    final List<TiebaMessageKind> called = <TiebaMessageKind>[];
    final FloatingSearchBarController search = FloatingSearchBarController();
    addTearDown(search.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(MessagePan(
      controller: search,
      loaders: <TiebaMessageKind, MessageLoader>{
        TiebaMessageKind.reply: (int pn) async {
          called.add(TiebaMessageKind.reply);
          return MessagePageResult(
              items: <TiebaMessage>[_reply('感谢整理，第 3 步的顺序很关键', unread: true)],
              unread: 3,
              hasMore: false);
        },
        TiebaMessageKind.at: (int pn) async {
          called.add(TiebaMessageKind.at);
          return const MessagePageResult(
              items: <TiebaMessage>[], hasMore: false);
        },
        TiebaMessageKind.like: (int pn) async {
          called.add(TiebaMessageKind.like);
          return const MessagePageResult(
              items: <TiebaMessage>[], hasMore: false);
        },
      },
    )));
    await tester.pump();
    await tester.pump();

    expect(called, <TiebaMessageKind>[TiebaMessageKind.reply],
        reason: '另外两个页签不该在进消息页时一起打出去');
    expect(find.text('感谢整理，第 3 步的顺序很关键'), findsOneWidget);
    expect(find.text('未读 3'), findsNothing, reason: '列表计数不冒充分类提醒数');

    // 切到「给我点赞」：只请求点赞，且这个页签是空的
    await _switchTo(tester, '给我点赞');
    expect(called,
        <TiebaMessageKind>[TiebaMessageKind.reply, TiebaMessageKind.like]);
    expect(find.text('还没有人给你点赞'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('翻页追加：滚到底拉下一页，到底后不再请求', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();

    int calls = 0;
    final FloatingSearchBarController search = FloatingSearchBarController();
    addTearDown(search.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(MessagePan(
      controller: search,
      loaders: <TiebaMessageKind, MessageLoader>{
        TiebaMessageKind.reply: (int pn) async {
          calls++;
          // 第二页给一条；第三页开始为空，用来验「到底了就不再拉」
          if (pn > 2) {
            return const MessagePageResult(
                items: <TiebaMessage>[], hasMore: false);
          }
          return MessagePageResult(
            items:
                List<TiebaMessage>.generate(8, (int i) => _reply('第$pn页第$i条')),
            hasMore: true,
          );
        },
      },
    )));
    await tester.pump();
    await tester.pump();

    expect(calls, 1);
    expect(find.text('第1页第0条'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -1600));
    for (int i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(calls, 2);
    expect(find.text('第2页第0条'), findsOneWidget);

    // 翻页节流是 2s 冷却计时器，跑完它再结束。
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('点赞接口报错时走错误态，不装成空列表', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();

    final FloatingSearchBarController search = FloatingSearchBarController();
    addTearDown(search.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(MessagePan(
      controller: search,
      loaders: <TiebaMessageKind, MessageLoader>{
        TiebaMessageKind.reply: (int pn) async =>
            const MessagePageResult(items: <TiebaMessage>[], hasMore: false),
        TiebaMessageKind.like: (int pn) async => throw Exception('获取失败'),
      },
    )));
    await tester.pump();
    await tester.pump();

    await _switchTo(tester, '给我点赞');

    expect(find.text('网络似乎有点问题'), findsOneWidget);
    expect(find.text('还没有人给你点赞'), findsNothing);
    expect(find.byType(MessageCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点赞卡片显示「赞了我的主题 / 回复」+ 被赞内容', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();

    final FloatingSearchBarController search = FloatingSearchBarController();
    addTearDown(search.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(MessagePan(
      controller: search,
      loaders: <TiebaMessageKind, MessageLoader>{
        TiebaMessageKind.reply: (int pn) async =>
            const MessagePageResult(items: <TiebaMessage>[], hasMore: false),
        TiebaMessageKind.like: (int pn) async => MessagePageResult(
              items: <TiebaMessage>[
                _like('Flutter 3.47 升级踩坑记录', onThread: true),
                _like('我们最后收敛成了三级：卡片 12、控件 8、标签 999。', onThread: false),
              ],
              hasMore: false,
            ),
      },
    )));
    await tester.pump();
    await tester.pump();

    await _switchTo(tester, '给我点赞');

    expect(find.text('赞了我的主题', findRichText: true), findsOneWidget);
    expect(find.text('赞了我的回复', findRichText: true), findsOneWidget);
    // 被赞内容过 ExtendedText（要渲染 @ / 表情等贴吧语法），find.text 看不到它，
    // 所以内容本身在模型层验，界面只验它被渲染出来了。
    expect(find.byType(ExtendedText), findsNWidgets(2));
    expect(find.text('来自 Flutter吧'), findsOneWidget);
    expect(find.text('来自 前端吧'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('点赞行：赞了主题取标题，赞了回复取回复原文', () {
    final TiebaMessage onThread = _like('Flutter 3.47 升级踩坑记录', onThread: true);
    expect(onThread.likedThread, isTrue, reason: 'type=1 是主题');
    expect(onThread.quoteLine, '赞了我的主题');
    expect(onThread.likedText, 'Flutter 3.47 升级踩坑记录');

    final TiebaMessage onFloor = _like('网络层先行能尽早暴露字段缺失', onThread: false);
    expect(onFloor.likedThread, isFalse, reason: '有楼层 id / 引用原文就是赞了回复');
    expect(onFloor.quoteLine, '赞了我的回复');
    expect(onFloor.likedText, '网络层先行能尽早暴露字段缺失');
  });

  testWidgets('未读点固定在卡片最右侧，不随昵称长度变化', (tester) async {
    final TiebaMessage short = _reply('短昵称', unread: true);
    final TiebaMessage long = _like('长昵称', onThread: true)
      ..unread = true
      ..nameShow = '这是一个非常非常非常长的昵称用于验证截断';
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(Column(children: <Widget>[
      MessageCard(message: short),
      MessageCard(message: long),
    ])));
    final Finder dots =
        find.byKey(const ValueKey<String>('message-unread-dot'));
    expect(dots, findsNWidgets(2));
    expect(tester.getRect(dots.at(0)).right, tester.getRect(dots.at(1)).right);
    final Rect card = tester.getRect(find.byType(Material).at(1));
    expect(tester.getRect(dots.first).right, card.right - 13);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点开后立即消点，不持久化，刷新后服从接口未读状态', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{'uid': '7'});
    Global.profile = await SharedPreferences.getInstance();
    final FloatingSearchBarController search = FloatingSearchBarController();
    addTearDown(search.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Widget page() => _app(MessagePan(
          controller: search,
          loaders: <TiebaMessageKind, MessageLoader>{
            TiebaMessageKind.reply: (_) async => MessagePageResult(
                  items: <TiebaMessage>[
                    _reply('点我', unread: true)
                      ..time = DateTime.fromMillisecondsSinceEpoch(100000)
                  ],
                  unread: 1,
                  hasMore: false,
                ),
          },
        ));
    await tester.pumpWidget(page());
    await tester.pump();
    await tester.pump();
    final Finder dots =
        find.byKey(const ValueKey<String>('message-unread-dot'));
    expect(dots, findsOneWidget);
    expect(find.text('未读 1'), findsNothing);
    await tester.tap(find.byType(MessageCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    Navigator.of(tester.element(find.text('帖子详情'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(dots, findsNothing);
    expect(find.text('未读 1'), findsNothing);
    final Future<void> refresh = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await refresh;
    expect(dots, findsOneWidget);
    expect(Global.profile.getKeys().where((key) => key.contains('messageRead')),
        isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page());
    await tester.pump();
    await tester.pump();
    expect(dots, findsOneWidget);
    expect(find.text('未读 1'), findsNothing);
  });

  testWidgets('分类角标来自独立提醒，点赞离开分类清提醒，不把每条点赞当未读', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    MessageReminder.counts.value =
        const MessageUnreadCounts(reply: 2, at: 3, like: 5);
    final search = FloatingSearchBarController();
    addTearDown(search.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(MessagePan(controller: search, loaders: {
      TiebaMessageKind.reply: (_) async =>
          const MessagePageResult(items: [], hasMore: false),
      TiebaMessageKind.like: (_) async => MessagePageResult(
          items: [_like('赞主题', onThread: true)], hasMore: false),
    })));
    await tester.pump();
    await tester.pump();
    expect(MessageReminder.counts.value.reply, 0);
    expect(MessageReminder.counts.value.total, 8);
    await _switchTo(tester, '给我点赞');
    expect(find.text('未读 5'), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('message-unread-dot')), findsNothing);
    await _switchTo(tester, '回复');
    expect(MessageReminder.counts.value.like, 0);
    expect(MessageReminder.counts.value.at, 3);
  });
}
