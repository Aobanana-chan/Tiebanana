import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/features/account/state/login_failure.dart';
import 'package:tiebanana/features/account/widgets/login_failure_prompt.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    LoginFailureController controller,
    Future<void> Function() onRelogin,
  ) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      builder: (context, child) => LoginFailurePrompt(
        controller: controller,
        navigatorKey: key,
        onRelogin: onRelogin,
        child: child!,
      ),
      home: const Scaffold(body: Text('首页')),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('启动前的登录错误在界面就绪后弹窗，取消后不重复提示', (tester) async {
    final controller = LoginFailureController();
    addTearDown(controller.dispose);
    controller.report(1990006, '请手动完成登录');
    var calls = 0;
    await mount(tester, controller, () async {
      calls++;
    });
    expect(find.text('登录失败'), findsOneWidget);
    expect(find.textContaining('1990006'), findsOneWidget);
    await tester.tap(find.text('暂不登录'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    controller.report(1990006, '请手动完成登录');
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('选择重新登录触发登录入口，新会话失败仍可提示', (tester) async {
    final controller = LoginFailureController();
    addTearDown(controller.dispose);
    controller.report(1990006, '请手动完成登录');
    var calls = 0;
    await mount(tester, controller, () async {
      calls++;
    });
    await tester.tap(find.text('重新登录'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byType(AlertDialog), findsNothing);
    controller.reset();
    controller.report(1990006, '新会话登录失败');
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
