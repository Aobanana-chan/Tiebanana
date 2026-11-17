import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/thread/widgets/thread_floor_card.dart';
import 'package:tiebanana/shared/media/img_explorer.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

class _FailedImageState extends Fake implements ExtendedImageState {
  @override
  LoadState get extendedImageLoadState => LoadState.failed;
}

void main() {
  setUp(() => Global.setting = APPSetting.fromJson(defaultAPPSetting));

  Future<void> mount(WidgetTester tester, List<TiebaPostContent> posts,
      {VoidCallback? onTap}) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => APPSettingProvider(),
      child: MaterialApp(
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: GestureDetector(
              onTap: onTap,
              child: InnerPost(posts: posts),
            ),
          ),
        ),
      ),
    ));
  }

  List<TiebaImageContent> images(int count) => List.generate(
      count,
      (i) => TiebaImageContent(
          src: 'https://example.com/thumb-$i.jpg',
          bigCdnSrc: 'https://example.com/display-$i.jpg',
          originSrc: 'https://example.com/original-$i.jpg'));

  testWidgets('纯图片回复展示受限缩略图，最多四张且标记剩余数量', (tester) async {
    await mount(tester, images(6));
    expect(find.byType(ExtendedImage), findsNWidgets(4));
    expect(find.text('+2'), findsOneWidget);
    for (final element in find.byType(ExtendedImage).evaluate()) {
      final size = tester.getSize(find.byWidget(element.widget));
      expect(size.width, lessThanOrEqualTo(72));
      expect(size.height, size.width);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('点击第四张直接打开查看器，保留全部图片及原图且不触发外层点击', (tester) async {
    var tapped = false;
    await mount(tester, images(6), onTap: () => tapped = true);
    await tester.tap(find.byType(ExtendedImage).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final viewer =
        tester.widget<ZoomedImgExplorer>(find.byType(ZoomedImgExplorer));
    expect(viewer.index, 3);
    expect(viewer.imgUrls, hasLength(6));
    expect(viewer.highQualityUrls![3], 'https://example.com/original-3.jpg');
    expect(tapped, isFalse);
  });

  testWidgets('没有地址时显示图片占位，不创建网络图片', (tester) async {
    await mount(tester, [TiebaImageContent()]);
    expect(find.text('[图片]'), findsOneWidget);
    expect(find.byType(ExtendedImage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('智能无图档不自动加载大图，但保留点击查看', (tester) async {
    Global.setting.pictureLoadSetting = 1;
    await mount(tester, [images(1).single..bsize = '2000,2000']);
    expect(find.text('[图片]'), findsOneWidget);
    expect(find.byType(ExtendedImage), findsNothing);
    await tester.tap(find.text('[图片]'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(ZoomedImgExplorer), findsOneWidget);
  });

  testWidgets('缩略图使用省流地址，加载失败后显示图片占位', (tester) async {
    Global.setting.pictureLoadSetting = 0;
    await mount(tester, images(1));
    final image = tester.widget<ExtendedImage>(find.byType(ExtendedImage));
    expect((image.image as ExtendedNetworkImageProvider).url,
        'https://example.com/thumb-0.jpg');
    final fallback = image.loadStateChanged!(_FailedImageState());
    await tester.pumpWidget(MaterialApp(home: fallback));
    expect(find.text('[图片]'), findsOneWidget);
  });

  testWidgets('文字与图片并存，点击文字仍交给外层楼中楼入口', (tester) async {
    var tapped = false;
    await mount(tester, [TiebaTextContent(text: '配图说明'), ...images(1)],
        onTap: () => tapped = true);
    expect(find.text('配图说明', findRichText: true), findsOneWidget);
    await tester.tap(find.text('配图说明', findRichText: true));
    expect(tapped, isTrue);
  });
}
