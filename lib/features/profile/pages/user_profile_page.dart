import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/home/widgets/forum_tag.dart';
import 'package:tiebanana/features/message/models/chat_route_data.dart';
import 'package:tiebanana/features/moderation/widgets/moderation_actions.dart';
import 'package:tiebanana/features/profile/state/profile_events.dart';
import 'package:tiebanana/shared/content/special_span.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/layout/page_wrap.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/app_toast.dart';
import 'package:tiebanana/shared/widgets/broadcast_image_lightbox.dart';
import 'package:tiebanana/shared/widgets/desktop_panel.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';
import 'package:tiebanana/shared/widgets/extended_nested_scroll_view_wrapper.dart';
import 'package:tiebanana/shared/widgets/keep_alive_wrapper.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';
import 'package:tiebanana/shared/widgets/tiebanana_refresh_indicator.dart';
import 'package:tiebanana/shared/widgets/tiebanana_tab_indicator.dart';

/// 性别语义色：男蓝女粉，不跟随主题色变化。
const Color _kMaleColor = Color(0xFF3E7CD8);
const Color _kFemaleColor = Color(0xFFE0559A);

/// 用户主页（本人与访客共用一屏）。
///
/// - `< 720dp` 保持移动端 `ExtendedNestedScrollView` + 资料卡 + 吸顶药丸页签；
/// - `≥ 720dp` 纳入 [DesktopShellFrame] 与 [PageWrap]，采用左停靠用户档案卡 +
///   右吸顶控制条与内容流（「左档右流」，`< 900dp` 折叠为顶部满宽横卡）。
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
  int _tabIndex = 0;

  /// 资料卡滚走后顶栏标题才淡入（与吧页 / 贴页同一套做法）。
  final ValueNotifier<bool> _titleVisible = ValueNotifier<bool>(false);
  final ValueNotifier<int> _desktopRefreshSignal = ValueNotifier<int>(0);
  final GlobalKey _cardKey = GlobalKey();
  ScrollController? _outer;
  bool _outerAttached = false;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_onTabChanged);
    _load();
    profileEvents.addListener(_onProfileSaved);
  }

  void _onTabChanged() {
    if (!mounted) return;
    if (_tabIndex != _tabs.index) {
      setState(() => _tabIndex = _tabs.index);
    }
  }

  void _onProfileSaved() {
    if (profileEvents.uid == widget.uid) _reload();
  }

  @override
  void dispose() {
    profileEvents.removeListener(_onProfileSaved);
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _titleVisible.dispose();
    _desktopRefreshSignal.dispose();
    if (_outerAttached) {
      _outer?.removeListener(_onOuterScroll);
    }
    super.dispose();
  }

  void _load() {
    // 无效 uid（空串 / 0 / 非数字）不发请求，避免把脏数据展示成网络错误。
    if (!isValidUserUid(widget.uid)) return;
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

  Future<void> _refreshAll() async {
    if (!isValidUserUid(widget.uid)) return;
    _reload();
    _desktopRefreshSignal.value++;
    try {
      await _profile;
    } catch (_) {
      // 失败态由页面内的 FutureBuilder 接管展示。
    }
  }

  /// 自己的主页显示「编辑资料」。
  ///
  /// uid 与本地缓存一致时视为本人。
  bool get _isSelf {
    try {
      return Global.profile.getString("uid") == widget.uid;
    } catch (_) {
      return false;
    }
  }

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
    final double windowWidth = MediaQuery.sizeOf(context).width;
    final bool desktop = AppBreakpoints.isDesktopWidth(windowWidth);

    if (!isValidUserUid(widget.uid)) {
      final Widget invalidBody = Center(
        child: SingleChildScrollView(
          child: desktop
              ? PageWrap(
                  maxWidth: 520,
                  child: DesktopPanel(
                    borderRadius: TiebananaMetrics.brXl,
                    child: StateView(
                      icon: Icons.person_off_outlined,
                      title: '找不到该用户',
                      body: '用户 ID 无效或内容已不可用',
                      primaryLabel: '返回',
                      primaryIcon: Icons.arrow_back_rounded,
                      onPrimary: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                )
              : StateView(
                  icon: Icons.person_off_outlined,
                  title: '找不到该用户',
                  body: '用户 ID 无效或内容已不可用',
                  primaryLabel: '返回',
                  primaryIcon: Icons.arrow_back_rounded,
                  onPrimary: () => Navigator.of(context).maybePop(),
                ),
        ),
      );
      if (desktop) {
        return DesktopShellFrame(
          title: '用户主页',
          subtitle: '无效用户 ID',
          activeTab: -1,
          child: invalidBody,
        );
      }
      return Scaffold(
        backgroundColor: tokens.bg,
        appBar: AppBar(
          backgroundColor: tokens.bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text('用户主页'),
        ),
        body: invalidBody,
      );
    }

    final Widget futureBody = FutureBuilder<TiebaUserProfile>(
      future: _profile,
      builder: (BuildContext context, AsyncSnapshot<TiebaUserProfile> s) {
        if (s.hasError && !s.hasData) {
          final Widget errorState = StateView(
            icon: Icons.wifi_off_outlined,
            title: '网络似乎有点问题',
            body: '检查一下网络连接后重试',
            primaryLabel: '重试',
            primaryIcon: Icons.refresh,
            onPrimary: _reload,
          );
          if (desktop) {
            return Center(
              child: SingleChildScrollView(
                child: PageWrap(
                  maxWidth: 520,
                  child: DesktopPanel(
                    borderRadius: TiebananaMetrics.brXl,
                    child: errorState,
                  ),
                ),
              ),
            );
          }
          return Center(child: errorState);
        }
        final TiebaUserProfile? user = s.data;
        if (user == null) {
          return desktop
              ? _DesktopVisitorSkeleton(windowWidth: windowWidth)
              : const _VisitorSkeleton();
        }
        return desktop
            ? _desktopContent(context, user, windowWidth)
            : _content(user);
      },
    );

    if (desktop) {
      return DesktopShellFrame(
        title: _name.isEmpty ? '用户主页' : _name,
        subtitle: _name.isEmpty
            ? (_isSelf ? '我的主页' : '正在加载…')
            : '${_isSelf ? '我的主页' : '用户主页'} · ID ${widget.uid}',
        activeTab: _isSelf ? 3 : -1,
        onRefresh: _refreshAll,
        child: futureBody,
      );
    }

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: _appBar(tokens),
      body: futureBody,
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

  Widget _desktopContent(
    BuildContext context,
    TiebaUserProfile user,
    double windowWidth,
  ) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool twoCol = windowWidth >= AppBreakpoints.mediumMax;
    final double dockWidth = windowWidth >= 1100 ? 296 : 268;
    final String sub =
        '${user.name} · 贴吧 ID ${user.uid}${user.tbAge.trim().isNotEmpty ? ' · 吧龄 ${user.tbAge.trim()}' : ''}';

    final Widget controlBar = _DesktopVisitorControlBar(
      tabIndex: _tabIndex,
      threads: user.postNum,
      replies: user.rePostNum,
      forums: user.likeForumNum,
      onSelectTab: (int i) => _tabs.animateTo(i),
    );

    final Widget tabView = TabBarView(
      controller: _tabs,
      children: <Widget>[
        _desktopTab<TiebaUserPost>(
          index: 0,
          load: (int pn) async {
            final TiebaUserPostPage page =
                await Global.tiebaAPI.getUserPost(uid: widget.uid, pn: pn);
            return _PageData<TiebaUserPost>(
                hidden: page.hidePost, items: page.posts);
          },
          itemBuilder: (BuildContext context, TiebaUserPost post) =>
              _userPostCard(post, threads: true, desktop: true),
          emptyTitle: '还没有发过贴子',
          emptyBody: 'TA 在关注的吧里还没开过主题',
          hiddenText: '这位老铁已将贴设为隐藏',
        ),
        _desktopTab<TiebaUserPost>(
          index: 1,
          load: (int pn) async {
            final TiebaUserPostPage page = await Global.tiebaAPI
                .getUserPostLowVersion(uid: widget.uid, pn: pn);
            return _PageData<TiebaUserPost>(
                hidden: page.hidePost, items: page.posts);
          },
          itemBuilder: (BuildContext context, TiebaUserPost post) =>
              _userPostCard(post, threads: false, desktop: true),
          emptyTitle: '还没有回复过',
          emptyBody: 'TA 还没在任何吧里回过贴',
          hiddenText: '这位老铁已将回复设为隐藏',
        ),
        _desktopTab<TiebaUserLikeForum>(
          index: 2,
          load: (int pn) => _loadUserForums(user, pn),
          itemBuilder: (BuildContext context, TiebaUserLikeForum forum) =>
              ForumTagMedium(
            avatarUrl: forum.avatar,
            forumName: forum.forumName,
            member: forum.memberCount,
            level: forum.levelId,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 68,
          ),
          emptyTitle: '还没有关注的吧',
          emptyBody: 'TA 还没有关注任何吧',
          hiddenText: '这位老铁已将关注的吧设为隐藏',
        ),
      ],
    );

    return PageWrap(
      bottomPadding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DesktopPageHeader(
            title: _isSelf ? '我的主页' : '用户主页',
            subtitle: sub,
            tools: <Widget>[
              if (_isSelf)
                OutlinedButton(
                  onPressed: () {
                    Global.desktopTabRequest.value = 3;
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context)
                          .popUntil((Route<dynamic> r) => r.isFirst);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.textSecondary,
                    side: BorderSide(color: tokens.line),
                    minimumSize: const Size(0, 29),
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('返回个人与设置'),
                ),
              OutlinedButton.icon(
                onPressed: _refreshAll,
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.textSecondary,
                  side: BorderSide(color: tokens.line),
                  minimumSize: const Size(0, 29),
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('刷新资料'),
              ),
            ],
          ),
          if (twoCol)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: dockWidth,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _DesktopUserDock(
                        user: user,
                        isSelf: _isSelf,
                        compact: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        controlBar,
                        const SizedBox(height: 11),
                        Expanded(child: tabView),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _DesktopUserDock(
                    user: user,
                    isSelf: _isSelf,
                    compact: true,
                  ),
                  const SizedBox(height: 12),
                  controlBar,
                  const SizedBox(height: 10),
                  Expanded(child: tabView),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<_PageData<TiebaUserLikeForum>> _loadUserForums(
    TiebaUserProfile user,
    int pn,
  ) async {
    final int? total = int.tryParse(user.likeForumNum);
    // Profile 已携带全部关注吧时直接使用；预览数量不足时再按页读取完整列表。
    if (user.likeForums.isNotEmpty && total == user.likeForums.length) {
      return _PageData<TiebaUserLikeForum>(
        hidden: false,
        items: pn == 1 ? user.likeForums : const <TiebaUserLikeForum>[],
        hasMore: false,
      );
    }
    final UserForumLikePage page = await Global.tiebaAPI.getUserForumnLike(
        widget.uid, Global.profile.getString("uid") ?? "", pn, 50);
    if (page.unavailable) {
      return _PageData<TiebaUserLikeForum>(
        hidden: false,
        items: pn == 1 ? user.likeForums : const <TiebaUserLikeForum>[],
        hasMore: false,
        notice: user.likeForums.isEmpty ? '关注的吧已隐藏' : '其余吧已隐藏',
      );
    }
    if (pn == 1 && page.forums.isEmpty && (total ?? 0) > 0) {
      // 已知有关注却没拿到列表，显示可重试错误，而非「没有关注」。
      throw StateError('关注吧数量与列表响应不一致');
    }
    return _PageData<TiebaUserLikeForum>(
      hidden: false,
      items: page.forums,
      hasMore: page.hasMore,
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
                    load: (int pn) => _loadUserForums(user, pn),
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

  Widget _desktopTab<T>({
    required int index,
    required Future<_PageData<T>> Function(int pn) load,
    required Widget Function(BuildContext context, T item) itemBuilder,
    required String emptyTitle,
    required String emptyBody,
    required String hiddenText,
    SliverGridDelegate? gridDelegate,
  }) {
    return KeepAliveWrapper(
      child: _DesktopVisitorTab<T>(
        load: load,
        itemBuilder: itemBuilder,
        tabIndex: index,
        refreshSignal: _desktopRefreshSignal,
        emptyTitle: emptyTitle,
        emptyBody: emptyBody,
        hiddenText: hiddenText,
        gridDelegate: gridDelegate,
      ),
    );
  }

  /// 用户帖 / 回复共用 [ThreadSummary]。
  Widget _userPostCard(
    TiebaUserPost post, {
    required bool threads,
    bool desktop = false,
  }) {
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
      desktop: desktop,
      showForumChip: desktop,
      margin: desktop ? const EdgeInsets.only(bottom: 11) : null,
    );
  }
}

/// 桌面端左侧停靠用户档案卡（`< 900dp` 变为顶部满宽横卡）。
class _DesktopUserDock extends StatelessWidget {
  const _DesktopUserDock({
    required this.user,
    required this.isSelf,
    required this.compact,
  });

  final TiebaUserProfile user;
  final bool isSelf;
  final bool compact;

  bool get _chatSupported {
    try {
      return Global.tiebaAPI is TiebaChatApi;
    } catch (_) {
      return false;
    }
  }

  void _copyUid() {
    Clipboard.setData(ClipboardData(text: user.uid));
    Fluttertoast.showToast(msg: '已复制 ID：${user.uid}');
  }

  void _openChat(BuildContext context) {
    Navigator.pushNamed(
      context,
      PageRouter.chat,
      arguments: ChatRouteData(
        conversationId: user.uid,
        peerUid: user.uid,
        title: user.name,
        avatar: profileEvents.avatarUrl(user.uid, user.portraitUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DesktopPanel(
      borderRadius: TiebananaMetrics.brXl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHero(context, tokens, textTheme),
          _buildBody(context, tokens, textTheme),
        ],
      ),
    );
  }

  Widget _buildHero(
    BuildContext context,
    TiebananaTokens tokens,
    TextTheme textTheme,
  ) {
    final String resolvedAvatar =
        profileEvents.avatarUrl(user.uid, user.portraitUrl);
    final bool hasLocalPreview = profileEvents.avatarPreview(user.uid) != null;
    final bool useLightbox = !hasLocalPreview &&
        (resolvedAvatar.startsWith('http://') ||
            resolvedAvatar.startsWith('https://'));

    final Widget avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: tokens.surface, width: 2),
        boxShadow: tokens.cardShadow,
      ),
      child: Avatar(
        userId: user.uid,
        imgUrl: resolvedAvatar,
        height: compact ? 54 : 64,
        width: compact ? 54 : 64,
        onTap: useLightbox
            ? () => showBroadcastImageLightbox(
                  context,
                  url: resolvedAvatar,
                  title: '${user.name} 的头像',
                  desktop: true,
                )
            : null,
      ),
    );

    final Widget identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          user.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 5,
          runSpacing: 4,
          children: <Widget>[
            if (isSelf)
              _SoftTag(
                label: '本人',
                bg: tokens.primaryContainer,
                fg: tokens.onPrimaryContainer,
              ),
            if (isSelf && user.nicknameEditing)
              _SoftTag(
                label: '昵称审核中',
                bg: tokens.danger.withValues(alpha: .12),
                fg: tokens.danger,
              ),
            if (user.sex == '1')
              _SoftTag(
                label: '♂ 男',
                bg: _kMaleColor.withValues(alpha: .14),
                fg: _kMaleColor,
              )
            else if (user.sex == '2')
              _SoftTag(
                label: '♀ 女',
                bg: _kFemaleColor.withValues(alpha: .14),
                fg: _kFemaleColor,
              ),
          ],
        ),
      ],
    );

    final bool emptyBio = user.intro.trim().isEmpty;
    final Widget bio = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(
            Icons.edit_outlined,
            size: 14,
            color: emptyBio
                ? tokens.textTertiary.withValues(alpha: .6)
                : tokens.textTertiary,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            emptyBio ? '这懒人没设签名喵' : user.intro,
            maxLines: compact ? 2 : 4,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12.5,
              height: 1.55,
              color: emptyBio ? tokens.textTertiary : tokens.textSecondary,
            ),
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        compact ? 14 : 18,
        18,
        compact ? 12 : 15,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(tokens.surface, tokens.primaryContainer, 0.55)!,
            Color.lerp(tokens.surface, tokens.primaryContainer, 0.14)!,
            tokens.surface,
          ],
          stops: const <double>[0, 0.72, 1],
        ),
        border: Border(bottom: BorderSide(color: tokens.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              avatar,
              const SizedBox(width: 8),
              Expanded(child: identity),
              if (compact) ...<Widget>[
                const SizedBox(width: 10),
                _buildActions(context, tokens, compactCluster: true),
              ] else if (!isSelf)
                _UserMorePopoverButton(user: user),
            ],
          ),
          SizedBox(height: compact ? 10 : 12),
          bio,
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TiebananaTokens tokens,
    TextTheme textTheme,
  ) {
    final Widget stats = _buildStatsGrid(tokens, textTheme);
    final Widget meta = _buildMetaLedger(context, tokens, textTheme);

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        child: Row(
          children: <Widget>[
            Expanded(flex: 5, child: stats),
            const SizedBox(width: 16),
            Expanded(flex: 6, child: meta),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          stats,
          const SizedBox(height: 12),
          _buildActions(context, tokens, compactCluster: false),
          const SizedBox(height: 14),
          meta,
        ],
      ),
    );
  }

  Widget _buildStatsGrid(TiebananaTokens tokens, TextTheme textTheme) {
    final List<MapEntry<String, String>> items = <MapEntry<String, String>>[
      MapEntry<String, String>('获赞', user.displayTotalAgreeNum),
      MapEntry<String, String>('粉丝', user.fansNum),
      MapEntry<String, String>('关注', user.concernNum),
    ];

    return Container(
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.line),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            for (int i = 0; i < items.length; i++) ...<Widget>[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 8,
                  endIndent: 8,
                  color: tokens.line,
                ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        items[i].value.isEmpty ? '0' : items[i].value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].key,
                        maxLines: 1,
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          color: tokens.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    TiebananaTokens tokens, {
    required bool compactCluster,
  }) {
    if (isSelf) {
      return FilledButton.icon(
        onPressed: () => Navigator.pushNamed(context, PageRouter.profileEdit),
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.accentOn,
          minimumSize: Size(compactCluster ? 0 : double.infinity, 34),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle:
              const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.edit_outlined, size: 15),
        label: const Text('编辑资料'),
      );
    }

    final Widget followBtn = FilledButton.tonal(
      onPressed: () => Fluttertoast.showToast(msg: '关注接口还没接入'),
      style: FilledButton.styleFrom(
        backgroundColor: tokens.primaryContainer,
        foregroundColor: tokens.onPrimaryContainer,
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      child: const Text('＋ 关注'),
    );

    final Widget? chatBtn = _chatSupported
        ? OutlinedButton.icon(
            onPressed: () => _openChat(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.textPrimary,
              side: BorderSide(color: tokens.line),
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
            label: const Text('私信'),
          )
        : null;

    if (compactCluster) {
      return Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (chatBtn != null) chatBtn,
          followBtn,
          _UserMorePopoverButton(user: user),
        ],
      );
    }

    if (chatBtn == null) {
      return SizedBox(width: double.infinity, child: followBtn);
    }

    return Row(
      children: <Widget>[
        Expanded(child: chatBtn),
        const SizedBox(width: 8),
        Expanded(child: followBtn),
      ],
    );
  }

  Widget _buildMetaLedger(
    BuildContext context,
    TiebananaTokens tokens,
    TextTheme textTheme,
  ) {
    final TextStyle? keyStyle = textTheme.bodySmall?.copyWith(
      fontSize: 12,
      color: tokens.textTertiary,
    );
    final TextStyle? valStyle = textTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: tokens.textPrimary,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );

    final Widget idRow = Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment:
          compact ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('贴吧 ID', style: keyStyle),
        const SizedBox(width: 8),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  user.uid,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: valStyle,
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: tokens.fill,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: _copyUid,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.copy_rounded,
                            size: 11, color: tokens.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '复制',
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final Widget? ageRow = user.tbAge.trim().isEmpty
        ? null
        : Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: compact
                ? MainAxisAlignment.start
                : MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('吧龄', style: keyStyle),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  user.tbAge.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: valStyle,
                ),
              ),
            ],
          );

    final Widget postRow = Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment:
          compact ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('历史发帖', style: keyStyle),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '贴子 ${user.postNum} · 回复 ${user.rePostNum}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: compact ? TextAlign.start : TextAlign.end,
            style: valStyle,
          ),
        ),
      ],
    );

    if (compact) {
      return Wrap(
        spacing: 14,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          idRow,
          if (ageRow != null) ageRow,
          postRow,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        idRow,
        if (ageRow != null) ...<Widget>[
          const SizedBox(height: 7),
          ageRow,
        ],
        const SizedBox(height: 7),
        postRow,
      ],
    );
  }
}

