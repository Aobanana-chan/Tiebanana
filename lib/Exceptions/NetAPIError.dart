import 'package:tiebanana/Exceptions/Exception.dart';

///处理网络API错误
class NetAPIErrorHandle implements TiebananaErrorHandler {
  @override
  void process(Object error) async {
    NetAPIError e = error as NetAPIError;
    for (var i = 0; i < e.redoTimes; i++) {
      try {
        if (e.redoTimes > 0) {
          await e.redoFunction?.call();
          return;
        }
      } catch (_) {}
    }
  }

  @override
  List<Object> types = [NetAPIError];
}

///异常类型
class NetAPIError implements Exception {
  final NetAPIErrorType type;
  final int redoTimes;
  Function? redoFunction;
  String? errorMessage;
  NetAPIError(
      {required this.type,
      required this.redoTimes,
      this.redoFunction,
      this.errorMessage});
}

enum NetAPIErrorType { initFailed, actionFalied }
