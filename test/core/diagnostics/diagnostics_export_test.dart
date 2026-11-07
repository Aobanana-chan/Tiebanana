import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:tiebanana/core/diagnostics/diagnostics.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.path);
  final String path;
  @override
  Future<String?> getTemporaryPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('外部导出传递 ZIP 字节，正确返回 URI/取消/错误并清理临时包', () async {
    final directory =
        await Directory.systemTemp.createTemp('tiebanana-save-test-');
    final previous = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(directory.path);
    try {
      await AppLog.shared.initialize(Directory('${directory.path}/logs'));
      final destination = Uri.parse('content://documents/diagnostics.zip');
      final saved = await Diagnostics.shared.saveToExternal(
          saveFile: (name, bytes) async {
        expect(name, endsWith('.zip'));
        expect(ZipDecoder().decodeBytes(bytes).findFile('manifest.json'),
            isNotNull);
        return destination;
      });
      expect(saved, destination);
      expect(
          await Diagnostics.shared
              .saveToExternal(saveFile: (name, bytes) async => null),
          isNull);
      await expectLater(
          Diagnostics.shared.saveToExternal(
              saveFile: (name, bytes) async => throw StateError('save failed')),
          throwsStateError);
      expect(
          await Directory('${directory.path}/diagnostic_exports')
              .list()
              .toList(),
          isEmpty);
    } finally {
      await AppLog.shared.clear();
      PathProviderPlatform.instance = previous;
      await directory.delete(recursive: true);
    }
  });
  test('诊断包只包含白名单日志和 manifest，不包含数据库与 cookie', () async {
    final directory =
        await Directory.systemTemp.createTemp('tiebanana-export-test-');
    final previous = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(directory.path);
    try {
      final logs = Directory('${directory.path}/logs');
      await AppLog.shared.initialize(logs);
      await File('${logs.path}/cookies').writeAsString('BDUSS=secret');
      await File('${logs.path}/database.db').writeAsString('private');
      AppLog.shared.record('test.export_failed', level: 'error');
      final file = await Diagnostics.shared.createBundle();
      final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
      expect(archive.files.map((f) => f.name), contains('manifest.json'));
      expect(
          archive.files.every((f) =>
              f.name == 'manifest.json' ||
              RegExp(r'^logs/log-\d+-\d+\.jsonl$').hasMatch(f.name)),
          isTrue);
      final contents = archive.files.map((f) => utf8.decode(f.content)).join();
      expect(contents, contains('test.export'));
      expect(contents, isNot(contains('secret')));
      expect(contents, isNot(contains('private')));
      final manifest =
          jsonDecode(utf8.decode(archive.findFile('manifest.json')!.content));
      expect(manifest['schema'], 2);
      expect(manifest['sessionId'], AppLog.shared.sessionId);
    } finally {
      await AppLog.shared.clear();
      PathProviderPlatform.instance = previous;
      await directory.delete(recursive: true);
    }
  });
}
