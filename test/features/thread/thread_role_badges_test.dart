import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/thread/data/thread_cache_codec.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/features/thread/widgets/thread_common.dart';

void main() {
  test('所有主题的吧务标签前景背景对比度至少4.5', () {
    for (final seed in tiebananaSeeds.values) {
      for (final dark in [false, true]) {
        final theme = dark
            ? TiebananaTheme.dark(seed, 16)
            : TiebananaTheme.light(seed, 16);
        final tokens = theme.extension<TiebananaTokens>()!;
        for (final pair in [
          (tokens.assistantBadgeForeground, tokens.assistantBadgeBackground),
          (tokens.managerBadgeForeground, tokens.managerBadgeBackground),
        ]) {
          final a = pair.$1.computeLuminance();
          final b = pair.$2.computeLuminance();
          final contrast =
              a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
          expect(contrast, greaterThanOrEqualTo(4.5));
        }
      }
    }
  });
  test('作者身份缓存往返及旧缓存兼容', () {
    final author = TiebaAuthor(
        icons: [],
        levelID: '12',
        nameShow: '昵称',
        portrait: '',
        uid: '7',
        username: null,
        forumRole: TiebaForumRole.manager);
    final json = ThreadCacheCodec.author(author);
    expect(ThreadCacheCodec.readAuthor(json).forumRole, TiebaForumRole.manager);
    json.remove('forumRole');
    expect(ThreadCacheCodec.readAuthor(json).forumRole, isNull);
  });

  for (final dark in [false, true]) {
    for (final width in [320.0, 390.0]) {
      testWidgets('身份并列且窄屏大字不溢出 $dark $width', (tester) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
          theme: dark
              ? TiebananaTheme.dark(seedOf('blue'), 22)
              : TiebananaTheme.light(seedOf('blue'), 22),
          home: const Scaffold(
              body: Padding(
            padding: EdgeInsets.all(16),
            child: Column(children: [
              ThreadAuthorLine(
                  name: '一个非常非常长的楼主兼任吧主昵称',
                  level: '18',
                  icons: [],
                  isOp: true,
                  forumRole: TiebaForumRole.manager),
              ThreadAuthorLine(
                  name: '小吧用户',
                  level: null,
                  icons: [],
                  forumRole: TiebaForumRole.assistant),
              ThreadAuthorLine(name: '普通用户', level: null, icons: []),
            ]),
          )),
        ));
        expect(find.text('楼主'), findsOneWidget);
        expect(find.text('吧主'), findsOneWidget);
        expect(find.text('小吧'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final admin = tester.widget<Container>(find
            .descendant(
                of: find.byType(ThreadForumRoleBadge).first,
                matching: find.byType(Container))
            .first);
        final color = (admin.decoration as BoxDecoration).color!;
        expect(color.r, greaterThan(color.b));
      });
    }
  }
}
