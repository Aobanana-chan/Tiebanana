import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/update/data/version.dart';
import 'package:tiebanana/features/update/services/auto_check_update.dart';
import 'package:tiebanana/features/update/state/update_reminder.dart';
import 'package:tiebanana/features/update/widgets/update_badge.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    Version.debugSetCurrentVersion('1.1.0');
    UpdateReminder.restore();
  });

  testWidgets('冷启动仍检查，同一版本只弹一次，稍后保留红点', (tester) async {
    int requests = 0;
    String latestVersion = 'v1.1.0';
    bool hasUpdate = false;

    Future<void> coldStart() async {
      await tester.pumpWidget(const SizedBox.shrink());
      final checker = AutoCheckUpdate(checkUpdate: () async {
        requests++;
        return UpdateCheckResult(
          status: hasUpdate ? UpdateStatus.available : UpdateStatus.upToDate,
          currentVersion: '1.1.0',
          latestVersion: latestVersion,
        );
      });
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => APPSettingProvider(),
        child: MaterialApp(
          theme: TiebananaTheme.light(seedOf('blue'), 16),
          home: Builder(builder: (context) {
            checker.onHomeFormPageCreate(context);
            checker.onHomeFormPageCreate(context);
            return const Scaffold(body: UpdateBadge());
          }),
        ),
      ));
      await tester.pumpAndSettle();
    }

    await coldStart();
    expect(requests, 1);
    expect(find.textContaining('发现新版本'), findsNothing);

    latestVersion = 'v1.1.1';
    hasUpdate = true;
    await coldStart();
    expect(requests, 2);
    expect(find.text('发现新版本 v1.1.1'), findsOneWidget);
    await tester.tap(find.text('稍后'));
    await tester.pumpAndSettle();
    expect(find.byType(Badge), findsOneWidget);

    await coldStart();
    expect(requests, 3);
    expect(find.text('发现新版本 v1.1.1'), findsNothing);
    expect(find.byType(Badge), findsOneWidget);

    latestVersion = 'v1.1.2';
    await coldStart();
    expect(requests, 4);
    expect(find.text('发现新版本 v1.1.2'), findsOneWidget);
    await tester.tap(find.text('跳过此版本'));
    await tester.pumpAndSettle();
    expect(find.byType(Badge), findsNothing);

    latestVersion = 'v1.1.1';
    await coldStart();
    expect(find.textContaining('发现新版本'), findsNothing);
  });

  testWidgets('跨日兼容旧提醒，关闭自动检查立即隐藏红点', (tester) async {
    await Global.profile
        .setString('latestAutoUpdateReminder', '2020-1-1:v1.1.1');
    const result = UpdateCheckResult(
      status: UpdateStatus.available,
      currentVersion: '1.1.0',
      latestVersion: 'v1.1.1',
    );
    int requests = 0;
    await tester.pumpWidget(MaterialApp(
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: Builder(builder: (context) {
        AutoCheckUpdate(checkUpdate: () async {
          requests++;
          return result;
        }).onHomeFormPageCreate(context);
        return const Scaffold(body: UpdateBadge());
      }),
    ));
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.textContaining('发现新版本'), findsNothing);
    expect(find.byType(Badge), findsOneWidget);

    final settings = APPSettingProvider();
    addTearDown(settings.dispose);
    settings.checkUpdateAutomatically = false;
    await tester.pump();
    expect(find.byType(Badge), findsNothing);

    settings.checkUpdateAutomatically = true;
    await tester.pump();
    expect(find.byType(Badge), findsOneWidget);

    await UpdateReminder.markViewed(result);
    UpdateReminder.restore();
    await tester.pump();
    expect(find.byType(Badge), findsNothing);
    expect(UpdateReminder.shouldPrompt('v1.1.1'), isFalse);
  });
}
