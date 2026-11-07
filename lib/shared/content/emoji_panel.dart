import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/core/config/constants.dart';
import 'package:tiebanana/core/config/asset_list.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/features/media/state/image_upload.dart';

class EmojiPanel extends StatefulWidget {
  final TextEditingController controller;
  final double height;
  const EmojiPanel({super.key, required this.controller, required this.height});

  @override
  State<EmojiPanel> createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<EmojiPanel> {
  late PageController controller;
  List<String> emoji = [];
  static const int _crossAxisCount = 7;
  static const int _rowCount = 3;
  static const double _mainAxisExtent = 30;
  static const double _mainAxisSpacing = 20;
  late final TextEditingController textController;
  @override
  void initState() {
    super.initState();
    controller = PageController();
    emoji.add("image_emoticon.png");
    for (var i = 2; i <= 129; i++) {
      if (AssetList.emojis.contains("image_emoticon$i.png")) {
        emoji.add("image_emoticon$i.png");
      }
    }

    textController = widget.controller;
  }

  List<String> emojiPage(int page) => emoji.sublist(
      page * _crossAxisCount * _rowCount,
      (page + 1) * _crossAxisCount * _rowCount > emoji.length
          ? emoji.length
          : (page + 1) * _crossAxisCount * _rowCount);

  void insertText(String text) {
    final TextEditingValue value = textController.value;
    final int start = value.selection.baseOffset;
    int end = value.selection.extentOffset;
    if (value.selection.isValid) {
      String newText = '';
      if (value.selection.isCollapsed) {
        if (end > 0) {
          newText += value.text.substring(0, end);
        }
        newText += text;
        if (value.text.length > end) {
          newText += value.text.substring(end, value.text.length);
        }
      } else {
        newText = value.text.replaceRange(start, end, text);
        end = start;
      }

      textController.value = value.copyWith(
          text: newText,
          selection: value.selection.copyWith(
              baseOffset: end + text.length, extentOffset: end + text.length));
    } else {
      textController.value = TextEditingValue(
          text: text,
          selection:
              TextSelection.fromPosition(TextPosition(offset: text.length)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: widget.height),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          constraints: const BoxConstraints(
              maxHeight: (_mainAxisExtent + _mainAxisSpacing) * _rowCount),
          child: PageView.builder(
            itemCount: (emoji.length / (_crossAxisCount * _rowCount)).ceil(),
            controller: controller,
            itemBuilder: (BuildContext context, int pageindex) {
              return GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    mainAxisExtent: _mainAxisExtent,
                    crossAxisCount: _crossAxisCount,
                    mainAxisSpacing: _mainAxisSpacing,
                    crossAxisSpacing: 5),
                itemCount: emojiPage(pageindex).length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      var emojiName =
                          emojiPage(pageindex)[index].replaceFirst(".png", "");
                      insertText("#(${emojiFileMapping[emojiName]})");
                    },
                    child: ExtendedImage.asset(
                      "assets/emoji/${emojiPage(pageindex)[index]}",
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: SmoothPageIndicator(
            controller: controller,
            count: (emoji.length / (_crossAxisCount * _rowCount)).ceil(),
            onDotClicked: (index) {
              controller.animateToPage(index,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut);
            },
            effect: WormEffect(
                spacing: 20,
                dotWidth: 7,
                dotHeight: 7,
                activeDotColor: TiebananaTokens.of(context).textTertiary,
                dotColor: TiebananaTokens.of(context).fill),
          ),
        )
      ]),
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
