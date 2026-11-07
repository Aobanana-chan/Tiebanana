import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/thread/data/thread_cache.dart';
import 'package:tiebanana/features/history/data/dao_api.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/thread/pages/thread_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/features/thread/widgets/thread_floor_card.dart';

import '../thread/thread_cache_test.dart' as fixtures;

class _Dao extends DAOAPI {
  @override
  void storeViewHistory(String tid, String title, String forumName) {}
}

class _Api extends DemoTiebaApi {
  int calls = 0;
  int innerCalls = 0;
  Completer<TiebaThreadPage> pending = Completer();
  Completer<InnerFloor> innerPending = Completer();
  @override
  Future<TiebaThreadPage> getThreadPage(String kz,
      {String? pid, int pn = 1, int rn = 30, bool onlyLz = false}) {
    calls++;
    pending = Completer();
    return pending.future;
  }

  @override
  Future<InnerFloor> getInnerFloor(String kz, String pid,
      {String spid = '', int pn = 1, int rn = 30}) {
    innerCalls++;
    innerPending = Completer();
    return innerPending.future;
  }
}

Widget host(Widget child) => ChangeNotifierProvider(
    create: (_) => APPSettingProvider(),
    child: MaterialApp(
        theme: TiebananaTheme.light(seedOf('blue'), 16), home: child));

void main() {
  late Directory dir;
  late _Api api;
  late DAOAPI oldDao;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'uid': 'a'});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    dir = await Directory('build').createTemp('tiebanana_cache_page_test_');
    Global.threadCache = ThreadCache();
    await Global.threadCache.init(dir.path);
    api = _Api();
    Global.tiebaAPI = api;
    oldDao = Global.daoapi;
    Global.daoapi = _Dao();
  });
  tearDown(() async {
    Global.daoapi = oldDao;
    Global.threadCache = ThreadCache();
    await dir.delete(recursive: true);
  });

  testWidgets('缓存先构建；删帖不退出、所有自动请求暂停；手动刷新增量更新且保留旧楼层', (tester) async {
    await tester.runAsync(() => Global.threadCache
        .savePage('a', fixtures.page(stored: true)..videoInfo = null));
    await tester.runAsync(
        () => tester.pumpWidget(host(const ThreadPageRoute(kz: '123'))));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(find.byType(ThreadPageMain), findsOneWidget);
    expect(api.calls, 1);
    final state =
        tester.state<ThreadPageMainState>(find.byType(ThreadPageMain));
    expect(state.info.postList.map((p) => p.id), ['1', '2']);
    await tester.runAsync(() async {
      api.pending.completeError(StateError('帖子已删除'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();
    expect(find.text('正在浏览缓存，自动请求已暂停'), findsOneWidget);
    state.nextPage();
    state.prevPage();
    state.onlyLz();
    state.onlyLz();
    expect(api.calls, 1);

    api.pending = Completer();
    await tester.ensureVisible(find.text('刷新'));
    await tester.runAsync(() => tester.tap(find.text('刷新')));
    await tester.pump();
    expect(api.calls, 2);
    final fresh = fixtures.page(stored: true, ids: ['2', '3'])
      ..videoInfo = null;
    fresh.posts.first.content = [TiebaTextContent(text: '最新正文')];
    await tester.runAsync(() async {
      api.pending.complete(fresh);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(tester.state(find.byType(ThreadPageMain)), same(state));
    expect(state.info.postList.map((p) => p.id), ['1', '2', '3']);
    expect(state.info.postList.first.isDeleted, isTrue);
    expect(find.text('已删除'), findsOneWidget);
    expect((state.info.postList[1].content.single as TiebaTextContent).text,
        '最新正文');
    expect(state.session.paused, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('无缓存失败显示页内提示，重试防重复点击，成功后展示帖子', (tester) async {
    await tester.runAsync(
        () => tester.pumpWidget(host(const ThreadPageRoute(kz: '123'))));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.runAsync(() async {
      api.pending.completeError(StateError('offline'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();
    expect(find.byType(ThreadPageRoute), findsOneWidget);
    expect(find.text('帖子暂时打不开'), findsOneWidget);
    expect(find.text('请稍后重试，当前暂无可用缓存'), findsOneWidget);
    expect(find.text('加载失败，请稍后重试'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    // 独立入口没有上一页，不提供无效的返回按钮。
    expect(find.text('返回'), findsNothing);
    expect(api.calls, 1);

    await tester.runAsync(() => tester.tap(find.text('重试')));
    await tester.pump();
    expect(api.calls, 2);
    expect(find.text('帖子暂时打不开'), findsOneWidget);
    expect(find.text('正在重试…'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.tap(find.text('正在重试…'));
    expect(api.calls, 2);

    await tester.runAsync(() async {
      api.pending.complete(fixtures.page()..videoInfo = null);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    expect(find.byType(ThreadPageMain), findsOneWidget);
    expect(find.text('帖子暂时打不开'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('无缓存连续失败可再次重试，也可返回原页面', (tester) async {
    await tester.pumpWidget(host(Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const ThreadPageRoute(kz: '123'))),
          child: const Text('打开帖子'),
        ),
      ),
    )));
    await tester.runAsync(() async {
      await tester.tap(find.text('打开帖子'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    expect(api.calls, 1);
    await tester.runAsync(() async {
      api.pending.completeError(StateError('offline'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pumpAndSettle();
    expect(find.text('返回'), findsOneWidget);
    await tester.runAsync(() => tester.tap(find.text('重试')));
    await tester.pump();
    expect(api.calls, 2);
    await tester.runAsync(() async {
      api.pending.completeError(StateError('still offline'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pumpAndSettle();
    expect(find.text('重试'), findsOneWidget);
    expect(find.text('正在重试…'), findsNothing);
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tap(find.text('返回'));
    await tester.pumpAndSettle();
    expect(find.byType(ThreadPageRoute), findsNothing);
    expect(find.text('打开帖子'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('主帖熔断时楼中楼从磁盘恢复且不发送请求，手动刷新才恢复', (tester) async {
    final session = ThreadReadSession()..fail(StateError('deleted'));
    final p = fixtures.page(stored: true);
    final inner = InnerFloor(
        post: fixtures.post('2'),
        subposts: [fixtures.reply('saved')],
        page:
            const TiebaPageInfo(currentPage: 1, hasMore: false, hasPrev: false),
        thread: p.thread,
        authors: p.userListSet);
    await tester.runAsync(() async {
      await Global.threadCache.savePage('a', p);
      await Global.threadCache.saveInner('a', '123', '2', inner);
    });
    await tester.runAsync(() => tester.pumpWidget(host(Scaffold(
        body: InnerFloorBottomSheet(
            floorNum: '2',
            kz: '123',
            pid: '2',
            forum: p,
            session: session,
            cacheUid: 'a')))));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();
    expect(find.byType(InnerFloorCard), findsNWidgets(2));
    expect(api.innerCalls, 0);
    await tester.runAsync(() => tester.tap(find.byTooltip('刷新楼中楼')));
    await tester.pump();
    expect(api.innerCalls, 1);
    await tester.runAsync(() async {
      api.innerPending.completeError(StateError('still deleted'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();
    expect(find.byType(InnerFloorCard), findsNWidgets(2));
    expect(session.paused, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
}
