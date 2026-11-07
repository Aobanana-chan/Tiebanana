// 启动壳的行为：开屏与 Global.init() 并行，谁慢等谁。
//
// 这两个顺序都很容易写反（提前走 / 永远不走），而且真机上不一定复现，
// 所以在测试里把两种时序都钉住。
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/app/bootstrap.dart';
import 'package:tiebanana/features/splash/splash_page.dart';
import 'package:tiebanana/features/splash/splash_timeline.dart';

/// 冒充真正的 App —— 真的 `App` 一建起来就要读 Global，测试里没有。
class _FakeApp extends StatelessWidget {
  const _FakeApp();

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: Color(0xFF00FF00));
}

const Duration _tick = Duration(milliseconds: 20);

Future<void> _pump(WidgetTester tester, Duration d) async {
  final int steps = (d.inMilliseconds / _tick.inMilliseconds).ceil();
  for (int i = 0; i < steps; i++) {
    await tester.pump(_tick);
  }
}

void main() {
  testWidgets('首次启动点击不跳过，完整交接后才记录播放完成', (tester) async {
    final boot = BootState()..markReady();
    var completions = 0;
    await tester.pumpWidget(BootstrapApp(
      boot: boot,
      app: const _FakeApp(),
      onSplashCompleted: () => completions++,
    ));
    await _pump(tester, const Duration(milliseconds: 200));
    final before = tester.widget<SplashPage>(find.byType(SplashPage)).t;
    await tester.tap(find.byType(SplashPage));
    await tester.pump();
    expect(tester.widget<SplashPage>(find.byType(SplashPage)).t, before);
    expect(completions, 0);

    await _pump(tester,
        SplashTiming.introDuration + SplashTiming.handoffDuration + _tick);
    expect(find.byType(SplashPage), findsNothing);
    expect(completions, 1);
  });

  testWidgets('后续启动点击跳到波纹，重复点击不会重播，收尾后进入应用', (tester) async {
    final boot = BootState()
      ..setSplashSkippable(true)
      ..markReady();
    await tester.pumpWidget(BootstrapApp(boot: boot, app: const _FakeApp()));
    await _pump(tester, const Duration(milliseconds: 100));
    final app = tester.element(find.byType(_FakeApp));
    await tester.tap(find.byType(SplashPage));
    await tester.pump();
    expect(tester.widget<SplashPage>(find.byType(SplashPage)).t,
        closeTo(SplashTiming.skipTo, .001));

    await _pump(tester, const Duration(milliseconds: 100));
    final before = tester.widget<SplashPage>(find.byType(SplashPage)).t;
    await tester.tap(find.byType(SplashPage));
    await tester.pump();
    expect(tester.widget<SplashPage>(find.byType(SplashPage)).t, before);
    await _pump(tester, const Duration(milliseconds: 1000));
    expect(find.byType(SplashPage), findsNothing);
    expect(tester.element(find.byType(_FakeApp)), same(app));
  });

  testWidgets('后续启动跳过后仍等待初始化，不提前移除开屏', (tester) async {
    final boot = BootState()..setSplashSkippable(true);
    var completions = 0;
    await tester.pumpWidget(BootstrapApp(
      boot: boot,
      app: const _FakeApp(),
      onSplashCompleted: () => completions++,
    ));
    await tester.tap(find.byType(SplashPage));
    await tester.pump();
    await _pump(tester, SplashTiming.introDuration);
    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(_FakeApp), findsNothing);
    expect(completions, 0);

    boot.markReady();
    await tester.pump();
    await _pump(tester, SplashTiming.handoffDuration + _tick);
    expect(find.byType(SplashPage), findsNothing);
    expect(completions, 1);
  });

  testWidgets('后续启动不点击仍完整播放', (tester) async {
    final boot = BootState()
      ..setSplashSkippable(true)
      ..markReady();
    await tester.pumpWidget(BootstrapApp(boot: boot, app: const _FakeApp()));
    await _pump(tester, SplashTiming.introDuration ~/ 2);
    expect(tester.widget<SplashPage>(find.byType(SplashPage)).t,
        lessThan(SplashTiming.skipTo));
    await _pump(tester,
        SplashTiming.introDuration + SplashTiming.handoffDuration + _tick);
    expect(find.byType(SplashPage), findsNothing);
  });

  test('初始化失败只调用一次，不自动重试；手动重试可以恢复', () async {
    final BootState boot = BootState();
    addTearDown(boot.dispose);
    var calls = 0;
    await boot.initialize(() async {
      calls++;
      throw StateError('login 1990006');
    });
    expect(calls, 1);
    expect(boot.value, isFalse);
    expect(boot.error, isA<StateError>());

    await boot.initialize(() async {
      calls++;
    });
    expect(calls, 2);
    expect(boot.value, isTrue);
    expect(boot.error, isNull);
  });

  test('初始化进行中忽略重复请求', () async {
    final BootState boot = BootState();
    addTearDown(boot.dispose);
    final pending = Completer<void>();
    final first = boot.initialize(() => pending.future);
    var duplicateCalls = 0;
    await boot.initialize(() async {
      duplicateCalls++;
    });
    expect(duplicateCalls, 0);
    pending.complete();
    await first;
    expect(boot.value, isTrue);
  });

  testWidgets('初始化失败显示重试入口，手动重试成功后进入应用', (tester) async {
    final BootState boot = BootState();
    await tester.pumpWidget(BootstrapApp(
      boot: boot,
      app: const _FakeApp(),
      onRetry: () => boot.initialize(() async {}),
    ));
    await boot.initialize(() async {
      throw StateError('基础初始化失败');
    });
    await tester.pump();
    expect(find.text('启动失败，请重试'), findsOneWidget);
    expect(find.byType(_FakeApp), findsNothing);

    await tester.tap(find.text('重试'));
    await tester.pump();
    await _pump(tester, SplashTiming.introDuration + _tick);
    await _pump(tester, SplashTiming.handoffDuration + _tick);
    expect(find.byType(_FakeApp), findsOneWidget);
    expect(find.text('启动失败，请重试'), findsNothing);
  });

  testWidgets('初始化慢于动画：开屏停住等它，回来之后才交接', (WidgetTester tester) async {
    final BootState boot = BootState();
    await tester.pumpWidget(BootstrapApp(boot: boot, app: const _FakeApp()));
    await tester.pump();

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(_FakeApp), findsNothing, reason: '初始化没好之前不该建首屏');

    // 四拍走完（此时 boot 还没 ready）
    await _pump(tester, SplashTiming.introDuration + _tick);
    await tester.pump();
    expect(find.byType(SplashPage), findsOneWidget, reason: '初始化没完成，开屏不许自己走');
    expect(find.byType(_FakeApp), findsNothing);

    // 初始化完成 → 交接
    boot.markReady();
    await tester.pump();
    expect(find.byType(_FakeApp), findsOneWidget);

    await _pump(tester, SplashTiming.handoffDuration + _tick);
    await tester.pump();
    expect(find.byType(SplashPage), findsNothing, reason: '交接结束应当把开屏摘掉');
    expect(find.byType(_FakeApp), findsOneWidget);
  });

  testWidgets('初始化快于动画：开屏照样播完前四拍', (WidgetTester tester) async {
    final BootState boot = BootState()..markReady();
    await tester.pumpWidget(BootstrapApp(boot: boot, app: const _FakeApp()));
    await tester.pump();

    expect(find.byType(_FakeApp), findsOneWidget, reason: '初始化好了就该先把首屏建起来预热');

    // 前四拍只走了一半
    await _pump(tester, SplashTiming.introDuration ~/ 2);
    expect(find.byType(SplashPage), findsOneWidget, reason: '品牌这一拍不该被跳过');

    await _pump(tester, SplashTiming.introDuration);
    await _pump(tester, SplashTiming.handoffDuration + _tick);
    await tester.pump();
    expect(find.byType(SplashPage), findsNothing);
    expect(find.byType(_FakeApp), findsOneWidget);
  });

  testWidgets('交接期间首屏始终是同一个实例（不会被重建、白拉一次数据）', (WidgetTester tester) async {
    final BootState boot = BootState()..markReady();
    await tester.pumpWidget(BootstrapApp(boot: boot, app: const _FakeApp()));
    await tester.pump();

    final Element first = tester.element(find.byType(_FakeApp));
    await _pump(tester, SplashTiming.introDuration + _tick);
    await _pump(tester, SplashTiming.handoffDuration + _tick);
    await tester.pump();

    expect(find.byType(_FakeApp), findsOneWidget);
    expect(identical(tester.element(find.byType(_FakeApp)), first), isTrue);
  });
}
