import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiebanana/Widgets/ClipbordEnterThread.dart';
import 'package:tiebanana/Widgets/common/AlterDialog.dart';
import 'package:tiebanana/routes/routes.dart';
import 'package:webview_flutter/webview_flutter.dart';

abstract class AppUtil {
  static Future<bool> urlRoute(bool mounted, BuildContext context, String url,
      {bool needConfirm = false}) async {
    var uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }
    var qurey = uri.queryParameters;

    if (uri.host == "tieba.baidu.com" && uri.path == "/f") {
      //清除剪切板
      await Clipboard.setData(const ClipboardData(text: null));
      //进入吧界面
      if (mounted) {
        Navigator.pushNamed(context, PageRouter.forumHome,
            arguments: qurey["kw"]);
      }

      return true;
    } else if (uri.host == "tieba.baidu.com" && uri.path.startsWith("/p/")) {
      //清除剪切板
      await Clipboard.setData(const ClipboardData(text: null));

      //进入贴界面
      var tid = uri.path.substring(3);
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
        if (q == true && mounted) {
          Navigator.pushNamed(context, PageRouter.threadPage,
              arguments: ThreadPageRouterData(kz: tid, pid: qurey["pid"]));
          return true;
        } else {
          return false;
        }
      } else {
        if (mounted) {
          Navigator.pushNamed(context, PageRouter.threadPage,
              arguments: ThreadPageRouterData(kz: tid, pid: qurey["pid"]));
        }

        return true;
      }
    }

    return false;
  }

  static Future observClipBord(
      bool mounted, BuildContext context, AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      var data = await Clipboard.getData("text/plain");
      if (mounted) {
        await urlRoute(mounted, context, data?.text ?? "", needConfirm: true);
      }
    }
  }
}
