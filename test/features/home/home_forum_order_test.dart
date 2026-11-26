// 首页吧标签拖动排序回归：
// - 长按抬起后跟手移动，其余标签实时换位（挤开），松手才保存顺序；
// - 没有真的移动过时不写存储。
import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/forum/state/forum_state.dart';
import 'package:tiebanana/features/history/models/view_history_page_model.dart';
import 'package:tiebanana/features/home/widgets/forum_tag.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

/// 只记录排序结果，不发网络请求。
class _RecordingForumState extends ForumState {
  _RecordingForumState(this._forums);

  final List<LikeForumInfo> _forums;
  List<LikeForumInfo>? saved;

  @override
  List<LikeForumInfo> get forums => _forums;

  @override
  Future<void> refresh() async {}

  @override
  void saveForumOrder(List<LikeForumInfo> ordered) {
    saved = List<LikeForumInfo>.of(ordered);
    _forums
      ..clear()
      ..addAll(ordered);
  }
}

LikeForumInfo _forum(String name) => LikeForumInfo(
      forumId: name,
      avatar: '',
      forumName: name,
      isSign: '1',
      levelId: '4',
    );

Widget _app(ForumState forumState, {bool scaled = false}) {
  return MultiProvider(
    providers: <ChangeNotifierProvider<APPSettingProvider>>[
      ChangeNotifierProvider<APPSettingProvider>(
          create: (BuildContext context) => APPSettingProvider()),
    ],
    child: ChangeNotifierProvider<ForumState>.value(
      value: forumState,
      child: MaterialApp(
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        builder: scaled
            ? (context, child) => FittedBox(
                  child: SizedBox(width: 400, height: 300, child: child),
                )
            : null,
        home: Scaffold(
          body: TagPan(historyLoader: () => <ViewHistoryPageModel>[]),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
  });

  testWidgets('长按拖动：其余标签实时挤开，松手后才保存顺序', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();

    final _RecordingForumState forumState = _RecordingForumState(
      <LikeForumInfo>[_forum('吧A'), _forum('吧B'), _forum('吧C'), _forum('吧D')],
    );
    addTearDown(forumState.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(forumState));
    await tester.pumpAndSettle();

    final Offset first = tester.getCenter(find.text('吧A'));
    final Offset second = tester.getCenter(find.text('吧B'));
    expect(second.dx, greaterThan(first.dx));

    final TestGesture gesture = await tester.startGesture(first);
    await tester.pump(const Duration(milliseconds: 420));

    // 长按抬起后，被拖的吧由浮层跟手绘制，网格里留出空位。
    await gesture.moveTo(second);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 吧B 已经被挤到第一格，吧A 跟着手指停在原来吧B 的位置。
    expect(tester.getCenter(find.text('吧B')).dx, closeTo(first.dx, 1));
    // 网格里留空的那一份 + 浮层里跟手的一份。
    expect(find.text('吧A'), findsNWidgets(2));
    // 还没松手，不落库。
    expect(forumState.saved, isNull);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(forumState.saved, isNotNull);
    expect(
      forumState.saved!.map((LikeForumInfo f) => f.forumName).toList(),
      <String>['吧B', '吧A', '吧C', '吧D'],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('长按后原地松手：顺序不变、不写存储', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();

    final _RecordingForumState forumState = _RecordingForumState(
      <LikeForumInfo>[_forum('吧A'), _forum('吧B')],
    );
    addTearDown(forumState.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(forumState));
    await tester.pumpAndSettle();

    final TestGesture gesture =
        await tester.startGesture(tester.getCenter(find.text('吧A')));
    await tester.pump(const Duration(milliseconds: 420));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(forumState.saved, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('缩放视口中浮层、挤开空位和自动滚动后的落点一致', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    final state = _RecordingForumState(
      List.generate(80, (i) => _forum('吧$i')),
    );
    addTearDown(state.dispose);
    await tester.pumpWidget(_app(state, scaled: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('展开全部 80 个'));
    await tester.pumpAndSettle();

    Finder tag(String id) => find.byWidgetPredicate(
        (w) => w is ForumTag && w.info.forumId == id && !w.dragging);
    final first = tester.getCenter(tag('吧0'));
    final target = tester.getCenter(tag('吧7'));
    final gesture = await tester.startGesture(first);
    await tester.pump(const Duration(milliseconds: 420));
    // 外层放大两倍，上浮 12 个布局像素对应 24 个屏幕像素。
    await gesture.moveTo(target + const Offset(0, 24));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    void expectAligned() {
      final floating =
          find.byWidgetPredicate((w) => w is ForumTag && w.dragging);
      expect(
          (tester.getCenter(floating) - tester.getCenter(tag('吧0'))).distance,
          lessThan(1));
    }

    expectAligned();
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    final viewport = tester.getRect(find.byType(Scrollable).first);
    await gesture.moveTo(Offset(target.dx, viewport.bottom - 6));
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(position.pixels, greaterThan(0));
    // 离开边缘停止滚动，再把浮层中心对准当前某个槽位中心。
    await gesture.moveTo(Offset(target.dx, viewport.center.dy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final hiddenCenter = tester.getCenter(tag('吧0'));
    await gesture.moveTo(hiddenCenter + const Offset(0, 24));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expectAligned();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(state.saved, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('拖到视口底部会自动向下滚动，吧多了也能拖到底', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();

    final _RecordingForumState forumState = _RecordingForumState(
      List<LikeForumInfo>.generate(40, (int i) => _forum('吧$i')),
    );
    addTearDown(forumState.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(forumState));
    await tester.pumpAndSettle();

    // 展开全部，让网格高度超过一屏，必须滚动才够得着后面的格子。
    await tester.tap(find.text('展开全部 40 个'));
    await tester.pumpAndSettle();

    final ScrollableState scrollable =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    final Rect viewport = tester.getRect(find.byType(Scrollable).first);
    expect(scrollable.position.pixels, 0);

    final TestGesture gesture =
        await tester.startGesture(tester.getCenter(find.text('吧0')));
    await tester.pump(const Duration(milliseconds: 420));

    // 按住不放，把卡片贴到视口下沿：应当自己往下滚。
    await gesture.moveTo(Offset(viewport.center.dx, viewport.bottom - 6));
    await tester.pump();
    for (int i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(scrollable.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);

    await gesture.up();
    await tester.pumpAndSettle();

    // 自动滚过之后落位，被拖的吧已经离开第一位。
    expect(forumState.saved, isNotNull);
    expect(forumState.saved!.first.forumName, isNot('吧0'));
    expect(tester.takeException(), isNull);
  });
}
