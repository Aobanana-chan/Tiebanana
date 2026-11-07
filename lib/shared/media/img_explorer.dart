import 'dart:ui' show ImageFilter;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

// 媒体覆盖层固定黑底，控件使用白色。
const _ink = Colors.white;
const _backdrop = Colors.black;
const _placeholder = Color(0xFF1B1B1F);

/// 图片由 Hero 展开/回缩，背景与控件单独淡入淡出。
class ImageExplorerRoute extends PageRouteBuilder<void> {
  ImageExplorerRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        );
}

/// 头像等单图入口，与贴内多图共用同一套浏览界面。
class ImgExplorer extends StatelessWidget {
  final String heroTagSalt;

  /// 固定回到点击入口，切页或切换预览图/原图时保持不变。
  final Object? heroTag;
  final String imgUrl;
  final String? highQualityUrl;

  const ImgExplorer({
    super.key,
    required this.imgUrl,
    this.highQualityUrl,
    required this.heroTagSalt,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) => ZoomedImgExplorer(
        imgUrls: [imgUrl],
        highQualityUrls: [highQualityUrl],
        heroTagSalt: heroTagSalt,
        heroTag: heroTag,
      );
}

class ZoomedImgExplorer extends StatefulWidget {
  final List<String> imgUrls;
  final List<String?>? highQualityUrls;
  final ExtendedPageController? pageController;
  final int index;
  final String heroTagSalt;
  final Object? heroTag;

  const ZoomedImgExplorer({
    super.key,
    required this.imgUrls,
    this.pageController,
    this.index = 0,
    this.highQualityUrls,
    required this.heroTagSalt,
    this.heroTag,
  });

  @override
  State<ZoomedImgExplorer> createState() => _ZoomedImgExplorerState();
}

class _ZoomedImgExplorerState extends State<ZoomedImgExplorer> {
  late final ExtendedPageController _pages;
  final _thumbnails = ScrollController();
  final _originals = <int>{};
  final _failedOriginals = <int>{};
  final _loaded = <String, int?>{};
  late int _current;
  late final Object? _heroTag;
  bool _saving = false;
  bool _controlsVisible = true;
  bool _thumbnailsVisible = false;

  String? _original(int index) {
    final urls = widget.highQualityUrls;
    if (urls == null || index >= urls.length) return null;
    final url = urls[index];
    return url == null || url.isEmpty ? null : url;
  }

  String _source(int index) {
    final original = _original(index);
    final autoOriginal = Global.setting.pictureLoadSetting == 2 ||
        (Global.setting.pictureLoadSetting == 0 &&
            !Global.netStatus.contains(ConnectivityResult.mobile));
    return original != null &&
            !_failedOriginals.contains(index) &&
            (autoOriginal || _originals.contains(index))
        ? original
        : widget.imgUrls[index];
  }

  @override
  void initState() {
    super.initState();
    _current = widget.imgUrls.isEmpty
        ? 0
        : (widget.pageController?.initialPage ?? widget.index)
            .clamp(0, widget.imgUrls.length - 1);
    _pages =
        widget.pageController ?? ExtendedPageController(initialPage: _current);
    _heroTag = widget.heroTag ??
        (widget.imgUrls.isEmpty
            ? null
            : widget.imgUrls[_current] + widget.heroTagSalt);
    _checkCache();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealThumbnail());
  }

