// 消息提醒区：默认收起、展开两张卡、隐藏后铃铛恢复。
import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/message/pages/message_page.dart';
import 'package:tiebanana/features/message/state/message_reminder.dart';
import 'package:tiebanana/features/message/state/notification_reminder.dart';
import 'package:tiebanana/features/message/widgets/broadcast_entry_card.dart';
import 'package:tiebanana/features/message/widgets/mutual_help_card.dart';
import 'package:tiebanana/features/message/widgets/reminder_bar.dart';
import 'package:tiebanana/features/message/widgets/reminder_bell.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/floating_search_app_bar.dart';

Widget _app(Widget child) {
  return ChangeNotifierProvider<APPSettingProvider>(
    create: (BuildContext context) => APPSettingProvider(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    Global.tiebaAPI = DemoTiebaApi(latency: Duration.zero);
    MessageReminder.reset();
  });

  testWidgets('默认收起，点开显示互助与广播，隐藏后铃铛可恢复', (WidgetTester tester) async {
    final FloatingSearchBarController search = FloatingSearchBarController();
    addTearDown(search.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(MessagePan(controller: search)));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ReminderBar), findsOneWidget);
    expect(find.byType(MutualHelpCard), findsNothing);
    expect(find.byType(BroadcastEntryCard), findsNothing);
    expect(find.byType(ReminderBell), findsNothing);

    await tester.tap(find.byType(ReminderBar));
    await tester.pump();
    expect(find.byType(MutualHelpCard), findsOneWidget);
    expect(find.byType(BroadcastEntryCard), findsOneWidget);
    expect(find.text('去帮忙'), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(ReminderBar),
      matching: find.byIcon(Icons.close),
    ));
    await tester.pump();

    expect(find.byType(ReminderBar), findsNothing);
    expect(find.byType(MutualHelpCard), findsNothing);
    expect(find.byType(ReminderBell), findsOneWidget);
    expect(find.text('提醒已隐藏'), findsOneWidget);
    expect(NotificationReminder.instance.bellVisible, isTrue);
    expect(NotificationReminder.instance.bellDot, isTrue);

    await tester.tap(find.byType(ReminderBell));
    await tester.pumpAndSettle();
    expect(find.text('消息提醒'), findsOneWidget);
    expect(find.text('显示卡片'), findsOneWidget);
    expect(find.text('显示入口'), findsOneWidget);

    await tester.tap(find.text('显示卡片'));
    await tester.pump();
    await tester.tap(find.text('显示入口'));
    await tester.pump();
    expect(NotificationReminder.instance.mutualVisible, isTrue);
    expect(NotificationReminder.instance.broadcastVisible, isTrue);

    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
}
