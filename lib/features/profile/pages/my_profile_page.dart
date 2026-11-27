import 'dart:async';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/core/cache/image_cache_manager.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/features/account/widgets/account_switch_sheet.dart';
import 'package:tiebanana/features/diagnostics/pages/diagnostics_page.dart';
import 'package:tiebanana/features/history/models/view_history_page_model.dart';
import 'package:tiebanana/features/profile/state/profile_events.dart';
import 'package:tiebanana/features/profile/widgets/user_card.dart';
import 'package:tiebanana/features/search/widgets/search_bar.dart';
import 'package:tiebanana/features/settings/pages/image_cache_page.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/settings/widgets/setting_panel.dart';
import 'package:tiebanana/features/update/data/version.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/layout/page_wrap.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/theme/tiebanana_typography.dart';
import 'package:tiebanana/shared/widgets/adaptive_panel.dart';
import 'package:tiebanana/shared/widgets/alert_dialog.dart';
import 'package:tiebanana/shared/widgets/app_toast.dart';
import 'package:tiebanana/shared/widgets/desktop_panel.dart';
import 'package:tiebanana/shared/widgets/floating_search_app_bar.dart';
import 'package:tiebanana/shared/widgets/setting_group.dart';

///用户信息和设置界面
class UserPage extends StatefulWidget {
  final FloatingSearchBarController controller;
  const UserPage({super.key, required this.controller});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  /// 只拉个人资料接口（`c/u/user/profile`，cmd 303012）。
  ///
  /// 它同时带 id / 昵称 / 头像 / 签名与四项计数（关注 / 粉丝 / 关注的吧 / 帖子），
  /// 而 `getuserinfo`（`getMyInfo`）只有身份、**没有这四项计数**，
  /// uid 直接使用登录时写入的本地缓存。
  late Future<TiebaUserProfile> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _loadProfile();
    profileEvents.addListener(_onProfileSaved);
    Global.desktopRefreshTick.addListener(_onDesktopRefresh);
  }

  void _onDesktopRefresh() {
    if (!mounted) return;
    setState(() {
      _profile = _loadProfile();
    });
  }

  void _onProfileSaved() {
    if (profileEvents.uid == Global.profile.getString('uid')) {
      final Future<TiebaUserProfile> profile = _loadProfile();
      setState(() {
        _profile = profile;
      });
    }
  }

  @override
  void dispose() {
    Global.desktopRefreshTick.removeListener(_onDesktopRefresh);
    profileEvents.removeListener(_onProfileSaved);
    super.dispose();
  }

  Future<TiebaUserProfile> _loadProfile() async {
    final String uid = Global.profile.getString("uid") ?? "";
    if (uid.isEmpty) {
      throw Exception("缺少本地 uid");
    }
    return Global.tiebaAPI.getUserInfo(uid: uid);
  }

  /// 昵称：优先昵称（name_show），为空时退回用户名（name）。
  String _displayName(TiebaUserProfile user) => user.name;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final bool desktop = width >= AppBreakpoints.compactMax;
        return FutureBuilder<TiebaUserProfile>(
          future: _profile,
          builder:
              (BuildContext context, AsyncSnapshot<TiebaUserProfile> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return const Center(
                  child: Text("初始化中..."),
                );
              case ConnectionState.active:
                return const Center(
                  child: Text("加载中..."),
                );
              default:
                final TiebaUserProfile? user = snapshot.data;
                if (user != null) {
                  SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                    if (!context.mounted) return;
                    Provider.of<User>(context, listen: false).name =
                        _displayName(user);
                  });
                  if (desktop) {
                    return _DesktopProfileWorkbench(
                      user: user,
                      displayName: _displayName(user),
                      width: width,
                    );
                  }
                  return Column(
                    children: [
                      SearchBar(
                        maxHeight: constraints.maxHeight,
                        barController: widget.controller,
                      ),
                      Expanded(
                          child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: (() => widget.controller.close()),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    UserCard(
                                      concernNum: user.concernNum,
                                      fansNum: user.fansNum,
                                      likeForumNum: user.likeForumNum,
                                      // 帖子 = 主题帖数（thread_num）
                                      postNum: user.postNum,
                                      portraitUrl: profileEvents.avatarUrl(
                                          user.uid, user.portraitUrl),
                                      id: user.uid,
                                      name: _displayName(user),
                                      intro: user.intro,
                                    ),
                                    const SettingPanel(),
                                    // 与概念图一致：最后一组与底栏之间留一点呼吸。
                                    const SizedBox(
                                        height: TiebananaMetrics.gapMd),
                                  ],
                                ),
                              )))
                    ],
                  );
                } else if (snapshot.hasError) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _profile = _loadProfile();
                      });
                    },
                    child: const Center(
                      child: Text("发生了错误...点击重试"),
                    ),
                  );
                }
            }
            return Container();
          },
        );
      },
    );
  }
}

