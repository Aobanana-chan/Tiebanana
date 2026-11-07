import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/content/special_span.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';

///消息卡片：回复我的 / @我的 / 给我点赞 共用一张。
///
///对应概念图 `design/mockups/message.html`（方向 A）：
///头像 + 昵称 + 时间 → 引用行 → 正文 → 来自 X吧，未读点固定在内容区最右侧。
///点赞消息与另外两种共用这张卡片，仅文案和内容来源不同。
class MessageCard extends StatelessWidget {
  const MessageCard(
      {super.key, required this.message, this.unread, this.onRead});

  final TiebaMessage message;
  final bool? unread;
  final VoidCallback? onRead;

  ///未读点直径，概念图为 7px。
  static const double _dotSize = 7;

  ///点卡片进贴：接口给了楼层 id 就落到那一层，没给就进主题首页。
  void _open(BuildContext context) {
    final String tid = message.threadId;
    if (tid.isEmpty || tid == "0") {
      return;
    }
    onRead?.call();
    Navigator.pushNamed(context, PageRouter.threadPage,
        arguments: ThreadPageRouterData(
            kz: tid, pid: message.postId.isEmpty ? null : message.postId));
  }

  ///正文使用 ExtendedText，用于渲染 @某人 / `#(滑稽)` 这类贴吧语法。
  Widget _richText(String text, {required int maxLines, TextStyle? style}) {
    return ExtendedText(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: style,
      specialTextSpanBuilder: TiebaSpanBuilder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isLike = message.kind == TiebaMessageKind.like;
    final TextStyle? metaStyle =
        textTheme.labelSmall?.copyWith(color: tokens.textTertiary);
    final String time =
        message.hasTime ? TiebaParser.getPostTime(dateTime: message.time) : "";

    return Container(
      margin: const EdgeInsets.fromLTRB(TiebananaMetrics.pageGutter, 0,
          TiebananaMetrics.pageGutter, TiebananaMetrics.gapSm),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: TiebananaMetrics.brLg,
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _header(context, tokens, textTheme, metaStyle, time),
                const SizedBox(height: TiebananaMetrics.gapSm),
                if (isLike) ...<Widget>[
                  _likeLine(tokens, textTheme),
                  const SizedBox(height: TiebananaMetrics.gapSm),
                  _quoteBlock(
                    tokens,
                    child: _richText(
                      message.likedText,
                      maxLines: 2,
                      style: textTheme.bodySmall
                          ?.copyWith(color: tokens.textSecondary),
                    ),
                  ),
                ] else ...<Widget>[
                  _quoteBlock(
                    tokens,
                    child: Text(
                      message.quoteLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall
                          ?.copyWith(color: tokens.textSecondary),
                    ),
                  ),
                  const SizedBox(height: TiebananaMetrics.gapSm),
                  _richText(
                    message.content,
                    maxLines: 3,
                    style: textTheme.bodyLarge
                        ?.copyWith(color: tokens.textPrimary),
                  ),
                ],
                const SizedBox(height: TiebananaMetrics.gapSm),
                Text(
                  message.fname.isEmpty ? "" : "来自 ${message.fname}吧",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metaStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ///头像 + 昵称 + 时间 + 未读点。
  Widget _header(
    BuildContext context,
    TiebananaTokens tokens,
    TextTheme textTheme,
    TextStyle? metaStyle,
    String time,
  ) {
    return Row(
      children: <Widget>[
        Avatar(
          imgUrl: resolveAvatarUrl(message.portrait),
          height: TiebananaMetrics.avatarSm,
          width: TiebananaMetrics.avatarSm,
          onTap: message.uid.isEmpty
              ? null
              : () {
                  Navigator.pushNamed(context, PageRouter.user,
                      arguments: message.uid);
                },
        ),
        const SizedBox(width: TiebananaMetrics.gapSm),
        Expanded(
          child: Row(children: <Widget>[
            Flexible(
                child: Text(
              message.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(color: tokens.textPrimary),
            )),
            if (time.isNotEmpty) ...<Widget>[
              const SizedBox(width: TiebananaMetrics.gapSm),
              Text(time, style: metaStyle),
            ],
          ]),
        ),
        const SizedBox(width: TiebananaMetrics.gapSm),
        // 固定 7px 的行尾槽位；已读后保留槽位，昵称和时间不会跳动。
        SizedBox(
          width: _dotSize,
          height: _dotSize,
          child: (unread ?? message.unread)
              ? Semantics(
                  label: '未读消息',
                  child: Container(
                    key: const ValueKey<String>('message-unread-dot'),
                    decoration: BoxDecoration(
                      color: tokens.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }

  ///点赞消息的第二行：图标 + 「赞了我的主题 / 回复」。
  ///
  ///用 primary 的图标点一下「这是个赞」，被赞对象（主题 / 回复）加重，
  ///与概念图的 `.mlike b{font-weight:650}` 一致。
  Widget _likeLine(TiebananaTokens tokens, TextTheme textTheme) {
    final TextStyle? base =
        textTheme.bodySmall?.copyWith(color: tokens.textSecondary, height: 1.2);
    return Row(
      children: <Widget>[
        Icon(Icons.thumb_up,
            size: TiebananaMetrics.iconSizeSmall, color: tokens.primary),
        const SizedBox(width: TiebananaMetrics.gapXs + 2),
        Text.rich(
          TextSpan(
            style: base,
            children: <InlineSpan>[
              const TextSpan(text: "赞了我的"),
              TextSpan(
                text: message.likedThread ? "主题" : "回复",
                style: base?.copyWith(
                    color: tokens.textPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  ///引用块：容器填充色 + 12 圆角，装不下就截断。
  Widget _quoteBlock(TiebananaTokens tokens, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: TiebananaMetrics.gapMd - 1, vertical: 9),
      decoration: BoxDecoration(
        color: tokens.quoteBackground,
        borderRadius: TiebananaMetrics.brSm,
      ),
      child: child,
    );
  }
}
