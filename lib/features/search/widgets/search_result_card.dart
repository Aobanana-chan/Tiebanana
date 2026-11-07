import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/highlight_text.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';

/// 一条搜索结果：作者行 + 标题 + 摘要，命中的关键词用强调色高亮。
///
/// 吧内搜索与全站搜索共用这一张卡。全站结果跨吧，调用方把 [showForum] 打开，
/// 卡片底部会多一个来源吧名的胶囊。
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.post,
    required this.keyword,
    required this.onTap,
    this.showForum = false,
  });

  final TiebaSearchPost post;
  final String keyword;
  final VoidCallback onTap;

  /// 全站搜索时底部标出 `forumName`；吧内搜索隐藏。
  final bool showForum;

  /// 回复结果的标题接口会带「回复：」前缀，交给「回复」徽章表达，正文里去掉。
  String get _title {
    final String title = post.title;
    if (post.type == 2) {
      if (title.startsWith("回复：")) return title.substring(3);
      if (title.startsWith("回复:")) return title.substring(3);
    }
    return title;
  }

  String get _timeText {
    final int stamp = int.tryParse(post.time) ?? 0;
    return stamp <= 0 ? "" : TiebaParser.getPostTime(intTime: stamp);
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String title = _title;
    final String time = _timeText;
    return Container(
      margin: const EdgeInsets.fromLTRB(TiebananaMetrics.pageGutter, 0,
          TiebananaMetrics.pageGutter, TiebananaMetrics.gapSm),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: MaterialButton(
        onPressed: onTap,
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
            Row(
              children: <Widget>[
                Avatar(
                  onTap: () {
                    // 搜索结果只有昵称与头像，没有 uid，跳不过去用户页；
                    // 点作者等同于点这条结果。
                    onTap();
                  },
                  imgUrl: post.userAvatar,
                  height: TiebananaMetrics.avatarSm,
                  width: TiebananaMetrics.avatarSm,
                ),
                const SizedBox(width: TiebananaMetrics.gapSm),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          post.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium
                              ?.copyWith(color: tokens.textPrimary),
                        ),
                      ),
                      if (post.type == 2) ...<Widget>[
                        const SizedBox(width: TiebananaMetrics.gapXs),
                        _ReplyBadge(tokens: tokens),
                      ],
                      if (time.isNotEmpty) ...<Widget>[
                        const SizedBox(width: TiebananaMetrics.gapXs),
                        Text(
                          time,
                          style: textTheme.labelSmall
                              ?.copyWith(color: tokens.textTertiary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (title.isNotEmpty) ...<Widget>[
              const SizedBox(height: TiebananaMetrics.gapSm),
              HighlightText(
                title,
                keyword: keyword,
                style: textTheme.titleSmall
                    ?.copyWith(color: tokens.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (post.content.isNotEmpty) ...<Widget>[
              const SizedBox(height: TiebananaMetrics.gapXs),
              HighlightText(
                post.content,
                keyword: keyword,
                style: textTheme.bodyMedium
                    ?.copyWith(color: tokens.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (showForum && post.forumName.isNotEmpty) ...<Widget>[
              const SizedBox(height: TiebananaMetrics.gapSm),
              _ForumSource(forumName: post.forumName, tokens: tokens),
            ],
          ],
        ),
      ),
    );
  }
}

/// 来源吧名：全站结果跨吧，需要让用户知道这条属于哪个吧。
class _ForumSource extends StatelessWidget {
  const _ForumSource({required this.forumName, required this.tokens});

  final String forumName;
  final TiebananaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tokens.fill,
        borderRadius: BorderRadius.circular(TiebananaMetrics.radiusXs),
      ),
      child: Text(
        forumName.endsWith("吧") ? forumName : "$forumName吧",
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: tokens.textSecondary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 「回复」徽章：搜索范围含回复时，标出这条命中来自楼层。
class _ReplyBadge extends StatelessWidget {
  const _ReplyBadge({required this.tokens});

  final TiebananaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: TiebananaMetrics.gapXs + 1, vertical: 1),
      decoration: BoxDecoration(
        color: tokens.primaryContainer,
        borderRadius: TiebananaMetrics.brXs,
      ),
      child: Text(
        "回复",
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tokens.onPrimaryContainer, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// 首屏骨架：三张与 [SearchResultCard] 同构的卡片。
class SearchResultSkeletonList extends StatelessWidget {
  const SearchResultSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SearchResultSkeletonCard(),
        SearchResultSkeletonCard(),
        SearchResultSkeletonCard(),
      ],
    );
  }
}

/// 单张结果卡骨架。公共字段与 [SearchResultCard] 对齐：作者行 → 标题 → 两行摘要。
class SearchResultSkeletonCard extends StatelessWidget {
  const SearchResultSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(TiebananaMetrics.pageGutter, 0,
          TiebananaMetrics.pageGutter, TiebananaMetrics.gapSm),
      padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              SkeletonBox(
                  width: TiebananaMetrics.avatarSm,
                  height: TiebananaMetrics.avatarSm,
                  radius: TiebananaMetrics.avatarSm / 2),
              SizedBox(width: TiebananaMetrics.gapSm),
              SkeletonBox(width: 82),
              SizedBox(width: TiebananaMetrics.gapSm),
              SkeletonBox(width: 46),
            ],
          ),
          const SizedBox(height: TiebananaMetrics.gapMd),
          const FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.78,
            child: SkeletonBox(height: 13),
          ),
          const SizedBox(height: TiebananaMetrics.gapSm),
          const SkeletonBox(height: 11),
          const SizedBox(height: TiebananaMetrics.gapXs + 2),
          const FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.58,
            child: SkeletonBox(height: 11),
          ),
        ],
      ),
    );
  }
}
