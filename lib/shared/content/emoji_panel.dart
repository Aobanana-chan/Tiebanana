import 'package:extended_image/extended_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/core/config/constants.dart';
import 'package:tiebanana/core/config/asset_list.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/features/media/state/image_upload.dart';

List<String> _buildEmojiAssets() {
  return <String>[
    'image_emoticon.png',
    for (int i = 2; i <= 129; i++)
      if (AssetList.emojis.contains('image_emoticon$i.png'))
        'image_emoticon$i.png',
  ];
}

void _insertEmojiToken(TextEditingController controller, String fileName) {
  final String key = fileName.replaceFirst('.png', '');
  final String? label = emojiFileMapping[key];
  if (label == null) return;
  final String token = '#($label)';
  final TextEditingValue value = controller.value;
  if (value.selection.isValid) {
    final int start = value.selection.start;
    final int end = value.selection.end;
    final String newText = value.text.replaceRange(start, end, token);
    controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  } else {
    final String next = controller.text + token;
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }
}

WormEffect _emojiIndicatorEffect(TiebananaTokens tokens) {
  return WormEffect(
    spacing: 20,
    dotWidth: 7,
    dotHeight: 7,
    activeDotColor: tokens.textTertiary,
    dotColor: tokens.fill,
  );
}

mixin _EmojiPageWheelMixin<T extends StatefulWidget> on State<T> {
  late final PageController _pageController = PageController();
  int _currentPage = 0;
  int? _targetPage;
  double _wheelAccum = 0;
  DateTime? _lastWheelAt;
  DateTime? _lastTouchpadTurnAt;

  int get _pageCount;
  int get _effectivePage => _targetPage ?? _currentPage;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageChanged(int index) {
    if (_currentPage != index) {
      setState(() => _currentPage = index);
    }
  }

  Future<void> _goToPage(int page) async {
    final int count = _pageCount;
    if (count <= 0) return;
    final int target = page.clamp(0, count - 1);
    if (target == _effectivePage) return;
    setState(() => _targetPage = target);
    await _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
    if (mounted && _targetPage == target) {
      setState(() => _targetPage = null);
    }
  }

  void _stepPage(int delta) {
    _goToPage(_effectivePage + delta);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final double dy = event.scrollDelta.dy;
    final double dx = event.scrollDelta.dx;
    final double delta = dy.abs() >= dx.abs() ? dy : dx;
    if (delta == 0) return;

    const double threshold = 24.0;
    final DateTime now = DateTime.now();

    if (delta.abs() >= threshold) {
      _wheelAccum = 0;
      _lastWheelAt = now;
      _stepPage(delta > 0 ? 1 : -1);
      return;
    }

    if (_lastTouchpadTurnAt != null &&
        now.difference(_lastTouchpadTurnAt!) <
            const Duration(milliseconds: 180)) {
      return;
    }
    if (_lastWheelAt != null &&
        now.difference(_lastWheelAt!) > const Duration(milliseconds: 220)) {
      _wheelAccum = 0;
    }
    _lastWheelAt = now;
    _wheelAccum += delta;
    if (_wheelAccum.abs() >= threshold) {
      final int step = _wheelAccum > 0 ? 1 : -1;
      _wheelAccum = 0;
      _lastTouchpadTurnAt = now;
      _stepPage(step);
    }
  }
}

class EmojiPanel extends StatefulWidget {
  final TextEditingController controller;
  final double height;
  const EmojiPanel({super.key, required this.controller, required this.height});

