import 'package:animate_do/animate_do.dart';
import 'package:extended_image/extended_image.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/media/img_explorer.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';
import 'package:tiebanana/features/profile/state/profile_events.dart';
import 'package:tiebanana/shared/widgets/avatar_image.dart';
import 'package:tiebanana/shared/content/thread_preview_content.dart';
import 'package:tiebanana/shared/content/special_span.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/moderation/widgets/moderation_actions.dart';
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
      this.dismissible = true});

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

    //动态流看的是「最近一次活动」，拿不到时退回发帖时间。
    final String latest = _timeText(latestTime);
    final String when = latest.isNotEmpty ? latest : _timeText(createTime);

    final String excerpt = _excerpt();

    final TextStyle? metaStyle =
        textTheme.labelSmall?.copyWith(color: tokens.textTertiary);

    return Container(
      margin: const EdgeInsets.fromLTRB(TiebananaMetrics.pageGutter, 0,
          TiebananaMetrics.pageGutter, TiebananaMetrics.gapSm),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: MaterialButton(
        onPressed: () async {
          Navigator.pushNamed(context, PageRouter.threadPage,
              arguments: ThreadPageRouterData(kz: tid, pid: null));
        },
        color: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minWidth: 0,
        padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
        shape: RoundedRectangleBorder(borderRadius: TiebananaMetrics.brLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            //作者行：头像 + 昵称（含等级图标）+ 时间 + 不感兴趣
            Row(
              children: <Widget>[
                Avatar(
                  onTap: () {
                    Navigator.pushNamed(context, PageRouter.user,
                        arguments: author.id);
                  },
                  imgUrl: resolveAvatarUrl(author.portrait),
                  height: TiebananaMetrics.avatarSm,
                  width: TiebananaMetrics.avatarSm,
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
                          style: textTheme.labelMedium
                              ?.copyWith(color: tokens.textPrimary),
                        ),
                      ),
                      ...icons,
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
                          child: Icon(Icons.close,
                              size: TiebananaMetrics.iconSizeSmall,
                              color: tokens.textTertiary),
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
                style:
                    textTheme.titleSmall?.copyWith(color: tokens.textPrimary),
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
            //缩略图（最多三张）
            if (ThreadPreviewMedia.hasContent(firstPostContent)) ...<Widget>[
              const SizedBox(height: TiebananaMetrics.gapSm),
              ThreadPreviewMedia(contents: firstPostContent, threadId: tid),
            ],
            //页脚：吧名 + 浏览量 / 赞同 / 回复
            const SizedBox(height: TiebananaMetrics.gapSm),
            DefaultTextStyle(
              style: metaStyle ?? const TextStyle(),
              child: Row(
                children: <Widget>[
                  // 吧名占满剩余宽度，统计组保持在右侧固定位置。
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
                  IconTheme(
                    data: IconThemeData(
                        color: tokens.textTertiary,
                        size: TiebananaMetrics.iconSizeSmall),
                    child: Row(
                      children: <Widget>[
                        // 用户帖没有浏览量，空串时整组收掉（不然会显示一个孤零零的眼睛 + 0）。
                        if (viewNum.isNotEmpty) ...<Widget>[
                          const Icon(Icons.remove_red_eye),
                          const SizedBox(width: TiebananaMetrics.gapXXs),
                          Text(viewNum),
                          const SizedBox(width: TiebananaMetrics.gapMd),
                        ],
                        // 话题流等来源没有点赞数时整组收掉，不显示一个孤零零的大拇指。
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
                  ),
                ],
              ),
            )
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
      this.radius = 5});

  @override
  _ThumbnailState createState() => _ThumbnailState();
}

class _ThumbnailState extends State<Thumbnail> {
  String heroTagSalt = const Uuid().v4();
  @override
  Widget build(BuildContext context) {
    // 空地址 / 非法地址直接跳过：投票首段之类的 linkImage 可能没有 src。
    final String img = widget.img.trim();
    if (img.isEmpty) {
      return const SizedBox.shrink();
    }
    return Builder(
      builder: (context) {
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
                child: FadeIn(
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
                                LoadState.failed) {
                              return Container(
                                constraints: constraints,
                                alignment: Alignment.center,
                                color: TiebananaTokens.of(context).fill,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 20,
                                  color:
                                      TiebananaTokens.of(context).textTertiary,
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
              ),
            ));
      },
    );
  }
}
