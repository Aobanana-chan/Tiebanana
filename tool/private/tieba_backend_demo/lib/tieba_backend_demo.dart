/// 私有构建使用的 `tieba_backend_demo` 替代包。
///
/// 包名必须与公开演示包一致，`pubspec_overrides.yaml` 才能在不改应用源码的
/// 情况下把依赖地址切换到这里。应用只依赖 `createTiebaApi` 这一个入口。
library;

import 'package:headless_tieba/headless_tieba.dart';

typedef DemoDiagnosticCallback = void Function(
    String event, Map<String, Object?> data);

/// 构造真实贴吧协议后端。
TiebaApi createTiebaApi({
  required TiebaApiHost host,
  required bool Function() signUpperHex,
  required bool Function() enableSig,
  String? debugProxy,
  int? accountUid,
  void Function(int code, String message)? onLoginFailure,
  DemoDiagnosticCallback? onDiagnostic,
}) {
  return HeadlessTiebaApi(HeadlessOptions(
    host: host,
    signUpperHex: signUpperHex,
    enableSig: enableSig,
    debugProxy: debugProxy,
    accountUid: accountUid,
    onLoginFailure: onLoginFailure,
    onDiagnostic: onDiagnostic,
  ));
}
