import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/features/media/pages/image_picker_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key, required this.target});
  final TiebaReportTarget target;
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportImage {
  _ReportImage(this.asset);
  final AssetEntity asset;
  String? url;
}

class _ReportPageState extends State<ReportPage> {
  final _api = Global.tiebaAPI;
  final _account = AccountStore.currentUid;
  final _detail = TextEditingController();
  final _images = <_ReportImage>[];
  final _threads = <String>{};
  TiebaReportForm? _form;
  TiebaReportReason? _reason;
  DateTime? _date;
  String? _error;
  bool _loading = true, _busy = false, _success = false, _uncertain = false;
  bool _dirty = false, _allowPop = false;
  bool _verificationRequired = false;
  bool get _sameAccount =>
      identical(_api, Global.tiebaAPI) && _account == AccountStore.currentUid;
  TiebaReportInput get _input => TiebaReportInput(
      reason: _reason!,
      detail: _detail.text,
      imageUrls:
          _images.where((i) => i.url != null).map((i) => i.url!).toList(),
      threadIds: _threads.toList(),
      replyDate: _date);
  bool get _valid =>
      _reason != null &&
      TiebaReportInput(
              reason: _reason!,
              detail: _detail.text,
              imageUrls: List.filled(_images.length, 'pending'),
              threadIds: _threads.toList(),
              replyDate: _date)
          .isValid;
  @override
  void initState() {
    super.initState();
    _detail.addListener(_changed);
    _load();
  }

