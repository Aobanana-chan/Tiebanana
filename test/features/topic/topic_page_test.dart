import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/topic/pages/topic_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

void main() {
  testWidgets('话题页渲染原生头图、讨论流和发帖入口', (tester) async {
    await _pump(tester, DemoTiebaApi(latency: Duration.zero));

    expect(tester.takeException(), isNull);
    expect(find.text('#s16分锅投票#'), findsOneWidget);
    expect(find.text('吧友热议'), findsOneWidget);
    expect(find.text('热门'), findsOneWidget);
    expect(find.text('最新'), findsOneWidget);
    expect(find.text('发帖'), findsOneWidget);
  });

  testWidgets('话题头失败时是错误态，不是白屏', (tester) async {
    await _pump(tester, _FailingApi());
    await tester.pumpAndSettle();

    expect(find.text('话题没加载出来'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('话题没有帖子时是空态', (tester) async {
    await _pump(tester, _EmptyApi());
    await tester.pumpAndSettle();

    expect(find.text('还没有相关帖子'), findsOneWidget);
    expect(find.text('刷新'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('切换热门/最新不重置页面，旧列表保留', (tester) async {
    final _SlowSortApi api = _SlowSortApi();
    await _pump(tester, api);

    expect(find.textContaining('主要问题出在哪'), findsWidgets);
    await tester.tap(find.text('最新'));
    await tester.pump();

    // 不是整页加载态：旧列表还在，只有一条细进度条。
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('主要问题出在哪'), findsWidgets);
    expect(find.text('吧友热议'), findsOneWidget);

    api.completeSort();
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('话题内搜索只筛选当前话题帖子', (tester) async {
    await _pump(tester, DemoTiebaApi(latency: Duration.zero));

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '队伍需要补强');
    await tester.pumpAndSettle();

    expect(find.text('搜索结果'), findsOneWidget);
    expect(find.text('1 条'), findsOneWidget);
    expect(find.textContaining('队伍需要补强'), findsWidgets);
    expect(find.textContaining('理性讨论'), findsNothing);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('吧友热议'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('长简介默认收起，显示全部后可展开/收起', (tester) async {
    await _pump(tester, _LongDescApi());

    expect(find.text('显示全部'), findsOneWidget);
    expect(find.text('收起'), findsNothing);

    await tester.tap(find.text('显示全部'));
    await tester.pumpAndSettle();
    expect(find.text('显示全部'), findsNothing);
    expect(find.text('收起'), findsOneWidget);

    await tester.tap(find.text('收起'));
    await tester.pumpAndSettle();
    expect(find.text('显示全部'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('分享面板提供复制链接与浏览器打开', (tester) async {
    await _pump(tester, DemoTiebaApi(latency: Duration.zero));

    await tester.tap(find.byIcon(Icons.ios_share_rounded));
    await tester.pumpAndSettle();

    expect(find.text('分享话题'), findsOneWidget);
    expect(find.text('复制话题链接'), findsOneWidget);
    expect(find.text('在浏览器打开'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(WidgetTester tester, TiebaApi api) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 1200);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final theme = TiebananaTheme.light(seedOf('blue'), 16);
  await tester.pumpWidget(MaterialApp(
    theme: theme,
    home: TopicPageRoute(
      data: const TopicPageRouterData(
        name: 's16分锅投票',
        fid: '17019292',
        forumName: '抗压背锅',
      ),
      api: api,
    ),
  ));
  await tester.pumpAndSettle();
}

class _FailingApi extends DemoTiebaApi {
  _FailingApi() : super(latency: Duration.zero);

  @override
  Future<TiebaTopicDetail> getTopicDetail({
    required String name,
    String topicId = '',
    String fid = '',
    String forumName = '',
  }) async {
    throw StateError('topic detail failed');
  }
}

class _EmptyApi extends DemoTiebaApi {
  _EmptyApi() : super(latency: Duration.zero);

  @override
  Future<TiebaTopicThreadPage> getTopicThreads({
    required String name,
    String topicId = '',
    int page = 1,
    int sort = 1,
    String lastId = '',
  }) async {
    return const TiebaTopicThreadPage(
      threads: <TiebaThreadInfo>[],
      hasMore: false,
      lastId: '',
      currentPage: 1,
    );
  }
}

class _LongDescApi extends DemoTiebaApi {
  _LongDescApi() : super(latency: Duration.zero);

  @override
  Future<TiebaTopicDetail> getTopicDetail({
    required String name,
    String topicId = '',
    String fid = '',
    String forumName = '',
  }) async {
    return TiebaTopicDetail(
      id: topicId.isEmpty ? 'demo-topic' : topicId,
      name: name,
      desc: '这是一段很长的话题简介，用来验证默认只显示三行、底部有半透明渐变遮罩和显示全部按钮。' * 4,
      postNum: '24',
      fid: fid,
      forumName: forumName,
    );
  }
}

class _SlowSortApi extends DemoTiebaApi {
  _SlowSortApi() : super(latency: Duration.zero);

  final Completer<void> _sort2 = Completer<void>();

  void completeSort() {
    if (!_sort2.isCompleted) _sort2.complete();
  }

  @override
  Future<TiebaTopicThreadPage> getTopicThreads({
    required String name,
    String topicId = '',
    int page = 1,
    int sort = 1,
    String lastId = '',
  }) async {
    if (sort == 2) await _sort2.future;
    return super.getTopicThreads(
      name: name,
      topicId: topicId,
      page: page,
      sort: sort,
      lastId: lastId,
    );
  }
}
