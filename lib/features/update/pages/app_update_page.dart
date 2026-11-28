import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiebanana/features/update/data/version.dart';
import 'package:tiebanana/features/update/state/update_reminder.dart';
import 'package:tiebanana/features/update/widgets/update_release_notes.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/layout/page_wrap.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/desktop_panel.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';
import 'package:tiebanana/shared/widgets/tiebanana_refresh_indicator.dart';
import 'package:url_launcher/url_launcher_string.dart';

enum _UpdatePlatformTab { android, windows, ios }

/// 多平台应用更新中心。
///
/// - `>= 720dp` 接入 `DesktopShellFrame` + `PageWrap(1060)` + `DesktopPageHeader`；
/// - `>= 900dp` 采用「顶置版本 Hero + 左栏更新日志 + 右栏多平台下载与 SHA-256 校验」；
/// - `< 900dp` 自动收束为单栏，且将多平台安装包卡置于更新日志之前，方便直接下载。
class UpdatePage extends StatefulWidget {
  const UpdatePage({
    super.key,
    this.checkUpdate = Version.checkUpdate,
    this.initialPlatform,
  });

  final Future<UpdateCheckResult> Function() checkUpdate;

  /// 可选预选平台键：`'android'` / `'windows'` / `'ios'`。
  final String? initialPlatform;

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  UpdateCheckResult? _result;
  bool _loading = true;
  String? _deviceAbi;
  late _UpdatePlatformTab _selectedTab;
  bool _initializedTab = false;
  final Set<String> _expandedShas = <String>{};
  bool _abiHelpExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = _resolveInitialTab();
    _initializedTab = true;
    _check();
    _detectDeviceAbi();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 单元测试或平台变体切换时同步初始平台（尚未手动切过 Tab 时生效）。
    if (!_initializedTab) {
      _selectedTab = _resolveInitialTab();
      _initializedTab = true;
    }
  }

  _UpdatePlatformTab _resolveInitialTab() {
    final String? explicit = widget.initialPlatform?.toLowerCase();
    if (explicit == 'android') return _UpdatePlatformTab.android;
    if (explicit == 'windows') return _UpdatePlatformTab.windows;
    if (explicit == 'ios') return _UpdatePlatformTab.ios;
    return switch (Version.currentPlatformKey) {
      'windows' => _UpdatePlatformTab.windows,
      'ios' => _UpdatePlatformTab.ios,
      _ => _UpdatePlatformTab.android,
    };
  }

  Future<void> _detectDeviceAbi() async {
    final String? abi = await Version.detectDeviceAbi();
    if (!mounted || abi == null) {
      return;
    }
    setState(() => _deviceAbi = abi);
  }

  Future<void> _check() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    final UpdateCheckResult result = await widget.checkUpdate();
    if (!mounted) {
      return;
    }
    setState(() {
      _result = result;
      _loading = false;
    });
    try {
      await UpdateReminder.markViewed(result);
    } catch (error) {
      debugPrint('保存更新已读状态失败：$error');
    }
  }

  Future<void> _launch(String url) async {
    bool opened = false;
    try {
      opened = await launchUrlString(
        url,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(),
      );
    } catch (error) {
      debugPrint('打开更新链接失败：$error');
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开链接，请稍后重试')),
      );
    }
  }

  Future<void> _copyDigest(String label, String digest) async {
    try {
      await Clipboard.setData(ClipboardData(text: digest));
    } catch (error) {
      debugPrint('复制 SHA-256 失败：$error');
      return;
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制 $label 的 SHA-256')),
    );
  }

  Future<void> _toggleIgnoreVersion(String version) async {
    if (UpdateReminder.isIgnored(version)) {
      await UpdateReminder.unignore(version);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已恢复新版本提醒')),
        );
      }
    } else {
      await UpdateReminder.ignore(version);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已跳过 $version 的提醒')),
        );
      }
    }
    if (mounted) setState(() {});
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
    final double sideWidth = width >= 1100 ? 384 : 340;

    return DesktopShellFrame(
      activeTab: -1,
      activeAbout: true,
      title: '更新与多平台下载',
      subtitle: '关于 Tiebanana · GitHub Releases',
      onRefresh: _check,
      child: TiebananaRefreshIndicator(
        onRefresh: _check,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageWrap(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                DesktopPageHeader(
                  title: '更新与多平台下载',
                  subtitle: '支持跨平台获取 Android APK、Windows x64 便携包与 iOS 未签名 IPA，并核对 SHA-256 摘要',
                  tools: <Widget>[
                    OutlinedButton.icon(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).maybePop();
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('返回'),
                    ),
                  ],
                ),
                _buildHeroCard(context),
                const SizedBox(height: 16),
                ..._buildBodySections(
                  context,
                  twoCol: twoCol,
                  sideWidth: sideWidth,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.bg,
        foregroundColor: tokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text('更新与多平台下载'),
        actions: <Widget>[
          IconButton(
            tooltip: '重新检查',
            onPressed: _loading ? null : _check,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: TiebananaRefreshIndicator(
        onRefresh: _check,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            TiebananaMetrics.pageGutter,
            TiebananaMetrics.gapSm,
            TiebananaMetrics.pageGutter,
            TiebananaMetrics.gapXl,
          ),
          children: <Widget>[
            _buildHeroCard(context),
            const SizedBox(height: 12),
            ..._buildBodySections(
              context,
              twoCol: false,
              sideWidth: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBodySections(
    BuildContext context, {
    required bool twoCol,
    required double sideWidth,
  }) {
    if (_loading && _result == null) {
      return <Widget>[_buildLoadingBody(twoCol: twoCol, sideWidth: sideWidth)];
    }
    final UpdateCheckResult? result = _result;
    if (result == null || result.failed) {
      return <Widget>[_buildFailureCard(context, result)];
    }

    final Widget notesCard = _buildReleaseNotesCard(context, result);
    final Widget packagesCard = _buildMultiPlatformCard(context, result);

    if (twoCol) {
      return <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: notesCard),
            const SizedBox(width: 16),
            SizedBox(width: sideWidth, child: packagesCard),
          ],
        ),
      ];
    }

    // 单栏布局把多平台安装包排在更新日志前面，方便半屏与手机端立即下载。
    return <Widget>[
      packagesCard,
      const SizedBox(height: 14),
      notesCard,
    ];
  }

  Widget _buildHeroCard(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final UpdateCheckResult? result = _result;
    final bool isLoadingInitial = _loading && result == null;
    final bool failed = !isLoadingInitial && (result == null || result.failed);
    final bool hasUpdate = !isLoadingInitial && !failed && (result?.hasUpdate ?? false);
    final String? latest = result?.latestVersion;
    final String releaseUrl = result?.releasePageUrl ?? Version.releasesPageUrl;
    final String? publishedLabel = _formatPublishedDate(result?.publishedAt);

    final String titleText;
    final String badgeLabel;
    final Color badgeBg;
    final Color badgeFg;

    if (isLoadingInitial) {
      titleText = '正在检查 GitHub Releases…';
      badgeLabel = '检查中';
      badgeBg = tokens.fill;
      badgeFg = tokens.textSecondary;
    } else if (failed) {
      titleText = '检查更新失败';
      badgeLabel = '网络异常';
      badgeBg = tokens.danger.withValues(alpha: 0.14);
      badgeFg = tokens.danger;
    } else if (hasUpdate) {
      titleText = '发现新版本 ${latest ?? ''}';
      badgeLabel = '有新版本';
      badgeBg = tokens.primaryContainer;
      badgeFg = tokens.onPrimaryContainer;
    } else {
      titleText = '当前已是最新版本';
      badgeLabel = '已最新';
      badgeBg = tokens.assistantBadgeBackground;
      badgeFg = tokens.assistantBadgeForeground;
    }

    final String latestText = isLoadingInitial
        ? '最新版本：检查中…'
        : (latest == null ? '最新版本：未知' : '最新版本：$latest');

    final String? hostPrimaryUrl = _hostPrimaryDownloadUrl(result);
    final bool isIgnored =
        hasUpdate && latest != null && UpdateReminder.isIgnored(latest);

    return DesktopPanel(
      borderRadius: TiebananaMetrics.brXl,
      padding: const EdgeInsets.all(18),
      child: Wrap(
        spacing: 16,
        runSpacing: 14,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  borderRadius: TiebananaMetrics.brMd,
                  boxShadow: tokens.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: TiebananaMetrics.brMd,
                  child: Image.asset(
                    'assets/icon/ic_launcher_round.png',
                    width: 54,
                    height: 54,
                    errorBuilder: (BuildContext context, Object error,
                            StackTrace? stackTrace) =>
                        Container(
                      width: 54,
                      height: 54,
                      color: tokens.primaryContainer,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.chat_bubble_rounded,
                        size: 26,
                        color: tokens.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            titleText,
                            style: textTheme.titleMedium?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          _StatusBadge(
                            label: badgeLabel,
                            background: badgeBg,
                            foreground: badgeFg,
                          ),
                          if (isIgnored)
                            _StatusBadge(
                              label: '已跳过提醒',
                              background: tokens.managerBadgeBackground,
                              foreground: tokens.managerBadgeForeground,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: <Widget>[
                          Text(
                            '当前版本：${Version.displayVersion}',
                            style: textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                          Text(
                            latestText,
                            style: textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                          Text(
                            '运行平台：${Version.currentPlatformLabel}',
                            style: textTheme.bodySmall?.copyWith(
                              color: tokens.textTertiary,
                            ),
                          ),
                          if (publishedLabel != null)
                            Text(
                              '发布于 $publishedLabel',
                              style: textTheme.bodySmall?.copyWith(
                                color: tokens.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (isLoadingInitial)
                const FilledButton(
                  onPressed: null,
                  child: Text('检查中…'),
                )
              else if (failed)
                FilledButton.icon(
                  onPressed: _loading ? null : _check,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('重试检查'),
                )
              else if (hasUpdate && hostPrimaryUrl != null)
                FilledButton.icon(
                  onPressed: () => _launch(hostPrimaryUrl),
                  icon: const Icon(Icons.download_rounded, size: 17),
                  label: const Text('下载推荐包'),
                )
              else if (hasUpdate)
                FilledButton.icon(
                  onPressed: () => _launch(releaseUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: const Text('前往发布页'),
                )
              else
                FilledButton.tonalIcon(
                  onPressed: _loading ? null : _check,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('重新检查'),
                ),
              if (hasUpdate && latest != null)
                OutlinedButton(
                  onPressed: () => _toggleIgnoreVersion(latest),
                  child: Text(isIgnored ? '恢复提醒' : '跳过此版本'),
                ),
              OutlinedButton.icon(
                onPressed: () => _launch(releaseUrl),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('发布页'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _hostPrimaryDownloadUrl(UpdateCheckResult? result) {
    if (result == null) return null;
    switch (Version.currentPlatformKey) {
      case 'windows':
        return result.effectiveWindowsUrl;
      case 'ios':
        return result.effectiveIosUrl;
      case 'android':
        final List<AndroidUpdateAsset> list = _orderedAndroidAssets(result);
        if (list.isEmpty) return null;
        return list.first.url;
      default:
        return null;
    }
  }

  Widget _buildLoadingBody({required bool twoCol, required double sideWidth}) {
    final Widget notesSkel = DesktopPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          SkeletonBox(width: 140, height: 18),
          SizedBox(height: 16),
          SkeletonBox(height: 14),
          SizedBox(height: 10),
          SkeletonBox(width: 260, height: 14),
          SizedBox(height: 16),
          SkeletonBox(height: 110, radius: TiebananaMetrics.radiusSm),
        ],
      ),
    );

    final Widget dlSkel = DesktopPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const <Widget>[
          SkeletonBox(height: 36, radius: TiebananaMetrics.radiusSm),
          SizedBox(height: 14),
          SkeletonBox(height: 78, radius: TiebananaMetrics.radiusMd),
          SizedBox(height: 10),
          SkeletonBox(height: 78, radius: TiebananaMetrics.radiusMd),
        ],
      ),
    );

    if (twoCol) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: notesSkel),
          const SizedBox(width: 16),
          SizedBox(width: sideWidth, child: dlSkel),
        ],
      );
    }

    return Column(
      children: <Widget>[
        dlSkel,
        const SizedBox(height: 14),
        notesSkel,
      ],
    );
  }

  Widget _buildFailureCard(BuildContext context, UpdateCheckResult? result) {
    final String url = result?.releasePageUrl ?? Version.releasesPageUrl;
    return DesktopPanel(
      child: StateView(
        icon: Icons.cloud_off_rounded,
        title: '检查更新失败，请检查网络后重试。',
        body: '可能是 GitHub API 超时或受到网络限制，你可以重新检查，或直接在浏览器打开发布页手动下载安装包。',
        primaryLabel: '重试',
        primaryIcon: Icons.refresh_rounded,
        onPrimary: _loading ? null : _check,
        secondaryLabel: '打开发布页',
        onSecondary: () => _launch(url),
      ),
    );
  }

  Widget _buildReleaseNotesCard(BuildContext context, UpdateCheckResult result) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String releaseUrl = result.releasePageUrl ?? Version.releasesPageUrl;
    final String? versionTag = result.latestVersion;

    return DesktopPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      '更新日志',
                      style: textTheme.titleSmall?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (versionTag != null)
                      _StatusBadge(
                        label: versionTag,
                        background: tokens.primaryContainer,
                        foreground: tokens.onPrimaryContainer,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _launch(releaseUrl),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('GitHub Release'),
              ),
            ],
          ),
          Divider(height: 20, thickness: 1, color: tokens.line),
          UpdateReleaseNotes(notes: result.notes, showHeader: false),
        ],
      ),
    );
  }

  Widget _buildMultiPlatformCard(BuildContext context, UpdateCheckResult result) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? hostKey = Version.currentPlatformKey;
    final String? tag = result.latestVersion;

    return DesktopPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '多平台安装包',
                    style: textTheme.titleSmall?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (tag != null)
                  _StatusBadge(
                    label: tag,
                    background: tokens.fill,
                    foreground: tokens.textSecondary,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PlatformSegmentBar(
              selected: _selectedTab,
              hostKey: hostKey,
              onChanged: (_UpdatePlatformTab next) =>
                  setState(() => _selectedTab = next),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: switch (_selectedTab) {
              _UpdatePlatformTab.android =>
                _buildAndroidTab(context, result),
              _UpdatePlatformTab.windows =>
                _buildWindowsTab(context, result),
              _UpdatePlatformTab.ios => _buildIosTab(context, result),
            },
          ),
          Divider(height: 1, thickness: 1, color: tokens.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '构建产物来自 GitHub Actions',
                    style: textTheme.labelSmall?.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () =>
                      _launch(result.releasePageUrl ?? Version.releasesPageUrl),
                  child: const Text('全部版本'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<AndroidUpdateAsset> _orderedAndroidAssets(UpdateCheckResult result) {
    final List<AndroidUpdateAsset> assets = <AndroidUpdateAsset>[
      for (final String abi in androidUpdateAbis)
        if (result.downloads[abi] != null) result.downloads[abi]!,
    ];
    final int recommendedIndex = assets
        .indexWhere((AndroidUpdateAsset asset) => asset.abi == _deviceAbi);
    if (recommendedIndex > 0) {
      final AndroidUpdateAsset recommended = assets.removeAt(recommendedIndex);
      assets.insert(0, recommended);
    }
    return assets;
  }

  Widget _buildAndroidTab(BuildContext context, UpdateCheckResult result) {
    final List<AndroidUpdateAsset> assets = _orderedAndroidAssets(result);
    if (assets.isEmpty) {
      return _buildMissingAsset(
        context,
        result,
        '本次发布未找到可用的 Android 安装包，请前往发布页查看。',
      );
    }

    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _PlatformNoticeBox(
          title: 'Android 正式签名 APK',
          body: _deviceAbi != null
              ? '已识别本机架构为 $_deviceAbi，已置顶并标为推荐；支持覆盖升级安装。'
              : '提供 3 种 CPU 架构分包，支持在手机端直接覆盖安装升级。',
          experimental: false,
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < assets.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 8),
          _buildAndroidAssetCard(context, assets[i]),
        ],
        const SizedBox(height: 8),
        InkWell(
          borderRadius: TiebananaMetrics.brSm,
          onTap: () => setState(() => _abiHelpExpanded = !_abiHelpExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: <Widget>[
                Icon(Icons.help_outline_rounded,
                    size: 16, color: tokens.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '如何选择 Android 架构（ABI）？',
                    style: textTheme.labelMedium?.copyWith(
                      color: tokens.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _abiHelpExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: tokens.primary,
                ),
              ],
            ),
          ),
        ),
        if (_abiHelpExpanded)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tokens.fill,
              borderRadius: TiebananaMetrics.brSm,
            ),
            child: Text(
              '• arm64-v8a：大多数 2016 年以后的主流 64 位手机首选，性能最佳。\n'
              '• armeabi-v7a：兼容较老 32 位设备，不确定型号时可选此版本。\n'
              '• x86_64：仅用于少数 x86 架构平板或桌面端模拟器。',
              style: textTheme.bodySmall?.copyWith(
                color: tokens.textSecondary,
                height: 1.55,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAndroidAssetCard(BuildContext context, AndroidUpdateAsset asset) {
    final bool recommended = asset.abi == _deviceAbi;
    final String? sizeText = _formatBytes(asset.sizeBytes);
    final String subtitle =
        sizeText == null ? asset.name : '${asset.name} · $sizeText';
    final String tag = switch (asset.abi) {
      'arm64-v8a' => '主流 64 位',
      'armeabi-v7a' => '32 位兼容',
      'x86_64' => '平板 / 模拟器',
      _ => asset.abi,
    };

    return _AssetDownloadCard(
      title: asset.abi,
      tag: recommended ? '本机推荐' : tag,
      highlighted: recommended,
      subtitle: subtitle,
      sha256: asset.sha256,
      shaExpanded: _expandedShas.contains('android:${asset.abi}'),
      onToggleSha: () => setState(() {
        final String key = 'android:${asset.abi}';
        if (!_expandedShas.remove(key)) _expandedShas.add(key);
      }),
      onCopySha: asset.sha256 == null
          ? null
          : () => _copyDigest(asset.abi, asset.sha256!),
      actionButton: recommended
          ? FilledButton.icon(
              onPressed: () => _launch(asset.url),
              icon: const Icon(Icons.download_rounded, size: 17),
              label: Text('下载 ${asset.abi} 安装包（推荐）'),
            )
          : OutlinedButton.icon(
              onPressed: () => _launch(asset.url),
              icon: const Icon(Icons.download_rounded, size: 17),
              label: Text('下载 ${asset.abi} 安装包'),
            ),
    );
  }

  Widget _buildWindowsTab(BuildContext context, UpdateCheckResult result) {
    final ReleasePackageAsset? asset = result.effectiveWindowsAsset;
    if (asset == null) {
      return _buildMissingAsset(
        context,
        result,
        '本次发布未找到 Windows x64 安装包，请前往发布页查看。',
      );
    }

    final String? sizeText = _formatBytes(asset.sizeBytes);
    final String subtitle =
        sizeText == null ? asset.name : '${asset.name} · $sizeText';
    final bool isHost = Version.currentPlatformKey == 'windows';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _PlatformNoticeBox(
          title: 'Windows 10 / 11 64 位便携压缩包',
          body: '解压后请保留整个 Tiebanana/ 目录，运行 tiebanana.exe；网页登录需系统已安装 WebView2 Runtime（Win11 一般自带）。',
          experimental: true,
        ),
        const SizedBox(height: 10),
        _AssetDownloadCard(
          title: 'Windows x64',
          tag: isHost ? '当前平台' : 'Win 10 / 11',
          highlighted: isHost,
          subtitle: subtitle,
          sha256: asset.sha256,
          shaExpanded: _expandedShas.contains('windows'),
          onToggleSha: () => setState(() {
            if (!_expandedShas.remove('windows')) _expandedShas.add('windows');
          }),
          onCopySha: asset.sha256 == null
              ? null
              : () => _copyDigest('Windows x64', asset.sha256!),
          actionButton: FilledButton.icon(
            onPressed: () => _launch(asset.url),
            icon: const Icon(Icons.download_rounded, size: 17),
            label: const Text('下载 Windows x64 ZIP'),
          ),
        ),
      ],
    );
  }

  Widget _buildIosTab(BuildContext context, UpdateCheckResult result) {
    final ReleasePackageAsset? asset = result.effectiveIosAsset;
    if (asset == null) {
      return _buildMissingAsset(
        context,
        result,
        '本次发布未找到 iOS 安装包，请前往发布页查看。',
      );
    }

    final String? sizeText = _formatBytes(asset.sizeBytes);
    final String subtitle =
        sizeText == null ? asset.name : '${asset.name} · $sizeText';
    final bool isHost = Version.currentPlatformKey == 'ios';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _PlatformNoticeBox(
          title: 'iOS 15.0+ 未签名 IPA',
          body: '尚未经过完整真机测试，不保证全部功能正常；下载后需使用自签工具自行签名并安装。',
          experimental: true,
        ),
        const SizedBox(height: 10),
        _AssetDownloadCard(
          title: 'iOS 通用 IPA',
          tag: isHost ? '当前平台' : '需自签',
          highlighted: isHost,
          subtitle: subtitle,
          sha256: asset.sha256,
          shaExpanded: _expandedShas.contains('ios'),
          onToggleSha: () => setState(() {
            if (!_expandedShas.remove('ios')) _expandedShas.add('ios');
          }),
          onCopySha: asset.sha256 == null
              ? null
              : () => _copyDigest('iOS IPA', asset.sha256!),
          actionButton: FilledButton.icon(
            onPressed: () => _launch(asset.url),
            icon: const Icon(Icons.download_rounded, size: 17),
            label: const Text('下载未签名 IPA'),
          ),
        ),
      ],
    );
  }

  Widget _buildMissingAsset(
    BuildContext context,
    UpdateCheckResult result,
    String message,
  ) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String url = result.releasePageUrl ?? Version.releasesPageUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.fill,
        borderRadius: TiebananaMetrics.brMd,
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.inventory_2_outlined,
              size: 28, color: tokens.textTertiary),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: tokens.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _launch(url),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('打开发布页'),
          ),
        ],
      ),
    );
  }

  static String? _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return null;
    const double mb = 1024 * 1024;
    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  static String? _formatPublishedDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final DateTime? dt = DateTime.tryParse(raw.trim())?.toLocal();
    if (dt == null) return null;
    final String m = dt.month.toString().padLeft(2, '0');
    final String d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }
}

