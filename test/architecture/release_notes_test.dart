import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/generate_release_notes.dart';

void main() {
  const readme = '''
# App
## 下载安装
### Android
选择 arm64 或 armeabi-v7a。
### iOS
实验性，未经测试，需要自行签名。
## 从源码运行
不要出现在发布说明中。
''';

  test('下载说明在前，提取 tag 对应版本且保留内部 Markdown', () {
    final result = generateReleaseNotes(
      tag: 'v1.2.3',
      readme: readme.replaceAll('\n', '\r\n'),
      changelog: '''
# Changelog
## Unreleased
未来更新
## [1.2.3] - 2026-11-14
### 修复
- **修复内容**
```markdown
## 代码块内的标题
```
## 1.2.2
旧版更新
''',
    );
    expect(result.indexOf('## 下载说明'), lessThan(result.indexOf('## 本版本更新')));
    expect(result, contains('实验性，未经测试，需要自行签名。'));
    expect(result, contains('### 修复\n- **修复内容**'));
    expect(result, contains('## 代码块内的标题'));
    expect(result, isNot(contains('未来更新')));
    expect(result, isNot(contains('旧版更新')));
    expect(result, isNot(contains('从源码运行')));
  });

  test('支持普通版本及带 v 的 Changelog 标题，不混淆相似版本', () {
    for (final heading in ['1.2.3', 'v1.2.3', '[v1.2.3]']) {
      expect(
        generateReleaseNotes(
          tag: 'v1.2.3',
          readme: readme,
          changelog: '## 1.2.30\n其他更新\n## $heading\n本次更新',
        ),
        endsWith('本次更新\n'),
      );
    }
  });

  test('缺少版本、空内容或缺少下载说明时明确失败', () {
    for (final changelog in ['## 1.2.30\n不是该版本', '## 1.2.3\n\n## 1.2.2\n旧版']) {
      expect(
        () => generateReleaseNotes(
            tag: 'v1.2.3', readme: readme, changelog: changelog),
        throwsFormatException,
      );
    }
    expect(
      () => generateReleaseNotes(
          tag: 'v1.2.3', readme: '# App', changelog: '## 1.2.3\n更新'),
      throwsFormatException,
    );
  });

  test('仓库发布说明包含 ABI 指引、未经测试提示和当前版本更新', () {
    final version = RegExp(r'^version:\s*(\d+\.\d+\.\d+)', multiLine: true)
        .firstMatch(File('pubspec.yaml').readAsStringSync())![1]!;
    final result = generateReleaseNotes(
      tag: 'v$version',
      readme: File('README.md').readAsStringSync(),
      changelog: File('CHANGELOG.md').readAsStringSync(),
    );
    expect(result, contains('app-arm64-v8a-release.apk'));
    expect(result, contains('app-armeabi-v7a-release.apk'));
    expect(result, contains('还没经过测试'));
    expect(result, contains('无签名'));
    final workflow = File('.github/workflows/main.yml').readAsStringSync();
    expect(workflow, contains('bodyFile: build/release-notes.md'));
    expect(workflow, isNot(contains('generateReleaseNotes: true')));
  });
}
