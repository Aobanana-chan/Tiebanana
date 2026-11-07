import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 图片选择只返回资源，上传与正文编辑由回复面板统一管理。
class ImagePickerRoute extends StatefulWidget {
  const ImagePickerRoute({super.key, this.singleSelection = false});

  /// 头像等单图用途；默认发帖流程仍为多选。
  final bool singleSelection;

  @override
  State<ImagePickerRoute> createState() => _ImagePickerRouteState();
}

class _ImagePickerRouteState extends State<ImagePickerRoute>
    with WidgetsBindingObserver {
  static const _pageSize = 60;
  final _selected = <AssetEntity>{};
  final _images = <AssetEntity>[];
  final _scroll = ScrollController();
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _album;
  PermissionState? _permission;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _original = false;
  bool _openingSettings = false;
  String? _error;
  int _page = 0;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _openingSettings) {
      _openingSettings = false;
      _reload();
    }
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) _loadMore();
  }

  Future<void> _reload({AssetPathEntity? album}) async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
    });
    try {
      final permission = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.image,
            mediaLocation: false,
          ),
        ),
      );
      final albums = permission.hasAccess
          ? await PhotoManager.getAssetPathList(type: RequestType.image)
          : <AssetPathEntity>[];
      final current = albums.where((a) => a.id == (album ?? _album)?.id);
      final chosen = current.isNotEmpty
          ? current.first
          : albums.isNotEmpty
              ? albums.first
              : null;
      final images =
          await chosen?.getAssetListPaged(page: 0, size: _pageSize) ??
              <AssetEntity>[];
      if (!mounted || generation != _generation) return;
      setState(() {
        _permission = permission;
        _albums = albums;
        _album = chosen;
        _images
          ..clear()
          ..addAll(images);
        _page = 1;
        _hasMore = images.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = '无法读取相册，请重试';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading ||
        _loadingMore ||
        !_hasMore ||
        _album == null ||
        _error != null) {
      return;
    }
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final images =
          await _album!.getAssetListPaged(page: _page, size: _pageSize);
      if (!mounted || generation != _generation) return;
      setState(() {
        _images.addAll(images);
        _page++;
        _hasMore = images.length == _pageSize;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loadingMore = false;
        _error = '加载更多照片失败';
      });
    }
  }

  void _toggle(AssetEntity image) => setState(() {
        if (widget.singleSelection && !_selected.contains(image)) {
          _selected.clear();
        }
        if (!_selected.remove(image)) _selected.add(image);
      });

  Future<void> _chooseAlbum() async {
    final album = await showModalBottomSheet<AssetPathEntity>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('全部相册')),
            for (final album in _albums)
              ListTile(
                title: Text(album.name),
                trailing: album.id == _album?.id
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(context, album),
              ),
          ],
        ),
      ),
    );
    if (mounted && album != null) _reload(album: album);
  }

  Future<void> _settings() async {
    _openingSettings = true;
    await PhotoManager.openSetting();
  }

  Future<void> _preview(AssetEntity image) async {
    final file = await image.file;
    if (!mounted || file == null) return;
    await Navigator.push<void>(context, appPageRoute<void>(builder: (context) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('预览图片')),
        body: Center(
          child: ExtendedImage.file(file, mode: ExtendedImageMode.gesture),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () {
                _toggle(image);
                Navigator.pop(context);
              },
              child: Text(_selected.contains(image) ? '取消选择' : '选择图片'),
            ),
          ),
        ),
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TiebananaTokens.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.singleSelection ? '选择头像' : '图片上传'),
        actions: [
          IconButton(
            tooltip: '刷新相册',
            onPressed: _loading ? null : () => _reload(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(children: [
                Expanded(
                  child: Text('已选 ${_selected.length} 张',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (!widget.singleSelection) const Text('原图'),
                if (!widget.singleSelection)
                  Switch(
                    value: _original,
                    onChanged: (value) => setState(() => _original = value),
                  ),
              ]),
            ),
          ),
          if (_selected.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text('从最近项目中选择图片，长按可预览',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: tokens.textTertiary)),
              ),
            )
          else
            _grid(_selected.toList(), selectedSection: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(children: [
                Expanded(
                  child: Text(_album?.isAll == false ? _album!.name : '最近项目',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton(
                  onPressed: _albums.isEmpty ? null : _chooseAlbum,
                  child: const Text('全部相册 ›'),
                ),
              ]),
            ),
          ),
          if (_permission == PermissionState.limited)
            SliverToBoxAdapter(
              child: ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('目前只授权了部分照片'),
                trailing:
                    TextButton(onPressed: _settings, child: const Text('管理权限')),
              ),
            ),
          if (_loading)
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator())))
          else if (_permission?.hasAccess == false)
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (!_loading && _permission?.hasAccess == false)
            SliverToBoxAdapter(
              child: ImagePickerStateView(
                title: '需要访问相册',
                message: '请在系统设置中允许访问照片，以便选择回复配图。',
                action: '去设置',
                onAction: _settings,
              ),
            )
          else if (!_loading && _images.isEmpty && _error == null)
            SliverToBoxAdapter(
              child: ImagePickerStateView(
                title: '相册里还没有照片',
                message: _permission == PermissionState.limited
                    ? '只授权了部分照片，可以在设置中选择更多照片。'
                    : '拍摄或保存图片后，刷新再试。',
                action: '刷新',
                onAction: () => _reload(),
              ),
            ),
          if (!_loading && _images.isNotEmpty) _grid(_images),
          if (_error != null)
            SliverToBoxAdapter(
              child: ImagePickerStateView(
                title: _error!,
                message: '请检查相册权限后重试。',
                action: '重试',
                onAction: () {
                  if (_images.isEmpty) {
                    _reload();
                  } else {
                    setState(() => _error = null);
                    _loadMore();
                  }
                },
              ),
            ),
          if (_loadingMore)
            const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator())),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      bottomNavigationBar: ImagePickerFooter(
        count: _selected.length,
        singleSelection: widget.singleSelection,
        onConfirm: _selected.isEmpty
            ? null
            : () => Navigator.pop(context, [Set.of(_selected), _original]),
      ),
    );
  }

  Widget _grid(List<AssetEntity> images, {bool selectedSection = false}) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
        itemCount: images.length + (selectedSection ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == images.length) {
            return Material(
              color: TiebananaTokens.of(context).fill,
              borderRadius: TiebananaMetrics.brCtl,
              child: InkWell(
                borderRadius: TiebananaMetrics.brCtl,
                onTap: () => _scroll.animateTo(
                    ((_selected.length / 3).ceil() * 130.0)
                        .clamp(0.0, _scroll.position.maxScrollExtent),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut),
                child: const Center(child: Icon(Icons.add_rounded, size: 32)),
              ),
            );
          }
          final image = images[index];
          return ImageSelectionTile(
            key: ValueKey(
                '${selectedSection ? 'selected' : 'recent'}-${image.id}'),
            image: image,
            selected: _selected.contains(image),
            order: _selected.toList().indexOf(image) + 1,
            removable: selectedSection,
            onTap: () => _toggle(image),
            onPreview: () => _preview(image),
          );
        },
      ),
    );
  }
}

