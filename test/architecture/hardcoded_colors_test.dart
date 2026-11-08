import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 允许保留硬编码颜色的文件 → 处数。
///
/// 这些是**有意保留**的，不是漏改：
/// - `video_player` / `img_explorer` / `image_picker(看图器)`：全屏纯黑遮罩，
///   其上的白字白图标正是设计意图，跟着主题走反而会看不见。
/// - `login` / `service_center` / `thread_floor_card` / `tieba_parser`：
///   WebView 必须白底（否则加载瞬间闪黑），以及缩略图角标上的深色半透明遮罩。
/// - `forum_tag`：贴吧等级徽章的固定配色，属于语义色。
///
/// 新增这些文件之外的硬编码颜色、或让某个文件的处数变化，这个测试都会失败。
/// 处理方式：Review 之后把新值写进上表，而不是直接放宽规则。
const Map<String, int> allowedHardcodedColors = <String, int>{
  'lib/shared/media/video_player.dart': 25,
  'lib/shared/media/img_explorer.dart': 3,
  'lib/shared/content/tieba_parser.dart': 3,
  'lib/features/account/pages/login_page.dart': 2,
  'lib/features/settings/pages/service_center_page.dart': 1,
  'lib/features/browser/pages/in_app_browser_page.dart': 1,
  'lib/features/media/pages/image_picker_page.dart': 1,
  // 性别图标：男蓝女粉是语义色，不该跟主题色走。
  'lib/features/profile/pages/user_profile_page.dart': 2,
  // 开屏的品牌色：必须与 App 图标逐色一致，不跟主题走（见 lib/features/splash/splash_brand.dart）。
  'lib/features/splash/splash_brand.dart': 5,
  // 主题色卡上的对勾固定白：色块本身就是饱和主色，白勾在明暗主题下都清晰。
  'lib/features/settings/widgets/theme_swatch_grid.dart': 1,
};

/// 只在 lib 下扫描，排除主题层自身（那里定义颜色是本职）。
const List<String> _skipDirs = <String>['theme', 'proto_generated'];

final RegExp _hardcoded = RegExp(
  r'Colors\.(?:white|black|grey|green|red|yellow|blue|amber|pink)\b|Color\(0x',
);

/// 去掉行尾注释后再匹配，避免把 `// color: Colors.white,` 这类死注释算进来。
String _stripLineComment(String line) {
  final int i = line.indexOf('//');
  return i == -1 ? line : line.substring(0, i);
}

Map<String, int> scan(String root, {List<String> skipDirs = _skipDirs}) {
  final Map<String, int> found = <String, int>{};
  for (final FileSystemEntity e
      in Directory(root).listSync(recursive: true, followLinks: false)) {
    if (e is! File || !e.path.endsWith('.dart')) continue;
    final String rel = e.path.replaceAll('\\', '/');
    if (skipDirs.any((String d) => rel.contains('/$d/'))) continue;
    int n = 0;
    for (final String line in e.readAsLinesSync()) {
      final String code = _stripLineComment(line);
      if (code.trim().isEmpty) continue;
      n += _hardcoded.allMatches(code).length;
    }
    if (n > 0) found[rel] = n;
  }
  return found;
}

void main() {
  test('硬编码颜色只出现在白名单文件里，且数量不再增长', () {
    final Map<String, int> actual = scan('lib');

    // 白名单之外的文件出现了硬编码颜色 —— 请改用 TiebananaTokens.of(context)
    final List<String> unexpected = actual.keys
        .where((String f) => !allowedHardcodedColors.containsKey(f))
        .toList();
    expect(
      unexpected,
      isEmpty,
      reason: '这些文件新出现了硬编码颜色，请改用 TiebananaTokens.of(context)：\n'
          '${unexpected.map((String f) => '  $f (${actual[f]})').join('\n')}',
    );

    // 数量变化 —— 增加要 review，减少是好事（顺手把白名单调小）
    final List<String> drift = <String>[];
    actual.forEach((String f, int n) {
      final int? expected = allowedHardcodedColors[f];
      if (expected != null && expected != n) {
        drift.add('  $f: 白名单 $expected → 实际 $n');
      }
    });
    expect(drift, isEmpty,
        reason: '硬编码颜色数量变化，review 后同步白名单：\n${drift.join('\n')}');

    // 白名单里已经没有硬编码的文件，应该从表里删掉
    final List<String> stale = allowedHardcodedColors.keys
        .where((String f) => !actual.containsKey(f))
        .toList();
    expect(stale, isEmpty, reason: '这些文件已经清干净了，请从白名单删除：\n${stale.join('\n')}');
  });

  test('主题层不许引用 Flutter 的 Colors 调色板（除 transparent）', () {
    // 调色板的值必须由 TiebananaSeed 派生；一旦有人图省事写 Colors.blue，
    // 换主题色就会失效，而且这种退化不会报错，只会静默变丑。
    final RegExp paletteUse = RegExp(r'Colors\.([A-Za-z]+)');
    final List<String> offenders = <String>[];
    for (final FileSystemEntity e
        in Directory('lib/shared/theme').listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      for (final String line in e.readAsLinesSync()) {
        final String code = _stripLineComment(line);
        for (final RegExpMatch m in paletteUse.allMatches(code)) {
          if (m.group(1) != 'transparent') {
            offenders.add('${e.path}: ${code.trim()}');
          }
        }
      }
    }
    expect(offenders, isEmpty,
        reason: '主题层出现了 Colors 调色板引用，应改为由种子派生：\n'
            '${offenders.join('\n')}');
  });
}
