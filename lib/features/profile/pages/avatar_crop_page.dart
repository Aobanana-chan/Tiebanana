import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

const int _maxInputBytes = 20 * 1024 * 1024;
const int _maxInputPixels = 24 * 1024 * 1024;
const double _maxZoom = 8;

img.Image _decodeAvatar(Uint8List bytes) {
  if (bytes.isEmpty) throw const FormatException('图片为空，请重新选择');
  if (bytes.length > _maxInputBytes) {
    throw const FormatException('图片超过20MB，请选择较小的图片');
  }
  try {
    final decoder = img.findDecoderForData(bytes);
    final info = decoder?.startDecode(bytes);
    if (info == null) throw const FormatException('无法读取图片，请重新选择');
    // Read dimensions before allocating a full decoded pixel buffer.
    if (info.width <= 0 ||
        info.height <= 0 ||
        info.width > 16384 ||
        info.height > 16384 ||
        info.width * info.height > _maxInputPixels) {
      throw const FormatException('图片尺寸过大，请选择较小的图片');
    }
    // Decode only the first frame, never a complete animation.
    final decoded = decoder!.decodeFrame(0);
    if (decoded == null) throw const FormatException('无法读取图片，请重新选择');
    return img.bakeOrientation(decoded);
  } on FormatException {
    rethrow;
  } catch (_) {
    throw const FormatException('无法读取图片，请重新选择');
  }
}

