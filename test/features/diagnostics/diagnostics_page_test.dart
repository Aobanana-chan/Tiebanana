import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/features/diagnostics/pages/diagnostics_page.dart';
import 'package:tiebanana/app/bootstrap.dart';

void main() {
  testWidgets('诊断页不依赖 Global，显示导出和清空确认', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DiagnosticsPage()));
    await tester.pumpAndSettle();
    expect(find.text('导出诊断包'), findsOneWidget);
    expect(find.text('分享诊断包'), findsOneWidget);
    await tester.tap(find.text('清空日志'));
    await tester.pumpAndSettle();
    expect(find.text('清空本地日志？'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('清空本地日志？'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('导出与分享独立，取消导出不触发分享', (tester) async {
    var exports = 0;
    var shares = 0;
    await tester.pumpWidget(MaterialApp(
        home: DiagnosticsPage(
      onExport: () async {
        exports++;
        return null;
      },
      onShare: (origin) async {
        shares++;
        expect(origin.width, greaterThan(0));
      },
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('导出诊断包'));
    await tester.pumpAndSettle();
    expect(exports, 1);
    expect(shares, 0);
    expect(find.text('已取消导出'), findsOneWidget);
    await tester.ensureVisible(find.text('分享诊断包'));
    await tester.tap(find.text('分享诊断包'));
    await tester.pumpAndSettle();
    expect(exports, 1);
    expect(shares, 1);
  });

  testWidgets('启动失败能打开诊断页', (tester) async {
    final boot = BootState();
    await tester.pumpWidget(BootstrapApp(boot: boot, app: const SizedBox()));
    await boot.initialize(() async => throw StateError('test'));
    await tester.pump();
    await tester.tap(find.text('导出诊断日志'));
    await tester.pumpAndSettle();
    expect(find.byType(DiagnosticsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    boot.dispose();
  });
}
