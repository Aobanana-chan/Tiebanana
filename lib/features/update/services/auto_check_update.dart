import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tiebanana/app/lifecycle/app_lifecycle_hook.dart';
import 'package:tiebanana/features/update/data/version.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/update/state/update_reminder.dart';
import 'package:tiebanana/features/update/widgets/update_release_notes.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/alert_dialog.dart';

///自动检查版本更新
class AutoCheckUpdate extends APPStateCallback {
  AutoCheckUpdate({
    Future<UpdateCheckResult> Function() checkUpdate = Version.checkUpdate,
  }) : _checkUpdate = checkUpdate;

  final Future<UpdateCheckResult> Function() _checkUpdate;

  @override
  void afterInit() {}

  @override
  void onRoute(RouteSettings settings) {}

  @override
  void onHomeFormPageCreate(BuildContext context) {
    if (done) return;
    done = true;
    if (!Version.supportsUpdateReminders ||
        !Global.setting.checkUpdateAutomaticlly) {
      return;
    }

    unawaited(_check(context));
  }

  Future<void> _check(BuildContext context) async {
    try {
      final UpdateCheckResult result = await _checkUpdate();
      // 请求期间也可能关闭自动检查。
      if (!Global.setting.checkUpdateAutomaticlly) return;
      await UpdateReminder.recordCheck(result);
      final String? latestVersion = result.latestVersion;
      if (!result.hasUpdate ||
          !context.mounted ||
          !Global.setting.checkUpdateAutomaticlly ||
          latestVersion == null ||
          !UpdateReminder.shouldPrompt(latestVersion)) {
        return;
      }

      final Future<_UpdateChoice?> dialog = showDialog<_UpdateChoice>(
        context: context,
        builder: (BuildContext builder) {
          final Size size = MediaQuery.sizeOf(builder);
          final bool desktop = AppBreakpoints.isDesktopWidth(size.width);
          final TiebananaTokens tokens = TiebananaTokens.of(builder);
          return TiebaActionDialog<_UpdateChoice>(
            title: "发现新版本 $latestVersion",
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: desktop ? 500 : double.maxFinite,
                maxHeight: size.height * (desktop ? 0.46 : 0.4),
              ),
              child: SizedBox(
                width: desktop ? 500 : double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: tokens.primaryContainer,
                        borderRadius: TiebananaMetrics.brPill,
                      ),
                      child: Text(
                        '当前平台：${Version.currentPlatformLabel}',
                        style: Theme.of(builder).textTheme.labelSmall?.copyWith(
                              color: tokens.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        child: UpdateReleaseNotes(notes: result.notes),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: const <TiebaDialogAction<_UpdateChoice>>[
              TiebaDialogAction<_UpdateChoice>('跳过此版本', _UpdateChoice.ignore),
              TiebaDialogAction<_UpdateChoice>('稍后', _UpdateChoice.later),
              TiebaDialogAction<_UpdateChoice>('前往更新', _UpdateChoice.update),
            ],
          );
        },
      );
      await UpdateReminder.markPrompted(latestVersion);
      final _UpdateChoice? choice = await dialog;
      if (choice == _UpdateChoice.update) {
        if (context.mounted) {
          Navigator.pushNamed(context, PageRouter.appUpdate);
        }
      } else if (choice == _UpdateChoice.ignore) {
        await UpdateReminder.ignore(latestVersion);
      }
    } catch (error) {
      // 自动检查属于后台行为，任何异常都不应打断首页。
      debugPrint('自动检查更新失败：$error');
    }
  }
}

enum _UpdateChoice { update, later, ignore }
