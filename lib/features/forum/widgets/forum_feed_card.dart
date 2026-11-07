import 'package:flutter/material.dart';
import 'package:extended_text/extended_text.dart';
import 'package:tiebanana/shared/content/special_span.dart';
import 'package:tiebanana/shared/content/thread_preview_content.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/app/navigation/route_names.dart';

/// 卡片流卡片（吧页 `page_data.feed_list`）。
///
/// 与帖子流的 [ThreadSummary] 布局不同：**标题在前**，页脚给热度 + 赞 + 回复；
/// 正文摘要与缩略图保留。
class ForumFeedCard extends StatelessWidget {
  final TiebaThreadInfo item;

  const ForumFeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
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
        onPressed: () => Navigator.pushNamed(context, PageRouter.threadPage,
            arguments: ThreadPageRouterData(kz: item.id, pid: null)),
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
            // 标题（卡片流是「标题在前」）
            ExtendedText(
              item.title,
              specialTextSpanBuilder: TiebaSpanBuilder(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(color: tokens.textPrimary),
            ),
            if (ThreadPreviewExcerpt.hasContent(
                item.firstPostContent)) ...<Widget>[
              const SizedBox(height: TiebananaMetrics.gapXs),
              ThreadPreviewExcerpt(contents: item.firstPostContent),
            ],
            if (ThreadPreviewMedia.hasContent(
                item.firstPostContent)) ...<Widget>[
              const SizedBox(height: TiebananaMetrics.gapSm),
              ThreadPreviewMedia(
                  contents: item.firstPostContent, threadId: item.id),
            ],
            const SizedBox(height: TiebananaMetrics.gapSm),
            // 页脚：热度（浏览量）+ 赞 + 回复 + 作者
            DefaultTextStyle(
              style: metaStyle ?? const TextStyle(),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.fname.isEmpty ? '' : '${item.fname}吧',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconTheme(
                    data: IconThemeData(
                        color: tokens.textTertiary,
                        size: TiebananaMetrics.iconSizeSmall),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.local_fire_department),
                        const SizedBox(width: TiebananaMetrics.gapXXs),
                        Text(item.viewNum.isEmpty ? '0' : item.viewNum),
                        const SizedBox(width: TiebananaMetrics.gapMd),
                        const Icon(Icons.thumb_up),
                        const SizedBox(width: TiebananaMetrics.gapXXs),
                        Text(item.agreeNum),
                        const SizedBox(width: TiebananaMetrics.gapMd),
                        const Icon(Icons.speaker_notes),
                        const SizedBox(width: TiebananaMetrics.gapXXs),
                        Text(item.replyNum),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
