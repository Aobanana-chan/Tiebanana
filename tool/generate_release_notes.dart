import 'dart:io';

/// 从 Markdown 二级标题中提取一节，保留内部标题、列表和代码块。
String markdownSection(String markdown, bool Function(String) matches) {
  final lines = markdown.replaceAll('\r\n', '\n').split('\n');
  final content = <String>[];
  var found = false;
  String? fence;
  var fenceLength = 0;
  for (final line in lines) {
    final marker = RegExp(r'^ {0,3}(`{3,}|~{3,})').firstMatch(line);
    if (marker != null) {
      final run = marker[1]!;
      if (fence == null) {
        fence = run[0];
        fenceLength = run.length;
      } else if (run[0] == fence &&
          run.length >= fenceLength &&
          line.substring(marker.end).trim().isEmpty) {
        fence = null;
      }
      if (found) content.add(line);
      continue;
    }
    final heading =
        fence == null ? RegExp(r'^##\s+(.+?)\s*#*\s*$').firstMatch(line) : null;
    if (heading != null) {
      if (found) return content.join('\n').trim();
      found = matches(heading[1]!);
    } else if (found) {
      content.add(line);
    }
  }
  if (!found) throw const FormatException('找不到对应的 Markdown 章节');
  return content.join('\n').trim();
}

String generateReleaseNotes({
  required String tag,
  required String readme,
  required String changelog,
}) {
  final version = tag.startsWith('v') ? tag.substring(1) : tag;
  if (!RegExp(r'^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$').hasMatch(version)) {
    throw FormatException('无效的发布版本：$tag');
  }
  final downloads = markdownSection(readme, (title) => title == '下载安装');
  final changes = markdownSection(changelog, (title) {
    // 支持 ## 1.0.1、## [1.0.1] - 日期 和带 v 前缀的标题。
    final token = title.split(RegExp(r'\s+')).first;
    final normalized = token.replaceAll(RegExp(r'[\[\]]'), '');
    return normalized == version || normalized == 'v$version';
  });
  if (downloads.isEmpty || changes.isEmpty) {
    throw FormatException('下载说明或 $version 的 Changelog 为空');
  }
  return '## 下载说明\n\n$downloads\n\n## 本版本更新（$version）\n\n$changes\n';
}

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('用法：dart tool/generate_release_notes.dart <tag> <输出文件>');
    exitCode = 1;
    return;
  }
  try {
    final notes = generateReleaseNotes(
      tag: args[0],
      readme: File('README.md').readAsStringSync(),
      changelog: File('CHANGELOG.md').readAsStringSync(),
    );
    File(args[1])
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(notes);
  } catch (error) {
    stderr.writeln('生成 Release 说明失败：$error');
    exitCode = 1;
  }
}
