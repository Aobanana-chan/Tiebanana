import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/update/data/version.dart';
import 'package:tiebanana/features/update/services/auto_check_update.dart';

void main() {
  testWidgets('当天先查到无更新，后续冷启动仍能发现新版本', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'latestAutoCheckUpdate': DateTime.now().millisecondsSinceEpoch,
    });
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);

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
          home: Builder(builder: (context) {
            checker.onHomeFormPageCreate(context);
            checker.onHomeFormPageCreate(context);
            return const Scaffold();
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

    await coldStart();
    expect(requests, 3);
    expect(find.text('发现新版本 v1.1.1'), findsNothing);

    latestVersion = 'v1.1.2';
    await coldStart();
    expect(requests, 4);
    expect(find.text('发现新版本 v1.1.2'), findsOneWidget);
  });
}
