import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tiebanana/features/media/data/local_image_asset.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 从 [AssetEntity] / [LocalImageAsset] 读取的真实文件元信息。
class ImageAssetMeta {
  const ImageAssetMeta({
    required this.name,
    required this.ext,
    this.sizeBytes,
  });

  final String name;
  final String ext;
  final int? sizeBytes;

  String get formattedSize {
    final int? bytes = sizeBytes;
    if (bytes == null) return '未知大小';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  static String _extOf(String name) {
    final int dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return 'IMG';
    return name.substring(dot + 1).toUpperCase();
  }

  static Future<ImageAssetMeta> load(AssetEntity asset) async {
    if (asset is LocalImageAsset) {
      final String name =
          asset.title?.isNotEmpty == true ? asset.title! : 'image_${asset.id}';
      int? sizeBytes;
      try {
        if (await asset.localFile.exists()) {
          sizeBytes = await asset.localFile.length();
        }
      } catch (_) {}
      return ImageAssetMeta(
        name: name,
        ext: _extOf(name),
        sizeBytes: sizeBytes,
      );
    }
    String name = asset.title?.trim() ?? '';
    int? sizeBytes;
    try {
      final File? file = await asset.file;
      if (file != null) {
        if (name.isEmpty) {
          final List<String> parts = file.path.split(RegExp(r'[/\\]'));
          if (parts.isNotEmpty) name = parts.last;
        }
        if (await file.exists()) {
          sizeBytes = await file.length();
        }
      }
    } catch (_) {}
    if (name.isEmpty) name = '图片 ${asset.id}';
    return ImageAssetMeta(
      name: name,
      ext: _extOf(name),
      sizeBytes: sizeBytes,
    );
  }
}

/// 桌面端居中图片灯箱预览：支持滚轮缩放、键盘左右切换与 `Esc` 关闭。
Future<void> showImagePickerLightbox(
  BuildContext context, {
  required List<AssetEntity> images,
  required int initialIndex,
  required Map<String, ImageAssetMeta> metaCache,
  bool showToggleSelection = false,
  required bool Function(AssetEntity image) isSelected,
  required void Function(AssetEntity image) onToggleSelection,
}) {
  if (images.isEmpty) return Future<void>.value();
  final TiebananaTokens tokens = TiebananaTokens.of(context);
  return showDialog<void>(
    context: context,
    barrierColor: tokens.imageScrim.withValues(alpha: 0.56),
    builder: (BuildContext dialogContext) => _ImagePickerLightboxDialog(
      images: images,
      initialIndex: initialIndex.clamp(0, images.length - 1),
      metaCache: metaCache,
      showToggleSelection: showToggleSelection,
      isSelected: isSelected,
      onToggleSelection: onToggleSelection,
    ),
  );
}

class _ImagePickerLightboxDialog extends StatefulWidget {
  const _ImagePickerLightboxDialog({
    required this.images,
    required this.initialIndex,
    required this.metaCache,
    required this.showToggleSelection,
    required this.isSelected,
    required this.onToggleSelection,
  });

  final List<AssetEntity> images;
  final int initialIndex;
  final Map<String, ImageAssetMeta> metaCache;
  final bool showToggleSelection;
  final bool Function(AssetEntity image) isSelected;
  final void Function(AssetEntity image) onToggleSelection;

