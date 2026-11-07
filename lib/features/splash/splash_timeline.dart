import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart' show immutable;

/// 时间轴上的一个节点（单位：**设计毫秒**）。
///
/// 「设计毫秒」= `design/splash/splash.html` 那条时间轴上的时刻。
/// 真机时长由 [SplashTiming] 压缩，但所有节点数值都保持与概念图一致，便于逐帧核对。
@immutable
class Beat {
  const Beat(this.from, this.to);

  final double from;
  final double to;

  double get span => to - from;
}

/// 与 `design/splash/splash.html` 的 `T` 表**一一对应**。
/// 改动画之前先改概念图，然后把这里的数值同步过来。
class SplashBeats {
  const SplashBeats._();

  // ① 蓝底浮现 · 光晕
  static const Beat glow = Beat(0, 1200);

  // ② 写「贴」+ 起字标
  static const Beat bei = Beat(260, 780);
  static const Beat ghostV = Beat(660, 920);
  static const Beat ghostH = Beat(840, 1050);
  static const Beat tieba = Beat(1000, 1440);
  static const Beat kou = Beat(1060, 1480);

  // ③ 顶替
  static const Beat banana = Beat(1480, 1980);
  static const Beat evictV = Beat(1650, 1950);
  static const Beat leaf = Beat(1680, 2040);
  static const Beat evictH = Beat(1780, 2030);

  // ④ 落定 · 字标合拢 · 交接
  static const Beat impact = Beat(1970, 2110);
  static const Beat sparks = Beat(1975, 2495);
  static const Beat nana = Beat(2060, 2540);
  static const Beat green = Beat(2280, 2790);
  static const Beat hold = Beat(2790, 3020);
  static const Beat out = Beat(3020, 3300);
}

/// 真机时长。
///
/// 概念图那条轴是 3.3s —— 那是为了逐帧审阅方便，真机太长了。
/// 这里整体压到 [_k] 倍（≈ 2.3s），并且只在**冷启动**播（热启动直接进入首页）。
class SplashTiming {
  const SplashTiming._();

  static const double _k = 0.70;

  /// 前四拍：0 → 落定 / 字标合上（对应设计轴的 [SplashBeats.hold].from）。
  static final Duration introDuration =
      Duration(milliseconds: (SplashBeats.hold.from * _k).round());

  /// 交接：开屏推走 + 首屏浮起（对应设计轴的 [SplashBeats.hold].from → [SplashBeats.out].to）。
  static final Duration handoffDuration = Duration(
      milliseconds:
          ((SplashBeats.out.to - SplashBeats.hold.from) * _k).round());

  /// 底部加载点的呼吸周期。
  static const Duration dotPeriod = Duration(milliseconds: 620);

  /// 前四拍里 `t` 的取值范围。
  static const double introFrom = 0;
  static final double introTo = SplashBeats.hold.from;

  /// 后续启动点击后，从落定波纹开始播放最后一段。
  static final double skipTo = SplashBeats.impact.from;

  /// 交接里 `t` 的取值范围。
  static final double handoffFrom = SplashBeats.hold.from;
  static final double handoffTo = SplashBeats.out.to;
}

/// 缓动曲线，数值与概念图里的 `cubic-bezier(...)` 一致。
class SplashCurves {
  const SplashCurves._();

  /// 快速起步 → 缓收。大多数入场的默认。
  static const Curve out = Cubic(0, 0, .22, 1);

  /// 更狠的缓收，香蕉水平分量用它。
  static const Curve expo = Cubic(.16, 1, .30, 1);

  /// 加速下坠（重力感）。
  static const Curve gravity = Cubic(.55, 0, 1, .45);

  static const Curve inOut = Cubic(.42, 0, .58, 1);

  /// 过冲回弹 —— 「灵动」主要靠它。
  static const Curve back = Cubic(.34, 1.56, .64, 1);

  /// 轻过冲，给旋转用。
  static const Curve soft = Cubic(.22, 1.18, .36, 1);
}

/// 概念图里的 `seg(t, a, b)`：把 [t] 映射到 [a, b] 上的 0–1 进度。
double seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

/// `seg` + 缓动。
double ease(double t, double a, double b, Curve curve) =>
    curve.transform(seg(t, a, b));

double mix(double a, double b, double p) => a + (b - a) * p;

/// 关键帧上的一个停靠点。
@immutable
class Stop {
  const Stop(this.at, this.value);

  /// 0–1。
  final double at;
  final double value;
}

/// 概念图里的 `kf(t, stops)`：分段插值，段内用同一个缓动。
/// 用来做「荡进来 → 过冲 → 回稳」这种多段摆动的旋转。
double kf(double t, List<Stop> stops, [Curve curve = SplashCurves.inOut]) {
  if (t <= stops.first.at) return stops.first.value;
  for (int i = 1; i < stops.length; i++) {
    if (t <= stops[i].at) {
      final double p = seg(t, stops[i - 1].at, stops[i].at);
      return mix(stops[i - 1].value, stops[i].value, curve.transform(p));
    }
  }
  return stops.last.value;
}

/// 角度转弧度。
double deg(double d) => d * math.pi / 180;

/// 概念图里 `E.out` 之类直接作用在 0–1 进度上的写法。
double curveAt(Curve curve, double p) => curve.transform(p.clamp(0.0, 1.0));
