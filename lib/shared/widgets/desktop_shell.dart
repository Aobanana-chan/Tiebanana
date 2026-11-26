import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/features/account/widgets/account_switch_sheet.dart';
import 'package:tiebanana/features/forum/state/forum_state.dart';
import 'package:tiebanana/features/message/state/notification_reminder.dart';
import 'package:tiebanana/features/message/widgets/reminder_sheet.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/app_toast.dart';
import 'package:tiebanana/shared/widgets/avatar_image.dart';
import 'package:tiebanana/shared/widgets/message_badge.dart';

/// 桌面端统一壳层（`≥ 720dp`）：左侧导航栏（76px 图标轨 / 220px 展开侧边栏）
/// + 顶部 56px 全局栏 + 主工作区。
///
/// 根页面（首页/动态/消息/个人）与二级页面（吧主页/帖子详情/搜索等）共用此壳层。
class DesktopShellFrame extends StatefulWidget {
  const DesktopShellFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.activeTab = 0,
    this.onSelectTab,
    this.onRefresh,
    this.onBack,
    this.onSearchTap,
    this.hideSearchPill = false,
    this.replaceForumRoute = false,
    this.topBarTrailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// 当前高亮的一级分区下标：0 首页 / 1 动态 / 2 消息 / 3 个人；二级页面可传 -1。
  final int activeTab;

  /// 根页面切页签回调；为 null 时设置 [Global.desktopTabRequest] 并退回首页根路由。
  final ValueChanged<int>? onSelectTab;
  final VoidCallback? onRefresh;
  final VoidCallback? onBack;
  final VoidCallback? onSearchTap;
  final bool hideSearchPill;
  final bool replaceForumRoute;
  final List<Widget>? topBarTrailing;

  @override
  State<DesktopShellFrame> createState() => _DesktopShellFrameState();
}

class _DesktopShellFrameState extends State<DesktopShellFrame> {
  final GlobalKey _bellKey = GlobalKey();
  bool _signingAll = false;

  static T? _maybeRead<T>(BuildContext context, {bool listen = true}) {
    try {
      return Provider.of<T>(context, listen: listen);
    } catch (_) {
      return null;
    }
  }

  void _selectTab(int index) {
    if (widget.onSelectTab != null) {
      widget.onSelectTab!(index);
      return;
    }
    Global.desktopTabRequest.value = index;
    Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
  }

  void _openSearch() {
    if (widget.onSearchTap != null) {
      widget.onSearchTap!();
      return;
    }
    if (widget.hideSearchPill) return;
    Navigator.pushNamed(context, PageRouter.search, arguments: '');
  }

