import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/Exceptions/Exception.dart';

///处理网络API错误
class NetAPIErrorHandle implements TiebananaErrorHandler {
  @override
  void process(FlutterErrorDetails details) {
    var e = details.exception as NetAPIError;
    switch (e.type) {
      case NetAPIErrorType.initFailed:
        try {
          e.redoFunction?.call();
        } catch (e) {
          throw NetAPIError(type: NetAPIErrorType.initFailed, needRedo: true);
        }
        break;
      default:
    }
  }

  @override
  List<Object> types = [DioError];
}

///异常类型
class NetAPIError implements Exception {
  late NetAPIErrorType type;
  late bool needRedo;
  Function? redoFunction;
  NetAPIError({required this.type, required this.needRedo, this.redoFunction});
}

enum NetAPIErrorType { initFailed }