/// Pure square crop in the orientation-corrected image coordinate space.
///
/// [centerX] and [centerY] are normalized image coordinates. [zoom] is relative
/// to the largest square fitting inside the image (1–8). Out-of-bounds centers
/// are clamped so no empty border can appear. Invalid input throws
/// [FormatException]; invalid output/transform settings throw [ArgumentError].
Uint8List cropAvatarImage(
  Uint8List imageBytes, {
  double centerX = .5,
  double centerY = .5,
  double zoom = 1,
  int outputSize = 960,
  int quality = 80,
}) {
  if (outputSize < 1 || outputSize > 4096) {
    throw ArgumentError.value(outputSize, 'outputSize', '必须在1至4096之间');
  }
  if (quality < 1 || quality > 100) {
    throw ArgumentError.value(quality, 'quality', '必须在1至100之间');
  }
  if (!centerX.isFinite ||
      !centerY.isFinite ||
      !zoom.isFinite ||
      zoom < 1 ||
      zoom > _maxZoom) {
    throw ArgumentError('裁切位置或缩放比例无效');
  }
  final image = _decodeAvatar(imageBytes);
  final side =
      math.max(1, (math.min(image.width, image.height) / zoom).round());
  final x = (centerX.clamp(0.0, 1.0) * image.width - side / 2)
      .round()
      .clamp(0, image.width - side);
  final y = (centerY.clamp(0.0, 1.0) * image.height - side / 2)
      .round()
      .clamp(0, image.height - side);
  final cropped = img.copyCrop(image, x: x, y: y, width: side, height: side);
  final resized = img.copyResize(cropped,
      width: outputSize,
      height: outputSize,
      interpolation: img.Interpolation.linear);
  // JPEG has no alpha. Composite transparent pixels onto white, not black.
  final opaque = img.Image(width: outputSize, height: outputSize);
  img.fill(opaque, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(opaque, resized);
  opaque.exif = img.ExifData();
  return Uint8List.fromList(img.encodeJpg(opaque, quality: quality));
}

typedef _Preview = ({Uint8List bytes, int width, int height});
typedef _CropRequest = ({
  Uint8List bytes,
  double x,
  double y,
  double zoom,
  int outputSize,
  int quality
});

_Preview _preparePreview(Uint8List bytes) {
  final image = _decodeAvatar(bytes);
  final preview = math.max(image.width, image.height) > 1280
      ? img.copyResize(image,
          width: image.width >= image.height ? 1280 : null,
          height: image.height > image.width ? 1280 : null)
      : image;
  return (
    bytes: Uint8List.fromList(img.encodePng(preview)),
    width: image.width,
    height: image.height
  );
}

Uint8List _cropRequest(_CropRequest request) => cropAvatarImage(request.bytes,
    centerX: request.x,
    centerY: request.y,
    zoom: request.zoom,
    outputSize: request.outputSize,
    quality: request.quality);

/// Returns JPEG bytes through Navigator.pop; cancellation returns null.
class AvatarCropPage extends StatefulWidget {
  const AvatarCropPage(
      {super.key,
      required this.imageBytes,
      this.outputSize = 960,
      this.quality = 80});

  final Uint8List imageBytes;
  final int outputSize;
  final int quality;

  @override
  State<AvatarCropPage> createState() => _AvatarCropPageState();
}

class _AvatarCropPageState extends State<AvatarCropPage> {
  _Preview? _preview;
  String? _error;
  bool _saving = false;
  bool _allowPop = false;
  Offset _center = Offset.zero;
  double _zoom = 1;
  double _startZoom = 1;
  Offset _anchor = Offset.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preview = await compute(_preparePreview, widget.imageBytes);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _center = Offset(preview.width / 2, preview.height / 2);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() =>
          _error = error is FormatException ? error.message : '无法读取图片，请重新选择');
    }
  }

  Offset _clampCenter(Offset center, double zoom) {
    final p = _preview!;
    final half = math.min(p.width, p.height) / zoom / 2;
    return Offset(center.dx.clamp(half, p.width - half),
        center.dy.clamp(half, p.height - half));
  }

  Future<void> _useAvatar() async {
    if (_saving || _preview == null) return;
    setState(() => _saving = true);
    try {
      final bytes = await compute(_cropRequest, (
        bytes: widget.imageBytes,
        x: _center.dx / _preview!.width,
        y: _center.dy / _preview!.height,
        zoom: _zoom,
        outputSize: widget.outputSize,
        quality: widget.quality,
      ));
      if (!mounted) return;
      setState(() => _allowPop = true);
      // PopScope must rebuild before the successful programmatic pop.
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('头像处理失败，请重试或选择其他图片')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TiebananaTokens.of(context);
    return PopScope<Uint8List>(
      canPop: !_saving || _allowPop,
      child: Scaffold(
        backgroundColor: tokens.bg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: tokens.bg,
          foregroundColor: tokens.textPrimary,
          surfaceTintColor: tokens.bg.withValues(alpha: 0),
          toolbarHeight: TiebananaMetrics.appBarHeight +
              (MediaQuery.textScalerOf(context).scale(20) - 20)
                  .clamp(0.0, double.infinity),
          leadingWidth: 72,
          leading: TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('取消')),
          title: const Text('裁切头像'),
          actions: <Widget>[
            TextButton(
              onPressed: _saving || _preview == null ? null : _useAvatar,
              style: TextButton.styleFrom(
                  foregroundColor: tokens.primary,
                  disabledForegroundColor: tokens.textTertiary),
              child: Text(_saving ? '处理中…' : '使用头像'),
            ),
            const SizedBox(width: TiebananaMetrics.gapSm),
          ],
        ),
        body: SafeArea(
          top: false,
          child: _error != null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(TiebananaMetrics.gapXl),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: tokens.textSecondary))))
              : _preview == null
                  ? const Center(
                      child:
                          CircularProgressIndicator(semanticsLabel: '正在读取图片'))
                  : _editor(context),
        ),
      ),
    );
  }

  Widget _editor(BuildContext context) {
    final tokens = TiebananaTokens.of(context);
    final p = _preview!;
    return Column(children: <Widget>[
      Expanded(
          child: Padding(
        padding: const EdgeInsets.all(TiebananaMetrics.gapLg),
        child: LayoutBuilder(builder: (context, constraints) {
          final side = math.min(constraints.maxWidth, constraints.maxHeight);
          final scale = side / math.min(p.width, p.height) * _zoom;
          return Center(
              child: SizedBox.square(
            dimension: side,
            child: Semantics(
              label: '头像裁切区域，可拖动和双指缩放',
              image: true,
              child: GestureDetector(
                key: const ValueKey('avatar-crop-gesture'),
                behavior: HitTestBehavior.opaque,
                onScaleStart: _saving
                    ? null
                    : (details) {
                        _startZoom = _zoom;
                        _anchor = _center +
                            (details.localFocalPoint -
                                    Offset(side / 2, side / 2)) /
                                scale;
                      },
                onScaleUpdate: _saving
                    ? null
                    : (details) {
                        final zoom =
                            (_startZoom * details.scale).clamp(1.0, _maxZoom);
                        final nextScale =
                            side / math.min(p.width, p.height) * zoom;
                        setState(() {
                          _zoom = zoom;
                          _center = _clampCenter(
                              _anchor -
                                  (details.localFocalPoint -
                                          Offset(side / 2, side / 2)) /
                                      nextScale,
                              zoom);
                        });
                      },
                child: ClipRect(
                    child: Stack(children: <Widget>[
                  Positioned(
                    left: side / 2 - _center.dx * scale,
                    top: side / 2 - _center.dy * scale,
                    width: p.width * scale,
                    height: p.height * scale,
                    child: Image.memory(p.bytes,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                        excludeFromSemantics: true),
                  ),
                  Positioned.fill(
                      child: IgnorePointer(
                          child: DecoratedBox(
                    decoration: BoxDecoration(
                        border: Border.all(color: tokens.primary, width: 2)),
                  ))),
                ])),
              ),
            ),
          ));
        }),
      )),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: TiebananaMetrics.gapLg),
        child: Row(children: <Widget>[
          Icon(Icons.zoom_out, color: tokens.textSecondary),
          Expanded(
              child: Slider(
            value: _zoom,
            min: 1,
            max: _maxZoom,
            semanticFormatterCallback: (value) =>
                '${value.toStringAsFixed(1)}倍',
            onChanged: _saving
                ? null
                : (value) => setState(() {
                      _zoom = value;
                      _center = _clampCenter(_center, value);
                    }),
          )),
          Icon(Icons.zoom_in, color: tokens.textSecondary),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(TiebananaMetrics.gapLg, 0,
            TiebananaMetrics.gapLg, TiebananaMetrics.gapXl),
        child: Text(_saving ? '正在生成头像，请稍候' : '拖动调整位置，双指或滑块缩放\n点击「使用头像」后上传到贴吧',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: tokens.textSecondary)),
      ),
    ]);
  }
}

