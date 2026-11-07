// 全站搜索的行为：四个页签的请求参数、搜索历史、排序 / 范围、翻页、错误重试。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/search/pages/search_page.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/features/search/widgets/search_bar.dart' show searchHistoryKey;

/// 记录四类搜索的入参；返回固定的样例数据。
class _RecordingApi extends DemoTiebaApi {
  _RecordingApi() : super(latency: Duration.zero);

  int forumCalls = 0;
  int postCalls = 0;
  int userCalls = 0;
  int mixedCalls = 0;

  String? lastForumKeyword;
  String? lastPostKeyword;
  String? lastUserKeyword;
  String? lastMixedKeyword;
  String? lastFname;
  int? lastPn;
  int? lastOrder;
  int? lastFilter;

  @override
  Future<SearchForumResult> searchForum(String keywords, int pn,
      {int rn = 10}) async {
    forumCalls++;
    lastForumKeyword = keywords;
    lastPn = pn;
    return SearchForumResult(
      forums: <TiebaSearchForum>[
        TiebaSearchForum(
          name: 'Flutter',
          img: 'tb.1.forum',
          brief: '跨平台 UI 框架，一套代码跑六端',
          member: 1286000,
          post: 23412000,
          isLike: false,
        ),
        TiebaSearchForum(
          name: 'FlutterFlow',
          img: 'tb.1.forum2',
          brief: '可视化 Flutter 应用搭建工具',
          member: 24000,
          post: 61000,
          isLike: true,
        ),
      ],
    );
  }

  @override
  Future<SearchMixedPage> searchMixed(String keywords,
      {int pn = 1, int rn = 20}) async {
    mixedCalls++;
    lastMixedKeyword = keywords;
    return SearchMixedPage(
      cards: <SearchMixedCard>[
        SearchMixedCard.forum(TiebaSearchForum(
          name: keywords,
          img: 'tb.1.forum',
          brief: '综合搜索里的吧卡',
          member: 1286000,
          post: 23412000,
          isLike: true,
        )),
        SearchMixedCard.thread(TiebaSearchPost(
          type: 1,
          tid: '3001',
          userAvatar: 'tb.1.avatar',
          username: '青葉ナナ',
          title: '综合结果：$keywords 3.47 升级踩坑记录',
          forumName: keywords,
          time: '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
          content: '综合搜索里的贴卡。',
        )),
      ],
      hasMore: false,
    );
  }

  @override
  Future<SearchPostPage> searchPost(String keywords,
      {int pn = 1,
      int order = 0,
      int filter = 1,
      int ct = 2,
      String? fname}) async {
    postCalls++;
    lastPostKeyword = keywords;
    lastFname = fname;
    lastPn = pn;
    lastOrder = order;
    lastFilter = filter;
    return SearchPostPage(
      posts: <TiebaSearchPost>[
        TiebaSearchPost(
          type: 1,
          tid: '1001',
          userAvatar: 'tb.1.avatar',
          username: '青葉ナナ',
          title: '$keywords 3.47 升级踩坑记录',
          forumName: 'Flutter',
          time: '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
          content: '从 3.24 升到 3.47 花了两个晚上。',
        ),
        TiebaSearchPost(
          type: 2,
          tid: '1002',
          pid: '2002',
          userAvatar: 'tb.1.avatar2',
          username: '路人甲',
          title: '回复：按钮圆角到底该用 8 还是 12？',
          forumName: '设计',
          time: '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
          content: '$keywords 里卡片用 12、按钮用 8。',
        ),
      ],
      hasMore: false,
    );
  }

  @override
  Future<SearchUserResult> searchUser(String keyword) async {
    userCalls++;
    lastUserKeyword = keyword;
    return SearchUserResult(
      users: <TiebaUserMatch>[
        TiebaUserMatch(
          id: '2001',
          name: 'nana_ao',
          userNickname: '青葉ナナ',
          showNickname: '青葉ナナ',
          portrait: 'tb.1.user',
          intro: 'Flutter / 设计系统 / 偶尔做饭',
        ),
      ],
    );
  }
}

