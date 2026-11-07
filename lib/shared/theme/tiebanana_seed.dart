import 'package:flutter/material.dart';

/// 主题种子。
///
/// 整个 App 的配色只由这三个数派生：色相 [hue]、彩度系数 [chroma]、
/// 以及亮色模式下主色的明度 [primaryLightness]。
///
/// [primaryLightness] 按色相单独设置：HSL 明度不等于感知亮度。
/// 同一明度下青 / 薄荷 / 绿作正文只有约 3.4 对比度，蓝 / 粉则超过 7:1。
///
/// 各值对应的对比度（正文对底色）：
/// blue 8.6 / cyan 6.2 / teal 6.2 / green 6.0 / yellow 5.0 / pink 7.3 / white 7.0
@immutable
class TiebananaSeed {
  const TiebananaSeed({
    required this.name,
    required this.hue,
    required this.chroma,
    required this.primaryLightness,
  });

  /// 与 `APPSetting.theme` 存的值一致。
  final String name;

  /// 色相（0~360）。
  final double hue;

  /// 彩度系数，1 为满彩度；`white` 主题接近 0。
  final double chroma;

  /// 亮色模式下主色的明度（0~1）。逐主题校准，勿统一。
  final double primaryLightness;

  /// 供 `ColorScheme.fromSeed` 使用的种子色。
  Color get color => hsl(hue, 0.74 * chroma, primaryLightness);

  /// 主题选择器里的圆点颜色。
  Color get swatch =>
      hsl(hue, 0.74 * chroma, 0.45);

  /// 由种子派生一个颜色。统一入口。
  static Color hsl(double h, double s, double l) => HSLColor.fromAHSL(
        1,
        h % 360,
        s.clamp(0.0, 1.0),
        l.clamp(0.0, 1.0),
      ).toColor();
}

/// 七个可选主题。key 与 `APPSetting.theme` 的取值、`themeName` 的 key 一一对应。
///
/// `primaryLightness` 一列是按实测对比度逐个校准的结果，改动前请重新测对比度。
const Map<String, TiebananaSeed> tiebananaSeeds = <String, TiebananaSeed>{
  'blue': TiebananaSeed(
      name: 'blue', hue: 221, chroma: 1, primaryLightness: .34),
  'cyan': TiebananaSeed(
      name: 'cyan', hue: 189, chroma: 1, primaryLightness: .26),
  'teal': TiebananaSeed(
      name: 'teal', hue: 174, chroma: 1, primaryLightness: .26),
  'green': TiebananaSeed(
      name: 'green', hue: 148, chroma: .95, primaryLightness: .28),
  'yellow': TiebananaSeed(
      name: 'yellow', hue: 43, chroma: .95, primaryLightness: .30),
  'pink': TiebananaSeed(
      name: 'pink', hue: 331, chroma: 1, primaryLightness: .34),
  'white': TiebananaSeed(
      name: 'white', hue: 222, chroma: .1, primaryLightness: .34),
};

/// 取主题种子；未知名称回落到蓝色。
TiebananaSeed seedOf(String? name) =>
    tiebananaSeeds[name] ?? tiebananaSeeds['blue']!;
