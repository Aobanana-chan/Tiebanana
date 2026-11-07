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
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // 本应用也注册了贴吧 scheme，指定官方包，确保跳转到贴吧客户端。
        return await const MethodChannel('tiebanana/official_tieba')
                .invokeMethod<bool>('open', {'url': uri.toString()}) ??
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
