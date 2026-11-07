// 吧内搜索的行为：请求参数（fname / 排序 / 范围）、空关键词、翻页。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/forum/pages/forum_search_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/highlight_text.dart';

/// 记录每次搜索的参数，行为断言都看它。
class _RecordingApi extends DemoTiebaApi {
  _RecordingApi() : super(latency: Duration.zero);

  int calls = 0;
  String? lastKeyword;
  String? lastFname;
  int? lastOrder;
  int? lastFilter;
  int? lastPn;

  @override
  Future<SearchPostPage> searchPost(String keywords,
      {int pn = 1,
      int order = 0,
      int filter = 1,
      int ct = 2,
      String? fname}) {
    calls++;
    lastKeyword = keywords;
    lastFname = fname;
    lastOrder = order;
    lastFilter = filter;
    lastPn = pn;
    return super.searchPost(keywords,
        pn: pn, order: order, filter: filter, ct: ct, fname: fname);
  }
}

/// 分页用：第一页给 20 条并声明有下一页，第二页给 3 条收尾。
class _PagingApi extends DemoTiebaApi {
  _PagingApi() : super(latency: Duration.zero);

  int calls = 0;

  @override
  Future<SearchPostPage> searchPost(String keywords,
      {int pn = 1,
      int order = 0,
      int filter = 1,
      int ct = 2,
      String? fname}) async {
    calls++;
    final int count = pn == 1 ? 20 : 3;
    return SearchPostPage(
      posts: <TiebaSearchPost>[
        for (int i = 1; i <= count; i++)
          TiebaSearchPost(
            type: 1,
            tid: '$pn-$i',
            pid: '9$i',
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

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: TiebananaTheme.light(seedOf('blue'), 16),
    home: child,
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('默认走吧内搜索并带上 fname', (WidgetTester tester) async {
    final _RecordingApi api = _RecordingApi();
    Global.tiebaAPI = api;

    await _pump(tester,
        const ForumSearchPage(forumName: 'Flutter', initialKeyword: 'flutter'));

    expect(api.calls, 1);
    expect(api.lastKeyword, 'flutter');
    expect(api.lastFname, 'Flutter');
    // 默认相关度 + 只看主题帖。
    expect(api.lastOrder, 2);
    expect(api.lastFilter, 1);
    expect(api.lastPn, 1);
  });

  testWidgets('空关键词停在引导态，不发请求', (WidgetTester tester) async {
    final _RecordingApi api = _RecordingApi();
    Global.tiebaAPI = api;

    await _pump(tester, const ForumSearchPage(forumName: 'Flutter'));

    expect(api.calls, 0);
    expect(find.text('搜一搜 Flutter吧'), findsOneWidget);
  });

  testWidgets('关掉「只看主题帖」按 filter=0 重新搜', (WidgetTester tester) async {
    final _RecordingApi api = _RecordingApi();
    Global.tiebaAPI = api;

    await _pump(tester,
        const ForumSearchPage(forumName: 'Flutter', initialKeyword: 'flutter'));
    expect(api.calls, 1);
    expect(api.lastFilter, 1);

    await tester.tap(find.text('只看主题帖'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(api.calls, 2);
    expect(api.lastFilter, 0);
    expect(api.lastOrder, 2);
  });

  testWidgets('改关键词点「搜索」按新词重搜', (WidgetTester tester) async {
    final _RecordingApi api = _RecordingApi();
    Global.tiebaAPI = api;

    await _pump(tester,
        const ForumSearchPage(forumName: 'Flutter', initialKeyword: 'flutter'));

    await tester.enterText(find.byType(TextField), 'objectbox');
    await tester.tap(find.text('搜索'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(api.calls, 2);
    expect(api.lastKeyword, 'objectbox');
    expect(api.lastFname, 'Flutter');
  });

  testWidgets('高亮：命中片段加粗上色，没命中退回纯文本', (WidgetTester tester) async {
    const Key hit = Key('hl-hit');
    const Key miss = Key('hl-miss');
    await tester.pumpWidget(MaterialApp(
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: const Scaffold(
        body: Column(
          children: <Widget>[
            HighlightText('Flutter 升级', key: hit, keyword: 'flutter'),
            HighlightText('没有命中的内容', key: miss, keyword: 'flutter'),
          ],
        ),
      ),
    ));

    Text textOf(Key key) => tester.widget<Text>(find.descendant(
        of: find.byKey(key), matching: find.byType(Text)));

    final List<InlineSpan>? spans =
        (textOf(hit).textSpan as TextSpan?)?.children;
    expect(spans, isNotNull);
    expect(spans!.length, 2);
    expect((spans.first as TextSpan).text, 'Flutter');
    expect((spans.first as TextSpan).style?.fontWeight, FontWeight.w700);
    // 高亮色就是强调色，不是正文色。
    expect((spans.first as TextSpan).style?.color,
        TiebananaTokens.of(tester.element(find.byKey(hit))).primary);
    expect((spans.last as TextSpan).style, isNull);

    expect(textOf(miss).data, '没有命中的内容');
  });

  testWidgets('滚到底自动翻页', (WidgetTester tester) async {
    final _PagingApi api = _PagingApi();
    Global.tiebaAPI = api;

    await _pump(tester,
        const ForumSearchPage(forumName: 'Flutter', initialKeyword: 'flutter'));
    expect(api.calls, 1);
    expect(find.text('第 1 页第 1 条 flutter'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(api.calls, 2);

    // 追加的条目在视口下方，再滚一段才会被 ListView 构建出来。
    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pump();
    expect(find.text('第 2 页第 3 条 flutter'), findsOneWidget);
  });
}