enum _ProfileSection { store, history, theme, general, storage }

class _DesktopProfileWorkbench extends StatefulWidget {
  const _DesktopProfileWorkbench({
    required this.user,
    required this.displayName,
    required this.width,
  });

  final TiebaUserProfile user;
  final String displayName;
  final double width;

  @override
  State<_DesktopProfileWorkbench> createState() =>
      _DesktopProfileWorkbenchState();
}

class _DesktopProfileWorkbenchState extends State<_DesktopProfileWorkbench> {
  _ProfileSection _section = _ProfileSection.theme;
  late double _fontSize;

  int? _imageCacheBytes;
  int? _logBytes;
  List<TiebaStoredThread> _stored = <TiebaStoredThread>[];
  bool _loadingStore = false;
  bool _storeLoaded = false;
  List<ViewHistoryPageModel> _history = <ViewHistoryPageModel>[];
  bool _loadingHistory = false;
  bool _historyLoaded = false;

  static const List<String> _seedKeys = <String>[
    'blue',
    'cyan',
    'teal',
    'green',
    'yellow',
    'pink',
    'white',
  ];

  static const List<String> _pictureModes = <String>[
    '智能省流量',
    '智能无图',
    '始终高质量',
    '始终无图',
  ];

  @override
  void initState() {
    super.initState();
    _fontSize = Provider.of<APPSettingProvider>(context, listen: false)
        .fontSize
        .roundToDouble()
        .clamp(12.0, 20.0);
    unawaited(_loadCounts());
  }

  Future<void> _loadCounts() async {
    unawaited(_loadHistory());
    unawaited(_loadStore());
    try {
      final int bytes = await ImageCacheManager.shared.sizeBytes();
      if (mounted) setState(() => _imageCacheBytes = bytes);
    } catch (_) {}
    try {
      final int logBytes = await AppLog.shared.sizeBytes();
      if (mounted) setState(() => _logBytes = logBytes);
    } catch (_) {}
  }

