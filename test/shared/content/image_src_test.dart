// 图片地址候选链（契约数据类 TiebaImageContent）回归。
import 'package:flutter_test/flutter_test.dart';
import 'package:tieba_contract/tieba_contract.dart';

void main() {
  group('图片地址候选链（对齐官方 TbRichTextImageInfo）', () {
    test('displaySrc 优先 cdn_src_active', () {
      final img = TiebaImageContent(
          cdnSrcActive: 'active.jpg',
          bigCdnSrc: 'big.jpg',
          bigSrc: 'bigraw.jpg',
          cdnSrc: 'cdn.jpg',
          src: 'thumb.jpg',
          originSrc: 'origin.jpg');
      expect(img.displaySrc, 'active.jpg');
      expect(img.originalSrc, 'origin.jpg');
    });

    test('displaySrc 逐级回退：big_cdn_src → big_src → cdn_src → src → origin_src', () {
      expect(
          TiebaImageContent(bigCdnSrc: 'big.jpg', bigSrc: 'raw.jpg')
              .displaySrc,
          'big.jpg');
      expect(TiebaImageContent(bigSrc: 'raw.jpg').displaySrc, 'raw.jpg');
      expect(TiebaImageContent(cdnSrc: 'cdn.jpg').displaySrc, 'cdn.jpg');
      expect(TiebaImageContent(src: 'thumb.jpg').displaySrc, 'thumb.jpg');
      expect(TiebaImageContent(originSrc: 'origin.jpg').displaySrc,
          'origin.jpg');
    });

    test('lowFlowSrc 优先 cdn_src（官方非大图模式）', () {
      final img = TiebaImageContent(
          bigCdnSrc: 'big.jpg', cdnSrc: 'cdn.jpg', src: 'thumb.jpg');
      expect(img.lowFlowSrc, 'cdn.jpg');
      expect(TiebaImageContent(src: 'thumb.jpg').lowFlowSrc, 'thumb.jpg');
      expect(TiebaImageContent(originSrc: 'origin.jpg').lowFlowSrc,
          'origin.jpg');
    });

    test('originalSrc 优先 origin_src，缺失时回退显示地址', () {
      expect(TiebaImageContent(bigCdnSrc: 'big.jpg').originalSrc, 'big.jpg');
    });

    test('字段全缺时返回空串而不是抛异常', () {
      final img = TiebaImageContent();
      expect(img.displaySrc, '');
      expect(img.lowFlowSrc, '');
      expect(img.originalSrc, '');
      expect(img.bsizeValue, 0);
    });

    test('bsizeValue 缺失或非法时为 0', () {
      expect(TiebaImageContent(bsize: '1080,1920').bsizeValue, 10801920);
      expect(TiebaImageContent(bsize: '').bsizeValue, 0);
      expect(TiebaImageContent(bsize: 'wide').bsizeValue, 0);
    });
  });

  group('动图识别', () {
    const proxy =
        'http://c.tieba.baidu.com/c/p/img?src=http://static.tieba.baidu.com/tb/editor/images/qw_cat_small/qw_cat_0001.gif'
        '&width=720&height=720&qulity=60&first_gif=1&imgtype=0';

    test('图片代理带 first_gif 即视为动图', () {
      expect(TiebaImageContent(cdnSrcActive: proxy).isAnimated, isTrue);
    });

    test('任一候选地址是 GIF 都算动图', () {
      expect(
          TiebaImageContent(
                  cdnSrcActive: 'https://example.com/active.jpg',
                  originSrc: 'https://example.com/anim.gif')
              .isAnimated,
          isTrue);
      expect(
          TiebaImageContent(
                  cdnSrcActive:
                      'https://example.com/c/p/img?src=https://example.com/a.gif')
              .isAnimated,
          isTrue);
    });

    test('静态图与空地址不显示动图标识', () {
      expect(
          TiebaImageContent(
                  cdnSrcActive: 'https://example.com/active.jpg',
                  bigCdnSrc: 'https://example.com/big.jpg',
                  originSrc: 'https://example.com/origin.jpg')
              .isAnimated,
          isFalse);
      expect(TiebaImageContent().isAnimated, isFalse);
    });
  });
}
