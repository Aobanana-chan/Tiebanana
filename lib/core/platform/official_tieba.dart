import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 官方客户端公开使用的 unidispatch 链接，仅携带贴吧名、帖子 ID 和楼层 ID。
class OfficialTiebaTarget {
  const OfficialTiebaTarget({required this.forumName, this.tid, this.pid});

  final String forumName;
  final String? tid;
  final String? pid;

  bool get isThread => tid != null && tid!.isNotEmpty;

  Uri get uri => Uri(
        scheme: 'com.baidu.tieba',
        host: 'unidispatch',
        path: isThread ? '/pb' : '/frs',
        queryParameters: isThread
            ? {'tid': tid!, if (pid != null && pid!.isNotEmpty) 'pid': pid!}
            : {'kw': forumName},
      );

  Future<bool> open() async {
    return _open(uri, method: 'open');
  }

  /// 用官方贴吧客户端打开任意贴吧 scheme。
  ///
  /// 站内没有对应页面时使用。Android 上指定 `com.baidu.tieba` 包，
  /// 避免本应用也注册了贴吧 scheme 时跳回自己。
  static Future<bool> openOfficialTiebaUri(Uri uri) async {
    return _open(uri, method: 'openUri');
  }

  static Future<bool> _open(Uri uri, {required String method}) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return await const MethodChannel('tiebanana/official_tieba')
                .invokeMethod<bool>(method, {'url': uri.toString()}) ??
            false;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
