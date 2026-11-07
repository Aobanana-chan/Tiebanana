import 'package:flutter/material.dart';

import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
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
/// 主题赞踩只出现在底部回复栏。
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
    final List<TiebaPostContent> displayContent = hasPollMark
        ? contentWithoutUnusableImages(postMain.content)
        : postMain.content;
    final TiebaVoteBadgeContent? voteBadge =
        postMain.content.whereType<TiebaVoteBadgeContent>().firstOrNull;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        TiebananaMetrics.pageGutter,
        TiebananaMetrics.gapMd,
        TiebananaMetrics.pageGutter,
        0,
      ),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          //标题
          SelectionArea(
            child: Text(
              title,
              style: textTheme.titleMedium?.copyWith(color: tokens.textPrimary),
            ),
          ),
          const SizedBox(height: TiebananaMetrics.gapSm),
          //作者行
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Avatar(
                imgUrl: resolveAvatarUrl(author.portrait),
                height: 42,
                width: 42,
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
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: TiebaParser.parseContent(
                context,
                displayContent,
                allImgs,
                allOrgImgs,
                videoInfo: videoInfo,
                selectable: true,
                forumName: forumName,
              ),
            ),
          ),
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
        ],
      ),
    );
  }
}
