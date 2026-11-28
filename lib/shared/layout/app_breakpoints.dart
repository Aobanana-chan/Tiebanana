import 'package:flutter/widgets.dart';

/// 四档响应式窗口断点。
enum AppBreakpoint {
  /// `< 720dp`：手机 / 窄窗，保留底部 NavigationBar 与单列布局。
  compact,

  /// `720–899dp`：紧凑平板 / 半屏窗口，左侧 76px 图标轨 + 单列满宽卡片。
  medium,

  /// `900–1199dp`：笔记本桌面，左侧 76px 图标轨 + 双栏布局。
  expanded,

  /// `≥ 1200dp`：宽屏桌面，左侧 220px 展开侧边栏（可折叠回 76px）+ 双栏布局。
  wide,
}

/// 桌面端与响应式布局常量。
///
/// 判断「用哪套骨架」（手机底栏 / 桌面壳层）一律看窗口宽度
/// （`MediaQuery.sizeOf`）；宽屏壳层占掉侧栏后内容宽度会小 76–220dp，
/// 内容宽度只用于页内单栏 / 双栏这类局部取舍。
class AppBreakpoints {
  const AppBreakpoints._();

  static const double compactMax = 720;
  static const double mediumMax = 900;
  static const double expandedMax = 1200;

  static const double pageMaxWidth = 1060;
  static const double feedMaxWidth = 760;

  static const double railWidth = 76;
  static const double sidebarWidth = 220;
  static const double topBarHeight = 56;

  static AppBreakpoint fromWidth(double width) {
    if (width < compactMax) return AppBreakpoint.compact;
    if (width < mediumMax) return AppBreakpoint.medium;
    if (width < expandedMax) return AppBreakpoint.expanded;
    return AppBreakpoint.wide;
  }

  static AppBreakpoint of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static bool isCompactWidth(double width) => width < compactMax;
  static bool isDesktopWidth(double width) => width >= compactMax;
  static bool isTwoColumnWidth(double width) => width >= mediumMax;
  static bool canExpandSidebarWidth(double width) => width >= expandedMax;

  static bool isCompact(BuildContext context) =>
      isCompactWidth(MediaQuery.sizeOf(context).width);
  static bool isDesktop(BuildContext context) =>
      isDesktopWidth(MediaQuery.sizeOf(context).width);
  static bool isTwoColumn(BuildContext context) =>
      isTwoColumnWidth(MediaQuery.sizeOf(context).width);

  /// PageWrap 统一水平内边距：窄窗 12、半屏 18、宽屏 24。
  static double pagePaddingFor(double width) {
    if (width < compactMax) return 12;
    if (width < mediumMax) return 18;
    return 24;
  }
}
