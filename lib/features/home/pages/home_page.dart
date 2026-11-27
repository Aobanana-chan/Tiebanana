import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide SearchBar;
import 'package:tiebanana/shared/widgets/app_toast.dart';
import 'package:tiebanana/shared/widgets/floating_search_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/app/lifecycle/app_lifecycle.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/features/message/state/message_reminder.dart';
import 'package:tiebanana/features/message/state/notification_reminder.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/shared/controllers/back_to_top_controller.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/features/forum/state/forum_state.dart';
import 'package:tiebanana/features/home/widgets/forum_tag.dart';
import 'package:tiebanana/features/search/widgets/search_bar.dart';
import 'package:tiebanana/features/account/pages/login_page.dart';
import 'package:tiebanana/features/message/pages/message_page.dart';
import 'package:tiebanana/features/recommend/pages/recommend_page.dart';
import 'package:tiebanana/features/profile/pages/my_profile_page.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:app_links/app_links.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/link_router.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';
import 'package:tiebanana/shared/widgets/keep_alive_wrapper.dart';
import 'package:tiebanana/shared/widgets/message_badge.dart';
import 'package:tiebanana/core/platform/app_exit.dart';
import 'package:tiebanana/core/platform/browser_url.dart';

///首页
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Widget> page;
  var _currentPage = 0;
  late ForumState forumState;
  PageController controller = PageController();
  final GlobalKey _pageViewKey = GlobalKey();
  bool? _lastDesktop;
  DateTime? lastPopTime;
  late bool Function() onWillPop;
  List<FloatingSearchBarController> barController = [];

  /// 每个页签一个：返回键先问当前页签「列表回顶了没」，回了才走退出流程。
  List<BackToTopController> backToTopController = [];

  /// 当前页签下标。分页器本身不滚动，只在这里更新；消息页据此暂停后台轮询。
  final ValueNotifier<int> _activeTab = ValueNotifier<int>(0);

  StreamSubscription? _sub;
  late AppLinks _appLinks;
  Timer? _reminderTimer;

  /// 上一条已处理的深链；平台偶尔会重复发送，一段时间内只处理一次。
  String? _lastDeepLink;
  DateTime? _lastDeepLinkAt;

  @override
  void initState() {
    super.initState();
    forumState = ForumState();
    // 切换 / 退出账号后，关注的吧属于另一个账号，首页原地刷新。
    AccountStore.changes.addListener(_onAccountChanged);
    Global.desktopTabRequest.addListener(_onDesktopTabRequested);
    // 已读状态建议按版本 + 账号记 SharedPreferences（如 introTipsSeen.<version>.<uid>），
    // 多账号各自记录。
    onWillPop = () {
      if (barController[_currentPage].isOpen) {
        barController[_currentPage].close();
        return false;
      }
      // 列表还没回到顶部：这一次返回只用于「回顶 + 刷新」，
      // 回顶时保留 lastPopTime，退出次数不变。
      if (backToTopController[_currentPage].needsBackToTop) {
        backToTopController[_currentPage].backToTop();
        return false;
      }
      // 点击返回键的操作
      if (lastPopTime == null ||
          DateTime.now().difference(lastPopTime!) >
              const Duration(seconds: 2)) {
        lastPopTime = DateTime.now();
        Fluttertoast.showToast(msg: '请再按一次退出！');
        return false;
      } else {
        lastPopTime = DateTime.now();
        // 退出app
        return true;
      }
    };
    for (var i = 0; i < 4; i++) {
      barController.add(FloatingSearchBarController());
      backToTopController.add(BackToTopController());
    }
    page = _buildPages();
    MessageReminder.reset();
    MessageReminder.refresh();
    MessageReminder.refreshChat();
    NotificationReminder.instance.load();
    // 官方 HTTP 提醒的周期为 600000ms；不为计数预取三个列表。
    _reminderTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      MessageReminder.refresh();
      NotificationReminder.instance.refresh();
    });

    //监听Scheme
    initPlatformStateForStringUniLinks();
  }

  /// 账号切换后整组页面换 key 重建：动态流、消息、个人资料都属于某个人，
  /// 沿用 KeepAlive 的旧 State 会把上一个账号的内容留在屏幕上。
  List<Widget> _buildPages() {
    final int revision = AccountStore.changes.value;
    return <Widget>[
      KeepAliveWrapper(
          key: ValueKey<String>('home-$revision'),
          child: _Home(
            controller: barController[0],
          )),
      KeepAliveWrapper(
          key: ValueKey<String>('recommend-$revision'),
          child: _Recommand(
            controller: barController[1],
            backController: backToTopController[1],
          )),
      KeepAliveWrapper(
          key: ValueKey<String>('message-$revision'),
          child: _ActiveTab(
            active: _activeTab,
            index: 2,
            child: _Notifaction(
              controller: barController[2],
              onBrowse: () => goToTab(0),
            ),
          )),
      KeepAliveWrapper(
          key: ValueKey<String>('user-$revision'),
          child: _UserAndSettings(
            controller: barController[3],
          ))
    ];
  }

  void _onAccountChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      page = _buildPages();
    });
    MessageReminder.reset();
    MessageReminder.refresh();
    MessageReminder.refreshChat();
    NotificationReminder.instance.load();
    forumState.refresh();
  }

  void _onDesktopTabRequested() {
    final int? target = Global.desktopTabRequest.value;
    if (target == null) return;
    Global.desktopTabRequest.value = null;
    if (mounted) goToTab(target);
  }

  ///切到第 [index] 个页签。底栏与消息页空态的「去逛逛」共用这一条路径。
  void goToTab(int index) {
    if (index == _currentPage) {
      return;
    }
    if (_currentPage == 2 && MessageReminder.likeOpened) {
      MessageReminder.clear(TiebaMessageKind.like);
    }
    if (index == 2) {
      MessageReminder.refresh();
      MessageReminder.refreshChat();
      NotificationReminder.instance.refresh();
    }
    setState(() {
      _currentPage = index;
      if (controller.hasClients) {
        controller.animateToPage(_currentPage,
            duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
      }
    });
    _activeTab.value = index;
  }

  /// 底部「消息」：数字优先；只有广播未读时才显示红点，且不带数字。
  Widget _messageBadge(Widget icon) => MessageBadge(child: icon);

  void initPlatformStateForStringUniLinks() {
    _appLinks = AppLinks();
    // app_links 的 uriLinkStream 在冷启动时也会补发让 App 启动的那条链接，
    // 再调用 getInitialLink 会把同一条链接处理两次（会连续打开两个贴子）。
    _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (!mounted || uri == null) return;
      _openDeepLink(uri);
    }, onError: (Object err) {
      // 深链解析失败不影响应用继续运行。
    });
  }

  void _openDeepLink(Uri uri) {
    final String raw = uri.toString();
    final DateTime now = DateTime.now();
    // 个别平台在启动 / 恢复时会重复发送同一条链接，短时间内只处理一次。
    if (raw == _lastDeepLink &&
        _lastDeepLinkAt != null &&
        now.difference(_lastDeepLinkAt!) < const Duration(seconds: 1)) {
      return;
    }
    final TiebaDeepLink? link = BrowserUrl.tiebaDeepLink(uri);
    if (link == null) {
      return;
    }
    _lastDeepLink = raw;
    _lastDeepLinkAt = now;
    // 从浏览器跳进来时这条链接往往还在剪贴板里，记下来避免恢复后再弹一次。
    AppUtil.noteDeepLinkOpened(raw);
    if (link.isThread) {
      //进入贴
      Navigator.pushNamed(context, PageRouter.threadPage,
          arguments: ThreadPageRouterData(kz: link.tid!, pid: link.pid));
    } else if (link.forumName != null) {
      //进入吧
      Navigator.pushNamed(context, PageRouter.forumHome,
          arguments: link.forumName);
    }
  }

  ({String title, String subtitle}) _desktopBarMeta(User user) {
    switch (_currentPage) {
      case 0:
        return (title: '首页', subtitle: '轻一点，逛贴吧');
      case 1:
        return (title: '动态', subtitle: '发现正在发生的讨论');
      case 2:
        final int chatUnread = MessageReminder.chatUnread.value;
        final String sub = chatUnread > 0 ? '$chatUnread 条未读私信' : '私信与互动消息';
        return (title: '消息', subtitle: sub);
      case 3:
        final String name = user.name.trim();
        return (
          title: '个人与设置',
          subtitle: name.isEmpty ? '账号与外观设置' : name,
        );
      default:
        return (title: 'Tiebanana', subtitle: '轻一点，逛贴吧');
    }
  }

  void _refreshActiveDesktopTab() {
    switch (_currentPage) {
      case 0:
        forumState.refresh();
      case 2:
        MessageReminder.refresh();
        MessageReminder.refreshChat();
        NotificationReminder.instance.refresh();
    }
    Global.desktopRefreshTick.value++;
  }

  @override
  Widget build(BuildContext context) {
    final User user = Provider.of<User>(context);
    final bool desktop = !AppBreakpoints.isCompact(context);
    if (!controller.hasClients && controller.initialPage != _currentPage) {
      controller.dispose();
      controller = PageController(initialPage: _currentPage);
    }
    if (_lastDesktop != null && _lastDesktop != desktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !controller.hasClients) return;
        if (controller.page != _currentPage.toDouble()) {
          controller.jumpToPage(_currentPage);
        }
      });
    }
    _lastDesktop = desktop;

    final Widget pageView = PageView(
      key: _pageViewKey,
      physics: const NeverScrollableScrollPhysics(),
      controller: controller,
      children: page,
    );

    Widget childpage;
    if (user.isLogin == false) {
      childpage = const Scaffold(
        body: LoginPage(),
      );
    } else if (desktop) {
      childpage = ListenableBuilder(
        listenable: MessageBadge.listenable,
        builder: (BuildContext context, _) {
          final ({String title, String subtitle}) liveMeta =
              _desktopBarMeta(user);
          return DesktopShellFrame(
            title: liveMeta.title,
            subtitle: liveMeta.subtitle,
            activeTab: _currentPage,
            onSelectTab: goToTab,
            onRefresh: _refreshActiveDesktopTab,
            child: pageView,
          );
        },
      );
    } else {
      childpage = Scaffold(
        resizeToAvoidBottomInset: false,
        // M3 NavigationBar：药丸指示器 + 常显标签，与概念图一致。
        // 旧的 BottomNavigationBar 在 4 个 item 下会退化成 shifting（只有选中项显示文字）。
        bottomNavigationBar: ListenableBuilder(
          listenable: MessageBadge.listenable,
          builder: (BuildContext context, Widget? child) => NavigationBar(
            selectedIndex: _currentPage,
            onDestinationSelected: goToTab,
            destinations: [
              const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: "首页"),
              const NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: "动态"),
              NavigationDestination(
                  icon: _messageBadge(const Icon(Icons.notifications_none)),
                  selectedIcon: _messageBadge(const Icon(Icons.notifications)),
                  label: "消息"),
              const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: "个人"),
            ],
          ),
        ),
        body: pageView,
      );
    }
    return ChangeNotifierProvider.value(
      value: forumState,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (!onWillPop() || !context.mounted) return;
          await AppExit.handleRootBack(context);
        },
        child: childpage,
      ),
    );
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    _activeTab.dispose();
    Global.desktopTabRequest.removeListener(_onDesktopTabRequested);
    AccountStore.changes.removeListener(_onAccountChanged);
    forumState.dispose();
    controller.dispose();
    _sub?.cancel();
    super.dispose();
  }
}

