import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:tiebanana/features/update/data/version.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:url_launcher/url_launcher_string.dart';

///App更新页面

class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  UpdateCheckResult? _result;
  bool _loading = true;
  String? _deviceAbi;

  @override
  void initState() {
    super.initState();
    _check();
    _detectDeviceAbi();
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
    final UpdateCheckResult result = await Version.checkUpdate();
    if (!mounted) {
      return;
    }
    setState(() {
      _result = result;
      _loading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.surface,
      appBar: AppBar(
        title: const Text("更新APP"),
        actions: <Widget>[
          IconButton(
            tooltip: '重新检查',
            onPressed: _loading ? null : _check,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _check,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(10),
          children: <Widget>[
            Center(
              child: Image.asset(
                "assets/icon/ic_launcher_round.png",
                height: 50,
                width: 50,
                errorBuilder: (BuildContext context, Object error,
                        StackTrace? stackTrace) =>
                    Icon(
                  Icons.chat_bubble_rounded,
                  size: 50,
                  color: tokens.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text("当前版本：${Version.displayVersion}")),
            const SizedBox(height: 4),
            _buildLatestVersion(tokens),
            const SizedBox(height: 8),
            if (_loading && _result == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_result == null || _result!.failed)
              _buildFailure()
            else if (_result!.hasUpdate)
              ..._buildUpdateContent(tokens, _result!)
            else
              const Center(child: Text("已经是最新版本")),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestVersion(TiebananaTokens tokens) {
    if (_loading && _result == null) {
      return const Center(child: Text("最新版本：检查中…"));
    }
    final String? latest = _result?.latestVersion;
    if (latest == null) {
      return const Center(child: Text("最新版本：未知"));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text("最新版本：$latest"),
        if (_result!.hasUpdate) ...<Widget>[
          const SizedBox(width: 4),
          Icon(
            Icons.brightness_1,
            color: tokens.danger,
            size: 8,
          ),
        ],
      ],
    );
  }

  Widget _buildFailure() {
    return Column(
      children: <Widget>[
        const Text("检查更新失败，请检查网络后重试。"),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _check,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text("重试"),
        ),
      ],
    );
  }

  List<Widget> _buildUpdateContent(
    TiebananaTokens tokens,
    UpdateCheckResult result,
  ) {
    final String notes = result.notes.trim();
    return <Widget>[
      if (notes.isNotEmpty)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(TiebananaMetrics.gapMd),
          decoration: BoxDecoration(
            color: tokens.bg,
            borderRadius: TiebananaMetrics.brLg,
          ),
          child: MarkdownBody(
            data: notes,
            shrinkWrap: true,
            selectable: true,
          ),
        ),
      _buildDownloadSection(result),
    ];
  }

  Widget _buildDownloadSection(UpdateCheckResult result) {
    final List<AndroidUpdateAsset> assets = <AndroidUpdateAsset>[
      for (final String abi in androidUpdateAbis)
        if (result.downloads[abi] != null) result.downloads[abi]!,
    ];

    if (!Version.isAndroidPlatform) {
      return _buildFallback(
        result,
        "当前平台暂不支持应用内更新，请前往发布页查看。",
      );
    }
    if (assets.isEmpty) {
      return _buildFallback(
        result,
        "本次发布未找到可用的 Android 安装包，请前往发布页查看。",
      );
    }

    // 当前设备 ABI 排在最前，并用实心按钮标为推荐。
    final int recommendedIndex = assets
        .indexWhere((AndroidUpdateAsset asset) => asset.abi == _deviceAbi);
    if (recommendedIndex > 0) {
      final AndroidUpdateAsset recommended = assets.removeAt(recommendedIndex);
      assets.insert(0, recommended);
    }

    final List<AndroidUpdateAsset> digestAssets = assets
        .where((AndroidUpdateAsset asset) => asset.sha256 != null)
        .toList();

    return Column(
      children: <Widget>[
        for (final AndroidUpdateAsset asset in assets)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: asset.abi == _deviceAbi
                ? FilledButton.icon(
                    onPressed: () => _launch(asset.url),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text("下载 ${asset.abi} 安装包（推荐）"),
                  )
                : OutlinedButton.icon(
                    onPressed: () => _launch(asset.url),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text("下载 ${asset.abi} 安装包"),
                  ),
          ),
        if (digestAssets.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text("SHA-256 校验值"),
            subtitle: const Text("下载后可在文件管理器或系统工具中核对"),
            children: <Widget>[
              for (final AndroidUpdateAsset asset in digestAssets)
                _buildDigestTile(asset),
            ],
          ),
        TextButton(
          onPressed: () => _showAbiHelp(),
          child: const Text("如何选择?"),
        ),
      ],
    );
  }

  Widget _buildDigestTile(AndroidUpdateAsset asset) {
    final String digest = asset.sha256!;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(asset.abi),
      subtitle: SelectableText(
        digest,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
      ),
      trailing: IconButton(
        tooltip: '复制 SHA-256',
        icon: const Icon(Icons.copy_rounded, size: 18),
        onPressed: () => _copyDigest(asset.abi, digest),
      ),
    );
  }

  Future<void> _copyDigest(String abi, String digest) async {
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
      SnackBar(content: Text('已复制 $abi 的 SHA-256')),
    );
  }

  Widget _buildFallback(UpdateCheckResult result, String message) {
    final String url = result.releasePageUrl ?? Version.releasesPageUrl;
    return Column(
      children: <Widget>[
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _launch(url),
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: const Text("打开发布页"),
        ),
      ],
    );
  }

  void _showAbiHelp() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              child: const Text(
                  '''         大部分2016年以后的主流手机都可选择arm64-v8a,使用arm64-v8a可获得最佳的性能。
        几乎所有的手机都可使用armeabi-v7a,若无法使用arm64-v8a,可使用armeabi-v7a。
        x86_64设备很少,而且一般为平板,若不是确定设备为x86_64架构,请优先使用其他版本。'''),
            )
          ],
        );
      },
    );
  }
}
