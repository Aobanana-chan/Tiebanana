import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/features/forum/data/forum_visit_store.dart';
import 'package:tiebanana/features/forum/pages/forum_home_page.dart';
import 'package:tiebanana/features/forum/state/forum_state.dart';
import 'package:tiebanana/features/history/data/dao_api.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/thread/data/thread_cache.dart';
import 'package:tiebanana/features/thread/pages/thread_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';

class _TestForumState extends ForumState {
  _TestForumState(this._items);

  final List<LikeForumInfo> _items;

  @override
  List<LikeForumInfo> get forums => _items;

  @override
  Future<void> refresh() async {}

  @override
  void saveForumOrder(List<LikeForumInfo> ordered) {
    _items
      ..clear()
      ..addAll(ordered);
    notifyListeners();
  }
}

class _NoopDao extends DAOAPI {
  @override
  void storeViewHistory(String tid, String title, String forumName) {}
}

class _VisitTestApi extends DemoTiebaApi {
  _VisitTestApi() : super(latency: Duration.zero);

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
    return ForumPage(
      threads: const <TiebaThreadInfo>[],
      forum: TiebaForumHeader(
        avatar: '',
        name: kw,
        levelupScore: '100',
        curScore: '20',
        isLike: true,
        isSigned: false,
        fid: '100',
        levelId: '5',
        levelName: '铁杆会员',
        memberNum: '100',
        postNum: '200',
        goodClassify: const <TiebaGoodPostClassify>[],
      ),
      page: TiebaPageInfo(currentPage: pn, hasMore: false, hasPrev: false),
      tabs: const <TiebaForumTab>[
        TiebaForumTab(
          id: '1',
          type: '13',
          name: '看帖',
          netTabType: 2,
          isDefault: true,
        ),
        TiebaForumTab(
          id: '2',
          type: '14',
          name: '最新',
          netTabType: 1,
        ),
      ],
      defaultTabId: '1',
    );
  }

  @override
  Future<TiebaThreadPage> getThreadPage(
    String kz, {
    String? pid,
    int pn = 1,
    int rn = 30,
    bool onlyLz = false,
  }) async {
    final String forumName = kz == 't_b' ? '吧B' : '吧A';
    return TiebaThreadPage(
      tid: kz,
      fid: '1',
      forumName: forumName,
      avatar: '',
      title: '测试帖子 $kz',
      posts: <TiebaThreadPagePost>[
        TiebaThreadPagePost(
          id: 'p1',
          title: '',
          floor: '1',
          lbsInfo: '',
          ipLocation: '',
          subPostList: const <TiebaSubPost>[],
          subPostNumber: '0',
          content: <TiebaPostContent>[TiebaTextContent(text: '正文')],
          createTime: '1700000000',
          isFirstFloor: true,
          isInnerFloor: false,
          portrait: '',
          uid: 'u1',
          nameShow: '作者',
          username: 'author',
        ),
      ],
      userListSet: <String, TiebaAuthor>{
        'u1': TiebaAuthor(
          icons: const <String>[],
          levelID: '5',
          forumRole: null,
          nameShow: '作者',
          portrait: '',
          uid: 'u1',
          username: 'author',
        ),
      },
      thread: TiebaThreadData(
        agreeType: '0',
        storeCount: 0,
        authorUid: 'u1',
      ),
      videoInfo: null,
      page: TiebaPageInfo(currentPage: 1, hasMore: false, hasPrev: false),
      isStored: false,
    );
  }
}

LikeForumInfo _forum(String name, {String isSign = '0', String levelId = '4'}) =>
    LikeForumInfo(
      forumId: name,
      avatar: '',
      forumName: name,
      isSign: isSign,
      levelId: levelId,
    );

