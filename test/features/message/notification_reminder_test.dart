// 通知区：通用行、分组头折叠、隐藏与常驻铃铛恢复。
import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/message/pages/message_page.dart';
import 'package:tiebanana/features/message/state/message_reminder.dart';
import 'package:tiebanana/features/message/state/notify_entry.dart';
import 'package:tiebanana/features/message/state/notification_reminder.dart';
import 'package:tiebanana/features/message/widgets/notify_entry_row.dart';
import 'package:tiebanana/features/message/widgets/notify_section_header.dart';
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

  test('没有通知数据时不渲染通知区，铃铛仍保留', () {
    final NotificationReminder reminder = NotificationReminder.instance;
    reminder.debugSet(
      mutual: TiebaMutualHelpNotice.empty,
      broadcast: TiebaBroadcastNotice.empty,
      loggedIn: true,
    );

    expect(reminder.hasNotifyData, isFalse);
    expect(reminder.entries, hasLength(1));
    final NotifyEntry entry = reminder.entries.single;
    expect(entry.kind, NotifyEntryKind.broadcast);
    expect(entry.badge, NotifyBadgeKind.none);
    expect(reminder.sectionMeta, '暂无未读');
    // 不画占位、不写「未连接」；面板仍可打开广播页。
    expect(reminder.reminderVisible, isFalse);
    expect(reminder.bellVisible, isTrue);
  });

  test('广播只贡献红点，已屏蔽的互助不计入数字', () {
    final NotificationReminder reminder = NotificationReminder.instance;
    reminder.debugSet(
      mutual: const TiebaMutualHelpNotice(
        visible: true,
        unread: 3,
        masked: true,
      ),
      broadcast: const TiebaBroadcastNotice(
        unread: true,
        title: '期末考试安排已发布',
      ),
      loggedIn: true,
    );

    expect(reminder.mutualUnread, 0);
    expect(reminder.visibleUnreadCount, 0);
    expect(reminder.visibleBroadcastDot, isTrue);
    expect(reminder.sectionMeta, '有新公告');

    final NotifyEntry mutual = reminder.entries.firstWhere(
        (NotifyEntry entry) => entry.kind == NotifyEntryKind.mutualHelp);
    expect(mutual.badge, NotifyBadgeKind.none);
    expect(mutual.muted, isTrue);

    final NotifyEntry broadcast = reminder.entries.firstWhere(
        (NotifyEntry entry) => entry.kind == NotifyEntryKind.broadcast);
    expect(broadcast.badge, NotifyBadgeKind.dot);
  });

  test('已读之后，同一时间的概览不会重新点亮未读', () async {
    final _FixedTimeNotifyApi api = _FixedTimeNotifyApi();
    Global.tiebaAPI = api;
    final NotificationReminder reminder = NotificationReminder.instance;

    await reminder.load();
    expect(reminder.mutualUnread, 3);
    expect(reminder.broadcastDot, isTrue);

    reminder.markMutualRead();
    reminder.markBroadcastRead();
    expect(reminder.mutualUnread, 0);
    expect(reminder.broadcastDot, isFalse);

    // IM 概览会继续返回同一个未读；消费时间之后不应回弹。
    await reminder.refresh();
    expect(reminder.mutualUnread, 0);
    expect(reminder.broadcastDot, isFalse);

    // 时间没变但计数变大，仍然算新提醒。
    api.unread = 5;
    await reminder.refresh();
    expect(reminder.mutualUnread, 5);

    // 新消息把 latestTime 推后，红点重新出现。
    api.time = api.time.add(const Duration(minutes: 5));
    await reminder.refresh();
    expect(reminder.mutualUnread, 5);
    expect(reminder.broadcastDot, isTrue);
  });

  test('远端为空时保留缓存，重启后仍能渲染通知区', () async {
    Global.tiebaAPI = _FixedTimeNotifyApi();
    final NotificationReminder reminder = NotificationReminder.instance;
    await reminder.load();
    expect(reminder.broadcast.hasData, isTrue);
    expect(reminder.reminderVisible, isTrue);

    // IM 这次没给数据，但缓存里的广播仍在，不应该退回空白。
    Global.tiebaAPI = _EmptyNotifyApi();
    await reminder.refresh();
    expect(reminder.broadcast.hasData, isTrue);
    expect(reminder.reminderVisible, isTrue);

    reminder.markBroadcastRead();
    await reminder.refresh();
    expect(reminder.broadcastDot, isFalse);

    // 重启：运行时清空后按本机缓存恢复。
    reminder.reset();
    Global.tiebaAPI = _EmptyNotifyApi();
    await reminder.load();
    expect(reminder.broadcast.hasData, isTrue);
    expect(reminder.reminderVisible, isTrue);
    expect(reminder.broadcastDot, isFalse);
  });

  testWidgets('没有通知数据时整块隐藏，只留铃铛', (WidgetTester tester) async {
    Global.tiebaAPI = _EmptyNotifyApi();
    final FloatingSearchBarController search = FloatingSearchBarController();
    addTearDown(search.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(MessagePan(controller: search)));
    await tester.pump();
    await tester.pump();

    expect(find.byType(NotifySectionHeader), findsNothing);
    expect(find.byType(NotifyEntryRow), findsNothing);
    expect(find.text('功能入口'), findsNothing);
    expect(find.textContaining('未连接'), findsNothing);
    // 铃铛仍可作为广播入口。
    expect(find.byType(ReminderBell), findsOneWidget);
  });

  testWidgets('通知行按数据生成，可折叠、隐藏，并由常驻铃铛恢复', (WidgetTester tester) async {
    final FloatingSearchBarController search = FloatingSearchBarController();
    addTearDown(search.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(MessagePan(controller: search)));
    await tester.pump();
    await tester.pump();

    // 演示后端同时给出互助与广播，所以是两条通用行，而不是两张专用卡。
    expect(find.byType(NotifySectionHeader), findsOneWidget);
    expect(find.byType(NotifyEntryRow), findsNWidgets(2));
    expect(find.text('吧友互助'), findsOneWidget);
    expect(find.text('吧广播'), findsOneWidget);
    expect(NotificationReminder.instance.hasNotifyData, isTrue);

    // 铃铛常驻，任何卡都没被隐藏时也在，且没有红点。
    expect(find.byType(ReminderBell), findsOneWidget);
    expect(NotificationReminder.instance.bellVisible, isTrue);
    expect(NotificationReminder.instance.bellDot, isFalse);

    // 折叠只留下分组头，行不占高度。
    await tester.tap(find.byIcon(Icons.expand_less));
    await tester.pump();
    expect(find.byType(NotifyEntryRow), findsNothing);
    expect(find.byType(NotifySectionHeader), findsOneWidget);

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pump();
    expect(find.byType(NotifyEntryRow), findsNWidgets(2));

    // 隐藏整组：分组头消失，铃铛保留并亮红点。
    await tester.tap(find.descendant(
      of: find.byType(NotifySectionHeader),
      matching: find.byIcon(Icons.close),
    ));
    await tester.pump();

    expect(find.byType(NotifySectionHeader), findsNothing);
    expect(find.byType(NotifyEntryRow), findsNothing);
    expect(find.text('提醒已隐藏'), findsOneWidget);
    expect(find.byType(ReminderBell), findsOneWidget);
    expect(NotificationReminder.instance.bellVisible, isTrue);
    expect(NotificationReminder.instance.bellDot, isTrue);

    // 面板按行恢复：互助、广播各有自己的显示开关，另有账号级 switch 45。
    await tester.tap(find.byType(ReminderBell));
    await tester.pumpAndSettle();
    expect(find.text('消息提醒'), findsOneWidget);
    expect(find.text('通知'), findsOneWidget);
    expect(find.text('账号'), findsOneWidget);
    expect(find.text('打开互助'), findsOneWidget);
    expect(find.text('打开吧广播'), findsOneWidget);
    expect(find.text('接收互助提醒'), findsOneWidget);
    // 面板不再出现技术说明或 switch 17 提示。
    expect(find.textContaining('不清未读'), findsNothing);
    expect(find.textContaining('switch 17'), findsNothing);
    expect(find.byKey(const ValueKey<String>('notify-visibility-mutualHelp')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('notify-visibility-broadcast')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('mutual-account-toggle')),
        findsOneWidget);

    // 开关顺序：互助显示、广播显示、接收互助提醒。
    await tester.tap(
        find.byKey(const ValueKey<String>('notify-visibility-mutualHelp')));
    await tester.pump();
    await tester
        .tap(find.byKey(const ValueKey<String>('notify-visibility-broadcast')));
    await tester.pump();
    expect(NotificationReminder.instance.mutualVisible, isTrue);
    expect(NotificationReminder.instance.broadcastVisible, isTrue);
    expect(NotificationReminder.instance.bellDot, isFalse);

    // 关掉面板后行恢复，铃铛仍在。
    Navigator.of(tester.element(find.text('消息提醒'))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(NotifyEntryRow), findsNWidgets(2));
    expect(find.byType(ReminderBell), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}

/// 没有任何通知数据的后端。
class _EmptyNotifyApi extends DemoTiebaApi {
  _EmptyNotifyApi() : super(latency: Duration.zero);

  @override
  Future<TiebaNotificationOverview> getNotificationOverview() async =>
      TiebaNotificationOverview.empty;

  @override
  Future<bool> getMutualHelpMasked() async => false;
}

/// 固定时间的通知概览，用来验证「已读不回弹」。
class _FixedTimeNotifyApi extends DemoTiebaApi {
  _FixedTimeNotifyApi() : super(latency: Duration.zero);

  DateTime time = DateTime(2026, 1, 1, 12);
  int unread = 3;

  @override
  Future<TiebaNotificationOverview> getNotificationOverview() async {
    return TiebaNotificationOverview(
      mutualHelp: TiebaMutualHelpNotice(
        visible: true,
        unread: unread,
        latestTime: time,
      ),
      broadcast: TiebaBroadcastNotice(
        unread: true,
        latestTime: time,
        title: '期末考试安排已发布',
        summary: '请提前查看考场',
      ),
    );
  }

  @override
  Future<bool> getMutualHelpMasked() async => false;
}
