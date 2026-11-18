import 'package:flutter/material.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/app/navigation/link_router.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/browser/pages/in_app_browser_page.dart';
import 'package:tiebanana/features/message/state/notification_reminder.dart';

/// 官方 H5 入口。
///
/// 原生只负责打开网页、传 `obj_type`、清本地未读；问题、回答、广播聚合与
/// 发布都由网页自己完成。
abstract class OfficialNotifyPages {
  static const String mutualHelpBase =
      'https://tieba.baidu.com/mo/q/hybrid-main-user/askDetail'
      '?nonavigationbar=1&customfullscreen=1&loadingSignal=1&anchor=recommend';

  static const String broadcast =
      'https://tieba.baidu.com/mo/q/hybrid-main-frs/baBroadcast'
      '?loadingSignal=1&nonavigationbar=1&customfullscreen=1';

  /// 互助列表；已屏蔽时带 `obj_type=2`。
  static String mutualHelpUrl({required bool masked}) =>
      '$mutualHelpBase&obj_type=${masked ? 2 : 1}';
}

/// 打开互助 H5，并清本地互助未读。
Future<void> openMutualHelp(BuildContext context) async {
  final NotificationReminder reminder = NotificationReminder.instance;
  final bool masked = reminder.masked;
  reminder.markMutualRead();
  await _open(context, OfficialNotifyPages.mutualHelpUrl(masked: masked),
      failure: '网页没有打开，稍后重试');
}

/// 打开原生「吧广播」聚合流，并清本地合并会话红点。
Future<void> openBroadcastFeed(BuildContext context) async {
  NotificationReminder.instance.markBroadcastRead();
  await Navigator.pushNamed(context, PageRouter.broadcastFeed);
}

/// 打开发布吧广播的网页版（只用于发布 / 配额入口）。
Future<void> openBroadcastPublish(BuildContext context,
    {bool markRead = false}) async {
  if (markRead) NotificationReminder.instance.markBroadcastRead();
  await _open(context, OfficialNotifyPages.broadcast, failure: '网页没有打开，稍后重试');
}

Future<void> _open(BuildContext context, String url,
    {required String failure}) async {
  if (!context.mounted) return;
  try {
    await Navigator.of(context).push(
      appPageRoute(
        builder: (BuildContext pageContext) => InAppBrowserPage(
          initialUrl: url,
          onNavigation: (BuildContext browserContext, String requestUrl) =>
              AppUtil.handleWebViewNavigation(browserContext, requestUrl),
        ),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(failure)));
  }
}
