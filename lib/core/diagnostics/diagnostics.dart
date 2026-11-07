import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'app_log.dart';

class Diagnostics with WidgetsBindingObserver {
  Diagnostics._();
  static final shared = Diagnostics._();
  final Map<String, Object?> _environment = {};
  bool _observing = false;

  Future<void> initialize() async {
    try {
      final directory = await getApplicationSupportDirectory();
      await AppLog.shared
          .initialize(Directory('${directory.path}/diagnostics'));
    } catch (error, stack) {
      AppLog.shared.error('log.initialize_failed', error, stack);
    }
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    _environment['platform'] = defaultTargetPlatform.name;
    try {
      final info = await PackageInfo.fromPlatform();
      _environment.addAll({'version': info.version, 'build': info.buildNumber});
    } catch (error, stack) {
      AppLog.shared.error('environment.package_failed', error, stack);
    }
    try {
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        _environment.addAll({
          'model': info.model,
          'osVersion': info.version.release,
          'abis': info.supportedAbis.join(','),
        });
      } else if (Platform.isIOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        _environment.addAll(
            {'model': info.utsname.machine, 'osVersion': info.systemVersion});
      }
    } catch (error, stack) {
      AppLog.shared.error('environment.device_failed', error, stack);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLog.shared.flush();
  }

  /// 生成用于分享/导出的临时包；这不是保存到用户选择的位置。
  Future<File> createBundle() async {
    final snapshot = await AppLog.shared.snapshot();
    final archive = Archive();
    final manifest = utf8.encode(jsonEncode({
      'schema': 2,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'sessionId': AppLog.shared.sessionId,
      'environment': _environment,
      'privacy':
          'Exceptions only. Unknown content snapshots preserve structure, not string values. Thread/post identifiers may be included. No credentials or databases.',
    }));
    archive.addFile(ArchiveFile('manifest.json', manifest.length, manifest));
    for (final entry in snapshot.entries) {
      archive.addFile(
          ArchiveFile('logs/${entry.key}', entry.value.length, entry.value));
    }
    final directory =
        Directory('${(await getTemporaryDirectory()).path}/diagnostic_exports');
    await directory.create(recursive: true);
    // 只清理本功能生成、超过一天的临时导出文件，不碰其他缓存。
    await for (final entity in directory.list()) {
      if (entity is File &&
          RegExp(r'^tiebanana-diagnostics-\d+\.zip$')
              .hasMatch(entity.uri.pathSegments.last) &&
          (await entity.stat())
              .modified
              .isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        await entity.delete();
      }
    }
    final bytes = await compute(_zip, archive);
    return File(
            '${directory.path}/tiebanana-diagnostics-${DateTime.now().microsecondsSinceEpoch}.zip')
        .writeAsBytes(bytes, flush: true);
  }

  Future<void> share(Rect origin) async {
    final file = await createBundle();
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/zip')],
      subject: 'Tiebanana 诊断日志',
      sharePositionOrigin: origin,
    ));
  }

  /// Android 使用系统 SAF，iOS 使用文档导出器；插件完成写入后才返回。
  /// 返回值可能是 content:// URI，需要按 URI 处理。null 表示取消。
  Future<Uri?> saveToExternal({
    @visibleForTesting
    Future<Uri?> Function(String name, Uint8List bytes)? saveFile,
  }) async {
    final file = await createBundle();
    try {
      final bytes = await file.readAsBytes();
      final name = file.uri.pathSegments.last;
      if (saveFile != null) return await saveFile(name, bytes);
      return await FilePicker.saveFile(
        fileName: name,
        bytes: bytes,
        mimeType: 'application/zip',
        dialogTitle: '导出诊断包',
      );
    } finally {
      // 外部副本由系统保存；取消或失败时也不留下本次临时包。
      try {
        await file.delete();
      } catch (_) {}
    }
  }
}

List<int> _zip(Archive archive) => ZipEncoder().encode(archive);
