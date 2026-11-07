import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';

class _RejectedLoginApi extends DemoTiebaApi {
  int calls = 0;

  @override
  bool get isLogin => true;

  @override
  Future<MyUserData> getMyInfo() async {
    calls++;
    throw NetAPIError(
      type: NetAPIErrorType.actionFalied,
      redoTimes: 0,
      errorMessage: '1990006 请手动完成登录',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('启动账号刷新被拒绝时不重试、不清除本地账号，也不阻止后续初始化', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'uid': '123'});
    Global.profile = await SharedPreferences.getInstance();
    final api = _RejectedLoginApi();
    Global.tiebaAPI = api;

    await Global.refreshLoggedInUser();

    expect(api.calls, 1);
    expect(Global.profile.getString('uid'), '123');
    expect(api.isLogin, isTrue);
  });
}
