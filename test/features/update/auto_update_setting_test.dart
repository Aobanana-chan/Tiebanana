import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/core/config/default_config.dart';

void main() {
  const String key = 'checkUpdateAutomaticlly';

  test('新设置默认开启自动检查更新', () {
    expect(APPSetting(fontSize: 16).checkUpdateAutomaticlly, isTrue);
    expect(
        APPSetting.fromJson(defaultAPPSetting).checkUpdateAutomaticlly, isTrue);
  });

  test('旧设置缺少自动检查开关或开关为 null 时默认开启', () {
    final legacy = Map<String, dynamic>.of(defaultAPPSetting)..remove(key);
    expect(APPSetting.fromJson(legacy).checkUpdateAutomaticlly, isTrue);

    legacy[key] = null;
    expect(APPSetting.fromJson(legacy).checkUpdateAutomaticlly, isTrue);
  });

  test('用户明确关闭后，保存并重新读取仍保持关闭', () {
    final setting = APPSetting.fromJson(defaultAPPSetting)
      ..checkUpdateAutomaticlly = false;

    expect(
        APPSetting.fromJson(setting.toJson()).checkUpdateAutomaticlly, isFalse);
  });
}
