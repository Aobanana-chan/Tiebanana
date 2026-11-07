import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/features/forum/services/auto_sign.dart';
import 'package:tiebanana/app/global.dart';

class _SignApi extends DemoTiebaApi {
  _SignApi({this.reject = false});

  final bool reject;
  int calls = 0;

  @override
  Future<void> signAll() async {
    calls++;
    if (reject) {
      throw NetAPIError(
        type: NetAPIErrorType.actionFalied,
        redoTimes: 0,
        errorMessage: '无法获取用户ID',
      );
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
  });

  test('自动签到失败被处理，只请求一次且不标记当天已签到', () async {
    final api = _SignApi(reject: true);
    Global.tiebaAPI = api;
    final messages = <String>[];

    final result = await AutoSign(onMessage: messages.add).runSign();

    expect(result, isFalse);
    expect(api.calls, 1);
    expect(Global.profile.getInt('latestAutoSigned'), isNull);
    expect(messages.single, contains('自动签到失败'));
  });

  test('自动签到成功后才记录当天已签到', () async {
    Global.tiebaAPI = _SignApi();
    final messages = <String>[];
    expect(await AutoSign(onMessage: messages.add).runSign(), isTrue);
    expect(Global.profile.getInt('latestAutoSigned'), isNotNull);
    expect(messages, isEmpty);
  });

  testWidgets('自动签到失败不触发依赖 ForumState 的首页刷新', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    final callback = SignRefresh(Future<bool>.value(false));
    callback.onHomeFormPageCreate(context);
    await tester.pump();
    expect(callback.done, isTrue);
    expect(tester.takeException(), isNull);
  });
}
