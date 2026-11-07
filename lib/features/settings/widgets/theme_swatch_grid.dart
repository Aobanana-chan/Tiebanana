import 'package:flutter/material.dart';

import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 主题色卡网格（概念图 `design/mockups/theme_change.html` 的 `.tgrid`）。
///
/// 每张色卡展示的是这个主题**真正的主色**（`seed.color`，即
/// `hsl(hue, .74·chroma, primaryLightness)`），不是更亮的 `seed.swatch`：
/// 点下去整个 App 的主按钮 / 选中态就是这个颜色，所见即所得。
///
/// 选中态在色块外描一圈 `primary` 环 + 压一个对勾；外圈与色块之间留 2px
/// 「缝隙」，所以始终保留这段内边距，未选中时描边透明，保持尺寸稳定。
class ThemeSwatchGrid extends StatelessWidget {
  const ThemeSwatchGrid({
    super.key,
    required this.selected,
    required this.onPicked,
  });

  /// 当前主题 key（`APPSetting.theme`）。
  final String selected;

  final ValueChanged<String> onPicked;

  /// 色卡顺序与 `tiebananaSeeds` / `themeName` 一致。
  static const List<String> keys = <String>[
    'blue',
    'cyan',
    'teal',
    'green',
    'yellow',
    'pink',
    'white',
  ];

  static const int _columns = 4;
  static const double _gap = 14;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double tileWidth = (constraints.maxWidth -
                TiebananaMetrics.pageGutter * 2 -
                _gap * (_columns - 1)) /
            _columns;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TiebananaMetrics.pageGutter,
            vertical: TiebananaMetrics.gapSm,
          ),
          child: Wrap(
            spacing: _gap,
            runSpacing: _gap,
            children: <Widget>[
              for (final String key in keys)
                SizedBox(
                  width: tileWidth,
                  child: _ThemeSwatch(
                    themeKey: key,
                    selected: key == selected,
                    onTap: () => onPicked(key),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.themeKey,
    required this.selected,
    required this.onTap,
  });

  final String themeKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TiebananaSeed seed = seedOf(themeKey);
    final String label = themeName[themeKey] ?? themeKey;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(_ThemeSwatch.ringGap),
                decoration: BoxDecoration(
                  borderRadius: TiebananaMetrics.brLg,
                  border: Border.all(
                    color: selected ? tokens.primary : Colors.transparent,
                    width: _ThemeSwatch.ringWidth,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: seed.color,
                    borderRadius: TiebananaMetrics.brMd,
                    boxShadow: tokens.cardShadow,
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          // 色块是饱和主色，白勾在明暗主题下都清晰；
                          // 硬编码颜色例外见 test/hardcoded_colors_test.dart。
                          color: Colors.white,
                          size: 22,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: TiebananaMetrics.gapSm),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: tokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  static const double ringWidth = 2;
  static const double ringGap = 2;
}
