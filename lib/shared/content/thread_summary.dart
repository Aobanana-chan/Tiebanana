import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:extended_image/extended_image.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/media/animated_image_probe.dart';
import 'package:tiebanana/shared/media/img_explorer.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';
import 'package:tiebanana/features/profile/state/profile_events.dart';
import 'package:tiebanana/shared/widgets/avatar_image.dart';
import 'package:tiebanana/shared/content/thread_preview_content.dart';
import 'package:tiebanana/shared/content/special_span.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/moderation/widgets/moderation_actions.dart';
import 'package:tiebanana/features/share/models/share_content.dart';
import 'package:tiebanana/features/share/widgets/share_sheet.dart';
import 'package:uuid/uuid.dart';

import 'package:tieba_contract/tieba_contract.dart';

///帖子气泡(动态推荐流 / 吧页列表 / 用户主页)-小部件
///
///对应概念图 `design/mockups/recommend.html`（方向 A）与
///`design/mockups/visitor.html`：作者行 + 标题 + 两行摘要（+ 被引用内容）
///+ 最多三张缩略图 + 页脚统计。三个列表页共用这一份。
class ThreadSummary extends StatelessWidget {
  // final ThreadRecommendSummary info;
  final List<TiebaPostContent> firstPostContent; //一楼Content
  final TiebaAuthor author;
  final String createTime;
  final String latestTime; //最近回复时间
  final String tid;
  final String fname;
  final String viewNum;
  final String title;
  final String agreeNum;
  final String disagreeNum;
  final String replyNum;

  /// 被引用的内容（用户主页的「回复」页签）。空串时隐藏。
  ///
  /// 引用块使用 `quoteBackground` / `quoteText`，与楼层引用保持同一套语义。
  final String quote;

  /// 右上角的内容操作入口（举报帖子 / 拉黑作者）。
  final bool dismissible;

  /// 外边距；传 `EdgeInsets.only(bottom: 11)` 可与 PageWrap 严格对齐。
  final EdgeInsetsGeometry? margin;

  /// 分栏阅读中当前选中的帖子高亮。
  final bool selected;

  /// 覆盖默认进帖跳转（用于分栏阅读选中）。
  final VoidCallback? onTap;

  /// 是否在作者行显示所属吧胶囊（桌面推荐流开启，吧主页关闭）。
  final bool showForumChip;

  /// 是否使用桌面端卡片排版（24dp 头像、左统计右分享页脚）。
  final bool desktop;

  const ThreadSummary(
      {super.key,
      required this.firstPostContent,
      required this.author,
      required this.createTime,
      required this.latestTime,
      required this.tid,
      required this.fname,
      required this.viewNum,
      required this.title,
      required this.agreeNum,
      required this.disagreeNum,
      required this.replyNum,
      this.quote = "",
      this.dismissible = true,
      this.margin,
      this.selected = false,
      this.onTap,
      this.showForumChip = false,
      this.desktop = false});

  ///摘要：只收文字类内容，图片 / 视频由缩略图行展示。
  String _excerpt() {
    final StringBuffer buffer = StringBuffer();
    for (final TiebaPostContent content in firstPostContent) {
      if (content is TiebaTextContent) {
        buffer.write(content.text);
      } else if (content is TiebaAtContent) {
        buffer.write(content.text);
      } else if (content is TiebaLinkContent) {
        buffer.write(content.text);
      } else if (content is TiebaPhoneContent) {
        buffer.write(content.text);
      } else if (content is TiebaEmojiContent) {
        buffer.write("#(${content.c})");
      }
      //摘要只占两行，超出部分截断即可，不必把整楼拼完。
      if (buffer.length > 200) {
        break;
      }
    }
    return buffer.toString().trim();
  }

