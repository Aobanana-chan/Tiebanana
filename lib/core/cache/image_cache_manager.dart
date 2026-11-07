import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import '../diagnostics/app_log.dart';

class ImageCachePolicy {
  const ImageCachePolicy({
    this.enabled = false,
    this.byAge = true,
    this.days = 30,
    this.bySize = true,
    this.maxMiB = 500,
  });

  final bool enabled;
  final bool byAge;
  final int days;
  final bool bySize;
  final int maxMiB;

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'byAge': byAge,
        'days': days,
        'bySize': bySize,
        'maxMiB': maxMiB,
      };

  factory ImageCachePolicy.fromJson(Map<String, dynamic> json) =>
      ImageCachePolicy(
        enabled: json['enabled'] == true,
        byAge: json['byAge'] != false,
        days: json['days'] is int && json['days'] >= 1 && json['days'] <= 3650
            ? json['days'] as int
            : 30,
        bySize: json['bySize'] != false,
        maxMiB: json['maxMiB'] is int &&
                json['maxMiB'] >= 1 &&
                json['maxMiB'] <= 102400
            ? json['maxMiB'] as int
            : 500,
      );
}

class ImageCacheCleanupResult {
  const ImageCacheCleanupResult(this.bytes, this.failures);
  final int bytes;
  final int failures;
}

/// 管理 ExtendedImage 与头像共享的 cacheimage 目录中的 MD5 缓存文件。
/// 清理时跳过符号链接、子目录和正在写入的 .refresh 文件。
class ImageCacheManager with WidgetsBindingObserver {
  ImageCacheManager({Future<Directory> Function()? directory})
      : _directory = directory ?? _defaultDirectory;

  static final shared = ImageCacheManager();
  static const preferenceKey = 'imageCache.policy';
  final Future<Directory> Function() _directory;
  final Lock _lock = Lock();
  Timer? _timer;
  bool _started = false;
  bool _checking = false;
  ImageCachePolicy policy = const ImageCachePolicy();

  static Future<Directory> _defaultDirectory() async =>
      Directory('${(await getTemporaryDirectory()).path}/cacheimage');

  Future<void> loadPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(preferenceKey);
      if (raw != null) {
        policy =
            ImageCachePolicy.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } on FormatException {
      policy = const ImageCachePolicy();
    } on TypeError {
      policy = const ImageCachePolicy();
    }
  }

  Future<void> savePolicy(ImageCachePolicy value) async {
    if (value.enabled && !value.byAge && !value.bySize) {
      throw ArgumentError('请至少选择一种自动清理规则');
    }
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(preferenceKey, jsonEncode(value.toJson()))) {
      throw StateError('无法保存图片缓存设置');
    }
    policy = value;
    await checkAutomatically();
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await loadPolicy();
    WidgetsBinding.instance.addObserver(this);
    _schedule();
    await checkAutomatically();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 15), (_) {
      unawaited(checkAutomatically());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _schedule();
      unawaited(checkAutomatically());
    } else {
      _timer?.cancel();
    }
  }

  Future<void> checkAutomatically() async {
    if (!policy.enabled || _checking) return;
    _checking = true;
    try {
      await clean();
    } catch (error, stack) {
      AppLog.shared.error('cache.cleanup_failed', error, stack);
      // 自动维护失败不阻断启动或前台恢复，下次检查再试。
      debugPrint('自动清理图片缓存失败：$error');
    } finally {
      _checking = false;
    }
  }

  Future<List<({File file, FileStat stat})>> _files() async {
    final directory = await _directory();
    final files = <({File file, FileStat stat})>[];
    if (!await directory.exists()) return files;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File ||
          !RegExp(r'^[a-f0-9]{32}$')
              .hasMatch(entity.path.split(Platform.pathSeparator).last)) {
        continue;
      }
      final stat = await entity.stat();
      if (stat.type == FileSystemEntityType.file) {
        files.add((file: entity, stat: stat));
      }
    }
    return files;
  }

  Future<int> sizeBytes() => _lock.synchronized(() async {
        final files = await _files();
        return files.fold<int>(0, (sum, entry) => sum + entry.stat.size);
      });

  /// 时间按文件最后写入时间计算；先删过期文件，再按最旧优先压到容量上限。
  Future<ImageCacheCleanupResult> clean({bool all = false, DateTime? now}) =>
      _lock.synchronized(() async {
        if (!all && !policy.enabled) {
          return const ImageCacheCleanupResult(0, 0);
        }
        final rules = policy;
        final files = await _files();
        files.sort((a, b) => a.stat.modified.compareTo(b.stat.modified));
        var total = files.fold<int>(0, (sum, entry) => sum + entry.stat.size);
        var removed = 0;
        var failures = 0;
        final cutoff =
            (now ?? DateTime.now()).subtract(Duration(days: rules.days));
        for (final entry in files) {
          final expired = rules.byAge && entry.stat.modified.isBefore(cutoff);
          final oversized = rules.bySize && total > rules.maxMiB * 1024 * 1024;
          if (!all && !expired && !oversized) continue;
          try {
            // 下载与清理可能并发；不删除扫描后刚被头像刷新覆盖的文件。
            final current = await entry.file.stat();
            if (current.type != FileSystemEntityType.file ||
                current.modified != entry.stat.modified ||
                current.size != entry.stat.size) {
              continue;
            }
            await entry.file.delete();
            total -= entry.stat.size;
            removed += entry.stat.size;
          } on FileSystemException {
            failures++;
          }
        }
        if (all || removed > 0) {
          PaintingBinding.instance.imageCache.clear();
        }
        return ImageCacheCleanupResult(removed, failures);
      });
}

String formatImageCacheSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GiB';
}
