import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/media/img_explorer.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/features/thread/widgets/thread_common.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';
import 'package:tiebanana/features/thread/widgets/thread_poll_card.dart';

/// 帖子首楼卡片。
///
/// 对应概念图 `design/mockups/thread.html` 的 `.p1`：
/// 标题 → 头像 · 作者 · 更多 → 通栏正文。头像位于作者行，正文通栏展示。
/// 桌面端将附图收成固定 2 列网格，点击进入支持滚轮缩放 / Esc / 方向键的灯箱。
class ThreadFirstComment extends StatelessWidget {
  final TiebaThreadPagePost postMain;
  final TiebaAuthor author;
  final TiebaVideoInfo? videoInfo;
  final List<String> allImgs;
  final List<String> allOrgImgs;
  final String threadID;
  final String threadTitle;
  final ValueNotifier<bool>? storedNotifier;
  final TiebaPoll? poll;
  final bool hasPoll;

  /// 吧 ID，投票时随请求提交。
  final String fid;

  /// 吧名，话题跳转时带上，方便话题页「发帖」回到当前吧。
  final String forumName;

  /// 主楼投票提交回调；为空时投票卡只读。
  final Future<void> Function(Set<int> optionIds)? onVote;

  final bool desktop;
  final EdgeInsetsGeometry? margin;
  final ThreadAgreeController? agreeController;
  final VoidCallback? onToggleStore;
  final VoidCallback? onShare;
  final int? replyCount;

  const ThreadFirstComment({
    super.key,
    required this.postMain,
    required this.author,
    this.videoInfo,
    required this.allImgs,
    required this.allOrgImgs,
    required this.threadID,
    required this.threadTitle,
    this.storedNotifier,
    this.poll,
    this.hasPoll = false,
    this.fid = '',
    this.forumName = '',
    this.onVote,
    this.desktop = false,
    this.margin,
    this.agreeController,
    this.onToggleStore,
    this.onShare,
    this.replyCount,
  });

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String title =
        postMain.title.trim().isEmpty ? threadTitle : postMain.title;
    final List<Widget> icons = TiebaParser.processIcon(author) ?? <Widget>[];

    // 与楼层卡一致：投票封面 / 阵营图片没有可用地址时直接过滤。
    final bool hasPollMark =
        poll != null || postMain.poll != null || hasPoll || postMain.hasPoll;
    final List<TiebaPostContent> usableContent = hasPollMark
        ? contentWithoutUnusableImages(postMain.content)
        : postMain.content;
    final TiebaVoteBadgeContent? voteBadge =
        postMain.content.whereType<TiebaVoteBadgeContent>().firstOrNull;

    final List<TiebaImageContent> desktopImages = desktop
        ? usableContent.whereType<TiebaImageContent>().toList()
        : const <TiebaImageContent>[];
    final List<TiebaPostContent> bodyContent = desktop
        ? usableContent
            .where((TiebaPostContent c) => c is! TiebaImageContent)
            .toList()
        : usableContent;

    return Container(
      margin: margin ??
          EdgeInsets.fromLTRB(
            desktop ? 0 : TiebananaMetrics.pageGutter,
            desktop ? 0 : TiebananaMetrics.gapMd,
            desktop ? 0 : TiebananaMetrics.pageGutter,
            0,
          ),
      padding: desktop
          ? const EdgeInsets.fromLTRB(20, 18, 20, 14)
          : const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: desktop ? TiebananaMetrics.brXl : TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          //标题
          SelectionArea(
            child: Text(
              title,
              style: (desktop ? textTheme.headlineSmall : textTheme.titleMedium)
                  ?.copyWith(color: tokens.textPrimary),
            ),
          ),
          const SizedBox(height: TiebananaMetrics.gapSm),
          //作者行
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Avatar(
                imgUrl: resolveAvatarUrl(author.portrait),
                height: desktop ? 36 : 42,
                width: desktop ? 36 : 42,
                onTap: () {
                  Navigator.pushNamed(context, PageRouter.user,
                      arguments: author.id);
                },
              ),
              const SizedBox(width: TiebananaMetrics.gapSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: ThreadAuthorLine(
                            forumRole: author.forumRole,
                            name: author.name,
                            level: author.levelID,
                            icons: icons,
                            isOp: true,
                            isDeleted: postMain.isDeleted,
                          ),
                        ),
                        const SizedBox(width: TiebananaMetrics.gapXs),
                        ThreadMoreButton(
                          threadId: threadID,
                          postId: postMain.id,
                          authorId: author.id,
                          authorName: author.name,
                          portrait: author.portrait,
                          summary: title,
                          reportKind: TiebaReportKind.thread,
                          storedNotifier: storedNotifier,
                        ),
                      ],
                    ),
                    const SizedBox(height: TiebananaMetrics.gapXs),
                    ThreadPostMeta(
                      time: threadTimeText(postMain.createTime),
                      ipLocation: postMain.ipLocation,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TiebananaMetrics.gapMd),
          if (voteBadge != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: ThreadVoteBadge(badge: voteBadge),
            ),
            const SizedBox(height: TiebananaMetrics.gapSm),
          ],
          // 首楼独立于回复楼层的左侧头像轨道，正文与标题左右对齐。
          if (bodyContent.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: TiebaParser.parseContent(
                  context,
                  bodyContent,
                  allImgs,
                  allOrgImgs,
                  videoInfo: videoInfo,
                  selectable: true,
                  forumName: forumName,
                ),
              ),
            ),
          if (desktop && desktopImages.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _DesktopPhotoGrid(
              images: desktopImages,
              allImgs: allImgs,
              allOrgImgs: allOrgImgs,
            ),
          ],
          if (poll != null ||
              hasPoll ||
              postMain.poll != null ||
              postMain.hasPoll) ...[
            const SizedBox(height: TiebananaMetrics.gapMd),
            ThreadPollCard(
              poll: poll ?? postMain.poll,
              onVote: onVote,
            ),
          ],
          if (desktop) ...<Widget>[
            const SizedBox(height: 14),
            Divider(height: 1, color: tokens.line),
            const SizedBox(height: 10),
            _desktopFooter(context, tokens, textTheme),
          ],
        ],
      ),
    );
  }

  Widget _desktopFooter(
    BuildContext context,
    TiebananaTokens tokens,
    TextTheme textTheme,
  ) {
    return Row(
      children: <Widget>[
        if (replyCount != null)
          Text(
            '已加载 $replyCount 条回复',
            style: textTheme.labelSmall?.copyWith(color: tokens.textTertiary),
          ),
        const Spacer(),
        if (agreeController != null)
          AnimatedBuilder(
            animation: agreeController!,
            builder: (BuildContext context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _FooterBtn(
                  icon: agreeController!.liked
                      ? Icons.thumb_up_alt_rounded
                      : Icons.thumb_up_alt_outlined,
                  label: threadCountText(agreeController!.agreeNum),
                  active: agreeController!.liked,
                  onTap: agreeController!.busy
                      ? null
                      : () => agreeController!.toggleLike(),
                ),
                const SizedBox(width: 4),
                _FooterBtn(
                  icon: agreeController!.disliked
                      ? Icons.thumb_down_alt_rounded
                      : Icons.thumb_down_alt_outlined,
                  label: '',
                  active: agreeController!.disliked,
                  onTap: agreeController!.busy
                      ? null
                      : () => agreeController!.toggleDislike(),
                ),
              ],
            ),
          ),
        if (storedNotifier != null) ...<Widget>[
          const SizedBox(width: 4),
          ValueListenableBuilder<bool>(
            valueListenable: storedNotifier!,
            builder: (BuildContext context, bool stored, _) => _FooterBtn(
              icon: stored ? Icons.star_rounded : Icons.star_border_rounded,
              label: stored ? '已收藏' : '收藏',
              active: stored,
              onTap: onToggleStore,
            ),
          ),
        ],
        if (onShare != null) ...<Widget>[
          const SizedBox(width: 4),
          _FooterBtn(
            icon: Icons.share_outlined,
            label: '分享',
            onTap: onShare,
          ),
        ],
      ],
    );
  }
}

