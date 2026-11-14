import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';

export 'package:flutter_inappwebview/flutter_inappwebview.dart' show WebUri;

/// 所有 Windows WebView 与 CookieManager 共用同一份可写用户数据目录。
class WindowsWebEnvironment {
  static Future<WebViewEnvironment>? _pending;

  static Future<WebViewEnvironment> get shared => _pending ??= _create();

  static Future<WebViewEnvironment> _create() async {
    try {
      final support = await getApplicationSupportDirectory();
      final directory = Directory('${support.path}/webview2');
      await directory.create(recursive: true);
      return await WebViewEnvironment.create(
          settings: WebViewEnvironmentSettings(userDataFolder: directory.path));
    } catch (_) {
      _pending = null;
      rethrow;
    }
  }

  static Future<CookieManager> get cookies async =>
      CookieManager.instance(webViewEnvironment: await shared);
}

/// WebView2 浏览视图。只在 Windows 使用，移动端保留原生 WebView 行为。
class WindowsWebView extends StatefulWidget {
  const WindowsWebView({
    super.key,
    required this.url,
    this.userAgent,
    this.clearCookies = false,
    this.onReady,
    this.onLoading,
    this.onLoaded,
    this.onNavigation,
    this.onTitle,
  });

  final String url;
  final String? userAgent;
  final bool clearCookies;
  final VoidCallback? onReady;
  final ValueChanged<bool>? onLoading;
  final ValueChanged<String>? onLoaded;
  final Future<bool> Function(String)? onNavigation;
  final ValueChanged<String>? onTitle;

  @override
  State<WindowsWebView> createState() => _WindowsWebViewState();
}

class _WindowsWebViewState extends State<WindowsWebView> {
  late Future<WebViewEnvironment> _environment = _prepare();
  InAppWebViewController? _controller;
  String? _loadError;

  Future<WebViewEnvironment> _prepare() async {
    final environment = await WindowsWebEnvironment.shared;
    if (widget.clearCookies) {
      await CookieManager.instance(webViewEnvironment: environment)
          .deleteAllCookies();
    }
    return environment;
  }

  Widget _failure(String message) => Center(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: () {
                      if (_loadError != null && _controller != null) {
                        setState(() => _loadError = null);
                        _controller!.reload();
                      } else {
                        setState(() => _environment = _prepare());
                      }
                    },
                    child: const Text('重试')),
              ],
            )),
      );

  @override
  Widget build(BuildContext context) => FutureBuilder<WebViewEnvironment>(
        future: _environment,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _failure(
                '无法初始化网页组件。请安装 Microsoft Edge WebView2 Runtime 后重试。');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(children: [
            InAppWebView(
              webViewEnvironment: snapshot.data,
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(
                userAgent: widget.userAgent,
                javaScriptEnabled: true,
                useShouldOverrideUrlLoading: true,
                supportMultipleWindows: true,
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
                widget.onReady?.call();
              },
              onLoadStart: (_, url) {
                if (mounted) setState(() => _loadError = null);
                widget.onLoading?.call(true);
              },
              onLoadStop: (_, url) {
                widget.onLoading?.call(false);
                if (url != null) widget.onLoaded?.call(url.toString());
              },
              onTitleChanged: (_, title) {
                if (title != null && title.trim().isNotEmpty) {
                  widget.onTitle?.call(title);
                }
              },
              shouldOverrideUrlLoading: (_, action) async {
                final url = action.request.url;
                if (url == null) return NavigationActionPolicy.CANCEL;
                if (action.isForMainFrame == false) {
                  return NavigationActionPolicy.ALLOW;
                }
                return await widget.onNavigation?.call(url.toString()) ?? true
                    ? NavigationActionPolicy.ALLOW
                    : NavigationActionPolicy.CANCEL;
              },
              onCreateWindow: (controller, action) async {
                final url = action.request.url;
                if (url != null &&
                    (await widget.onNavigation?.call(url.toString()) ?? true)) {
                  await controller.loadUrl(urlRequest: URLRequest(url: url));
                }
                return false;
              },
              onReceivedError: (_, request, error) {
                if (request.isForMainFrame == true && mounted) {
                  setState(() => _loadError = '网页加载失败，请检查网络后重试');
                  widget.onLoading?.call(false);
                }
              },
            ),
            if (_loadError != null)
              Positioned.fill(
                  child: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: _failure(_loadError!),
              )),
          ]);
        },
      );
}
