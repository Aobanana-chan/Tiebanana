import 'package:flutter/material.dart';

import 'tiebanana_palette.dart';

/// 挂在 `ThemeData.extensions` 上的语义色令牌。
///
/// `ColorScheme` 覆盖不到的语义都由这里提供：引用块、骨架屏、导航条、
/// 容器填充、细描边等。间距/圆角/动效见 `TiebananaMetrics`（与明暗无关，放在常量类中）。
///
/// 用法：`TiebananaTokens.of(context).bg`
@immutable
class TiebananaTokens extends ThemeExtension<TiebananaTokens> {
  const TiebananaTokens(this.palette);

  final TiebananaPalette palette;

  Color get bg => palette.bg;
  Color get surface => palette.surface;
  Color get surfaceAlt => palette.surfaceAlt;
  Color get surfaceHigh => palette.surfaceHigh;
  Color get fill => palette.fill;
  Color get bar => palette.bar;
  Color get line => palette.line;
  Color get lineStrong => palette.lineStrong;
  Color get textPrimary => palette.textPrimary;
  Color get textSecondary => palette.textSecondary;
  Color get textTertiary => palette.textTertiary;
  Color get primary => palette.primary;
  Color get primaryContainer => palette.primaryContainer;
  Color get onPrimaryContainer => palette.onPrimaryContainer;
  Color get accentFill => palette.accentFill;
  Color get accentOn => palette.accentOn;
  Color get danger => palette.danger;
  Color get quoteBackground => palette.quoteBackground;
  Color get quoteText => palette.quoteText;
  Color get skeleton => palette.skeleton;
  Color get skeletonHighlight => palette.skeletonHighlight;
  Color get shadow => palette.shadow;

  /// 封面 / 图片上的固定白色文字与图标。
  ///
  /// 固定白色，用于压在图片上的内容；图片本身可能很暗，暗色主题下仍保持可读。
  Color get onImage => const Color(0xFFFFFFFF);

  /// 图片上方的压暗遮罩（配合不同 alpha 使用）。
  Color get imageScrim => const Color(0xFF000000);

  // 吧务身份使用固定语义色。
  bool get _dark => palette.bg.computeLuminance() < .5;
  Color get assistantBadgeBackground =>
      _dark ? const Color(0xff173f70) : const Color(0xffdeeeff);
  Color get assistantBadgeForeground =>
      _dark ? const Color(0xff86c5ff) : const Color(0xff0965cf);
  Color get managerBadgeBackground =>
      _dark ? const Color(0xff602936) : const Color(0xffffe5e9);
  Color get managerBadgeForeground =>
      _dark ? const Color(0xffff9faf) : const Color(0xffcf193b);

  // 投票阵营（蓝方 / 红方）。固定色相，不跟随主题色，
  // 让“蓝方 vs 红方”在任何换色下都保持可辨识的对抗关系。
  Color get pollBlue =>
      _dark ? const Color(0xff8fb6ff) : const Color(0xff2f6bff);
  Color get pollBlueContainer =>
      _dark ? const Color(0xff16274a) : const Color(0xffe9f1ff);
  Color get pollBlueOnContainer =>
      _dark ? const Color(0xffd6e4ff) : const Color(0xff173a7a);
  Color get pollRed =>
      _dark ? const Color(0xffff9aa0) : const Color(0xffe8414b);
  Color get pollRedContainer =>
      _dark ? const Color(0xff3d1a1d) : const Color(0xffffecee);
  Color get pollRedOnContainer =>
      _dark ? const Color(0xffffd6d8) : const Color(0xff8a1c24);

  /// A 方向卡片的统一投影。卡片靠它 + 表面色差从染了主题色的底上浮起。
  List<BoxShadow> get cardShadow => <BoxShadow>[
        BoxShadow(
          color: palette.shadow,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static TiebananaTokens of(BuildContext context) {
    final TiebananaTokens? tokens =
        Theme.of(context).extension<TiebananaTokens>();
    assert(
      tokens != null,
      'TiebananaTokens 未注册：ThemeData 必须由 TiebananaTheme.light/dark 构建。',
    );
    return tokens!;
  }

  /// 只要调色板时的简写。
  static TiebananaPalette paletteOf(BuildContext context) =>
      of(context).palette;

  @override
  TiebananaTokens copyWith({TiebananaPalette? palette}) =>
      TiebananaTokens(palette ?? this.palette);

  @override
  TiebananaTokens lerp(ThemeExtension<TiebananaTokens>? other, double t) {
    if (other is! TiebananaTokens) {
      return this;
    }
    return TiebananaTokens(
      TiebananaPalette.lerp(palette, other.palette, t),
    );
  }
}
