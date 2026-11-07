import 'package:flutter/material.dart';
import 'package:tiebanana/features/settings/data/license.dart';
import 'package:tiebanana/features/update/data/version.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/setting_group.dart';

/// 「关于」屏。
///
/// 概念图 `design/mockups/app_setting.html` 的规格卡：关于独立成一屏，
/// 展示「品牌卡 + 检查更新（= 更新日志入口）+ 开源许可 + 版权说明」。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: tokens.bg,
        foregroundColor: tokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text('关于'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: TiebananaMetrics.gapXl),
        children: <Widget>[
          _brand(context, tokens, textTheme),
          SettingGroup(
            children: <Widget>[
              SettingRow(
                icon: Icons.system_update_alt_rounded,
                title: '检查更新',
                subtitle: '更新内容会显示在版本页里',
                value: Version.displayVersion,
                showChevron: true,
                onTap: () => Navigator.pushNamed(context, PageRouter.appUpdate),
              ),
              SettingRow(
                icon: Icons.description_outlined,
                title: '开源许可',
                value: 'MIT',
                showChevron: true,
                onTap: () => Navigator.push(
                  context,
                  appPageRoute<void>(
                    builder: (BuildContext context) => const LicenseFullPage(),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TiebananaMetrics.gapLg,
              TiebananaMetrics.gapLg,
              TiebananaMetrics.gapLg,
              0,
            ),
            child: Text(
              'Tiebanana 是非官方的贴吧客户端\n以 MIT 许可开放源代码',
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(color: tokens.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  /// 品牌卡：图标 + 名称 + 当前版本。
  Widget _brand(
      BuildContext context, TiebananaTokens tokens, TextTheme textTheme) {
    return SettingCard(
      child: Padding(
        padding: const EdgeInsets.all(TiebananaMetrics.gapXl),
        child: Column(
          children: <Widget>[
            ClipRRect(
              borderRadius: TiebananaMetrics.brXl,
              child: Image.asset(
                'assets/icon/ic_launcher_round.png',
                width: 74,
                height: 74,
                // 资源缺失（或测试环境没打资源包）时显示主题色方块。
                errorBuilder: (BuildContext context, Object error,
                        StackTrace? stackTrace) =>
                    Container(
                  width: 74,
                  height: 74,
                  color: tokens.primaryContainer,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.chat_bubble_rounded,
                    size: 34,
                    color: tokens.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: TiebananaMetrics.gapMd),
            Text(
              'Tiebanana',
              style:
                  textTheme.headlineSmall?.copyWith(color: tokens.textPrimary),
            ),
            const SizedBox(height: TiebananaMetrics.gapXs),
            Text(
              Version.displayVersion,
              style: textTheme.labelSmall?.copyWith(color: tokens.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

/// 开源许可全文。
///
/// MIT 要求分发时附带版权声明与许可声明，所以这里把
/// `lib/features/settings/data/license.dart` 的全文铺出来（可选可复制）。
class LicenseFullPage extends StatelessWidget {
  const LicenseFullPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: tokens.bg,
        foregroundColor: tokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text('开源许可'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TiebananaMetrics.gapLg),
        child: SelectableText(
          license,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.textSecondary,
                height: 1.5,
              ),
        ),
      ),
    );
  }
}
