import 'package:flutter/material.dart';

/// 间距、圆角、阴影、动效的固定阶梯。与明暗 / 主题色无关，使用常量定义。
///
/// 取值来自概念图 `design/mockups/_mock.css`（方向 A · 现代 M3 圆润卡片）。
/// 修改时同步概念图 `design/mockups/_mock.css`。
class TiebananaMetrics {
  const TiebananaMetrics._();

  // ---------------- 间距 ----------------
  static const double gapXXs = 2;
  static const double gapXs = 4;
  static const double gapSm = 8;
  static const double gapMd = 12;
  static const double gapLg = 16;
  static const double gapXl = 24;
  static const double gapXXl = 32;

  /// 页面左右留白（卡片外侧）。
  static const double pageGutter = 12;

  /// 卡片内边距。
  static const double cardPadding = 13;

  // ---------------- 圆角 ----------------
  /// 标签 / 小徽章。
  static const double radiusXs = 6;

  /// 引用块 / 缩略图。
  static const double radiusSm = 12;

  /// 按钮 / 输入框。
  static const double radiusCtl = 14;

  /// 楼中楼容器等中间档圆角。
  static const double radiusMd = 16;

  /// 卡片。
  static const double radiusLg = 18;

  /// 大卡（吧头部 / 用户卡）。
  static const double radiusXl = 22;

  /// 药丸。
  static const double radiusPill = 999;

  static BorderRadius get brXs => BorderRadius.circular(radiusXs);
  static BorderRadius get brSm => BorderRadius.circular(radiusSm);
  static BorderRadius get brCtl => BorderRadius.circular(radiusCtl);
  static BorderRadius get brMd => BorderRadius.circular(radiusMd);
  static BorderRadius get brLg => BorderRadius.circular(radiusLg);
  static BorderRadius get brXl => BorderRadius.circular(radiusXl);
  static BorderRadius get brPill => BorderRadius.circular(radiusPill);

  // ---------------- 布局 ----------------
  static const double appBarHeight = 54;
  static const double bottomBarHeight = 82;
  static const double iconSize = 22;
  static const double iconSizeSmall = 14;
  static const double avatarSm = 30;
  static const double avatarMd = 36;
  static const double avatarLg = 42;
  static const double avatarXl = 56;

  // ---------------- 动效 ----------------
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationBase = Duration(milliseconds: 250);
  static const Curve curveStandard = Curves.easeOutCubic;
  static const Curve curveExit = Curves.easeInCubic;
}
