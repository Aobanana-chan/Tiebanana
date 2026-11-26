// ignore_for_file: use_build_context_synchronously

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:provider/provider.dart';

import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/thread/state/reply_events.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/features/thread/data/thread_cache.dart';
import 'package:tiebanana/app/navigation/link_router.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/moderation/widgets/moderation_actions.dart';
import 'package:tiebanana/features/thread/pages/thread_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/adaptive_panel.dart';
import 'package:tiebanana/shared/content/special_span.dart';
import 'package:tiebanana/shared/content/post_link_span.dart';
import 'package:tiebanana/features/thread/widgets/thread_common.dart';
import 'package:tiebanana/features/thread/widgets/thread_reply_bar.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';
import 'package:tiebanana/shared/media/img_explorer.dart';
import 'package:tiebanana/features/thread/widgets/thread_poll_card.dart';

/// 帖子楼层卡片。
///
/// 对应概念图 `design/mockups/thread.html` 的 `.floor`：
/// 左轨（头像 + 楼层号）· 作者身份 · 正文 · 底部赞踩 / 更多，整卡可点即回复；
/// 楼中楼是卡内的 `surface-2` 容器。
class ThreadFloorComment extends StatefulWidget {
  final TiebaForum forum;
  final TiebaThreadPagePost postMain;
  final TiebaAuthor author;
  final TiebaVideoInfo? videoInfo;
  final List<String> allImgs;
  final List<String> allOrgImgs;
  final Map<String, TiebaAuthor> userList;
  final String threadID;
  final String threadTitle;
  final bool isOp;
  final String threadOwnerUid;
  final ValueNotifier<bool>? storedNotifier;
  final bool desktop;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onDesktopReply;

  const ThreadFloorComment({
    super.key,
    required this.author,
    this.videoInfo,
    required this.allImgs,
    required this.allOrgImgs,
    required this.postMain,
    required this.userList,
    required this.threadID,
    required this.threadTitle,
    required this.forum,
    this.isOp = false,
    this.threadOwnerUid = '',
    this.storedNotifier,
    this.desktop = false,
    this.margin,
    this.onDesktopReply,
  });

  @override
  State<ThreadFloorComment> createState() => _ThreadFloorCommentState();
}

class _ThreadFloorCommentState extends State<ThreadFloorComment> {
  bool _hovered = false;

  void _openReply(BuildContext context) {
    if (widget.onDesktopReply != null) {
      widget.onDesktopReply!();
      return;
    }
    showReplyPanel(
      context,
      (BuildContext context) {
        return ReplyBottomSheet(
          replyText: TiebaParser.parserContentString(widget.postMain.content),
          targetName: widget.author.name,
          targetMeta: '${widget.postMain.floor}楼 · '
              '${threadMetaText(threadTimeText(widget.postMain.createTime), widget.postMain.ipLocation)}',
          threadTitle: widget.threadTitle,
          kw: widget.forum.forumName,
          fid: widget.forum.fid,
          tid: widget.threadID,
          floorId: widget.postMain.id,
          isReplyThread: false,
        );
      },
    );
  }

