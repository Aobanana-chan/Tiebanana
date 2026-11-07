import 'package:device_info_plus/device_info_plus.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tiebanana/features/update/data/github_get_latest_version.dart';
import 'package:tiebanana/features/update/data/semantic_version.dart';

/// 更新检查结果。
enum UpdateStatus {
  /// 线上存在比当前安装版本更新的正式版。
  available,

  /// 当前已是最新版本。
  upToDate,

  /// 网络、解析或数据异常；调用方应允许重试。
  failed,
}

/// 支持的 Android ABI，同时也是更新页的展示顺序。
const List<String> androidUpdateAbis = <String>[
  'arm64-v8a',
  'armeabi-v7a',
  'x86_64',
];

/// 一次发布中某个 ABI 对应的安装包。
class AndroidUpdateAsset {
  const AndroidUpdateAsset({
    required this.abi,
    required this.name,
    required this.url,
    this.digest,
  });

  final String abi;
  final String name;
  final String url;

  /// GitHub Release 资产摘要，形如 `sha256:...`。
  final String? digest;

  /// 去掉 `sha256:` 前缀后的十六进制摘要；缺失或算法不是 SHA-256 时为 null。
  String? get sha256 {
    final String? value = digest?.trim();
    if (value == null || !value.toLowerCase().startsWith('sha256:')) {
      return null;
    }
    final String hex = value.substring(7).trim();
    return hex.isEmpty ? null : hex;
  }
}

/// 一次更新检查的不可变结果。
///
/// 不可变结果，自动检查与更新页共享同一份数据，
/// 页面据此展示“加载中 / 已最新 / 有新版本 / 失败”四态。
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.status,
    required this.currentVersion,
    this.latestVersion,
    this.notes = '',
    this.downloads = const <String, AndroidUpdateAsset>{},
    this.releasePageUrl,
    this.error,
  });

  final UpdateStatus status;

  /// 当前安装版本（不含 `v` 前缀），例如 `0.2.1`。
  final String currentVersion;

  /// 线上 Release 的 tag，例如 `v0.2.2`。
  final String? latestVersion;

  /// Release 正文（Markdown），可能为空。
  final String notes;

  /// ABI → 安装包；只包含本次 Release 实际提供的 ABI。
  final Map<String, AndroidUpdateAsset> downloads;

  /// Release 页面地址，资产缺失或非 Android 平台时作为兜底入口。
  final String? releasePageUrl;

  final Object? error;

  bool get hasUpdate => status == UpdateStatus.available;
  bool get failed => status == UpdateStatus.failed;
}

/// APP 版本与更新检查。
class Version {
  Version._();

  static const String _repository = 'Aobanana-chan/Tiebanana';
  static const String _latestReleaseApi =
      'https://api.github.com/repos/$_repository/releases/latest';

