import 'package:extended_image/extended_image.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/content/special_span.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/shared/media/video_player.dart';

/// 列表摘要保留表情资源与动态表情地址。
class ThreadPreviewExcerpt extends StatelessWidget {
  const ThreadPreviewExcerpt({super.key, required this.contents});

  final List<TiebaPostContent> contents;

  static String textOf(TiebaPostContent content) => switch (content) {
        TiebaTextContent c => c.text,
        TiebaAtContent c => c.text,
        TiebaLinkContent c => c.text,
        TiebaPhoneContent c => c.text,
        TiebaTopicContent c => c.text,
        _ => '',
      };

  static bool hasContent(List<TiebaPostContent> contents) => contents
      .any((c) => c is TiebaEmojiContent || textOf(c).trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: TiebananaTokens.of(context).textSecondary);
    final spans = <InlineSpan>[];
    var length = 0;
    final size = (style?.fontSize ?? 14) + 2;
    for (final content in contents) {
      if (content is TiebaEmojiContent) {
        spans.add(EmojiSpan(content.text,
            imageWidth: size,
            imageHeight: size,
            actualText: '#(${content.c})',
            fallbackUrl: content.dynamicUrl ?? content.staticUrl,
            cache: true));
        length++;
      } else {
        final text = textOf(content);
        spans.add(TiebaSpanBuilder().build(text, textStyle: style));
        length += text.length;
      }
      if (length > 200) break;
    }
    return ExtendedText.rich(TextSpan(children: spans),
        style: style, maxLines: 2, overflow: TextOverflow.ellipsis);
  }
}

/// 图片和视频按原始顺序展示；图片固定 16:9，视频按真实画面比例排版。
class ThreadPreviewMedia extends StatelessWidget {
  const ThreadPreviewMedia(
      {super.key, required this.contents, required this.threadId});

  final List<TiebaPostContent> contents;
  final String threadId;
  static const int _limit = 3;

  static bool _isMedia(TiebaPostContent c) => switch (c) {
        // 没有可用地址的图片（如投票封面）不算媒体，
        // 不生成 16:9 占位块。
        TiebaImageContent image => _usableImage(image),
        TiebaVideoContent _ || TiebaVideoLinkContent _ => true,
        _ => false,
      };

  static bool _usableImage(TiebaImageContent image) {
    final String src = image.displaySrc.trim();
    if (src.isEmpty) return false;
    final Uri? uri = Uri.tryParse(src);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  static bool hasContent(List<TiebaPostContent> contents) =>
      contents.any(_isMedia);

  static double _aspectRatioOf(TiebaPostContent content) => switch (content) {
        TiebaVideoContent video => normalizeVideoAspectRatio(
            videoAspectRatioOf(video.width, video.height)),
        _ => 16 / 9,
      };

  @override
  Widget build(BuildContext context) {
    final media = contents.where(_isMedia).toList();
    final images = contents
        .whereType<TiebaImageContent>()
        .where(_usableImage)
        .toList();
    final tokens = TiebananaTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < media.length && i < _limit; i++) ...[
          if (i > 0) const SizedBox(width: TiebananaMetrics.gapXs),
          Expanded(
            child: ClipRRect(
              borderRadius: TiebananaMetrics.brSm,
              child: AspectRatio(
                aspectRatio: _aspectRatioOf(media[i]),
                child: Stack(fit: StackFit.expand, children: [
                  if (media[i] case final TiebaImageContent image)
                    Thumbnail(
                      imgs: images.map((c) => c.displaySrc).toList(),
                      imgsOriginSrc: images.map((c) => c.originalSrc).toList(),
                      controller: ExtendedPageController(
                          initialPage: images.indexOf(image)),
                      img: image.displaySrc,
                      padding: EdgeInsets.zero,
                      radius: TiebananaMetrics.radiusSm,
                    )
                  else
                    _VideoPreview(content: media[i], threadId: threadId),
                  if (i == _limit - 1 && media.length > _limit)
                    Positioned(
                      right: TiebananaMetrics.gapXs,
                      bottom: TiebananaMetrics.gapXs,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: TiebananaMetrics.gapXs, vertical: 1),
                          decoration: BoxDecoration(
                              color: tokens.accentFill,
                              borderRadius: TiebananaMetrics.brXs),
                          child: Text('${media.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: tokens.accentOn)),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 列表里只加载封面，点击后创建播放器。
class _VideoPreview extends StatefulWidget {
  const _VideoPreview({required this.content, required this.threadId});
  final TiebaPostContent content;
  final String threadId;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  bool _showPlayer = false;

  @override
  void didUpdateWidget(covariant _VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) _showPlayer = false;
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.content;
    final video = content is TiebaVideoContent ? content : null;
    if (_showPlayer) {
      return VideoPlayer(
          cover: video?.cover,
          url: video!.link!,
          autoplay: true,
          aspectRatio: normalizeVideoAspectRatio(
              videoAspectRatioOf(video.width, video.height)));
    }
    final tokens = TiebananaTokens.of(context);
    return Semantics(
      label: '播放视频',
      button: true,
      child: GestureDetector(
        onTap: () {
          if (video?.link?.trim().isNotEmpty ?? false) {
            setState(() => _showPlayer = true);
          } else {
            Navigator.pushNamed(context, PageRouter.threadPage,
                arguments:
                    ThreadPageRouterData(kz: widget.threadId, pid: null));
          }
        },
        child: ColoredBox(
          color: tokens.quoteBackground,
          child: Stack(fit: StackFit.expand, children: [
            if (video?.cover?.isNotEmpty ?? false)
              ExtendedImage.network(video!.cover!,
                  fit: BoxFit.cover, cache: true),
            Center(
              child: ExcludeSemantics(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double side = constraints.biggest.shortestSide;
                    return VideoPlayButton(
                      size: (side * .42).clamp(36.0, 56.0),
                      label: '播放视频',
                    );
                  },
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
