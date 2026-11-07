// 吧页首屏页签回归：
// 首屏响应只对应服务端默认页签；上次停留的页签是另一个时，进页面要直接
// 拉那个页签，而不是把默认列表塞过去、TabController 却停在第一项。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/forum/pages/forum_home_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

import '../../support/fake_thread.dart';

/// 两个页签各返回一条标题不同的帖子，记录实际请求过的页签。
class _TabsApi extends DemoTiebaApi {
  _TabsApi({this.emptyWithoutTab = false}) : super(latency: Duration.zero);

  /// 模拟部分吧：不带页签的首屏请求返回空列表，带页签才有帖子。
  final bool emptyWithoutTab;

  final List<String?> requestedTabs = <String?>[];

  @override
  Future<ForumPage> getForumPage({
    required String kw,
    required int pn,
    int rn = 20,
    int sortType = 0,
    bool isgood = false,
    int cid = 0,
    TiebaForumTab? tab,
    int partitionType = 0,
    String frsCommonInfo = '',
    String topCardId = '',
  }) async {
    requestedTabs.add(tab?.id);
    final bool latest = tab?.id == '503';
    final bool empty = emptyWithoutTab && tab == null;
    return ForumPage(
      threads: empty
          ? const <TiebaThreadInfo>[]
          : <TiebaThreadInfo>[
              fakeThreadInfo(
                tid: latest ? '2' : '1',
                title: latest ? '最新页签的帖子' : '默认页签的帖子',
                fname: '测试吧',
              ),
            ],
      forum: TiebaForumHeader(
        avatar: '',
        name: '测试吧',
        levelupScore: '100',
        curScore: '20',
        isLike: false,
        isSigned: false,
        fid: '100',
        levelId: '1',
        levelName: '初级粉丝',
        memberNum: '10',
        postNum: '20',
        goodClassify: const <TiebaGoodPostClassify>[],
      ),
      page: TiebaPageInfo(currentPage: pn, hasMore: false, hasPrev: false),
      tabs: const <TiebaForumTab>[
        TiebaForumTab(
          id: '1',
          type: '13',
          name: '热门',
          netTabType: 2,
          isDefault: true,
        ),
        TiebaForumTab(
          id: '503',
          type: '14',
          name: '最新',
          netTabType: 1,
        ),
      ],
      defaultTabId: '1',
    );
  }
}

void main() {
  testWidgets('上次停在非默认页签：进页面直接显示该页签的帖子', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'forumTab.100': '503',
    });
    Global.profile = await SharedPreferences.getInstance();
    Global.tiebaAPI = _TabsApi();

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: const Scaffold(body: Text('home')),
    ));
    await tester.pumpAndSettle();

    // 走真实路由创建时机：Overlay 已挂载，吧页才能在 initState 里量尺寸。
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(MaterialPageRoute<void>(
          builder: (BuildContext context) => const ForumHomePage(kw: '测试吧'),
        ));
    // 骨架 / 页签切换里有循环动画，pumpAndSettle 不会停；固定推进几帧。
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('最新页签的帖子'), findsOneWidget);
    expect(find.text('默认页签的帖子'), findsNothing);
    expect(find.text('这个吧还没有帖子'), findsNothing);
    expect((Global.tiebaAPI as _TabsApi).requestedTabs, <String?>[null, '503']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('首屏空列表：带默认页签自动补拉，不显示「还没有帖子」', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    Global.tiebaAPI = _TabsApi(emptyWithoutTab: true);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: const Scaffold(body: Text('home')),
    ));
    await tester.pumpAndSettle();

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(MaterialPageRoute<void>(
          builder: (BuildContext context) => const ForumHomePage(kw: '测试吧'),
        ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('默认页签的帖子'), findsOneWidget);
    expect(find.text('这个吧还没有帖子'), findsNothing);
    expect((Global.tiebaAPI as _TabsApi).requestedTabs, <String?>[null, '1']);
    expect(tester.takeException(), isNull);
  });
}
