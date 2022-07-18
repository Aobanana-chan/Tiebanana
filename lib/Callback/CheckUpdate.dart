import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Callback/LifeTimeCallback.dart';
import 'package:tiebanana/Widgets/common/AlterDialog.dart';
import 'package:tiebanana/common/Config/Version.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/routes.dart';

///自动检查版本更新
class AutoCheckUpdate extends APPStateCallback {
  @override
  void afterInit() {}

  @override
  void onRoute(RouteSettings settings) {}

  @override
  void onHomeFormPageCreate(BuildContext context) {
    if (Global.setting.checkUpdateAutomaticlly == true && !isCanceled()) {
      Version().checkUpdate().then((value) async {
        Global.profile.setInt(
            "latestAutoCheckUpdate", DateTime.now().millisecondsSinceEpoch);
        if (Version().hasUpdate!) {
          bool? r = await showDialog(
              context: context,
              builder: (builder) =>
                  const TiebaAlterDialog(title: "发现新版本,是否前往更新？"));
          if (r == true) {
            // ignore: use_build_context_synchronously
            Navigator.pushNamed(context, PageRouter.appUpdate);
          }
        }
      });
    }

    done = true;
  }

  bool isCanceled() {
    var time = Global.profile.getInt("latestAutoCheckUpdate");
    if (time != null) {
      var date = DateTime.fromMillisecondsSinceEpoch(time);
      var now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return true;
      }
    }
    return false;
  }
}
