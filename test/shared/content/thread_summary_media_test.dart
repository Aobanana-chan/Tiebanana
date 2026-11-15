import 'package:extended_image/extended_image.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/features/forum/widgets/forum_feed_card.dart';
import 'package:tiebanana/shared/content/special_span.dart';
import 'package:tiebanana/shared/content/thread_preview_content.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/shared/media/video_player.dart';

import '../../support/fake_thread.dart';

void main() {
  setUp(() {
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
  });

  Future<void> mount(WidgetTester tester, Widget card,
      {RouteFactory? onGenerateRoute}) async {
    await tester.pumpWidget(MaterialApp(
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      onGenerateRoute: onGenerateRoute,
      home: Scaffold(body: SingleChildScrollView(child: card)),
    ));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Widget summary(List<TiebaPostContent> contents) => ThreadSummary(
      firstPostContent: contents,
      author: fakeAuthor(),
      createTime: '',
      latestTime: '',
      tid: '1',
      fname: '测试',
      viewNum: '1',
      title: '标题',
      agreeNum: '0',
      disagreeNum: '0',
      replyNum: '0',
      dismissible: false);

  for (final feed in [false, true]) {
    Widget card(List<TiebaPostContent> contents) {
      if (!feed) return summary(contents);
      final item = fakeThreadInfo()..firstPostContent = contents;
      return ForumFeedCard(item: item);
    }

    testWidgets('鼠标悬停不产生暗影，保留点击反馈 ${feed ? "卡片流" : "帖子流"}', (tester) async {
      await mount(tester, card([]));
      final buttonFinder = find.byType(MaterialButton);
      final button = tester.widget<MaterialButton>(buttonFinder);
      final context = tester.element(buttonFinder);
      final theme = Theme.of(context);
      expect(button.hoverElevation, 0);
      expect(
          button.hoverColor, theme.colorScheme.primary.withValues(alpha: .04));
      // 不覆盖既有的按下与水波纹反馈。
      expect(button.highlightColor, isNull);
      expect(button.splashColor, isNull);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(buttonFinder));
      await tester.pumpAndSettle();
      final materialFinder =
          find.descendant(of: buttonFinder, matching: find.byType(Material));
      for (final material in tester.widgetList<Material>(materialFinder)) {
        expect(material.elevation, 0);
      }
      expect(materialFinder, findsWidgets);
      await mouse.removePointer();
      expect(tester.takeException(), isNull);
    });

    testWidgets('预览表情使用图片 ${feed ? "卡片流" : "帖子流"}', (tester) async {
      await mount(
          tester,
          card([
            TiebaTextContent(text: '正文#(滑稽)', uid: '7'),
            TiebaEmojiContent(c: '滑稽', text: 'image_emoticon25'),
            TiebaEmojiContent(
                c: '动态',
                text: 'custom_emoji',
                dynamicUrl: 'https://example.com/e.gif'),
          ]));
      final text = tester.widget<ExtendedText>(find.descendant(
          of: find.byType(ThreadPreviewExcerpt),
          matching: find.byType(ExtendedText)));
      final spans = <InlineSpan>[];
      text.textSpan!.visitChildren((span) {
        if (span is EmojiSpan) spans.add(span);
        return true;
      });
      expect(spans, hasLength(3));
      expect(
          find.byWidgetPredicate((w) =>
              w is ExtendedImage &&
              w.image is ExtendedNetworkImageProvider &&
              (w.image as ExtendedNetworkImageProvider).url ==
                  'https://example.com/e.gif'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final count in [1, 2, 3, 4]) {
      testWidgets('媒体16:9并保留视频 ${feed ? "卡片流" : "帖子流"} $count', (tester) async {
        final contents = <TiebaPostContent>[
          TiebaVideoContent(cover: 'https://example.com/cover.jpg'),
          for (var i = 1; i < count; i++)
            TiebaImageContent(src: 'https://example.com/$i.jpg'),
        ];
        await mount(tester, card(contents));
        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
        expect(find.byType(VideoPlayer), findsNothing);
        final ratios = find.descendant(
            of: find.byType(ThreadPreviewMedia),
            matching: find.byType(AspectRatio));
        expect(ratios, findsNWidgets(count > 3 ? 3 : count));
        for (final element in ratios.evaluate()) {
          final size = tester.getSize(find.byWidget(element.widget));
          expect(size.width / size.height, closeTo(16 / 9, 0.001));
        }
        if (count == 4) expect(find.text('4'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('视频预览按画面比例排版，竖屏不再套 16:9', (tester) async {
    await mount(
        tester,
        summary([
          TiebaVideoContent(
              cover: 'https://example.com/cover.jpg',
              width: 1080,
              height: 1920),
        ]));
    final ratio = tester.widget<AspectRatio>(find
        .descendant(
            of: find.byType(ThreadPreviewMedia),
            matching: find.byType(AspectRatio))
        .first);
    expect(ratio.aspectRatio, closeTo(9 / 16, .001));
    final size = tester.getSize(find.byWidget(ratio));
    expect(size.width / size.height, closeTo(9 / 16, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('缺少视频直链时进入帖子，不初始化无效播放器', (tester) async {
    RouteSettings? opened;
    await mount(tester, summary([TiebaVideoContent()]),
        onGenerateRoute: (settings) {
      opened = settings;
      return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('详情')));
    });
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();
    expect(opened?.name, PageRouter.threadPage);
    expect((opened?.arguments as ThreadPageRouterData).kz, '1');
    expect(find.text('详情'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('省流量档位的动图缩略图显示 GIF 角标', (tester) async {
    Global.setting.pictureLoadSetting = 0;
    await mount(
        tester,
        summary([
          TiebaImageContent(src: 'https://example.com/anim.gif'),
        ]));
    expect(find.text('GIF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('高质量档位和静态图不显示 GIF 角标', (tester) async {
    Global.setting.pictureLoadSetting = 2;
    await mount(
        tester,
        summary([
          TiebaImageContent(src: 'https://example.com/anim.gif'),
        ]));
    expect(find.text('GIF'), findsNothing);

    Global.setting.pictureLoadSetting = 0;
    await mount(
        tester,
        summary([
          TiebaImageContent(src: 'https://example.com/static.jpg'),
        ]));
    expect(find.text('GIF'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