class _SoftTag extends StatelessWidget {
  const _SoftTag({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TiebananaMetrics.radiusXs),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1,
            ),
      ),
    );
  }
}

/// 桌面端锚定用户管理菜单（举报用户 / 拉黑范围）。
class _UserMorePopoverButton extends StatelessWidget {
  const _UserMorePopoverButton({required this.user});

  final TiebaUserProfile user;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return PopupMenuButton<String>(
      tooltip: '更多用户操作',
      offset: const Offset(0, 34),
      color: tokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tokens.line),
      ),
      onSelected: (String action) {
        if (action == 'report') {
          openReportPage(
            context,
            TiebaReportTarget(
              kind: TiebaReportKind.user,
              userId: user.uid,
              name: user.name,
              portrait: user.portraitUrl,
              source: '用户资料',
            ),
          );
        } else if (action == 'block') {
          showBlockSettings(context, uid: user.uid, name: user.name);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: <Widget>[
              Icon(Icons.flag_outlined, size: 17, color: tokens.textSecondary),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('举报用户',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary)),
                  Text('反馈个人资料或发布内容违规',
                      style: TextStyle(
                          fontSize: 10.5, color: tokens.textTertiary)),
                ],
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'block',
          child: Row(
            children: <Widget>[
              Icon(Icons.block_outlined, size: 17, color: tokens.danger),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('拉黑范围',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.danger)),
                  Text('设置关注、互动及私信权限',
                      style: TextStyle(
                          fontSize: 10.5, color: tokens.textTertiary)),
                ],
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.line.withValues(alpha: .7)),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.more_horiz_rounded,
            size: 17, color: tokens.textSecondary),
      ),
    );
  }
}

