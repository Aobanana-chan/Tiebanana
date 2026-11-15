import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/features/update/widgets/update_release_notes.dart';

void main() {
  testWidgets('更新日志按 Markdown 展示并支持选择文本', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UpdateReleaseNotes(notes: '  ## 新功能\n\n- 支持查看更新日志  '),
        ),
      ),
    );

    expect(find.text('更新日志'), findsOneWidget);
    final MarkdownBody markdown =
        tester.widget<MarkdownBody>(find.byType(MarkdownBody));
    expect(markdown.data, '## 新功能\n\n- 支持查看更新日志');
    expect(markdown.selectable, isTrue);
    expect(find.textContaining('支持查看更新日志'), findsOneWidget);
  });

  for (final String notes in <String>['', ' \n\t ']) {
    testWidgets('空日志显示兜底提示 ${notes.length}', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UpdateReleaseNotes(notes: notes)),
        ),
      );

      expect(find.text('此版本暂未提供更新日志，可前往发布页查看。'), findsOneWidget);
      expect(find.byType(MarkdownBody), findsNothing);
    });
  }

  testWidgets('长日志可在弹窗内滚动，不挤出操作按钮', (WidgetTester tester) async {
    final String notes = List<String>.generate(
      50,
      (int index) => '- 更新内容 $index',
    ).join('\n');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlertDialog(
            title: const Text('发现新版本 v1.0.3'),
            content: SizedBox(
              width: double.maxFinite,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: SingleChildScrollView(
                  child: UpdateReleaseNotes(notes: notes),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(onPressed: () {}, child: const Text('前往更新')),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('前往更新').hitTestable(), findsOneWidget);
    final ScrollableState scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