Widget _shellApp(ForumState forumState) {
  return MultiProvider(
    providers: <ChangeNotifierProvider<dynamic>>[
      ChangeNotifierProvider<APPSettingProvider>(
        create: (_) => APPSettingProvider(),
      ),
      ChangeNotifierProvider<User>(
        create: (_) => User(),
      ),
      ChangeNotifierProvider<ForumState>.value(value: forumState),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: const DesktopShellFrame(
        title: '首页',
        activeTab: 0,
        child: SizedBox.expand(),
      ),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'uid': '10001',
      'userName': '测试账号',
    });
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting)
      ..sidebarFolded = false;
    Global.tiebaAPI = _VisitTestApi();
  });

  test('ForumVisitStore 按账号隔离并累计访问次数，忽略空吧名和损坏数据', () {
    ForumVisitStore.recordVisit('   ');
    expect(ForumVisitStore.load(), isEmpty);

    ForumVisitStore.recordVisit(
      '吧A',
      avatar: 'https://example.com/a.png',
      now: DateTime(2026, 11, 29, 10, 0),
    );
    ForumVisitStore.recordVisit(
      '吧A',
      now: DateTime(2026, 11, 29, 10, 5),
    );
    ForumVisitStore.recordVisit(
      '吧B',
      now: DateTime(2026, 11, 29, 10, 2),
    );

    final Map<String, ForumVisitRecord> uid1 = ForumVisitStore.load();
    expect(uid1['吧A']?.count, 2);
    expect(uid1['吧A']?.avatar, 'https://example.com/a.png');
    expect(
      uid1['吧A']?.lastVisitAt,
      DateTime(2026, 11, 29, 10, 5).millisecondsSinceEpoch,
    );
    expect(uid1['吧B']?.count, 1);

    // 切换账号后数据独立
    Global.profile.setString('uid', '10002');
    expect(ForumVisitStore.load(), isEmpty);
    ForumVisitStore.recordVisit('吧C');
    expect(ForumVisitStore.load()['吧C']?.count, 1);

    Global.profile.setString('uid', '10001');
    expect(ForumVisitStore.load()['吧C'], isNull);
    expect(ForumVisitStore.load()['吧A']?.count, 2);

    // 损坏 JSON 不崩溃
    Global.profile.setString('${ForumVisitStore.storageKeyPrefix}10001', '{bad');
    expect(ForumVisitStore.load(), isEmpty);
  });

  testWidgets('桌面侧边栏常逛的吧仅显示逛过的吧，按进入该吧和该吧贴的次数排序，不跟随关注吧排序', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    final _TestForumState forumState = _TestForumState(<LikeForumInfo>[
      for (int i = 0; i < 10; i++) _forum('吧$i'),
    ]);
    addTearDown(forumState.dispose);

    await tester.pumpWidget(_shellApp(forumState));
    await tester.pumpAndSettle();

    // 未逛过任何吧时，不显示未逛过的关注吧
    expect(find.text('暂无逛过的吧'), findsOneWidget);
    for (int i = 0; i < 10; i++) {
      expect(find.text('吧$i'), findsNothing);
    }

    // 吧9 访问 3 次，吧5 访问 2 次，吧2 访问 2 次（时间更早），未关注的 路人吧 访问 4 次。
    ForumVisitStore.recordVisit('吧2', now: DateTime(2026, 11, 29, 9, 0));
    ForumVisitStore.recordVisit('吧2', now: DateTime(2026, 11, 29, 9, 1));
    ForumVisitStore.recordVisit('吧5', now: DateTime(2026, 11, 29, 9, 2));
    ForumVisitStore.recordVisit('吧5', now: DateTime(2026, 11, 29, 9, 5));
    ForumVisitStore.recordVisit('吧9', now: DateTime(2026, 11, 29, 9, 3));
    ForumVisitStore.recordVisit('吧9', now: DateTime(2026, 11, 29, 9, 4));
    ForumVisitStore.recordVisit('吧9', now: DateTime(2026, 11, 29, 9, 6));
    for (int i = 0; i < 4; i++) {
      ForumVisitStore.recordVisit('路人吧', now: DateTime(2026, 11, 29, 9, 7 + i));
    }

    await tester.pumpAndSettle();

    List<String> displayedOrder() {
      final List<String> names = <String>[
        '路人吧',
        for (int i = 0; i < 10; i++) '吧$i',
      ];
      final List<({String name, double dy})> found =
          <({String name, double dy})>[];
      for (final String name in names) {
        final Finder f = find.text(name);
        if (f.evaluate().isNotEmpty) {
          found.add((name: name, dy: tester.getTopLeft(f.first).dy));
        }
      }
      found.sort((a, b) => a.dy.compareTo(b.dy));
      return found.map((e) => e.name).toList();
    }

    // 只显示逛过的 4 个吧：路人吧(4) -> 吧9(3) -> 吧5(2,更近) -> 吧2(2,更早)；未逛过的 吧0 等不显示
    expect(find.text('暂无逛过的吧'), findsNothing);
    expect(
      displayedOrder(),
      <String>['路人吧', '吧9', '吧5', '吧2'],
    );
    // 路人吧未关注，不显示 Lv. 徽章；已关注的 3 个逛过的吧显示 Lv.4
    expect(find.text('Lv.4'), findsNWidgets(3));

    // 手动改动关注吧排序：把 吧8 放到最前，常逛的吧顺序不受影响且不显示未逛过的 吧8
    forumState.saveForumOrder(<LikeForumInfo>[
      _forum('吧8'),
      for (int i = 0; i < 10; i++)
        if (i != 8) _forum('吧$i'),
    ]);
    await tester.pumpAndSettle();
    expect(
      displayedOrder(),
      <String>['路人吧', '吧9', '吧5', '吧2'],
    );

    // 实时增加 吧1 的访问次数（5次）后，吧1 出现在首位；再增加到超过 8 个逛过的吧，只保留前 8 个
    for (int i = 0; i < 5; i++) {
      ForumVisitStore.recordVisit('吧1', now: DateTime(2026, 11, 29, 10, i));
    }
    await tester.pumpAndSettle();
    expect(
      displayedOrder(),
      <String>['吧1', '路人吧', '吧9', '吧5', '吧2'],
    );

    for (final String extra in <String>['吧0', '吧3', '吧4', '吧6']) {
      ForumVisitStore.recordVisit(extra, now: DateTime(2026, 11, 29, 8, 0));
    }
    await tester.pumpAndSettle();
    expect(displayedOrder().length, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('进入吧主页和进入该吧的贴均会累计到该吧的访问次数', (WidgetTester tester) async {
    late Directory dir;
    final ThreadCache prevCache = Global.threadCache;
    final DAOAPI prevDao = Global.daoapi;
    await tester.runAsync(() async {
      dir = await Directory('build').createTemp('tiebanana_visit_test_');
      Global.threadCache = ThreadCache();
      await Global.threadCache.init(dir.path);
    });
    Global.daoapi = _NoopDao();
    addTearDown(() {
      Global.threadCache = prevCache;
      Global.daoapi = prevDao;
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 1. 进入 吧A 主页（+1）并切页签不重复计数（通过 Navigator.push 确保 Overlay 已挂载）
    await tester.pumpWidget(
      ChangeNotifierProvider<APPSettingProvider>(
        create: (_) => APPSettingProvider(),
        child: MaterialApp(
          theme: TiebananaTheme.light(seedOf('blue'), 16),
          home: const Scaffold(body: Text('host')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(MaterialPageRoute<void>(
          builder: (BuildContext context) => const ForumHomePage(kw: '吧A'),
        ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(ForumVisitStore.load()['吧A']?.count, 1);

    await tester.tap(find.text('最新'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(ForumVisitStore.load()['吧A']?.count, 1);

    // 2. 进入 吧A 下的两个帖子（各 +1 -> 共 3 次），以及 吧B 下的一个帖子（+1）
    Future<void> openThread(String kz) async {
      await tester.runAsync(() => tester.pumpWidget(
            ChangeNotifierProvider<APPSettingProvider>(
              create: (_) => APPSettingProvider(),
              child: MaterialApp(
                theme: TiebananaTheme.light(seedOf('blue'), 16),
                home: ThreadPageRoute(key: ValueKey<String>(kz), kz: kz),
              ),
            ),
          ));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
    }

    await openThread('t_a1');
    expect(ForumVisitStore.load()['吧A']?.count, 2);

    await openThread('t_a2');
    expect(ForumVisitStore.load()['吧A']?.count, 3);

    await openThread('t_b');
    expect(ForumVisitStore.load()['吧B']?.count, 1);
    expect(tester.takeException(), isNull);
  });
}
