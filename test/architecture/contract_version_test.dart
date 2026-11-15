import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

Map<Object?, Object?> _readPubspec(String path) =>
    loadYaml(File(path).readAsStringSync()) as Map<Object?, Object?>;

Version _packageVersion(String path) =>
    Version.parse(_readPubspec(path)['version'] as String);

VersionConstraint _contractConstraint(String path) {
  final Object? dependencies = _readPubspec(path)['dependencies'];
  expect(dependencies, isA<Map<Object?, Object?>>(),
      reason: '$path 缺少 dependencies');
  final Object? dependency =
      (dependencies as Map<Object?, Object?>)['tieba_contract'];
  expect(dependency, isA<Map<Object?, Object?>>(),
      reason: '$path 必须以 path/git 方式依赖 tieba_contract');
  final Object? version =
      (dependency as Map<Object?, Object?>)['version'];
  expect(version, isA<String>(),
      reason: '$path 的 tieba_contract 依赖必须写 version 范围');
  return VersionConstraint.parse(version! as String);
}

void main() {
  test('应用和演示后端声明的契约范围包含当前契约版本', () {
    final Version contract = _packageVersion(
      'packages/tieba_contract/pubspec.yaml',
    );
    for (final String path in <String>[
      'pubspec.yaml',
      'packages/tieba_backend_demo/pubspec.yaml',
    ]) {
      final VersionConstraint constraint = _contractConstraint(path);
      expect(
        constraint.allows(contract),
        isTrue,
        reason: '$path 的 tieba_contract 范围 $constraint 不包含当前契约版本 '
            '$contract；请同步依赖范围和子模块指针。',
      );
    }
  });

  test('契约版本与 CHANGELOG 章节同步', () {
    final Version contract = _packageVersion(
      'packages/tieba_contract/pubspec.yaml',
    );
    final String changelog =
        File('packages/tieba_contract/CHANGELOG.md').readAsStringSync();
    final RegExp heading = RegExp(
      '^##\\s+\\[?v?${RegExp.escape(contract.toString())}\\]?\\s*\$',
      multiLine: true,
    );
    expect(
      heading.hasMatch(changelog),
      isTrue,
      reason: 'tieba_contract $contract 缺少 CHANGELOG 章节。',
    );
  });

  test('兼容表记录当前应用与契约版本', () {
    final Version app = _packageVersion('pubspec.yaml');
    final Version contract = _packageVersion(
      'packages/tieba_contract/pubspec.yaml',
    );
    final String doc =
        File('docs/contract-versioning.md').readAsStringSync();
    final String appVersion = '${app.major}.${app.minor}.${app.patch}';
    expect(
      doc,
      contains('| $appVersion'),
      reason: 'docs/contract-versioning.md 缺少 Tiebanana $appVersion 的兼容行。',
    );
    expect(
      doc,
      contains(contract.toString()),
      reason: 'docs/contract-versioning.md 未记录当前契约版本 $contract。',
    );
  });
}