/// 第一页 20 条并声明有下一页，第二页 3 条收尾。
class _PagingApi extends _RecordingApi {
  @override
  Future<SearchPostPage> searchPost(String keywords,
      {int pn = 1,
      int order = 0,
      int filter = 1,
      int ct = 2,
      String? fname}) async {
    postCalls++;
    lastPostKeyword = keywords;
    lastPn = pn;
    final int count = pn == 1 ? 20 : 3;
    return SearchPostPage(
      posts: <TiebaSearchPost>[
        for (int i = 1; i <= count; i++)
          TiebaSearchPost(
            type: 1,
            tid: '$pn-$i',
            userAvatar: 'tb.1.demo',
            username: '演示用户',
            title: '第 $pn 页第 $i 条 $keywords',
            forumName: 'Flutter',
            time: '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
            content: '演示正文 $keywords',
          ),
      ],
      hasMore: pn == 1,
    );
  }
}

/// 吧搜索第一次抛错，重试时成功。
class _FlakyForumApi extends _RecordingApi {
  bool _failed = false;

  /// 失败那次没有走到 [super.searchForum]，所以用单独的计数记「发起过几次」。
  int forumAttempts = 0;

  @override
  Future<SearchForumResult> searchForum(String keywords, int pn,
      {int rn = 10}) {
    forumAttempts++;
    if (!_failed) {
      _failed = true;
      return Future<SearchForumResult>.error(Exception('boom'));
    }
    return super.searchForum(keywords, pn);
  }
}

Future<void> _setHistory(List<String> history) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    if (history.isNotEmpty) searchHistoryKey: history,
  });
  Global.profile = await SharedPreferences.getInstance();
}

