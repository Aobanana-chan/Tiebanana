import 'dart:ui' show Color;

/// 开屏的品牌色。
///
/// **固定配色**：与 App 图标（`assets/icon/ic_launcher.png`）逐色一致，
/// 冷启动从原生启动图切进来时颜色连续；主题色（`lib/shared/theme/`）变化时开屏保持不变。
/// 因此这里的颜色直接硬编码，与 `video_player` / `img_explorer` 的纯黑遮罩同一类。
///
/// 取值来自 `docs/icon/build_icons.js` 的 `royal` 调色板（与应用图标一致，
/// `indigo` 是 `#2C3585 → #1A1E58` 的深藏青，与图标不符）。
/// 概念图与逐帧演示：`design/splash/splash.html`。
class SplashBrand {
  const SplashBrand._();

  /// 底色渐变（概念图里是 CSS `linear-gradient(168deg, …)`）。
  static const Color bgTop = Color(0xFF4C86F5);
  static const Color bgBottom = Color(0xFF2B5FD9);

  /// 「贴」的字形色。
  static const Color ink = Color(0xFFFFFFFF);

  /// 字标 `banana` 那一段变绿的目标色。
  /// 取图标里叶子的绿（`#5CBE66`）提亮一档 —— 原绿压在宝蓝底上偏暗。
  static const Color wordmarkGreen = Color(0xFF6FD37A);

  /// 字标投影用的深靛（半透明），只为在蓝底上把字托起来。
  static const Color wordmarkShadow = Color(0x59121A4A);
}
