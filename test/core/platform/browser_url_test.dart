import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/core/platform/browser_url.dart';

void main() {
  group('BrowserUrl.isWeb', () {
    test('只把 http / https 当作网页', () {
      expect(BrowserUrl.isWeb(Uri.parse('https://example.com')), isTrue);
      expect(BrowserUrl.isWeb(Uri.parse('http://example.com')), isTrue);
      expect(BrowserUrl.isWeb(Uri.parse('alipays://platformapi')), isFalse);
    });
  });

  group('BrowserUrl.isWebViewInternal', () {
    test('放行 WebView 内部 scheme', () {
      expect(BrowserUrl.isWebViewInternal(Uri.parse('about:blank')), isTrue);
      expect(
        BrowserUrl.isWebViewInternal(Uri.parse('data:text/html,<html></html>')),
        isTrue,
      );
      expect(
        BrowserUrl.isWebViewInternal(Uri.parse('file:///tmp/a.html')),
        isTrue,
      );
      expect(
        BrowserUrl.isWebViewInternal(Uri.parse('https://example.com')),
        isFalse,
      );
    });
  });

  group('BrowserUrl.isCloseCurrentPage', () {
    test('识别 URL 编码后的 params', () {
      final Uri uri = Uri.parse(
        'baiduboxapp://tieba/hybrid/notify'
        '?params=%7B%22action%22%3A%22closeCurrentPage%22%7D',
      );
      expect(BrowserUrl.isCloseCurrentPage(uri), isTrue);
    });

    test('识别明文 params 和直接 action', () {
      final Uri encoded = Uri(
        scheme: 'baiduboxapp',
        host: 'tieba',
        path: '/hybrid/notify',
        queryParameters: <String, String>{
          'params': '{"action":"closeCurrentPage"}',
        },
      );
      final Uri direct = Uri(
        scheme: 'baiduboxapp',
        host: 'tieba',
        path: '/hybrid/notify',
        queryParameters: <String, String>{'action': 'closePage'},
      );
      expect(BrowserUrl.isCloseCurrentPage(encoded), isTrue);
      expect(BrowserUrl.isCloseCurrentPage(direct), isTrue);
    });

    test('不会把其他 action 或 scheme 误判为关闭页面', () {
      final Uri openPage = Uri(
        scheme: 'baiduboxapp',
        host: 'tieba',
        path: '/hybrid/notify',
        queryParameters: <String, String>{
          'params': '{"action":"openPage"}',
        },
      );
      expect(BrowserUrl.isCloseCurrentPage(openPage), isFalse);
      expect(
        BrowserUrl.isCloseCurrentPage(
            Uri.parse('alipays://platformapi/startapp')),
        isFalse,
      );
    });
  });

  group('BrowserUrl.tiebaDeepLink', () {
    test('解析 tbfrs 吧链接', () {
      final TiebaDeepLink? link = BrowserUrl.tiebaDeepLink(
        Uri.parse('tbfrs://tieba.baidu.com/frs?kw=%E8%B4%B4%E5%90%A7'),
      );
      expect(link?.forumName, '贴吧');
      expect(link?.isThread, isFalse);
    });

    test('解析 tbpb 贴链接', () {
      final TiebaDeepLink? link = BrowserUrl.tiebaDeepLink(
        Uri.parse('tbpb://tieba.baidu.com/pb?tid=123&pid=456'),
      );
      expect(link?.tid, '123');
      expect(link?.pid, '456');
      expect(link?.isThread, isTrue);
    });

    test('解析 com.baidu.tieba unidispatch 链接', () {
      final TiebaDeepLink? thread = BrowserUrl.tiebaDeepLink(
        Uri.parse('com.baidu.tieba://unidispatch/pb?tid=123'),
      );
      final TiebaDeepLink? forum = BrowserUrl.tiebaDeepLink(
        Uri.parse('com.baidu.tieba://unidispatch/frs?kw=test'),
      );
      expect(thread?.tid, '123');
      expect(forum?.forumName, 'test');
    });

    test('没有可站内打开的页面时返回 null', () {
      expect(
        BrowserUrl.tiebaDeepLink(
            Uri.parse('com.baidu.tieba://unidispatch/other?tid=123')),
        isNull,
      );
      expect(BrowserUrl.tiebaDeepLink(Uri.parse('tbpb://tieba.baidu.com/pb')),
          isNull);
    });

    test('识别贴吧 scheme 以便回退官方客户端', () {
      expect(
        BrowserUrl.isTiebaScheme(
            Uri.parse('com.baidu.tieba://unidispatch/other')),
        isTrue,
      );
      expect(BrowserUrl.isTiebaScheme(Uri.parse('tbpb://tieba.baidu.com/pb')),
          isTrue);
      expect(
        BrowserUrl.isTiebaScheme(Uri.parse('alipays://platformapi')),
        isFalse,
      );
    });
  });
}
