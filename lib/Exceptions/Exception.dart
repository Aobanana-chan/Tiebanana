import 'package:tiebanana/Exceptions/NetAPIError.dart';

///TODO:异常处理和上报

class TiebananaErrorProcesser {
  Map<Object, List<TiebananaErrorHandler>> handlers = {};

  //单列模式
  static final TiebananaErrorProcesser _instance =
      TiebananaErrorProcesser.init();
  factory TiebananaErrorProcesser() {
    return _instance;
  }
  TiebananaErrorProcesser.init() {
    // var nativeErrorProcess = FlutterError.onError;
    // FlutterError.onError = ((details) {
    //   for (TiebananaErrorHandler handler in handlers[details.exception] ?? []) {
    //     handler.process(details);
    //   }
    //   nativeErrorProcess?.call(details);
    // });

    regist(NetAPIErrorHandle());
  }

  ///注册异常处理
  void regist(TiebananaErrorHandler handler) {
    for (var ept in handler.types) {
      if (handlers[ept] == null) {
        handlers[ept] = [];
        handlers[ept]?.add(handler);
      } else {
        handlers[ept]?.add(handler);
      }
    }
  }

  ///处理异常
  void handle(Object error) {
    for (TiebananaErrorHandler handler in handlers[error.runtimeType] ?? []) {
      handler.process(error);
    }
  }
}

abstract class TiebananaErrorHandler {
  ///注册生效的异常
  late List<Object> types;

  ///异常处理
  void process(Object error);
}