/// 桌面端居中头像裁切弹窗（520dp 宽），复用 [cropAvatarImage] 逻辑。
Future<Uint8List?> showAvatarCropDialog(
  BuildContext context, {
  required Uint8List imageBytes,
  int outputSize = 960,
  int quality = 80,
  Future<Uint8List?> Function()? onRepick,
}) {
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) => AvatarCropDialog(
      imageBytes: imageBytes,
      outputSize: outputSize,
      quality: quality,
      onRepick: onRepick,
    ),
  );
}

class AvatarCropDialog extends StatefulWidget {
  const AvatarCropDialog({
    super.key,
    required this.imageBytes,
    this.outputSize = 960,
    this.quality = 80,
    this.onRepick,
  });

  final Uint8List imageBytes;
  final int outputSize;
  final int quality;
  final Future<Uint8List?> Function()? onRepick;

  @override
  State<AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<AvatarCropDialog> {
  late Uint8List _sourceBytes = widget.imageBytes;
  _Preview? _preview;
  String? _error;
  bool _saving = false;
  bool _repicking = false;
  Offset _center = Offset.zero;
  double _zoom = 1;
  double _startZoom = 1;
  Offset _anchor = Offset.zero;
  int _loadEpoch = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final int epoch = ++_loadEpoch;
    try {
      final _Preview preview = await compute(_preparePreview, _sourceBytes);
      if (!mounted || epoch != _loadEpoch) return;
      setState(() {
        _preview = preview;
        _error = null;
        _zoom = 1;
        _center = Offset(preview.width / 2, preview.height / 2);
      });
    } catch (error) {
      if (!mounted || epoch != _loadEpoch) return;
      setState(() {
        _preview = null;
        _error = error is FormatException ? error.message : '无法读取图片，请重新选择';
      });
    }
  }

  Offset _clampCenter(Offset center, double zoom) {
    final _Preview p = _preview!;
    final double half = math.min(p.width, p.height) / zoom / 2;
    return Offset(
      center.dx.clamp(half, p.width - half),
      center.dy.clamp(half, p.height - half),
    );
  }