  Future<void> _loadStore() async {
    if (_loadingStore) return;
    _loadingStore = true;
    try {
      final String uid = widget.user.uid;
      List<TiebaStoredThread> items = <TiebaStoredThread>[];
      try {
        final ThreadStorePage remote =
            await Global.tiebaAPI.getThreadStore(0, uid, rn: 12);
        final List<TiebaStoredThread> local =
            await Global.threadCache.storedThreads(uid);
        final Set<String> ids = remote.threads.map((e) => e.id).toSet();
        items = <TiebaStoredThread>[
          ...remote.threads,
          ...local.where((e) => !ids.contains(e.id)),
        ];
      } catch (_) {
        items = await Global.threadCache.storedThreads(uid);
      }
      if (!mounted) return;
      setState(() {
        _stored = items;
        _storeLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _storeLoaded = true);
    } finally {
      _loadingStore = false;
    }
  }

  Future<void> _loadHistory() async {
    if (_loadingHistory) return;
    _loadingHistory = true;
    try {
      final List<ViewHistoryPageModel> items = Global.daoapi
          .getHistoryList(offset: 0, limit: 15)
          .map(ViewHistoryPageModel.fromViewHistoryDatabase)
          .toList();
      if (!mounted) return;
      setState(() {
        _history = items;
        _historyLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _historyLoaded = true);
    } finally {
      _loadingHistory = false;
    }
  }

  void _commitSetting(VoidCallback fn) {
    setState(fn);
    Global.saveProfile();
  }

  String _fontLabel(double size) {
    if (size <= 13) return '紧凑';
    if (size <= 16) return '标准';
    if (size <= 18) return '偏大';
    return '特大';
  }

  Future<void> _logout(BuildContext context) async {
    final User user = Provider.of<User>(context, listen: false);
    final bool? sure = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) =>
          const TiebaAlterDialog(title: '确认退出当前账号?'),
    );
    if (sure != true || !mounted) return;
    await AccountStore.logoutCurrent();
    user.refreshAccount(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool twoCol = widget.width >= AppBreakpoints.mediumMax;
    final TiebaUserProfile user = widget.user;

    return SingleChildScrollView(
      child: PageWrap(
        maxWidth: AppBreakpoints.pageMaxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const DesktopPageHeader(
              title: '我的空间',
              subtitle: '个人资料卡顶置通栏，左侧固定导航，右侧展开详情',
            ),
            UserCard(
              concernNum: user.concernNum,
              fansNum: user.fansNum,
              likeForumNum: user.likeForumNum,
              postNum: user.postNum,
              portraitUrl: profileEvents.avatarUrl(user.uid, user.portraitUrl),
              id: user.uid,
              name: widget.displayName,
              intro: user.intro,
              margin: const EdgeInsets.only(bottom: 14),
            ),
            if (twoCol)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 230,
                    child: _buildVerticalMenu(context, tokens),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActivePanel(context, tokens),
                  ),
                ],
              )
            else ...<Widget>[
              _buildHorizontalMenu(context, tokens),
              const SizedBox(height: 12),
              _buildActivePanel(context, tokens),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalMenu(BuildContext context, TiebananaTokens tokens) {
    final String? cacheText = _imageCacheBytes == null
        ? null
        : formatImageCacheSize(_imageCacheBytes!);
    final String? storeBadge =
        _storeLoaded && _stored.isNotEmpty ? '${_stored.length}' : null;
    final String? historyBadge =
        _historyLoaded && _history.isNotEmpty ? '${_history.length}' : null;

    return DesktopPanel(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _MenuRow(
            icon: Icons.bookmark_border_rounded,
            label: '我的收藏',
            badge: storeBadge,
            selected: _section == _ProfileSection.store,
            onTap: () => setState(() => _section = _ProfileSection.store),
          ),
          _MenuRow(
            icon: Icons.history_rounded,
            label: '浏览历史',
            badge: historyBadge,
            selected: _section == _ProfileSection.history,
            onTap: () => setState(() => _section = _ProfileSection.history),
          ),
          _MenuRow(
            icon: Icons.palette_outlined,
            label: '外观与主题',
            selected: _section == _ProfileSection.theme,
            showChevron: true,
            onTap: () => setState(() => _section = _ProfileSection.theme),
          ),
          _MenuRow(
            icon: Icons.tune_rounded,
            label: '阅读与通用',
            selected: _section == _ProfileSection.general,
            showChevron: true,
            onTap: () => setState(() => _section = _ProfileSection.general),
          ),
          _MenuRow(
            icon: Icons.storage_outlined,
            label: '存储与诊断',
            badge: cacheText,
            selected: _section == _ProfileSection.storage,
            onTap: () => setState(() => _section = _ProfileSection.storage),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Divider(height: 1, color: tokens.line),
          ),
          _MenuRow(
            icon: Icons.people_outline_rounded,
            label: '切换账号',
            selected: false,
            onTap: () => showAccountSwitchSheet(context),
          ),
          _MenuRow(
            icon: Icons.logout_rounded,
            label: '退出登录',
            selected: false,
            danger: true,
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalMenu(BuildContext context, TiebananaTokens tokens) {
    final List<({_ProfileSection sec, IconData icon, String label})> items =
        <({_ProfileSection sec, IconData icon, String label})>[
      (
        sec: _ProfileSection.store,
        icon: Icons.bookmark_border_rounded,
        label: '我的收藏'
      ),
      (
        sec: _ProfileSection.history,
        icon: Icons.history_rounded,
        label: '浏览历史'
      ),
      (
        sec: _ProfileSection.theme,
        icon: Icons.palette_outlined,
        label: '外观与主题'
      ),
      (sec: _ProfileSection.general, icon: Icons.tune_rounded, label: '阅读与通用'),
      (
        sec: _ProfileSection.storage,
        icon: Icons.storage_outlined,
        label: '存储与诊断'
      ),
    ];
    return DesktopPanel(
      padding: const EdgeInsets.all(6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (final item in items) ...<Widget>[
              _HorizontalMenuPill(
                icon: item.icon,
                label: item.label,
                selected: _section == item.sec,
                onTap: () => setState(() => _section = item.sec),
              ),
              const SizedBox(width: 4),
            ],
            _HorizontalMenuPill(
              icon: Icons.people_outline_rounded,
              label: '切换账号',
              selected: false,
              onTap: () => showAccountSwitchSheet(context),
            ),
            const SizedBox(width: 4),
            _HorizontalMenuPill(
              icon: Icons.logout_rounded,
              label: '退出登录',
              selected: false,
              danger: true,
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePanel(BuildContext context, TiebananaTokens tokens) {
    return DesktopPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: switch (_section) {
        _ProfileSection.theme => _buildThemePanel(context, tokens),
        _ProfileSection.general => _buildGeneralPanel(context, tokens),
        _ProfileSection.store => _buildStorePanel(context, tokens),
        _ProfileSection.history => _buildHistoryPanel(context, tokens),
        _ProfileSection.storage => _buildStoragePanel(context, tokens),
      },
    );
  }

  Widget _buildPanelHead(
    BuildContext context,
    TiebananaTokens tokens, {
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 2,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10.5,
                        color: tokens.textTertiary,
                      ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildThemePanel(BuildContext context, TiebananaTokens tokens) {
    final APPSettingProvider setting = context.watch<APPSettingProvider>();
    final double previewScale = TiebananaTypography.scaleOf(_fontSize);
    final TextTheme previewText = TiebananaTypography.textTheme(previewScale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildPanelHead(
          context,
          tokens,
          title: '外观与主题',
          subtitle: '选择会立即应用并落盘，不需要保存',
        ),
        // 浅色 / 深色 / 跟随系统分段开关
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: tokens.fill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _DarkModeChip(
                  icon: Icons.light_mode_outlined,
                  label: '浅色',
                  selected: setting.darkModel == 2,
                  onTap: () => setting.darkModel = 2,
                ),
                _DarkModeChip(
                  icon: Icons.dark_mode_outlined,
                  label: '深色',
                  selected: setting.darkModel == 1,
                  onTap: () => setting.darkModel = 1,
                ),
                _DarkModeChip(
                  icon: Icons.desktop_windows_outlined,
                  label: '跟随系统',
                  selected: setting.darkModel == 0,
                  onTap: () => setting.darkModel = 0,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 单行 7 列满宽主题色板
        Row(
          children: <Widget>[
            for (int i = 0; i < _seedKeys.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 7),
              Expanded(
                child: _SeedChip(
                  seedKey: _seedKeys[i],
                  selected: setting.theme == _seedKeys[i],
                  onTap: () => setting.theme = _seedKeys[i],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        // 12–20 实时字号滑块
        Row(
          children: <Widget>[
            Text(
              'A',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10.5,
                    color: tokens.textTertiary,
                  ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: tokens.primary,
                  inactiveTrackColor: tokens.surfaceAlt,
                  thumbColor: tokens.primary,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  min: 12,
                  max: 20,
                  divisions: 8,
                  value: _fontSize.clamp(12.0, 20.0),
                  onChanged: (double v) =>
                      setState(() => _fontSize = v.roundToDouble()),
                  onChangeEnd: (double v) =>
                      setting.fontSize = v.roundToDouble(),
                ),
              ),
            ),
            Text(
              'A',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.textSecondary,
                  ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 64,
              child: Text(
                '${_fontLabel(_fontSize)} · ${_fontSize.round()}',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: tokens.textTertiary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 实时预览卡
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.lineStrong),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    '实时预览',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: tokens.textTertiary,
                        ),
                  ),
                  Text(
                    '随主题与字号同步',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: tokens.textTertiary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: tokens.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: tokens.primaryContainer,
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 12,
                            color: tokens.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '示例作者',
                          style: previewText.labelMedium?.copyWith(
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tokens.fill,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '示例吧',
                            style: previewText.labelSmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '主题预览',
                          style: previewText.labelSmall?.copyWith(
                            color: tokens.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '正文字号与主题色板实时联动预览',
                      style: previewText.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '拖动上方字号滑块（12–20）或切换 7 套主题种子与明暗模式，此处排版与配色将即时更新。',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: previewText.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tokens.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '主题预览',
                            style: previewText.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: tokens.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralPanel(BuildContext context, TiebananaTokens tokens) {
    final APPSetting setting = Global.setting;
    final APPSettingProvider provider = context.watch<APPSettingProvider>();
    final int modeIndex =
        (setting.pictureLoadSetting ?? 0).clamp(0, _pictureModes.length - 1);
    final String tail = setting.postTail ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildPanelHead(
          context,
          tokens,
          title: '阅读与通用',
          subtitle: '全部来自 defaultAPPSetting',
        ),
        _SettingItemRow(
          title: '图片浏览模式',
          subtitle: '对应 pictureLoadSetting（0–3），当前：${_pictureModes[modeIndex]}',
          trailing: PopupMenuButton<int>(
            initialValue: modeIndex,
            onSelected: (int mode) =>
                _commitSetting(() => setting.pictureLoadSetting = mode),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              for (int i = 0; i < _pictureModes.length; i++)
                PopupMenuItem<int>(value: i, child: Text(_pictureModes[i])),
            ],
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: tokens.fill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    _pictureModes[modeIndex],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more_rounded,
                      size: 14, color: tokens.textSecondary),
                ],
              ),
            ),
          ),
          showTopBorder: false,
        ),
        _SettingItemRow(
          title: '小尾巴',
          subtitle: tail.isEmpty ? '未设置小尾巴 · 点击右侧编辑' : '$tail · 发帖时附带',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              OutlinedButton(
                onPressed: () => _editDesktopPostTail(context, setting),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.textSecondary,
                  side: BorderSide(color: tokens.line),
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                ),
                child: const Text('编辑'),
              ),
              const SizedBox(width: 8),
              SettingSwitch(
                value: (setting.usePostTail ?? false) && tail.isNotEmpty,
                onChanged: tail.isEmpty
                    ? null
                    : (bool v) => _commitSetting(() => setting.usePostTail = v),
              ),
            ],
          ),
        ),
        _SettingItemRow(
          title: '自动签到',
          subtitle: '打开应用后自动签到已关注的吧',
          trailing: SettingSwitch(
            value: setting.signAllsinceOpen ?? true,
            onChanged: (bool v) =>
                _commitSetting(() => setting.signAllsinceOpen = v),
          ),
        ),
        _SettingItemRow(
          title: '发帖 / 回帖风险提醒',
          subtitle: '打开编辑界面时提示第三方客户端风险',
          trailing: SettingSwitch(
            value: setting.showPostingRiskWarning,
            onChanged: (bool v) =>
                _commitSetting(() => setting.showPostingRiskWarning = v),
          ),
        ),
        _SettingItemRow(
          title: '首页历史记录数量',
          subtitle: '1–50 条，默认 15 条',
          trailing: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _pickDesktopHistoryCount(context, provider),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: tokens.fill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.line),
              ),
              alignment: Alignment.center,
              child: Text(
                '${provider.homeHistoryMaxCount} 条',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
          ),
        ),
        _SettingItemRow(
          title: '长期缓存收藏贴',
          subtitle: '收藏贴保留到取消收藏为止',
          trailing: SettingSwitch(
            value: setting.markedCache ?? true,
            onChanged: (bool v) =>
                _commitSetting(() => setting.markedCache = v),
          ),
        ),
        _SettingItemRow(
          title: '自动检查更新',
          subtitle: '手动检查入口位于「关于」',
          trailing: SettingSwitch(
            value: setting.checkUpdateAutomaticlly,
            onChanged: (bool v) =>
                _commitSetting(() => setting.checkUpdateAutomaticlly = v),
          ),
        ),
        _SettingItemRow(
          title: '使用内置浏览器',
          subtitle: '外部链接优先在应用内打开',
          trailing: SettingSwitch(
            value: setting.useBuildinBrowser ?? true,
            onChanged: (bool v) =>
                _commitSetting(() => setting.useBuildinBrowser = v),
          ),
        ),
      ],
    );
  }

  Future<void> _editDesktopPostTail(
    BuildContext context,
    APPSetting setting,
  ) async {
    final TextEditingController ctrl =
        TextEditingController(text: setting.postTail ?? '');
    bool enabled = setting.usePostTail ?? false;
    final bool? saved = await showAdaptivePanel<bool>(
      context: context,
      maxWidth: 420,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setLocal) {
            final TiebananaTokens tokens = TiebananaTokens.of(ctx);
            final bool hasText = ctrl.text.trim().isNotEmpty;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    '我的小尾巴',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    minLines: 3,
                    maxLines: 5,
                    autofocus: true,
                    onChanged: (_) => setLocal(() {}),
                    decoration: InputDecoration(
                      hintText: '输入发帖小尾巴',
                      filled: true,
                      fillColor: tokens.fill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      const Expanded(child: Text('发帖时带上小尾巴')),
                      SettingSwitch(
                        value: enabled && hasText,
                        onChanged: hasText
                            ? (bool v) => setLocal(() => enabled = v)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    final String text = ctrl.text.trim();
    ctrl.dispose();
    if (saved == true && mounted) {
      _commitSetting(() {
        setting.postTail = text.isEmpty ? null : text;
        setting.usePostTail = enabled && text.isNotEmpty;
      });
    }
  }

  Future<void> _pickDesktopHistoryCount(
    BuildContext context,
    APPSettingProvider settings,
  ) async {
    int count = settings.homeHistoryMaxCount;
    final int? picked = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter update) => AlertDialog(
          title: const Text('首页历史记录数量'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('$count 条'),
              Slider(
                min: APPSetting.minHomeHistoryMaxCount.toDouble(),
                max: APPSetting.maxHomeHistoryMaxCount.toDouble(),
                divisions: APPSetting.maxHomeHistoryMaxCount -
                    APPSetting.minHomeHistoryMaxCount,
                value: count.toDouble(),
                label: '$count 条',
                onChanged: (double value) =>
                    update(() => count = value.round()),
              ),
              const Text('可设置 1–50 条，默认 15 条'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, count),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      settings.homeHistoryMaxCount = picked;
    }
  }

  Widget _buildStorePanel(BuildContext context, TiebananaTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildPanelHead(
          context,
          tokens,
          title: '我的收藏',
          subtitle:
              _stored.isEmpty ? '收藏的帖子会出现在这里' : '已加载 ${_stored.length} 篇收藏',
          trailing: OutlinedButton(
            onPressed: () async {
              await Navigator.pushNamed(context, PageRouter.threadStore);
              if (mounted) unawaited(_loadStore());
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.textSecondary,
              side: BorderSide(color: tokens.line),
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            child: const Text('打开完整列表'),
          ),
        ),
        if (!_storeLoaded)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_stored.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                '暂无收藏帖子',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: tokens.textTertiary),
              ),
            ),
          )
        else
          for (int i = 0; i < _stored.length; i++)
            _DesktopStoreItem(
              info: _stored[i],
              showTopBorder: i > 0,
              onOpen: () => Navigator.pushNamed(
                context,
                PageRouter.threadPage,
                arguments: ThreadPageRouterData(
                  kz: _stored[i].id,
                  pid: _stored[i].pid,
                ),
              ),
              onRemove: () async {
                final TiebaStoredThread item = _stored[i];
                try {
                  await Global.tiebaAPI.threadRemoveStore(item.id);
                  await Global.threadCache
                      .setStored(widget.user.uid, item.id, false);
                  if (!mounted) return;
                  setState(() => _stored.removeWhere((e) => e.id == item.id));
                  Fluttertoast.showToast(msg: '已取消收藏');
                } catch (_) {
                  Fluttertoast.showToast(msg: '取消收藏失败');
                }
              },
            ),
      ],
    );
  }

  Widget _buildHistoryPanel(BuildContext context, TiebananaTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildPanelHead(
          context,
          tokens,
          title: '浏览历史',
          subtitle: '包含首页中已隐藏的记录，可在此恢复或打开完整历史搜索',
          trailing: OutlinedButton(
            onPressed: () async {
              await Navigator.pushNamed(context, PageRouter.viewHistory);
              if (mounted) unawaited(_loadHistory());
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.textSecondary,
              side: BorderSide(color: tokens.line),
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            child: const Text('打开完整列表'),
          ),
        ),
        if (!_historyLoaded)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                '暂无浏览历史',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: tokens.textTertiary),
              ),
            ),
          )
        else
          for (int i = 0; i < _history.length; i++)
            _DesktopHistoryItem(
              info: _history[i],
              showTopBorder: i > 0,
              onOpen: () => Navigator.pushNamed(
                context,
                PageRouter.threadPage,
                arguments: ThreadPageRouterData(kz: _history[i].tid, pid: null),
              ),
              onUnhide: _history[i].hidden
                  ? () {
                      final ViewHistoryPageModel item = _history[i];
                      Global.daoapi.setViewHistoryHidden(item.id, false);
                      setState(() => item.hidden = false);
                    }
                  : null,
              onDelete: () {
                final ViewHistoryPageModel item = _history[i];
                Global.daoapi.deleteViewHistory(item.id);
                setState(() => _history.removeWhere((e) => e.id == item.id));
              },
            ),
      ],
    );
  }

