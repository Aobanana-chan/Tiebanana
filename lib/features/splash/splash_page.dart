import 'dart:math' as math;

import 'package:flutter/material.dart' show Colors, Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tiebanana/features/splash/splash_brand.dart';
import 'package:tiebanana/features/splash/splash_mark.dart';
import 'package:tiebanana/features/splash/splash_timeline.dart';
import 'package:tiebanana/features/splash/splash_wordmark.dart';

/// 开屏页。**纯展示**：所有状态都从 [t]（设计毫秒，0–3300）算出来，
/// 控制器由 `BootstrapApp` 持有 —— 这样它既能被逐帧驱动，也能在测试里定格任意一帧。
///
/// 布局与 `design/splash/splash.html` 对齐：
/// 图标中心在屏高 40%、字标在 58%、加载点在 78%，图标宽度占屏宽 61%。
class SplashPage extends StatelessWidget {
  const SplashPage({super.key, required this.t});

  /// 设计毫秒。见 [SplashBeats]。
  final double t;

  /// 概念图里的基准屏宽（iPhone 14 那一档）。
  static const double _refWidth = 390;
  static const double _refMarkSize = 238;
  static const double _refWordSize = 31;

  @override
  Widget build(BuildContext context) {
    final double outK =
        ease(t, SplashBeats.out.from, SplashBeats.out.to, SplashCurves.gravity);

    Widget content = _Content(t: t);

    // 交接：整屏向前推走（对应概念图的 `scale(1 + .07 * outK)` + 淡出）
    if (outK > 0) {
      content = Opacity(
        opacity: (1 - outK).clamp(0, 1),
        child: Transform.scale(scale: 1 + .07 * outK, child: content),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 开屏是全屏宝蓝，状态栏图标得是浅色
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: SplashBrand.bgBottom,
      ),
      // 开屏期间拦截点击，避免落到下面已经起好的首屏。
      child: AbsorbPointer(
        // 页面里没有 Material 祖先时，`WidgetsApp` 会把 DefaultTextStyle 设成
        // 那个「红色 + 黄色下划线」的错误样式（`_errorTextStyle`）来提醒你；
        // 字标会原样继承下来。这里补一层透明 Material，把默认文字样式拉回主题。
        child: Material(
          type: MaterialType.transparency,
          child: content,
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double w = c.maxWidth;
        final double h = c.maxHeight;
        // 版式随屏宽等比缩放，但夹住上下限，免得在平板/折叠屏上走形
        final double s = (w / SplashPage._refWidth).clamp(.85, 1.5);
        final double markSize = SplashPage._refMarkSize * s;

        return Stack(
          children: <Widget>[
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // 概念图是 CSS `linear-gradient(168deg, …)`：几乎竖直、略向右下
                  gradient: LinearGradient(
                    begin: Alignment(-.208, -.978),
                    end: Alignment(.208, .978),
                    colors: <Color>[SplashBrand.bgTop, SplashBrand.bgBottom],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: IgnorePointer(child: _Shine(t: t))),
            Positioned(
              left: 0,
              right: 0,
              top: h * .40 - markSize / 2,
              child: Center(
                child: SplashMark(t: t, size: markSize),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: h * .58,
              child: Center(
                child: SplashWordmark(
                  t: t,
                  fontSize: SplashPage._refWordSize * s,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: h * .78,
              child: Center(child: _LoadingDots(t: t, size: 6 * s)),
            ),
          ],
        );
      },
    );
  }
}

/// 缓慢漂移的高光，为宝蓝底增加层次。
///
/// 概念图使用 `mix-blend-mode: soft-light`；这里改用低透明度白光，
/// 视觉效果接近，同时省去一次混合模式的开销。
class _Shine extends StatelessWidget {
  const _Shine({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double s = seg(t, 0, SplashBeats.out.to);
        // 概念图里元素是 150% 见方，位移百分比按元素自身尺寸算
        final double size = c.maxWidth * 1.5;
        final double dx = (-.06 + .12 * s) * size;
        final double dy = (.04 - .09 * s) * size;
        // 亮度也一起呼吸
        final double a = .55 + .45 * math.sin(s * math.pi);
        return Stack(
          children: <Widget>[
            Positioned(
              left: -c.maxWidth * .25 + dx,
              top: -c.maxHeight * .14 + dy,
              width: size,
              height: size,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: <Color>[
                      SplashBrand.ink.withValues(alpha: .085 * a),
                      SplashBrand.ink.withValues(alpha: .025 * a),
                      SplashBrand.ink.withValues(alpha: 0),
                    ],
                    stops: const <double>[0, .55, .72],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 底部三个加载点。开屏动画走完但 `Global.init()` 尚未完成时，
/// 用它提示用户仍在初始化。
class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.t, required this.size});

  final double t;
  final double size;

  @override
  Widget build(BuildContext context) {
    // 与概念图一致：字标起来之后才淡入
    final double appear = ease(t, 2150, 2400, SplashCurves.out);
    final double alive =
        1 - ease(t, SplashBeats.out.from, SplashBeats.out.to, SplashCurves.gravity);
    final double group = (appear * alive * .95).clamp(0, 1);

    return Opacity(
      opacity: group,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(3, (int i) {
          final double phase =
              (t / SplashTiming.dotPeriod.inMilliseconds - i * .17) % 1;
          final double k = .5 - .5 * math.cos(phase * math.pi * 2);
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: size * .58),
            child: Transform.translate(
              offset: Offset(0, -2.4 * k * (size / 6)),
              child: Transform.scale(
                scale: 1 + .2 * k,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SplashBrand.ink
                          .withValues(alpha: .6 * (.35 + .65 * k)),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