  void _openReport(BuildContext context) {
    openReportPage(
      context,
      TiebaReportTarget(
        kind: TiebaReportKind.reply,
        userId: widget.author.id,
        name: widget.author.name,
        portrait: widget.author.portrait,
        threadId: widget.threadID,
        postId: widget.postMain.id,
        summary: widget.postMain.content
            .whereType<TiebaTextContent>()
            .map((part) => part.text)
            .join(),
        source: '${widget.postMain.floor ?? ''} 楼',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThreadPageMainState? readingHistoryPid =
        context.findAncestorStateOfType<ThreadPageMainState>();
    readingHistoryPid?.pid = widget.postMain.id;
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final List<Widget> icons =
        TiebaParser.processIcon(widget.author) ?? <Widget>[];
    final int subCount = int.tryParse(widget.postMain.subPostNumber) ??
        widget.postMain.subPostList.length;

    // 当帖子含有投票时，content 里的投票封面 / 阵营图片常常没有可用地址。
    // 这里剔除这类无效图片，正常配图保留。
    final List<TiebaPostContent> displayContent =
        widget.postMain.hasPoll || widget.postMain.poll != null
            ? contentWithoutUnusableImages(widget.postMain.content)
            : widget.postMain.content;
    // 作者投的阵营徽章（type 52）。官方把徽章放在正文最前面。
    final TiebaVoteBadgeContent? voteBadge =
        widget.postMain.content.whereType<TiebaVoteBadgeContent>().firstOrNull;

    final Widget card = Container(
      margin: widget.margin ??
          EdgeInsets.fromLTRB(
            widget.desktop ? 0 : TiebananaMetrics.pageGutter,
            0,
            widget.desktop ? 0 : TiebananaMetrics.pageGutter,
            widget.desktop ? 10 : TiebananaMetrics.gapSm,
          ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
        border: widget.desktop
            ? Border.all(color: _hovered ? tokens.line : Colors.transparent)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: TiebananaMetrics.brLg,
        child: InkWell(
          borderRadius: TiebananaMetrics.brLg,
          onTap: () => _openReply(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 13, 13, 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                //左轨：头像 + 楼层号，单独占一列
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Avatar(
                      imgUrl: resolveAvatarUrl(widget.author.portrait),
                      height: 34,
                      width: 34,
                      onTap: () {
                        Navigator.pushNamed(context, PageRouter.user,
                            arguments: widget.author.id);
                      },
                    ),
                    const SizedBox(height: TiebananaMetrics.gapXXs),
                    ThreadFloorTag(
                      floor: widget.postMain.floor,
                      isOp: widget.isOp,
                    ),
                    if (voteBadge != null) ...[
                      const SizedBox(height: TiebananaMetrics.gapXXs),
                      // 用户投的阵营放在楼层号下面，约为主楼徽章的 0.8 倍。
                      ThreadVoteBadge(badge: voteBadge, height: 19.2),
                    ],
                  ],
                ),
                const SizedBox(width: TiebananaMetrics.gapSm),
                //作者、正文、楼中楼统一从右轨开始
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // 作者行与操作按钮同行：作者信息 Expanded 自然换行，
                      // 按钮组 mainAxisSize.min 钉在右上角，名字再长也不会挤走按钮。
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: ThreadAuthorLine(
                              forumRole: widget.author.forumRole,
                              name: widget.author.name,
                              level: widget.author.levelID,
                              icons: icons,
                              isOp: widget.isOp,
                              isDeleted: widget.postMain.isDeleted,
                            ),
                          ),
                          const SizedBox(width: TiebananaMetrics.gapSm),
                          if (widget.desktop)
                            Text(
                              '#${widget.postMain.floor ?? ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                color: tokens.textTertiary,
                                fontFeatures: const <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ThreadVoteBar(
                                  key: ValueKey<String>(
                                      'vote-${widget.postMain.id}'),
                                  postId: widget.postMain.id,
                                  threadId: widget.threadID,
                                  objType: 1,
                                  forumId: widget.forum.fid,
                                  agreeNum:
                                      int.tryParse(widget.postMain.agreeNum) ??
                                          0,
                                  disagreeNum: int.tryParse(
                                          widget.postMain.disagreeNum) ??
                                      0,
                                  hasAgree: widget.postMain.hasAgree,
                                  agreeType:
                                      int.tryParse(widget.postMain.agreeType) ??
                                          0,
                                ),
                                const SizedBox(width: 5),
                                ThreadMoreButton(
                                  threadId: widget.threadID,
                                  postId: widget.postMain.id,
                                  storedNotifier: widget.storedNotifier,
                                  authorId: widget.author.id,
                                  authorName: widget.author.name,
                                  portrait: widget.author.portrait,
                                  summary: widget.postMain.content
                                      .whereType<TiebaTextContent>()
                                      .map((part) => part.text)
                                      .join(),
                                  source: '${widget.postMain.floor ?? ''} 楼',
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: TiebananaMetrics.gapXs),
                      ThreadPostMeta(
                        time: threadTimeText(widget.postMain.createTime),
                        ipLocation: widget.postMain.ipLocation,
                      ),
                      const SizedBox(height: TiebananaMetrics.gapSm),
                      Wrap(
                        children: TiebaParser.parseContent(
                          context,
                          displayContent,
                          widget.allImgs,
                          widget.allOrgImgs,
                          videoInfo: widget.videoInfo,
                          selectable: true,
                          forumName: widget.forum.forumName,
                        ),
                      ),
                      if (widget.postMain.poll != null ||
                          widget.postMain.hasPoll) ...[
                        const SizedBox(height: TiebananaMetrics.gapMd),
                        // 卡内投票区域拦截点击，避免触发整层的「回复」操作。
                        // 当 poll==null（服务端仅标记 hasPoll）时，只显示文字占位。
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: ThreadPollCard(
                              poll: widget.postMain.poll, compact: true),
                        ),
                      ],
                      if (subCount > 0 || widget.postMain.subPostList.isNotEmpty)
                        InnerFloorEntry(
                          subPostList: widget.postMain.subPostList,
                          userlist: widget.userList,
                          subPostNumber: widget.postMain.subPostNumber,
                          floorNum: widget.postMain.floor.toString(),
                          kz: widget.threadID,
                          pid: widget.postMain.id,
                          forum: widget.forum,
                          threadTitle: widget.threadTitle,
                          threadOwnerUid: widget.threadOwnerUid,
                        ),
                      if (widget.desktop) ...<Widget>[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IgnorePointer(
                            ignoring: !_hovered,
                            child: AnimatedOpacity(
                              opacity: _hovered ? 1 : 0,
                              duration: TiebananaMetrics.durationFast,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  _DesktopFloorBtn(
                                    icon: Icons.reply_rounded,
                                    label: '回复',
                                    onTap: () => _openReply(context),
                                  ),
                                  const SizedBox(width: 6),
                                  ThreadVoteBar(
                                    key: ValueKey<String>(
                                        'vote-${widget.postMain.id}'),
                                    postId: widget.postMain.id,
                                    threadId: widget.threadID,
                                    objType: 1,
                                    forumId: widget.forum.fid,
                                    agreeNum: int.tryParse(
                                            widget.postMain.agreeNum) ??
                                        0,
                                    disagreeNum: int.tryParse(
                                            widget.postMain.disagreeNum) ??
                                        0,
                                    hasAgree: widget.postMain.hasAgree,
                                    agreeType: int.tryParse(
                                            widget.postMain.agreeType) ??
                                        0,
                                  ),
                                  if ((int.tryParse(widget.postMain.id) ?? 0) >
                                      0) ...<Widget>[
                                    const SizedBox(width: 6),
                                    _DesktopFloorBtn(
                                      icon: Icons.flag_outlined,
                                      label: '举报',
                                      onTap: () => _openReport(context),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!widget.desktop) return card;
    return MouseRegion(
      onEnter: (_) {
        if (!_hovered) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: card,
    );
  }
}

class _DesktopFloorBtn extends StatelessWidget {
  const _DesktopFloorBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: SizedBox(
        height: 25,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 13, color: tokens.textTertiary),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10.5,
                      color: tokens.textTertiary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 楼中楼容器。
///
/// 有内容时展开前两条 + 「查看剩余」；只有计数、没有内容时显示折叠入口。
class InnerFloorEntry extends StatelessWidget {
  final Map<String, TiebaAuthor> userlist;
  final List<TiebaSubPost> subPostList;
  final String subPostNumber;
  final String floorNum;
  final String kz;
  final String pid;
  final TiebaForum forum;
  final String threadTitle;
  final String threadOwnerUid;

  const InnerFloorEntry({
    super.key,
    required this.subPostList,
    required this.userlist,
    required this.subPostNumber,
    required this.floorNum,
    required this.kz,
    required this.pid,
    required this.forum,
    required this.threadTitle,
    required this.threadOwnerUid,
  });

  /// 卡内最多展开几条，剩下的交给底部面板。
  static const int _visibleLimit = 2;

  void _openSheet(BuildContext context, {String spid = ''}) {
    final page = context.findAncestorStateOfType<ThreadPageMainState>();
    showAdaptivePanel<void>(
      context: context,
      maxWidth: 560,
      builder: (BuildContext context) => InnerFloorBottomSheet(
        floorNum: floorNum,
        kz: kz,
        pid: pid,
        spid: spid,
        forum: forum,
        session: page?.session,
        cacheUid: page?.cacheUid,
        cachedPost: page?.info.postList.where((p) => p.id == pid).firstOrNull,
        cachedAuthors: userlist,
        threadOwnerUid: threadOwnerUid,
      ),
    );
  }

  void _openReply(BuildContext context, TiebaSubPost post) {
    final TiebaAuthor? author = userlist[post.uid];
    if (author == null) return;
    showReplyPanel(
      context,
      (BuildContext context) => ReplyBottomSheet(
        replyText: TiebaParser.parserContentString(_innerPreviewBody(post)),
        targetName: author.name,
        targetMeta: '$floorNum楼回复',
        threadTitle: threadTitle,
        kw: forum.forumName,
        fid: forum.fid,
        tid: kz,
        floorId: pid,
        isReplyThread: false,
        replyUser: author,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int total = int.tryParse(subPostNumber) ?? subPostList.length;

    if (total <= 0 && subPostList.isEmpty) {
      return const SizedBox.shrink();
    }

    //只有计数没有内容：一条折叠入口。
    if (subPostList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Material(
          color: tokens.surfaceAlt,
          borderRadius: TiebananaMetrics.brCtl,
          child: InkWell(
            borderRadius: TiebananaMetrics.brCtl,
            onTap: () => _openSheet(context),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: <Widget>[
                  Icon(Icons.mode_comment_outlined,
                      size: 14, color: tokens.primary),
                  const SizedBox(width: 6),
                  Text(
                    '楼中楼',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$total 条回复',
                    style: textTheme.labelSmall
                        ?.copyWith(color: tokens.textTertiary),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: tokens.textTertiary),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final List<TiebaSubPost> visible = subPostList
        .take(subPostList.length > _visibleLimit
            ? _visibleLimit
            : subPostList.length)
        .toList();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: TiebananaMetrics.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openSheet(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: <Widget>[
                  Icon(Icons.mode_comment_outlined,
                      size: 13, color: tokens.primary),
                  const SizedBox(width: 5),
                  Text(
                    '楼中楼',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$total 条回复',
                    style: textTheme.labelSmall
                        ?.copyWith(color: tokens.textTertiary),
                  ),
                ],
              ),
            ),
          ),
          for (final TiebaSubPost post in visible)
            _InnerFloorRow(
              threadId: kz,
              post: post,
              author: userlist[post.uid],
              isOp: threadOwnerUid.isNotEmpty && post.uid == threadOwnerUid,
              onTap: () => _openSheet(context, spid: post.id),
              onReply: () => _openReply(context, post),
              forumName: forum.forumName,
            ),
          if (total > visible.length)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Material(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _openSheet(context),
                  child: Container(
                    height: 32,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          '查看剩余 ${total - visible.length} 条回复',
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: tokens.primary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.expand_more_rounded,
                            size: 14, color: tokens.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InnerFloorRow extends StatelessWidget {
  const _InnerFloorRow({
    required this.threadId,
    required this.post,
    required this.author,
    required this.isOp,
    required this.onTap,
    required this.onReply,
    required this.forumName,
  });

  final TiebaSubPost post;
  final String threadId;
  final TiebaAuthor? author;
  final bool isOp;
  final VoidCallback onTap;
  final VoidCallback onReply;
  final String forumName;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TiebaAuthor user = author ??
        TiebaAuthor(
            icons: const [],
            levelID: null,
            nameShow: post.nameShow,
            portrait: post.portrait,
            uid: post.uid,
            username: post.username);
    final int likes = int.tryParse(post.agreeNum) ?? 0;
    final body = _innerPreviewBody(post);
    return InkWell(
      borderRadius: TiebananaMetrics.brCtl,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Avatar(
              imgUrl: resolveAvatarUrl(user.portrait),
              height: 24,
              width: 24,
            ),
            const SizedBox(width: TiebananaMetrics.gapSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ThreadAuthorLine(
                    name: user.name.isEmpty ? '' : '${user.name}：',
                    level: null,
                    icons: const <Widget>[],
                    isOp: isOp,
                    forumRole: user.forumRole,
                    isDeleted: post.isDeleted,
                  ),
                  const SizedBox(height: 2),
                  InnerPost(posts: body, forumName: forumName),
                  const SizedBox(height: 3),
                  Text(
                    threadTimeText(post.createTime),
                    style: textTheme.labelSmall
                        ?.copyWith(color: tokens.textTertiary),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: <Widget>[
                      _SubAction(label: '回复', onTap: onReply),
                      const SizedBox(width: 12),
                      Text(
                        '赞 $likes',
                        style: textTheme.labelSmall
                            ?.copyWith(color: tokens.textTertiary),
                      ),
                      const Spacer(),
                      ThreadMoreButton(
                          threadId: threadId,
                          postId: post.id,
                          authorId: post.uid,
                          authorName: user.name,
                          portrait: user.portrait,
                           summary: body
                              .whereType<TiebaTextContent>()
                              .map((part) => part.text)
                              .join(),
                          reportKind: TiebaReportKind.subReply),
                    ],
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

final _innerPreviewSeparator =
    RegExp(r'^[ \t\u00a0\u3000]*[:：][ \t\u00a0\u3000]*');

/// 帖子页的预览有时把昵称分隔符放在正文开头；正式回复不走这条路径。
List<TiebaPostContent> _innerPreviewBody(TiebaSubPost post) {
  final content = post.content;
  for (var i = 0; i < content.length; i++) {
    final part = content[i];
    if (part is! TiebaTextContent) break;
    if (part.text.isEmpty) continue;
    final separator = _innerPreviewSeparator.firstMatch(part.text);
    if (separator == null) break;
    return [
      if (separator.end < part.text.length)
        TiebaTextContent(
          text: part.text.substring(separator.end),
          uid: part.uid,
          type: part.type,
        ),
      ...content.skip(i + 1),
    ];
  }
  return content;
}

/// 从帖子页恢复面板时，不修改仍在帖子页使用的预览对象。
TiebaSubPost _innerReplyFromPreview(TiebaSubPost post) {
  final body = _innerPreviewBody(post);
  if (identical(body, post.content)) return post;
  return TiebaSubPost(
    id: post.id,
    title: post.title,
    isVoice: post.isVoice,
    agreeNum: post.agreeNum,
    disagreeNum: post.disagreeNum,
    hasAgree: post.hasAgree,
    agreeType: post.agreeType,
    content: body,
    createTime: post.createTime,
    isFirstFloor: post.isFirstFloor,
    isInnerFloor: post.isInnerFloor,
    portrait: post.portrait,
    uid: post.uid,
    nameShow: post.nameShow,
    username: post.username,
  )..isDeleted = post.isDeleted;
}

class _SubAction extends StatelessWidget {
  const _SubAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: tokens.primary,
            ),
      ),
    );
  }
}

/// 楼中楼正文。只渲染内容本身，作者名由外层标题行显示。
class InnerPost extends StatelessWidget {
  final List<TiebaPostContent> posts;
  final String forumName;

  const InnerPost({super.key, required this.posts, this.forumName = ''});

  List<InlineSpan> _buildContent(BuildContext context) {
    final List<InlineSpan> spans = <InlineSpan>[];
    for (final TiebaPostContent content in posts) {
      if (content is TiebaTextContent) {
        // 正文不跳用户页；回帖里的“回复某某”段同样按普通文字处理。
        // 只有真正的 @ 段（TiebaAtContent）才可点进用户资料。
        spans.add(TextSpan(text: content.text));
      } else if (content is TiebaEmojiContent) {
        spans.add(EmojiSpan(
          content.text,
          imageWidth: Provider.of<APPSettingProvider>(context).fontSize + 2,
          imageHeight: Provider.of<APPSettingProvider>(context).fontSize + 2,
        ));
      } else if (content is TiebaTopicContent) {
        spans.add(TextSpan(
          text: content.text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: TiebananaTokens.of(context).primary,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              AppUtil.urlRoute(context, content.link, forumName: forumName);
            },
        ));
      } else if (content is TiebaLinkContent) {
        spans.add(prependLinkIcon(
            context,
            TextSpan(
              text: content.text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: TiebananaTokens.of(context).primary,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  await AppUtil.openLink(context, content.link,
                      forumName: forumName);
                },
            ),
            fontSize: Provider.of<APPSettingProvider>(context).fontSize - 1));
      } else if (content is TiebaPhoneContent) {
        spans.add(TextSpan(text: content.text));
      } else if (content is TiebaAtContent) {
        spans.add(AtUserSpan(context, text: content.text, uid: content.uid));
      } else if (content is TiebaVoiceContent) {
        //语音回复
        final int? during = content.duringTime;
        spans.add(TextSpan(
          text: during != null && during > 0 ? "[语音 $during″]" : "[语音]",
          style: TextStyle(color: TiebananaTokens.of(context).primary),
        ));
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final images = posts.whereType<TiebaImageContent>().toList();
    final spans = _buildContent(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (spans.isNotEmpty)
          RichText(
            maxLines: images.isEmpty ? 4 : 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: spans,
              style: TextStyle(
                color: TiebananaTokens.of(context).textSecondary,
                fontSize: Provider.of<APPSettingProvider>(context).fontSize - 1,
                height: 1.55,
              ),
            ),
          ),
        if (images.isNotEmpty) ...[
          if (spans.isNotEmpty) const SizedBox(height: 6),
          _InnerPostImages(images: images),
        ],
      ],
    );
  }
}

/// 楼层内只展示小图；查看器仍可浏览该回复的全部有效图片。
class _InnerPostImages extends StatelessWidget {
  const _InnerPostImages({required this.images});

  final List<TiebaImageContent> images;
  static const int _limit = 4;

  void _openImage(BuildContext context, TiebaImageContent image) {
    final valid =
        images.where((part) => part.displaySrc.trim().isNotEmpty).toList();
    Navigator.of(context).push(ImageExplorerRoute(
      builder: (_) => ZoomedImgExplorer(
        imgUrls: valid.map((part) => part.displaySrc).toList(),
        highQualityUrls: valid.map((part) => part.originalSrc).toList(),
        index: valid.indexOf(image),
        heroTagSalt: 'inner-post-${identityHashCode(images)}',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TiebananaTokens.of(context);
    final pictureSetting = Global.setting.pictureLoadSetting;
    return LayoutBuilder(builder: (context, constraints) {
      final side = ((constraints.maxWidth - 18) / 4).clamp(0.0, 72.0);
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < images.length && i < _limit; i++)
            Semantics(
              label: '查看第 ${i + 1} 张图片，共 ${images.length} 张',
              button: images[i].displaySrc.trim().isNotEmpty,
              child: GestureDetector(
                onTap: images[i].displaySrc.trim().isEmpty
                    ? null
                    : () => _openImage(context, images[i]),
                child: ClipRRect(
                  borderRadius: TiebananaMetrics.brCtl,
                  child: SizedBox.square(
                    dimension: side,
                    child: ColoredBox(
                      color: tokens.surface,
                      child: Stack(fit: StackFit.expand, children: [
                        if (images[i].displaySrc.trim().isEmpty ||
                            (pictureSetting == 1 &&
                                images[i].bsizeValue >= 0x100000))
                          Center(
                              child: Text('[图片]',
                                  style:
                                      TextStyle(color: tokens.textSecondary)))
                        else
                          ExtendedImage.network(
                            pictureSetting == 2
                                ? images[i].displaySrc
                                : images[i].lowFlowSrc,
                            cache: true,
                            fit: BoxFit.cover,
                            loadStateChanged: (state) {
                              switch (state.extendedImageLoadState) {
                                case LoadState.completed:
                                  return null;
                                case LoadState.failed:
                                  return Center(
                                      child: Text('[图片]',
                                          style: TextStyle(
                                              color: tokens.textSecondary)));
                                case LoadState.loading:
                                  return Center(
                                      child: Icon(Icons.image_outlined,
                                          color: tokens.textTertiary,
                                          size: 20));
                              }
                            },
                          ),
                        if (i == _limit - 1 && images.length > _limit)
                          IgnorePointer(
                            child: ColoredBox(
                              color: Colors.black54,
                              child: Center(
                                  child: Text('+${images.length - _limit}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600))),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

/// 展开楼中楼（底部面板）。
class InnerFloorBottomSheet extends StatefulWidget {
  final String floorNum;
  final String kz;
  final String pid;
  final String spid;
  final int pn;
  final TiebaForum forum;
  final ThreadReadSession? session;
  final String? cacheUid;
  final TiebaThreadPagePost? cachedPost;
  final Map<String, TiebaAuthor>? cachedAuthors;
  final String threadOwnerUid;

  const InnerFloorBottomSheet({
    super.key,
    required this.floorNum,
    required this.kz,
    required this.pid,
    this.spid = '',
    this.pn = 1,
    required this.forum,
    this.session,
    this.cacheUid,
    this.cachedPost,
    this.cachedAuthors,
    this.threadOwnerUid = '',
  });

  @override
  State<InnerFloorBottomSheet> createState() => _InnerFloorBottomSheetState();
}

class _InnerFloorBottomSheetState extends State<InnerFloorBottomSheet>
    with SingleTickerProviderStateMixin {
  late Future<InnerFloor> dataLoader;
  final Map<int, InnerFloor> floorPages = <int, InnerFloor>{};
  late int pn;
  final ScrollController controller = ScrollController();
  late AnimationController animationcontroller;
  late final ThreadReadSession session;
  late final String cacheUid;
  bool _requesting = false;

  /// 目标楼中楼卡片的 key，用于滚动定位。
  final Map<String, GlobalKey> _replyKeys = <String, GlobalKey>{};

  /// 正在闪烁强调的回复 id。
  String? _highlightId;

  /// 从预览点进来时只自动定位一次。
  bool _revealed = false;

  GlobalKey _keyFor(String id) => _replyKeys.putIfAbsent(id, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    session = widget.session ?? ThreadReadSession();
    cacheUid = widget.cacheUid ?? AccountStore.currentUid ?? '';
    session.addListener(_sessionChanged);
    pn = widget.pn;
    dataLoader = _restore();
    replyEvents.addListener(_onReplySent);
    animationcontroller = AnimationController(
      vsync: this,
      value: 0,
      upperBound: double.infinity,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    session.removeListener(_sessionChanged);
    if (widget.session == null) session.dispose();
    replyEvents.removeListener(_onReplySent);
    controller.dispose();
    animationcontroller.dispose();
    super.dispose();
  }

  void _sessionChanged() {
    if (mounted) setState(() {});
  }

  Future<InnerFloor> _restore() async {
    final cached =
        await Global.threadCache.readInner(cacheUid, widget.kz, widget.pid);
    if (!mounted) throw StateError('面板已关闭');
    floorPages.addAll(cached);
    if (floorPages.isEmpty && widget.cachedPost != null) {
      final post = widget.cachedPost!;
      floorPages[1] = InnerFloor(
          post: post,
          subposts: post.subPostList.map(_innerReplyFromPreview).toList(),
          page: const TiebaPageInfo(
              currentPage: 1, hasMore: false, hasPrev: false),
          thread: TiebaThreadData(agreeType: null),
          authors: widget.cachedAuthors ?? {});
    }
    setState(() {});
    _scheduleReveal();
    if (!session.paused) return _request(pn, spid: widget.spid);
    if (floorPages.isNotEmpty) return floorPages.values.first;
    throw StateError('没有已缓存的楼中楼');
  }

  Future<InnerFloor> _request(int pageNum, {String spid = ''}) async {
    if (session.paused || _requesting) {
      if (floorPages.isNotEmpty) return floorPages.values.first;
      throw StateError('自动请求已暂停');
    }
    _requesting = true;
    try {
      final value = await Global.tiebaAPI
          .getInnerFloor(widget.kz, widget.pid, spid: spid, pn: pageNum);
      if (!mounted || cacheUid != (AccountStore.currentUid ?? '')) return value;
      // 带 spid 的响应从锚点开始，可能只覆盖部分楼层；
      // 普通分页请求用于读取整页。
      final bool completePage = spid.isEmpty;
      await Global.threadCache.saveInner(cacheUid, widget.kz, widget.pid, value,
          completePage: completePage);
      if (!mounted) return value;
      pn = value.page.currentPage;
      final old = floorPages[pn];
      final Set<String> aliveIds = <String>{
        for (final MapEntry<int, InnerFloor> entry in floorPages.entries)
          if (entry.key != pn)
            for (final TiebaSubPost p in entry.value.subposts) p.id,
      };
      final merged = InnerFloor(
          post: value.post,
          subposts: ThreadCache.mergePosts(old?.subposts ?? [], value.subposts,
              markMissingDeleted: completePage, aliveIds: aliveIds),
          page: value.page,
          thread: value.thread,
          authors: {...?old?.authors, ...value.authors});
      setState(() => floorPages[pn] = merged);
      _scheduleReveal();
      return merged;
    } catch (e) {
      if (mounted) session.fail(e);
      if (floorPages.isNotEmpty) return floorPages.values.first;
      rethrow;
    } finally {
      _requesting = false;
    }
  }

  void _scheduleReveal() {
    if (_revealed || widget.spid.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealTarget());
  }

  /// 平滑滚动到被点击的楼中楼，并闪烁强调。
  Future<void> _revealTarget() async {
    if (_revealed || !mounted || widget.spid.isEmpty) return;
    final BuildContext? target = _replyKeys[widget.spid]?.currentContext;
    if (target == null) return;
    _revealed = true;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.12,
    );
    if (!mounted) return;
    setState(() => _highlightId = widget.spid);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _highlightId = null);
  }

  void _onReplySent() {
    if (replyEvents.threadId != widget.kz ||
        replyEvents.floorId != widget.pid) {
      return;
    }
    // 覆盖原页并保留其他已读取的楼中楼。
    setState(() => loadPage(pn, refresh: true));
  }

  void loadPage(int pageNum, {bool refresh = false}) {
    if (session.paused || _requesting) return;
    dataLoader = _request(pageNum);
  }

  /// 按 uid 取作者。
  ///
  /// 后端未提供该 uid 的作者时（`author_id` 与作者信息不一致、作者被抽走等），
  /// 使用楼层自带的信息。
  TiebaAuthor _authorOf(InnerFloor floor, TiebaPost post) {
    return floor.authors[post.uid] ??
        TiebaAuthor(
          icons: const <String>[],
          levelID: null,
          nameShow: post.nameShow,
          portrait: post.portrait,
          uid: post.uid,
          username: post.username,
        );
  }

  List<Widget> buildFloor() {
    final List<Widget> widgets = <Widget>[];
    final keys = floorPages.keys.toList()..sort();
    final seen = <String>{};
    for (final key in keys) {
      final value = floorPages[key]!;
      final ownerUid = value.thread.authorUid.isNotEmpty
          ? value.thread.authorUid
          : widget.threadOwnerUid;
      if (widgets.isEmpty) {
        widgets.add(
          InnerFloorCard(
            author: _authorOf(value, value.post),
            postMain: value.post,
            threadID: widget.kz,
            isSpid: false,
            forum: widget.forum,
            floorId: value.post.id,
            isOp: ownerUid.isNotEmpty && value.post.uid == ownerUid,
          ),
        );
        widgets.add(const SizedBox(height: TiebananaMetrics.gapSm));
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            '${value.subposts.length}条回复',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ));
        widgets.add(const SizedBox(height: TiebananaMetrics.gapXs));
      }
      for (final TiebaSubPost subpost in value.subposts) {
        if (!seen.add(subpost.id)) continue;
        widgets.add(
          InnerFloorCard(
            key: _keyFor(subpost.id),
            author: _authorOf(value, subpost),
            postMain: subpost,
            threadID: widget.kz,
            isSpid: false,
            highlighted: subpost.id == _highlightId,
            forum: widget.forum,
            floorId: value.post.id,
            isOp: ownerUid.isNotEmpty && subpost.uid == ownerUid,
          ),
        );
        widgets.add(const SizedBox(height: TiebananaMetrics.gapSm));
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return AnimatedBuilder(
      animation: animationcontroller,
      builder: (BuildContext context, Widget? child) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height -
                80 -
                animationcontroller.value,
          ),
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(26),
              topRight: Radius.circular(26),
            ),
            color: tokens.surface,
          ),
          child: child,
        );
      },
      child: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: tokens.lineStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${widget.floorNum}楼的回复',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: tokens.textPrimary),
                  ),
                ),
                IconButton(
                  tooltip: '刷新楼中楼',
                  onPressed: _requesting
                      ? null
                      : () {
                          session.retry();
                          setState(() => loadPage(pn, refresh: true));
                        },
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: tokens.textSecondary,
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<InnerFloor>(
              future: dataLoader,
              builder:
                  (BuildContext context, AsyncSnapshot<InnerFloor> snapshot) {
                final List<Widget> floors = buildFloor();
                return Column(
                  children: <Widget>[
                    if (session.paused)
                      const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('正在浏览缓存，自动请求已暂停。可点击右上角刷新。')),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const LinearProgressIndicator(),
                    if (snapshot.hasError && floors.isEmpty)
                      const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('没有可用的楼中楼缓存')),
                    if (!session.paused &&
                        floorPages.isNotEmpty &&
                        floorPages[(floorPages.keys.toList()..sort()).first]!
                            .page
                            .hasPrev)
                      TextButton(
                          onPressed: _requesting
                              ? null
                              : () => setState(() => loadPage(
                                  (floorPages.keys.toList()..sort()).first -
                                      1)),
                          child: const Text('加载前面的回复')),
                    Expanded(
                      child: Listener(
                        onPointerMove: (PointerMoveEvent event) {
                          if (controller.offset == 0) {
                            if (event.delta.dy < 0 &&
                                animationcontroller.value != 0) {
                              setState(() {
                                controller.jumpTo(0);
                              });
                            }
                            animationcontroller.value += event.delta.dy;
                          }
                        },
                        onPointerUp: (PointerUpEvent event) {
                          if (animationcontroller.value > 170) {
                            Navigator.pop(context);
                          } else {
                            animationcontroller.reverse();
                          }
                        },
                        child: NotificationListener<
                            OverscrollIndicatorNotification>(
                          onNotification:
                              (OverscrollIndicatorNotification? overscroll) {
                            overscroll!.disallowIndicator();
                            return true;
                          },
                          child: SingleChildScrollView(
                            controller: controller,
                            physics: animationcontroller.value > 0
                                ? const NeverScrollableScrollPhysics()
                                : const ClampingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: floors,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Builder(
                      builder: (BuildContext context) {
                        if (floorPages.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        late TiebaAuthor author;
                        late String threadID;
                        late TiebaPost postMain;
                        for (final InnerFloor v in floorPages.values) {
                          author = _authorOf(v, v.post);
                          threadID = widget.kz;
                          postMain = v.post;
                        }
                        return InnerFloorReplyBar(
                          author: author,
                          postMain: postMain,
                          threadID: threadID,
                          forum: widget.forum,
                        );
                      },
                    ),
                    if (!session.paused &&
                        floorPages.isNotEmpty &&
                        floorPages[(floorPages.keys.toList()..sort()).last]!
                            .page
                            .hasMore)
                      TextButton(
                          onPressed: _requesting
                              ? null
                              : () => setState(() => loadPage(
                                  (floorPages.keys.toList()..sort()).last + 1)),
                          child: const Text('加载更多回复')),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 楼中楼楼层组件（底部面板内）。
class InnerFloorCard extends StatelessWidget {
  final TiebaAuthor author;
  final TiebaPost postMain;
  final String threadID;
  final bool isSpid;

  /// 刚刚被定位到的回复，短暂高亮强调。
  final bool highlighted;
  final TiebaForum forum;
  final String floorId;
  final bool isOp;

  const InnerFloorCard({
    super.key,
    required this.author,
    required this.postMain,
    required this.threadID,
    required this.isSpid,
    required this.forum,
    required this.floorId,
    this.isOp = false,
    this.highlighted = false,
  });

  List<String> _imgCollect() {
    return <String>[
      for (final TiebaPostContent content in postMain.content)
        if (content is TiebaImageContent) content.displaySrc,
    ];
  }

  List<String> _originImgCollect() {
    return <String>[
      for (final TiebaPostContent content in postMain.content)
        if (content is TiebaImageContent) content.originalSrc,
    ];
  }

  void _openReply(BuildContext context) {
    showReplyPanel(
      context,
      (BuildContext context) {
        return ReplyBottomSheet(
          replyText: TiebaParser.parserContentString(postMain.content),
          targetName: author.name,
          targetMeta: '楼中楼回复',
          threadTitle: '',
          kw: forum.forumName,
          fid: forum.fid,
          tid: threadID,
          floorId: floorId,
          isReplyThread: false,
          replyUser: author,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TiebaVoteBadgeContent? voteBadge =
        postMain.content.whereType<TiebaVoteBadgeContent>().firstOrNull;
    final bool tinted = highlighted || isSpid;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tinted ? tokens.primaryContainer : tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tinted ? null : tokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: TiebananaMetrics.brLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: TiebananaMetrics.brLg,
          onTap: () => _openReply(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Avatar(
                  imgUrl: resolveAvatarUrl(author.portrait),
                  height: 34,
                  width: 34,
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
                      // 作者行与操作按钮同行
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: ThreadAuthorLine(
                              name: author.name,
                              level: author.levelID,
                              icons: const <Widget>[],
                              isOp: isOp,
                              forumRole: author.forumRole,
                              isDeleted: postMain.isDeleted,
                            ),
                          ),
                          const SizedBox(width: TiebananaMetrics.gapSm),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ThreadVoteBar(
                                key: ValueKey<String>(
                                    'inner-vote-${postMain.id}'),
                                postId: postMain.id,
                                threadId: threadID,
                                objType: postMain is TiebaSubPost ? 2 : 1,
                                forumId: forum.fid,
                                agreeNum: int.tryParse(postMain.agreeNum) ?? 0,
                                disagreeNum:
                                    int.tryParse(postMain.disagreeNum) ?? 0,
                                hasAgree: postMain.hasAgree,
                                agreeType:
                                    int.tryParse(postMain.agreeType) ?? 0,
                              ),
                              const SizedBox(width: 5),
                              ThreadMoreButton(
                                  threadId: threadID,
                                  postId: postMain.id,
                                  authorId: author.id,
                                  authorName: author.name,
                                  portrait: author.portrait,
                                  summary: postMain.content
                                      .whereType<TiebaTextContent>()
                                      .map((part) => part.text)
                                      .join(),
                                  reportKind: postMain is TiebaSubPost
                                      ? TiebaReportKind.subReply
                                      : TiebaReportKind.reply),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: TiebananaMetrics.gapXs),
                      ThreadPostMeta(
                        time: threadTimeText(postMain.createTime),
                        ipLocation: postMain is TiebaThreadPagePost
                            ? (postMain as TiebaThreadPagePost).ipLocation
                            : '',
                      ),
                      if (voteBadge != null) ...[
                        const SizedBox(height: TiebananaMetrics.gapXs),
                        ThreadVoteBadge(badge: voteBadge),
                      ],
                      const SizedBox(height: TiebananaMetrics.gapSm),
                      Wrap(
                        children: TiebaParser.parseContent(
                          context,
                          postMain.content,
                          _imgCollect(),
                          _originImgCollect(),
                          selectable: true,
                          forumName: forum.forumName,
                        ),
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
