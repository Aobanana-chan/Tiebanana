import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiebanana/app/navigation/clipboard_thread_preview.dart';
import 'package:tiebanana/shared/widgets/alert_dialog.dart';
import 'package:tiebanana/app/navigation/route_names.dart';

abstract class AppUtil {
  static Future<bool> urlRoute(BuildContext context, String url,
      {bool needConfirm = false, String forumName = ''}) async {
    var uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }
    var qurey = uri.queryParameters;

    final TopicPageRouterData? topic =
        topicRouteData(url, forumName: forumName);
    if (topic != null) {
      await Clipboard.setData(const ClipboardData(text: ''));
      if (!context.mounted) return true;
      Navigator.pushNamed(context, PageRouter.topic, arguments: topic);
      return true;
    }

    if (uri.host == "tieba.baidu.com" && uri.path == "/f") {
      //清除剪切板
      await Clipboard.setData(const ClipboardData(text: ''));
      //进入吧界面
      if (context.mounted) {
        Navigator.pushNamed(context, PageRouter.forumHome,
            arguments: qurey["kw"]);
      }

      return true;
    } else if (uri.host == "tieba.baidu.com" && uri.path.startsWith("/p/")) {
      //清除剪切板
      await Clipboard.setData(const ClipboardData(text: ''));

      //进入贴界面
      var tid = uri.path.substring(3);
      if (!context.mounted) {
        return false;
      }
      if (needConfirm) {
        bool? q = await showDialog(
            context: context,
            builder: (builder) => TiebaAlterDialog(
                  title: "是否进入剪切板复制的贴?",
                  content: ClipBordEnterThread(
                    originUrl: url,
                    tid: tid,
                  ),
                ));
        if (q == true && context.mounted) {
          Navigator.pushNamed(context, PageRouter.threadPage,
              arguments: ThreadPageRouterData(kz: tid, pid: qurey["pid"]));
          return true;
        } else {
          return false;
        }
      } else {
        if (context.mounted) {
          Navigator.pushNamed(context, PageRouter.threadPage,
              arguments: ThreadPageRouterData(kz: tid, pid: qurey["pid"]));
        }

        return true;
      }
    }

    return false;
  }

  /// 从话题链接解析站内话题页参数；非话题链接返回 null。
  ///
  /// 覆盖官方内容段实际出现的三种形态：
  /// - `/mo/q/hotMessage?...&&topic_name=...`（旧帖最常见，topic_id 常为 0）
  /// - `/hottopic/browse/hottopic?...`
  /// - `/mo/q/hybrid-usergrow-base/naTopicDetail?...`
  static TopicPageRouterData? topicRouteData(String url,
      {String forumName = ''}) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return null;
    final String host = uri.host.toLowerCase();
    if (host != 'tieba.baidu.com' && host != 'tiebac.baidu.com') return null;
    final String path = uri.path.toLowerCase();
    final bool isTopic = path.contains('hotmessage') ||
        path.contains('hottopic') ||
        path.contains('natopicdetail');
    if (!isTopic) return null;
    final Map<String, String> query = uri.queryParameters;
    final String name = _cleanTopicName(
      query['topic_name'] ?? query['topicName'] ?? '',
    );
    if (name.isEmpty) return null;
    return TopicPageRouterData(
      name: name,
      topicId: _nonZero(query['topic_id'] ?? query['topicId'] ?? ''),
      fid: _nonZero(query['fid'] ?? query['topic_fid'] ?? ''),
      forumName: forumName,
    );
  }

  /// 旧链接里的 `0` 是占位值，视为空 ID。
  static String _nonZero(String value) {
    final String text = value.trim();
    return text == '0' ? '' : text;
  }

  static String _cleanTopicName(String value) {
    String name = value.trim();
    if (name.length > 2 && name.startsWith('#') && name.endsWith('#')) {
      name = name.substring(1, name.length - 1);
    }
    return name.trim();
  }

  static Future observClipBord(
      BuildContext context, AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      var data = await Clipboard.getData("text/plain");
      if (context.mounted) {
        await urlRoute(context, data?.text ?? "", needConfirm: true);
      }
    }
  }
}
