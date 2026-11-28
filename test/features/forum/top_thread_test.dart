import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/features/forum/widgets/top_thread.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

void main() {
  testWidgets('宽屏下置顶帖悬停时使用主题色高亮，不增加阴影', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final theme = TiebananaTheme.light(seedOf('blue'), 16);
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: const Scaffold(body: TopThread(tid: '1', title: '置顶帖标题')),
    ));

    final button = find.byType(MaterialButton);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(button));
    await tester.pumpAndSettle();

    final material =
        find.descendant(of: button, matching: find.byType(Material));
    expect(tester.widget<Material>(material).elevation, 0);
    final inkWell = find.descendant(of: button, matching: find.byType(InkWell));
    expect(tester.widget<InkWell>(inkWell).hoverColor,
        theme.colorScheme.primary.withValues(alpha: .04));

    await mouse.removePointer();
  });
}
