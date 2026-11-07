import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/thread/data/thread_cache_codec.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/features/thread/widgets/thread_poll_card.dart';

TiebaPoll _poll(
        {bool? voted = true,
        int? total = 192,
        int? endTime,
        int? remaining = -1,
        int? optionCount = 3}) =>
    TiebaPoll(
      title: '希望优先改善哪些体验？',
      multiple: true,
      participantCount: 128,
      totalVotes: total,
      hasVoted: voted,
      selectedIds: {9, 23},
      endTime: endTime,
      remainingSeconds: remaining,
      optionCount: optionCount,
      options: const [
        TiebaPollOption(id: 9, text: '阅读体验', votes: 72),
        TiebaPollOption(id: 23, text: '图片加载', votes: 96),
        TiebaPollOption(id: 45, text: '消息通知', votes: 24)
      ],
    );

TiebaPoll _duelPoll({bool? voted = true}) => TiebaPoll(
      title: '最喜欢哪个兔子',
      multiple: false,
      participantCount: 3225,
      totalVotes: 3225,
      hasVoted: voted,
      selectedIds: voted == true ? {2} : const {},
      remainingSeconds: -1,
      optionCount: 2,
      options: const [
        TiebaPollOption(id: 1, text: '兔子妈😍（747）', votes: 1455),
        TiebaPollOption(id: 2, text: '兔子妹😍（644）', votes: 1770),
      ],
    );