/// 桌面端右侧吸顶控制条（药丸页签 + 当前页签说明）。
class _DesktopVisitorControlBar extends StatelessWidget {
  const _DesktopVisitorControlBar({
    required this.tabIndex,
    required this.threads,
    required this.replies,
    required this.forums,
    required this.onSelectTab,
  });

  final int tabIndex;
  final String threads;
  final String replies;
  final String forums;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final List<({String label, String count})> items =
        <({String label, String count})>[
      (label: '贴子', count: threads),
      (label: '回复', count: replies),
      (label: '关注的吧', count: forums),
    ];
    final String tip = switch (tabIndex) {
      0 => '点击帖子进帖',
      1 => '含原帖引用上下文',
      _ => '2 列网格 · 点击进吧',
    };

    return DesktopPanel(
      borderRadius: TiebananaMetrics.brCtl,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (int i = 0; i < items.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: 4),
                    _ControlPillTab(
                      label: '${items[i].label} ${items[i].count}',
                      selected: tabIndex == i,
                      onTap: () => onSelectTab(i),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            tip,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: tokens.textTertiary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ControlPillTab extends StatelessWidget {
  const _ControlPillTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Material(
      color: selected ? tokens.primaryContainer : Colors.transparent,
      borderRadius: TiebananaMetrics.brPill,
      child: InkWell(
        borderRadius: TiebananaMetrics.brPill,
        hoverColor: tokens.primary.withValues(alpha: .05),
        onTap: onTap,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color:
                  selected ? tokens.onPrimaryContainer : tokens.textSecondary,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

/// 桌面端右侧分页列表/网格：与顶栏刷新联动，带显式分页状态页脚。
class _DesktopVisitorTab<T> extends StatefulWidget {
  const _DesktopVisitorTab({
    required this.load,
    required this.itemBuilder,
    required this.tabIndex,
    required this.refreshSignal,
    required this.emptyTitle,
    required this.emptyBody,
    required this.hiddenText,
    this.gridDelegate,
  });

  final Future<_PageData<T>> Function(int pn) load;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final int tabIndex;
  final ValueNotifier<int> refreshSignal;
  final String emptyTitle;
  final String emptyBody;
  final String hiddenText;
  final SliverGridDelegate? gridDelegate;

  @override
  State<_DesktopVisitorTab<T>> createState() => _DesktopVisitorTabState<T>();
}

class _DesktopVisitorTabState<T> extends State<_DesktopVisitorTab<T>> {
  final List<T> _items = <T>[];
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
    widget.refreshSignal.addListener(_onRefreshSignal);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetch(1, refresh: true);
    });
  }

  @override
  void didUpdateWidget(covariant _DesktopVisitorTab<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal.removeListener(_onRefreshSignal);
      widget.refreshSignal.addListener(_onRefreshSignal);
    }
  }

  @override
  void dispose() {
    widget.refreshSignal.removeListener(_onRefreshSignal);
    super.dispose();
  }

  void _onRefreshSignal() {
    if (mounted) _fetch(1, refresh: true);
  }

  Future<void> _fetch(int pn, {bool refresh = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (refresh) _error = null;
    });
    try {
      final _PageData<T> page = await widget.load(pn);
      if (!mounted) return;
      setState(() {
        if (refresh) _items.clear();
        _pn = pn;
        _items.addAll(page.items);
        _hidden = page.hidden;
        _hasMore = page.hasMore ?? page.items.isNotEmpty;
        _notice = page.notice;
        _first = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _first = false;
        _error = e;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _statePanel({
    required IconData icon,
    required String title,
    required String body,
    VoidCallback? onRetry,
  }) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: DesktopPanel(
        borderRadius: TiebananaMetrics.brXl,
        child: StateView(
          icon: icon,
          title: title,
          body: body,
          primaryLabel: onRetry == null ? null : '重试',
          primaryIcon: onRetry == null ? null : Icons.refresh,
          onPrimary: onRetry,
        ),
      ),
    );
  }

  Widget _footer(TiebananaTokens tokens) {
    final TextStyle? style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 12,
          color: tokens.textTertiary,
        );
    if (_loading && _items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: tokens.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text('正在加载更多…', style: style),
          ],
        ),
      );
    }
    if (_error != null && _items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('加载失败，', style: style),
            TextButton(
              onPressed: () => _fetch(_pn + 1),
              child: const Text('点此重试'),
            ),
          ],
        ),
      );
    }
    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            OutlinedButton(
              onPressed: () => _fetch(_pn + 1),
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.textSecondary,
                side: BorderSide(color: tokens.line),
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
              child: const Text('点击加载更多'),
            ),
            const SizedBox(width: 10),
            Text('已显示 ${_items.length} 条', style: style),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(child: Text('已加载全部 ${_items.length} 条内容', style: style)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    if (_hidden) {
      return _statePanel(
        icon: Icons.lock_outline,
        title: widget.hiddenText,
        body: '这是接口明确给出的隐私状态，不等于「列表为空」',
      );
    }
    if (_first) {
      return const _DesktopTabSkeleton();
    }
    if (_items.isEmpty && _error != null) {
      return _statePanel(
        icon: Icons.wifi_off_outlined,
        title: '网络似乎有点问题',
        body: '检查一下网络连接后重试',
        onRetry: () => _fetch(1, refresh: true),
      );
    }
    if (_items.isEmpty) {
      if (_notice != null) {
        return _statePanel(
          icon: Icons.lock_outline,
          title: '关注的吧已隐藏',
          body: _notice!,
        );
      }
      return _statePanel(
        icon: Icons.inbox_outlined,
        title: widget.emptyTitle,
        body: widget.emptyBody,
      );
    }

    return TiebananaRefreshIndicator(
      onRefresh: () => _fetch(1, refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification.metrics.axis != Axis.vertical) return false;
          final ScrollMetrics m = notification.metrics;
          if (m.maxScrollExtent > 0 &&
              m.pixels >= m.maxScrollExtent - m.viewportDimension) {
            if (_hasMore && !_loading) {
              Throttle.seconds(1, () => _fetch(_pn + 1));
            }
          }
          return false;
        },
        child: CustomScrollView(
          key: PageStorageKey<String>('desktop-visitor-tab-${widget.tabIndex}'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            if (widget.gridDelegate != null)
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) =>
                      widget.itemBuilder(context, _items[index]),
                  childCount: _items.length,
                ),
                gridDelegate: widget.gridDelegate!,
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) =>
                      widget.itemBuilder(context, _items[index]),
                  childCount: _items.length,
                ),
              ),
            if (_notice != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: tokens.fill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: tokens.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _notice!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _footer(tokens),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopVisitorSkeleton extends StatelessWidget {
  const _DesktopVisitorSkeleton({required this.windowWidth});

  final double windowWidth;

  @override
  Widget build(BuildContext context) {
    final bool twoCol = windowWidth >= AppBreakpoints.mediumMax;
    final double dockWidth = windowWidth >= 1100 ? 296 : 268;

    final Widget dockSkeleton = DesktopPanel(
      borderRadius: TiebananaMetrics.brXl,
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const SkeletonBox(width: 64, height: 64, radius: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const <Widget>[
                    SkeletonBox(width: 110, height: 18, radius: 6),
                    SizedBox(height: 8),
                    SkeletonBox(width: 62, height: 18, radius: 6),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonBox(width: double.infinity, height: 12),
          const SizedBox(height: 7),
          const SkeletonBox(width: 160, height: 12),
          const SizedBox(height: 16),
          const SkeletonBox(width: double.infinity, height: 54, radius: 12),
          const SizedBox(height: 12),
          const SkeletonBox(width: double.infinity, height: 34, radius: 10),
        ],
      ),
    );

    return PageWrap(
      bottomPadding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const DesktopPageHeader(
            title: '用户主页',
            subtitle: '正在读取用户资料与动态…',
          ),
          if (twoCol)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(width: dockWidth, child: dockSkeleton),
                  const SizedBox(width: 16),
                  const Expanded(child: _DesktopTabSkeleton(withHeader: true)),
                ],
              ),
            )
          else
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  dockSkeleton,
                  const SizedBox(height: 12),
                  const Expanded(child: _DesktopTabSkeleton(withHeader: true)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DesktopTabSkeleton extends StatelessWidget {
  const _DesktopTabSkeleton({this.withHeader = false});

  final bool withHeader;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: <Widget>[
          if (withHeader) ...<Widget>[
            DesktopPanel(
              borderRadius: TiebananaMetrics.brCtl,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: const <Widget>[
                  SkeletonBox(width: 82, height: 28, radius: 999),
                  SizedBox(width: 6),
                  SkeletonBox(width: 82, height: 28, radius: 999),
                  SizedBox(width: 6),
                  SkeletonBox(width: 96, height: 28, radius: 999),
                ],
              ),
            ),
            const SizedBox(height: 11),
          ],
          for (int i = 0; i < 3; i++)
            DesktopPanel(
              margin: const EdgeInsets.only(bottom: 11),
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  Row(
                    children: <Widget>[
                      SkeletonBox(width: 24, height: 24, radius: 12),
                      SizedBox(width: 8),
                      SkeletonBox(width: 84, height: 12),
                      SizedBox(width: 8),
                      SkeletonBox(width: 60, height: 18, radius: 6),
                    ],
                  ),
                  SizedBox(height: 12),
                  SkeletonBox(width: 340, height: 15),
                  SizedBox(height: 8),
                  SkeletonBox(width: double.infinity, height: 12),
                  SizedBox(height: 6),
                  SkeletonBox(width: 240, height: 12),
                ],
              ),
            ),
        ],
      ),
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
            onTap: () {
              Clipboard.setData(ClipboardData(text: user.uid));
              Fluttertoast.showToast(msg: '已复制 ID：${user.uid}');
            },
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
              color: user.sex == "1" ? _kMaleColor : _kFemaleColor,
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

  /// 访客显示「私信」+「＋ 关注」，本人显示「编辑资料」。
  ///
  /// 私信入口只在后端实现 [TiebaChatApi] 时出现；发起会话时把 uid 作为
  /// `toUid`，首次发送由 205001 建立会话。
  Widget _actionButton(BuildContext context, TiebananaTokens tokens) {
    final bool self = isSelf;
    bool chatSupported = false;
    try {
      chatSupported = Global.tiebaAPI is TiebaChatApi;
    } catch (_) {
      // 后端尚未初始化（测试或启动早期）时不显示私信入口。
    }
    if (self) {
      return _pillButton(
        context,
        tokens,
        label: '编辑资料',
        onTap: () => Navigator.pushNamed(context, PageRouter.profileEdit),
        tonal: false,
      );
    }
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 4,
      children: <Widget>[
        if (chatSupported)
          _pillButton(
            context,
            tokens,
            label: '私信',
            icon: Icons.chat_bubble_outline,
            onTap: () => Navigator.pushNamed(
              context,
              PageRouter.chat,
              arguments: ChatRouteData(
                conversationId: user.uid,
                peerUid: user.uid,
                title: user.name,
                avatar: profileEvents.avatarUrl(user.uid, user.portraitUrl),
              ),
            ),
            tonal: false,
          ),
        _pillButton(
          context,
          tokens,
          label: '＋ 关注',
          onTap: () => Fluttertoast.showToast(msg: '关注接口还没接入'),
          tonal: true,
        ),
      ],
    );
  }

  Widget _pillButton(
    BuildContext context,
    TiebananaTokens tokens, {
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    required bool tonal,
  }) {
    return Material(
      color: tonal ? tokens.primaryContainer : Colors.transparent,
      borderRadius: TiebananaMetrics.brPill,
      child: InkWell(
        borderRadius: TiebananaMetrics.brPill,
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: TiebananaMetrics.brPill,
            border: tonal ? null : Border.all(color: tokens.lineStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 14,
                  color:
                      tonal ? tokens.onPrimaryContainer : tokens.textSecondary,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: tonal
                          ? tokens.onPrimaryContainer
                          : tokens.textSecondary,
                    ),
              ),
            ],
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
