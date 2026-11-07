import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/theme/tiebanana_typography.dart';
import 'package:tiebanana/shared/widgets/setting_group.dart';

/// 正文字号调节面板。
///
/// 与「应用设置」页那行的行内滑块同一套取值（`TiebananaTypography` 的
/// 倍率区间换算），只是换成底部面板以便带一块实时预览。
Future<void> showFontSizeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TiebananaTokens.of(context).surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(TiebananaMetrics.radiusXl),
      ),
    ),
    builder: (BuildContext sheetContext) => const _FontSizeSheet(),
  );
}

class _FontSizeSheet extends StatefulWidget {
  const _FontSizeSheet();

  @override
  State<_FontSizeSheet> createState() => _FontSizeSheetState();
}

class _FontSizeSheetState extends State<_FontSizeSheet> {
  /// 拖动中的字号。松手才落库：`Global.saveProfile()` 每帧都写
  /// SharedPreferences 会把拖动拖卡（同 app_setting_page）。
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = Provider.of<APPSettingProvider>(context, listen: false)
        .fontSize
        .roundToDouble()
        .clamp(
          TiebananaTypography.minUserFontSize,
          TiebananaTypography.maxUserFontSize,
        );
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return SettingSheetShell(
      title: '正文字号',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                '字号',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: tokens.textPrimary),
              ),
              const Spacer(),
              Text(
                _value.toStringAsFixed(0),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: tokens.textTertiary),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: tokens.primary,
              inactiveTrackColor: tokens.surfaceAlt,
              thumbColor: tokens.primary,
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              min: TiebananaTypography.minUserFontSize,
              max: TiebananaTypography.maxUserFontSize,
              divisions: (TiebananaTypography.maxUserFontSize -
                      TiebananaTypography.minUserFontSize)
                  .toInt(),
              value: _value,
              onChanged: (double value) =>
                  setState(() => _value = value.roundToDouble()),
              onChangeEnd: (double value) =>
                  Provider.of<APPSettingProvider>(context, listen: false)
                      .fontSize = value.roundToDouble(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: TiebananaMetrics.gapSm),
            child: _Preview(
                tokens: tokens, scale: TiebananaTypography.scaleOf(_value)),
          ),
          const SizedBox(height: TiebananaMetrics.gapMd),
          Text(
            '字号改的是整套字阶的倍率，标题 / 正文 / 元信息等比缩放。',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: tokens.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// 实时预览：一块卡片里放标题 / 正文 / 元信息三级文字。
class _Preview extends StatelessWidget {
  const _Preview({required this.tokens, required this.scale});

  final TiebananaTokens tokens;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final TextTheme preview = TiebananaTypography.textTheme(scale);
    return Container(
      padding: const EdgeInsets.all(TiebananaMetrics.gapMd),
      decoration: BoxDecoration(
        color: tokens.fill,
        borderRadius: TiebananaMetrics.brCtl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '预览 · 帖子标题',
            style: preview.titleSmall?.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: TiebananaMetrics.gapXs),
          Text(
            '正文示例：字号会等比放大，层级不会因为调大而塌掉。',
            style: preview.bodyLarge?.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: TiebananaMetrics.gapXs),
          Text(
            '3 楼 · 2 小时前',
            style: preview.labelSmall?.copyWith(color: tokens.textTertiary),
          ),
        ],
      ),
    );
  }
}
