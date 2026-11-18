import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/message/state/notification_time.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 吧广播历史卡片。
///
/// 只展示协议给出的字段；没有点赞、评论、转发、收藏，也不显示审核状态。
class BroadcastCard extends StatefulWidget {
  const BroadcastCard({
    super.key,
    required this.item,
    required this.onOpenThread,
  });

  final TiebaBroadcastItem item;
  final VoidCallback onOpenThread;

  @override
  State<BroadcastCard> createState() => _BroadcastCardState();
}

class _BroadcastCardState extends State<BroadcastCard> {
  bool _expanded = false;

  /// 粗略判断是否超过 3 行：按典型 12.5px 字号、每行约 30 个汉字估算。
  /// 协议没有给排版信息，这里只用来避免短正文也出现「展开全文」。
  bool get _isLong {
    final String content = widget.item.content;
    if (content.isEmpty) return false;
    final int newlines = '\n'.allMatches(content).length;
    return newlines >= 3 || content.runes.length > 90;
  }

  @override
  Widget build(BuildContext context) {
    final TiebaBroadcastItem item = widget.item;
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasThread = item.hasThread;
    final String time = broadcastTimeLabel(item.publishTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: TiebananaMetrics.brLg,
          onTap: () {
            if (hasThread) {
              widget.onOpenThread();
            } else {
              setState(() => _expanded = !_expanded);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
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
                          if (item.hasTitle) ...<Widget>[
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                color: tokens.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (item.hasContent)
                            Text(
                              item.content,
                              maxLines: _expanded ? null : 3,
                              overflow: _expanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: tokens.textSecondary,
                                fontSize: 12.5,
                                height: 1.65,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (item.hasImage) ...<Widget>[
                      const SizedBox(width: 11),
                      _Thumb(url: item.picUrl),
                    ],
                  ],
                ),
                if (time.isNotEmpty ||
                    item.pushUserCount > 0 ||
                    item.pv >= 0) ...<Widget>[
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: <Widget>[
                      if (time.isNotEmpty)
                        _Meta(
                          icon: Icons.schedule_rounded,
                          text: time,
                          tokens: tokens,
                        ),
                      if (item.pushUserCount > 0)
                        _Meta(
                          icon: Icons.groups_2_outlined,
                          text: '推送给 ${groupedCount(item.pushUserCount)} 人',
                          tokens: tokens,
                        ),
                      _Meta(
                        icon: Icons.visibility_outlined,
                        text: '阅读 ${groupedCount(item.pv)}',
                        tokens: tokens,
                      ),
                    ],
                  ),
                ],
                if (hasThread ||
                    (item.hasContent && !_expanded && _isLong) ||
                    _expanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: <Widget>[
                        Text(
                          hasThread ? '查看帖子' : (_expanded ? '收起' : '展开全文'),
                          style: TextStyle(
                            color: hasThread
                                ? tokens.primary
                                : tokens.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          hasThread
                              ? Icons.arrow_forward_rounded
                              : (_expanded
                                  ? Icons.expand_less
                                  : Icons.expand_more),
                          size: 13,
                          color:
                              hasThread ? tokens.primary : tokens.textTertiary,
                        ),
                      ],
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

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return ClipRRect(
      borderRadius: TiebananaMetrics.brSm,
      child: SizedBox(
        width: 88,
        height: 66,
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

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, required this.tokens});

  final IconData icon;
  final String text;
  final TiebananaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 13, color: tokens.textTertiary),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: tokens.textTertiary,
            fontSize: 10.5,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