  Widget _buildStoragePanel(BuildContext context, TiebananaTokens tokens) {
    final String imageCacheText = _imageCacheBytes == null
        ? '读取中…'
        : formatImageCacheSize(_imageCacheBytes!);
    final String logText = _logBytes == null
        ? '读取中…'
        : '${(_logBytes! / 1024).toStringAsFixed(1)} KB';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildPanelHead(
          context,
          tokens,
          title: '存储与诊断',
          subtitle: '缓存清理、日志导出与版本信息',
        ),
        _SettingItemRow(
          title: '图片缓存',
          subtitle: '当前占用：$imageCacheText',
          showTopBorder: false,
          trailing: OutlinedButton(
            onPressed: () async {
              await Navigator.of(context).push(appPageRoute<void>(
                builder: (_) => const ImageCachePage(),
              ));
              if (mounted) {
                try {
                  final int bytes = await ImageCacheManager.shared.sizeBytes();
                  if (mounted) setState(() => _imageCacheBytes = bytes);
                } catch (_) {}
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.textSecondary,
              side: BorderSide(color: tokens.line),
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            child: const Text('管理缓存'),
          ),
        ),
        _SettingItemRow(
          title: '日志与诊断',
          subtitle: '导出本地日志，帮助定位问题（占用 $logText）',
          trailing: OutlinedButton(
            onPressed: () => Navigator.of(context).push(appPageRoute<void>(
              settings: const RouteSettings(name: '/diagnostics'),
              builder: (_) => const DiagnosticsPage(),
            )),
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.textSecondary,
              side: BorderSide(color: tokens.line),
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            child: const Text('打开'),
          ),
        ),
        _SettingItemRow(
          title: '服务中心',
          subtitle: '官方帮助与反馈入口',
          trailing: OutlinedButton(
            onPressed: () =>
                Navigator.pushNamed(context, PageRouter.serviceCenter),
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.textSecondary,
              side: BorderSide(color: tokens.line),
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            child: const Text('打开'),
          ),
        ),
        _SettingItemRow(
          title: '关于 Tiebanana',
          subtitle: '版本与开源许可 · ${Version.displayVersion}',
          trailing: OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, PageRouter.about),
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.textSecondary,
              side: BorderSide(color: tokens.line),
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            child: const Text('查看'),
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.showChevron = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final bool showChevron;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Color fg = danger
        ? tokens.danger
        : (selected ? tokens.onPrimaryContainer : tokens.textSecondary);
    return Material(
      color: selected ? tokens.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12.5,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: fg,
                        ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tokens.fill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
                        color: tokens.textSecondary,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  )
                else if (showChevron)
                  Icon(Icons.chevron_right_rounded, size: 15, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalMenuPill extends StatelessWidget {
  const _HorizontalMenuPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Color fg = danger
        ? tokens.danger
        : (selected ? tokens.onPrimaryContainer : tokens.textSecondary);
    return Material(
      color: selected ? tokens.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: fg,
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

class _DarkModeChip extends StatelessWidget {
  const _DarkModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Material(
      color: selected ? tokens.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      elevation: selected ? 1 : 0,
      shadowColor: tokens.shadow,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          height: 28,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? tokens.textPrimary : tokens.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? tokens.textPrimary
                            : tokens.textSecondary,
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

class _SeedChip extends StatelessWidget {
  const _SeedChip({
    required this.seedKey,
    required this.selected,
    required this.onTap,
  });

  final String seedKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TiebananaSeed seed = seedOf(seedKey);
    final String label = themeName[seedKey] ?? seedKey;
    return Material(
      color: selected ? tokens.primaryContainer : tokens.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? tokens.primary : tokens.line,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: seed.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? tokens.onPrimaryContainer
                            : tokens.textSecondary,
                      ),
                ),
              ),
              if (selected) ...<Widget>[
                const SizedBox(width: 3),
                Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: tokens.onPrimaryContainer,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingItemRow extends StatelessWidget {
  const _SettingItemRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.showTopBorder = true,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: showTopBorder
          ? BoxDecoration(border: Border(top: BorderSide(color: tokens.line)))
          : null,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10.5,
                        color: tokens.textTertiary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _DesktopStoreItem extends StatelessWidget {
  const _DesktopStoreItem({
    required this.info,
    required this.onOpen,
    required this.onRemove,
    this.showTopBorder = true,
  });

  final TiebaStoredThread info;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  final bool showTopBorder;

  String get _meta {
    final List<String> parts = <String>[];
    if (info.name.isNotEmpty) parts.add(info.name);
    final String msg = info.postNoMsg?.trim() ?? '';
    if (msg.isNotEmpty) parts.add(msg);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final String? image = info.getImage;
    final String meta = _meta;
    final int newCount = info.newCount;

    return Container(
      decoration: showTopBorder
          ? BoxDecoration(border: Border(top: BorderSide(color: tokens.line)))
          : null,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                hoverColor: tokens.primary.withValues(alpha: .04),
                onTap: onOpen,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              info.title.isEmpty ? '（无标题）' : info.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                    color: info.isDeleted
                                        ? tokens.textTertiary
                                        : tokens.textPrimary,
                                  ),
                            ),
                            if (meta.isNotEmpty ||
                                newCount > 0 ||
                                info.isDeleted) ...<Widget>[
                              const SizedBox(height: 5),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 4,
                                children: <Widget>[
                                  if (meta.isNotEmpty)
                                    Text(
                                      meta,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            fontSize: 11,
                                            color: tokens.textTertiary,
                                          ),
                                    ),
                                  if (newCount > 0)
                                    _DesktopItemPill(
                                      text: '$newCount 条更新',
                                      background: tokens.primaryContainer,
                                      foreground: tokens.onPrimaryContainer,
                                    ),
                                  if (info.isDeleted)
                                    _DesktopItemPill(
                                      text: '已删除',
                                      background:
                                          tokens.danger.withValues(alpha: .10),
                                      foreground: tokens.danger,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (image != null && image.isNotEmpty) ...<Widget>[
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ExtendedImage.network(
                            image,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                            cache: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _DesktopItemActionBtn(
            icon: Icons.star_border_rounded,
            tooltip: '取消收藏',
            color: tokens.danger,
            onTap: onRemove,
          ),
        ],
      ),
    );
  }
}

class _DesktopHistoryItem extends StatelessWidget {
  const _DesktopHistoryItem({
    required this.info,
    required this.onOpen,
    required this.onDelete,
    this.onUnhide,
    this.showTopBorder = true,
  });

  final ViewHistoryPageModel info;
  final VoidCallback onOpen;
  final VoidCallback? onUnhide;
  final VoidCallback onDelete;
  final bool showTopBorder;

  String get _meta {
    final String time = TiebaParser.getPostTime(dateTime: info.latestViewTime);
    if (info.forumName.isEmpty) return '浏览于 $time';
    return '${info.forumName}吧 · 浏览于 $time';
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      decoration: showTopBorder
          ? BoxDecoration(border: Border(top: BorderSide(color: tokens.line)))
          : null,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                hoverColor: tokens.primary.withValues(alpha: .04),
                onTap: onOpen,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        info.title.isEmpty ? '（无标题）' : info.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              color: tokens.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: <Widget>[
                          Text(
                            _meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontSize: 11,
                                  color: tokens.textTertiary,
                                ),
                          ),
                          if (info.hidden)
                            _DesktopItemPill(
                              text: '已隐藏',
                              background: tokens.fill,
                              foreground: tokens.textSecondary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (onUnhide != null) ...<Widget>[
            _DesktopItemActionBtn(
              icon: Icons.visibility_outlined,
              tooltip: '取消在首页隐藏',
              color: tokens.textSecondary,
              onTap: onUnhide!,
            ),
            const SizedBox(width: 4),
          ],
          _DesktopItemActionBtn(
            icon: Icons.delete_outline_rounded,
            tooltip: '删除记录',
            color: tokens.danger,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _DesktopItemPill extends StatelessWidget {
  const _DesktopItemPill({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: foreground,
              height: 1.1,
            ),
      ),
    );
  }
}

class _DesktopItemActionBtn extends StatelessWidget {
  const _DesktopItemActionBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: tokens.fill,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          hoverColor: color.withValues(alpha: .10),
          onTap: onTap,
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}
