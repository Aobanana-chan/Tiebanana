import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:tieba_contract/tieba_contract.dart';

/// 本地诊断日志，只记录白名单字段。
class AppLog {
  AppLog({
    this.maxFileBytes = 2 * 1024 * 1024,
    this.maxTotalBytes = 20 * 1024 * 1024,
    this.retention = const Duration(days: 7),
  });

  static final shared = AppLog();
  static const _fields = {
    'phase',
    'durationMs',
    'method',
    'endpoint',
    'requestId',
    'operationId',
    'statusCode',
    'businessCode',
    'errorType',
    'network',
    'state',
    'route',
    'action',
    'version',
    'build',
    'platform',
    'osVersion',
    'model',
    'abis',
    'dropped',
    'source',
    'tid',
    'pid',
    'page',
    'onlyLz',
    'parser',
    'rawType',
  };
  final int maxFileBytes;
  final int maxTotalBytes;
  final Duration retention;
  final String sessionId = const Uuid().v4();
  final List<String> _pending = [];
  Future<void> _tail = Future<void>.value();
  Timer? _timer;
  Directory? _directory;
  File? _current;
  int _bytes = 0;
  int _sequence = 0;
  int _dropped = 0;
  bool _available = false;
  bool _flushScheduled = false;
  final Set<String> _unknownContent = {};

  bool get available => _available;

  Future<void> initialize(Directory directory) async {
    await _serial(() async {
      try {
        await directory.create(recursive: true);
        _directory = directory;
        _current = null;
        _bytes = 0;
        _available = true;
        await _prune();
      } catch (_) {
        _available = false;
      }
    });
    if (_available) await flush();
  }

  /// 只保留异常类型和 Dart 栈帧。
  void error(String event, Object error, StackTrace? stack,
      {Map<String, Object?> data = const {}}) {
    // 已知传输失败、业务拒绝由原有 UI 处理，不属于未处理异常。
    if (!event.startsWith('uncaught.') &&
        (error is DioException ||
            error is NetAPIError ||
            error is TiebaPublishUncertain)) {
      return;
    }
    record(event,
        level: 'error',
        data: {
          ...data,
          'errorType': error.runtimeType.toString(),
        },
        stack: stack);
  }

  void record(String event,
      {String level = 'info',
      Map<String, Object?> data = const {},
      StackTrace? stack,
      Map<String, Object?>? snapshot}) {
    if (level != 'error') return;
    if (!RegExp(r'^[a-z][a-z0-9_.]{0,79}$').hasMatch(event)) return;
    final safe = <String, Object?>{};
    for (final entry in data.entries) {
      if (!_fields.contains(entry.key)) continue;
      final value = entry.value;
      if (value is num && !value.isFinite) continue;
      if (value is num || value is bool || value == null) {
        safe[entry.key] = value;
      } else if (value is String) {
        // 字段值限定为代码生成的标识、枚举和环境信息。
        if (RegExp(r'bduss|stoken|authorization|cookie|password|[?=&\r\n]',
                caseSensitive: false)
            .hasMatch(value)) {
          safe[entry.key] = '<redacted>';
        } else {
          safe[entry.key] = value.substring(0, value.length.clamp(0, 256));
        }
      }
    }
    final frames = stack
        ?.toString()
        .split('\n')
        .where((line) =>
            RegExp(r'^#\d+\s+[\w<>.$ =]+\s+\((?:package:|dart:)[\w./:-]+\)$')
                .hasMatch(line))
        .take(40)
        .toList();
    final line = jsonEncode({
      'schema': 2,
      'time': DateTime.now().toUtc().toIso8601String(),
      'sessionId': sessionId,
      'level': level,
      'event': event,
      'data': safe,
      if (snapshot != null) 'snapshot': _safeStructure(snapshot),
      if (frames != null) 'stack': frames,
    });
    if (_pending.length >= 500) {
      _dropped++;
      return;
    }
    _pending.add('$line\n');
    if (!_available) return;
    if (level == 'error' || _pending.length >= 50) {
      if (!_flushScheduled) {
        _flushScheduled = true;
        unawaited(flush().whenComplete(() {
          _flushScheduled = false;
          if (_available && _pending.isNotEmpty) {
            _timer ??= Timer(const Duration(seconds: 1), () {
              _timer = null;
              unawaited(flush());
            });
          }
        }));
      }
    } else {
      _timer ??= Timer(const Duration(seconds: 1), () {
        _timer = null;
        unawaited(flush());
      });
    }
  }

