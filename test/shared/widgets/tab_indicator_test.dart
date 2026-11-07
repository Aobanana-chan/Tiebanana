// 页签药丸的几何回归：TabBar 交进来的是「标签宽 × 整条页签栏」，
// 药丸高度必须自己定，否则两个字的页签会撑成一颗球（高度 ≈ 宽度）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/tiebanana_tab_indicator.dart';

/// TabBar 实际交给指示器的矩形：宽度是标签自身，高度是整条页签栏
/// （`Tab` 恒为 `kTabHeight` 46 + 指示器权重 2，配 `labelPadding: 17` 时宽 62）。
Rect _labelRect({double width = 28, double height = 48}) =>
    Rect.fromLTWH(100, 0, width, height);

void main() {
  const TiebananaPillTabIndicator indicator =
      TiebananaPillTabIndicator(color: Color(0xFF123456));

  test('药丸高度不跟着页签栏走', () {
    final Rect pill = indicator.pillRect(_labelRect());

    expect(pill.height, TiebananaPillTabIndicator.defaultHeight);
    expect(pill.height, lessThan(_labelRect().height),
        reason: '页签栏比药丸高，药丸要留在里面');
  });

  test('两个字宽的页签不会画成球', () {
    final Rect pill = indicator.pillRect(_labelRect(width: 28));

    expect(pill.width, 28 + 14 * 2, reason: '宽度按概念图的 padding:0 14px 外扩');
    expect(pill.width / pill.height, greaterThan(1.5),
        reason: '药丸得明显比高度宽，不然看着就是个圆');
  });

  test('药丸垂直居中在页签栏里', () {
    final Rect label = _labelRect(height: 48);
    final Rect pill = indicator.pillRect(label);

    expect(pill.center.dy, label.center.dy);
    expect(pill.top - label.top, label.bottom - pill.bottom);
    expect(pill.top - label.top,
        (48 - TiebananaPillTabIndicator.defaultHeight) / 2);
  });

  test('页签栏比药丸还矮时不溢出', () {
    final Rect pill = indicator.pillRect(_labelRect(height: 20));

    expect(pill.height, 20);
    expect(pill.top, 0);
  });

  testWidgets('页签栏高度贴着药丸，不空出一圈', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          body: Builder(
            builder: (BuildContext context) => TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: TiebananaPillTabIndicator(
                  color: TiebananaTokens.of(context).primaryContainer),
              tabs: const <Widget>[
                Tab(height: TiebananaPillTabIndicator.tabHeight, text: '回复'),
                Tab(height: TiebananaPillTabIndicator.tabHeight, text: '@我'),
              ],
            ),
          ),
        ),
      ),
    ));

    final double stripHeight = tester.getSize(find.byType(TabBar)).height;
    // tabHeight 已经把 TabBar 垫在页签下面的 indicatorWeight(2) 提前扣掉了，
    // 所以页签栏正好是药丸高度。
    expect(stripHeight, TiebananaPillTabIndicator.defaultHeight);
    expect(stripHeight, lessThan(48), reason: '别又长回 Tab 默认的 46 + 2');
    // 药丸正好填满页签栏，上下都不留空。
    final Rect pill = indicator.pillRect(Rect.fromLTWH(0, 0, 28, stripHeight));
    expect(pill.top, 0);
    expect(pill.bottom, stripHeight);
  });
}
