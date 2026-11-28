import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/app/navigation/link_router.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/settings/data/license.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/update/data/version.dart';
import 'package:tiebanana/features/update/state/update_reminder.dart';
import 'package:tiebanana/features/update/widgets/update_badge.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/layout/page_wrap.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/adaptive_panel.dart';
import 'package:tiebanana/shared/widgets/app_toast.dart';
import 'package:tiebanana/shared/widgets/desktop_panel.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';
import 'package:tiebanana/shared/widgets/setting_group.dart';

/// 作者信息；GitHub 主页用于「关于」页的作者入口。
const String _authorName = 'Aobanana-chan';
const String _authorGithubUrl = 'https://github.com/Aobanana-chan';

/// 「关于 Tiebanana」页面：
/// - `≥ 720dp` 接入 `DesktopShellFrame` + `PageWrap(1060)` + `DesktopPageHeader`：
///   - `≥ 900dp` 左 `304/276dp` 停靠品牌与运行档案卡 + 右 `1fr` 更新入口/项目/声明卡；
///   - `720–899dp` 顶部满宽横向品牌卡 + 下方满宽卡片组；
///   - 开源许可打开居中 `560dp` 对话框（支持一键复制全文）。
/// - `< 720dp` 保持同一套「品牌档案卡 + 版本与多平台更新卡 + 作者/仓库/许可卡 + 声明卡」视觉层级。
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static T? _maybeRead<T>(BuildContext context, {bool listen = true}) {
    try {
      return Provider.of<T>(context, listen: listen);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // 移动端或 Android 上补全本机 ABI 标签展示。
    Version.detectDeviceAbi().then((String? abi) {
      if (mounted && abi != null) {
        setState(() {});
      }
    });
  }

  bool _readAutoCheck(BuildContext context) {
    final APPSettingProvider? provider =
        _maybeRead<APPSettingProvider>(context);
    return provider?.checkUpdateAutomatically ??
        Global.setting.checkUpdateAutomaticlly;
  }

  void _setAutoCheck(BuildContext context, bool value) {
    final APPSettingProvider? provider =
        _maybeRead<APPSettingProvider>(context, listen: false);
    if (provider != null) {
      provider.checkUpdateAutomatically = value;
      return;
    }
    setState(() {
      Global.setting.checkUpdateAutomaticlly = value;
      Global.saveProfile();
      UpdateReminder.refreshDot();
    });
  }

  void _openUpdate(BuildContext context, {String? platform}) {
    Navigator.pushNamed(context, PageRouter.appUpdate, arguments: platform);
  }

  Future<void> _copyText(
    BuildContext context,
    String text,
    String toastMessage,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!context.mounted) return;
      Fluttertoast.showToast(msg: toastMessage);
    } catch (_) {
      if (!context.mounted) return;
      Fluttertoast.showToast(msg: '复制失败');
    }
  }

  void _openLicense(BuildContext context) {
    if (!AppBreakpoints.isDesktop(context)) {
      Navigator.push(
        context,
        appPageRoute<void>(
          builder: (BuildContext context) => const LicenseFullPage(),
        ),
      );
      return;
    }
    showAdaptivePanel<void>(
      context: context,
      maxWidth: 560,
      maxHeightFactor: 0.78,
      builder: (BuildContext dialogContext) => _DesktopLicenseModal(
        onCopy: () => _copyText(
          dialogContext,
          license,
          '已复制 MIT 开源许可全文',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (AppBreakpoints.isDesktopWidth(width)) {
      return _buildDesktop(context, width);
    }
    return _buildMobile(context);
  }

  Widget _buildDesktop(BuildContext context, double width) {
    final bool twoCol = AppBreakpoints.isTwoColumnWidth(width);
    final double dockWidth = width >= 1100 ? 304 : 276;
    final bool autoCheck = _readAutoCheck(context);

    return DesktopShellFrame(
      activeTab: -1,
      activeAbout: true,
      title: '关于 Tiebanana',
      subtitle: '个人与设置 · ${Version.displayVersion}',
      child: SingleChildScrollView(
        child: PageWrap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const DesktopPageHeader(
                title: '关于 Tiebanana',
                subtitle: '版本档案、多平台更新入口、开源许可与项目说明',
              ),
              if (twoCol)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: dockWidth,
                      child: _AboutBrandDockCard(
                        horizontal: false,
                        onCopyEnv: () => _copyText(
                          context,
                          'Tiebanana ${Version.displayVersion} (${Version.currentPlatformLabel})',
                          '已复制环境摘要：${Version.displayVersion}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailCards(context, autoCheck),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _AboutBrandDockCard(
                      horizontal: true,
                      onCopyEnv: () => _copyText(
                        context,
                        'Tiebanana ${Version.displayVersion} (${Version.currentPlatformLabel})',
                        '已复制环境摘要：${Version.displayVersion}',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildDetailCards(context, autoCheck),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool autoCheck = _readAutoCheck(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.bg,
        foregroundColor: tokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text('关于'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          TiebananaMetrics.pageGutter,
          TiebananaMetrics.gapSm,
          TiebananaMetrics.pageGutter,
          TiebananaMetrics.gapXl,
        ),
        children: <Widget>[
          _AboutBrandDockCard(
            horizontal: false,
            onCopyEnv: () => _copyText(
              context,
              'Tiebanana ${Version.displayVersion} (${Version.currentPlatformLabel})',
              '已复制环境摘要：${Version.displayVersion}',
            ),
          ),
          const SizedBox(height: 14),
          _buildDetailCards(context, autoCheck),
        ],
      ),
    );
  }

  /// 右侧 / 竖屏下方三张统一卡片（版本与多平台更新 + 作者仓库许可 + 声明）。
  Widget _buildDetailCards(BuildContext context, bool autoCheck) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DesktopPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ValueListenableBuilder<bool>(
                valueListenable: UpdateReminder.showDot,
                builder: (BuildContext context, bool showDot, Widget? _) {
                  final String? detected = UpdateReminder.detectedVersion;
                  final bool highlight = showDot && detected != null;
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color:
                          highlight ? tokens.primaryContainer : tokens.fill,
                      borderRadius: TiebananaMetrics.brMd,
                    ),
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        final Widget infoBlock = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                if (highlight) ...<Widget>[
                                  const UpdateBadge(),
                                  const SizedBox(width: 7),
                                ],
                                Flexible(
                                  child: Text(
                                    highlight
                                        ? '发现新版本 $detected'
                                        : '当前版本 ${Version.displayVersion}',
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: highlight
                                          ? tokens.onPrimaryContainer
                                          : tokens.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              highlight
                                  ? '含 Android / Windows / iOS 安装包与校验'
                                  : '支持 Android / Windows / iOS 多平台下载与 SHA-256 校验',
                              style: textTheme.bodySmall?.copyWith(
                                color: highlight
                                    ? tokens.onPrimaryContainer
                                        .withValues(alpha: 0.85)
                                    : tokens.textSecondary,
                              ),
                            ),
                          ],
                        );

                        final Widget ctaButton = highlight
                            ? FilledButton(
                                onPressed: () => _openUpdate(context),
                                style: FilledButton.styleFrom(
                                  backgroundColor: tokens.primary,
                                  foregroundColor: tokens.accentOn,
                                  minimumSize: const Size(0, 32),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: TiebananaMetrics.brCtl,
                                  ),
                                  textStyle: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: const Text('查看更新与下载'),
                              )
                            : FilledButton.tonal(
                                onPressed: () => _openUpdate(context),
                                style: FilledButton.styleFrom(
                                  backgroundColor: tokens.primaryContainer,
                                  foregroundColor: tokens.onPrimaryContainer,
                                  minimumSize: const Size(0, 32),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: TiebananaMetrics.brCtl,
                                  ),
                                  textStyle: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: const Text('检查更新'),
                              );

                        if (constraints.maxWidth < 330) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              infoBlock,
                              const SizedBox(height: 10),
                              ctaButton,
                            ],
                          );
                        }

                        return Row(
                          children: <Widget>[
                            Expanded(child: infoBlock),
                            const SizedBox(width: 12),
                            ctaButton,
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      '支持平台：',
                      style: textTheme.labelMedium?.copyWith(
                        color: tokens.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _PlatformChip(
                      label: 'Android · APK',
                      activeHost: Version.currentPlatformKey == 'android',
                      onTap: () => _openUpdate(context, platform: 'android'),
                    ),
                    _PlatformChip(
                      label: 'Windows · x64 ZIP',
                      activeHost: Version.currentPlatformKey == 'windows',
                      onTap: () => _openUpdate(context, platform: 'windows'),
                    ),
                    _PlatformChip(
                      label: 'iOS · 未签名 IPA',
                      activeHost: Version.currentPlatformKey == 'ios',
                      onTap: () => _openUpdate(context, platform: 'ios'),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: tokens.line),
              _AboutActionRow(
                icon: Icons.download_rounded,
                title: '启动时自动检查更新',
                subtitle: '同步自应用设置 · 检测到正式版时提示更新日志',
                trailing: SettingSwitch(
                  value: autoCheck,
                  onChanged: (bool value) => _setAutoCheck(context, value),
                ),
                onTap: () => _setAutoCheck(context, !autoCheck),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DesktopPanel(
          child: Column(
            children: <Widget>[
              _AboutActionRow(
                icon: Icons.person_outline_rounded,
                title: '作者',
                subtitle: 'GitHub 个人主页',
                value: _authorName,
                trailingIcon: Icons.open_in_new_rounded,
                onTap: () => AppUtil.openLink(context, _authorGithubUrl),
              ),
              Divider(height: 1, thickness: 1, color: tokens.line),
              _AboutActionRow(
                icon: Icons.code_rounded,
                title: '项目仓库',
                subtitle: Version.repositoryUrl,
                trailing: IconButton(
                  tooltip: '复制仓库地址',
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints.tightFor(width: 28, height: 28),
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.copy_rounded,
                      size: 16, color: tokens.textTertiary),
                  onPressed: () =>
                      _copyText(context, Version.repositoryUrl, '已复制项目仓库地址'),
                ),
                trailingIcon: Icons.open_in_new_rounded,
                onTap: () => AppUtil.openLink(context, Version.repositoryUrl),
              ),
              Divider(height: 1, thickness: 1, color: tokens.line),
              _AboutActionRow(
                icon: Icons.description_outlined,
                title: '开源许可',
                subtitle: 'Copyright (c) 2026 Tiebanana contributors',
                value: 'MIT',
                trailingIcon: Icons.chevron_right_rounded,
                onTap: () => _openLicense(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DesktopPanel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            'Tiebanana 是基于 Flutter 的非官方第三方百度贴吧客户端，与百度官方无关联 · 以 MIT 许可开放源代码',
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: tokens.textTertiary,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

class _AboutActionRow extends StatelessWidget {
  const _AboutActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.value,
    this.trailing,
    this.trailingIcon,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? value;
  final Widget? trailing;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tokens.fill,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 17, color: tokens.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 11.5,
                      color: tokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (value != null) ...<Widget>[
              const SizedBox(width: 8),
              Text(
                value!,
                style: textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 8),
              trailing!,
            ],
            if (trailingIcon != null) ...<Widget>[
              const SizedBox(width: 6),
              Icon(
                trailingIcon,
                size: trailingIcon == Icons.open_in_new_rounded ? 14 : 18,
                color: tokens.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AboutBrandDockCard extends StatelessWidget {
  const _AboutBrandDockCard({
    required this.horizontal,
    required this.onCopyEnv,
  });

  final bool horizontal;
  final VoidCallback onCopyEnv;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    final Widget heroContent = horizontal
        ? Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  tokens.primaryContainer,
                  Color.lerp(tokens.primaryContainer, tokens.surface, 0.78)!,
                ],
              ),
            ),
            child: Row(
              children: <Widget>[
                const _BrandIcon(size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const _WordmarkText(fontSize: 22),
                      const SizedBox(height: 4),
                      Text(
                        '轻一点，逛贴吧。',
                        style: textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _BrandPills(),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  tokens.primaryContainer,
                  Color.lerp(tokens.primaryContainer, tokens.surface, 0.78)!,
                ],
              ),
              border: Border(bottom: BorderSide(color: tokens.line)),
            ),
            child: Column(
              children: <Widget>[
                const _BrandIcon(size: 72),
                const SizedBox(height: 12),
                const _WordmarkText(fontSize: 25),
                const SizedBox(height: 4),
                Text(
                  '轻一点，逛贴吧。',
                  style: textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                const _BrandPills(),
              ],
            ),
          );

    final Widget ledger = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _LedgerRow(
            label: '应用版本',
            value: Version.displayVersion,
            trailing: IconButton(
              tooltip: '复制环境信息',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              padding: EdgeInsets.zero,
              onPressed: onCopyEnv,
              icon: Icon(Icons.copy_rounded,
                  size: 15, color: tokens.textTertiary),
            ),
          ),
          const SizedBox(height: 8),
          _LedgerRow(
            label: '运行平台',
            value: Version.currentPlatformLabel,
          ),
          const SizedBox(height: 8),
          const _LedgerRow(
            label: '发布源',
            value: 'GitHub Releases',
          ),
          const SizedBox(height: 8),
          const _LedgerRow(
            label: '开源协议',
            value: 'MIT License',
          ),
        ],
      ),
    );

    if (horizontal) {
      return DesktopPanel(
        borderRadius: TiebananaMetrics.brXl,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: heroContent),
              VerticalDivider(width: 1, thickness: 1, color: tokens.line),
              SizedBox(width: 244, child: Center(child: ledger)),
            ],
          ),
        ),
      );
    }

    return DesktopPanel(
      borderRadius: TiebananaMetrics.brXl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          heroContent,
          ledger,
        ],
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: TiebananaMetrics.brLg,
        child: Image.asset(
          'assets/icon/ic_launcher_round.png',
          width: size,
          height: size,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) =>
                  Container(
            width: size,
            height: size,
            color: tokens.primaryContainer,
            alignment: Alignment.center,
            child: Icon(
              Icons.chat_bubble_rounded,
              size: size * 0.46,
              color: tokens.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _WordmarkText extends StatelessWidget {
  const _WordmarkText({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Text(
      'Tiebanana',
      style: TextStyle(
        fontFamily: 'TiebananaWordmark',
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
        height: 1.15,
      ),
    );
  }
}

class _BrandPills extends StatelessWidget {
  const _BrandPills();

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: <Widget>[
        _SmallPill(
          label: Version.displayVersion,
          background: tokens.primaryContainer,
          foreground: tokens.onPrimaryContainer,
        ),
        _SmallPill(
          label: 'MIT 开源',
          background: tokens.fill,
          foreground: tokens.textSecondary,
        ),
      ],
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: TiebananaMetrics.brPill,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: tokens.textTertiary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: textTheme.bodySmall?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 4),
          trailing!,
        ],
      ],
    );
  }
}

class _PlatformChip extends StatelessWidget {
  const _PlatformChip({
    required this.label,
    required this.activeHost,
    required this.onTap,
  });

  final String label;
  final bool activeHost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Material(
      color: tokens.fill,
      borderRadius: TiebananaMetrics.brPill,
      child: InkWell(
        borderRadius: TiebananaMetrics.brPill,
        hoverColor: tokens.primaryContainer.withValues(alpha: 0.7),
        onTap: onTap,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (activeHost) ...<Widget>[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: tokens.assistantBadgeForeground,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11.5,
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopLicenseModal extends StatelessWidget {
  const _DesktopLicenseModal({required this.onCopy});

  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '开源许可 · MIT License',
                  style: textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: tokens.textSecondary),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: tokens.line),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tokens.fill,
                borderRadius: TiebananaMetrics.brSm,
              ),
              child: SelectableText(
                license,
                style: textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: tokens.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: tokens.line),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('复制许可全文'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 开源许可全文（窄屏独立页面）。
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
        actions: <Widget>[
          IconButton(
            tooltip: '复制全文',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: license));
              if (!context.mounted) return;
              Fluttertoast.showToast(msg: '已复制 MIT 开源许可全文');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TiebananaMetrics.gapLg),
        child: DesktopPanel(
          padding: const EdgeInsets.all(TiebananaMetrics.gapLg),
          child: SelectableText(
            license,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: tokens.textSecondary,
                  height: 1.6,
                ),
          ),
        ),
      ),
    );
  }
}
