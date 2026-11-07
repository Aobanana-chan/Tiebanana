import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/features/splash/tiebanana_glyph.dart';

Offset _at(double x, double y) => Offset(45.08 + .95 * x, -52.01 + .95 * y);

void main() {
  test('口的上沿连续且没有卜的残笔', () {
    for (double x = 594; x <= 685; x += 2) {
      final double top = 594 + (x - 457) * (555 - 594) / (836 - 457);
      expect(TiebananaGlyph.kouPath.contains(_at(x, top - 1)), isFalse);
      expect(TiebananaGlyph.kouPath.contains(_at(x, top + 1)), isTrue);
    }
    expect(TiebananaGlyph.kouPath.contains(_at(650, 800)), isFalse,
        reason: '保留口的字腔');
  });

  test('卜与口沿真实斜边互补，组合后没有缺笔', () {
    final Path assembled = Path.combine(
        PathOperation.union, TiebananaGlyph.buPath, TiebananaGlyph.kouPath);
    for (double y = 220.5; y < 1055; y += 3) {
      for (double x = 410.5; x < 890; x += 3) {
        final Offset point = _at(x, y);
        // 原字体上沿在卜的两侧略微不共线；修正后统一拉直，忽略该亚像素带。
        final double top = 594 + (x - 457) * (555 - 594) / (836 - 457);
        if ((y - top).abs() < 1) continue;
        expect(
            assembled.contains(point), TiebananaGlyph.zhanPath.contains(point),
            reason: 'em ($x, $y)');
      }
    }
  });

  test('卜的两笔裁剪覆盖完整轮廓', () {
    for (double y = 225.5; y < 595; y += 2) {
      for (double x = 560.5; x < 875; x += 2) {
        final Offset point = _at(x, y);
        if (!TiebananaGlyph.buPath.contains(point)) continue;
        expect(
            TiebananaGlyph.buVRect.contains(point) ||
                TiebananaGlyph.buHRect.contains(point),
            isTrue,
            reason: 'em ($x, $y)');
      }
    }
  });
}
