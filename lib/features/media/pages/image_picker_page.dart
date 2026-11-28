import 'dart:async';
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/core/platform/platform_capabilities.dart';
import 'package:tiebanana/features/media/data/local_image_asset.dart';
import 'package:tiebanana/features/media/widgets/image_picker_lightbox.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/layout/page_wrap.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/dashed_border.dart';
import 'package:tiebanana/shared/widgets/desktop_panel.dart';

/// 图片选择只返回资源，上传与正文编辑由回复面板统一管理。
class ImagePickerRoute extends StatefulWidget {
  const ImagePickerRoute({
    super.key,
    this.singleSelection = false,
    this.filePicker,
  });

  /// 桌面文件选择入口，可注入以验证取消、失败与多选行为。
  final Future<List<AssetEntity>> Function(bool singleSelection)? filePicker;

  /// 头像等单图用途；默认发帖流程仍为多选。
  final bool singleSelection;

  @override
  State<ImagePickerRoute> createState() => _ImagePickerRouteState();
}

class _ImagePickerRouteState extends State<ImagePickerRoute>
    with WidgetsBindingObserver {
  static const int _pageSize = 60;
  static const int _avatarMaxBytes = 20 * 1024 * 1024;

  final Set<AssetEntity> _selected = <AssetEntity>{};
  final List<AssetEntity> _images = <AssetEntity>[];
  final ScrollController _scroll = ScrollController();
  final Map<String, ImageAssetMeta> _metaCache = <String, ImageAssetMeta>{};

  List<AssetPathEntity> _albums = <AssetPathEntity>[];
  AssetPathEntity? _album;
  AssetEntity? _focused;
  PermissionState? _permission;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _original = false;
  bool _openingSettings = false;
  bool _pickingFiles = false;
  String? _error;
  int _page = 0;
  int _generation = 0;

  bool get _usesFilePicker => isDesktop || widget.filePicker != null;

  bool get _hasOversizeAvatar {
    if (!widget.singleSelection || _selected.isEmpty) return false;
    final int? bytes = _metaCache[_selected.first.id]?.sizeBytes;
    return bytes != null && bytes > _avatarMaxBytes;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    if (_usesFilePicker) {
      _loading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickFiles());
    } else {
      _reload();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _openingSettings &&
        !_usesFilePicker) {
      _openingSettings = false;
      _reload();
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 400) _loadMore();
  }

  void _ensureMeta(AssetEntity asset) {
    if (_metaCache.containsKey(asset.id)) return;
    unawaited(ImageAssetMeta.load(asset).then((ImageAssetMeta meta) {
      if (!mounted) return;
      setState(() => _metaCache[asset.id] = meta);
    }));
  }

  void _syncFocus({AssetEntity? preferred}) {
    if (preferred != null && _selected.contains(preferred)) {
      _focused = preferred;
    } else if (_focused == null ||
        (!_selected.contains(_focused) && !_images.contains(_focused))) {
      _focused = _selected.isNotEmpty ? _selected.first : null;
    }
    if (_focused != null) _ensureMeta(_focused!);
  }

  Future<void> _pickFiles() async {
    if (!mounted || _pickingFiles) return;
    _pickingFiles = true;
    try {
      if (widget.filePicker != null) {
        final List<AssetEntity> assets =
            await widget.filePicker!(widget.singleSelection);
        if (!mounted || assets.isEmpty) return;
        final Iterable<AssetEntity> chosen =
            widget.singleSelection ? assets.take(1) : assets;
        for (final AssetEntity asset in chosen) {
          _ensureMeta(asset);
        }
        setState(() {
          if (widget.singleSelection) _selected.clear();
          _selected.addAll(chosen);
          _syncFocus(preferred: chosen.first);
          _error = null;
        });
        return;
      }
      final List<PlatformFile> result = widget.singleSelection
          ? <PlatformFile?>[
              await FilePicker.pickFile(
                type: FileType.custom,
                allowedExtensions: const <String>[
                  'jpg',
                  'jpeg',
                  'png',
                  'gif',
                  'webp',
                  'bmp',
                ],
              ),
            ].whereType<PlatformFile>().toList()
          : await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: const <String>[
                'jpg',
                'jpeg',
                'png',
                'gif',
                'webp',
                'bmp',
              ],
            );
      if (result.isEmpty || !mounted) return;
      final List<AssetEntity> assets = <AssetEntity>[];
      for (final PlatformFile file in result) {
        if (file.path != null) {
          final LocalImageAsset asset =
              await LocalImageAsset.fromFile(File(file.path!));
          assets.add(asset);
          _ensureMeta(asset);
        }
      }
      if (!mounted || assets.isEmpty) return;
      setState(() {
        if (widget.singleSelection) _selected.clear();
        _selected.addAll(assets);
        _syncFocus(preferred: assets.first);
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = '无法读取图片，请选择有效的图片文件');
      }
    } finally {
      _pickingFiles = false;
    }
  }

  Future<void> _reload({AssetPathEntity? album}) async {
    final int generation = ++_generation;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
    });
    try {
      final PermissionState permission =
          await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.image,
            mediaLocation: false,
          ),
        ),
      );
      final List<AssetPathEntity> albums = permission.hasAccess
          ? await PhotoManager.getAssetPathList(type: RequestType.image)
          : <AssetPathEntity>[];
      final Iterable<AssetPathEntity> current =
          albums.where((AssetPathEntity a) => a.id == (album ?? _album)?.id);
      final AssetPathEntity? chosen = current.isNotEmpty
          ? current.first
          : albums.isNotEmpty
              ? albums.first
              : null;
      final List<AssetEntity> images =
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
    } catch (_) {
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
    final int generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final List<AssetEntity> images =
          await _album!.getAssetListPaged(page: _page, size: _pageSize);
      if (!mounted || generation != _generation) return;
      setState(() {
        _images.addAll(images);
        _page++;
        _hasMore = images.length == _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loadingMore = false;
        _error = '加载更多照片失败';
      });
    }
  }

  void _toggle(AssetEntity image) {
    setState(() {
      if (widget.singleSelection && !_selected.contains(image)) {
        _selected.clear();
      }
      if (!_selected.remove(image)) {
        _selected.add(image);
        _focused = image;
        _ensureMeta(image);
      } else {
        _syncFocus();
      }
    });
  }

  void _focusDesktopTile(AssetEntity image) {
    setState(() {
      _focused = image;
      _ensureMeta(image);
    });
  }

  void _removeSelected(AssetEntity image) {
    setState(() {
      _selected.remove(image);
      _syncFocus();
    });
  }

  void _clearSelected() {
    setState(() {
      _selected.clear();
      _focused = null;
    });
  }

  void _moveSelected(int from, int to) {
    if (from < 0 ||
        to < 0 ||
        from >= _selected.length ||
        to >= _selected.length) {
      return;
    }
    final List<AssetEntity> list = _selected.toList();
    final AssetEntity moved = list.removeAt(from);
    list.insert(to, moved);
    setState(() {
      _selected
        ..clear()
        ..addAll(list);
      _focused = moved;
    });
  }

  void _confirm() {
    if (_selected.isEmpty || _hasOversizeAvatar) return;
    Navigator.pop(
        context, <dynamic>[Set<AssetEntity>.of(_selected), _original]);
  }

  Future<void> _chooseAlbum() async {
    final bool desktop = AppBreakpoints.isDesktop(context);
    final AssetPathEntity? album = desktop
        ? await showDialog<AssetPathEntity>(
            context: context,
            builder: (BuildContext dialogContext) {
              final TiebananaTokens tokens = TiebananaTokens.of(dialogContext);
              return Dialog(
                backgroundColor: tokens.surface,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: tokens.line),
                ),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 360, maxHeight: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      PanelHeader(
                        title: '全部相册',
                        count: _albums.length,
                        trailing: <Widget>[
                          IconButton(
                            tooltip: '关闭',
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                        ],
                      ),
                      Divider(height: 1, color: tokens.line),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          children: <Widget>[
                            for (final AssetPathEntity item in _albums)
                              ListTile(
                                dense: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: TiebananaMetrics.brSm,
                                ),
                                selected: item.id == _album?.id,
                                selectedTileColor: tokens.primaryContainer,
                                title: Text(item.name),
                                trailing: item.id == _album?.id
                                    ? const Icon(Icons.check_rounded, size: 18)
                                    : null,
                                onTap: () => Navigator.pop(dialogContext, item),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        : await showModalBottomSheet<AssetPathEntity>(
            context: context,
            showDragHandle: true,
            builder: (BuildContext context) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  const ListTile(title: Text('全部相册')),
                  for (final AssetPathEntity item in _albums)
                    ListTile(
                      title: Text(item.name),
                      trailing: item.id == _album?.id
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () => Navigator.pop(context, item),
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

  Future<void> _preview(AssetEntity image, {List<AssetEntity>? pool}) async {
    if (AppBreakpoints.isDesktop(context)) {
      final List<AssetEntity> list =
          (pool != null && pool.isNotEmpty) ? pool : <AssetEntity>[image];
      final int idx = list.indexOf(image);
      await showImagePickerLightbox(
        context,
        images: list,
        initialIndex: idx < 0 ? 0 : idx,
        metaCache: _metaCache,
        showToggleSelection: !_usesFilePicker,
        isSelected: (AssetEntity item) => _selected.contains(item),
        onToggleSelection: _toggle,
      );
      return;
    }
    final File? file = await image.file;
    if (!mounted || file == null) return;
    await Navigator.push<void>(
      context,
      appPageRoute<void>(
        builder: (BuildContext context) => Scaffold(
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final AppBreakpoint bp = AppBreakpoints.fromWidth(width);

    if (bp == AppBreakpoint.compact) {
      return _usesFilePicker
          ? _buildCompactDesktopFileScaffold(context)
          : _buildCompactAlbumScaffold(context);
    }

    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
        if (_usesFilePicker)
          const SingleActivator(LogicalKeyboardKey.keyO, control: true):
              _pickFiles,
        if (!_usesFilePicker) ...<ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.f5): () => _reload(),
          const SingleActivator(LogicalKeyboardKey.keyR, control: true): () =>
              _reload(),
        },
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            _confirm,
        const SingleActivator(LogicalKeyboardKey.delete): () {
          if (_focused != null && _selected.contains(_focused)) {
            _removeSelected(_focused!);
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: tokens.bg,
          body: Column(
            children: <Widget>[
              _buildWidescreenTopBar(context, width),
              Expanded(
                child: _usesFilePicker
                    ? _buildWidescreenDesktopFileBody(context, bp)
                    : _buildWidescreenAlbumBody(context, bp),
              ),
              ImagePickerFooter(
                count: _selected.length,
                singleSelection: widget.singleSelection,
                onConfirm:
                    (_selected.isEmpty || _hasOversizeAvatar) ? null : _confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 宽屏顶栏 =================

  Widget _buildWidescreenTopBar(BuildContext context, double width) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double hPad = AppBreakpoints.pagePaddingFor(width);
    final String title = widget.singleSelection ? '选择头像' : '选择图片';
    final String sourceTag = _usesFilePicker ? '本地文件' : '系统相册';
    final String subtitle = widget.singleSelection
        ? '单图选择 · 下一步进入 1:1 头像裁切，不会立即上传'
        : _usesFilePicker
            ? '可分批从本地文件夹添加；单击切换检视，双击或点右上角缩放'
            : '点击勾选照片并保留插入顺序；长按或点放大图标可预览大图';

    return Material(
      color: tokens.bar,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: tokens.line)),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppBreakpoints.pageMaxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 10),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      tooltip: '返回 (Esc)',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: tokens.primaryContainer,
                                  borderRadius: TiebananaMetrics.brXs,
                                ),
                                child: Text(
                                  sourceTag,
                                  style: textTheme.labelSmall?.copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              color: tokens.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_usesFilePicker) ...<Widget>[
                      if (_selected.isNotEmpty && !widget.singleSelection)
                        TextButton(
                          onPressed: _clearSelected,
                          child: const Text('清空已选'),
                        ),
                      const SizedBox(width: 4),
                      FilledButton.tonalIcon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.folder_open_rounded, size: 17),
                        label: const Text('选择文件'),
                      ),
                    ] else ...<Widget>[
                      if (_selected.isNotEmpty && !widget.singleSelection)
                        TextButton(
                          onPressed: _clearSelected,
                          child: Text('清空（${_selected.length}）'),
                        ),
                      IconButton(
                        tooltip: '刷新相册',
                        onPressed: _loading ? null : () => _reload(),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= 宽屏：桌面本地文件模式 =================

  Widget _buildWidescreenDesktopFileBody(
    BuildContext context,
    AppBreakpoint bp,
  ) {
    final List<AssetEntity> selectedList = _selected.toList();
    if (bp == AppBreakpoint.medium) {
      return SingleChildScrollView(
        controller: _scroll,
        child: PageWrap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildDesktopGridPanel(
                context,
                selectedList: selectedList,
                crossAxisCount: 4,
                showMediumControls: true,
              ),
              if (selectedList.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                _buildInspectorPanel(
                  context,
                  selectedList: selectedList,
                  compactHorizontal: true,
                ),
              ],
            ],
          ),
        ),
      );
    }

    final int cols = bp == AppBreakpoint.wide ? 4 : 3;
    final double inspectorWidth = bp == AppBreakpoint.wide ? 316 : 288;

    return PageWrap(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              child: _buildDesktopGridPanel(
                context,
                selectedList: selectedList,
                crossAxisCount: cols,
                showMediumControls: false,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: inspectorWidth,
            child: SingleChildScrollView(
              child: _buildInspectorPanel(
                context,
                selectedList: selectedList,
                compactHorizontal: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGridPanel(
    BuildContext context, {
    required List<AssetEntity> selectedList,
    required int crossAxisCount,
    required bool showMediumControls,
  }) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DesktopPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PanelHeader(
            title: widget.singleSelection ? '头像源文件' : '待添加图片',
            trailing: <Widget>[
              Text(
                '已选 ${selectedList.length} 张',
                style: textTheme.labelMedium?.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (showMediumControls && !widget.singleSelection) ...<Widget>[
                const SizedBox(width: 6),
                Text(
                  '原图',
                  style: textTheme.labelMedium?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
                Switch(
                  value: _original,
                  onChanged: (bool value) => setState(() => _original = value),
                ),
              ],
            ],
          ),
          Divider(height: 1, color: tokens.line),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _InlineBanner(
                icon: Icons.error_outline_rounded,
                text: _error!,
                danger: true,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: selectedList.isEmpty
                ? _buildDesktopEmptyZone(context)
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount:
                        selectedList.length + (widget.singleSelection ? 0 : 1),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == selectedList.length) {
                        return _AddMoreTile(onTap: _pickFiles);
                      }
                      final AssetEntity asset = selectedList[index];
                      _ensureMeta(asset);
                      final ImageAssetMeta? meta = _metaCache[asset.id];
                      final bool oversize = widget.singleSelection &&
                          meta?.sizeBytes != null &&
                          meta!.sizeBytes! > _avatarMaxBytes;
                      final String? dimLabel = asset.width > 0 &&
                              asset.height > 0
                          ? '${meta?.ext ?? 'IMG'} · ${asset.width}×${asset.height}'
                          : meta?.ext;
                      return ImageSelectionTile(
                        key: ValueKey('selected-${asset.id}'),
                        image: asset,
                        selected: true,
                        focused: _focused == asset ||
                            (_focused == null && index == 0),
                        order: index + 1,
                        removable: true,
                        desktopMode: true,
                        metaLabel: oversize ? '>20MB' : dimLabel,
                        metaWarning: oversize,
                        onTap: () => _focusDesktopTile(asset),
                        onRemove: () => _removeSelected(asset),
                        onPreview: () => _preview(asset, pool: selectedList),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopEmptyZone(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return CustomPaint(
      painter: DashedBorderPainter(
        color: tokens.lineStrong,
        radius: TiebananaMetrics.brMd,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
        decoration: BoxDecoration(
          color: tokens.fill.withValues(alpha: 0.45),
          borderRadius: TiebananaMetrics.brMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tokens.primaryContainer,
                borderRadius: TiebananaMetrics.brMd,
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 28,
                color: tokens.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.singleSelection ? '选择一张本地图片作为头像' : '从本地文件夹选择图片',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.singleSelection
                  ? '支持 JPG、PNG、GIF、WEBP、BMP；文件大小建议不超过 20 MB'
                  : '支持 JPG、PNG、GIF、WEBP、BMP；可分批多次添加并自动去重',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: const Text('从文件夹选择'),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 宽屏：系统相册模式 =================

  Widget _buildWidescreenAlbumBody(BuildContext context, AppBreakpoint bp) {
    final List<AssetEntity> selectedList = _selected.toList();

    if (bp == AppBreakpoint.medium) {
      return _buildMediumAlbumBody(context, selectedList);
    }

    final bool showAlbumRail = bp == AppBreakpoint.wide;
    final double inspectorWidth = showAlbumRail ? 296 : 284;

    return PageWrap(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showAlbumRail) ...<Widget>[
            SizedBox(
              width: 208,
              child: _buildAlbumRail(context),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: _buildAlbumGridPanel(
              context,
              crossAxisCount: 3,
              showDropdownButton: !showAlbumRail,
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: inspectorWidth,
            child: SingleChildScrollView(
              child: _buildInspectorPanel(
                context,
                selectedList: selectedList,
                compactHorizontal: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediumAlbumBody(
    BuildContext context,
    List<AssetEntity> selectedList,
  ) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return PageWrap(
      child: CustomScrollView(
        controller: _scroll,
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: DesktopPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '已选 ${_selected.length} 张',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                        if (!widget.singleSelection) ...<Widget>[
                          Text(
                            '原图',
                            style: textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Switch(
                            value: _original,
                            onChanged: (bool value) =>
                                setState(() => _original = value),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (selectedList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        '从最近项目中选择图片，长按或点击放大图标可预览',
                        style: textTheme.bodySmall?.copyWith(
                          color: tokens.textTertiary,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                        itemCount: selectedList.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (BuildContext context, int index) {
                          final AssetEntity image = selectedList[index];
                          return SizedBox(
                            width: 78,
                            height: 78,
                            child: ImageSelectionTile(
                              key: ValueKey('selected-${image.id}'),
                              image: image,
                              selected: true,
                              order: index + 1,
                              removable: true,
                              onTap: () => _toggle(image),
                              onPreview: () =>
                                  _preview(image, pool: selectedList),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(
            child: DesktopPanel(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(TiebananaMetrics.radiusLg),
                bottom: _loading ||
                        _permission?.hasAccess == false ||
                        (_images.isEmpty && _error == null)
                    ? Radius.circular(TiebananaMetrics.radiusLg)
                    : Radius.zero,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _album?.isAll == false ? _album!.name : '最近项目',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _albums.isEmpty ? null : _chooseAlbum,
                          child: const Text('全部相册 ›'),
                        ),
                      ],
                    ),
                  ),
                  if (_permission == PermissionState.limited)
                    _buildLimitedPermissionTile(context),
                  ..._buildAlbumStateWidgets(context),
                ],
              ),
            ),
          ),
          if (!_loading && _images.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.only(top: 10),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _images.length,
                itemBuilder: (BuildContext context, int index) {
                  final AssetEntity image = _images[index];
                  return ImageSelectionTile(
                    key: ValueKey('recent-${image.id}'),
                    image: image,
                    selected: _selected.contains(image),
                    order: _selected.toList().indexOf(image) + 1,
                    removable: false,
                    onTap: () => _toggle(image),
                    onPreview: () => _preview(image, pool: _images),
                  );
                },
              ),
            ),
          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildAlbumRail(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return DesktopPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PanelHeader(title: '全部相册', count: _albums.length),
          Divider(height: 1, color: tokens.line),
          Expanded(
            child: _albums.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _loading ? '读取相册中…' : '暂无可用相册',
                        style: textTheme.bodySmall?.copyWith(
                          color: tokens.textTertiary,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: _albums.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 3),
                    itemBuilder: (BuildContext context, int index) {
                      final AssetPathEntity album = _albums[index];
                      final bool active = album.id == _album?.id;
                      return Material(
                        color: active
                            ? tokens.primaryContainer
                            : Colors.transparent,
                        borderRadius: TiebananaMetrics.brSm,
                        child: InkWell(
                          borderRadius: TiebananaMetrics.brSm,
                          onTap: () => _reload(album: album),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 9,
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    album.isAll ? '最近项目' : album.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: active
                                          ? tokens.onPrimaryContainer
                                          : tokens.textSecondary,
                                    ),
                                  ),
                                ),
                                if (active)
                                  Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: tokens.onPrimaryContainer,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumGridPanel(
    BuildContext context, {
    required int crossAxisCount,
    required bool showDropdownButton,
  }) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final String albumTitle = _album?.isAll == false ? _album!.name : '最近项目';

    return DesktopPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PanelHeader(
            title: albumTitle,
            count: _images.isNotEmpty ? _images.length : null,
            trailing: <Widget>[
              if (showDropdownButton)
                TextButton(
                  onPressed: _albums.isEmpty ? null : _chooseAlbum,
                  child: const Text('全部相册 ›'),
                ),
            ],
          ),
          Divider(height: 1, color: tokens.line),
          if (_permission == PermissionState.limited)
            _buildLimitedPermissionTile(context),
          Expanded(
            child: CustomScrollView(
              controller: _scroll,
              slivers: <Widget>[
                for (final Widget w in _buildAlbumStateWidgets(context))
                  SliverToBoxAdapter(child: w),
                if (!_loading && _images.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(14),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 9,
                        crossAxisSpacing: 9,
                      ),
                      itemCount: _images.length,
                      itemBuilder: (BuildContext context, int index) {
                        final AssetEntity image = _images[index];
                        return ImageSelectionTile(
                          key: ValueKey('recent-${image.id}'),
                          image: image,
                          selected: _selected.contains(image),
                          order: _selected.toList().indexOf(image) + 1,
                          removable: false,
                          desktopMode: true,
                          onTap: () => _toggle(image),
                          onPreview: () => _preview(image, pool: _images),
                        );
                      },
                    ),
                  ),
                if (_loadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitedPermissionTile(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.fill,
        borderRadius: TiebananaMetrics.brSm,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.photo_library_outlined,
            size: 18,
            color: tokens.textSecondary,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('目前只授权了部分照片',
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          TextButton(onPressed: _settings, child: const Text('管理权限')),
        ],
      ),
    );
  }

  List<Widget> _buildAlbumStateWidgets(BuildContext context) {
    if (_loading) {
      return const <Widget>[
        Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_permission?.hasAccess == false) {
      return <Widget>[
        ImagePickerStateView(
          title: '需要访问相册',
          message: '请在系统设置中允许访问照片，以便选择回复配图。',
          action: '去设置',
          onAction: _settings,
        ),
      ];
    }
    if (_images.isEmpty && _error == null) {
      return <Widget>[
        ImagePickerStateView(
          title: '相册里还没有照片',
          message: _permission == PermissionState.limited
              ? '只授权了部分照片，可以在设置中选择更多照片。'
              : '拍摄或保存图片后，刷新再试。',
          action: '刷新',
          onAction: () => _reload(),
        ),
      ];
    }
    if (_error != null) {
      return <Widget>[
        ImagePickerStateView(
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
      ];
    }
    return const <Widget>[];
  }

  // ================= 右侧停靠检视与顺序队列 =================

  Widget _buildInspectorPanel(
    BuildContext context, {
    required List<AssetEntity> selectedList,
    required bool compactHorizontal,
  }) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AssetEntity? focused = (_focused != null &&
            (_selected.contains(_focused) || _images.contains(_focused)))
        ? _focused
        : (selectedList.isNotEmpty ? selectedList.first : null);
    if (focused != null) _ensureMeta(focused);
    final ImageAssetMeta? meta =
        focused == null ? null : _metaCache[focused.id];
    final bool oversizeAvatar = widget.singleSelection &&
        meta?.sizeBytes != null &&
        meta!.sizeBytes! > _avatarMaxBytes;

    return DesktopPanel(
      borderRadius: TiebananaMetrics.brXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PanelHeader(
            title: widget.singleSelection ? '头像预览与校验' : '焦点预览与顺序',
            trailing: <Widget>[
              if (meta != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: tokens.fill,
                    borderRadius: TiebananaMetrics.brXs,
                  ),
                  child: Text(
                    meta.ext,
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          Divider(height: 1, color: tokens.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
            child: focused == null
                ? Container(
                    height: 148,
                    decoration: BoxDecoration(
                      color: tokens.fill.withValues(alpha: 0.65),
                      borderRadius: TiebananaMetrics.brSm,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.image_outlined,
                          size: 28,
                          color: tokens.textTertiary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '尚未选择图片',
                          style: textTheme.bodySmall?.copyWith(
                            color: tokens.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Center(
                        child: AspectRatio(
                          aspectRatio: widget.singleSelection ? 1.0 : 16 / 10,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: widget.singleSelection ? 210 : 400,
                            ),
                            child: Material(
                              color: tokens.bg,
                              borderRadius: TiebananaMetrics.brSm,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _preview(
                                  focused,
                                  pool: selectedList.isNotEmpty
                                      ? selectedList
                                      : _images,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: TiebananaMetrics.brSm,
                                    border: Border.all(color: tokens.line),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: <Widget>[
                                      _AssetPreviewImage(
                                        key: ValueKey('insp-${focused.id}'),
                                        asset: focused,
                                      ),
                                      Positioned(
                                        right: 8,
                                        bottom: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: tokens.imageScrim
                                                .withValues(alpha: 0.66),
                                            borderRadius:
                                                TiebananaMetrics.brPill,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Icon(
                                                Icons.zoom_in_rounded,
                                                size: 14,
                                                color: tokens.onImage,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '放大查看',
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                  fontSize: 10.5,
                                                  color: tokens.onImage,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MetaRow(label: '文件名', value: meta?.name ?? '读取中…'),
                      const SizedBox(height: 5),
                      _MetaRow(
                        label: '像素尺寸',
                        value: focused.width > 0 && focused.height > 0
                            ? '${focused.width} × ${focused.height} px'
                            : '未知尺寸',
                      ),
                      const SizedBox(height: 5),
                      _MetaRow(
                        label: '体积 / 格式',
                        value: meta == null
                            ? '读取中…'
                            : '${meta.formattedSize} · ${meta.ext}',
                      ),
                      if (widget.singleSelection) ...<Widget>[
                        const SizedBox(height: 10),
                        _InlineBanner(
                          icon: oversizeAvatar
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline_rounded,
                          text: oversizeAvatar
                              ? '超过 20 MB 上限（当前 ${meta.formattedSize}），请换选较小的图片。'
                              : '体积与格式符合要求，点击右下角「裁切头像」继续。',
                          danger: oversizeAvatar,
                        ),
                      ],
                    ],
                  ),
          ),
          if (!compactHorizontal &&
              !widget.singleSelection &&
              selectedList.isNotEmpty) ...<Widget>[
            Divider(height: 1, color: tokens.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 11, 15, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        '发送顺序（${selectedList.length}）',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '按此顺序插入正文',
                        style: textTheme.labelSmall?.copyWith(
                          color: tokens.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 196),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: selectedList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 5),
                      itemBuilder: (BuildContext context, int index) {
                        final AssetEntity item = selectedList[index];
                        _ensureMeta(item);
                        final ImageAssetMeta? itemMeta = _metaCache[item.id];
                        final bool isFocused = focused == item;
                        return Material(
                          color:
                              isFocused ? tokens.primaryContainer : tokens.bg,
                          borderRadius: TiebananaMetrics.brSm,
                          child: InkWell(
                            borderRadius: TiebananaMetrics.brSm,
                            onTap: () => _focusDesktopTile(item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 5,
                              ),
                              child: Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 18,
                                    child: Text(
                                      '${index + 1}',
                                      textAlign: TextAlign.center,
                                      style: textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: tokens.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: _AssetPreviewImage(
                                        key: ValueKey('q-${item.id}'),
                                        asset: item,
                                        fit: BoxFit.cover,
                                        thumbSize:
                                            const ThumbnailSize(120, 120),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text(
                                          itemMeta?.name ?? '图片 ${index + 1}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: tokens.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          item.width > 0 && item.height > 0
                                              ? '${item.width}×${item.height}'
                                              : (itemMeta?.formattedSize ?? ''),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.labelSmall?.copyWith(
                                            fontSize: 10.5,
                                            color: tokens.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 24,
                                      height: 24,
                                    ),
                                    padding: EdgeInsets.zero,
                                    tooltip: '上移',
                                    onPressed: index == 0
                                        ? null
                                        : () => _moveSelected(index, index - 1),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                      size: 16,
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 24,
                                      height: 24,
                                    ),
                                    padding: EdgeInsets.zero,
                                    tooltip: '下移',
                                    onPressed: index == selectedList.length - 1
                                        ? null
                                        : () => _moveSelected(index, index + 1),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 24,
                                      height: 24,
                                    ),
                                    padding: EdgeInsets.zero,
                                    tooltip: '移除',
                                    onPressed: () => _removeSelected(item),
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 15,
                                      color: tokens.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!compactHorizontal && !widget.singleSelection) ...<Widget>[
            Divider(height: 1, color: tokens.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '原图',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Text(
                          '保留原始分辨率与画质，上传较慢',
                          style: textTheme.labelSmall?.copyWith(
                            color: tokens.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _original,
                    onChanged: (bool value) =>
                        setState(() => _original = value),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================= 窄屏（< 720dp）保持原有移动体验 =================

  Widget _buildCompactDesktopFileScaffold(BuildContext context) {
    final List<AssetEntity> selectedList = _selected.toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.singleSelection ? '选择头像' : '选择图片')),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('选择文件'),
                  ),
                  Text('已选 ${_selected.length} 张'),
                  if (!widget.singleSelection) ...<Widget>[
                    const Text('原图'),
                    Switch(
                      value: _original,
                      onChanged: (bool value) =>
                          setState(() => _original = value),
                    ),
                  ],
                  if (_error != null) Text(_error!),
                ],
              ),
            ),
          ),
          if (selectedList.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildDesktopEmptyZone(context),
              ),
            )
          else
            _compactGrid(selectedList, selectedSection: true),
        ],
      ),
      bottomNavigationBar: ImagePickerFooter(
        count: _selected.length,
        singleSelection: widget.singleSelection,
        onConfirm: (_selected.isEmpty || _hasOversizeAvatar) ? null : _confirm,
      ),
    );
  }

  Widget _buildCompactAlbumScaffold(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.singleSelection ? '选择头像' : '图片上传'),
        actions: <Widget>[
          IconButton(
            tooltip: '刷新相册',
            onPressed: _loading ? null : () => _reload(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scroll,
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '已选 ${_selected.length} 张',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (!widget.singleSelection) const Text('原图'),
                  if (!widget.singleSelection)
                    Switch(
                      value: _original,
                      onChanged: (bool value) =>
                          setState(() => _original = value),
                    ),
                ],
              ),
            ),
          ),
          if (_selected.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  '从最近项目中选择图片，长按可预览',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: tokens.textTertiary),
                ),
              ),
            )
          else
            _compactGrid(_selected.toList(), selectedSection: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _album?.isAll == false ? _album!.name : '最近项目',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: _albums.isEmpty ? null : _chooseAlbum,
                    child: const Text('全部相册 ›'),
                  ),
                ],
              ),
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
                child: Center(child: CircularProgressIndicator()),
              ),
            )
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
          if (!_loading && _images.isNotEmpty) _compactGrid(_images),
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
              child: Center(child: CircularProgressIndicator()),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      bottomNavigationBar: ImagePickerFooter(
        count: _selected.length,
        singleSelection: widget.singleSelection,
        onConfirm: (_selected.isEmpty || _hasOversizeAvatar) ? null : _confirm,
      ),
    );
  }

  Widget _compactGrid(List<AssetEntity> images,
      {bool selectedSection = false}) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: images.length +
            (selectedSection && !widget.singleSelection ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index == images.length) {
            return Material(
              color: TiebananaTokens.of(context).fill,
              borderRadius: TiebananaMetrics.brCtl,
              child: InkWell(
                borderRadius: TiebananaMetrics.brCtl,
                onTap: () {
                  if (_usesFilePicker) {
                    _pickFiles();
                    return;
                  }
                  if (!_scroll.hasClients) return;
                  _scroll.animateTo(
                    ((_selected.length / 3).ceil() * 130.0)
                        .clamp(0.0, _scroll.position.maxScrollExtent),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                },
                child: const Center(child: Icon(Icons.add_rounded, size: 32)),
              ),
            );
          }
          final AssetEntity image = images[index];
          return ImageSelectionTile(
            key: ValueKey(
              '${selectedSection ? 'selected' : 'recent'}-${image.id}',
            ),
            image: image,
            selected: _selected.contains(image),
            order: _selected.toList().indexOf(image) + 1,
            removable: selectedSection,
            onTap: () => _toggle(image),
            onPreview: () => _preview(image, pool: images),
          );
        },
      ),
    );
  }
}

class _AddMoreTile extends StatelessWidget {
  const _AddMoreTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return CustomPaint(
      painter: DashedBorderPainter(
        color: tokens.lineStrong,
        radius: TiebananaMetrics.brCtl,
      ),
      child: Material(
        color: tokens.fill.withValues(alpha: 0.45),
        borderRadius: TiebananaMetrics.brCtl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.add_rounded, size: 26, color: tokens.textSecondary),
              const SizedBox(height: 4),
              Text(
                '添加图片',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetPreviewImage extends StatefulWidget {
  const _AssetPreviewImage({
    super.key,
    required this.asset,
    this.fit = BoxFit.contain,
    this.thumbSize = const ThumbnailSize(640, 640),
  });

  final AssetEntity asset;
  final BoxFit fit;
  final ThumbnailSize thumbSize;

  @override
  State<_AssetPreviewImage> createState() => _AssetPreviewImageState();
}

class _AssetPreviewImageState extends State<_AssetPreviewImage> {
  late final Future<Uint8List?> _thumb =
      widget.asset.thumbnailDataWithSize(widget.thumbSize);

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return FutureBuilder<Uint8List?>(
      future: _thumb,
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        if (snapshot.data == null) {
          return Center(
            child: Icon(Icons.image_outlined, color: tokens.textTertiary),
          );
        }
        return Image.memory(
          snapshot.data!,
          fit: widget.fit,
          gaplessPlayback: true,
        );
      },
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: tokens.textTertiary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: textTheme.labelSmall?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.icon,
    required this.text,
    this.danger = false,
  });

  final IconData icon;
  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Color tone = danger ? tokens.danger : tokens.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: TiebananaMetrics.brSm,
        border: Border.all(color: tone.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: tone),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tone,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 独立展示件便于在无相册插件的环境下验证状态与布局。
class ImagePickerStateView extends StatelessWidget {
  const ImagePickerStateView({
    super.key,
    required this.title,
    required this.message,
    required this.action,
    required this.onAction,
  });
  final String title;
  final String message;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.photo_library_outlined,
              size: 40,
              color: TiebananaTokens.of(context).textTertiary,
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      );
}

class ImagePickerFooter extends StatelessWidget {
  const ImagePickerFooter({
    super.key,
    required this.count,
    this.onConfirm,
    this.singleSelection = false,
  });
  final bool singleSelection;
  final int count;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final double width = MediaQuery.sizeOf(context).width;
    final bool desktop = AppBreakpoints.isDesktopWidth(width);
    final double hPad = desktop ? AppBreakpoints.pagePaddingFor(width) : 16;

    return Material(
      color: tokens.surface,
      child: DecoratedBox(
        decoration: desktop
            ? BoxDecoration(
                border: Border(top: BorderSide(color: tokens.line)),
              )
            : const BoxDecoration(),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    desktop ? AppBreakpoints.pageMaxWidth : double.infinity,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: hPad,
                  vertical: desktop ? 12 : 16,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        singleSelection ? '下一步裁切头像，不会立即上传' : '选择后返回回复框',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onConfirm,
                      child: Text(
                        count == 0
                            ? '请选择图片'
                            : singleSelection
                                ? '裁切头像'
                                : '添加（$count）',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ImageSelectionTile extends StatefulWidget {
  const ImageSelectionTile({
    super.key,
    required this.image,
    required this.selected,
    required this.order,
    required this.removable,
    required this.onTap,
    required this.onPreview,
    this.focused = false,
    this.desktopMode = false,
    this.onRemove,
    this.metaLabel,
    this.metaWarning = false,
  });
  final AssetEntity image;
  final bool selected;
  final int order;
  final bool removable;
  final VoidCallback onTap;
  final VoidCallback onPreview;
  final bool focused;
  final bool desktopMode;
  final VoidCallback? onRemove;
  final String? metaLabel;
  final bool metaWarning;

  @override
  State<ImageSelectionTile> createState() => _ImageSelectionTileState();
}

class _ImageSelectionTileState extends State<ImageSelectionTile> {
  late final Future<Uint8List?> _thumbnail = widget.image.thumbnailDataWithSize(
    widget.desktopMode
        ? const ThumbnailSize(512, 512)
        : const ThumbnailSize(320, 320),
  );
  bool _hovered = false;
  DateTime? _lastTapAt;

  void _handleTap() {
    widget.onTap();
    if (!widget.desktopMode) return;
    final DateTime now = DateTime.now();
    if (_lastTapAt != null &&
        now.difference(_lastTapAt!) <= const Duration(milliseconds: 280)) {
      _lastTapAt = null;
      widget.onPreview();
    } else {
      _lastTapAt = now;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool showOrderLeft =
        widget.desktopMode && widget.removable && widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: tokens.fill,
        borderRadius: TiebananaMetrics.brCtl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _handleTap,
          onLongPress: widget.onPreview,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              FutureBuilder<Uint8List?>(
                future: _thumbnail,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<Uint8List?> snapshot,
                ) =>
                    snapshot.data == null
                        ? const Icon(Icons.image_outlined)
                        : Image.memory(snapshot.data!, fit: BoxFit.cover),
              ),
              if (widget.selected || widget.focused)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.focused
                            ? tokens.primary
                            : tokens.primary.withValues(alpha: 0.72),
                        width: widget.focused ? 3 : 2,
                      ),
                      borderRadius: TiebananaMetrics.brCtl,
                    ),
                  ),
                ),
              if (showOrderLeft)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 24),
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: tokens.accentFill,
                      borderRadius: TiebananaMetrics.brPill,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.order}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: tokens.accentOn,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),
              Positioned(
                top: 6,
                right: 6,
                child: Semantics(
                  label: widget.removable ? '移除图片' : '选择第 ${widget.order} 张图片',
                  selected: widget.selected,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.removable && widget.onRemove != null
                        ? widget.onRemove
                        : null,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.removable && widget.desktopMode
                            ? tokens.imageScrim.withValues(alpha: 0.68)
                            : widget.selected
                                ? tokens.accentFill
                                : tokens.surface,
                      ),
                      alignment: Alignment.center,
                      child: widget.removable
                          ? Icon(
                              Icons.close_rounded,
                              size: 17,
                              color: widget.desktopMode
                                  ? tokens.onImage
                                  : tokens.accentOn,
                            )
                          : widget.selected
                              ? Text(
                                  '${widget.order}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: tokens.accentOn),
                                )
                              : Icon(
                                  Icons.circle_outlined,
                                  size: 22,
                                  color: tokens.textSecondary,
                                ),
                    ),
                  ),
                ),
              ),
              if (widget.metaLabel != null)
                Positioned(
                  left: 6,
                  bottom: 6,
                  right: 36,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.metaWarning
                            ? tokens.danger
                            : tokens.imageScrim.withValues(alpha: 0.65),
                        borderRadius: TiebananaMetrics.brXs,
                      ),
                      child: Text(
                        widget.metaLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: tokens.onImage,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
              if (widget.desktopMode && (_hovered || widget.focused))
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Material(
                    color: tokens.imageScrim.withValues(alpha: 0.66),
                    borderRadius: TiebananaMetrics.brXs,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: widget.onPreview,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.zoom_in_rounded,
                          size: 16,
                          color: tokens.onImage,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
