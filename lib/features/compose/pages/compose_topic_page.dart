import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

class ComposeTopicPage extends StatefulWidget {
  const ComposeTopicPage({super.key, required this.fid});
  final String fid;
  @override
  State<ComposeTopicPage> createState() => _ComposeTopicPageState();
}

class _ComposeTopicPageState extends State<ComposeTopicPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  int _generation = 0;
  bool _loading = true;
  String? _error;
  List<TiebaComposeTopic> _items = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await Global.tiebaAPI
          .searchComposeTopics(fid: widget.fid, prefix: _search.text.trim());
      if (mounted && generation == _generation) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: TiebananaTokens.of(context).bg,
      appBar: AppBar(title: const Text('添加话题')),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                    hintText: '搜索感兴趣的话题', prefixIcon: Icon(Icons.search)),
                onSubmitted: (_) {
                  _debounce?.cancel();
                  _load();
                },
                onChanged: (_) {
                  // 输入立即废弃旧请求，防抖等待期间只显示最新关键词的结果。
                  _generation++;
                  _debounce?.cancel();
                  setState(() {
                    _loading = true;
                  });
                  _debounce = Timer(const Duration(milliseconds: 350), _load);
                })),
        Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_error!),
                                  TextButton(
                                      onPressed: _load, child: const Text('重试'))
                                ])))
                    : _items.isEmpty
                        ? const Center(child: Text('没有找到相关话题，试试其他关键词'))
                        : ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return ListTile(
                                  leading: Icon(Icons.tag,
                                      color:
                                          TiebananaTokens.of(context).primary),
                                  title: Text(item.name),
                                  subtitle: item.description.isEmpty
                                      ? null
                                      : Text(item.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                  trailing: const Icon(Icons.add),
                                  onTap: () => Navigator.pop(context, item));
                            })),
      ]));
}
