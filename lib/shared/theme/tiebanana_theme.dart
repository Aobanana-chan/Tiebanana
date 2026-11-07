import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'tiebanana_metrics.dart';
import 'tiebanana_palette.dart';
import 'tiebanana_seed.dart';
import 'tiebanana_tokens.dart';
import 'tiebanana_typography.dart';

/// 由「种子 + 用户字号」构建 ThemeData。
///
/// 这是 App 唯一的主题入口。页面通过它获取主题，颜色从 [TiebananaTokens] 读取。
class TiebananaTheme {
  const TiebananaTheme._();

  static ThemeData light(TiebananaSeed seed, double userFontSize) =>
      _build(seed, Brightness.light, userFontSize);

  static ThemeData dark(TiebananaSeed seed, double userFontSize) =>
      _build(seed, Brightness.dark, userFontSize);

  static ThemeData _build(
      TiebananaSeed seed, Brightness brightness, double userFontSize) {
    final bool isLight = brightness == Brightness.light;
    final TiebananaPalette p =
        isLight ? TiebananaPalette.light(seed) : TiebananaPalette.dark(seed);
    final double scale = TiebananaTypography.scaleOf(userFontSize);
    final TextTheme text = TiebananaTypography.textTheme(scale);

    // fromSeed 只用来补齐 secondary / tertiary / inverse / error 等其余角色；
    // 真正决定观感的 surface 系列全部覆盖成自己派生的值。
    // 注意：M3 默认的 surface 带极低彩度的"灰紫"，正是旧版观感发脏的来源之一。
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed.color,
      brightness: brightness,
    ).copyWith(
      primary: p.primary,
      onPrimary: p.accentOn,
      primaryContainer: p.primaryContainer,
      onPrimaryContainer: p.onPrimaryContainer,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surfaceAlt,
      surfaceContainerHigh: p.surfaceAlt,
      surfaceContainerHighest: p.surfaceHigh,
      outline: p.lineStrong,
      outlineVariant: p.line,
      error: p.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      // 兼容旧代码里大量的 `Theme.of(context).primaryColor`，Phase 4 清理干净后可移除。
      primaryColor: p.primary,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.surface,
      textTheme: text,
      // 全平台统一 iOS 翻页动画。命令式跳转都走 appPageRoute，这里兜住
      // 第三方页面或漏改的 MaterialPageRoute，避免 Android 上出现缩放淡入。
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
        },
      ),
      // 表面色已自行派生，关掉 M3 的高度叠加染色，避免二次偏色。
      appBarTheme: AppBarTheme(
        backgroundColor: p.bar,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: TiebananaMetrics.appBarHeight,
        titleTextStyle: text.titleLarge?.copyWith(color: p.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.bar,
        selectedItemColor: p.primary,
        unselectedItemColor: p.textSecondary,
        selectedLabelStyle: text.labelSmall,
        unselectedLabelStyle: text.labelSmall,
        // 四个标签都常显，固定为 fixed。
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        // 页签统一成 A 方向的药丸：选中项是 primaryContainer 填充 + onPrimaryContainer 文字，
        // 指示器由调用点用 TiebananaPillTabIndicator 传入（需要 context 里的 token），
        // 所以这里把默认的指示器与分隔线都关掉，避免药丸下面压着一条 1px 线。
        labelColor: p.onPrimaryContainer,
        unselectedLabelColor: p.textSecondary,
        indicatorColor: Colors.transparent,
        dividerColor: Colors.transparent,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
      ),
      // 首页底栏用 M3 NavigationBar：药丸指示器 + 常显标签，
      // 与概念图一致（旧的 BottomNavigationBar 在 4 个 item 下会退化成 shifting）。
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.bar,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => text.labelSmall!.copyWith(
            color: states.contains(WidgetState.selected)
                ? p.textPrimary
                : p.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => IconThemeData(
            size: TiebananaMetrics.iconSize,
            color: states.contains(WidgetState.selected)
                ? p.onPrimaryContainer
                : p.textSecondary,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.line,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(
        color: p.textSecondary,
        size: TiebananaMetrics.iconSize,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.primary,
        textColor: p.textPrimary,
      ),
      // 旧 main.dart 里的默认值，大量 MaterialButton 依赖它（零内边距 + 收缩点击区）。
      // 按钮逐个收敛后可以移除。
      buttonTheme: const ButtonThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
      ),
      splashColor: p.primary.withValues(alpha: .08),
      highlightColor: p.primary.withValues(alpha: .05),
      extensions: <ThemeExtension<dynamic>>[
        TiebananaTokens(p),
      ],
    );
  }
}
