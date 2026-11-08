import 'package:flutter/material.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:tiebanana/core/diagnostics/diagnostics.dart';

/// 启动失败时也可打开的诊断页。
class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key, this.onExport, this.onShare});

  /// 可注入系统操作，便于 widget 测试。
  final Future<Uri?> Function()? onExport;
  final Future<void> Function(Rect origin)? onShare;
  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  int? _bytes;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final bytes = await AppLog.shared.sizeBytes();
      if (mounted) setState(() => _bytes = bytes);
    } catch (_) {
      if (mounted) setState(() => _message = '日志存储不可用，请检查剩余空间后重启应用。');
    }
  }

  Future<void> _run(Future<void> Function() work) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await work();
    } catch (error, stack) {
      AppLog.shared.error('log.action_failed', error, stack);
      if (mounted) setState(() => _message = '操作失败，请检查存储空间或稍后重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('日志与诊断')),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          const Text(
              '点击「导出诊断包」选择保存位置保存 ZIP，或点击「分享诊断包」通过系统分享面板发送。诊断包仅包含脱敏的异常记录，不包含凭证等敏感数据。'),
          const SizedBox(height: 12),
          Text(_bytes == null
              ? '正在读取日志大小…'
              : '日志占用：${(_bytes! / 1024).toStringAsFixed(1)} KB'),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.save_alt),
            label: const Text('导出诊断包'),
            onPressed: _busy
                ? null
                : () => _run(() async {
                      final saved = await (widget.onExport ??
                          Diagnostics.shared.saveToExternal)();
                      if (mounted) {
                        setState(() => _message = saved == null
                            ? '已取消导出'
                            : '诊断包已保存到所选位置，可在系统文件管理器中查看。');
                      }
                    }),
          ),
          const SizedBox(height: 12),
          Builder(
              builder: (buttonContext) => OutlinedButton.icon(
                    icon: const Icon(Icons.ios_share),
                    label: const Text('分享诊断包'),
                    onPressed: _busy
                        ? null
                        : () {
                            final box =
                                buttonContext.findRenderObject()! as RenderBox;
                            final origin =
                                box.localToGlobal(Offset.zero) & box.size;
                            _run(() => (widget.onShare ??
                                Diagnostics.shared.share)(origin));
                          },
                  )),
          TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: const Text('清空本地日志？'),
                                content:
                                    const Text('清空后将无法导出此前的问题记录，已分享的诊断包不受影响。'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('取消')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('清空')),
                                ],
                              ));
                      if (confirmed == true && mounted) {
                        await _run(() async {
                          await AppLog.shared.clear();
                          await _refresh();
                        });
                      }
                    },
              child: const Text('清空日志')),
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_message != null) Text(_message!),
        ]),
      );
}
