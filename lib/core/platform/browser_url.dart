import 'dart:convert';

/// 贴吧 scheme 中可站内打开的页面参数。
class TiebaDeepLink {
  const TiebaDeepLink({this.forumName, this.tid, this.pid});

  final String? forumName;
  final String? tid;
  final String? pid;

  bool get isThread => tid != null && tid!.isNotEmpty;
}

/// 对 WebView 中出现的 URL 做纯解析，不依赖页面与平台。
abstract class BrowserUrl {
  static const Set<String> _webSchemes = <String>{'http', 'https'};

  static const Set<String> _webViewInternalSchemes = <String>{
    'about',
    'data',
    'blob',
    'file',
    'javascript',
  };

  static const Set<String> _tiebaSchemes = <String>{
    'tbfrs',
    'tbpb',
    'com.baidu.tieba',
  };

  static const Set<String> _closeActions = <String>{
    'closecurrentpage',
    'closepage',
    'close',
    'finish',
    'exit',
  };

  static bool isWeb(Uri uri) => _webSchemes.contains(uri.scheme.toLowerCase());

  static bool isWebViewInternal(Uri uri) =>
      _webViewInternalSchemes.contains(uri.scheme.toLowerCase());

  static bool isTiebaScheme(Uri uri) =>
      _tiebaSchemes.contains(uri.scheme.toLowerCase());

  /// 是否是百度页面里的“关闭当前页”通知。
  ///
  /// 例：`baiduboxapp://tieba/hybrid/notify?params=%7B%22action%22%3A%22closeCurrentPage%22%7D`
  static bool isCloseCurrentPage(Uri uri) {
    if (uri.scheme.toLowerCase() != 'baiduboxapp') {
      return false;
    }
    final Map<String, String> query = uri.queryParameters;
    if (_isCloseAction(query['action'])) {
      return true;
    }
    final Map<String, dynamic>? params = _decodeJsonMap(query['params']);
    return params != null && _isCloseAction(params['action']);
  }

  /// 解析贴吧可站内打开的 scheme；无法识别时返回 null。
  static TiebaDeepLink? tiebaDeepLink(Uri uri) {
    final String scheme = uri.scheme.toLowerCase();
    final Map<String, String> query = uri.queryParameters;
    switch (scheme) {
      case 'tbfrs':
        final String? forumName = _firstNonEmpty(<String?>[
          query['kw'],
          query['forum_name'],
          query['forumName'],
        ]);
        return forumName == null ? null : TiebaDeepLink(forumName: forumName);
      case 'tbpb':
        final String? tid = _threadId(query);
        return tid == null
            ? null
            : TiebaDeepLink(tid: tid, pid: _postId(query));
      case 'com.baidu.tieba':
        if (uri.host.toLowerCase() != 'unidispatch') {
          return null;
        }
        switch (uri.path.toLowerCase()) {
          case '/pb':
            final String? tid = _threadId(query);
            return tid == null
                ? null
                : TiebaDeepLink(tid: tid, pid: _postId(query));
          case '/frs':
            final String? forumName = _firstNonEmpty(<String?>[
              query['kw'],
              query['forum_name'],
              query['forumName'],
            ]);
            return forumName == null
                ? null
                : TiebaDeepLink(forumName: forumName);
        }
    }
    return null;
  }

  static String? _threadId(Map<String, String> query) =>
      _firstNonEmpty(<String?>[
        query['tid'],
        query['thread_id'],
        query['threadId'],
      ]);

  static String? _postId(Map<String, String> query) => _firstNonEmpty(<String?>[
        query['pid'],
        query['post_id'],
        query['postId'],
      ]);

  static String? _firstNonEmpty(List<String?> values) {
    for (final String? value in values) {
      final String text = value?.trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  static bool _isCloseAction(Object? action) {
    return action is String &&
        _closeActions.contains(action.trim().toLowerCase());
  }

  static Map<String, dynamic>? _decodeJsonMap(String? raw) {
    final String text = raw?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final List<String> candidates = <String>[text];
    try {
      final String decoded = Uri.decodeComponent(text);
      if (decoded != text) {
        candidates.add(decoded);
      }
    } catch (_) {
      // 已经是明文 JSON 时 decodeComponent 可能报错，忽略即可。
    }
    for (final String candidate in candidates) {
      try {
        final Object? value = jsonDecode(candidate);
        if (value is Map<String, dynamic>) {
          return value;
        }
        if (value is Map) {
          return value.map<String, dynamic>(
            (Object? key, Object? value) =>
                MapEntry<String, dynamic>(key.toString(), value),
          );
        }
      } catch (_) {
        // 尝试下一个候选值。
      }
    }
    return null;
  }
}
