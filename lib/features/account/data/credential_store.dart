/// 宿主提供的凭证/设备指纹存储实现（注入给后端实现）。
///
/// 后端的持久化只依赖契约的 [KeyValueStore] 抽象；Flutter 侧用
/// SharedPreferences 实现。
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';

/// 基于 SharedPreferences 的 [KeyValueStore]（设备指纹 cuid/BAIDUID 等持久化）。
class SharedPreferencesKeyValueStore implements KeyValueStore {
  final SharedPreferences prefs;

  SharedPreferencesKeyValueStore(this.prefs);

  @override
  String? getString(String key) => prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      prefs.setString(key, value);
}
