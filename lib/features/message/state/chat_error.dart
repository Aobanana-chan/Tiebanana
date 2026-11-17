import 'dart:async';
import 'dart:io';

import 'package:tieba_contract/tieba_contract.dart';

/// 不直接显示原始异常，避免握手凭证或消息正文进入界面/截图。
String chatErrorBody(Object? error) {
  if (error is TimeoutException) {
    return '私信连接或同步超时，请检查网络和代理后重试';
  }
  if (error is WebSocketException) {
    final int? status = error.httpStatusCode;
    return status == null
        ? '私信 WebSocket 握手失败，请检查网络和代理配置'
        : '私信 WebSocket 握手失败（HTTP $status），请检查网络和代理配置';
  }
  if (error is SocketException && error.message == '私信连接已关闭') {
    return '私信连接已建立，但在登录或同步完成前断开，请重试';
  }
  if (error is SocketException || error is HttpException) {
    return '无法连接私信服务器，请检查网络和代理配置';
  }
  if (error is NetAPIError) {
    return '私信账号校验或同步失败，请重试；持续失败时请重新登录';
  }
  return '私信初始化或数据处理失败，请重试；持续失败时请导出诊断日志';
}