  void _goBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
    }
  }

  void _triggerRefresh() {
    if (widget.onRefresh != null) {
      widget.onRefresh!();
      return;
    }
    Global.desktopRefreshTick.value++;
  }

  void _toggleSidebarFold() {
    final APPSettingProvider? settings =
        _maybeRead<APPSettingProvider>(context, listen: false);
    if (settings != null) {
      settings.sidebarFolded = !settings.sidebarFolded;
    } else {
      Global.setting.sidebarFolded = !Global.setting.sidebarFolded;
      Global.saveProfile();
      setState(() {});
    }
  }

  void _toggleBrightness(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final int nextMode = isDark ? 2 : 1;
    final APPSettingProvider? settings =
        _maybeRead<APPSettingProvider>(context, listen: false);
    if (settings != null) {
      settings.darkModel = nextMode;
    } else {
      Global.setting.darkModel = nextMode;
      Global.saveProfile();
      setState(() {});
    }
  }

  Future<void> _signAll(ForumState? forumState) async {
    if (_signingAll) return;
    setState(() => _signingAll = true);
    Fluttertoast.showToast(msg: '签到开始，可前往通知栏查看签到进度');
    try {
      await Global.tiebaAPI.signAll();
    } catch (e) {
      final String msg =
          e is NetAPIError ? (e.errorMessage ?? '一键签到失败') : '一键签到失败';
      Fluttertoast.showToast(msg: msg);
    } finally {
      await forumState?.refresh();
      if (mounted) setState(() => _signingAll = false);
    }
  }

  void _openForum(String forumName) {
    if (widget.replaceForumRoute) {
      Navigator.pushReplacementNamed(context, PageRouter.forumHome,
          arguments: forumName);
    } else {
      Navigator.pushNamed(context, PageRouter.forumHome, arguments: forumName);
    }
  }

  void _openAccountPanel() {
    final User? user = _maybeRead<User>(context, listen: false);
    if (user != null && !user.isLogin) {
      Navigator.pushNamed(context, PageRouter.login);
      return;
    }
    showAccountSwitchSheet(context);
  }

  void _openBell() {
    final RenderBox? box =
        _bellKey.currentContext?.findRenderObject() as RenderBox?;
    Rect? anchor;
    if (box != null && box.attached) {
      anchor = box.localToGlobal(Offset.zero) & box.size;
    }
    showReminderSheet(context, anchorRect: anchor);
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final double width = MediaQuery.sizeOf(context).width;
    final APPSettingProvider? settings =
        _maybeRead<APPSettingProvider>(context);
    final bool foldedSetting =
        settings?.sidebarFolded ?? Global.setting.sidebarFolded;
    final bool canExpand = width >= AppBreakpoints.expandedMax;
    final bool expanded = canExpand && !foldedSetting;

    final User? user = _maybeRead<User>(context);
    final ForumState? forumState = _maybeRead<ForumState>(context);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _openSearch,
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
            _selectTab(0),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
            _selectTab(1),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
            _selectTab(2),
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () =>
            _selectTab(3),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): _goBack,
        const SingleActivator(LogicalKeyboardKey.bracketLeft, control: true):
            _goBack,
        const SingleActivator(LogicalKeyboardKey.f5): _triggerRefresh,
        const SingleActivator(LogicalKeyboardKey.keyR, control: true):
            _triggerRefresh,
      },
      child: FocusScope(
        child: Scaffold(
          backgroundColor: tokens.bg,
          resizeToAvoidBottomInset: false,
          body: Row(
            children: <Widget>[
              _DesktopSidebar(
                expanded: expanded,
                canExpand: canExpand,
                activeTab: widget.activeTab,
                onToggleFold: _toggleSidebarFold,
                onSelectTab: _selectTab,
                forumState: forumState,
                user: user,
                signingAll: _signingAll,
                onSignAll: () => _signAll(forumState),
                onOpenForum: _openForum,
                onOpenAccount: _openAccountPanel,
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    _DesktopTopBar(
                      title: widget.title,
                      subtitle: widget.subtitle,
                      canGoBack: widget.onBack != null ||
                          Navigator.of(context).canPop(),
                      onBack: _goBack,
                      hideSearchPill: widget.hideSearchPill,
                      onSearchTap: _openSearch,
                      onRefresh: _triggerRefresh,
                      bellKey: _bellKey,
                      onBellTap: _openBell,
                      onToggleBrightness: () => _toggleBrightness(context),
                      showTopAvatar: !expanded,
                      user: user,
                      onAvatarTap: () => _selectTab(3),
                      trailing: widget.topBarTrailing,
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.expanded,
    required this.canExpand,
    required this.activeTab,
    required this.onToggleFold,
    required this.onSelectTab,
    required this.forumState,
    required this.user,
    required this.signingAll,
    required this.onSignAll,
    required this.onOpenForum,
    required this.onOpenAccount,
  });

  final bool expanded;
  final bool canExpand;
  final int activeTab;
  final VoidCallback onToggleFold;
  final ValueChanged<int> onSelectTab;
  final ForumState? forumState;
  final User? user;
  final bool signingAll;
  final VoidCallback onSignAll;
  final ValueChanged<String> onOpenForum;
  final VoidCallback onOpenAccount;

  static const List<({IconData icon, IconData activeIcon, String label})>
      _navItems = <({IconData icon, IconData activeIcon, String label})>[
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: '首页',
    ),
    (
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: '动态',
    ),
    (
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: '消息',
    ),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: '个人与设置',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final double width =
        expanded ? AppBreakpoints.sidebarWidth : AppBreakpoints.railWidth;

    return AnimatedContainer(
      duration: TiebananaMetrics.durationFast,
      curve: TiebananaMetrics.curveStandard,
      width: width,
      decoration: BoxDecoration(
        color: tokens.bar,
        border: Border(right: BorderSide(color: tokens.line)),
      ),
      padding: EdgeInsets.fromLTRB(
        expanded ? 11 : 8,
        13,
        expanded ? 11 : 8,
        11,
      ),
      child: Column(
        crossAxisAlignment:
            expanded ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
        children: <Widget>[
          _buildBrand(context, tokens),
          const SizedBox(height: 8),
          for (int i = 0; i < _navItems.length; i++) ...<Widget>[
            _buildNavItem(context, tokens, i, _navItems[i]),
            if (i < _navItems.length - 1) const SizedBox(height: 3),
          ],
          if (expanded &&
              forumState != null &&
              forumState!.forums.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Expanded(child: _buildQuickForums(context, tokens)),
          ] else
            const Spacer(),
          _buildAccountCard(context, tokens),
        ],
      ),
    );
  }

  Widget _buildBrand(BuildContext context, TiebananaTokens tokens) {
    final Widget logo = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/icon/ic_launcher.png',
        width: 28,
        height: 28,
        fit: BoxFit.cover,
      ),
    );

    if (!expanded) {
      final Widget icon = Padding(
        padding: const EdgeInsets.only(top: 3, bottom: 11),
        child: canExpand
            ? Tooltip(
                message: '展开侧边栏',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onToggleFold,
                  child: logo,
                ),
              )
            : logo,
      );
      return Center(child: icon);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 3, 2, 9),
      child: Row(
        children: <Widget>[
          logo,
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Tiebanana',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'TiebananaWordmark',
                fontSize: 19,
                height: 1,
                color: tokens.textPrimary,
              ),
            ),
          ),
          Tooltip(
            message: '折叠侧边栏',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onToggleFold,
              child: SizedBox(
                width: 26,
                height: 26,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 16,
                  color: tokens.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    TiebananaTokens tokens,
    int index,
    ({IconData icon, IconData activeIcon, String label}) item,
  ) {
    final bool selected = activeTab == index;
    final Color fg =
        selected ? tokens.onPrimaryContainer : tokens.textSecondary;
    final Color bg = selected ? tokens.primaryContainer : Colors.transparent;
    final IconData iconData = selected ? item.activeIcon : item.icon;
    final bool isMessage = index == 2;

    if (!expanded) {
      final Widget iconWidget = Icon(iconData, size: 20, color: fg);
      return Tooltip(
        message: item.label,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            hoverColor: tokens.primary.withValues(alpha: .05),
            onTap: () => onSelectTab(index),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: Center(
                child: isMessage
                    ? MessageBadge(compactDot: true, child: iconWidget)
                    : iconWidget,
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        hoverColor: tokens.primary.withValues(alpha: .05),
        onTap: () => onSelectTab(index),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: <Widget>[
              Icon(iconData, size: 20, color: fg),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                ),
              ),
              if (isMessage) const MessageBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickForums(BuildContext context, TiebananaTokens tokens) {
    final List<LikeForumInfo> quick =
        forumState!.forums.take(8).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(9, 0, 4, 6),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '常逛的吧',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: tokens.textTertiary,
                      ),
                ),
              ),
              Tooltip(
                message: '一键签到',
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: signingAll ? null : onSignAll,
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: signingAll
                        ? Padding(
                            padding: const EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: tokens.primary,
                            ),
                          )
                        : Icon(Icons.check_rounded,
                            size: 14, color: tokens.textTertiary),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: quick.length,
            padding: EdgeInsets.zero,
            itemBuilder: (BuildContext context, int index) {
              final LikeForumInfo forum = quick[index];
              final bool signed = forum.isSign != '0';
              return InkWell(
                borderRadius: BorderRadius.circular(9),
                hoverColor: tokens.primary.withValues(alpha: .05),
                onTap: () => onOpenForum(forum.forumName),
                child: SizedBox(
                  height: 31,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    child: Row(
                      children: <Widget>[
                        _MiniForumAvatar(url: forum.avatar),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            forum.forumName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 12.5,
                                      color: tokens.textSecondary,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (signed)
                          Icon(Icons.check_rounded,
                              size: 13, color: tokens.primary)
                        else
                          Text(
                            'Lv.${forum.levelId}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: tokens.textTertiary,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(BuildContext context, TiebananaTokens tokens) {
    final TiebananaAccount? account = AccountStore.current;
    final String name = (user?.name.isNotEmpty ?? false)
        ? user!.name
        : ((account?.name.isNotEmpty ?? false) ? account!.name : '未登录');
    final String portrait = account?.portraitUrl ?? '';
    final int forumCount = forumState?.forums.length ?? 0;
    final String sub = (user?.isLogin ?? false)
        ? (forumCount > 0 ? '$forumCount 个关注的吧' : '点击切换账号')
        : '点击登录账号';

    if (!expanded) {
      return Tooltip(
        message: name,
        child: Material(
          color: tokens.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: tokens.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onOpenAccount,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
              child: Center(
                child: Avatar(
                  imgUrl: portrait,
                  userId: account?.uid,
                  width: 32,
                  height: 32,
                  onTap: onOpenAccount,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tokens.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpenAccount,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Row(
            children: <Widget>[
              Avatar(
                imgUrl: portrait,
                userId: account?.uid,
                width: 32,
                height: 32,
                onTap: onOpenAccount,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10.5,
                            color: tokens.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: '个人与设置',
                child: InkWell(
                  borderRadius: BorderRadius.circular(7),
                  onTap: () => onSelectTab(3),
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: Icon(
                      Icons.settings_outlined,
                      size: 16,
                      color: tokens.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniForumAvatar extends StatelessWidget {
  const _MiniForumAvatar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final String resolved = resolveAvatarUrl(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 20,
        height: 20,
        color: tokens.fill,
        child: resolved.isEmpty
            ? Icon(Icons.forum_outlined, size: 12, color: tokens.textTertiary)
            : AvatarImage(url: resolved),
      ),
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.title,
    required this.subtitle,
    required this.canGoBack,
    required this.onBack,
    required this.hideSearchPill,
    required this.onSearchTap,
    required this.onRefresh,
    required this.bellKey,
    required this.onBellTap,
    required this.onToggleBrightness,
    required this.showTopAvatar,
    required this.user,
    required this.onAvatarTap,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool canGoBack;
  final VoidCallback onBack;
  final bool hideSearchPill;
  final VoidCallback onSearchTap;
  final VoidCallback onRefresh;
  final GlobalKey bellKey;
  final VoidCallback onBellTap;
  final VoidCallback onToggleBrightness;
  final bool showTopAvatar;
  final User? user;
  final VoidCallback onAvatarTap;
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final TiebananaAccount? account = AccountStore.current;

    return Container(
      height: AppBreakpoints.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: tokens.bar,
        border: Border(bottom: BorderSide(color: tokens.line)),
      ),
      child: Row(
        children: <Widget>[
          _TopIconBtn(
            icon: Icons.arrow_back_rounded,
            tooltip: '返回 (Alt + ←)',
            onTap: canGoBack ? onBack : null,
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                        height: 1.2,
                      ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          color: tokens.textTertiary,
                          height: 1.2,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (!hideSearchPill) ...<Widget>[
            const SizedBox(width: 12),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Tooltip(
                    message: '全局搜索 (Ctrl + K)',
                    child: Material(
                      color: tokens.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: TiebananaMetrics.brPill,
                        side: BorderSide(color: tokens.line),
                      ),
                      child: InkWell(
                        borderRadius: TiebananaMetrics.brPill,
                        onTap: onSearchTap,
                        child: SizedBox(
                          height: 38,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 9, 0),
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.search_rounded,
                                    size: 17, color: tokens.textTertiary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '搜索吧、贴、用户',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontSize: 12.5,
                                          color: tokens.textTertiary,
                                        ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: tokens.fill,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: tokens.line),
                                  ),
                                  child: Text(
                                    'Ctrl K',
                                    style: TextStyle(
                                      fontSize: 10,
                                      height: 1,
                                      color: tokens.textTertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ] else
            const Spacer(),
          if (trailing != null) ...trailing!,
          _TopIconBtn(
            icon: Icons.refresh_rounded,
            tooltip: '刷新 (F5)',
            onTap: onRefresh,
          ),
          ListenableBuilder(
            listenable: NotificationReminder.instance,
            builder: (BuildContext context, _) {
              final NotificationReminder reminder =
                  NotificationReminder.instance;
              if (!reminder.bellVisible) return const SizedBox.shrink();
              return _TopIconBtn(
                buttonKey: bellKey,
                icon: Icons.notifications_none_rounded,
                tooltip: '消息提醒',
                showDot: reminder.bellDot,
                onTap: onBellTap,
              );
            },
          ),
          _TopIconBtn(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            tooltip: isDark ? '切换浅色' : '切换深色',
            onTap: onToggleBrightness,
          ),
          if (showTopAvatar) ...<Widget>[
            const SizedBox(width: 4),
            Tooltip(
              message: (user?.name.isNotEmpty ?? false)
                  ? user!.name
                  : (account?.name ?? '个人与设置'),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onAvatarTap,
                child: Avatar(
                  imgUrl: account?.portraitUrl ?? '',
                  userId: account?.uid,
                  width: 30,
                  height: 30,
                  onTap: onAvatarTap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopIconBtn extends StatelessWidget {
  const _TopIconBtn({
    this.buttonKey,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.showDot = false,
  });

  final GlobalKey? buttonKey;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Color fg = onTap == null
        ? tokens.textTertiary.withValues(alpha: 0.45)
        : tokens.textSecondary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        key: buttonKey,
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Center(child: Icon(icon, size: 18, color: fg)),
              if (showDot)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: tokens.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: tokens.bar, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
