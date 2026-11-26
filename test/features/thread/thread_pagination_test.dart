import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/thread/state/reply_events.dart';
import 'package:tiebanana/features/thread/data/thread_cache.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/thread/pages/thread_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/features/thread/widgets/thread_floor_card.dart';

TiebaThreadPagePost _post(int floor) => TiebaThreadPagePost(
      id: '$floor',
      title: '',
      floor: '$floor',
      lbsInfo: '',
      subPostList: [],
      subPostNumber: '0',
      agreeNum: '${100 - floor}',
      content: [TiebaTextContent(text: '楼层内容 $floor\n用于分页阅读测试')],
      createTime: '1700000000',
      isFirstFloor: floor == 1,
      isInnerFloor: false,
      portrait: '',
      uid: '7',
      nameShow: '测试用户',
      username: 'test',
    );

TiebaThreadPage _page(int pn, {bool more = false, int? start, int? end}) =>
    TiebaThreadPage(
      posts: [
        for (int i = start ?? (pn - 1) * 5 + 2; i <= (end ?? pn * 5 + 1); i++)
          _post(i),
      ],
      page: TiebaPageInfo(currentPage: pn, hasMore: more, hasPrev: pn > 1),
      thread: TiebaThreadData(agreeType: '0'),
      userListSet: {
        '7': TiebaAuthor(
            icons: [],
            levelID: null,
            nameShow: '测试用户',
            portrait: '',
            uid: '7',
            username: 'test'),
      },
      videoInfo: null,
      isStored: false,
      tid: '123',
      title: '分页测试',
      fid: '1',
      forumName: '测试',
      avatar: '',
    );

class _Api extends DemoTiebaApi {
  _Api() : super(latency: Duration.zero);
  final List<int> calls = [];
  final List<bool> modes = [];
  Completer<TiebaThreadPage>? pending;
  final storeUpdates = <(String, String)>[];

  @override
  Future<void> threadAddStore(String tid, String pid, {int status = 1}) async {
    storeUpdates.add((tid, pid));
  }

  @override
  Future<TiebaThreadPage> getThreadPage(String kz,
      {String? pid, int pn = 1, int rn = 30, bool onlyLz = false}) {
    calls.add(pn);
    modes.add(onlyLz);
    pending = Completer<TiebaThreadPage>();
    return pending!.future;
  }
}