  Future<void> _repick() async {
    if (_saving || _repicking || widget.onRepick == null) return;
    setState(() => _repicking = true);
    try {
      final Uint8List? next = await widget.onRepick!();
      if (!mounted || next == null) return;
      setState(() {
        _sourceBytes = next;
        _preview = null;
        _error = null;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error is StateError ? error.message : '无法读取图片，请重试')),
      );
    } finally {
      if (mounted) setState(() => _repicking = false);
    }
  }

  Future<void> _useAvatar() async {
    if (_saving || _repicking || _preview == null) return;
    setState(() => _saving = true);
    try {
      final Uint8List bytes = await compute(_cropRequest, (
        bytes: _sourceBytes,
        x: _center.dx / _preview!.width,
        y: _center.dy / _preview!.height,
        zoom: _zoom,
        outputSize: widget.outputSize,
        quality: widget.quality,
      ));
      if (!mounted) return;
      Navigator.pop(context, bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('头像处理失败，请重试或选择其他图片')),
      );
    }
  }

  Widget _croppedPreviewBox(double side, BorderRadius radius) {
    final _Preview p = _preview!;
    final double scale = side / math.min(p.width, p.height) * _zoom;
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox.square(
        dimension: side,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: side / 2 - _center.dx * scale,
              top: side / 2 - _center.dy * scale,
              width: p.width * scale,
              height: p.height * scale,
              child: Image.memory(
                p.bytes,
                fit: BoxFit.fill,
                gaplessPlayback: true,
                excludeFromSemantics: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return PopScope<Uint8List>(
      canPop: !_saving && !_repicking,
      child: Dialog(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(TiebananaMetrics.gapXl),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.line),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(18, 13, 10, 13),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: tokens.line)),
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      '裁切头像',
                      style: text.titleSmall?.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '正方形 ${widget.outputSize}×${widget.outputSize} · JPG',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          fontSize: 11,
                          color: tokens.textTertiary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭 (Esc)',
                      onPressed: _saving || _repicking
                          ? null
                          : () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded,
                          size: 18, color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: _error != null
                      ? SizedBox(
                          height: 240,
                          child: Center(
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: text.bodyMedium
                                  ?.copyWith(color: tokens.textSecondary),
                            ),
                          ),
                        )
                      : _preview == null
                          ? const SizedBox(
                              height: 280,
                              child: Center(
                                child: CircularProgressIndicator(
                                    semanticsLabel: '正在读取图片'),
                              ),
                            )
                          : _buildBody(context, tokens, text),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: tokens.line)),
                ),
                child: Row(
                  children: <Widget>[
                    if (widget.onRepick != null)
                      OutlinedButton(
                        onPressed: _saving || _repicking ? null : _repick,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: tokens.textSecondary,
                          side: BorderSide(color: tokens.line),
                          shape: RoundedRectangleBorder(
                              borderRadius: TiebananaMetrics.brSm),
                        ),
                        child: Text(_repicking ? '选择中…' : '重新选图'),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: _saving || _repicking
                          ? null
                          : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                          foregroundColor: tokens.textSecondary),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _saving || _repicking || _preview == null
                          ? null
                          : _useAvatar,
                      style: FilledButton.styleFrom(
                        backgroundColor: tokens.primary,
                        foregroundColor: tokens.accentOn,
                        shape: RoundedRectangleBorder(
                            borderRadius: TiebananaMetrics.brSm),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(_saving ? '处理中…' : '使用并上传'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, TiebananaTokens tokens, TextTheme text) {
    final _Preview p = _preview!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool sideBySide = constraints.maxWidth >= 430;
            final double boxSide = sideBySide ? 280 : constraints.maxWidth;
            final double scale = boxSide / math.min(p.width, p.height) * _zoom;
            final Widget cropBox = SizedBox.square(
              dimension: boxSide,
              child: Listener(
                onPointerSignal: _saving
                    ? null
                    : (PointerSignalEvent event) {
                        if (event is PointerScrollEvent) {
                          final double delta =
                              event.scrollDelta.dy < 0 ? 0.2 : -0.2;
                          final double nextZoom =
                              (_zoom + delta).clamp(1.0, _maxZoom);
                          setState(() {
                            _zoom = nextZoom;
                            _center = _clampCenter(_center, nextZoom);
                          });
                        }
                      },
                child: Semantics(
                  label: '头像裁切区域，可拖动和滚轮缩放',
                  image: true,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: GestureDetector(
                      key: const ValueKey('avatar-crop-gesture'),
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: _saving
                          ? null
                          : (ScaleStartDetails details) {
                              _startZoom = _zoom;
                              _anchor = _center +
                                  (details.localFocalPoint -
                                          Offset(boxSide / 2, boxSide / 2)) /
                                      scale;
                            },
                      onScaleUpdate: _saving
                          ? null
                          : (ScaleUpdateDetails details) {
                              final double zoom = (_startZoom * details.scale)
                                  .clamp(1.0, _maxZoom);
                              final double nextScale =
                                  boxSide / math.min(p.width, p.height) * zoom;
                              setState(() {
                                _zoom = zoom;
                                _center = _clampCenter(
                                  _anchor -
                                      (details.localFocalPoint -
                                              Offset(
                                                  boxSide / 2, boxSide / 2)) /
                                          nextScale,
                                  zoom,
                                );
                              });
                            },
                      child: ClipRRect(
                        borderRadius: TiebananaMetrics.brMd,
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: ColoredBox(color: tokens.surfaceAlt),
                            ),
                            Positioned(
                              left: boxSide / 2 - _center.dx * scale,
                              top: boxSide / 2 - _center.dy * scale,
                              width: p.width * scale,
                              height: p.height * scale,
                              child: Image.memory(
                                p.bytes,
                                fit: BoxFit.fill,
                                gaplessPlayback: true,
                                excludeFromSemantics: true,
                              ),
                            ),
                            const Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(painter: _CropGridPainter()),
                              ),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: TiebananaMetrics.brMd,
                                    border: Border.all(
                                        color: tokens.primary, width: 2),
                                  ),
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
            );

            final Widget previewSide = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.fill,
                    borderRadius: TiebananaMetrics.brSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '裁切效果预览',
                        style: text.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: tokens.line),
                            ),
                            child: _croppedPreviewBox(
                                56, BorderRadius.circular(13)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('个人主页',
                                    style: text.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: tokens.textPrimary,
                                    )),
                                Text('圆角方形 84px',
                                    style: text.bodySmall?.copyWith(
                                      fontSize: 10.5,
                                      color: tokens.textTertiary,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: tokens.line),
                            ),
                            child: _croppedPreviewBox(
                                36, BorderRadius.circular(18)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('帖子与评论',
                                    style: text.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: tokens.textPrimary,
                                    )),
                                Text('圆形头像 36px',
                                    style: text.bodySmall?.copyWith(
                                      fontSize: 10.5,
                                      color: tokens.textTertiary,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '拖动取景框调整位置，滚轮或下方滑块缩放（1.0× – 8.0×）。确认后将压缩为 JPG 并直接上传到贴吧。',
                  style: text.bodySmall?.copyWith(
                    fontSize: 11,
                    height: 1.55,
                    color: tokens.textTertiary,
                  ),
                ),
              ],
            );

            if (sideBySide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  cropBox,
                  const SizedBox(width: 16),
                  Expanded(child: previewSide),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(child: cropBox),
                const SizedBox(height: 14),
                previewSide,
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: tokens.fill,
            borderRadius: TiebananaMetrics.brSm,
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.zoom_out_rounded,
                  size: 18, color: tokens.textSecondary),
              Expanded(
                child: Slider(
                  value: _zoom,
                  min: 1,
                  max: _maxZoom,
                  semanticFormatterCallback: (double value) =>
                      '${value.toStringAsFixed(1)}倍',
                  onChanged: _saving
                      ? null
                      : (double value) => setState(() {
                            _zoom = value;
                            _center = _clampCenter(_center, value);
                          }),
                ),
              ),
              Icon(Icons.zoom_in_rounded,
                  size: 18, color: tokens.textSecondary),
              const SizedBox(width: 8),
              SizedBox(
                width: 38,
                child: Text(
                  '${_zoom.toStringAsFixed(1)}×',
                  textAlign: TextAlign.right,
                  style: text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.textSecondary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CropGridPainter extends CustomPainter {
  const _CropGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0x5CFFFFFF)
      ..strokeWidth = 1;
    final double thirdW = size.width / 3;
    final double thirdH = size.height / 3;
    canvas.drawLine(Offset(thirdW, 0), Offset(thirdW, size.height), paint);
    canvas.drawLine(
        Offset(thirdW * 2, 0), Offset(thirdW * 2, size.height), paint);
    canvas.drawLine(Offset(0, thirdH), Offset(size.width, thirdH), paint);
    canvas.drawLine(
        Offset(0, thirdH * 2), Offset(size.width, thirdH * 2), paint);
  }

  @override
  bool shouldRepaint(_CropGridPainter oldDelegate) => false;
}
