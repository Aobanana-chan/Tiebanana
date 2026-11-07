import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/features/settings/widgets/font_size_sheet.dart';
import 'package:tiebanana/shared/widgets/section_header.dart';
import 'package:tiebanana/shared/widgets/setting_group.dart';
import 'package:tiebanana/features/settings/widgets/theme_swatch_grid.dart';

/// 更换主题页。
///
/// 对应概念图 `design/mockups/theme_change.html`（方向 A）：
/// 「深色模式」三态分段控件 + 七张主题色卡网格 + 「正文字号」入口 + 一行说明。
///
/// 页面包含深色模式、主题色卡和正文字号，三项都写入 `APPSettingProvider`，
/// 修改后立即保存并重绘（`main.dart` 用同一份设置构建 ThemeData）。
class ThemeChangePage extends StatelessWidget {
  const ThemeChangePage({super.key});

  /// 深色模式三态，取值与 `APPSetting.darkModel` 一一对应。
  static const List<SettingSegmentOption<int>> _darkModeOptions =
      <SettingSegmentOption<int>>[
    SettingSegmentOption<int>(0, '跟随系统'),
    SettingSegmentOption<int>(1, '开'),
    SettingSegmentOption<int>(2, '关'),
  ];

  @override
  Widget build(BuildContext context) {
    final APPSettingProvider setting = context.watch<APPSettingProvider>();
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Scaffold(
      appBar: AppBar(
        // 与设置页一致：顶栏跟页面底色，不铺 `bar` 那层灰。
        backgroundColor: tokens.bg,
        foregroundColor: tokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text('更换主题'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: TiebananaMetrics.gapXl),
        children: <Widget>[
          SettingGroup(
            children: <Widget>[
              SettingRow(
                icon: Icons.brightness_6_outlined,
                title: '深色模式',
                trailing: SettingSegmented<int>(
                  value: setting.darkModel,
                  options: _darkModeOptions,
                  onChanged: (int mode) => setting.darkModel = mode,
                ),
              ),
            ],
          ),
          const SectionHeader(
            title: '主题色',
            trailing: '7 种',
          ),
          ThemeSwatchGrid(
            selected: setting.theme,
            onPicked: (String key) => setting.theme = key,
          ),
          SettingGroup(
            children: <Widget>[
              SettingRow(
                icon: Icons.text_fields_rounded,
                title: '正文字号',
                value: setting.fontSize.toStringAsFixed(0),
                showChevron: true,
                onTap: () => showFontSizeSheet(context),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TiebananaMetrics.gapLg,
              TiebananaMetrics.gapXl,
              TiebananaMetrics.gapLg,
              TiebananaMetrics.gapSm,
            ),
            child: Text(
              '主题色会同时改变底色、卡片、导航条与容器色，\n不只是文字颜色。',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: tokens.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
