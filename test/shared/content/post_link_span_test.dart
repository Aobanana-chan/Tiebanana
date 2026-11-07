import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/shared/content/post_link_span.dart';

void main() {
  for (final scale in [1.0, 1.5]) {
    testWidgets('链接图标同色、随字号缩放且可点击 $scale', (tester) async {
      var taps = 0;
      final recognizer = TapGestureRecognizer()..onTap = () => taps++;
      addTearDown(recognizer.dispose);
      late TextSpan span;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: Builder(builder: (context) {
            span = prependLinkIcon(
                context,
                TextSpan(
                    text: '查看链接',
                    style: const TextStyle(color: Colors.blue, fontSize: 16),
                    recognizer: recognizer),
                fontSize: 16);
            return Text.rich(span);
          })),
        ),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.link_rounded));
      expect(icon.color, Colors.blue);
      expect(icon.size, closeTo(16 * scale * 0.9, 0.001));
      expect(span.toPlainText(includePlaceholders: false), '查看链接');
      await tester.tap(find.byIcon(Icons.link_rounded));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