  /// 协议侧传来的快照已脱敏，这里再次做结构过滤。
  void protocolException(String event, Map<String, Object?> data) {
    if (event != 'parser.unknown_content' &&
        event != 'parser.failed' &&
        event != 'protocol.failed') {
      return;
    }
    Map<String, Object?>? snapshot;
    if (event.startsWith('parser.')) {
      final key =
          '$event:${data['parser']}:${data['rawType']}:${data['tid']}:${data['pid']}';
      if (_unknownContent.contains(key) || _unknownContent.length >= 200) {
        return;
      }
      _unknownContent.add(key);
      snapshot = {
        'structure': _safeStructure(data['snapshot']),
        'stringsRedacted': true
      };
    }
    record(event,
        level: 'error',
        data: data,
        snapshot: snapshot,
        stack: data['stackTrace'] is StackTrace
            ? data['stackTrace'] as StackTrace
            : null);
  }

  static Object? _safeStructure(Object? input, [int depth = 0]) {
    if (depth > 12) return '<truncated>';
    if (input == null || input is bool) return input;
    if (input is num) return input.isFinite ? input : '<non-finite>';
    if (input is String) {
      return RegExp(
                  r'^<(?:redacted(?::length=\d+|:number)?|truncated|non-finite)>$')
              .hasMatch(input)
          ? input
          : '<redacted>';
    }
    if (input is List) {
      return input.take(12).map((v) => _safeStructure(v, depth + 1)).toList();
    }
    if (input is Map) {
      return {
        for (final entry in input.entries.take(32))
          if (entry.key is String &&
              RegExp(r'^[a-zA-Z_][a-zA-Z_0-9]{0,63}$')
                  .hasMatch(entry.key as String))
            entry.key as String:
                RegExp(r'cookie|token|bduss|tbs|auth|password|uid|portrait|user|phone|email|device|cuid|imei',
                            caseSensitive: false)
                        .hasMatch(entry.key as String)
                    ? '<redacted>'
                    : _safeStructure(entry.value, depth + 1),
      };
    }
    return '<redacted>';
  }

  Future<void> _serial(Future<void> Function() work) {
    final next = _tail.then((_) => work());
    // 日志故障不允许递归进入全局错误处理。
    _tail = next.catchError((Object _) {});
    return next;
  }

  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    return _serial(_write);
  }

  Future<void> _write() async {
    if (!_available || _pending.isEmpty) return;
    final lines = List<String>.of(_pending);
    _pending.clear();
    if (_dropped > 0) {
      lines.add('${jsonEncode({
            'schema': 2,
            'time': DateTime.now().toUtc().toIso8601String(),
            'sessionId': sessionId,
            'level': 'warning',
            'event': 'log.dropped',
            'data': {'dropped': _dropped}
          })}\n');
      _dropped = 0;
    }
    try {
      final batch = <int>[];
      Future<void> writeBatch() async {
        if (batch.isEmpty) return;
        await _current!.writeAsBytes(batch, mode: FileMode.append, flush: true);
        batch.clear();
      }

      for (final line in lines) {
        final bytes = utf8.encode(line);
        if (bytes.length > maxFileBytes) {
          _dropped++;
          continue;
        }
        if (_current == null || _bytes + bytes.length > maxFileBytes) {
          await writeBatch();
          _current = File(
              '${_directory!.path}/log-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}.jsonl');
          _bytes = 0;
        }
        batch.addAll(bytes);
        _bytes += bytes.length;
      }
      await writeBatch();
      await _prune();
    } catch (_) {
      _available = false;
    }
  }

  Future<List<File>> _files() async {
    if (_directory == null) return [];
    final files = await _directory!
        .list()
        .where((f) =>
            f is File && RegExp(r'[/\\]log-\d+-\d+\.jsonl$').hasMatch(f.path))
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  Future<void> _prune() async {
    final files = await _files();
    var total = 0;
    final cutoff = DateTime.now().subtract(retention);
    for (final file in files.reversed) {
      final stat = await file.stat();
      if (stat.modified.isBefore(cutoff) || total + stat.size > maxTotalBytes) {
        await file.delete();
        if (file.path == _current?.path) {
          _current = null;
          _bytes = 0;
        }
      } else {
        total += stat.size;
      }
    }
  }

  /// 与写入共用队列，返回稳定的字节快照。
  Future<Map<String, List<int>>> snapshot() async {
    final result = <String, List<int>>{};
    await _serial(() async {
      await _write();
      if (!_available) throw StateError('日志目录不可用');
      await _prune();
      for (final file in await _files()) {
        result[file.uri.pathSegments.last] = await file.readAsBytes();
      }
    });
    if (!_available) throw StateError('日志目录不可用');
    return result;
  }

  Future<int> sizeBytes() async {
    final files = await snapshot();
    return files.values.fold<int>(0, (total, bytes) => total + bytes.length);
  }

  Future<void> clear() => _serial(() async {
        _pending.clear();
        _timer?.cancel();
        _timer = null;
        for (final file in await _files()) {
          await file.delete();
        }
        _current = null;
        _bytes = 0;
        _dropped = 0;
        _unknownContent.clear();
      });
}
