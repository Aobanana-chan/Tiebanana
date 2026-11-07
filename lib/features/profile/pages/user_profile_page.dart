import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/profile/state/profile_events.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/extended_nested_scroll_view_wrapper.dart';
import 'package:tiebanana/shared/widgets/keep_alive_wrapper.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';
import 'package:tiebanana/features/home/widgets/forum_tag.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/shared/widgets/tiebanana_tab_indicator.dart';
import 'package:tiebanana/features/moderation/widgets/moderation_actions.dart';

/// 用户主页（本人与访客共用一屏）。
///
/// 对应概念图 `design/mockups/visitor.html`（方向 A）：
/// 资料卡（头像·昵称·签名·获赞/粉丝/关注·ID/吧龄/性别）→ 吸顶药丸页签
/// → 三个列表（贴子 / 回复 / 关注的吧），每个列表各自覆盖
/// 骨架 / 空 / 网络错误 / 隐藏（`hide_post`）四种状态。
///
/// 三处与概念图的差异，原因见 `design/README.md` 的「用户主页 · 设计定稿」：
/// - 资料卡只展示契约 [TiebaUserProfile] 提供的字段；
/// - 贴子 / 回复的页脚只展示用户帖接口返回的数据；
/// - 「回复」计数由发帖总量减去主题帖数计算。
class UserVisitor extends StatefulWidget {
  final String uid;
  const UserVisitor({super.key, required this.uid});

  @override
  State<UserVisitor> createState() => _UserVisitorState();
}