  void _changed() {
    setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!_sameAccount) throw StateError('账号已切换，请重新打开举报');
      final form = await _api.getReportForm(widget.target);
      if (!mounted) return;
      if (!_sameAccount) throw StateError('账号已切换，请重新打开举报');
      if (form.groups.isEmpty) throw StateError('官方暂未提供可用举报原因');
      setState(() => _form = form);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _leave() async {
    if (_busy) return;
    final leave = !_dirty ||
        _success ||
        await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                        title: const Text('放弃这次举报？'),
                        content: const Text('离开后将丢失已填写的内容。'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('继续填写')),
                          FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('离开'))
                        ])) ==
            true;
    if (leave && mounted) {
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> _pickImages() async {
    final result = await Navigator.push<List<dynamic>>(
        context, appPageRoute(builder: (_) => const ImagePickerRoute()));
    if (!mounted || result == null) return;
    final assets = result[0] as Set<AssetEntity>;
    if (assets.length + _images.length > 4) {
      _message('最多添加 4 张图片，请重新选择');
      return;
    }
    setState(() {
      _images.addAll(assets.map(_ReportImage.new));
      _dirty = true;
    });
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _submit() async {
    if (_busy || !_valid || _uncertain || _verificationRequired) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_sameAccount) throw StateError('账号已切换，请重新打开举报');
      if (_reason!.fields.any((f) => f.component == 'select-images')) {
        for (final image in _images) {
          if (!mounted) return;
          if (image.url != null) continue;
          final file = await image.asset.file;
          if (file == null) throw StateError('无法读取图片，请重新选择');
          if (!_sameAccount) throw StateError('账号已切换，请重新打开举报');
          final uploaded = await _api.uploadPicture(
              '',
              true,
              UploadFile(
                  path: file.path,
                  width: image.asset.width,
                  height: image.asset.height,
                  resourceId: image.asset.id));
          final url = Uri.tryParse(uploaded.url ?? '');
          if (url == null || !const ['https', 'http'].contains(url.scheme)) {
            throw StateError('图片上传未返回有效地址');
          }
          image.url = url.toString();
        }
      }
      if (!_sameAccount) throw StateError('账号已切换，请重新打开举报');
      if (!mounted) return;
      await _api.submitReport(_form!, _input);
      if (!mounted) return;
      if (!_sameAccount) throw StateError('账号已切换，请在原账号下查看举报结果');
      setState(() {
        _success = true;
        _dirty = false;
      });
    } on TiebaReportVerification catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _verificationRequired = true;
        });
      }
    } on TiebaModerationUncertain catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _uncertain = true;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selectThreads() async {
    try {
      final threads = await _api.getReportThreads(_form!.portrait);
      if (!mounted) return;
      if (!_sameAccount) throw StateError('账号已切换');
      final selected = {..._threads};
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
              builder: (context, update) => AlertDialog(
                      title: const Text('选择违规主题帖'),
                      content: SizedBox(
                          width: 360,
                          child: SingleChildScrollView(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                 const Text('显示最近可选择的主题帖。'),
                                if (threads.isEmpty)
                                  const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Text('暂无可选择的主题帖')),
                                for (final thread in threads)
                                  CheckboxListTile(
                                      title: Text(thread.title),
                                      value: selected.contains(thread.id),
                                      onChanged: (value) => update(() {
                                            if (value!) {
                                              selected.add(thread.id);
                                            } else {
                                              selected.remove(thread.id);
                                            }
                                          })),
                              ]))),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消')),
                        FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('确认'))
                      ])));
      if (confirmed == true && mounted) {
        setState(() {
          _threads
            ..clear()
            ..addAll(selected);
          _dirty = true;
        });
      }
    } catch (error) {
      if (mounted) _message('$error');
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _date ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now());
    if (date != null && mounted) {
      setState(() {
        _date = date;
        _dirty = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TiebananaTokens.of(context);
    return PopScope(
        canPop: _allowPop || (!_dirty && !_busy),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: Scaffold(
          backgroundColor: tokens.bg,
          appBar: AppBar(
              title: Text('举报${widget.target.label}'),
              leading: IconButton(
                  onPressed: _busy ? null : _leave,
                  icon: const Icon(Icons.arrow_back))),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _form == null
                  ? Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(_error ?? '无法加载举报'),
                            const SizedBox(height: 12),
                            FilledButton(
                                onPressed: _load, child: const Text('重试'))
                          ])))
                  : _success
                      ? _result()
                      : ListView(
                          padding:
                              const EdgeInsets.all(TiebananaMetrics.pageGutter),
                          children: [
                              _targetCard(),
                              for (final group in _form!.groups) ...[
                                _heading(group.title, '单选'),
                                LayoutBuilder(builder: (context, constraints) {
                                  const columns = 2;
                                  return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final reason in group.reasons)
                                          SizedBox(
                                              width: (constraints.maxWidth -
                                                      8 * (columns - 1)) /
                                                  columns,
                                              child: ChoiceChip(
                                                  showCheckmark: false,
                                                  label: SizedBox(
                                                      width: double.infinity,
                                                      child: Text(reason.title,
                                                          textAlign:
                                                              TextAlign.center,
                                                          softWrap: true)),
                                                  selected: identical(
                                                      _reason, reason),
                                                  onSelected: _busy
                                                      ? null
                                                      : (_) => setState(() {
                                                            _reason = reason;
                                                            _dirty = true;
                                                          }))),
                                      ]);
                                }),
                              ],
                              for (final field in _reason?.fields ??
                                  <TiebaReportField>[]) ...[
                                _heading(
                                    field.title, field.required ? '必填' : '选填'),
                                if (field.tips.isNotEmpty)
                                  Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                          color: tokens.fill,
                                          borderRadius: TiebananaMetrics.brMd),
                                      child: Text(field.tips.join('\n'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall)),
                                _field(field),
                              ],
                              const SizedBox(height: 20),
                              Text('请基于事实反馈，勿重复或恶意举报。举报原因及所需材料由官方提供。',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: tokens.textSecondary)),
                              if (_error != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Text(_error!,
                                        style:
                                            TextStyle(color: tokens.danger))),
                              const SizedBox(height: 16),
                            ]),
          bottomNavigationBar: _form == null || _success
              ? null
              : SafeArea(
                  top: false,
                  child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      color: tokens.surface,
                      child: FilledButton(
                          onPressed: !_valid ||
                                  _busy ||
                                  _uncertain ||
                                   _verificationRequired
                              ? null
                              : _submit,
                          child: Text(_busy ? '正在提交，请勿重复操作…' : '提交举报')))),
        ));
  }

  Widget _heading(String title, String suffix) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
        Text(suffix, style: Theme.of(context).textTheme.bodySmall)
      ]));
  Widget _targetCard() => Card(
      margin: EdgeInsets.zero,
      child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.flag_outlined),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(widget.target.name.isEmpty
                      ? '举报${widget.target.label}'
                      : widget.target.name)),
              Text(widget.target.label,
                  style: Theme.of(context).textTheme.labelSmall)
            ]),
            if (widget.target.summary.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(widget.target.summary,
                      maxLines: 3, overflow: TextOverflow.ellipsis)),
            if (widget.target.source.isNotEmpty)
              Text(widget.target.source,
                  style: Theme.of(context).textTheme.bodySmall),
          ])));
  Widget _field(TiebaReportField field) {
    switch (field.component) {
      case 'content-input':
        return TextField(
            controller: _detail,
            enabled: !_busy,
            minLines: 3,
            maxLines: 6,
            maxLength: 200,
            decoration: const InputDecoration(
                hintText: '提供更多信息，有助于准确处理举报', border: OutlineInputBorder()));
      case 'select-images':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final image in _images)
              SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(children: [
                    Positioned.fill(
                        child: FutureBuilder<File?>(
                            future: image.asset.file,
                            builder: (context, snapshot) =>
                                snapshot.data == null
                                    ? const Icon(Icons.image_outlined)
                                    : Image.file(snapshot.data!,
                                        fit: BoxFit.cover))),
                    Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton.filledTonal(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                      _images.remove(image);
                                      _dirty = true;
                                    }),
                            icon: const Icon(Icons.close, size: 16),
                            constraints: const BoxConstraints.tightFor(
                                width: 28, height: 28),
                            padding: EdgeInsets.zero))
                  ])),
            if (_images.length < 4)
              SizedBox(
                  width: 76,
                  height: 76,
                  child: OutlinedButton(
                      onPressed: _busy ? null : _pickImages,
                      child: const Icon(Icons.add))),
          ]),
          const SizedBox(height: 8),
          Text('${_images.length} / 4 张 · 提交时上传所需材料',
              style: Theme.of(context).textTheme.bodySmall),
        ]);
      case 'select-content':
        return Card(
            margin: EdgeInsets.zero,
            child: Column(children: [
              const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('至少添加一项，帮助定位该用户的违规行为')),
              ListTile(
                  title: const Text('主题帖'),
                  subtitle: Text(_threads.isEmpty
                      ? '选择涉嫌违规的主题帖'
                      : '已选择 ${_threads.length} 条'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _busy ? null : _selectThreads),
              ListTile(
                  title: const Text('回复帖'),
                  subtitle: Text(_date == null
                      ? '选择回复的发布日期'
                      : '${_date!.year}-${_date!.month}-${_date!.day}'),
                  trailing: _date == null
                      ? const Icon(Icons.chevron_right)
                      : IconButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                    _date = null;
                                    _dirty = true;
                                  }),
                          icon: const Icon(Icons.close)),
                  onTap: _busy ? null : _selectDate),
              ListTile(
                  title: const Text('私信'),
                  subtitle: const Text('暂不支持选择聊天记录'),
                  enabled: false),
            ]));
      default:
        return const Text('当前版本暂不支持这项举报材料。');
    }
  }

  Widget _result() => Center(
      child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: TiebananaTokens.of(context).primary),
            const SizedBox(height: 18),
            Text('举报已提交', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text('感谢你维护社区氛围。处理结果以官方审核为准。'),
            const SizedBox(height: 20),
            FilledButton(onPressed: _leave, child: const Text('完成')),
          ])));
}
