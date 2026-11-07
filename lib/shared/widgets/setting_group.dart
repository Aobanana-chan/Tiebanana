import 'package:flutter/material.dart';

import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 方向 A 的卡片壳（概念图 `design/mockups/_mock.css` 的 `.sgroup`）。
///
/// 圆角 18 的 `surface` 卡浮在页面底色上，卡片之间只留 `gapSm + 2` 的间距。
/// 设置页的分组卡与「关于」页的品牌卡共用这一份外边距 + 投影 + 圆角。
class SettingCard extends StatelessWidget {
  const SettingCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        TiebananaMetrics.pageGutter,
        TiebananaMetrics.gapSm + 2,
        TiebananaMetrics.pageGutter,
        0,
      ),
      decoration: BoxDecoration(
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      // 用 Material 承载卡片表面：行内的水波纹会被圆角裁掉，不会画到卡片外。
      child: Material(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

/// 一张分组卡里的几行 [SettingRow]。
///
/// [divided] 为真时行与行之间补一条 `line` 细描边：设置页右侧控件多，
/// 靠横线把「控件属于哪一行」划清楚；纯入口列表（「我的」页）为假，
/// 与概念图 `user.html` 的 `.srow` 一致，只靠留白分隔。
class SettingGroup extends StatelessWidget {
  const SettingGroup({super.key, required this.children, this.divided = true});

  final List<Widget> children;

  final bool divided;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (divided && i > 0) {
        rows.add(Divider(height: 1, thickness: 1, color: tokens.line));
      }
      rows.add(children[i]);
    }
    return SettingCard(
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

/// 设置行（概念图 `.srow2`）：**图标 + 主/副标题 + 右侧控件**。
///
/// 右侧可以同时有 [value]（文字值，如「智能省流量」）与 [trailing]（开关 / 滑块）
/// ——「字体大小」那行就是两个都用的例子。
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.showChevron = false,
  });

  /// 左侧图标（`primary` 着色，危险行换 `danger`）。
  final IconData icon;

  final String title;

  /// 副标题：解释这一项做什么，或显示当前取值。
  final String? subtitle;

  /// 右侧文字值，排在 [trailing] 前面。
  final String? value;

  /// 右侧控件（开关 / 滑块）。
  final Widget? trailing;

  /// 整行点击。为 null 时只渲染普通行。
  final VoidCallback? onTap;

  /// 危险操作（退出登陆）：图标与标题都用 `danger`。
  final bool danger;

  /// 是否绘制右侧箭头：跳转行显示，开关行隐藏。
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color foreground = danger ? tokens.danger : tokens.textPrimary;

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TiebananaMetrics.gapLg,
        vertical: 13,
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: danger ? tokens.danger : tokens.primary),
          const SizedBox(width: TiebananaMetrics.gapMd),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(color: foreground),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall
                        ?.copyWith(color: tokens.textTertiary),
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...<Widget>[
            const SizedBox(width: TiebananaMetrics.gapSm),
            // 封顶宽度：值再长也只占一列，标题保持可读宽度。
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: textTheme.bodySmall?.copyWith(color: tokens.textTertiary),
              ),
            ),
          ],
          if (trailing != null) ...<Widget>[
            const SizedBox(width: TiebananaMetrics.gapSm),
            trailing!,
          ],
          if (showChevron) ...<Widget>[
            const SizedBox(width: TiebananaMetrics.gapXs),
            Icon(
              Icons.chevron_right_outlined,
              size: 18,
              color: tokens.textTertiary,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }
    return InkWell(onTap: onTap, child: content);
  }
}

/// 统一样式的开关。
///
/// 概念图里的 `.sw` 是 46×28 的自绘开关，这里直接用 Material 的 [Switch]
/// （有动画、有无障碍语义），只把 M3 默认的 48 点击区收掉 —— 点击区由整行
/// 承担，开关只是「这一行现在是开还是关」的指示。
class SettingSwitch extends StatelessWidget {
  const SettingSwitch({super.key, required this.value, this.onChanged});

  final bool value;

  /// 为 null 时开关置灰（例如小尾巴为空时的「带上小尾巴」）。
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// 底部面板的骨架（概念图 `design/mockups/overlays.html` 的 `.sheet`）：
/// 把手 + 标题 + 内容。小尾巴编辑、图片浏览模式、正文字号几处面板共用。
class SettingSheetShell extends StatelessWidget {
  const SettingSheetShell({super.key, required this.title, required this.child});

  final String title;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TiebananaMetrics.gapLg,
        10,
        TiebananaMetrics.gapLg,
        TiebananaMetrics.gapLg + 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: tokens.lineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: TiebananaMetrics.gapMd),
          child,
        ],
      ),
    );
  }
}

/// 分段控件的一个选项。
class SettingSegmentOption<T> {
  const SettingSegmentOption(this.value, this.label);

  final T value;
  final String label;
}

/// 分段控件（概念图 `.seg`）：一组互斥的小选项，选中项浮起来。
///
/// 用于「深色模式」的三态（跟随系统 / 开 / 关）。
class SettingSegmented<T> extends StatelessWidget {
  const SettingSegmented({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;

  final List<SettingSegmentOption<T>> options;

  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final SettingSegmentOption<T> option in options)
            _segment(tokens, textTheme, option),
        ],
      ),
    );
  }

  Widget _segment(
      TiebananaTokens tokens, TextTheme textTheme, SettingSegmentOption<T> option) {
    final bool on = option.value == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // 选中项点击时不触发回调。
      onTap: on ? null : () => onChanged(option.value),
      child: Container(
        height: 28,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: on ? tokens.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: on ? tokens.cardShadow : null,
        ),
        child: Text(
          option.label,
          style: textTheme.labelMedium?.copyWith(
            color: on ? tokens.textPrimary : tokens.textSecondary,
            fontWeight: on ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