class _UserVisitorState extends State<UserVisitor>
    with SingleTickerProviderStateMixin {
  late Future<TiebaUserProfile> _profile;

  /// 顶栏标题用的昵称：资料到达后才有，所以要单独存一份。
  String _name = "";

  late final TabController _tabs = TabController(length: 3, vsync: this);

  /// 资料卡滚走后顶栏标题才淡入（与吧页 / 贴页同一套做法）。
  final ValueNotifier<bool> _titleVisible = ValueNotifier<bool>(false);
  final GlobalKey _cardKey = GlobalKey();
  ScrollController? _outer;
  bool _outerAttached = false;

  @override
  void initState() {
    super.initState();
    _load();
    profileEvents.addListener(_onProfileSaved);
  }

  void _onProfileSaved() {
    if (profileEvents.uid == widget.uid) _reload();
  }

  @override
  void dispose() {
    profileEvents.removeListener(_onProfileSaved);
    _tabs.dispose();
    _titleVisible.dispose();
    if (_outerAttached) {
      _outer?.removeListener(_onOuterScroll);
    }
    super.dispose();
  }

  void _load() {
    final Future<TiebaUserProfile> future =
        Global.tiebaAPI.getUserInfo(uid: widget.uid);
    _profile = future;
    // 昵称要显示在顶栏（在 FutureBuilder 外面），这里单独取一次；
    // 失败由 FutureBuilder 走错误态，这里只需要吞掉这个派生 future 的异常。
    future.then<void>((TiebaUserProfile user) {
      if (mounted) {
        setState(() {
          _name = user.name;
        });
      }
    }, onError: (Object _) {});
  }

  void _reload() {
    setState(_load);
  }

  /// 自己的主页显示「编辑资料」。
  ///
  /// uid 与本地缓存一致时视为本人。
  bool get _isSelf => Global.profile.getString("uid") == widget.uid;

  void _onOuterScroll() {
    final ScrollController? controller = _outer;
    if (controller == null || !controller.hasClients) {
      return;
    }
    final double cardHeight = _cardKey.currentContext?.size?.height ?? 200;
    final bool away =
        controller.offset > cardHeight - TiebananaMetrics.gapXXl - 8;
    if (_titleVisible.value != away) {
      _titleVisible.value = away;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: _appBar(tokens),
      body: FutureBuilder<TiebaUserProfile>(
        future: _profile,
        builder: (BuildContext context, AsyncSnapshot<TiebaUserProfile> s) {
          if (s.hasError && !s.hasData) {
            return Center(
              child: StateView(
                icon: Icons.wifi_off_outlined,
                title: '网络似乎有点问题',
                body: '检查一下网络连接后重试',
                primaryLabel: '重试',
                primaryIcon: Icons.refresh,
                onPrimary: _reload,
              ),
            );
          }
          final TiebaUserProfile? user = s.data;
          if (user == null) {
            return const _VisitorSkeleton();
          }
          return _content(user);
        },
      ),
    );
  }

  AppBar _appBar(TiebananaTokens tokens) {
    return AppBar(
      backgroundColor: tokens.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: tokens.textPrimary,
      titleTextStyle: Theme.of(context).textTheme.titleMedium,
      // 标题在资料卡滚走后淡入。
      title: ValueListenableBuilder<bool>(
        valueListenable: _titleVisible,
        builder: (BuildContext context, bool visible, Widget? child) {
          return AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: TiebananaMetrics.durationBase,
            child: child,
          );
        },
        child: Text(_name, overflow: TextOverflow.ellipsis),
      ),
      actions: <Widget>[
        if (!_isSelf)
          IconButton(
            tooltip: '用户更多操作',
            onPressed: () =>
                showUserModerationMenu(context, uid: widget.uid, name: _name),
            icon: const Icon(Icons.more_vert),
          ),
      ],
    );
  }

  Widget _content(TiebaUserProfile user) {
    return ExtendedNestedScrollView(
      onlyOneScrollInBody: true,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverToBoxAdapter(
            child: _VisitorInfoCard(
              key: _cardKey,
              user: user,
              isSelf: _isSelf,
            ),
          ),
        ];
      },
      body: ExtendedNestedScrollViewInject(
        initCallback: (ExtendedNestedScrollViewState state) {
          if (_outerAttached) {
            _outer?.removeListener(_onOuterScroll);
          }
          _outer = state.outerController;
          _outer?.addListener(_onOuterScroll);
          _outerAttached = true;
        },
        child: Column(
          children: <Widget>[
            _VisitorTabs(
              controller: _tabs,
              threads: user.postNum,
              replies: user.rePostNum,
              forums: user.likeForumNum,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: <Widget>[
                  _tab(
                    index: 0,
                    load: (int pn) async {
                      final TiebaUserPostPage page = await Global.tiebaAPI
                          .getUserPost(uid: widget.uid, pn: pn);
                      return _PageData<TiebaUserPost>(
                          hidden: page.hidePost, items: page.posts);
                    },
                    itemBuilder: (BuildContext context, TiebaUserPost post) =>
                        _userPostCard(post, threads: true),
                    emptyTitle: '还没有发过贴子',
                    emptyBody: 'TA 在关注的吧里还没开过主题',
                    hiddenText: '这位老铁已将贴设为隐藏',
                  ),
                  _tab(
                    index: 1,
                    load: (int pn) async {
                      final TiebaUserPostPage page = await Global.tiebaAPI
                          .getUserPostLowVersion(uid: widget.uid, pn: pn);
                      return _PageData<TiebaUserPost>(
                          hidden: page.hidePost, items: page.posts);
                    },
                    itemBuilder: (BuildContext context, TiebaUserPost post) =>
                        _userPostCard(post, threads: false),
                    emptyTitle: '还没有回复过',
                    emptyBody: 'TA 还没在任何吧里回过贴',
                    hiddenText: '这位老铁已将回复设为隐藏',
                  ),
                  _tab(
                    index: 2,
                    load: (int pn) async {
                      final int? total = int.tryParse(user.likeForumNum);
                      // Profile 已携带全部关注吧时直接使用；预览数量不足时
                      // 再按页读取完整列表。
                      if (user.likeForums.isNotEmpty &&
                          total == user.likeForums.length) {
                        return _PageData<TiebaUserLikeForum>(
                          hidden: false,
                          items: pn == 1
                              ? user.likeForums
                              : const <TiebaUserLikeForum>[],
                        );
                      }
                      final UserForumLikePage page = await Global.tiebaAPI
                          .getUserForumnLike(widget.uid,
                              Global.profile.getString("uid") ?? "", pn, 50);
                      if (page.unavailable) {
                        return _PageData<TiebaUserLikeForum>(
                          hidden: false,
                          items: pn == 1
                              ? user.likeForums
                              : const <TiebaUserLikeForum>[],
                          hasMore: false,
                          notice: user.likeForums.isEmpty
                              ? '关注的吧已隐藏'
                              : '其余吧已隐藏',
                        );
                      }
                      if (pn == 1 && page.forums.isEmpty && (total ?? 0) > 0) {
                        // 已知有关注却没拿到列表，显示可重试错误，而非「没有关注」。
                        throw StateError('关注吧数量与列表响应不一致');
                      }
                      return _PageData<TiebaUserLikeForum>(
                          hidden: false,
                          items: page.forums,
                          hasMore: page.hasMore);
                    },
                    itemBuilder:
                        (BuildContext context, TiebaUserLikeForum forum) =>
                            Padding(
                      padding: const EdgeInsets.all(3),
                      child: ForumTagMedium(
                        avatarUrl: forum.avatar,
                        forumName: forum.forumName,
                        member: forum.memberCount,
                        level: forum.levelId,
                      ),
                    ),
                    // 与概念图一致：双列，行高 72（卡片 66 + 上下各 3）。
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 72,
                    ),
                    emptyTitle: '还没有关注的吧',
                    emptyBody: 'TA 还没有关注任何吧',
                    hiddenText: '这位老铁已将关注的吧设为隐藏',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab<T>({
    required int index,
    required Future<_PageData<T>> Function(int pn) load,
    required Widget Function(BuildContext context, T item) itemBuilder,
    required String emptyTitle,
    required String emptyBody,
    required String hiddenText,
    SliverGridDelegate? gridDelegate,
  }) {
    return KeepAliveWrapper(
      child: _VisitorTab<T>(
        load: load,
        itemBuilder: itemBuilder,
        tabController: _tabs,
        tabIndex: index,
        emptyTitle: emptyTitle,
        emptyBody: emptyBody,
        hiddenText: hiddenText,
        gridDelegate: gridDelegate,
      ),
    );
  }

  /// 用户帖 / 回复共用 [ThreadSummary]。
  Widget _userPostCard(TiebaUserPost post, {required bool threads}) {
    return ThreadSummary(
      firstPostContent: post.content,
      author: TiebaAuthor(
        icons: const <String>[],
        levelID: "",
        nameShow: post.username,
        username: post.username,
        portrait: post.userPortrait,
        uid: post.userId,
      ),
      createTime: post.createTime,
      latestTime: "",
      tid: post.threadId,
      fname: post.forumName,
      // 用户帖接口不给浏览量，页脚会自动收掉那一组。
      viewNum: "",
      // 回复没有标题；空串时隐藏标题块。
      title: threads ? post.title : "",
      agreeNum: post.agreeNum,
      disagreeNum: post.disagreeNum,
      replyNum: post.replyNum,
      quote: post.quotaContent ?? "",
      // 主页不提供「不感兴趣」操作。
      dismissible: false,
    );
  }
}

/// 吸顶页签：药丸选中态 + 各页签的真实计数。
///
/// 计数位数较多时，三颗药丸会超出 390 宽，整条支持横滑
/// （与吧页的页签条同一套：`isScrollable` + 左侧对齐）。
class _VisitorTabs extends StatelessWidget {
  const _VisitorTabs({
    required this.controller,
    required this.threads,
    required this.replies,
    required this.forums,
  });

  final TabController controller;
  final String threads;
  final String replies;
  final String forums;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.bg,
        // 吸顶那一行与内容之间用一条细描边分开（概念图的 .vpinned）。
        border: Border(bottom: BorderSide(color: tokens.line)),
      ),
      // 概念图的 .vtabs 是 `padding:10px 12px`。药丸左边缘 = 这里的外边距 +
      // labelPadding(17) − 指示器外扩(14)，所以外边距取 9 才落在 12 上。
      padding: const EdgeInsets.symmetric(
        horizontal: TiebananaMetrics.pageGutter - 3,
        vertical: TiebananaMetrics.gapSm + 2,
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        // 药丸左右各外扩 14（见 TiebananaPillTabIndicator），labelPadding 留 17
        // 让相邻两颗药丸之间还剩 6 的缝。
        labelPadding: const EdgeInsets.symmetric(horizontal: 17),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: TiebananaPillTabIndicator(color: tokens.primaryContainer),
        labelColor: tokens.onPrimaryContainer,
        unselectedLabelColor: tokens.textSecondary,
        labelStyle: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        tabs: <Widget>[
          Tab(height: TiebananaPillTabIndicator.tabHeight, text: '贴子 $threads'),
          Tab(height: TiebananaPillTabIndicator.tabHeight, text: '回复 $replies'),
          Tab(
              height: TiebananaPillTabIndicator.tabHeight,
              text: '关注的吧 $forums'),
        ],
      ),
    );
  }
}

/// 资料卡：头像 · 昵称 · 签名 · 获赞/粉丝/关注 · ID/吧龄/性别。
///
/// 与「我的」页的 `UserCard` 是同一套布局语言，但字段取舍不同：
/// 这里给「获赞 / 粉丝 / 关注」，那边给四项统计。
class _VisitorInfoCard extends StatelessWidget {
  const _VisitorInfoCard({super.key, required this.user, required this.isSelf});

  final TiebaUserProfile user;
  final bool isSelf;

  /// 性别是语义色：男蓝女粉，使用固定色值。
  static const Color _maleColor = Color(0xFF3E7CD8);
  static const Color _femaleColor = Color(0xFFE0559A);

  /// 签名：图标 + 文字。未设置签名时显示占位文案，保持卡片高度稳定。
  Widget _signature(TiebananaTokens tokens, TextTheme textTheme) {
    final bool empty = user.intro.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(
        top: TiebananaMetrics.gapXs + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.edit_outlined,
              size: TiebananaMetrics.iconSizeSmall,
              color: empty
                  ? tokens.textTertiary.withValues(alpha: .55)
                  : tokens.textTertiary,
            ),
          ),
          const SizedBox(width: TiebananaMetrics.gapSm),
          Expanded(
            child: Text(
              empty ? '这懒人没设签名喵' : user.intro,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                  color: empty ? tokens.textTertiary : tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  /// 获赞 / 粉丝 / 关注：三列等分，数字在上、标签在下。
  Widget _stats(TiebananaTokens tokens, TextTheme textTheme) {
    final List<MapEntry<String, String>> items = <MapEntry<String, String>>[
      MapEntry<String, String>('获赞', user.displayTotalAgreeNum),
      MapEntry<String, String>('粉丝', user.fansNum),
      MapEntry<String, String>('关注', user.concernNum),
    ];
    return Container(
      margin: const EdgeInsets.only(top: TiebananaMetrics.gapMd + 1),
      padding: const EdgeInsets.only(top: TiebananaMetrics.gapMd),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.line)),
      ),
      child: Row(
        children: items
            .map((MapEntry<String, String> e) => Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                        e.value.isEmpty ? '0' : e.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: TiebananaMetrics.gapXs - 1),
                      Text(
                        e.key,
                        style: textTheme.labelSmall
                            ?.copyWith(color: tokens.textTertiary),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  /// 台账行：ID（可复制）/ 吧龄 / 性别。与头像左边缘对齐。
  Widget _meta(TiebananaTokens tokens, TextTheme textTheme) {
    final TextStyle? style =
        textTheme.bodySmall?.copyWith(color: tokens.textSecondary);
    final TextStyle? numStyle = style?.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.only(
        top: TiebananaMetrics.gapMd + 1,
      ),
      child: Row(
        children: <Widget>[
          Text('ID', style: style),
          const SizedBox(width: TiebananaMetrics.gapXs + 1),
          Text(user.uid, style: numStyle),
          const SizedBox(width: TiebananaMetrics.gapXs),
          InkWell(
            borderRadius: TiebananaMetrics.brSm,
            onTap: () => Fluttertoast.showToast(msg: '已复制 ID：${user.uid}'),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.copy,
                  size: TiebananaMetrics.iconSizeSmall,
                  color: tokens.textTertiary),
            ),
          ),
          const SizedBox(width: TiebananaMetrics.gapMd),
          Text('吧龄', style: style),
          const SizedBox(width: TiebananaMetrics.gapXs + 1),
          Text(user.tbAge, style: numStyle),
          if (user.sex == "1" || user.sex == "2") ...<Widget>[
            const SizedBox(width: TiebananaMetrics.gapMd),
            Icon(
              // 官方契约：`"1"` 男 / `"2"` 女。
              user.sex == "1" ? Icons.male : Icons.female,
              size: TiebananaMetrics.iconSizeSmall + 1,
              color: user.sex == "1" ? _maleColor : _femaleColor,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        TiebananaMetrics.pageGutter,
        TiebananaMetrics.gapMd,
        TiebananaMetrics.pageGutter,
        0,
      ),
      decoration: BoxDecoration(
        borderRadius: TiebananaMetrics.brXl,
        boxShadow: tokens.cardShadow,
      ),
      child: Material(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brXl,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(TiebananaMetrics.gapLg - 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Avatar(
                    userId: user.uid,
                    imgUrl: profileEvents.avatarUrl(user.uid, user.portraitUrl),
                    height: TiebananaMetrics.avatarXl,
                    width: TiebananaMetrics.avatarXl,
                  ),
                  // Avatar 自带 5 的右外边距，这里补 8，合计 13。
                  const SizedBox(width: TiebananaMetrics.gapSm),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: TiebananaMetrics.gapXs + 2),
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.headlineSmall
                                  ?.copyWith(color: tokens.textPrimary),
                            ),
                          ),
                          const Spacer(),
                          _actionButton(context, tokens),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              _signature(tokens, textTheme),
              _stats(tokens, textTheme),
              _meta(tokens, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  /// 访客显示「＋ 关注」，本人显示「编辑资料」。
  ///
  /// 本人进入资料编辑页；访客关注仍待协议接入。
  Widget _actionButton(BuildContext context, TiebananaTokens tokens) {
    final bool self = isSelf;
    return Material(
      color: self ? Colors.transparent : tokens.primaryContainer,
      borderRadius: TiebananaMetrics.brPill,
      child: InkWell(
        borderRadius: TiebananaMetrics.brPill,
        onTap: () {
          if (self) {
            Navigator.pushNamed(context, PageRouter.profileEdit);
          } else {
            Fluttertoast.showToast(msg: '关注接口还没接入');
          }
        },
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(
              horizontal: TiebananaMetrics.gapMd + 1),
          decoration: BoxDecoration(
            borderRadius: TiebananaMetrics.brPill,
            border: self ? Border.all(color: tokens.lineStrong) : null,
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              self ? '编辑资料' : '＋ 关注',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color:
                        self ? tokens.textSecondary : tokens.onPrimaryContainer,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 一页内容。接口明确说「隐藏」时 [hidden] 为 true ——
/// 它**不是**「列表为空」，两者在界面上要分开（见规格卡）。
class _PageData<T> {
  const _PageData({
    required this.hidden,
    required this.items,
    this.hasMore,
    this.notice,
  });

  final bool hidden;
  final List<T> items;
  final bool? hasMore;
  final String? notice;
}

/// 三个页签共用的分页列表：骨架 / 空 / 网络错误 / 隐藏 + 翻页。
///
/// 翻页沿用项目里既有的写法：监听 `ExtendedNestedScrollView` 的内层控制器，
/// 快到底时用 [Throttle] 节流补一页。
class _VisitorTab<T> extends StatefulWidget {
  const _VisitorTab({
    required this.load,
    required this.itemBuilder,
    required this.tabController,
    required this.tabIndex,
    required this.emptyTitle,
    required this.emptyBody,
    required this.hiddenText,
    this.gridDelegate,
  });

  final Future<_PageData<T>> Function(int pn) load;
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// 三个页签共用同一个内层滚动控制器，每个页签自行判断当前是否激活。
  final TabController tabController;
  final int tabIndex;

  final String emptyTitle;
  final String emptyBody;
  final String hiddenText;

  /// 给了就按网格排（关注的吧），否则是单列列表。
  final SliverGridDelegate? gridDelegate;

  @override
  State<_VisitorTab<T>> createState() => _VisitorTabState<T>();
}

class _VisitorTabState<T> extends State<_VisitorTab<T>> {
  final List<T> _items = <T>[];
  ScrollController? _inner;
  bool _attached = false;
  int _pn = 1;
  bool _loading = false;
  bool _hasMore = true;
  bool _first = true;
  bool _hidden = false;
  Object? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    // 首帧之后再拉取，第一帧显示骨架屏。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetch(1, refresh: true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 内层控制器由 ExtendedNestedScrollView 提供，判断「滚到底」要靠它。
    _attach(context
        .findAncestorStateOfType<ExtendedNestedScrollViewState>()
        ?.innerController);
  }

  @override
  void dispose() {
    if (_attached) {
      _inner?.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _attach(ScrollController? controller) {
    if (_attached && identical(controller, _inner)) {
      return;
    }
    if (_attached) {
      _inner?.removeListener(_onScroll);
    }
    _inner = controller;
    _inner?.addListener(_onScroll);
    _attached = true;
  }

  bool get _isCurrentTab => widget.tabController.index == widget.tabIndex;

  void _onScroll() {
    final ScrollController? controller = _inner;
    if (controller == null || !controller.hasClients || !_isCurrentTab) {
      return;
    }
    final ScrollPosition position = controller.positions.last;
    if (position.pixels >
        position.maxScrollExtent - position.viewportDimension) {
      if (_hasMore && !_loading) {
        Throttle.seconds(1, () {
          _fetch(_pn + 1);
        });
      }
    }
  }

  Future<void> _fetch(int pn, {bool refresh = false}) async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
      if (refresh) {
        _error = null;
      }
    });
    try {
      final _PageData<T> page = await widget.load(pn);
      if (!mounted) {
        return;
      }
      setState(() {
        if (refresh) {
          _items.clear();
        }
        _pn = pn;
        _items.addAll(page.items);
        _hidden = page.hidden;
        // 空页说明到底了。
        _hasMore = page.hasMore ?? page.items.isNotEmpty;
        _notice = page.notice;
        _first = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _first = false;
        _error = e;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) {
      return _state(
        icon: Icons.lock_outline,
        title: widget.hiddenText,
        body: '这是接口明确给出的状态，不等于「列表为空」',
      );
    }
    if (_first) {
      return const _VisitorListSkeleton();
    }
    if (_items.isEmpty && _error != null) {
      return _state(
        icon: Icons.wifi_off_outlined,
        title: '网络似乎有点问题',
        body: '检查一下网络连接后重试',
        onRetry: () => _fetch(1, refresh: true),
      );
    }
    if (_items.isEmpty) {
      if (_notice != null) {
        return _state(
          icon: Icons.info_outline,
          title: '关注的吧已隐藏',
          body: _notice!,
        );
      }
      return _state(
        icon: Icons.inbox_outlined,
        title: widget.emptyTitle,
        body: widget.emptyBody,
      );
    }
    if (widget.gridDelegate != null) {
      final Widget grid = GridView.builder(
        padding: const EdgeInsets.fromLTRB(
          TiebananaMetrics.pageGutter - 3,
          TiebananaMetrics.gapSm,
          TiebananaMetrics.pageGutter - 3,
          0,
        ),
        gridDelegate: widget.gridDelegate!,
        itemCount: _items.length,
        itemBuilder: (BuildContext context, int index) =>
            widget.itemBuilder(context, _items[index]),
      );
      if (_notice == null) return grid;
      return Column(
        children: <Widget>[
          Expanded(child: grid),
          Padding(
            padding: const EdgeInsets.all(TiebananaMetrics.pageGutter),
            child: Text(_notice!, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: TiebananaMetrics.gapMd),
      itemCount: _items.length,
      itemBuilder: (BuildContext context, int index) =>
          widget.itemBuilder(context, _items[index]),
    );
  }

  Widget _state({
    required IconData icon,
    required String title,
    required String body,
    VoidCallback? onRetry,
  }) {
    return SingleChildScrollView(
      child: StateView(
        icon: icon,
        title: title,
        body: body,
        primaryLabel: onRetry == null ? null : '重试',
        primaryIcon: onRetry == null ? null : Icons.refresh,
        onPrimary: onRetry,
      ),
    );
  }
}

/// 首屏骨架：资料卡 / 帖子卡两段都与真实页同构，保持数据到达前后的布局稳定。
class _VisitorSkeleton extends StatelessWidget {
  const _VisitorSkeleton();

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.fromLTRB(
              TiebananaMetrics.pageGutter,
              TiebananaMetrics.gapMd,
              TiebananaMetrics.pageGutter,
              0,
            ),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: TiebananaMetrics.brXl,
              boxShadow: tokens.cardShadow,
            ),
            padding: const EdgeInsets.all(TiebananaMetrics.gapLg - 2),
            child: Column(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SkeletonBox(
                      width: TiebananaMetrics.avatarXl,
                      height: TiebananaMetrics.avatarXl,
                      radius: TiebananaMetrics.avatarXl / 2,
                    ),
                    const SizedBox(width: TiebananaMetrics.gapMd + 1),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const <Widget>[
                          SizedBox(height: TiebananaMetrics.gapXs + 2),
                          SkeletonBox(width: 92, height: 18, radius: 6),
                          SizedBox(height: TiebananaMetrics.gapSm + 1),
                          SkeletonBox(width: 160, height: 11),
                          SizedBox(height: 6),
                          SkeletonBox(width: 120, height: 11),
                        ],
                      ),
                    ),
                    const SizedBox(width: TiebananaMetrics.gapSm),
                    const SkeletonBox(width: 76, height: 32, radius: 999),
                  ],
                ),
                const SizedBox(height: TiebananaMetrics.gapLg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const <Widget>[
                    SkeletonBox(width: 48, height: 15),
                    SkeletonBox(width: 44, height: 15),
                    SkeletonBox(width: 44, height: 15),
                  ],
                ),
                const SizedBox(height: TiebananaMetrics.gapMd),
                const SkeletonBox(width: 170, height: 11),
              ],
            ),
          ),
          const SizedBox(height: TiebananaMetrics.gapMd),
          const _VisitorListSkeleton(),
        ],
      ),
    );
  }
}

/// 三张帖子卡骨架。
class _VisitorListSkeleton extends StatelessWidget {
  const _VisitorListSkeleton();

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    // 外层用禁用的滚动容器，骨架高于视口时可以正常容纳。
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < 3; i++)
            Container(
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
              padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  Row(
                    children: <Widget>[
                      SkeletonBox(
                        width: TiebananaMetrics.avatarSm,
                        height: TiebananaMetrics.avatarSm,
                        radius: TiebananaMetrics.avatarSm / 2,
                      ),
                      SizedBox(width: TiebananaMetrics.gapSm),
                      SkeletonBox(width: 74, height: 11),
                      SizedBox(width: TiebananaMetrics.gapSm),
                      SkeletonBox(width: 46, height: 11),
                    ],
                  ),
                  SizedBox(height: TiebananaMetrics.gapMd),
                  SkeletonBox(width: double.infinity, height: 14),
                  SizedBox(height: TiebananaMetrics.gapSm),
                  SkeletonBox(width: 200, height: 11),
                  SizedBox(height: TiebananaMetrics.gapMd),
                  SkeletonBox(width: double.infinity, height: 70, radius: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
