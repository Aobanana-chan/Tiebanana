// ignore_for_file: use_build_context_synchronously

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/thread/state/reply_events.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/features/thread/data/thread_cache.dart';
import 'package:tiebanana/app/navigation/link_router.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/thread/pages/thread_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/content/special_span.dart';
import 'package:tiebanana/shared/content/post_link_span.dart';
import 'package:tiebanana/features/thread/widgets/thread_common.dart';
import 'package:tiebanana/features/thread/widgets/thread_reply_bar.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';
import 'package:tiebanana/features/thread/widgets/thread_poll_card.dart';

/// 帖子楼层卡片。
///
/// 对应概念图 `design/mockups/thread.html` 的 `.floor`：
/// 左轨（头像 + 楼层号）· 作者身份 · 正文 · 底部赞踩 / 更多，整卡可点即回复；
/// 楼中楼是卡内的 `surface-2` 容器。
class ThreadFloorComment extends StatelessWidget {
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
  });

  void _openReply(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ReplyBottomSheet(
          replyText: TiebaParser.parserContentString(postMain.content),
          targetName: author.name,
          targetMeta: '${postMain.floor}楼 · '
              '${threadMetaText(threadTimeText(postMain.createTime), postMain.ipLocation)}',
          threadTitle: threadTitle,
          kw: forum.forumName,
          fid: forum.fid,
          tid: threadID,
          floorId: postMain.id,
          isReplyThread: false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThreadPageMainState? readingHistoryPid =
        context.findAncestorStateOfType<ThreadPageMainState>();
    readingHistoryPid?.pid = postMain.id;
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final List<Widget> icons = TiebaParser.processIcon(author) ?? <Widget>[];
    final int subCount =
        int.tryParse(postMain.subPostNumber) ?? postMain.subPostList.length;

    // 当帖子含有投票时，content 里的投票封面 / 阵营图片常常没有可用地址。
    // 这里剔除这类无效图片，正常配图保留。
    final List<TiebaPostContent> displayContent =
        postMain.hasPoll || postMain.poll != null
            ? contentWithoutUnusableImages(postMain.content)
            : postMain.content;
    // 作者投的阵营徽章（type 52）。官方把徽章放在正文最前面。
    final TiebaVoteBadgeContent? voteBadge =
        postMain.content.whereType<TiebaVoteBadgeContent>().firstOrNull;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        TiebananaMetrics.pageGutter,
        0,
        TiebananaMetrics.pageGutter,
        TiebananaMetrics.gapSm,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
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
                      imgUrl: resolveAvatarUrl(author.portrait),
                      height: 34,
                      width: 34,
                      onTap: () {
                        Navigator.pushNamed(context, PageRouter.user,
                            arguments: author.id);
                      },
                    ),
                    const SizedBox(height: TiebananaMetrics.gapXXs),
                    ThreadFloorTag(
                      floor: postMain.floor,
                      isOp: isOp,
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
                              forumRole: author.forumRole,
                              name: author.name,
                              level: author.levelID,
                              icons: icons,
                              isOp: isOp,
                              isDeleted: postMain.isDeleted,
                            ),
                          ),
                          const SizedBox(width: TiebananaMetrics.gapSm),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ThreadVoteBar(
                                key: ValueKey<String>('vote-${postMain.id}'),
                                postId: postMain.id,
                                threadId: threadID,
                                objType: 1,
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
                                storedNotifier: storedNotifier,
                                authorId: author.id,
                                authorName: author.name,
                                portrait: author.portrait,
                                summary: postMain.content
                                    .whereType<TiebaTextContent>()
                                    .map((part) => part.text)
                                    .join(),
                                source: '${postMain.floor ?? ''} 楼',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: TiebananaMetrics.gapXs),
                      ThreadPostMeta(
                        time: threadTimeText(postMain.createTime),
                        ipLocation: postMain.ipLocation,
                      ),
                      const SizedBox(height: TiebananaMetrics.gapSm),
                      Wrap(
                        children: TiebaParser.parseContent(
                          context,
                          displayContent,
                          allImgs,
                          allOrgImgs,
                          videoInfo: videoInfo,
                          selectable: true,
                          forumName: forum.forumName,
                        ),
                      ),
                      if (postMain.poll != null || postMain.hasPoll) ...[
                        const SizedBox(height: TiebananaMetrics.gapMd),
                        // 卡内投票区域拦截点击，避免触发整层的「回复」操作。
                        // 当 poll==null（服务端仅标记 hasPoll）时，只显示文字占位。
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: ThreadPollCard(
                              poll: postMain.poll, compact: true),
                        ),
                      ],
                      if (subCount > 0 || postMain.subPostList.isNotEmpty)
                        InnerFloorEntry(
                          subPostList: postMain.subPostList,
                          userlist: userList,
                          subPostNumber: postMain.subPostNumber,
                          floorNum: postMain.floor.toString(),
                          kz: threadID,
                          pid: postMain.id,
                          forum: forum,
                          threadTitle: threadTitle,
                          threadOwnerUid: threadOwnerUid,
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

  void _openSheet(BuildContext context) {
    final page = context.findAncestorStateOfType<ThreadPageMainState>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => InnerFloorBottomSheet(
        floorNum: floorNum,
        kz: kz,
        pid: pid,
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => ReplyBottomSheet(
        replyText: TiebaParser.parserContentString(post.content),
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
          Padding(
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
          for (final TiebaSubPost post in visible)
            _InnerFloorRow(
              threadId: kz,
              post: post,
              author: userlist[post.uid],
              isOp: threadOwnerUid.isNotEmpty && post.uid == threadOwnerUid,
              onTap: () => _openSheet(context),
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
                    name: user.name,
                    level: null,
                    icons: const <Widget>[],
                    isOp: isOp,
                    forumRole: user.forumRole,
                    isDeleted: post.isDeleted,
                  ),
                  const SizedBox(height: 2),
                  InnerPost(posts: post.content, forumName: forumName),
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
                          summary: post.content
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
        if (content.uid != null) {
          spans.add(TextSpan(
            text: content.text,
            style: TextStyle(color: TiebananaTokens.of(context).primary),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.pushNamed(context, PageRouter.user,
                    arguments: content.uid);
              },
          ));
        } else {
          spans.add(TextSpan(text: content.text));
        }
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
                  if (await AppUtil.urlRoute(context, content.link) == false) {
                    Navigator.push(
                      context,
                      appPageRoute(
                        builder: (BuildContext builder) => WebViewWidget(
                          controller: WebViewController()
                            ..setBackgroundColor(Colors.white)
                            ..setJavaScriptMode(JavaScriptMode.unrestricted)
                            ..setNavigationDelegate(NavigationDelegate(
                              onNavigationRequest:
                                  (NavigationRequest request) async {
                                if (await AppUtil.urlRoute(
                                  context,
                                  request.url,
                                )) {
                                  return NavigationDecision.prevent;
                                }
                                return NavigationDecision.navigate;
                              },
                            ))
                            ..loadRequest(Uri.parse(content.link)),
                        ),
                      ),
                    );
                  }
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
    return RichText(
      text: TextSpan(
        children: _buildContent(context),
        style: TextStyle(
          color: TiebananaTokens.of(context).textSecondary,
          fontSize: Provider.of<APPSettingProvider>(context).fontSize - 1,
          height: 1.55,
        ),
      ),
    );
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
          subposts: post.subPostList,
          page: const TiebaPageInfo(
              currentPage: 1, hasMore: false, hasPrev: false),
          thread: TiebaThreadData(agreeType: null),
          authors: widget.cachedAuthors ?? {});
    }
    setState(() {});
    if (!session.paused) return _request(pn);
    if (floorPages.isNotEmpty) return floorPages.values.first;
    throw StateError('没有已缓存的楼中楼');
  }

  Future<InnerFloor> _request(int pageNum) async {
    if (session.paused || _requesting) {
      if (floorPages.isNotEmpty) return floorPages.values.first;
      throw StateError('自动请求已暂停');
    }
    _requesting = true;
    try {
      final value = await Global.tiebaAPI
          .getInnerFloor(widget.kz, widget.pid, spid: widget.spid, pn: pageNum);
      if (!mounted || cacheUid != (AccountStore.currentUid ?? '')) return value;
      // 带 spid 的响应从锚点开始，可能只覆盖部分楼层；
      // 普通分页请求用于读取整页。
      final bool completePage = widget.spid.isEmpty;
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
      return merged;
    } catch (e) {
      if (mounted) session.fail(e);
      if (floorPages.isNotEmpty) return floorPages.values.first;
      rethrow;
    } finally {
      _requesting = false;
    }
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
            author: _authorOf(value, subpost),
            postMain: subpost,
            threadID: widget.kz,
            isSpid: subpost.id == widget.spid,
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
                          child: ListView.builder(
                            controller: controller,
                            physics: animationcontroller.value > 0
                                ? const NeverScrollableScrollPhysics()
                                : const ClampingScrollPhysics(),
                            itemCount: floors.length,
                            itemBuilder: (BuildContext context, int index) {
                              return floors[index];
                            },
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isSpid ? tokens.primaryContainer : tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: isSpid ? null : tokens.cardShadow,
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
