import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/message/state/chat_time.dart';
import 'package:tiebanana/features/message/state/chat_content.dart';
import 'package:tiebanana/shared/content/special_span.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/avatar_image.dart';

/// 会话卡片：头像 / 昵称 / 时间 / 最后一条摘要 / 未读。
///
/// 没有关系标签、没有置顶，也不提供长按菜单。
class ConversationCard extends StatelessWidget {
  const ConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
    this.selected = false,
  });

  final TiebaConversation conversation;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool unread = conversation.unread > 0;
    final Color nameColor =
        selected ? tokens.onPrimaryContainer : tokens.textPrimary;
    final Color previewColor = selected
        ? tokens.onPrimaryContainer
        : (unread ? tokens.textPrimary : tokens.textSecondary);
    final Color timeColor =
        selected ? tokens.onPrimaryContainer : tokens.textTertiary;
    final TextStyle? previewStyle = textTheme.bodySmall?.copyWith(
      color: previewColor,
      fontSize: 13,
      fontWeight: unread ? FontWeight.w500 : null,
    );
    final String previewText = conversation.lastMessage.isEmpty
        ? ''
        : chatDisplayText(
            conversation.lastMessageType,
            conversation.lastMessage,
            summary: true,
          );

    return Container(
      margin: const EdgeInsets.fromLTRB(
          TiebananaMetrics.pageGutter, 0, TiebananaMetrics.pageGutter, 8),
      decoration: BoxDecoration(
        color: selected ? tokens.primaryContainer : tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: selected ? null : tokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: TiebananaMetrics.brLg,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(TiebananaMetrics.gapMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _ConversationAvatar(url: conversation.avatar),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              conversation.title.isEmpty
                                  ? '贴吧用户'
                                  : conversation.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                color: nameColor,
                                fontSize: 15,
                                fontWeight:
                                    unread ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (conversation.lastTime != null) ...<Widget>[
                            const SizedBox(width: TiebananaMetrics.gapSm),
                            Text(
                              conversationTime(conversation.lastTime),
                              style: textTheme.labelSmall?.copyWith(
                                color: timeColor,
                                fontSize: 11,
                                fontFeatures: const <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Row(
                              children: <Widget>[
                                // 「我：」比正文更淡，未读时也不跟着加粗。
                                if (conversation.lastMessageIsMine &&
                                    previewText.isNotEmpty)
                                  Text(
                                    '我：',
                                    style: previewStyle?.copyWith(
                                      color: selected
                                          ? tokens.onPrimaryContainer
                                          : tokens.textTertiary,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                Expanded(
                                  child: ExtendedText(
                                    previewText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: previewStyle,
                                    specialTextSpanBuilder: TiebaSpanBuilder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (unread) ...<Widget>[
                            const SizedBox(width: TiebananaMetrics.gapSm),
                            _UnreadMark(
                              count: conversation.unread,
                              muted: conversation.isMuted,
                            ),
                          ] else if (conversation.lastMessageIsMine &&
                              conversation.lastMessage.isNotEmpty) ...<Widget>[
                            const SizedBox(width: TiebananaMetrics.gapSm),
                            Text(
                              conversation.lastMessageRead ? '已读' : '未读',
                              style: textTheme.labelSmall?.copyWith(
                                fontSize: 10.5,
                                color: selected
                                    ? tokens.onPrimaryContainer
                                    : (conversation.lastMessageRead
                                        ? tokens.primary
                                        : tokens.textSecondary),
                                fontWeight: conversation.lastMessageRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                                fontFeatures: const <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ],
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

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: tokens.fill,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? Icon(Icons.person_outline, color: tokens.textTertiary, size: 22)
          : AvatarImage(url: url),
    );
  }
}

class _UnreadMark extends StatelessWidget {
  const _UnreadMark({required this.count, required this.muted});

  final int count;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    if (muted) {
      return Semantics(
        label: '免打扰，$count 条未读',
        child: Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: tokens.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return UnreadCountBadge(count: count);
  }
}

/// 红色未读药丸。列表行、宽屏左栏标题和页签共用同一套尺寸。
class UnreadCountBadge extends StatelessWidget {
  const UnreadCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Semantics(
      label: '$count 条未读',
      child: Container(
        constraints: const BoxConstraints(minWidth: 18),
        height: 18,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: tokens.danger,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(
            count > 99 ? '99+' : '$count',
            style: TextStyle(
              color: tokens.onImage,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              height: 1,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
