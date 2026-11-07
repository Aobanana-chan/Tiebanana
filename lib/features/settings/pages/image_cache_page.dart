import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiebanana/core/cache/image_cache_manager.dart';
import 'package:tiebanana/shared/widgets/setting_group.dart';

class ImageCachePage extends StatefulWidget {
  const ImageCachePage({super.key, this.manager});
  final ImageCacheManager? manager;

  @override
  State<ImageCachePage> createState() => _ImageCachePageState();
}

class _ImageCachePageState extends State<ImageCachePage> {
  late final _manager = widget.manager ?? ImageCacheManager.shared;
  final _days = TextEditingController();
  final _size = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _enabled = false;
  bool _byAge = true;
  bool _bySize = true;
  bool _loading = true;
  bool _busy = false;
  int? _bytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _manager.loadPolicy();
      final bytes = await _manager.sizeBytes();
      if (!mounted) return;
      final policy = _manager.policy;
      setState(() {
        _enabled = policy.enabled;
        _byAge = policy.byAge;
        _bySize = policy.bySize;
        _days.text = '${policy.days}';
        _size.text = '${policy.maxMiB}';
        _bytes = bytes;
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = '读取缓存失败，请重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _days.dispose();
    _size.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_enabled && !_byAge && !_bySize) {
      _message('请至少开启一种自动清理规则');
      return;
    }
    setState(() => _busy = true);
    try {
      await _manager.savePolicy(ImageCachePolicy(
        enabled: _enabled,
        byAge: _byAge,
        days: _enabled && _byAge ? int.parse(_days.text) : _manager.policy.days,
        bySize: _bySize,
        maxMiB: _enabled && _bySize
            ? int.parse(_size.text)
            : _manager.policy.maxMiB,
      ));
      final bytes = await _manager.sizeBytes();
      if (!mounted) return;
      setState(() => _bytes = bytes);
      _message('已保存图片缓存设置');
    } catch (_) {
      if (mounted) _message('保存失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理图片缓存？'),
        content: const Text(
            '清理头像、帖子图片和原图缓存。之后查看时会重新下载，不影响账号、收藏和浏览记录。正在显示或下载的图片可能继续占用或重新产生缓存。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('清理')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await _manager.clean(all: true);
      final bytes = await _manager.sizeBytes();
      if (!mounted) return;
      setState(() => _bytes = bytes);
      _message(
          '已清理 ${formatImageCacheSize(result.bytes)}${result.failures > 0 ? '，部分文件清理失败，请重试' : ''}');
    } catch (_) {
      if (mounted) _message('清理失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _number(TextEditingController controller, String label, int max,
          bool enabled) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration:
              InputDecoration(labelText: label, helperText: '可设置 1–$max'),
          validator: (text) {
            if (!enabled) return null;
            final value = int.tryParse(text ?? '');
            return value == null || value < 1 || value > max
                ? '请输入 1–$max 的整数'
                : null;
          },
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('图片缓存')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: TextButton(onPressed: _load, child: Text(_error!)))
                : Form(
                    key: _form,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        SettingGroup(children: [
                          SettingRow(
                            icon: Icons.storage_outlined,
                            title: '当前图片缓存',
                            subtitle: '头像、帖子图片、预览图与原图的磁盘占用',
                            value: _bytes == null
                                ? '计算中'
                                : formatImageCacheSize(_bytes!),
                            onTap: _busy ? null : _load,
                          ),
                          SettingRow(
                            icon: Icons.delete_outline,
                            title: _busy ? '处理中…' : '立即清理',
                            danger: true,
                            onTap: _busy ? null : _clear,
                          ),
                        ]),
                        SettingGroup(children: [
                          SettingRow(
                            icon: Icons.auto_delete_outlined,
                            title: '自动清理',
                            subtitle: '启动、回到前台及前台每 15 分钟检查',
                            trailing: SettingSwitch(
                                value: _enabled,
                                onChanged: _busy
                                    ? null
                                    : (value) =>
                                        setState(() => _enabled = value)),
                          ),
                          SettingRow(
                            icon: Icons.schedule,
                            title: '按时间清理',
                            subtitle: '删除最后下载或更新超过指定天数的缓存',
                            trailing: SettingSwitch(
                                value: _byAge,
                                onChanged: !_enabled || _busy
                                    ? null
                                    : (value) =>
                                        setState(() => _byAge = value)),
                          ),
                          _number(_days, '保留天数（天）', 3650,
                              _enabled && _byAge && !_busy),
                          SettingRow(
                            icon: Icons.data_usage,
                            title: '按大小清理',
                            subtitle: '超过上限时，优先删除最旧的缓存直到低于上限',
                            trailing: SettingSwitch(
                                value: _bySize,
                                onChanged: !_enabled || _busy
                                    ? null
                                    : (value) =>
                                        setState(() => _bySize = value)),
                          ),
                          _number(_size, '容量上限（MiB）', 102400,
                              _enabled && _bySize && !_busy),
                        ]),
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                              '两种规则可以同时开启，先清理过期文件，再检查容量。时间按文件最后写入时间计算，不是上次查看时间。保存后立即检查；应用关闭期间不运行。'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: FilledButton(
                              onPressed: _busy ? null : _save,
                              child: const Text('保存设置')),
                        ),
                      ],
                    ),
                  ),
      );
}