/// 独立展示件便于在无相册插件的环境下验证状态与布局。
class ImagePickerStateView extends StatelessWidget {
  const ImagePickerStateView(
      {super.key,
      required this.title,
      required this.message,
      required this.action,
      required this.onAction});
  final String title;
  final String message;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Icon(Icons.photo_library_outlined,
              size: 40, color: TiebananaTokens.of(context).textTertiary),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          TextButton(onPressed: onAction, child: Text(action)),
        ]),
      );
}

class ImagePickerFooter extends StatelessWidget {
  const ImagePickerFooter(
      {super.key,
      required this.count,
      this.onConfirm,
      this.singleSelection = false});
  final bool singleSelection;
  final int count;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) => Material(
        color: TiebananaTokens.of(context).surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                  child: Text(singleSelection ? '下一步裁切头像，不会立即上传' : '选择后返回回复框',
                      style: Theme.of(context).textTheme.bodySmall)),
              const SizedBox(width: 8),
              FilledButton(
                  onPressed: onConfirm,
                  child: Text(count == 0
                      ? '请选择图片'
                      : singleSelection
                          ? '裁切头像'
                          : '添加（$count）')),
            ]),
          ),
        ),
      );
}

class ImageSelectionTile extends StatefulWidget {
  const ImageSelectionTile(
      {super.key,
      required this.image,
      required this.selected,
      required this.order,
      required this.removable,
      required this.onTap,
      required this.onPreview});
  final AssetEntity image;
  final bool selected;
  final int order;
  final bool removable;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  @override
  State<ImageSelectionTile> createState() => _ImageSelectionTileState();
}

class _ImageSelectionTileState extends State<ImageSelectionTile> {
  late final Future<Uint8List?> _thumbnail =
      widget.image.thumbnailDataWithSize(const ThumbnailSize(320, 320));

  @override
  Widget build(BuildContext context) {
    final tokens = TiebananaTokens.of(context);
    return Material(
      color: tokens.fill,
      borderRadius: TiebananaMetrics.brCtl,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onPreview,
        child: Stack(fit: StackFit.expand, children: [
          FutureBuilder<Uint8List?>(
            future: _thumbnail,
            builder: (context, snapshot) => snapshot.data == null
                ? const Icon(Icons.image_outlined)
                : Image.memory(snapshot.data!, fit: BoxFit.cover),
          ),
          if (widget.selected)
            IgnorePointer(
                child: DecoratedBox(
                    decoration: BoxDecoration(
              border: Border.all(color: tokens.primary, width: 3),
              borderRadius: TiebananaMetrics.brCtl,
            ))),
          Positioned(
            top: 6,
            right: 6,
            child: Semantics(
              label: widget.removable ? '移除图片' : '选择第 ${widget.order} 张图片',
              selected: widget.selected,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.selected ? tokens.accentFill : tokens.surface,
                ),
                alignment: Alignment.center,
                child: widget.removable
                    ? Icon(Icons.close_rounded,
                        size: 18, color: tokens.accentOn)
                    : widget.selected
                        ? Text('${widget.order}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: tokens.accentOn))
                        : Icon(Icons.circle_outlined,
                            size: 22, color: tokens.textSecondary),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