  @override
  State<EmojiPanel> createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<EmojiPanel>
    with _EmojiPageWheelMixin<EmojiPanel> {
  static const int _crossAxisCount = 7;
  static const int _rowCount = 3;
  static const int _perPage = _crossAxisCount * _rowCount;
  static const double _mainAxisExtent = 34;
  static const double _mainAxisSpacing = 12;
  static const double _gridHeight =
      _mainAxisExtent * _rowCount + _mainAxisSpacing * (_rowCount - 1);

  late final List<String> _emojis = _buildEmojiAssets();

  @override
  int get _pageCount => (_emojis.length / _perPage).ceil();

  List<String> _itemsFor(int page) {
    final int start = page * _perPage;
    final int end =
        (start + _perPage) > _emojis.length ? _emojis.length : start + _perPage;
    return _emojis.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: _handlePointerSignal,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.height),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                child: SizedBox(
                  height: _gridHeight,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pageCount,
                    onPageChanged: _handlePageChanged,
                    itemBuilder: (BuildContext context, int pageIndex) {
                      final List<String> pageItems = _itemsFor(pageIndex);
                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          mainAxisExtent: _mainAxisExtent,
                          crossAxisCount: _crossAxisCount,
                          mainAxisSpacing: _mainAxisSpacing,
                          crossAxisSpacing: 4,
                        ),
                        itemCount: pageItems.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String file = pageItems[index];
                          final String? label =
                              emojiFileMapping[file.replaceFirst('.png', '')];
                          return Tooltip(
                            message: label ?? '',
                            waitDuration: const Duration(milliseconds: 500),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () =>
                                    _insertEmojiToken(widget.controller, file),
                                child: Center(
                                  child: ExtendedImage.asset(
                                    'assets/emoji/$file',
                                    width: 26,
                                    height: 26,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: _pageCount,
                  onDotClicked: _goToPage,
                  effect: _emojiIndicatorEffect(tokens),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 桌面端锚定在表情按钮上方的悬浮 Popover（`364 × 200dp`，标题「贴吧表情」，`7 × 3` 分页）。
Future<void> showEmojiPopover({
  required BuildContext context,
  required GlobalKey anchorKey,
  required TextEditingController controller,
  VoidCallback? onInserted,
}) async {
  final RenderBox? box =
      anchorKey.currentContext?.findRenderObject() as RenderBox?;
  final Size screen = MediaQuery.sizeOf(context);
  const double popW = 364;
  const double popH = 200;

  double left = 16;
  double top = (screen.height - popH) / 2;
  if (box != null && box.attached) {
    final Offset pos = box.localToGlobal(Offset.zero);
    left = pos.dx
        .clamp(12.0, (screen.width - popW - 12).clamp(12.0, screen.width));
    final double aboveTop = pos.dy - popH - 8;
    if (aboveTop >= 12) {
      top = aboveTop;
    } else {
      top = (pos.dy + box.size.height + 8)
          .clamp(12.0, (screen.height - popH - 12).clamp(12.0, screen.height));
    }
  }

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭贴吧表情',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (BuildContext dialogContext, _, __) {
      return Stack(
        children: <Widget>[
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: DesktopEmojiPopover(
                controller: controller,
                onInserted: onInserted,
              ),
            ),
          ),
        ],
      );
    },
  );
}

class DesktopEmojiPopover extends StatefulWidget {
  const DesktopEmojiPopover({
    super.key,
    required this.controller,
    this.onInserted,
  });

  final TextEditingController controller;
  final VoidCallback? onInserted;

  @override
  State<DesktopEmojiPopover> createState() => _DesktopEmojiPopoverState();
}

class _DesktopEmojiPopoverState extends State<DesktopEmojiPopover>
    with _EmojiPageWheelMixin<DesktopEmojiPopover> {
  static const int _cols = 7;
  static const int _rows = 3;
  static const int _perPage = _cols * _rows;
  static const double _cellExtent = 38;
  static const double _mainAxisSpacing = 4;
  static const double _crossAxisSpacing = 4;
  static const double _gridHeight =
      _cellExtent * _rows + _mainAxisSpacing * (_rows - 1);

  late final List<String> _emojis = _buildEmojiAssets();

  @override
  int get _pageCount => (_emojis.length / _perPage).ceil();

  List<String> _itemsFor(int page) {
    final int start = page * _perPage;
    final int end =
        (start + _perPage) > _emojis.length ? _emojis.length : start + _perPage;
    return _emojis.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final int activePage = _effectivePage;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: _handlePointerSignal,
      child: Container(
        width: 364,
        padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: tokens.line),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: tokens.shadow,
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '贴吧表情',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.textSecondary,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: _gridHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageCount,
                onPageChanged: _handlePageChanged,
                itemBuilder: (BuildContext context, int pageIndex) {
                  final List<String> pageItems = _itemsFor(pageIndex);
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisExtent: _cellExtent,
                      crossAxisCount: _cols,
                      mainAxisSpacing: _mainAxisSpacing,
                      crossAxisSpacing: _crossAxisSpacing,
                    ),
                    itemCount: pageItems.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String file = pageItems[index];
                      final String? label =
                          emojiFileMapping[file.replaceFirst('.png', '')];
                      return Tooltip(
                        message: label ?? '',
                        waitDuration: const Duration(milliseconds: 500),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            _insertEmojiToken(widget.controller, file);
                            widget.onInserted?.call();
                          },
                          child: Center(
                            child: ExtendedImage.asset(
                              'assets/emoji/$file',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _pageBtn(
                  tokens,
                  icon: Icons.chevron_left_rounded,
                  tooltip: '上一页',
                  onTap: activePage > 0 ? () => _stepPage(-1) : null,
                ),
                const SizedBox(width: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: _pageCount,
                    onDotClicked: _goToPage,
                    effect: _emojiIndicatorEffect(tokens),
                  ),
                ),
                const SizedBox(width: 12),
                _pageBtn(
                  tokens,
                  icon: Icons.chevron_right_rounded,
                  tooltip: '下一页',
                  onTap:
                      activePage < _pageCount - 1 ? () => _stepPage(1) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageBtn(
    TiebananaTokens tokens, {
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: tokens.fill,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: SizedBox(
            width: 22,
            height: 22,
            child: Icon(
              icon,
              size: 15,
              color: onTap == null
                  ? tokens.textTertiary.withValues(alpha: 0.4)
                  : tokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadThumbnail extends StatefulWidget {
  const _UploadThumbnail({super.key, required this.asset});
  final AssetEntity asset;

  @override
  State<_UploadThumbnail> createState() => _UploadThumbnailState();
}

class _UploadThumbnailState extends State<_UploadThumbnail> {
  late final _thumbnail =
      widget.asset.thumbnailDataWithSize(const ThumbnailSize(240, 240));

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _thumbnail,
        builder: (context, snapshot) => snapshot.data == null
            ? const Icon(Icons.image_outlined)
            : Image.memory(snapshot.data!, fit: BoxFit.cover),
      );
}

class ImagePanel extends StatelessWidget {
  final Map<TiebaUploadedImage, AssetEntity> uploaded;
  final void Function()? onAddImage;
  final List<ImageUploadTask> tasks;
  final void Function(ImageUploadTask)? onRetry;
  final void Function(ImageUploadTask)? onRemove;
  const ImagePanel({
    super.key,
    required this.uploaded,
    required this.onAddImage,
    this.tasks = const [],
    this.onRetry,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TiebananaTokens.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text('配图（${tasks.length}）',
            style: Theme.of(context).textTheme.titleSmall),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
          itemCount: tasks.length + 1,
          itemBuilder: (context, index) {
            if (index == tasks.length) {
              return Material(
                color: tokens.primaryContainer,
                borderRadius: TiebananaMetrics.brCtl,
                child: InkWell(
                  onTap: onAddImage,
                  borderRadius: TiebananaMetrics.brCtl,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded,
                            color: tokens.onPrimaryContainer),
                        Text('添加图片',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: tokens.onPrimaryContainer)),
                      ]),
                ),
              );
            }
            final task = tasks[index];
            return ClipRRect(
              borderRadius: TiebananaMetrics.brCtl,
              child: ColoredBox(
                color: tokens.fill,
                child: Stack(fit: StackFit.expand, children: [
                  _UploadThumbnail(
                      key: ValueKey(task.asset.id), asset: task.asset),
                  if (task.result == null)
                    ColoredBox(
                      color: tokens.surface.withValues(alpha: 0.9),
                      child: Center(
                          child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: task.error != null
                            ? Column(mainAxisSize: MainAxisSize.min, children: [
                                Tooltip(
                                    message: task.error!,
                                    child: Text('上传失败',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(color: tokens.danger))),
                                TextButton(
                                    onPressed: () => onRetry?.call(task),
                                    child: const Text('重试')),
                              ])
                            : Column(mainAxisSize: MainAxisSize.min, children: [
                                LinearProgressIndicator(
                                    value: task.total > 0
                                        ? task.sent / task.total
                                        : null),
                                const SizedBox(height: 8),
                                Text(
                                    task.uploading
                                        ? task.total > 0 &&
                                                task.sent >= task.total
                                            ? '处理中…'
                                            : '上传中 ${task.total > 0 ? '${(task.sent * 100 / task.total).floor()}%' : ''}'
                                        : '等待上传',
                                    style:
                                        Theme.of(context).textTheme.labelSmall),
                              ]),
                      )),
                    ),
                  if (!task.uploading)
                    Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton.filledTonal(
                          tooltip: '移除图片',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => onRemove?.call(task),
                          icon: const Icon(Icons.close_rounded, size: 16),
                        )),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
