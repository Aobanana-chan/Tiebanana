// 动态页状态族回归：骨架 / 空 / 错误 / 未登录 / 续读条 / 帖子卡片。
import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_test/flutter_test.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/recommend/pages/recommend_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';

import '../../support/fake_thread.dart';

/// 推荐流里的一条帖子（对齐 `tbclient.ThreadInfo`）。
TiebaThreadInfo _thread(
        {String tid = '1',
        String title = 'Flutter 3.47 升级踩坑记录，附完整迁移清单',
        String fname = 'Flutter',
        String text = '从 3.24 升到 3.47 花了两个晚上，主要卡在 extended_image 与 objectbox 的非空迁移……'}) =>
    fakeRecommendThread(tid: tid, title: title, fname: fname, text: text);

Widget _app(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: TiebananaTheme.light(seedOf('blue'), 16),
    home: Scaffold(body: child),
  );
}

/// 直接渲染动态流展示层（不碰网络）。
Widget _feed({
  List<TiebaThreadInfo?> items = const <TiebaThreadInfo?>[],
  bool loading = false,
  Object? error,
  bool notLoggedIn = false,
  bool loadingMore = false,
  Object? moreError,
  ScrollController? scrollController,
  VoidCallback? onRetry,
  VoidCallback? onLoadMore,
  Future<void> Function()? onRefresh,
  Future<void> Function()? onResumeTap,
}) {
  return _app(RecommendFeed(
    items: items,
    loading: loading,
    error: error,
    notLoggedIn: notLoggedIn,
    loadingMore: loadingMore,
    moreError: moreError,
    scrollController: scrollController ?? ScrollController(),
    onRefresh: onRefresh ?? () async {},
    onResumeTap: onResumeTap ?? () async {},
    onRetry: onRetry ?? () {},
    onLoadMore: onLoadMore ?? () {},
  ));
}

void main() {
  testWidgets('加载中：出三张骨架卡片', (WidgetTester tester) async {
    await tester.pumpWidget(_feed(loading: true));
    await tester.pump();

    expect(find.byType(SkeletonBox), findsWidgets);
    expect(find.byType(StateView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('空态：给说明与重新加载', (WidgetTester tester) async {
    await tester.pumpWidget(_feed());
    await tester.pump();

    expect(find.text('还没有推荐内容'), findsOneWidget);
    expect(find.text('重新加载'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('网络错误：可重试', (WidgetTester tester) async {
    int retried = 0;
    await tester.pumpWidget(
        _feed(error: Exception('boom'), onRetry: () => retried++));
    await tester.pump();

    expect(find.text('网络似乎有点问题'), findsOneWidget);
    await tester.tap(find.text('重试'));
    expect(retried, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('未登录：给去登录入口而不是重试', (WidgetTester tester) async {
    await tester.pumpWidget(
        _feed(error: Exception('未登录'), notLoggedIn: true));
    await tester.pump();

    expect(find.text('登录后才能看动态'), findsOneWidget);
    expect(find.text('去登录'), findsOneWidget);
    expect(find.text('重试'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('续读条：点它触发刷新回调', (WidgetTester tester) async {
    int resumed = 0;
    await tester.pumpWidget(_feed(
      items: <TiebaThreadInfo?>[null],
      onResumeTap: () async => resumed++,
    ));
    await tester.pump();

    expect(find.text('上次读到这里，点击刷新'), findsOneWidget);
    await tester.tap(find.text('上次读到这里，点击刷新'));
    await tester.pump();
    expect(resumed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('列表：帖子卡片带标题、摘要与页脚统计', (WidgetTester tester) async {
    await tester.pumpWidget(_feed(items: <TiebaThreadInfo?>[_thread()]));
    await tester.pump();

    expect(find.byType(ThreadSummary), findsOneWidget);
    expect(find.text('Flutter 3.47 升级踩坑记录，附完整迁移清单'), findsOneWidget);
    expect(find.text('Flutter吧'), findsOneWidget);
    expect(find.text('12000'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('46'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('页脚统计右对齐：吧名长短不影响统计组位置', (WidgetTester tester) async {
    await tester.pumpWidget(_feed(items: <TiebaThreadInfo?>[
      _thread(tid: '1', fname: '猫'),
      _thread(
          tid: '2',
          fname: '一个名字特别长的吧所以要被省略号裁掉才行',
          title: '第二条'),
    ]));
    await tester.pump();

    final Finder stats = find.byIcon(Icons.speaker_notes);
    expect(stats, findsNWidgets(2));
    expect(
      tester.getCenter(stats.at(0)).dx,
      moreOrLessEquals(tester.getCenter(stats.at(1)).dx, epsilon: .5),
      reason: '两条帖子的回复图标应贴同一右边缘，不该随吧名长短漂',
    );

    // 而且是真的贴右边缘：最后一项的右边就是卡片内容区的右边。
    final Rect card = tester.getRect(find.byType(ThreadSummary).at(0));
    final Rect lastNum = tester.getRect(find.text('46').at(0));
    expect(
      card.right - lastNum.right,
      moreOrLessEquals(
          TiebananaMetrics.pageGutter + TiebananaMetrics.cardPadding,
          epsilon: .5),
      reason: '页脚统计组应贴卡片内容区右边缘',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('翻页失败：底部给重试口', (WidgetTester tester) async {
    int retried = 0;
    await tester.pumpWidget(_feed(
      items: <TiebaThreadInfo?>[_thread()],
      moreError: Exception('boom'),
      onLoadMore: () => retried++,
    ));
    await tester.pump();

    expect(find.text('加载失败，点击重试'), findsOneWidget);
    await tester.tap(find.text('加载失败，点击重试'));
    expect(retried, 1);
    expect(tester.takeException(), isNull);
  });
}
