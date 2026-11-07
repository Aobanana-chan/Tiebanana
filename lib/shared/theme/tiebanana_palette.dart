import 'package:flutter/material.dart';

import 'tiebanana_seed.dart';

/// 由 [TiebananaSeed] 派生的一整套语义色，明暗各一份。
///
/// 底色、卡片、导航条、容器和描边都带种子色相，切换主题色时整体观感一起变化。
///
/// 括号内是派生公式（见 design/README.md），改动时请同步那边。
@immutable
class TiebananaPalette {
  const TiebananaPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceHigh,
    required this.fill,
    required this.bar,
    required this.line,
    required this.lineStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.accentFill,
    required this.accentOn,
    required this.danger,
    required this.quoteBackground,
    required this.quoteText,
    required this.skeleton,
    required this.skeletonHighlight,
    required this.shadow,
  });

  /// 页面底色         hsl(h, 44%·c, 96%)
  final Color bg;

  /// 卡片 / 面板      hsl(h, 30%·c, 99.4%)
  final Color surface;

  /// 次级容器         hsl(h, 36%·c, 92%)
  final Color surfaceAlt;

  /// 三级容器         hsl(h, 34%·c, 86%)
  final Color surfaceHigh;

  /// 引用框 / 输入框  hsl(h, 42%·c, 92.5%)
  final Color fill;

  /// 底部导航条       hsl(h, 46%·c, 94.5%)
  final Color bar;

  /// 细描边           hsl(h, 32%·c, 87.5%)
  final Color line;

  /// 强调描边         hsl(h, 32%·c, 78%)
  final Color lineStrong;

  /// 正文
  final Color textPrimary;

  /// 次要文字（正文附注、摘要）
  final Color textSecondary;

  /// 三级文字（时间 / 浏览量 / 计数）
  final Color textTertiary;

  /// 主色             hsl(h, 74%·c, pl)
  final Color primary;

  /// 主色容器         hsl(h, 62%·c, 91%)
  final Color primaryContainer;

  /// 主色容器上的文字 hsl(h, 58%·c, 20%)
  final Color onPrimaryContainer;

  /// 实心按钮 / FAB 的填充色。
  /// 与 [primary] 分开：暗色下 primary 是浅色调，
  /// 作为填充配白字对比度不足（亮色配白字、暗色配深字）。
  final Color accentFill;

  /// 实心按钮 / FAB 上的前景色。
  final Color accentOn;

  /// 危险色（退出登录等）。
  final Color danger;

  /// 引用块底色。
  final Color quoteBackground;

  /// 引用块文字。
  final Color quoteText;

  /// 骨架屏底色。
  final Color skeleton;

  /// 骨架屏高光。
  final Color skeletonHighlight;

  /// 卡片投影色（带 alpha）。
  final Color shadow;

  /// 亮色：不透明的可读文字在浅底上。
  factory TiebananaPalette.light(TiebananaSeed s) {
    final double h = s.hue, c = s.chroma;
    final Color primary = TiebananaSeed.hsl(h, .74 * c, s.primaryLightness);
    final Color fill = TiebananaSeed.hsl(h, .42 * c, .925);
    const Color textSecondary = Color(0xFF4D545F);
    return TiebananaPalette(
      bg: TiebananaSeed.hsl(h, .44 * c, .96),
      surface: TiebananaSeed.hsl(h, .30 * c, .994),
      surfaceAlt: TiebananaSeed.hsl(h, .36 * c, .92),
      surfaceHigh: TiebananaSeed.hsl(h, .34 * c, .86),
      fill: fill,
      bar: TiebananaSeed.hsl(h, .46 * c, .945),
      line: TiebananaSeed.hsl(h, .32 * c, .875),
      lineStrong: TiebananaSeed.hsl(h, .32 * c, .78),
      textPrimary: const Color(0xFF17191D),
      textSecondary: textSecondary,
      textTertiary: const Color(0xFF666D77),
      primary: primary,
      primaryContainer: TiebananaSeed.hsl(h, .62 * c, .91),
      onPrimaryContainer: TiebananaSeed.hsl(h, .58 * c, .20),
      accentFill: primary,
      accentOn: const Color(0xFFFFFFFF),
      danger: const Color(0xFFC62828),
      quoteBackground: fill,
      quoteText: textSecondary,
      skeleton: TiebananaSeed.hsl(h, .32 * c, .92),
      skeletonHighlight: TiebananaSeed.hsl(h, .30 * c, .97),
      shadow: TiebananaSeed.hsl(h, .34 * c, .45).withValues(alpha: .13),
    );
  }

  /// 暗色：低彩度深色表面 + 浅色主色。
  factory TiebananaPalette.dark(TiebananaSeed s) {
    final double h = s.hue, c = s.chroma;
    final Color primary = TiebananaSeed.hsl(h, .68 * c, .76);
    final Color fill = TiebananaSeed.hsl(h, .28 * c, .18);
    const Color textSecondary = Color(0xFFA0A7B1);
    return TiebananaPalette(
      bg: TiebananaSeed.hsl(h, .32 * c, .08),
      surface: TiebananaSeed.hsl(h, .28 * c, .13),
      surfaceAlt: TiebananaSeed.hsl(h, .26 * c, .19),
      surfaceHigh: TiebananaSeed.hsl(h, .26 * c, .25),
      fill: fill,
      bar: TiebananaSeed.hsl(h, .30 * c, .105),
      line: TiebananaSeed.hsl(h, .26 * c, .23),
      lineStrong: TiebananaSeed.hsl(h, .26 * c, .32),
      textPrimary: const Color(0xFFE9EBEE),
      textSecondary: textSecondary,
      textTertiary: const Color(0xFF7B838D),
      primary: primary,
      primaryContainer: TiebananaSeed.hsl(h, .36 * c, .28),
      onPrimaryContainer: TiebananaSeed.hsl(h, .62 * c, .90),
      accentFill: primary,
      accentOn: TiebananaSeed.hsl(h, .42 * c, .10),
      danger: const Color(0xFFFF8A8F),
      quoteBackground: fill,
      quoteText: textSecondary,
      skeleton: TiebananaSeed.hsl(h, .26 * c, .20),
      skeletonHighlight: TiebananaSeed.hsl(h, .26 * c, .26),
      shadow: const Color(0xFF000000).withValues(alpha: .45),
    );
  }

  static TiebananaPalette lerp(
          TiebananaPalette a, TiebananaPalette b, double t) =>
      TiebananaPalette(
        bg: Color.lerp(a.bg, b.bg, t)!,
        surface: Color.lerp(a.surface, b.surface, t)!,
        surfaceAlt: Color.lerp(a.surfaceAlt, b.surfaceAlt, t)!,
        surfaceHigh: Color.lerp(a.surfaceHigh, b.surfaceHigh, t)!,
        fill: Color.lerp(a.fill, b.fill, t)!,
        bar: Color.lerp(a.bar, b.bar, t)!,
        line: Color.lerp(a.line, b.line, t)!,
        lineStrong: Color.lerp(a.lineStrong, b.lineStrong, t)!,
        textPrimary: Color.lerp(a.textPrimary, b.textPrimary, t)!,
        textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
        textTertiary: Color.lerp(a.textTertiary, b.textTertiary, t)!,
        primary: Color.lerp(a.primary, b.primary, t)!,
        primaryContainer: Color.lerp(a.primaryContainer, b.primaryContainer, t)!,
        onPrimaryContainer:
            Color.lerp(a.onPrimaryContainer, b.onPrimaryContainer, t)!,
        accentFill: Color.lerp(a.accentFill, b.accentFill, t)!,
        accentOn: Color.lerp(a.accentOn, b.accentOn, t)!,
        danger: Color.lerp(a.danger, b.danger, t)!,
        quoteBackground: Color.lerp(a.quoteBackground, b.quoteBackground, t)!,
        quoteText: Color.lerp(a.quoteText, b.quoteText, t)!,
        skeleton: Color.lerp(a.skeleton, b.skeleton, t)!,
        skeletonHighlight:
            Color.lerp(a.skeletonHighlight, b.skeletonHighlight, t)!,
        shadow: Color.lerp(a.shadow, b.shadow, t)!,
      );
}
