import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:tiebanana/features/splash/splash_brand.dart';
import 'package:tiebanana/features/splash/splash_timeline.dart';

/// 字标 `Tiebanana`。
///
/// 拆成 9 个单字分别驱动，所以「贴上」和「变绿」都能精确到某一颗字：
/// - `Tieba`（0–4）**提前出现**：逐字上浮，在写「贴」的同时就起来了；
/// - `nana`（5–8）**冲击环之后贴上**：逐字从右侧滑入 + 回弹，
///   同时整串让回半个「nana」的宽度，两边合拢；
/// - 第 3–8 个字**正好是 `banana`**，合拢之后从左往右白 → 绿。
///
/// 字体是图标同款 ZCOOL 快乐体（「贴」的轮廓就是这个字体的字形），
/// 已经子集化成只含这 9 个字母，见 `assets/fonts/` 与
/// `docs/icon/subset_wordmark_font.py`。
class SplashWordmark extends StatelessWidget {
  const SplashWordmark({super.key, required this.t, required this.fontSize});

  /// 设计毫秒（0–3300）。
  final double t;

  /// 字号。概念图是 390 宽屏幕上的 31px。
  final double fontSize;

  static const String fontFamily = 'TiebananaWordmark';
  static const String _word = 'Tiebanana';

  /// 概念图里的字号，用来把位移量按比例换算。
  static const double _refFontSize = 31;

  /// 「Tieba」= 0–4。
  static const int _tiebaCount = 5;

  /// 第 3–8 个字正好是 `banana`。
  static const int _greenFrom = 3;

  /// 单字上浮 / 滑入的错开间隔（毫秒）。
  static const double _tiebaStaggerMs = 40;
  static const double _nanaStaggerMs = 45;

  @override
  Widget build(BuildContext context) {
    // 位移量在概念图里是按 31px 字号给的，这里按实际字号等比缩放。
    final double u = fontSize / _refFontSize;

    final TextStyle base = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: fontSize * .035,
      height: 1.15,
      color: SplashBrand.ink,
      // 显式写死：品牌字标不该继承任何祖先的装饰（尤其是 WidgetsApp 那个
      // 黄色下划线的错误样式）
      decoration: TextDecoration.none,
    );

    // 让位多少要靠**实测**：`.lat` 的宽度从一开始就是整词宽度，
    // 所以「只有 Tieba」的时候它是偏左的，得先右推半个「nana」宽度。
    final double nanaWidth = _measure(_word.substring(_tiebaCount), base);

    final double join = ease(t, SplashBeats.nana.from, SplashBeats.nana.to,
        SplashCurves.back);
    // 贴上的那一下：整串轻微一弹
    final double pulse = math.sin(math.pi *
            seg(t, SplashBeats.nana.to - 60, SplashBeats.nana.to + 170)) *
        .045;
    // 交接时字标比整屏先走一步
    final double alive = 1 -
        ease(t, SplashBeats.out.from + 60, SplashBeats.out.from + 260,
            SplashCurves.gravity);

    final List<Widget> letters = <Widget>[];
    for (int i = 0; i < _word.length; i++) {
      double opacity;
      double dx = 0;
      double dy = 0;
      double rot = 0;

      if (i < _tiebaCount) {
        // 「Tieba」：逐字上浮
        final double a = SplashBeats.tieba.from + i * _tiebaStaggerMs;
        final double p = ease(t, a, a + 400, SplashCurves.out);
        opacity = p;
        dy = mix(16, 0, p) * u;
      } else {
        // 「nana」：从右侧滑入 + 轻微旋转，落位带回弹
        final double a =
            SplashBeats.nana.from + (i - _tiebaCount) * _nanaStaggerMs;
        final double raw = seg(t, a, a + 320);
        opacity = ease(t, a, a + 150, SplashCurves.out);
        dx = mix(66, 0, curveAt(SplashCurves.back, raw)) * u;
        rot = deg(mix(10, 0, curveAt(SplashCurves.out, raw)));
      }

      // `banana` 那一段渐变变绿。
      // 相位比 nana 的落位晚一点点 —— 于是每一颗「刚贴上就变绿」，
      // 绿色的波跟着到达的波走。
      Color color = SplashBrand.ink;
      if (i >= _greenFrom) {
        final double a =
            SplashBeats.green.from + (i - _greenFrom) * _nanaStaggerMs;
        color = Color.lerp(
          SplashBrand.ink,
          SplashBrand.wordmarkGreen,
          curveAt(SplashCurves.inOut, seg(t, a, a + 280)),
        )!;
      }

      letters.add(Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.rotate(
          angle: rot,
          child: Text(
            _word[i],
            // 品牌字标使用固定字号，保持版式
            textScaler: TextScaler.noScaling,
            style: base.copyWith(
              color: color.withValues(alpha: (opacity * alive).clamp(0, 1)),
              shadows: <Shadow>[
                Shadow(
                  color: SplashBrand.wordmarkShadow
                      .withValues(alpha: .35 * (opacity * alive).clamp(0, 1)),
                  blurRadius: 14 * u,
                  offset: Offset(0, 2 * u),
                ),
              ],
            ),
          ),
        ),
      ));
    }

    return Transform.translate(
      offset: Offset(nanaWidth / 2 * (1 - join), 0),
      child: Transform.scale(
        scale: 1 + pulse,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: letters,
        ),
      ),
    );
  }

  static double _measure(String text, TextStyle style) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    return tp.width;
  }
}
