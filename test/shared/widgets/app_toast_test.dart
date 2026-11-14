import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/shared/widgets/app_toast.dart';

void main() {
  testWidgets('Windows 提示使用应用内消息，无原生 Toast 通道', (tester) async {
    await tester.pumpWidget(MaterialApp(
      scaffoldMessengerKey: Fluttertoast.messengerKey,
      home: const Scaffold(body: Text('首页')),
    ));
    await Fluttertoast.showToast(msg: '保存成功');
    await tester.pump();
    expect(find.text('保存成功'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
