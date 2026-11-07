import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/core/config/default_config.dart';

void main() {
  test('旧设置缺少首页历史数量时默认 15 条', () {
    final json = Map<String, dynamic>.of(defaultAPPSetting)
      ..remove('homeHistoryMaxCount');
    expect(APPSetting.fromJson(json).homeHistoryMaxCountSafe, 15);
  });

  test('首页历史数量可序列化，越界取安全值', () {
    final setting = APPSetting.fromJson(defaultAPPSetting)
      ..homeHistoryMaxCount = 25;
    expect(APPSetting.fromJson(setting.toJson()).homeHistoryMaxCountSafe, 25);
    setting.homeHistoryMaxCount = -1;
    expect(setting.homeHistoryMaxCountSafe, 1);
    setting.homeHistoryMaxCount = 100;
    expect(setting.homeHistoryMaxCountSafe, 50);
    setting.homeHistoryMaxCount = null;
    expect(setting.homeHistoryMaxCountSafe, 15);
  });
}