  Future<void> _checkCache() async {
    for (var i = 0; i < widget.imgUrls.length; i++) {
      final url = _original(i);
      if (url == null) continue;
      final file = await getCachedImageFile(url);
      if (!mounted) return;
      if (file != null) {
        final length = await file.length();
        if (!mounted) return;
        setState(() {
          _originals.add(i);
          _loaded[url] = length;
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.pageController == null) _pages.dispose();
    _thumbnails.dispose();
    super.dispose();
  }

  void _revealThumbnail() {
    if (!mounted || !_thumbnails.hasClients) return;
    final position = _thumbnails.position;
    final target = (8 + _current * 52 + 24 - position.viewportDimension / 2)
        .clamp(0.0, position.maxScrollExtent);
    _thumbnails.animateTo(target,
        duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
  }

  void _toggleThumbnails() {
    setState(() => _thumbnailsVisible = !_thumbnailsVisible);
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealThumbnail());
  }

  Widget _chrome(Widget child) => IgnorePointer(
        ignoring: !_controlsVisible,
        child: AnimatedOpacity(
          opacity: _controlsVisible ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          child: child,
        ),
      );

  ButtonStyle get _overlayButtonStyle => TextButton.styleFrom(
        foregroundColor: _ink,
        disabledForegroundColor: _ink.withValues(alpha: .6),
        backgroundColor: _backdrop.withValues(alpha: .36),
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        shape: StadiumBorder(
          side: BorderSide(color: _ink.withValues(alpha: .1)),
        ),
      );

  Widget _glass(Widget child, {double radius = 24}) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: child,
        ),
      );

  void _viewOriginal() => setState(() {
        _failedOriginals.remove(_current);
        _originals.add(_current);
      });

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    if (_saving || widget.imgUrls.isEmpty) return;
    // 保存动作锁定点击时的图片，切页不改变正在保存的目标。
    final url = _original(_current) ?? widget.imgUrls[_current];
    setState(() => _saving = true);
    try {
      final permission = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          iosAccessLevel: IosAccessLevel.addOnly,
          androidPermission: AndroidPermission(
            type: RequestType.image,
            mediaLocation: false,
          ),
        ),
      );
      if (!permission.isAuth && !permission.hasAccess) {
        _message('需要相册权限才能保存图片，请在系统设置中允许');
        return;
      }
      final data = await getNetworkImageData(url);
      if (data == null || data.isEmpty) throw StateError('图片下载失败');
      await PhotoManager.editor.saveImage(data,
          filename: '${keyToMd5(url)}.jpg', title: keyToMd5(url));
      _message('图片已保存到相册');
    } catch (_) {
      _message('保存失败，请检查网络和相册权限后重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _sizeLabel(String url) {
    final bytes = _loaded[url];
    if (bytes == null) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: TiebananaTheme.dark(
          seedOf(Global.setting.theme),
          Global.setting.fontSize,
        ),
        child: Builder(builder: _buildViewer),
      );

  Widget _buildViewer(BuildContext context) {
    final hasImages = widget.imgUrls.isNotEmpty;
    final original = hasImages ? _original(_current) : null;
    final source = hasImages ? _source(_current) : '';
    final loadingOriginal = original != null &&
        source == original &&
        !_loaded.containsKey(original);
    final canViewOriginal = original != null && source != original;
    final sizeLabel = _sizeLabel(original ?? source);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _backdrop,
      ),
      child: Scaffold(
        backgroundColor: _backdrop,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: hasImages
                    ? ExtendedImageGesturePageView.builder(
                        controller: _pages,
                        itemCount: widget.imgUrls.length,
                        onPageChanged: (index) {
                          setState(() => _current = index);
                          _revealThumbnail();
                        },
                        itemBuilder: (context, index) => HeroMode(
                          enabled: index == _current,
                          child: Hero(
                            tag: _heroTag!,
                            flightShuttleBuilder: (flightContext, animation,
                                direction, fromContext, toContext) {
                              // 回缩沿用浏览中的图片，切页时画面连续。
                              final hero = (direction == HeroFlightDirection.pop
                                  ? fromContext.widget
                                  : toContext.widget) as Hero;
                              return hero.child;
                            },
                            child: _ExplorerImage(
                              key: ValueKey(index),
                              url: _source(index),
                              preview: widget.imgUrls[index],
                              onTap: () => setState(
                                  () => _controlsVisible = !_controlsVisible),
                              isOriginal: _source(index) == _original(index),
                              onLoaded: (url, bytes) {
                                if (!mounted ||
                                    (_loaded.containsKey(url) &&
                                        (bytes == null ||
                                            _loaded[url] == bytes))) {
                                  return;
                                }
                                setState(() => _loaded[url] = bytes);
                              },
                              onOriginalFailed: () {
                                if (!mounted) return;
                                setState(() => _failedOriginals.add(index));
                                _message('原图加载失败，已显示预览图，可重试');
                              },
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Text('暂无图片', style: TextStyle(color: _ink))),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: _chrome(Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(children: [
                    Expanded(
                        child: Align(
                      heightFactor: 1,
                      alignment: Alignment.centerLeft,
                      child: _glass(IconButton(
                        tooltip: '返回',
                        onPressed: () => Navigator.maybePop(context),
                        style: IconButton.styleFrom(
                          foregroundColor: _ink,
                          backgroundColor: _backdrop.withValues(alpha: .36),
                          fixedSize: const Size(44, 44),
                          side: BorderSide(color: _ink.withValues(alpha: .1)),
                        ),
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      )),
                    )),
                    if (widget.imgUrls.length > 1)
                      Semantics(
                        expanded: _thumbnailsVisible,
                        child: Tooltip(
                          message: _thumbnailsVisible ? '收起缩略图' : '展开缩略图',
                          child: _glass(TextButton(
                            onPressed: _toggleThumbnails,
                            style: _overlayButtonStyle.copyWith(
                              padding: const WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(horizontal: 12)),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Text('${_current + 1} / ${widget.imgUrls.length}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ])),
                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: _thumbnailsVisible ? .5 : 0,
                                duration: const Duration(milliseconds: 180),
                                child: const Icon(Icons.expand_more_rounded,
                                    size: 18),
                              ),
                            ]),
                          )),
                        ),
                      )
                    else
                      SizedBox(
                          height: 44,
                          child: Center(
                              child: Text(
                                  hasImages
                                      ? '${_current + 1} / ${widget.imgUrls.length}'
                                      : '0 / 0',
                                  style: const TextStyle(
                                      color: _ink,
                                      fontSize: 14,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ])))),
                    Expanded(
                        child: Align(
                      heightFactor: 1,
                      alignment: Alignment.centerRight,
                      child: hasImages
                          ? Tooltip(
                              message: _saving
                                  ? '正在保存…'
                                  : original == null
                                      ? '保存图片'
                                      : '保存原图',
                              child: _glass(TextButton.icon(
                                onPressed: _saving ? null : _save,
                                style: _overlayButtonStyle,
                                icon: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.download_rounded,
                                        size: 19),
                                label: Text(sizeLabel.isEmpty ? '—' : sizeLabel,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontFeatures: [
                                          FontFeature.tabularFigures()
                                        ])),
                              )),
                            )
                          : const SizedBox.shrink(),
                    )),
                  ]),
                )),
              ),
              if (hasImages)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _chrome(Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          alignment: Alignment.bottomCenter,
                          child: !_thumbnailsVisible ||
                                  widget.imgUrls.length < 2
                              ? const SizedBox(width: double.infinity)
                              : _glass(
                                  Container(
                                    width: double.infinity,
                                    constraints: BoxConstraints(
                                        maxWidth:
                                            widget.imgUrls.length * 52.0 + 12),
                                    height: 64,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: _backdrop.withValues(alpha: .36),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: _ink.withValues(alpha: .1)),
                                    ),
                                    child: LayoutBuilder(
                                        builder: (context, constraints) {
                                      final width =
                                          widget.imgUrls.length * 52.0 - 4;
                                      return ListView.separated(
                                        controller: _thumbnails,
                                        scrollDirection: Axis.horizontal,
                                        padding: EdgeInsets.symmetric(
                                            horizontal:
                                                width < constraints.maxWidth
                                                    ? (constraints.maxWidth -
                                                            width) /
                                                        2
                                                    : 8),
                                        itemCount: widget.imgUrls.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(width: 4),
                                        itemBuilder: (context, index) =>
                                            SizedBox(
                                          width: 48,
                                          child: Center(
                                            child: Semantics(
                                              button: true,
                                              selected: index == _current,
                                              label: '第 ${index + 1} 张图片',
                                              child: InkWell(
                                                onTap: () =>
                                                    _pages.animateToPage(index,
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    220),
                                                        curve: Curves.easeOut),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 180),
                                                    width: index == _current
                                                        ? 40
                                                        : 36,
                                                    height: index == _current
                                                        ? 40
                                                        : 36,
                                                    decoration: BoxDecoration(
                                                      color: _placeholder,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      border: Border.all(
                                                        color: index == _current
                                                            ? _ink.withValues(
                                                                alpha: .9)
                                                            : Colors
                                                                .transparent,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    clipBehavior:
                                                        Clip.antiAlias,
                                                    child:
                                                        ExtendedImage.network(
                                                      widget.imgUrls[index],
                                                      cache: true,
                                                      fit: BoxFit.cover,
                                                      loadStateChanged: (state) =>
                                                          state.extendedImageLoadState ==
                                                                  LoadState
                                                                      .completed
                                                              ? null
                                                              : const Icon(
                                                                  Icons
                                                                      .image_outlined,
                                                                  size: 16,
                                                                  color: _ink),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  radius: 20)),
                      Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (canViewOriginal || loadingOriginal)
                              IgnorePointer(
                                ignoring: loadingOriginal,
                                child: _glass(TextButton(
                                  onPressed:
                                      loadingOriginal ? null : _viewOriginal,
                                  style: _overlayButtonStyle,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (loadingOriginal) ...[
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: _ink.withValues(alpha: .6),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(loadingOriginal
                                          ? '正在加载原图…'
                                          : _failedOriginals.contains(_current)
                                              ? '重试原图'
                                              : '查看原图'),
                                    ],
                                  ),
                                )),
                              ),
                          ]),
                    ]),
                  )),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 每页独立管理手势、重试和渐进加载状态。
