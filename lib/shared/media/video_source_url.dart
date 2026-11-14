import 'package:flutter/foundation.dart';

/// 此 CDN 支持 HTTPS。Windows FFmpeg 的 HTTP 代理请求会显式带 :80，
/// 在当前代理/CDN 链路触发 401；HTTPS 通过 CONNECT 保留代理并避免该形式。
/// 只替换协议前缀，避免重编码签名、空参数或参数顺序。
String videoSourceUrl(String url) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return url;
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !url.startsWith('http://') ||
      uri.host != 'tb-video.bdstatic.com' ||
      uri.hasPort ||
      uri.userInfo.isNotEmpty) {
    return url;
  }
  return 'https://${url.substring('http://'.length)}';
}
