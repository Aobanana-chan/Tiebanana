import 'package:flutter/material.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView 导航拦截回调。
///
/// 返回 true 表示交给 WebView 继续导航，false 表示已经由外部处理。
typedef WebViewNavigationHandler = Future<bool> Function(
    BuildContext context, String url);

/// 应用内置浏览器页。
///
/// 只负责展示 WebView 和标题；站内跳转、外部 APP scheme 等策略由
/// [onNavigation] 注入，避免页面与链接路由互相依赖。
class InAppBrowserPage extends StatefulWidget {
  const InAppBrowserPage({
    super.key,
    required this.initialUrl,
    required this.onNavigation,
    this.title,
  });

  final String initialUrl;
  final WebViewNavigationHandler onNavigation;
  final String? title;

  @override
  State<InAppBrowserPage> createState() => _InAppBrowserPageState();
}

class _InAppBrowserPageState extends State<InAppBrowserPage> {
  late final WebViewController _controller;
  String? _title;
  bool _handlingNavigation = false;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _controller = WebViewController()
      ..setBackgroundColor(Colors.white)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: _onNavigationRequest,
        onPageFinished: _updateTitle,
      ))
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<void> _updateTitle(String url) async {
    String? title;
    try {
      title = await _controller.getTitle();
    } catch (_) {
      return;
    }
    final String text = title?.trim() ?? '';
    if (!mounted || text.isEmpty || text == _title) {
      return;
    }
    setState(() => _title = text);
  }

  Future<NavigationDecision> _onNavigationRequest(
      NavigationRequest request) async {
    if (_handlingNavigation) {
      return NavigationDecision.prevent;
    }
    _handlingNavigation = true;
    try {
      final bool navigate = await widget.onNavigation(context, request.url);
      return navigate
          ? NavigationDecision.navigate
          : NavigationDecision.prevent;
    } finally {
      _handlingNavigation = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Uri? uri = Uri.tryParse(widget.initialUrl);
    final String fallbackTitle =
        uri != null && uri.host.isNotEmpty ? uri.host : '浏览器';
    return Scaffold(
      backgroundColor: tokens.surface,
      appBar: AppBar(
        title: Text(
          _title ?? fallbackTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