Future<GlobalKey<ThreadPageMainState>> _mount(
    WidgetTester tester, TiebaThreadPage page,
    {String? pid, bool withPreviousRoute = false}) async {
  await tester.binding.setSurfaceSize(const Size(390, 600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final key = GlobalKey<ThreadPageMainState>();
  final navigator = GlobalKey<NavigatorState>();
  final detail = Scaffold(
    body: ThreadPageMain(
      key: key,
      kz: '123',
      page: page,
      pid: pid,
      pn: page.page.currentPage,
      initPost: page.posts,
    ),
  );
  await tester.pumpWidget(ChangeNotifierProvider(
    create: (_) => APPSettingProvider(),
    child: MaterialApp(
      navigatorKey: navigator,
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: withPreviousRoute ? const Scaffold(body: Text('上一页')) : detail,
    ),
  ));
  if (withPreviousRoute) {
    navigator.currentState!.push(appPageRoute<void>(builder: (_) => detail));
    await tester.pumpAndSettle();
  }
  return key;
}

Future<void> _swipeBack(WidgetTester tester, {double x = 4}) async {
  await tester.dragFrom(Offset(x, 300), const Offset(265, 0));
  await tester.pumpAndSettle();
}

/// 滚到列表底部后继续上拉并松手，触发一次底部动作。
Future<void> _pullUpAtBottom(WidgetTester tester) async {
  final scrollable = find.byType(CustomScrollView);
  final position =
      tester.state<ScrollableState>(find.byType(Scrollable).first).position;
  position.jumpTo(position.maxScrollExtent);
  await tester.pump();
  final gesture = await tester.startGesture(tester.getCenter(scrollable));
  await gesture.moveBy(const Offset(0, -40));
  await gesture.moveBy(const Offset(0, -140));
  await tester.pump();
  await gesture.up();
  // 松手后的回弹需要多帧才会静止并派发 ScrollEnd。
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _Api api;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    Global.threadCache = ThreadCache();
    api = _Api();
    Global.tiebaAPI = api;
  });
  tearDown(() => Global.tiebaAPI = DemoTiebaApi());

  final iOS = TargetPlatformVariant({TargetPlatform.iOS});

  testWidgets('iOS 未收藏和离线收藏帖允许原生左缘侧滑返回', variant: iOS, (tester) async {
    for (final stored in [false, true]) {
      final key = await _mount(tester, _page(1)..isStored = stored,
          withPreviousRoute: true);
      if (stored) {
        key.currentState!.session.fail('离线');
        await tester.pumpAndSettle();
      }
      final route = ModalRoute.of(key.currentContext!)!;
      expect(route.popGestureEnabled, isTrue);
      await _swipeBack(tester);
      expect(find.text('上一页'), findsOneWidget);
      expect(api.storeUpdates, isEmpty);
    }
  });

  testWidgets('iOS 收藏帖左缘侧滑保留确认、取消与更新楼层', variant: iOS, (tester) async {
    final key = await _mount(tester, _page(1), withPreviousRoute: true);
    key.currentState!.isStored = true;
    await tester.pumpAndSettle();

    await _swipeBack(tester, x: 60);
    expect(find.byType(AlertDialog), findsNothing);
    await _swipeBack(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tapAt(const Offset(4, 300));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(ThreadPageMain), findsOneWidget);
    expect(api.storeUpdates, isEmpty);

    await _swipeBack(tester);
    final currentPid = key.currentState!.pid;
    expect(currentPid, isNotEmpty);
    await tester.tap(find.text('是'));
    await tester.pumpAndSettle();
    expect(api.storeUpdates, [('123', currentPid)]);
    expect(find.text('上一页'), findsOneWidget);
  });

  testWidgets('回帖成功重新读取末页并补入新增的一页，取消或其他帖子不刷新', (tester) async {
    final key = await _mount(tester, _page(1));
    replyEvents.sent('other');
    expect(api.calls, isEmpty);
    replyEvents.sent('123');
    expect(api.calls, [1]);
    api.pending!.complete(_page(1, more: true));
    await tester.pump();
    expect(api.calls, [1, 2]);
    api.pending!.complete(_page(2));
    await tester.pump();
    expect(key.currentState!.info.postList.map((p) => p.id), contains('11'));
    expect(key.currentState!.info.hasMore, isFalse);
    await tester.pumpWidget(const SizedBox());
    replyEvents.sent('123');
    expect(api.calls, [1, 2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('楼中楼回复重新读取父楼所在页，不清除其他已读页', (tester) async {
    final key = await _mount(tester, _page(1, more: true));
    key.currentState!.nextPage();
    api.pending!.complete(_page(2));
    await tester.pump();
    replyEvents.sent('123', pid: '3');
    expect(api.calls, [2, 1]);
    api.pending!.complete(_page(1, more: true));
    await tester.pump();
    expect(key.currentState!.info.postPage.keys, [1, 2]);
    expect(key.currentState!.info.hasMore, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('翻页请求中收到回帖成功通知也会补发刷新', (tester) async {
    final key = await _mount(tester, _page(1, more: true));
    key.currentState!.nextPage();
    replyEvents.sent('123', pid: '3');
    expect(api.calls, [2]);
    api.pending!.complete(_page(2));
    await tester.pump();
    expect(api.calls, [2, 1]);
    api.pending!.complete(_page(1, more: true));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('最后一页仍可向前加载，且上下边界互不覆盖', (tester) async {
    final key = await _mount(tester, _page(3));
    key.currentState!.prevPage();
    await tester.pump();
    expect(api.calls, [2]);
    expect(find.text('正在加载前面的楼层…'), findsOneWidget);
    api.pending!.complete(_page(2, more: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(key.currentState!.info.hasMore, isFalse);
    expect(key.currentState!.info.hasPrev, isTrue);
    key.currentState!.nextPage();
    expect(api.calls, [2]);
    key.currentState!.prevPage();
    expect(api.calls, [2, 1]);
    api.pending!.complete(_page(1, more: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(key.currentState!.info.hasPrev, isFalse);
    expect(key.currentState!.info.hasMore, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('收藏定位先补全当前页，避免遗漏目标之前的同页楼层', (tester) async {
    final key = await _mount(tester, _page(2, start: 9), pid: '9');
    final anchor = find.byWidgetPredicate(
        (w) => w is ThreadFloorComment && w.postMain.id == '9');
    final before = tester.getTopLeft(anchor).dy;
    key.currentState!.prevPage();
    expect(api.calls, [2]);
    api.pending!.complete(_page(2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(key.currentState!.info.postList.map((p) => p.id),
        ['7', '8', '9', '10', '11']);
    expect(tester.getTopLeft(anchor).dy, closeTo(before, 1));
    key.currentState!.prevPage();
    expect(api.calls, [2, 1]);
    api.pending!.complete(_page(1, more: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('向后翻页不覆盖前端边界，只看楼主缓存与普通模式独立', (tester) async {
    final key = await _mount(tester, _page(1, more: true));
    key.currentState!.nextPage();
    api.pending!.complete(_page(2));
    await tester.pump();
    expect(key.currentState!.info.hasPrev, isFalse);
    expect(key.currentState!.info.hasMore, isFalse);

    key.currentState!.onlyLz();
    await tester.pump();
    expect(api.modes, [false, true]);
    // 请求中再次切换不会让响应写入错误模式。
    key.currentState!.onlyLz();
    expect(key.currentState!.lz, isTrue);
    api.pending!.complete(_page(1, more: true));
    await tester.pump();
    key.currentState!.nextPage();
    api.pending!.complete(_page(2));
    await tester.pump();
    expect(key.currentState!.info.hasPrev, isFalse);
    key.currentState!.onlyLz();
    await tester.pump();
    expect(key.currentState!.info.bottomPn, 2);
    expect(key.currentState!.info.hasMore, isFalse);
    expect(api.calls, [2, 1, 2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('下一页立即显示加载态、阻止重复请求，失败可重试并明确到底', (tester) async {
    final key = await _mount(tester, _page(1, more: true, end: 3));
    key.currentState!.nextPage();
    key.currentState!.nextPage();
    await tester.pump();
    expect(api.calls, [2]);
    expect(find.text('正在全力加载中'), findsOneWidget);
    final hidden = tester.widget<Opacity>(find
        .ancestor(of: find.text('正在全力加载中'), matching: find.byType(Opacity))
        .first);
    expect(hidden.opacity, 0);
    api.pending!.completeError(StateError('offline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('正在浏览缓存，自动请求已暂停'), findsOneWidget);
    expect(find.text('苏格拉也有底'), findsNothing);
    key.currentState!.nextPage();
    key.currentState!.prevPage();
    key.currentState!.onlyLz();
    expect(api.calls, [2]);
    key.currentState!.onlyLz();
    await tester.ensureVisible(find.text('刷新'));
    await tester.tap(find.text('刷新'));
    await tester.pump();
    expect(api.calls, [2, 1]);
    api.pending!.complete(_page(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final scrollable = find.byType(CustomScrollView);
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    expect(find.text('苏格拉也有底'), findsNothing);
    final gesture = await tester.startGesture(tester.getCenter(scrollable));
    await gesture.moveBy(const Offset(0, -30));
    await gesture.moveBy(const Offset(0, -140));
    await tester.pump();
    final revealed = tester.widget<Opacity>(find
        .ancestor(of: find.text('松开刷新'), matching: find.byType(Opacity))
        .first);
    expect(revealed.opacity, greaterThan(0));
    await gesture.up();
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(api.calls, [2, 1, 1]);
    api.pending!.complete(_page(1));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('未到底时上拉显示全力加载和跳动动画，松手隐藏', (tester) async {
    await _mount(tester, _page(1, more: true, end: 3));
    final scrollable = find.byType(CustomScrollView);
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    final gesture = await tester.startGesture(tester.getCenter(scrollable));
    await gesture.moveBy(const Offset(0, -30));
    await gesture.moveBy(const Offset(0, -140));
    await tester.pump();
    expect(api.calls, [2]);
    final caption = find.text('正在全力加载中');
    final opacity =
        find.ancestor(of: caption, matching: find.byType(Opacity)).first;
    expect(tester.widget<Opacity>(opacity).opacity, greaterThan(0));
    final dots = find.descendant(
        of: find.ancestor(of: caption, matching: find.byType(Row)).first,
        matching: find.byType(Transform));
    final before =
        tester.widget<Transform>(dots.first).transform.getTranslation().y;
    await tester.pump(const Duration(milliseconds: 150));
    final after =
        tester.widget<Transform>(dots.first).transform.getTranslation().y;
    expect(after, isNot(before));
    await gesture.up();
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.widget<Opacity>(opacity).opacity, 0);
    api.pending!.complete(_page(2));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('距离底部一屏左右即预取，不必触底', (tester) async {
    await _mount(tester, _page(1, more: true, end: 20));
    final scrollable = find.byType(CustomScrollView);
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    position.jumpTo(position.maxScrollExtent - 500);
    await tester.pump();
    expect(api.calls, isEmpty);
    await tester.drag(scrollable, const Offset(0, -80));
    await tester.pump();
    expect(position.extentAfter, greaterThan(0));
    expect(api.calls, [2]);
    api.pending!.complete(_page(2));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('默认正序，追加新页不按赞数重排已读楼层', (tester) async {
    final page = _page(1, more: true, end: 3);
    page.posts.first.agreeNum = '0';
    page.posts.last.agreeNum = '999';
    await _mount(tester, page);
    final floors = tester
        .widgetList<ThreadFloorComment>(find.byType(ThreadFloorComment))
        .map((w) => w.postMain.id)
        .toList();
    expect(floors, ['2', '3']);
  });

  testWidgets('最后一页继续上拉只刷新一次末页，新回复追加到底部', (tester) async {
    final key = await _mount(tester, _page(1, end: 20));
    await _pullUpAtBottom(tester);
    expect(find.text('正在刷新…'), findsOneWidget);
    expect(api.calls, [1]);
    // 刷新请求还在进行中，再次上拉不会重复请求。
    await _pullUpAtBottom(tester);
    expect(api.calls, [1]);
    api.pending!.complete(_page(1, end: 22));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(key.currentState!.info.postList.map((p) => p.id),
        containsAll(<String>['21', '22']));
    expect(key.currentState!.info.hasMore, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('底部刷新提示落在列表末尾空白区，不覆盖楼层内容', (tester) async {
    await _mount(tester, _page(1, end: 20));
    await _pullUpAtBottom(tester);
    expect(find.text('正在刷新…'), findsOneWidget);
    final Rect caption = tester.getRect(find.text('正在刷新…'));
    final List<ThreadFloorComment> floors = tester
        .widgetList<ThreadFloorComment>(find.byType(ThreadFloorComment))
        .toList();
    final Rect lastFloor = tester.getRect(find.byWidget(floors.last));
    expect(caption.top, greaterThanOrEqualTo(lastFloor.bottom));
    api.pending!.complete(_page(1, end: 20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('底部提示跟手、松开回弹到文字高度，无新内容显示到底再收起', (tester) async {
    await _mount(tester, _page(1, end: 20));
    final scrollable = find.byType(CustomScrollView);
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    final gesture = await tester.startGesture(tester.getCenter(scrollable));
    await gesture.moveBy(const Offset(0, -30));
    await gesture.moveBy(const Offset(0, -24));
    await tester.pump();
    expect(find.text('下拉刷新'), findsOneWidget);
    await gesture.moveBy(const Offset(0, -140));
    await tester.pump();
    expect(find.text('松开刷新'), findsOneWidget);
    final footer = find.byKey(const ValueKey('thread-bottom-refresh-space'));
    final expandedHeight = tester.getSize(footer).height;
    final lastFloor = find.byWidgetPredicate(
        (widget) => widget is ThreadFloorComment && widget.postMain.id == '20');
    final expandedBottom = tester.getBottomLeft(lastFloor).dy;
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(api.calls, [1]);
    expect(find.text('正在刷新…'), findsOneWidget);
    expect(tester.getSize(footer).height, inExclusiveRange(56, expandedHeight));
    expect(tester.getBottomLeft(lastFloor).dy, greaterThan(expandedBottom));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.getSize(footer).height, closeTo(56, .1));
    api.pending!.complete(_page(1, end: 20));
    await tester.pump();
    expect(find.text('苏格拉也有底'), findsOneWidget);
    expect(tester.getSize(footer).height, closeTo(56, .1));
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pump(const Duration(milliseconds: 140));
    expect(tester.getSize(footer).height, lessThan(expandedHeight));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getSize(footer).height, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('松开刷新状态往回拖逐步收起，不突然弹回也不请求刷新', (tester) async {
    await _mount(tester, _page(1, end: 20));
    final scrollable = find.byType(CustomScrollView);
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    final gesture = await tester.startGesture(tester.getCenter(scrollable));
    await gesture.moveBy(const Offset(0, -30));
    await gesture.moveBy(const Offset(0, -160));
    await tester.pump();
    expect(find.text('松开刷新'), findsOneWidget);
    final footer = find.byKey(const ValueKey('thread-bottom-refresh-space'));
    final height = tester.getSize(footer).height;
    final offset = position.pixels;
    final lastFloor = find.byWidgetPredicate(
        (widget) => widget is ThreadFloorComment && widget.postMain.id == '20');
    final bottom = tester.getBottomLeft(lastFloor).dy;
    await gesture.moveBy(const Offset(0, 12));
    await tester.pump();
    expect(tester.getSize(footer).height, closeTo(height - 12, 1));
    expect(position.pixels, closeTo(offset, 1));
    expect(tester.getBottomLeft(lastFloor).dy, closeTo(bottom + 12, 1));
    await gesture.moveBy(Offset(0, height - 40));
    await tester.pump();
    expect(find.text('下拉刷新'), findsOneWidget);
    expect(tester.getSize(footer).height, greaterThan(0));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getSize(footer).height, 0);
    expect(api.calls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('继续上拉有渐增阻尼，没有固定高度硬限位', (tester) async {
    await _mount(tester, _page(1, end: 20));
    final scrollable = find.byType(CustomScrollView);
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    final gesture = await tester.startGesture(tester.getCenter(scrollable));
    final footer = find.byKey(const ValueKey('thread-bottom-refresh-space'));
    await gesture.moveBy(const Offset(0, -30));
    await gesture.moveBy(const Offset(0, -140));
    await tester.pump();
    final first = tester.getSize(footer).height;
    await gesture.moveBy(const Offset(0, -140));
    await tester.pump();
    final second = tester.getSize(footer).height;
    await gesture.moveBy(const Offset(0, -140));
    await tester.pump();
    final third = tester.getSize(footer).height;
    expect(second, greaterThan(first));
    expect(third, greaterThan(second));
    expect(second, greaterThan(96));
    expect(third - second, lessThan(second - first));
    expect(second - first, lessThan(140));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.getSize(footer).height, closeTo(56, .1));
    expect(api.calls, [1]);
    api.pending!.complete(_page(1, end: 20));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('底部刷新的新楼层淡入，已有楼层保持不透明', (tester) async {
    await _mount(tester, _page(1, end: 20));
    await _pullUpAtBottom(tester);
    api.pending!.complete(_page(1, end: 22));
    await tester.pump();
    FadeTransition fade(String id) => tester.widget<FadeTransition>(
        find.byKey(ValueKey('bottom-floor-$id'), skipOffstage: false));
    expect(fade('21').opacity.value, 0);
    expect(fade('20').opacity.value, 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(fade('21').opacity.value, inExclusiveRange(0, 1));
    expect(fade('20').opacity.value, 1);
    await tester.pump(const Duration(milliseconds: 220));
    expect(fade('21').opacity.value, 1);
    expect(find.text('苏格拉也有底'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('末页刷新发现新页时继续加载', (tester) async {
    final key = await _mount(tester, _page(1, end: 20));
    await _pullUpAtBottom(tester);
    expect(api.calls, [1]);
    api.pending!.complete(_page(1, more: true, end: 20));
    await tester.pump();
    expect(api.calls, [1, 2]);
    api.pending!.complete(_page(2, start: 21, end: 25));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(key.currentState!.info.postList.map((p) => p.id), contains('25'));
    expect(key.currentState!.info.bottomPn, 2);
    expect(key.currentState!.info.hasMore, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('有下一页且加载失败时，上拉优先重试下一页', (tester) async {
    final key = await _mount(tester, _page(1, more: true, end: 20));
    key.currentState!.nextPage();
    expect(api.calls, [2]);
    api.pending!.completeError(StateError('offline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _pullUpAtBottom(tester);
    expect(api.calls, [2, 2]);
    api.pending!.complete(_page(2, start: 21, end: 25));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(key.currentState!.info.postList.map((p) => p.id), contains('21'));
    expect(key.currentState!.info.hasMore, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('末页刷新失败显示重试条，点击可重试', (tester) async {
    final key = await _mount(tester, _page(1, end: 20));
    await _pullUpAtBottom(tester);
    api.pending!.completeError(StateError('offline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('刷新失败，点击重试'), findsOneWidget);
    await tester.tap(find.text('刷新失败，点击重试'));
    await tester.pump();
    expect(api.calls, [1, 1]);
    api.pending!.complete(_page(1, end: 21));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(key.currentState!.info.postList.map((p) => p.id), contains('21'));
    expect(tester.takeException(), isNull);
  });
}
