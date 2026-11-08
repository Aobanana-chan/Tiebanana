import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/app/navigation/clipboard_thread_preview.dart';
import 'package:tiebanana/core/platform/browser_url.dart';
import 'package:tiebanana/core/platform/official_tieba.dart';
import 'package:tiebanana/features/browser/pages/in_app_browser_page.dart';
import 'package:tiebanana/shared/widgets/alert_dialog.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:url_launcher/url_launcher.dart';

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

  /// 打开正文 / 楼中楼中的链接。
  ///
  /// 站内能处理的贴吧链接直接进入对应页面；外链按设置交给内置浏览器
  /// 或系统浏览器；其他 APP scheme 交给系统解析。
  static Future<void> openLink(BuildContext context, String url,
      {String forumName = ''}) async {
    final String text = url.trim();
    if (text.isEmpty) {
      return;
    }
    if (await urlRoute(context, text, forumName: forumName)) {
      return;
    }

    final Uri? uri = Uri.tryParse(text);
    if (uri == null) {
      return;
    }

    if (BrowserUrl.isWeb(uri)) {
      if (!context.mounted) {
        return;
      }
      if (Global.setting.useBuildinBrowser ?? true) {
        await Navigator.of(context).push(appPageRoute(
          builder: (BuildContext pageContext) => InAppBrowserPage(
            initialUrl: text,
            onNavigation: (BuildContext browserContext, String requestUrl) =>
                handleWebViewNavigation(browserContext, requestUrl,
                    forumName: forumName),
          ),
        ));
      } else {
        await _launchExternal(context, uri);
      }
      return;
    }

    if (!context.mounted) {
      return;
    }
    if (BrowserUrl.isWebViewInternal(uri)) {
      return;
    }
    await _handleNonWebUri(context, uri, allowClose: false);
  }

  /// WebView 导航策略。
  ///
  /// 返回 true 表示继续交给 WebView 加载，false 表示已拦截并处理。
  static Future<bool> handleWebViewNavigation(BuildContext context, String url,
      {bool allowClose = true, String forumName = ''}) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }

    if (BrowserUrl.isWeb(uri)) {
      if (await urlRoute(context, url, forumName: forumName)) {
        return false;
      }
      return true;
    }

    if (BrowserUrl.isWebViewInternal(uri)) {
      return true;
    }

    return _handleNonWebUri(context, uri, allowClose: allowClose);
  }

  static Future<bool> _handleNonWebUri(BuildContext context, Uri uri,
      {required bool allowClose}) async {
    if (BrowserUrl.isCloseCurrentPage(uri)) {
      if (allowClose && context.mounted) {
        Navigator.of(context).maybePop();
      }
      return false;
    }

    final TiebaDeepLink? target = BrowserUrl.tiebaDeepLink(uri);
    if (target != null) {
      if (context.mounted) {
        if (target.isThread) {
          Navigator.pushNamed(context, PageRouter.threadPage,
              arguments:
                  ThreadPageRouterData(kz: target.tid!, pid: target.pid));
        } else if (target.forumName != null && target.forumName!.isNotEmpty) {
          Navigator.pushNamed(context, PageRouter.forumHome,
              arguments: target.forumName);
        }
      }
      return false;
    }

    // 贴吧 scheme 站内没有对应页面时，交给官方贴吧客户端。
    if (BrowserUrl.isTiebaScheme(uri)) {
      final bool opened = await OfficialTiebaTarget.openOfficialTiebaUri(uri);
      if (!opened && context.mounted) {
        _showNoHandler(context);
      }
      return false;
    }

    await _launchExternal(context, uri);
    return false;
  }

  static Future<bool> _launchExternal(BuildContext context, Uri uri) async {
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      opened = false;
    } on MissingPluginException {
      opened = false;
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      _showNoHandler(context);
    }
    return opened;
  }

  static void _showNoHandler(BuildContext context) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('未安装可打开该链接的应用')),
    );
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
