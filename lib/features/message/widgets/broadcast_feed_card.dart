import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/message/state/notification_time.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/avatar_image.dart';

/// 吧广播聚合流里的一张卡。
///
/// 版式对齐官方：标题、正文、右侧图片、吧信息与分享 / 评论 / 点赞数。
class BroadcastFeedCard extends StatelessWidget {
  const BroadcastFeedCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final TiebaBroadcastItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          TiebananaMetrics.pageGutter, 0, TiebananaMetrics.pageGutter, 10),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: TiebananaMetrics.brLg,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (item.hasTitle)
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                color: tokens.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          if (item.hasTitle && item.hasContent)
                            const SizedBox(height: 6),
                          if (item.hasContent)
                            Text(
                              item.content,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: tokens.textSecondary,
                                fontSize: 13.5,
                                height: 1.65,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (item.hasImage) ...<Widget>[
                      const SizedBox(width: 10),
                      _FeedThumb(url: item.picUrl),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    _ForumLine(item: item, tokens: tokens),
                    const Spacer(),
                    _Count(
                      icon: Icons.ios_share,
                      label: item.shareCount > 0
                          ? groupedCount(item.shareCount)
                          : '分享',
                      tokens: tokens,
                    ),
                    const SizedBox(width: 16),
                    _Count(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: groupedCount(item.commentCount),
                      tokens: tokens,
                    ),
                    const SizedBox(width: 16),
                    _Count(
                      icon: Icons.thumb_up_outlined,
                      label: groupedCount(item.likeCount),
                      tokens: tokens,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ForumLine extends StatelessWidget {
  const _ForumLine({required this.item, required this.tokens});

  final TiebaBroadcastItem item;
  final TiebananaTokens tokens;

  @override
  Widget build(BuildContext context) {
    final String name = item.forumName.trim();
    if (name.isEmpty) return const SizedBox.shrink();
    final String label = name.endsWith('吧') ? name : '$name吧';
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ForumAvatar(name: label, url: item.forumAvatar, tokens: tokens),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForumAvatar extends StatelessWidget {
  const _ForumAvatar({
    required this.name,
    required this.url,
    required this.tokens,
  });

  final String name;
  final String url;
  final TiebananaTokens tokens;

  @override
  Widget build(BuildContext context) {
    final String letter = name.isEmpty ? '吧' : name.substring(0, 1);
    return ClipOval(
      child: SizedBox(
        width: 20,
        height: 20,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Container(
              color: tokens.primaryContainer,
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                  color: tokens.onPrimaryContainer,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (url.isNotEmpty) AvatarImage(url: url),
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.icon,
    required this.label,
    required this.tokens,
  });

  final IconData icon;
  final String label;
  final TiebananaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: tokens.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: tokens.textTertiary,
            fontSize: 12.5,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _FeedThumb extends StatelessWidget {
  const _FeedThumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return ClipRRect(
      borderRadius: TiebananaMetrics.brSm,
      child: SizedBox(
        width: 92,
        height: 72,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stack) {
            return ColoredBox(
              color: tokens.fill,
              child: Icon(Icons.image_not_supported_outlined,
                  size: 18, color: tokens.textTertiary),
            );
          },
          loadingBuilder:
              (BuildContext context, Widget child, ImageChunkEvent? progress) {
            if (progress == null) return child;
            return ColoredBox(color: tokens.fill);
          },
        ),
      ),
    );
  }
}
