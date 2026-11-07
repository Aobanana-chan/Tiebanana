import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('应用顶层只保留装配、基础能力、功能与共享组件', () {
    final directories = Directory('lib')
        .listSync()
        .whereType<Directory>()
        .where((directory) => directory
            .listSync(recursive: true)
            .whereType<File>()
            .any((file) => file.path.endsWith('.dart')))
        .map((entry) => entry.path.replaceAll('\\', '/').split('/').last)
        .toSet();
    expect(directories, {'app', 'core', 'features', 'shared'});
  });

  test('功能与共享组件不依赖应用页面注册表或旧目录', () {
    final forbidden = RegExp(
      r'''(?:import|export)\s+['"]package:tiebanana/(?:routes|widgets|common|state|models|dao|theme|splash|backend)/|(?:import|export)\s+['"][^'"]*app_router\.dart['"]''',
    );
    final offenders = <String>[];
    for (final root in ['lib/features', 'lib/shared', 'lib/core']) {
      for (final entry in Directory(root).listSync(recursive: true)) {
        if (entry is! File || !entry.path.endsWith('.dart')) continue;
        if (forbidden.hasMatch(entry.readAsStringSync())) {
          offenders.add(entry.path);
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('路由标识与参数不依赖页面或 Flutter', () {
    final source =
        File('lib/app/navigation/route_names.dart').readAsStringSync();
    expect(RegExp(r'^\s*(?:import|export)\s', multiLine: true).hasMatch(source),
        isFalse);
  });

  test('图标目录使用大小写敏感平台也能找到的小写路径', () {
    final names = Directory('assets')
        .listSync()
        .whereType<Directory>()
        .map((entry) => entry.path.replaceAll('\\', '/').split('/').last);
    expect(names, contains('icon'));
    expect(names, isNot(contains('Icon')));
    expect(File('assets/icon/ic_launcher_round.png').existsSync(), isTrue);
  });
}
