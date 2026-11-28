import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';

void main() {
  testWidgets('桌面侧边栏在展开和折叠的动画帧中不溢出', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting)
      ..sidebarFolded = true;

    await tester.pumpWidget(
      ChangeNotifierProvider<APPSettingProvider>(
        create: (_) => APPSettingProvider(),
        child: MaterialApp(
          theme: TiebananaTheme.light(seedOf('blue'), 16),
          home: const DesktopShellFrame(
            title: '首页',
            child: SizedBox.expand(),
          ),
        ),
      ),
    );

    Future<void> pumpTransition() async {
      await tester.pump();
      expect(tester.takeException(), isNull);
      for (int elapsed = 0;
          elapsed < TiebananaMetrics.durationFast.inMilliseconds;
          elapsed += 10) {
        await tester.pump(const Duration(milliseconds: 10));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    final Finder expand = find.byTooltip('展开侧边栏');
    final Finder collapse = find.byTooltip('折叠侧边栏');
    final Finder wordmark = find.text('Tiebanana');
    expect(wordmark, findsNothing);

    await tester.tap(expand);
    await pumpTransition();
    expect(wordmark, findsOneWidget);

    await tester.tap(collapse);
    await pumpTransition();
    expect(expand, findsOneWidget);
    expect(wordmark, findsNothing);
  });
}
