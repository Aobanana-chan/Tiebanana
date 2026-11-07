import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:dio/dio.dart';
import 'package:tieba_contract/tieba_contract.dart';

void main() {
  late Directory directory;
  late AppLog log;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('tiebanana-log-test-');
    log = AppLog();
  });
  tearDown(() async {
    await log.flush();
    await directory.delete(recursive: true);
  });

  test('已处理网络/业务失败不记录，未捕获异常仍记录', () async {
    await log.initialize(directory);
    final error = DioException(requestOptions: RequestOptions(path: '/'), type: DioExceptionType.connectionTimeout);
    log.error('sign.failed', error, null);
    log.error('publish.reply_failed', NetAPIError(type: NetAPIErrorType.actionFalied, redoTimes: 0, errorMessage: 'secret'), null);
    expect(await log.snapshot(), isEmpty);
    log.error('uncaught.zone', error, null);
    expect((await log.snapshot()).length, 1);
  });

  test('早期日志、并发写入、重启后的记录均可导出', () async {
    log.record('test.early_failed', level: 'error');
    await log.initialize(directory);
    await Future.wait(List.generate(50, (i) async {
      log.record('test.failed', level: 'error', data: {'requestId': '$i'});
      await log.flush();
    }));
    final first = await log.snapshot();
    expect(first.values.expand((b) => utf8.decode(b).trim().split('\n')).length,
        51);
    final restarted = AppLog();
    await restarted.initialize(directory);
    final snapshot = await restarted.snapshot();
    expect(snapshot.keys, first.keys);
  });

  test('凭证、正文、查询参数、异常文本和本机路径不进入日志', () async {
    await log.initialize(directory);
    log.record('test.failed', level: 'error', data: {
      'body': 'private post',
      'BDUSS': 'secret',
      'endpoint': 'host/path?BDUSS=secret',
      'method': 'GET',
    });
    log.error(
        'test.failed',
        StateError('STOKEN=secret private post'),
        StackTrace.fromString('#0      foo (package:tiebanana/main.dart:12:3)\n'
            '#1      local (file:///C:/Users/private/main.dart:2:3)\n'
            'Cookie: secret'));
    log.record('private user content');
    final text = (await log.snapshot()).values.map(utf8.decode).join();
    expect(text, isNot(contains('secret')));
    expect(text, isNot(contains('private')));
    expect(text, isNot(contains('BDUSS')));
    expect(text, contains('package:tiebanana/main.dart:12:3'));
    expect(text, contains('StateError'));
    expect(text, contains('<redacted>'));
  });

  test('文件轮转和总量上限', () async {
    log = AppLog(maxFileBytes: 400, maxTotalBytes: 1000);
    await log.initialize(directory);
    for (var i = 0; i < 30; i++) {
      log.record('test.failed', level: 'error', data: {'requestId': '$i'});
    }
    final snapshot = await log.snapshot();
    expect(snapshot.length, greaterThan(1));
    expect(snapshot.values.every((b) => b.length <= 400), isTrue);
    expect(snapshot.values.fold<int>(0, (sum, b) => sum + b.length),
        lessThanOrEqualTo(1000));
    for (final bytes in snapshot.values) {
      for (final line in utf8.decode(bytes).trim().split('\n')) {
        expect(jsonDecode(line), isA<Map>());
      }
    }
  });

  test('过期日志删除，但不会删除其他文件', () async {
    final old = File('${directory.path}/log-100-0.jsonl');
    await old.writeAsString('old');
    await old.setLastModified(DateTime.now().subtract(const Duration(days: 8)));
    final unrelated = File('${directory.path}/cookies');
    await unrelated.writeAsString('untouched');
    await log.initialize(directory);
    expect(await old.exists(), isFalse);
    await log.clear();
    expect(await unrelated.readAsString(), 'untouched');
  });

  test('目录不可用不影响调用方，导出明确失败', () async {
    final file = File('${directory.path}/not-a-directory');
    await file.writeAsString('x');
    await log.initialize(Directory(file.path));
    log.error('test.failed', StateError('ignored'), StackTrace.current);
    await log.flush();
    expect(log.available, isFalse);
    await expectLater(log.snapshot(), throwsStateError);
  });

  test('写入中目录失效不向业务传播，重新初始化可恢复', () async {
    await log.initialize(directory);
    await directory.delete();
    log.record('test.failed', level: 'error');
    await log.flush();
    expect(log.available, isFalse);
    await log.initialize(directory);
    log.record('test.recovered', level: 'error');
    final text = (await log.snapshot()).values.map(utf8.decode).join();
    expect(text, contains('test.recovered'));
  });

  test('初始化前队列有界并记录丢弃数量，清空后无旧记录', () async {
    for (var i = 0; i < 600; i++) {
      log.record('test.failed', level: 'error');
    }
    await log.initialize(directory);
    final text = (await log.snapshot()).values.map(utf8.decode).join();
    expect(text, contains('"dropped":100'));
    await log.clear();
    expect(await log.snapshot(), isEmpty);
  });

  test('正常事件不写入；未知内容去重并附脱敏结构和定位', () async {
    await log.initialize(directory);
    log.record('network.complete');
    log.record('startup.ready');
    log.record('network.failed', level: 'warning');
    expect(await log.snapshot(), isEmpty);
    final data = <String, Object?>{
      'tid': '123',
      'pid': '456',
      'rawType': 999,
      'parser': 'PbContent',
      'snapshot': {'text': 'secret', 'token': 'secret', 'type': 999},
    };
    log.protocolException('parser.unknown_content', data);
    log.protocolException('parser.unknown_content', data);
    log.protocolException('network.complete', data);
    final rows = (await log.snapshot())
        .values
        .expand((b) => utf8.decode(b).trim().split('\n'))
        .toList();
    expect(rows.length, 1);
    expect(rows.single, isNot(contains('secret')));
    expect(rows.single, contains('999'));
    expect(rows.single, contains('"tid":"123"'));
    expect(jsonDecode(rows.single)['snapshot'], isA<Map>());
  });
}
