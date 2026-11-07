import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tiebanana/features/compose/models/thread_compose_draft.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/features/media/pages/image_picker_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

class ComposeScorePage extends StatefulWidget {
  const ComposeScorePage({super.key, this.initial});
  final ComposeScore? initial;
  @override
  State<ComposeScorePage> createState() => _ComposeScorePageState();
}

class _ScoreField {
  _ScoreField(this.assetId, {String title = '', String content = ''})
      : title = TextEditingController(text: title),
        content = TextEditingController(text: content);
  final String assetId;
  final TextEditingController title;
  final TextEditingController content;
  void dispose() {
    title.dispose();
    content.dispose();
  }
}

class _ComposeScorePageState extends State<ComposeScorePage> {
  late final _items = [
    for (final item in widget.initial?.items ?? <ComposeScoreItem>[])
      _ScoreField(item.assetId, title: item.title, content: item.content)
  ];
  late int _level = widget.initial?.levelLimit ?? 0;
  String? _error;
  bool _picking = false;
  bool _allowPop = false;
  bool _dirty = false;
  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    if (_items.length >= 30 || _picking) return;
    setState(() => _picking = true);
    try {
      final result = await Navigator.push<List<dynamic>>(
          context, appPageRoute(builder: (_) => const ImagePickerRoute()));
      if (!mounted || result == null) return;
      final assets = (result[0] as Set<AssetEntity>).toList();
      final limit = (30 - _items.length).clamp(0, 9);
      if (assets.length > limit) {
        setState(() => _error = '每次最多添加 $limit 张图片，请重新选择');
        return;
      }
      setState(() {
        for (final asset in assets) {
          _items.add(_ScoreField(asset.id));
        }
        _dirty = assets.isNotEmpty || _dirty;
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _finish() {
    final items = [
      for (final item in _items)
        ComposeScoreItem(
            assetId: item.assetId,
            title: item.title.text,
            content: item.content.text)
    ];
    final error = ComposeScore.validate(items);
    setState(() => _error = error);
    if (error == null) {
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(
              context, ComposeScore(items: items, levelLimit: _level));
        }
      });
    }
  }

  Future<void> _back() async {
    if (_dirty) {
      final result = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text('放弃本次打分编辑？'),
                  content: const Text('本次修改不会保存，原有组件保持不变。'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('继续编辑')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('放弃修改'))
                  ]));
      if (result != true || !mounted) return;
    }
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TiebananaTokens.of(context);
    return PopScope(
        canPop: _allowPop,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _back();
        },
        child: Scaffold(
            backgroundColor: tokens.bg,
            appBar: AppBar(
                title: const Text('编辑打分组件'),
                leading: BackButton(onPressed: _back),
                actions: [
                  TextButton(
                      onPressed: _picking ? null : _finish,
                      child: const Text('完成'))
                ]),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              Text('添加图片，创建想让吧友评价的打分项。',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              for (int i = 0; i < _items.length; i++)
                Container(
                    key: ValueKey(_items[i]),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: tokens.surface,
                        borderRadius: TiebananaMetrics.brLg),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text('打分项 ${i + 1}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall)),
                            IconButton(
                                tooltip: '移除打分项 ${i + 1}',
                                onPressed: () {
                                  final item = _items[i];
                                  setState(() {
                                    _items.removeAt(i);
                                    _dirty = true;
                                  });
                                  WidgetsBinding.instance.addPostFrameCallback(
                                      (_) => item.dispose());
                                },
                                icon: const Icon(Icons.close))
                          ]),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                  width: 88,
                                  height: 88,
                                  child: _ScoreThumbnail(
                                      key: ValueKey(_items[i].assetId),
                                      assetId: _items[i].assetId))),
                          const SizedBox(height: 12),
                          TextField(
                              controller: _items[i].title,
                              onChanged: (_) => _dirty = true,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(18)
                              ],
                              decoration: const InputDecoration(
                                  labelText: '打分项名称',
                                  hintText: '必填，最多 18 个字，不支持表情')),
                          const SizedBox(height: 10),
                          TextField(
                              controller: _items[i].content,
                              onChanged: (_) => _dirty = true,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(20)
                              ],
                              decoration: const InputDecoration(
                                  labelText: '补充简介', hintText: '选填，最多 20 个字')),
                        ])),
              OutlinedButton.icon(
                  onPressed: _items.length < 30 && !_picking ? _pick : null,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label:
                      Text(_picking ? '正在选图…' : '添加打分项（${_items.length}/30）')),
              const SizedBox(height: 24),
              Text('打分权限', style: Theme.of(context).textTheme.titleSmall),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('限制吧等级'),
                  subtitle:
                      Text(_level == 0 ? '所有人均可打分' : 'Lv.$_level 及以上吧友可打分'),
                  value: _level > 0,
                  onChanged: (v) => setState(() {
                        _level = v ? 1 : 0;
                        _dirty = true;
                      })),
              if (_level > 0)
                Row(children: [
                  IconButton(
                      tooltip: '降低等级',
                      onPressed: _level > 1
                          ? () => setState(() {
                                _level--;
                                _dirty = true;
                              })
                          : null,
                      icon: const Icon(Icons.remove)),
                  Expanded(
                      child: Text('Lv.$_level', textAlign: TextAlign.center)),
                  IconButton(
                      tooltip: '提高等级',
                      onPressed: _level < 18
                          ? () => setState(() {
                                _level++;
                                _dirty = true;
                              })
                          : null,
                      icon: const Icon(Icons.add))
                ]),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child:
                        Text(_error!, style: TextStyle(color: tokens.danger))),
            ])));
  }
}

class _ScoreThumbnail extends StatefulWidget {
  const _ScoreThumbnail({super.key, required this.assetId});
  final String assetId;
  @override
  State<_ScoreThumbnail> createState() => _ScoreThumbnailState();
}

class _ScoreThumbnailState extends State<_ScoreThumbnail> {
  late final _bytes = _load();
  Future<Uint8List?> _load() async {
    try {
      final asset = await AssetEntity.fromId(widget.assetId);
      return await asset?.thumbnailDataWithSize(const ThumbnailSize(240, 240));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: TiebananaMetrics.brSm,
      child: ColoredBox(
          color: TiebananaTokens.of(context).fill,
          child: FutureBuilder(
              future: _bytes,
              builder: (context, snapshot) => snapshot.data == null
                  ? const Icon(Icons.image_outlined)
                  : Image.memory(snapshot.data!, fit: BoxFit.cover))));
}
