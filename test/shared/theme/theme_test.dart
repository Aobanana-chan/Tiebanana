import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/shared/theme/tiebanana_palette.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// WCAG 2.1 相对亮度。
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

/// WCAG 对比度，1~21。
double contrast(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);
  final double hi = math.max(la, lb);
  final double lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

String _hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

void main() {
  group('TiebananaSeed 覆盖与 default_config 的 themeName 一致', () {
    test('候选主题集合相同', () {
      // 与 lib/core/config/default_config.dart 的 themeName 保持一致，
      // 避免出现设置页能选、但种子表里没有的主题。
      expect(
        tiebananaSeeds.keys.toSet(),
        {'blue', 'cyan', 'teal', 'green', 'yellow', 'pink', 'white'},
      );
    });

    test('未知主题名回落到蓝色', () {
      expect(seedOf('not-a-theme').name, 'blue');
      expect(seedOf(null).name, 'blue');
    });
  });

  group('对比度达标（这是设计稿里逐主题校准过的硬约束）', () {
    // 阈值：正文与可点文字 4.5:1（WCAG AA 普通文本），大字号/图形 3:1。
    const double aa = 4.5;

    for (final TiebananaSeed seed in tiebananaSeeds.values) {
      for (final Brightness brightness in Brightness.values) {
        final String id = '${seed.name}/${brightness.name}';
        final TiebananaPalette p = brightness == Brightness.light
            ? TiebananaPalette.light(seed)
            : TiebananaPalette.dark(seed);

        test('$id 主色作文字对底色', () {
          expect(contrast(p.primary, p.bg), greaterThanOrEqualTo(aa));
        });

        test('$id 三级文字对底色', () {
          expect(contrast(p.textTertiary, p.bg), greaterThanOrEqualTo(aa));
        });

        test('$id 正文对底色', () {
          expect(contrast(p.textPrimary, p.bg), greaterThanOrEqualTo(aa));
        });

        test('$id 卡片上的正文', () {
          expect(contrast(p.textPrimary, p.surface), greaterThanOrEqualTo(aa));
        });

        test('$id 实心按钮前景对填充', () {
          expect(contrast(p.accentOn, p.accentFill), greaterThanOrEqualTo(aa));
        });

        test('$id 主色容器上的文字', () {
          expect(
            contrast(p.onPrimaryContainer, p.primaryContainer),
            greaterThanOrEqualTo(aa),
          );
        });

        test('$id 引用块文字对引用块底色', () {
          expect(
            contrast(p.quoteText, p.quoteBackground),
            greaterThanOrEqualTo(aa),
          );
        });

        test('$id 危险色对底色', () {
          expect(contrast(p.danger, p.bg), greaterThanOrEqualTo(3.0));
        });
      }
    }
  });

  group('ThemeData 装配', () {
    test('浅色与深色都注册了 TiebananaTokens 且明暗正确', () {
      const double fontSize = 16.0;
      final ThemeData light = TiebananaTheme.light(tiebananaSeeds['blue']!, fontSize);
      final ThemeData dark = TiebananaTheme.dark(tiebananaSeeds['blue']!, fontSize);

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);

      final TiebananaTokens? lt = light.extension<TiebananaTokens>();
      final TiebananaTokens? dt = dark.extension<TiebananaTokens>();
      expect(lt, isNotNull);
      expect(dt, isNotNull);

      expect(light.scaffoldBackgroundColor, lt!.bg);
      expect(dark.scaffoldBackgroundColor, dt!.bg);

      // 底色必须真的带种子色相，否则就是"只换了文字颜色"的老问题。
      expect(lt.bg, isNot(Colors.white));
      expect(lt.bg, isNot(Colors.grey));
      expect(dt.bg, isNot(Colors.black));
    });

    test('换主题色会改变整屏表面，而不只是主色', () {
      const double fontSize = 16.0;
      final TiebananaPalette blue =
          TiebananaTheme.light(tiebananaSeeds['blue']!, fontSize)
              .extension<TiebananaTokens>()!
              .palette;
      final TiebananaPalette pink =
          TiebananaTheme.light(tiebananaSeeds['pink']!, fontSize)
              .extension<TiebananaTokens>()!
              .palette;

      expect(pink.primary, isNot(blue.primary));
      expect(pink.bg, isNot(blue.bg));
      expect(pink.surface, isNot(blue.surface));
      expect(pink.bar, isNot(blue.bar));
      expect(pink.fill, isNot(blue.fill));
      expect(pink.line, isNot(blue.line));
    });

    test('white 主题几乎无彩度，其余主题底色带色', () {
      final Color whiteBg = TiebananaPalette.light(tiebananaSeeds['white']!).bg;
      final Color yellowBg =
          TiebananaPalette.light(tiebananaSeeds['yellow']!).bg;
      final HSLColor w = HSLColor.fromColor(whiteBg);
      final HSLColor y = HSLColor.fromColor(yellowBg);

      expect(w.saturation, lessThan(0.05));
      expect(y.saturation, greaterThan(0.3));
    });

    test('字号按倍率缩放，层级不塌', () {
      final TextTheme small = TiebananaTheme.light(tiebananaSeeds['blue']!, 12)
          .textTheme;
      final TextTheme large = TiebananaTheme.light(tiebananaSeeds['blue']!, 22)
          .textTheme;

      // 层级必须始终存在：标题 > 正文 > 元信息
      for (final TextTheme t in [small, large]) {
        expect(t.titleMedium!.fontSize!,
            greaterThan(t.bodyLarge!.fontSize!));
        expect(t.bodyLarge!.fontSize!,
            greaterThan(t.labelSmall!.fontSize!));
      }
      expect(large.bodyLarge!.fontSize!,
          greaterThan(small.bodyLarge!.fontSize!));
    });

    test('全平台页面跳转统一为 iOS 翻页动画', () {
      final ThemeData theme = TiebananaTheme.light(tiebananaSeeds['blue']!, 16);
      for (final TargetPlatform platform in TargetPlatform.values) {
        expect(
          theme.pageTransitionsTheme.builders[platform],
          isA<CupertinoPageTransitionsBuilder>(),
          reason: '$platform 不应回落到缩放淡入',
        );
      }
    });

    test('打印七个主题的派生结果（便于与设计稿核对）', () {
      for (final TiebananaSeed s in tiebananaSeeds.values) {
        for (final Brightness b in Brightness.values) {
          final TiebananaPalette p = b == Brightness.light
              ? TiebananaPalette.light(s)
              : TiebananaPalette.dark(s);
          // ignore: avoid_print
          print('${s.name.padRight(7)}${b.name.padRight(6)} '
              'bg=${_hex(p.bg)} surface=${_hex(p.surface)} bar=${_hex(p.bar)} '
              'primary=${_hex(p.primary)} primaryC=${_hex(p.primaryContainer)}');
        }
      }
    });
  });

  group('运行时装配（防止页面在别的 ThemeData 下崩）', () {
    testWidgets('令牌在 copyWith 出来的主题里仍然可用', (WidgetTester tester) async {
      // app_setting_page / image_picker / thread_control_bar 都用了这种写法，
      // 一旦扩展没被继承，TiebananaTokens.of 的断言就会在 debug 下炸掉。
      late TiebananaTokens tokens;
      await tester.pumpWidget(MaterialApp(
        theme: TiebananaTheme.light(tiebananaSeeds['teal']!, 16),
        home: Builder(builder: (BuildContext context) {
          return Theme(
            data: Theme.of(context).copyWith(
              listTileTheme: const ListTileThemeData(),
            ),
            child: Builder(builder: (BuildContext inner) {
              tokens = TiebananaTokens.of(inner);
              return const SizedBox();
            }),
          );
        }),
      ));
      expect(tokens.bg, TiebananaPalette.light(tiebananaSeeds['teal']!).bg);
    });

    testWidgets('主色与表面色真的进入了 ColorScheme', (WidgetTester tester) async {
      late ColorScheme scheme;
      late TiebananaTokens tokens;
      await tester.pumpWidget(MaterialApp(
        theme: TiebananaTheme.light(tiebananaSeeds['pink']!, 16),
        home: Builder(builder: (BuildContext context) {
          scheme = Theme.of(context).colorScheme;
          tokens = TiebananaTokens.of(context);
          return const SizedBox();
        }),
      ));
      expect(scheme.primary, tokens.primary);
      expect(scheme.surface, tokens.surface);
      expect(scheme.onSurface, tokens.textPrimary);
      expect(scheme.onSurfaceVariant, tokens.textSecondary);
      expect(scheme.outlineVariant, tokens.line);
      expect(scheme.primaryContainer, tokens.primaryContainer);
    });
  });
}