class _PlatformSegmentBar extends StatelessWidget {
  const _PlatformSegmentBar({
    required this.selected,
    required this.hostKey,
    required this.onChanged,
  });

  final _UpdatePlatformTab selected;
  final String? hostKey;
  final ValueChanged<_UpdatePlatformTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tokens.fill,
        borderRadius: TiebananaMetrics.brSm,
      ),
      child: Row(
        children: <Widget>[
          _tab(context, _UpdatePlatformTab.android, 'Android', 'android'),
          _tab(context, _UpdatePlatformTab.windows, 'Windows', 'windows'),
          _tab(context, _UpdatePlatformTab.ios, 'iOS', 'ios'),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    _UpdatePlatformTab tab,
    String label,
    String keyName,
  ) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool on = selected == tab;
    final bool isHost = hostKey == keyName;

    return Expanded(
      child: Material(
        color: on ? tokens.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        elevation: on ? 1 : 0,
        shadowColor: tokens.shadow,
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => onChanged(tab),
          child: SizedBox(
            height: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (isHost) ...<Widget>[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: tokens.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: on
                            ? tokens.onPrimaryContainer
                            : tokens.textSecondary,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlatformNoticeBox extends StatelessWidget {
  const _PlatformNoticeBox({
    required this.title,
    required this.body,
    required this.experimental,
  });

  final String title;
  final String body;
  final bool experimental;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: experimental
            ? tokens.managerBadgeBackground.withValues(alpha: 0.45)
            : tokens.fill,
        borderRadius: TiebananaMetrics.brSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (experimental) ...<Widget>[
                _StatusBadge(
                  label: '实验性',
                  background: tokens.managerBadgeBackground,
                  foreground: tokens.managerBadgeForeground,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  title,
                  style: textTheme.labelMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: textTheme.bodySmall?.copyWith(
              color: tokens.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetDownloadCard extends StatelessWidget {
  const _AssetDownloadCard({
    required this.title,
    required this.tag,
    required this.highlighted,
    required this.subtitle,
    required this.sha256,
    required this.shaExpanded,
    required this.onToggleSha,
    required this.onCopySha,
    required this.actionButton,
  });

  final String title;
  final String tag;
  final bool highlighted;
  final String subtitle;
  final String? sha256;
  final bool shaExpanded;
  final VoidCallback onToggleSha;
  final VoidCallback? onCopySha;
  final Widget actionButton;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? tokens.primaryContainer.withValues(alpha: 0.25)
            : tokens.surface,
        borderRadius: TiebananaMetrics.brMd,
        border: Border.all(
          color: highlighted
              ? tokens.primary.withValues(alpha: 0.42)
              : tokens.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          title,
                          style: textTheme.titleSmall?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _StatusBadge(
                          label: tag,
                          background: highlighted
                              ? tokens.primaryContainer
                              : tokens.fill,
                          foreground: highlighted
                              ? tokens.onPrimaryContainer
                              : tokens.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        color: tokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: actionButton),
          if (sha256 != null) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.fill,
                borderRadius: TiebananaMetrics.brXs,
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    'SHA-256',
                    style: textTheme.labelSmall?.copyWith(
                      color: tokens.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: InkWell(
                      onTap: onToggleSha,
                      child: shaExpanded
                          ? SelectableText(
                              sha256!,
                              style: textTheme.labelSmall?.copyWith(
                                fontFamily: 'monospace',
                                color: tokens.textSecondary,
                              ),
                            )
                          : Text(
                              sha256!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                fontFamily: 'monospace',
                                color: tokens.textSecondary,
                              ),
                            ),
                    ),
                  ),
                  IconButton(
                    tooltip: '复制 SHA-256',
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints.tightFor(width: 28, height: 28),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.copy_rounded,
                        size: 16, color: tokens.textSecondary),
                    onPressed: onCopySha,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
