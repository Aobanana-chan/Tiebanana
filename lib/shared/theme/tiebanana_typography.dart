import 'package:flutter/material.dart';

/// 语义字阶 + 用户字号倍率。
///
/// 用户设置的是正文大小，整套字阶按倍率等比缩放，保持层级关系。
class TiebananaTypography {
  const TiebananaTypography._();

  /// 设计基准：默认设置 16.0 时，正文约 15.5px，与改动前基本一致。
  static const double baseBodyFontSize = 15.0;

  /// 允许的缩放区间。低于 0.85 中文会难读，高于 1.5 会撑破布局。
  static const double minScale = 0.85;
  static const double maxScale = 1.5;

  static double scaleOf(double userFontSize) =>
      (userFontSize / baseBodyFontSize).clamp(minScale, maxScale);

  /// 用户字号调节控件的整数区间，不超出有效倍率范围。
  static double get minUserFontSize =>
      (baseBodyFontSize * minScale).ceilToDouble();

  static double get maxUserFontSize =>
      (baseBodyFontSize * maxScale).floorToDouble();

  /// 中文需要比拉丁文更大的行距，正文统一 1.6。
  static TextTheme textTheme(double scale) {
    TextStyle t(double size, FontWeight weight,
            {double height = 1.4, double? spacing}) =>
        TextStyle(
          fontSize: size * scale,
          fontWeight: weight,
          height: height,
          letterSpacing: spacing,
        );

    return TextTheme(
      // 大标题：用户主页昵称等
      headlineSmall: t(20, FontWeight.w700, height: 1.3, spacing: .1),
      // 页面标题（AppBar）
      titleLarge: t(20, FontWeight.w600, height: 1.3),
      // 分区标题 / 贴子标题
      titleMedium: t(17, FontWeight.w700, height: 1.45),
      // 列表卡片标题
      titleSmall: t(15.5, FontWeight.w600, height: 1.45),
      // 正文
      bodyLarge: t(14.5, FontWeight.w400, height: 1.6),
      bodyMedium: t(13.5, FontWeight.w400, height: 1.6),
      bodySmall: t(12.5, FontWeight.w400, height: 1.6),
      // 按钮 / 可点文字
      labelLarge: t(14, FontWeight.w600, height: 1.2),
      labelMedium: t(12.5, FontWeight.w600, height: 1.2),
      // 元信息：时间、浏览量、计数
      labelSmall: t(11.5, FontWeight.w400, height: 1.35),
    );
  }
}