Future<void> _pump(WidgetTester tester, TiebaPoll? poll,
    {bool dark = false,
    double scale = 1,
    double width = 250,
    Future<void> Function(Set<int>)? onVote}) async {
  await tester.pumpWidget(MaterialApp(
    theme: dark
        ? TiebananaTheme.dark(seedOf('blue'), 16)
        : TiebananaTheme.light(seedOf('blue'), 16),
    home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
            body: SingleChildScrollView(
                child: Center(
                    child: SizedBox(
                        width: width,
                        child: ThreadPollCard(
                            poll: poll, compact: true, onVote: onVote)))))),
  ));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('缺少详情显示中性占位，不提供虚假重试按钮', (tester) async {
    await _pump(tester, null);
    expect(find.text('包含投票，暂未获取到详情'), findsOneWidget);
    expect(find.text('重试'), findsNothing);
  });

  testWidgets('两个选项使用蓝方 / 红方阵营，而不是普通列表', (tester) async {
    await _pump(tester, _duelPoll(voted: false));
    expect(find.text('蓝方'), findsOneWidget);
    expect(find.text('红方'), findsOneWidget);
    expect(find.text('VS'), findsOneWidget);
    expect(find.text('暂不支持投票'), findsOneWidget);
    // 未投票不提前暴露占比。
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('红蓝阵营结果展示百分比与票数', (tester) async {
    await _pump(tester, _duelPoll(), scale: 1.6);
    expect(find.text('45%'), findsOneWidget);
    expect(find.text('55%'), findsOneWidget);
    expect(find.text('1455 票'), findsOneWidget);
    expect(find.text('1770 票'), findsOneWidget);
    expect(find.text('你已投票'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
  });

  testWidgets('宽屏两个阵营左右并排且不溢出', (tester) async {
    await _pump(tester, _duelPoll(), width: 360);
    expect(find.text('蓝方'), findsOneWidget);
    expect(find.text('红方'), findsOneWidget);
    expect(find.text('VS'), findsOneWidget);
    expect(find.text('45%'), findsOneWidget);
    expect(find.text('55%'), findsOneWidget);
  });

  testWidgets('只有 two_options 正反方时也走红蓝阵营', (tester) async {
    final p = TiebaPoll(
      title: '辩论',
      multiple: false,
      totalVotes: 30,
      participantCount: 30,
      hasVoted: true,
      selectedIds: {2},
      remainingSeconds: -1,
      pros: const TiebaPollOption(id: 1, text: '正方观点', votes: 10),
      cons: const TiebaPollOption(id: 2, text: '反方观点', votes: 20),
    );
    await _pump(tester, p, width: 360);
    expect(find.text('蓝方'), findsOneWidget);
    expect(find.text('红方'), findsOneWidget);
    expect(find.text('正方观点'), findsOneWidget);
    expect(find.text('反方观点'), findsOneWidget);
    expect(find.text('33%'), findsOneWidget);
    expect(find.text('67%'), findsOneWidget);
  });

  testWidgets('可选状态下点击阵营再提交，回调收到选中项', (tester) async {
    Set<int>? submitted;
    await _pump(tester, _duelPoll(voted: false),
        width: 360, onVote: (Set<int> ids) async => submitted = ids);
    expect(find.text('投票'), findsNWidgets(2)); // 标题 + 按钮
    // 未选择时按钮禁用。
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, '投票'))
            .onPressed,
        isNull);
    await tester.tap(find.text('兔子妹😍（644）'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '投票'));
    await tester.pump();
    expect(submitted, <int>{2});
  });

  testWidgets('多选投票累加选中项，按钮显示数量', (tester) async {
    Set<int>? submitted;
    await _pump(tester, _poll(voted: false),
        width: 360, onVote: (Set<int> ids) async => submitted = ids);
    await tester.tap(find.text('阅读体验'));
    await tester.pump();
    await tester.tap(find.text('图片加载'));
    await tester.pump();
    expect(find.widgetWithText(FilledButton, '投票（2）'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '投票（2）'));
    await tester.pump();
    expect(submitted, <int>{9, 23});
  });

  for (final dark in [false, true]) {
    testWidgets('多选结果：人数和总票数分离、明暗大字号不溢出 $dark', (tester) async {
      await _pump(tester, _poll(), dark: dark, scale: 1.6);
      expect(find.text('128 人参与 · 192 票'), findsOneWidget);
      expect(find.text('72 票 · 38%'), findsOneWidget);
      expect(find.text('96 票 · 50%'), findsOneWidget);
      expect(find.text('24 票 · 12%'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));
      expect(find.text('暂不支持投票'), findsNothing);
    });
  }

  testWidgets('没有写接口，按钮禁用，不产生假成功', (tester) async {
    await _pump(tester, _poll(voted: false));
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.text('你已投票'), findsNothing);
    expect(find.textContaining('72 票'), findsNothing);
  });

  testWidgets('缺失总票数或选项不完整时不编造百分比', (tester) async {
    await _pump(tester, _poll(total: null));
    expect(find.text('72 票'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await _pump(tester, _poll(optionCount: 5));
    expect(find.text('部分选项暂未返回'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('过期未参与也显示结果，不显示提交入口', (tester) async {
    await _pump(tester, _poll(voted: false, endTime: 1));
    expect(find.text('已结束'), findsOneWidget);
    expect(find.text('72 票 · 38%'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  test('缓存保留正反方 two_options，读缓存后仍是红蓝阵营', () {
    final p = TiebaPoll(
      title: '正方与反方',
      totalVotes: 30,
      pros: const TiebaPollOption(id: 1, text: '正方', votes: 10),
      cons: const TiebaPollOption(id: 2, text: '反方', votes: 20),
    );
    final restored = ThreadCacheCodec.readPoll(ThreadCacheCodec.poll(p))!;
    expect(restored.pros?.text, '正方');
    expect(restored.pros?.votes, 10);
    expect(restored.cons?.text, '反方');
    expect(restored.cons?.votes, 20);
  });

  test('缓存保留投票字段、缺失值和选中ID，旧缓存可读', () {
    final p = _poll(total: null);
    final restored = ThreadCacheCodec.readPoll(ThreadCacheCodec.poll(p))!;
    expect(restored.title, p.title);
    expect(restored.selectedIds, {9, 23});
    expect(restored.totalVotes, isNull);
    expect(restored.options[1].votes, 96);
    expect(ThreadCacheCodec.readPoll(null), isNull);
  });
}
