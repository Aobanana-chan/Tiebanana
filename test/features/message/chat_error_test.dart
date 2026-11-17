import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/features/message/state/chat_error.dart';

void main() {
  test('区分握手、超时、连接和程序错误，不显示原始异常内容', () {
    expect(chatErrorBody(TimeoutException('secret')), contains('超时'));
    expect(
        chatErrorBody(WebSocketException('secret', 403)), contains('HTTP 403'));
    expect(chatErrorBody(const SocketException('secret')), contains('无法连接'));
    expect(chatErrorBody(const SocketException('私信连接已关闭')), contains('完成前断开'));
    expect(chatErrorBody(StateError('secret')), contains('初始化或数据处理失败'));
    expect(chatErrorBody(StateError('secret')), isNot(contains('secret')));
  });
}
