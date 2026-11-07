/// tieba_backend_demo：Tiebanana 的默认后端装配点。
///
/// 应用只依赖 [createTiebaApi] 这一个入口；本地演示数据与可交互的内存实现
/// 位于 `package:tieba_contract/testing.dart`，由本包和界面测试共用。
///
/// 私有构建通过 `pubspec_overrides.yaml` 把本包地址换成
/// `tool/private/tieba_backend_demo`，应用源码和测试都不受影响。
library;

import 'package:tieba_contract/testing.dart';
import 'package:tieba_contract/tieba_contract.dart';

// 与真实后端保持同一套装配签名；演示实现只使用 [TiebaApiHost] 里的
// 提示 / 签到进度回调，其余协议开关会被忽略。
typedef DemoDiagnosticCallback = void Function(
    String event, Map<String, Object?> data);

/// 构造默认演示后端。
TiebaApi createTiebaApi({
  required TiebaApiHost host,
  required bool Function() signUpperHex,
  required bool Function() enableSig,
  String? debugProxy,
  int? accountUid,
  void Function(int code, String message)? onLoginFailure,
  DemoDiagnosticCallback? onDiagnostic,
}) {
  return DemoTiebaApi(host: host);
}