  /// 资产缺失或非 Android 平台时打开的发布页。
  static const String releasesPageUrl =
      'https://github.com/$_repository/releases/latest';

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: const <String, String>{
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'Tiebanana-UpdateChecker',
      },
    ),
  );

  static String _currentVersion = '';
  static Future<void>? _initFuture;
  static Future<UpdateCheckResult>? _inFlight;
  static String? _deviceAbi;

  /// 更新检查与 APK 下载只在 Android 上提供。
  static bool get isAndroidPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 当前安装版本，来自 `pubspec.yaml` 的 version（发布构建由 tag 注入）。
  static String get currentVersion => _currentVersion;

  /// 界面上展示的版本号。
  static String get displayVersion =>
      _currentVersion.isEmpty ? '未知' : 'v$_currentVersion';

  /// 读取运行时版本。应在界面展示前调用一次（见 `Global.init`）。
  static Future<void> init() {
    final Future<void>? existing = _initFuture;
    if (existing != null) {
      return existing;
    }
    final Future<void> future = _loadPackageInfo();
    _initFuture = future;
    return future;
  }

  static Future<void> _loadPackageInfo() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      _currentVersion = info.version;
    } catch (error) {
      // 测试环境或平台通道不可用时保持空值，界面显示“未知”。
      debugPrint('读取应用版本失败：$error');
    }
  }

  @visibleForTesting
  static void debugSetCurrentVersion(String value) {
    _currentVersion = value;
    _initFuture = Future<void>.value();
  }

  @visibleForTesting
  static void debugReset() {
    _currentVersion = '';
    _initFuture = null;
    _inFlight = null;
    _deviceAbi = null;
  }

  /// 读取当前设备的首选 ABI，用于在更新页把推荐安装包排在前面。
  ///
  /// 只认 [androidUpdateAbis] 里列出的 ABI；读取失败时返回 null，
  /// 页面仍会展示 Release 提供的全部安装包。
  static Future<String?> detectDeviceAbi() async {
    final String? cached = _deviceAbi;
    if (cached != null) {
      return cached;
    }
    if (!isAndroidPlatform) {
      return null;
    }
    try {
      final AndroidDeviceInfo info = await DeviceInfoPlugin().androidInfo;
      for (final String abi in info.supportedAbis) {
        if (androidUpdateAbis.contains(abi)) {
          _deviceAbi = abi;
          return abi;
        }
      }
    } catch (error) {
      debugPrint('读取设备 ABI 失败：$error');
    }
    return null;
  }

  @visibleForTesting
  static void debugSetDeviceAbi(String? value) {
    _deviceAbi = value;
  }

  /// 检查线上最新正式版。
  ///
  /// 永不抛异常：网络、限流、响应格式等问题统一转成 [UpdateStatus.failed]。
  /// 并发调用共享同一个 in-flight 请求。
  static Future<UpdateCheckResult> checkUpdate() {
    final Future<UpdateCheckResult>? existing = _inFlight;
    if (existing != null) {
      return existing;
    }

    final Future<UpdateCheckResult> future = _checkOnce();
    _inFlight = future;
    future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    }).ignore();
    return future;
  }

  static Future<UpdateCheckResult> _checkOnce() async {
    if (_currentVersion.isEmpty) {
      await init();
    }
    if (_currentVersion.isEmpty) {
      return _failure(StateError('无法读取当前应用版本'));
    }

    try {
      final Response<Object?> response =
          await _dio.get<Object?>(_latestReleaseApi);
      final Object? data = response.data;
      if (data is! Map) {
        return _failure(
          const FormatException('GitHub Releases 响应格式不正确'),
        );
      }

      final GetLatestVersion release =
          GetLatestVersion.fromJson(Map<String, dynamic>.from(data));
      final String? latestTag = release.tagName?.trim();
      if (latestTag == null || latestTag.isEmpty) {
        return _failure(const FormatException('Release 缺少 tag_name'));
      }

      final bool hasUpdate = isNewerVersion(_currentVersion, latestTag);
      return UpdateCheckResult(
        status: hasUpdate ? UpdateStatus.available : UpdateStatus.upToDate,
        currentVersion: _currentVersion,
        latestVersion: latestTag,
        notes: release.body ?? '',
        downloads: hasUpdate
            ? mapAndroidAssetsByAbi(release.assets)
            : const <String, AndroidUpdateAsset>{},
        releasePageUrl: release.htmlUrl,
      );
    } catch (error, stack) {
      AppLog.shared.error('update.check_failed', error, stack);
      debugPrint('检查更新失败：$error');
      return _failure(error);
    }
  }

  static UpdateCheckResult _failure(Object error) {
    return UpdateCheckResult(
      status: UpdateStatus.failed,
      currentVersion: _currentVersion,
      error: error,
    );
  }
}

/// 从 Release 资产里挑出各 ABI 的安装包。
///
/// 资产名形如 `app-arm64-v8a-release.apk`。只返回确实存在的项，
/// 页面据此决定是否回退到 Release 页面。
Map<String, AndroidUpdateAsset> mapAndroidAssetsByAbi(List<Assets>? assets) {
  final Map<String, AndroidUpdateAsset> result = <String, AndroidUpdateAsset>{};
  for (final Assets asset in assets ?? const <Assets>[]) {
    final String? name = asset.name;
    final String? url = asset.browserDownloadUrl;
    if (name == null || url == null || url.isEmpty) {
      continue;
    }
    for (final String abi in androidUpdateAbis) {
      if (name.contains(abi)) {
        result[abi] = AndroidUpdateAsset(
          abi: abi,
          name: name,
          url: url,
          digest: asset.digest,
        );
        break;
      }
    }
  }
  return result;
}