class _ExplorerImage extends StatefulWidget {
  const _ExplorerImage(
      {super.key,
      required this.url,
      required this.preview,
      required this.onTap,
      required this.isOriginal,
      required this.onLoaded,
      required this.onOriginalFailed});

  final String url;
  final String preview;
  final VoidCallback onTap;
  final bool isOriginal;
  final void Function(String, int?) onLoaded;
  final VoidCallback onOriginalFailed;

  @override
  State<_ExplorerImage> createState() => _ExplorerImageState();
}

class _ExplorerImageState extends State<_ExplorerImage>
    with SingleTickerProviderStateMixin {
  final _gesture = GlobalKey<ExtendedImageGestureState>();
  late final _zoom = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 180));
  VoidCallback? _zoomListener;
  String? _reported;

  @override
  void didUpdateWidget(covariant _ExplorerImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _reported = null;
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _report(ExtendedImageState state, {bool failed = false}) {
    final url = widget.url;
    if (_reported == url) return;
    _reported = url;
    final bytes = state.loadingProgress?.expectedTotalBytes;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || widget.url != url) return;
      if (failed) {
        widget.onOriginalFailed();
      } else {
        widget.onLoaded(url, bytes);
        // 内存/磁盘命中时没有下载进度，从缓存读取真实文件大小。
        if (bytes == null) {
          final file = await getCachedImageFile(url);
          final length = await file?.length();
          if (!mounted || widget.url != url || length == null) return;
          widget.onLoaded(url, length);
        }
      }
    });
  }

  void _doubleTap(ExtendedImageGestureState state) {
    if (_zoomListener != null) _zoom.removeListener(_zoomListener!);
    _zoom.stop();
    _zoom.reset();
    final begin = state.gestureDetails?.totalScale ?? 1.0;
    final animation = Tween<double>(begin: begin, end: begin > 1 ? 1 : 2.5)
        .animate(CurvedAnimation(parent: _zoom, curve: Curves.easeOut));
    final position = state.pointerDownPosition;
    _zoomListener = () => state.handleDoubleTap(
        scale: animation.value, doubleTapPosition: position);
    _zoom.addListener(_zoomListener!);
    _zoom.forward();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: ExtendedImage.network(
          widget.url,
          cache: true,
          fit: BoxFit.contain,
          mode: ExtendedImageMode.gesture,
          extendedImageGestureKey: _gesture,
          handleLoadingProgress: true,
          initGestureConfigHandler: (_) => GestureConfig(
              inPageView: true, initialScale: 1, minScale: 1, maxScale: 5),
          onDoubleTap: _doubleTap,
          loadStateChanged: (state) {
            switch (state.extendedImageLoadState) {
              case LoadState.completed:
                _report(state);
                return null;
              case LoadState.failed:
                if (widget.isOriginal && widget.url != widget.preview) {
                  _report(state, failed: true);
                  return _preview();
                }
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.broken_image_outlined,
                        color: _ink, size: 40),
                    const SizedBox(height: 12),
                    const Text('图片加载失败', style: TextStyle(color: _ink)),
                    TextButton(
                      onPressed: () {
                        _reported = null;
                        state.reLoadImage();
                      },
                      child: const Text('重新加载'),
                    ),
                  ]),
                );
              case LoadState.loading:
                // 原图下载期间保持预览图可看、可缩放，不在图片中央覆盖进度。
                if (widget.url != widget.preview) return _preview();
                final progress = state.loadingProgress;
                final total = progress?.expectedTotalBytes;
                final value = total != null && total > 0
                    ? (progress!.cumulativeBytesLoaded / total).clamp(0.0, 1.0)
                    : null;
                return Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 1.5,
                        color: _ink.withValues(alpha: .5)),
                  ),
                );
            }
          },
        ),
      );

  Widget _preview() => ExtendedImage.network(
        widget.preview,
        cache: true,
        fit: BoxFit.contain,
        mode: ExtendedImageMode.gesture,
        extendedImageGestureKey: _gesture,
        initGestureConfigHandler: (_) => GestureConfig(
            inPageView: true, initialScale: 1, minScale: 1, maxScale: 5),
        onDoubleTap: _doubleTap,
        loadStateChanged: (state) =>
            state.extendedImageLoadState == LoadState.completed
                ? null
                : const SizedBox.shrink(),
      );
}