Future<void> _pump(WidgetTester tester, SearchPage page,
    {RouteFactory? onGenerateRoute}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: TiebananaTheme.light(seedOf('blue'), 16),
    home: page,
    onGenerateRoute: onGenerateRoute,
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('初始关键词并行搜索综合 / 贴 / 吧 / 人，贴不带 fname', (WidgetTester tester) async {
    await _setHistory(const <String>[]);
    final _RecordingApi api = _RecordingApi();
    Global.tiebaAPI = api;

    await _pump(tester, const SearchPage(searchWords: 'flutter'));

    expect(api.forumCalls, 1);
    expect(api.postCalls, 1);
    expect(api.userCalls, 1);
    expect(api.mixedCalls, 1);
    expect(api.lastForumKeyword, 'flutter');
    expect(api.lastPostKeyword, 'flutter');
    expect(api.lastUserKeyword, 'flutter');
    expect(api.lastMixedKeyword, 'flutter');
    // 全站搜索不能带吧名。
    expect(api.lastFname, isNull);
    // 默认相关度 + 只看主题帖。
    expect(api.lastOrder, 2);
    expect(api.lastFilter, 1);
    expect(api.lastPn, 1);
    final TabBar bar = tester.widget<TabBar>(find.byType(TabBar));
    expect(bar.tabs.map((Widget tab) => (tab as Tab).text),
        <String>['综合', '贴', '吧', '人']);
    expect(bar.controller!.index, 0);
  });

  testWidgets('空关键词停在搜索历史，不发请求；点历史直接搜', (WidgetTester tester) async {
    await _setHistory(<String>['flutter', 'objectbox 构建失败']);
    final _RecordingApi api = _RecordingApi();
    Global.tiebaAPI = api;

    await _pump(tester, const SearchPage(searchWords: ''));

    expect(api.forumCalls, 0);
    expect(api.postCalls, 0);
    expect(api.userCalls, 0);
    expect(find.text('搜索历史'), findsOneWidget);

    await tester.tap(find.text('flutter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(api.forumCalls, 1);
    expect(api.postCalls, 1);
    expect(api.userCalls, 1);
    expect(find.text('flutter'), findsWidgets);
  });

  testWidgets('提交新关键词会写历史并重搜四个页签', (WidgetTester tester) async {
    await _setHistory(<String>['flutter', 'objectbox']);
    final _RecordingApi api = _RecordingApi();
    Global.tiebaAPI = api;

    await _pump(tester, const SearchPage(searchWords: 'flutter'));

    await tester.enterText(find.byType(TextField), 'riverpod');
    await tester.tap(find.text('搜索'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(api.forumCalls, 2);
    expect(api.postCalls, 2);
    expect(api.userCalls, 2);
    expect(api.mixedCalls, 2);
    expect(api.lastForumKeyword, 'riverpod');
    expect(api.lastMixedKeyword, 'riverpod');
    // 去重置顶，不出现重复项。
    expect(Global.profile.getStringList(searchHistoryKey),
        <String>['riverpod', 'flutter', 'objectbox']);
  });

  testWidgets('贴页签改范围 / 排序只重发贴请求', (WidgetTester tester) async {
    await _setHistory(const <String>[]);
    final _RecordingApi api = _RecordingApi();
    Global.tiebaAPI = api;

    await _pump(
        tester, const SearchPage(searchWords: 'flutter', initialTab: 1));
    expect(api.postCalls, 1);

    await tester.tap(find.text('只看主题帖'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(api.postCalls, 2);
    expect(api.lastFilter, 0);
    expect(api.lastOrder, 2);
    // 吧 / 用户结果不受影响，不跟着重发。
    expect(api.forumCalls, 1);
    expect(api.userCalls, 1);
    expect(api.mixedCalls, 1);

    await tester.tap(find.text('相关度'));
    // 头像的网络占位动画会一直挂起，这里不能用 pumpAndSettle。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('最新').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(api.postCalls, 3);
    expect(api.lastOrder, 1);
    expect(api.lastFilter, 0);
  });

  testWidgets('贴结果滚到底自动翻页', (WidgetTester tester) async {
    await _setHistory(const <String>[]);
    final _PagingApi api = _PagingApi();
    Global.tiebaAPI = api;

    await _pump(
        tester, const SearchPage(searchWords: 'flutter', initialTab: 1));
    expect(api.postCalls, 1);
    expect(find.text('第 1 页第 1 条 flutter'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(api.postCalls, 2);
    expect(api.lastPn, 2);

    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pump();
    expect(find.text('第 2 页第 3 条 flutter'), findsOneWidget);
  });

  testWidgets('吧查询失败显示错误态，重试成功后消失', (WidgetTester tester) async {
    await _setHistory(const <String>[]);
    final _FlakyForumApi api = _FlakyForumApi();
    Global.tiebaAPI = api;

    await _pump(
        tester, const SearchPage(searchWords: 'flutter', initialTab: 2));
    expect(find.text('搜索没成功'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(api.forumAttempts, 2);
    expect(api.forumCalls, 1);
    expect(find.text('搜索没成功'), findsNothing);
    expect(find.text('最匹配'), findsOneWidget);
  });

  testWidgets('清空输入回到搜索历史', (WidgetTester tester) async {
    await _setHistory(<String>['flutter']);
    final _RecordingApi api = _RecordingApi();
    Global.tiebaAPI = api;

    await _pump(tester, const SearchPage(searchWords: 'flutter'));
    expect(find.text('搜索历史'), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(find.text('搜索历史'), findsOneWidget);
    expect(api.forumCalls, 1);
    expect(api.postCalls, 1);
    expect(api.userCalls, 1);
    expect(api.mixedCalls, 1);
  });

  testWidgets('综合页签混排吧卡与贴卡', (WidgetTester tester) async {
    await _setHistory(const <String>[]);
    final _RecordingApi api = _RecordingApi();
    Global.tiebaAPI = api;

    await _pump(tester, const SearchPage(searchWords: 'flutter'));

    expect(api.mixedCalls, 1);
    expect(find.text('综合搜索里的吧卡'), findsOneWidget);
    expect(find.text('综合结果：flutter 3.47 升级踩坑记录'), findsOneWidget);
    expect(find.text('最匹配'), findsOneWidget);
  });

  testWidgets('综合翻页失败后重试同一页，成功后按服务端顺序追加', (WidgetTester tester) async {
    await _setHistory(const <String>[]);
    Global.tiebaAPI = _RecordingApi();
    final List<int> pages = <int>[];
    bool fail = true;
    await _pump(
        tester,
        SearchPage(
          searchWords: 'flutter',
          mixedLoader: (String keyword, int pn) async {
            pages.add(pn);
            if (pn == 2 && fail) throw Exception('retry');
            return SearchMixedPage(
              cards: <SearchMixedCard>[
                for (int i = 0; i < (pn == 1 ? 20 : 1); i++)
                  SearchMixedCard.thread(TiebaSearchPost(
                    content: '综合摘要',
                    forumName: 'Flutter',
                    tid: '$pn-$i',
                    time: '0',
                    title: '综合第 $pn 页第 $i 条',
                    type: 1,
                    userAvatar: '',
                    username: '作者',
                  )),
              ],
              hasMore: pn == 1,
            );
          },
        ));

    await tester.drag(find.byType(ListView), const Offset(0, -6000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(pages, <int>[1, 2]);
    expect(find.text('加载失败，点击重试'), findsOneWidget);
    fail = false;
    await tester.ensureVisible(find.text('加载失败，点击重试'));
    await tester.pump();
    await tester.tap(find.text('加载失败，点击重试'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(pages, <int>[1, 2, 2]);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pump();
    expect(find.text('综合第 2 页第 0 条'), findsOneWidget);
    expect(find.text('没有更多了'), findsOneWidget);
  });

  testWidgets('新关键词结果不被旧综合响应覆盖，清空后旧响应也不回填', (WidgetTester tester) async {
    await _setHistory(const <String>[]);
    Global.tiebaAPI = _RecordingApi();
    final Completer<SearchMixedPage> old = Completer<SearchMixedPage>();
    final Completer<SearchMixedPage> pending = Completer<SearchMixedPage>();
    SearchMixedPage result(String title) => SearchMixedPage(
          cards: <SearchMixedCard>[
            SearchMixedCard.thread(TiebaSearchPost(
              content: '摘要',
              forumName: 'Flutter',
              tid: title,
              time: '0',
              title: title,
              type: 1,
              userAvatar: '',
              username: '作者',
            )),
          ],
          hasMore: false,
        );
    await _pump(
        tester,
        SearchPage(
          searchWords: 'old',
          mixedLoader: (String keyword, int pn) async {
            if (keyword == 'old') return old.future;
            if (keyword == 'pending') return pending.future;
            return result('新的综合结果');
          },
        ));
    await tester.enterText(find.byType(TextField), 'new');
    await tester.tap(find.text('搜索'));
    await tester.pump();
    old.complete(result('过期结果'));
    await tester.pump();
    expect(find.text('新的综合结果'), findsOneWidget);
    expect(find.text('过期结果'), findsNothing);

    await tester.enterText(find.byType(TextField), 'pending');
    await tester.tap(find.text('搜索'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    pending.complete(result('清空后的过期结果'));
    await tester.pump();
    expect(find.text('搜索历史'), findsOneWidget);
    expect(find.text('清空后的过期结果'), findsNothing);
    await tester.enterText(find.byType(TextField), 'new');
    await tester.tap(find.text('搜索'));
    await tester.pump();
    expect(find.text('新的综合结果'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('吧结果标出来源与最匹配，用户结果标 @用户名', (WidgetTester tester) async {
    await _setHistory(const <String>[]);
    final _RecordingApi api = _RecordingApi();
    Global.tiebaAPI = api;

    await _pump(
        tester, const SearchPage(searchWords: 'flutter', initialTab: 2));
    expect(find.text('最匹配'), findsOneWidget);

    await tester.tap(find.text('人'));
    // 头像的网络占位动画会一直挂起，这里不能用 pumpAndSettle。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('@nana_ao'), findsOneWidget);
    expect(find.text('青葉ナナ'), findsOneWidget);
  });

  testWidgets('人页签失败可以重试，点击结果携带 uid 打开主页', (WidgetTester tester) async {
    await _setHistory(const <String>[]);
    Global.tiebaAPI = _RecordingApi();
    int attempts = 0;
    RouteSettings? opened;
    await _pump(
        tester,
        SearchPage(
          searchWords: 'flutter',
          initialTab: 3,
          userLoader: (String keyword) async {
            if (++attempts == 1) throw Exception('network');
            return SearchUserResult(users: <TiebaUserMatch>[
              TiebaUserMatch(
                id: '59835',
                name: 'flutter',
                userNickname: '用户昵称',
                showNickname: '',
                portrait: '',
                intro: '搜索用户恢复',
              ),
            ]);
          },
        ), onGenerateRoute: (RouteSettings settings) {
      opened = settings;
      return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('用户主页')));
    });
    expect(find.text('搜索没成功'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(attempts, 2);
    expect(find.text('搜索没成功'), findsNothing);
    expect(find.text('搜索用户恢复'), findsOneWidget);
    await tester.tap(find.text('搜索用户恢复'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened!.name, PageRouter.user);
    expect(opened!.arguments, '59835');
    expect(find.text('用户主页'), findsOneWidget);
  });
}