class _FooterBtn extends StatelessWidget {
  const _FooterBtn({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Color fg = active ? tokens.primary : tokens.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: SizedBox(
        height: 26,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 14, color: fg),
              if (label.isNotEmpty) ...<Widget>[
                const SizedBox(width: 5),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: fg,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 桌面端首楼固定 2 列配图网格：点击在灯箱中查看，支持滚轮缩放 / Esc / 左右键切图。
class _DesktopPhotoGrid extends StatelessWidget {
  const _DesktopPhotoGrid({
    required this.images,
    required this.allImgs,
    required this.allOrgImgs,
  });

  final List<TiebaImageContent> images;
  final List<String> allImgs;
  final List<String> allOrgImgs;

  void _openLightbox(BuildContext context, TiebaImageContent image) {
    final List<String> urls = allImgs.isNotEmpty
        ? allImgs
        : images.map((TiebaImageContent e) => e.displaySrc).toList();
    final List<String?> origUrls = allOrgImgs.isNotEmpty
        ? allOrgImgs
        : images.map((TiebaImageContent e) => e.originalSrc).toList();
    final int idx = urls.indexOf(image.displaySrc);
    Navigator.push(
      context,
      ImageExplorerRoute(
        builder: (_) => ZoomedImgExplorer(
          imgUrls: urls,
          highQualityUrls: origUrls,
          index: idx < 0 ? 0 : idx,
          heroTagSalt: 'first-photo-${identityHashCode(images)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final int rows = (images.length / 2).ceil();
    final int picSetting = Global.setting.pictureLoadSetting ?? 0;

    return Column(
      children: <Widget>[
        for (int r = 0; r < rows; r++) ...<Widget>[
          if (r > 0) const SizedBox(height: 8),
          Row(
            children: <Widget>[
              for (int c = 0; c < 2; c++) ...<Widget>[
                if (c > 0) const SizedBox(width: 8),
                Expanded(
                  child: (r * 2 + c) < images.length
                      ? _buildCell(
                          context,
                          tokens,
                          images[r * 2 + c],
                          r * 2 + c,
                          picSetting,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCell(
    BuildContext context,
    TiebananaTokens tokens,
    TiebaImageContent image,
    int index,
    int picSetting,
  ) {
    final String url = picSetting == 2 ? image.originalSrc : image.lowFlowSrc;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openLightbox(context, image),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 156,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Container(
                  color: tokens.fill,
                  child: ExtendedImage.network(
                    url.isEmpty ? image.displaySrc : url,
                    fit: BoxFit.cover,
                    cache: true,
                    loadStateChanged: (ExtendedImageState state) {
                      if (state.extendedImageLoadState == LoadState.failed) {
                        return Center(
                          child: Icon(Icons.image_not_supported_outlined,
                              color: tokens.textTertiary),
                        );
                      }
                      return null;
                    },
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: tokens.imageScrim.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '${index + 1}/${images.length}',
                        style: TextStyle(
                          fontSize: 10,
                          color: tokens.onImage,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