  @override
  State<_ImagePickerLightboxDialog> createState() =>
      _ImagePickerLightboxDialogState();
}

class _ImagePickerLightboxDialogState
    extends State<_ImagePickerLightboxDialog> {
  final TransformationController _transform = TransformationController();
  late int _index = widget.initialIndex;
  double _scale = 1.0;
  File? _file;
  Uint8List? _fallbackThumb;
  ImageAssetMeta? _meta;
  int _loadEpoch = 0;

  AssetEntity get _current => widget.images[_index];

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  Future<void> _loadCurrent() async {
    final int epoch = ++_loadEpoch;
    final AssetEntity asset = _current;
    _meta = widget.metaCache[asset.id];
    _file = null;
    _fallbackThumb = null;
    if (mounted) setState(() {});

    File? file;
    try {
      file = await asset.file;
    } catch (_) {}
    Uint8List? thumb;
    if (file == null) {
      try {
        thumb =
            await asset.thumbnailDataWithSize(const ThumbnailSize(960, 960));
      } catch (_) {}
    }
    final ImageAssetMeta meta =
        widget.metaCache[asset.id] ?? await ImageAssetMeta.load(asset);
    widget.metaCache[asset.id] = meta;
    if (!mounted || epoch != _loadEpoch) return;
    setState(() {
      _file = file;
      _fallbackThumb = thumb;
      _meta = meta;
    });
  }

  void _setScale(double next) {
    final double clamped = next.clamp(1.0, 3.0);
    setState(() => _scale = clamped);
    _transform.value = Matrix4.diagonal3Values(clamped, clamped, 1.0);
  }

  void _step(int delta) {
    if (widget.images.length <= 1) return;
    setState(() {
      _index = (_index + delta + widget.images.length) % widget.images.length;
      _scale = 1.0;
      _transform.value = Matrix4.identity();
    });
    _loadCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Size size = MediaQuery.sizeOf(context);
    final AssetEntity asset = _current;
    final ImageAssetMeta? meta = _meta ?? widget.metaCache[asset.id];
    final String title = meta?.name ?? '图片预览';
    final String dimText = asset.width > 0 && asset.height > 0
        ? '${asset.width} × ${asset.height}'
        : '';
    final String subtitle = <String>[
      if (dimText.isNotEmpty) dimText,
      if (meta?.sizeBytes != null) meta!.formattedSize,
      if (meta != null) meta.ext,
    ].join(' · ');
    final bool selected = widget.isSelected(asset);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _step(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _step(1),
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          backgroundColor: tokens.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 18,
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: tokens.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 820,
              maxHeight: size.height * 0.86,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textPrimary,
                                  ),
                            ),
                            if (subtitle.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: tokens.textTertiary),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '关闭 (Esc)',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: tokens.line),
                Flexible(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 320),
                    color: tokens.imageScrim.withValues(alpha: 0.92),
                    child: Listener(
                      onPointerSignal: (PointerSignalEvent event) {
                        if (event is PointerScrollEvent) {
                          final double delta =
                              event.scrollDelta.dy < 0 ? 0.2 : -0.2;
                          _setScale(_scale + delta);
                        }
                      },
                      child: InteractiveViewer(
                        transformationController: _transform,
                        minScale: 1.0,
                        maxScale: 3.0,
                        child: Center(
                          child: _file != null
                              ? Image.file(
                                  _file!,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.broken_image_outlined,
                                    size: 48,
                                    color: tokens.onImage,
                                  ),
                                )
                              : _fallbackThumb != null
                                  ? Image.memory(
                                      _fallbackThumb!,
                                      fit: BoxFit.contain,
                                    )
                                  : Icon(
                                      Icons.image_outlined,
                                      size: 48,
                                      color:
                                          tokens.onImage.withValues(alpha: 0.7),
                                    ),
                        ),
                      ),
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: tokens.line),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextButton.icon(
                            onPressed: widget.images.length <= 1
                                ? null
                                : () => _step(-1),
                            icon: const Icon(Icons.chevron_left_rounded,
                                size: 18),
                            label: const Text('上一张'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '${_index + 1} / ${widget.images.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                color: tokens.textSecondary,
                                fontFeatures: const <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: widget.images.length <= 1
                                ? null
                                : () => _step(1),
                            icon: const Icon(Icons.chevron_right_rounded,
                                size: 18),
                            iconAlignment: IconAlignment.end,
                            label: const Text('下一张'),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            tooltip: '缩小',
                            onPressed: _scale <= 1.0
                                ? null
                                : () => _setScale(_scale - 0.25),
                            icon: const Icon(Icons.remove_rounded, size: 18),
                          ),
                          Text(
                            '${(_scale * 100).round()}%',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                              color: tokens.textSecondary,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: '放大',
                            onPressed: _scale >= 3.0
                                ? null
                                : () => _setScale(_scale + 0.25),
                            icon: const Icon(Icons.add_rounded, size: 18),
                          ),
                          TextButton(
                            onPressed:
                                _scale == 1.0 ? null : () => _setScale(1.0),
                            child: const Text('1:1'),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (widget.showToggleSelection) ...<Widget>[
                            FilledButton.tonal(
                              onPressed: () {
                                widget.onToggleSelection(asset);
                                setState(() {});
                              },
                              child: Text(selected ? '移出已选' : '选择图片'),
                            ),
                            const SizedBox(width: TiebananaMetrics.gapSm),
                          ],
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('关闭'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