//Home界面
class _Home extends StatefulWidget {
  final FloatingSearchBarController controller;
  const _Home({required this.controller});

  @override
  __HomeState createState() => __HomeState();
}

class __HomeState extends State<_Home> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    LifeTimeCallback().onHomeFormPageCreate(context);
    // decoration: const BoxDecoration(color: Color(0xFFF2F2F5)),
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SearchBar(
              maxHeight: constraints.maxHeight,
              barController: widget.controller,
            ),
            Expanded(
                child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: (() => widget.controller.close()),
              child: const TagPan(),
            )),
          ],
        );
      },
    );
  }
}

//动态界面（推荐贴）
class _Recommand extends StatefulWidget {
  final FloatingSearchBarController controller;
  final BackToTopController backController;
  const _Recommand({required this.controller, required this.backController});

  @override
  __RecommandState createState() => __RecommandState();
}

class __RecommandState extends State<_Recommand> {
  @override
  Widget build(BuildContext context) {
    return RecommendPan(
      controller: widget.controller,
      backController: widget.backController,
    );
  }
}

//消息回复和@页
class _Notifaction extends StatefulWidget {
  final FloatingSearchBarController controller;

  /// 空态「去逛逛」：切到首页页签。
  final VoidCallback? onBrowse;
  const _Notifaction({required this.controller, this.onBrowse});

  @override
  __NotifactionState createState() => __NotifactionState();
}

class __NotifactionState extends State<_Notifaction> {
  @override
  Widget build(BuildContext context) {
    return MessagePan(
      controller: widget.controller,
      onBrowse: widget.onBrowse,
    );
  }
}

//个人界面与软件设置
class _UserAndSettings extends StatefulWidget {
  final FloatingSearchBarController controller;
  const _UserAndSettings({required this.controller});

  @override
  __UserAndSettingsState createState() => __UserAndSettingsState();
}

class __UserAndSettingsState extends State<_UserAndSettings> {
  @override
  Widget build(BuildContext context) {
    return UserPage(
      controller: widget.controller,
    );
  }
}

/// 只让当前页签保持活跃：离屏页签的 TickerMode 关闭，消息页据此暂停轮询。
class _ActiveTab extends StatelessWidget {
  const _ActiveTab({
    required this.active,
    required this.index,
    required this.child,
  });

  final ValueListenable<int> active;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: active,
      child: child,
      builder: (BuildContext context, int value, Widget? child) {
        return TickerMode(enabled: value == index, child: child!);
      },
    );
  }
}
