// 动态页「回复：」卡片（方案 B：原帖语境前置 + 回复跟进）回归测试。
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_test/flutter_test.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/recommend/pages/recommend_page.dart';
import 'package:tiebanana/shared/content/thread_preview_content.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

import '../../support/fake_thread.dart';

Widget _app(
  Widget child, {
  List<ThreadPageRouterData>? pushed,
  double width = 390,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: TiebananaTheme.light(seedOf('blue'), 16),
    onGenerateRoute: (RouteSettings settings) {
      if (settings.name == PageRouter.threadPage) {
        pushed?.add(settings.arguments! as ThreadPageRouterData);
        return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('原帖详情页')),
        );
      }
      return null;
    },
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 844)),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('方案 B：前置原帖锚点条位于回复正文上方，并剥离「回复：」前缀', (WidgetTester tester) async {
    final TiebaThreadInfo item = fakeRecommendThread(
      tid: '11210767175',
      title: '回复：时狱篇一周目打完了，简单写点感想',
      fname: '机战',
      text: '这关我也是重打了两次才过。',
      authorName: '阿橘',
      isReply: true,
      originTitle: '时狱篇一周目打完了，简单写点感想',
    );

    await tester.pumpWidget(_app(RecommendFeed(
      items: <TiebaThreadInfo?>[item],
      loading: false,
      error: null,
      notLoggedIn: false,
      loadingMore: false,
      moreError: null,
      scrollController: ScrollController(),
      onRefresh: () async {},
      onResumeTap: () async {},
      onRetry: () {},
      onLoadMore: () {},
    )));
    await tester.pump();

    expect(find.text('回复原帖'), findsOneWidget);
    expect(find.text('回复：时狱篇一周目打完了，简单写点感想'), findsNothing);
    expect(
      find.byWidgetPredicate((Widget w) =>
          w is ExtendedText && w.data == '时狱篇一周目打完了，简单写点感想'),
      findsOneWidget,
    );

    final Rect tagRect = tester.getRect(find.text('回复原帖'));
    final Rect excerptRect =
        tester.getRect(find.byType(ThreadPreviewExcerpt).first);
    expect(tagRect.bottom, lessThan(excerptRect.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('未传 originTitle 时自动从 title 剥离前缀；点锚点条或整卡打开原帖',
      (WidgetTester tester) async {
    final List<ThreadPageRouterData> pushed = <ThreadPageRouterData>[];
    final TiebaThreadInfo item = fakeRecommendThread(
      tid: '11210767175',
      title: '回复：时狱篇一周目打完了，简单写点感想',
      fname: '机战',
      text: '这关我也是重打了两次才过。',
      isReply: true,
      originTitle: '',
    );

    await tester.pumpWidget(_app(
      RecommendFeed(
        items: <TiebaThreadInfo?>[item],
        loading: false,
        error: null,
        notLoggedIn: false,
        loadingMore: false,
        moreError: null,
        scrollController: ScrollController(),
        onRefresh: () async {},
        onResumeTap: () async {},
        onRetry: () {},
        onLoadMore: () {},
      ),
      pushed: pushed,
    ));
    await tester.pump();

    await tester.tap(find.text('回复原帖'));
    await tester.pumpAndSettle();
    expect(pushed.single.kz, '11210767175');
    expect(pushed.single.pid, isNull);
  });

  testWidgets('桌面分栏模式：点卡片正文选中预览，点「回复原帖」直接打开原帖',
      (WidgetTester tester) async {
    final List<ThreadPageRouterData> pushed = <ThreadPageRouterData>[];
    TiebaThreadInfo? selected;
    final TiebaThreadInfo item = fakeRecommendThread(
      tid: '11210767175',
      title: '回复：时狱篇一周目打完了，简单写点感想',
      fname: '机战',
      text: '这关我也是重打了两次才过。',
      isReply: true,
      originTitle: '时狱篇一周目打完了，简单写点感想',
    );

    await tester.pumpWidget(_app(
      SizedBox(
        width: 380,
        child: RecommendFeed(
          items: <TiebaThreadInfo?>[item],
          loading: false,
          error: null,
          notLoggedIn: false,
          loadingMore: false,
          moreError: null,
          scrollController: ScrollController(),
          onRefresh: () async {},
          onResumeTap: () async {},
          onRetry: () {},
          onLoadMore: () {},
          desktop: true,
          selectedThreadId: '11210767175',
          onSelectThread: (TiebaThreadInfo info) => selected = info,
        ),
      ),
      pushed: pushed,
      width: 1200,
    ));
    await tester.pump();

    await tester.tap(find.byType(ThreadPreviewExcerpt).first);
    await tester.pump();
    expect(selected?.id, '11210767175');
    expect(pushed, isEmpty);

    await tester.tap(find.text('回复原帖'));
    await tester.pumpAndSettle();
    expect(pushed.single.kz, '11210767175');
    expect(pushed.single.pid, isNull);
  });

  for (final bool desktop in [false, true]) {
    testWidgets('有回复 ID 时，卡片和锚点均定位回复（桌面：$desktop）',
        (WidgetTester tester) async {
      final pushed = <ThreadPageRouterData>[];
      await tester.pumpWidget(_app(
        RecommendFeed(
          items: [
            fakeRecommendThread(
              tid: '11210767175',
              title: '回复：原帖标题',
              text: '目标回复正文',
              isReply: true,
              replyPostId: '154167058515',
            ),
          ],
          loading: false,
          error: null,
          notLoggedIn: false,
          loadingMore: false,
          moreError: null,
          scrollController: ScrollController(),
          onRefresh: () async {},
          onResumeTap: () async {},
          onRetry: () {},
          onLoadMore: () {},
          desktop: desktop,
          onSelectThread: desktop ? (_) => fail('应直接定位回复') : null,
        ),
        pushed: pushed,
      ));

      for (final target in [
        find.byType(ThreadPreviewExcerpt).first,
        find.text('回复原帖'),
      ]) {
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(pushed.last.kz, '11210767175');
        expect(pushed.last.pid, '154167058515');
        Navigator.of(tester.element(find.text('原帖详情页'))).pop();
        await tester.pumpAndSettle();
      }
      expect(pushed, hasLength(2));
    });
  }

  testWidgets('字段缺失与极端长度降级不溢出：无原帖标题、无回复正文、超长昵称与长标题',
      (WidgetTester tester) async {
    final List<TiebaThreadInfo?> items = <TiebaThreadInfo?>[
      fakeRecommendThread(
        tid: '101',
        title: '回复：',
        fname: '机战',
        text: '确实，这个思路比官方攻略省事多了。',
        isReply: true,
        originTitle: '',
      ),
      fakeRecommendThread(
        tid: '102',
        title: '回复：时狱篇一周目打完了，简单写点感想',
        fname: '机战',
        authorName: '',
        isReply: true,
        originTitle: '时狱篇一周目打完了，简单写点感想',
        contents: const <TiebaPostContent>[],
      ),
      fakeRecommendThread(
        tid: '103',
        title: '回复：长标题测试',
        fname: '机战',
        authorName: '风间真一朗名字超级长的时候会怎么截断才不会把吧名挤掉',
        text: '第三回合增援直接把后排奶妈全卡死了，后来换了加移动力的芯片才勉强保住，另外这几个配装截图给你参考，记得带够精神回复。',
        isReply: true,
        originTitle: '请问高难模式第 32 话全 SR 达成路线是不是必须提前两回合往右上角冲锋，否则来不及？',
      ),
    ];

    await tester.pumpWidget(_app(
      RecommendFeed(
        items: items,
        loading: false,
        error: null,
        notLoggedIn: false,
        loadingMore: false,
        moreError: null,
        scrollController: ScrollController(),
        onRefresh: () async {},
        onResumeTap: () async {},
        onRetry: () {},
        onLoadMore: () {},
        desktop: true,
      ),
      width: 380,
    ));
    await tester.pump();

    expect(
      find.byWidgetPredicate(
          (Widget w) => w is ExtendedText && w.data == '机战吧的帖子'),
      findsOneWidget,
    );
    expect(find.text('贴吧用户'), findsOneWidget);
    expect(find.text('发表了一条回复'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