  ///相对时间文案（「3小时前」/「2024年5月1日」），空值返回空串。
  String _timeText(String seconds) {
    final int stamp = int.tryParse(seconds) ?? 0;
    if (stamp <= 0) {
      return "";
    }
    return TiebaParser.getPostTime(intTime: stamp);
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<Widget> icons = TiebaParser.processIcon(author) ?? <Widget>[];
    final bool desktopLayout = desktop;

    //动态流看的是「最近一次活动」，拿不到时退回发帖时间。
    final String latest = _timeText(latestTime);
    final String when = latest.isNotEmpty ? latest : _timeText(createTime);

    final String excerpt = _excerpt();

    final Color fgPrimary =
        selected ? tokens.onPrimaryContainer : tokens.textPrimary;
    final Color fgMeta =
        selected ? tokens.onPrimaryContainer : tokens.textTertiary;
    final TextStyle? metaStyle = textTheme.labelSmall?.copyWith(color: fgMeta);

    return Container(
      margin: margin ??
          const EdgeInsets.fromLTRB(TiebananaMetrics.pageGutter, 0,
              TiebananaMetrics.pageGutter, TiebananaMetrics.gapSm),
      decoration: BoxDecoration(
        color: selected ? tokens.primaryContainer : tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: selected ? null : tokens.cardShadow,
      ),
      child: MaterialButton(
        onPressed: onTap ??
            () async {
              Navigator.pushNamed(context, PageRouter.threadPage,
                  arguments: ThreadPageRouterData(kz: tid, pid: null));
            },
        color: Colors.transparent,
        elevation: 0,
        // 透明按钮默认悬停高度为 4，会在整张卡片上产生明显暗影。
        hoverElevation: 0,
        hoverColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: .04),
        highlightElevation: 0,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minWidth: 0,
        padding:
            EdgeInsets.all(desktopLayout ? 15 : TiebananaMetrics.cardPadding),
        shape: RoundedRectangleBorder(borderRadius: TiebananaMetrics.brLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            //作者行：头像 + 昵称（含等级图标）+ 吧胶囊 + 时间 + 操作
            Row(
              children: <Widget>[
                Avatar(
                  onTap: () {
                    Navigator.pushNamed(context, PageRouter.user,
                        arguments: author.id);
                  },
                  imgUrl: resolveAvatarUrl(author.portrait),
                  height: desktopLayout ? 24 : TiebananaMetrics.avatarSm,
                  width: desktopLayout ? 24 : TiebananaMetrics.avatarSm,
                ),
                const SizedBox(width: TiebananaMetrics.gapSm),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          author.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              textTheme.labelMedium?.copyWith(color: fgPrimary),
                        ),
                      ),
                      ...icons,
                      if (showForumChip && fname.isNotEmpty) ...<Widget>[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: selected
                                ? tokens.surface.withValues(alpha: .45)
                                : tokens.fill,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$fname吧',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? tokens.onPrimaryContainer
                                  : tokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                      if (when.isNotEmpty) ...<Widget>[
                        const SizedBox(width: TiebananaMetrics.gapXs),
                        Text(when, style: metaStyle),
                      ],
                    ],
                  ),
                ),
                if (dismissible)
                  Tooltip(
                    message: '帖子操作',
                    child: InkWell(
                        borderRadius:
                            BorderRadius.circular(TiebananaMetrics.radiusPill),
                        onTap: () => showThreadModerationMenu(context,
                            target: TiebaReportTarget(
                                kind: TiebaReportKind.thread,
                                userId: author.id,
                                name: author.name,
                                portrait: author.portrait,
                                threadId: tid,
                                summary: title.isEmpty ? excerpt : title,
                                source: fname)),
                        child: Padding(
                          padding: const EdgeInsets.all(TiebananaMetrics.gapXs),
                          child: Icon(
                              desktopLayout ? Icons.more_horiz : Icons.close,
                              size: desktopLayout
                                  ? 16
                                  : TiebananaMetrics.iconSizeSmall,
                              color: fgMeta),
                        )),
                  ),
              ],
            ),
            //标题。「回复」没有标题（title 为空串）时整块不画，别留一条空行。
            if (title.isNotEmpty) ...<Widget>[
              const SizedBox(height: TiebananaMetrics.gapSm),
              ExtendedText(
                title,
                specialTextSpanBuilder: TiebaSpanBuilder(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(color: fgPrimary),
              ),
            ],
            //被引用内容：用户主页的回复会带一条被引用的原文。
            if (quote.isNotEmpty) ...<Widget>[
              const SizedBox(height: TiebananaMetrics.gapSm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: TiebananaMetrics.gapSm + 2,
                  vertical: TiebananaMetrics.gapSm + 1,
                ),
                decoration: BoxDecoration(
                  color: tokens.quoteBackground,
                  borderRadius: TiebananaMetrics.brSm,
                ),
                child: ExtendedText(
                  quote,
                  specialTextSpanBuilder: TiebaSpanBuilder(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: tokens.quoteText),
                ),
              ),
            ],
            //正文摘要
            if (ThreadPreviewExcerpt.hasContent(firstPostContent)) ...<Widget>[
              const SizedBox(height: TiebananaMetrics.gapXs),
              ThreadPreviewExcerpt(contents: firstPostContent),
            ],
            //缩略图（最多三张，固定 3 列等宽等高）
            if (ThreadPreviewMedia.hasContent(firstPostContent)) ...<Widget>[
              const SizedBox(height: TiebananaMetrics.gapSm),
              ThreadPreviewMedia(contents: firstPostContent, threadId: tid),
            ],
            //页脚：桌面展示赞/回复/浏览 + 右侧分享；移动端保留吧名 + 右侧统计
            const SizedBox(height: TiebananaMetrics.gapSm),
            DefaultTextStyle(
              style: metaStyle ?? const TextStyle(),
              child: IconTheme(
                data: IconThemeData(
                    color: fgMeta, size: TiebananaMetrics.iconSizeSmall),
                child: desktopLayout
                    ? Row(
                        children: <Widget>[
                          if (agreeNum.isNotEmpty) ...<Widget>[
                            const Icon(Icons.thumb_up_outlined),
                            const SizedBox(width: TiebananaMetrics.gapXs),
                            Text(agreeNum),
                            const SizedBox(width: TiebananaMetrics.gapMd),
                          ],
                          const Icon(Icons.chat_bubble_outline_rounded),
                          const SizedBox(width: TiebananaMetrics.gapXs),
                          Text(replyNum),
                          if (viewNum.isNotEmpty) ...<Widget>[
                            const SizedBox(width: TiebananaMetrics.gapMd),
                            const Icon(Icons.visibility_outlined),
                            const SizedBox(width: TiebananaMetrics.gapXs),
                            Text(viewNum),
                          ],
                          const Spacer(),
                          InkWell(
                            borderRadius: TiebananaMetrics.brXs,
                            onTap: () => showShareSheet(
                              context,
                              ShareContent(
                                title: title.trim().isEmpty
                                    ? (excerpt.isEmpty ? '贴吧帖子' : excerpt)
                                    : title,
                                url: 'https://tieba.baidu.com/p/$tid',
                                source: fname.isEmpty ? '贴吧' : '$fname吧',
                                icon: Icons.article_outlined,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(Icons.share_outlined,
                                      size: TiebananaMetrics.iconSizeSmall,
                                      color: fgMeta),
                                  const SizedBox(width: TiebananaMetrics.gapXs),
                                  Text('分享', style: metaStyle),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: <Widget>[
                          Expanded(
                            child: Visibility(
                              visible: fname != "",
                              child: Text(
                                "$fname吧",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Row(
                            children: <Widget>[
                              if (viewNum.isNotEmpty) ...<Widget>[
                                const Icon(Icons.remove_red_eye),
                                const SizedBox(width: TiebananaMetrics.gapXXs),
                                Text(viewNum),
                                const SizedBox(width: TiebananaMetrics.gapMd),
                              ],
                              if (agreeNum.isNotEmpty) ...<Widget>[
                                const Icon(Icons.thumb_up),
                                const SizedBox(width: TiebananaMetrics.gapXXs),
                                Text(agreeNum),
                                const SizedBox(width: TiebananaMetrics.gapMd),
                              ],
                              const Icon(Icons.speaker_notes),
                              const SizedBox(width: TiebananaMetrics.gapXXs),
                              Text(replyNum),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Avatar extends StatefulWidget {
  final String imgUrl;

  /// 个人资料头像的账号；其他楼层头像不使用本机提交预览。
  final String? userId;
  final double? height;
  final double? width;
  final void Function()? onTap;
  const Avatar(
      {super.key,
      required this.imgUrl,
      this.userId,
      this.height,
      this.width,
      this.onTap});

  @override
  _AvatarState createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  String heroTagSalt = const Uuid().v4();
  @override
  Widget build(BuildContext context) {
    if (widget.userId != null) {
      return ListenableBuilder(
        listenable: profileEvents,
        builder: (context, _) => _buildAvatar(context),
      );
    }
    return _buildAvatar(context);
  }

  Widget _buildAvatar(BuildContext context) {
    final preview = profileEvents.avatarPreview(widget.userId ?? '');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap ??
          () {
            if (preview != null) {
              showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.memory(preview),
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('已提交的头像预览，网络展示可能尚未同步'),
                      ),
                    ],
                  ),
                ),
              );
              return;
            }
            if (widget.imgUrl.startsWith('data:image/')) {
              showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  child: Image.memory(
                    UriData.parse(widget.imgUrl).contentAsBytes(),
                    fit: BoxFit.contain,
                  ),
                ),
              );
              return;
            }
            Navigator.push(context, ImageExplorerRoute(builder: (builder) {
              return ImgExplorer(
                imgUrl: widget.imgUrl,
                heroTagSalt: heroTagSalt,
              );
            }));
          },
      child: Container(
        height: widget.height,
        width: widget.width,
        margin: const EdgeInsets.only(right: 5),
        child: ClipOval(
          child: Hero(
            tag: widget.imgUrl + heroTagSalt,
            child: preview != null
                ? Tooltip(
                    message: '已提交的头像预览，网络展示可能尚未同步',
                    child: Image.memory(preview, fit: BoxFit.cover),
                  )
                : AvatarImage(url: widget.imgUrl),
          ),
        ),
      ),
    );
  }
}

class Thumbnail extends StatefulWidget {
  final List<String> imgs;
  final List<String?>? imgsOriginSrc;
  final ExtendedPageController controller;
  final String img;
  final BoxFit fit;
  final EdgeInsets padding;
  final bool animated;

  ///GIF 角标距缩略图右 / 下边缘的距离。
  ///
  ///信息流的多图数量角标也占用右下角，此时由调用方把角标上移。
  final EdgeInsets gifBadgeMargin;

  ///圆角。动态卡片用 12，贴内嵌图沿用更小的 5。
  final double radius;
  const Thumbnail(
      {super.key,
      required this.imgs,
      this.imgsOriginSrc,
      required this.controller,
      required this.img,
      this.fit = BoxFit.cover,
      this.padding = const EdgeInsets.symmetric(horizontal: 2.5),
      this.animated = false,
      this.gifBadgeMargin = const EdgeInsets.all(4),
      this.radius = 5});

  @override
  _ThumbnailState createState() => _ThumbnailState();
}

class _ThumbnailState extends State<Thumbnail> {
  String heroTagSalt = const Uuid().v4();

  /// 图片加载后从磁盘缓存头识别出的动图；`.jpg` 地址下的真实动图靠它补上。
  bool _detectedAnimated = false;
  String? _probedUrl;

  @override
  void didUpdateWidget(covariant Thumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.img != widget.img) {
      _detectedAnimated = false;
      _probedUrl = null;
    }
  }

  /// 图片下载完成后读取文件头；与官方一样以实际图片格式为准，
  /// 不再用原图字节数猜测。
  void _ensureAnimatedProbe() {
    // 角标只在省流量档位显示；其他档位不做额外探测请求。
    if (Global.setting.pictureLoadSetting != 0 || widget.animated) return;
    final String url = widget.img.trim();
    if (url.isEmpty || _probedUrl == url) return;
    _probedUrl = url;
    unawaited(AnimatedImageProbe.shared.resolve(url).then((state) {
      if (!mounted || _probedUrl != url) return;
      if (state == AnimatedImageState.animated && !_detectedAnimated) {
        setState(() => _detectedAnimated = true);
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    // 空地址 / 非法地址直接跳过：投票首段之类的 linkImage 可能没有 src。
    final String img = widget.img.trim();
    if (img.isEmpty) {
      return const SizedBox.shrink();
    }
    return Builder(
      builder: (context) {
        final TiebananaTokens tokens = TiebananaTokens.of(context);
        // 省流量档位只加载首帧，用角标提示点开后是动图。
        final bool animated = widget.animated ||
            _detectedAnimated ||
            AnimatedImageProbe.shared.peek(img) == AnimatedImageState.animated;
        final bool showGifBadge =
            animated && Global.setting.pictureLoadSetting == 0;
        return GestureDetector(
            onTap: () {
              Navigator.push(context, ImageExplorerRoute(builder: (builder) {
                return ZoomedImgExplorer(
                  imgUrls: widget.imgs,
                  highQualityUrls: widget.imgsOriginSrc,
                  pageController: widget.controller,
                  heroTagSalt: heroTagSalt,
                  heroTag: widget.img + heroTagSalt,
                );
              }));
            },
            child: Padding(
              padding: widget.padding,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.radius),
                child: Stack(
                  fit: StackFit.passthrough,
                  children: <Widget>[
                    FadeIn(
                        child: Hero(
                      tag: widget.img + heroTagSalt,
                      child: LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          return Container(
                            constraints: constraints,
                            child: ExtendedImage.network(
                              widget.img,
                              fit: widget.fit,
                              cache: true,
                              clearMemoryCacheIfFailed: true,
                              // 加载失败时显示中性占位。
                              loadStateChanged: (ExtendedImageState state) {
                                if (state.extendedImageLoadState ==
                                    LoadState.completed) {
                                  _ensureAnimatedProbe();
                                }
                                if (state.extendedImageLoadState ==
                                    LoadState.failed) {
                                  return Container(
                                    constraints: constraints,
                                    alignment: Alignment.center,
                                    color: TiebananaTokens.of(context).fill,
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 20,
                                      color: TiebananaTokens.of(context)
                                          .textTertiary,
                                    ),
                                  );
                                }
                                return null;
                              },
                            ),
                          );
                        },
                      ),
                    )),
                    if (showGifBadge)
                      Positioned(
                        right: widget.gifBadgeMargin.right,
                        bottom: widget.gifBadgeMargin.bottom,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: tokens.imageScrim.withValues(alpha: .45),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              child: Text(
                                'GIF',
                                style: TextStyle(
                                  color: tokens.onImage,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  letterSpacing: .5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ));
      },
    );
  }
}
