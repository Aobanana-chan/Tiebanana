import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tiebanana/app/lifecycle/app_lifecycle_hook.dart';
import 'package:tiebanana/features/update/data/version.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/widgets/alert_dialog.dart';

///自动检查版本更新
class AutoCheckUpdate extends APPStateCallback {
  static const String _lastCheckKey = "latestAutoCheckUpdate";
  static const String _ignoredVersionKey = "ignoredUpdateVersion";

  @override
  void afterInit() {}

  @override
  void onRoute(RouteSettings settings) {}

  @override
  void onHomeFormPageCreate(BuildContext context) {
    // 更新页只处理 Android APK；其他平台不弹“去下载 APK”的提示。
    if (!Version.isAndroidPlatform ||
        Global.setting.checkUpdateAutomaticlly != true ||
        isCanceled()) {
      done = true;
      return;
    }

    unawaited(_check(context));
    done = true;
  }

  Future<void> _check(BuildContext context) async {
    try {
      final UpdateCheckResult result = await Version.checkUpdate();

      // 只在成功后记录时间戳；失败时下次冷启动重试，成功当天只请求一次。
      if (result.failed) {
        return;
      }
      await Global.profile.setInt(
        _lastCheckKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      if (!result.hasUpdate ||
          !context.mounted ||
          result.latestVersion == _ignoredVersion) {
        return;
      }

      final _UpdateChoice? choice = await showDialog<_UpdateChoice>(
        context: context,
        builder: (BuildContext builder) => TiebaActionDialog<_UpdateChoice>(
          title: "发现新版本 ${result.latestVersion}",
          content: const Text("是否前往更新？"),
          actions: const <TiebaDialogAction<_UpdateChoice>>[
            TiebaDialogAction<_UpdateChoice>('跳过此版本', _UpdateChoice.ignore),
            TiebaDialogAction<_UpdateChoice>('稍后', _UpdateChoice.later),
            TiebaDialogAction<_UpdateChoice>('前往更新', _UpdateChoice.update),
          ],
        ),
      );
      if (!context.mounted) {
        return;
      }
      if (choice == _UpdateChoice.update) {
        Navigator.pushNamed(context, PageRouter.appUpdate);
      } else if (choice == _UpdateChoice.ignore &&
          result.latestVersion != null) {
        await Global.profile.setString(
          _ignoredVersionKey,
          result.latestVersion!,
        );
      }
    } catch (error) {
      // 自动检查属于后台行为，任何异常都不应打断首页。
      debugPrint('自动检查更新失败：$error');
    }
  }

  String? get _ignoredVersion => Global.profile.getString(_ignoredVersionKey);

  bool isCanceled() {
    var time = Global.profile.getInt(_lastCheckKey);
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

enum _UpdateChoice { update, later, ignore }
