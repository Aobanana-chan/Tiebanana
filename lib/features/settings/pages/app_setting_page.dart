import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/features/update/data/version.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/cache/image_cache_manager.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/settings/pages/image_cache_page.dart';
import 'package:tiebanana/features/diagnostics/pages/diagnostics_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/theme/tiebanana_typography.dart';
import 'package:tiebanana/features/account/widgets/account_switch_sheet.dart';
import 'package:tiebanana/shared/widgets/alert_dialog.dart';
import 'package:tiebanana/shared/widgets/setting_group.dart';

/// 应用设置页。
///
/// 对应概念图 `design/mockups/app_setting.html`（方向 A）：四张圆角卡
/// （账号 / 显示与内容 / 通用开关 / 其他），每行是
/// 「图标 + 主副标题 + 右侧控件（文字值 / 开关 / 滑块 / 箭头）」。
///
/// 设置项按分组写入 `defaultAPPSetting`，自动检查更新、自动签到和长期缓存收藏贴
/// 各自使用独立的开关字段。存储 key 与 `defaultAPPSetting` 强绑定。
///
/// 以下两项待补充 UI：
/// - `homeForumMaxCount`（首页「我关注的吧」缩略显示数量，3–30）：数据层已就绪，
///   等设计给出控件形态（建议滑块 + 实时预览）再补 UI；
/// - `darkModel`（跟随系统 / 深色 / 浅色）：`main.dart` 已读取该设置，界面入口待补充。
class AppSettingPage extends StatefulWidget {
  const AppSettingPage({super.key});

  @override
  State<AppSettingPage> createState() => _AppSettingPageState();
}

class _AppSettingPageState extends State<AppSettingPage> {
  /// 字号滑块的区间。
  ///
  /// 字号滑块使用 `TiebananaTypography` 的有效倍率区间；
  /// 区间外的历史取值会夹到端点显示。
  static final double _minFontSize = TiebananaTypography.minUserFontSize;
  static final double _maxFontSize = TiebananaTypography.maxUserFontSize;

  /// 拖动中的字号。松手才落库：`Global.saveProfile()` 每次都会写一遍
  /// SharedPreferences，跟着每帧调它会把拖动拖卡。
  late double _fontSize;
  int? _imageCacheBytes;

  @override
  void initState() {
    super.initState();
    _refreshImageCacheSize();
    _fontSize = Provider.of<APPSettingProvider>(context, listen: false)
        .fontSize
        .roundToDouble()
        .clamp(_minFontSize, _maxFontSize);
  }

  Future<void> _refreshImageCacheSize() async {
    try {
      final bytes = await ImageCacheManager.shared.sizeBytes();
      if (mounted) setState(() => _imageCacheBytes = bytes);
    } catch (_) {
      // 临时目录不可读时仍可进入缓存页面重试。
    }
  }

  Future<void> _openImageCache() async {
    await Navigator.of(context).push(appPageRoute<void>(
      builder: (_) => const ImageCachePage(),
    ));
    if (mounted) await _refreshImageCacheSize();
  }

  /// 开关 / 单选都是即时的：改完立刻落盘并重建，没有「保存」按钮。
  void _commit(VoidCallback change) {
    setState(change);
    Global.saveProfile();
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Scaffold(
      appBar: AppBar(
        // 概念图里设置页的顶栏与页面同色（不是 bar 的那层灰）。
        backgroundColor: tokens.bg,
        foregroundColor: tokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text('应用设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: TiebananaMetrics.gapXl),
        children: <Widget>[
          _accountGroup(context),
          _displayGroup(context),
          _generalGroup(context),
          _otherGroup(context),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- 账号

  /// 账号组。未登录时这一组只剩「登录」一行（概念图规格卡里点名的状态）。
  Widget _accountGroup(BuildContext context) {
    final User user = context.watch<User>();
    if (!user.isLogin) {
      return SettingGroup(
        children: <Widget>[
          SettingRow(
            icon: Icons.login_rounded,
            title: '登录',
            subtitle: '登录后同步收藏、浏览历史与消息',
            showChevron: true,
            onTap: () => Navigator.pushNamed(context, PageRouter.login),
          ),
        ],
      );
    }
    return SettingGroup(
      children: <Widget>[
        SettingRow(
          icon: Icons.person_outline_rounded,
          title: '个人资料',
          showChevron: true,
          onTap: _openMyProfile,
        ),
        SettingRow(
          icon: Icons.change_circle_outlined,
          title: '切换账号',
          value: user.name.isEmpty ? null : user.name,
          showChevron: true,
          onTap: () => showAccountSwitchSheet(context),
        ),
        SettingRow(
          icon: Icons.logout_rounded,
          title: '退出登陆',
          danger: true,
          onTap: _logout,
        ),
      ],
    );
  }

  /// 进入本人的资料编辑页，身份由页面从当前账号读取。
  void _openMyProfile() {
    final String uid = Global.profile.getString('uid') ?? '';
    if (uid.isEmpty) {
      Fluttertoast.showToast(msg: '还没读到当前账号，稍后再试');
      return;
    }
    Navigator.pushNamed(context, PageRouter.profileEdit);
  }

  Future<void> _logout() async {
    final bool? sure = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) =>
          const TiebaAlterDialog(title: '确认退出当前账号?'),
    );
    if (sure != true || !mounted) {
      return;
    }
    await AccountStore.logoutCurrent();
    if (!mounted) {
      return;
    }
    // User 是 ChangeNotifier：刷新一次，上面那一组会切回「登录」或下一个账号。
    Provider.of<User>(context, listen: false).refreshAccount(force: true);
  }

  // -------------------------------------------------------- 显示与内容

  Widget _displayGroup(BuildContext context) {
    final APPSetting setting = Global.setting;
    final int historyCount =
        context.watch<APPSettingProvider>().homeHistoryMaxCount;
    final String tail = setting.postTail ?? '';
    return SettingGroup(
      children: <Widget>[
        SettingRow(
          icon: Icons.brush_outlined,
          title: '主题切换',
          value: themeName[setting.theme] ?? setting.theme,
          showChevron: true,
          onTap: () => Navigator.pushNamed(context, PageRouter.themeChange),
        ),
        SettingRow(
          icon: Icons.tag_outlined,
          title: '小尾巴',
          subtitle: tail.isEmpty ? '你还没有设置小尾巴' : tail,
          showChevron: true,
          onTap: () => _editPostTail(context),
        ),
        SettingRow(
          icon: Icons.image_search_outlined,
          title: '图片浏览模式',
          value: setting.pictureLoadMode,
          showChevron: true,
          onTap: () => _pickPictureMode(context),
        ),
        SettingRow(
          icon: Icons.text_fields_rounded,
          title: '字体大小',
          // 拖动时数值跟着走，松手才落库（真正的整屏预览由主题层放大字阶给出）。
          value: _fontSize.toStringAsFixed(0),
          trailing: SizedBox(width: 104, child: _fontSlider(context)),
        ),
        SettingRow(
          icon: Icons.history_rounded,
          title: '首页历史记录数量',
          value: '$historyCount 条',
          showChevron: true,
          onTap: () => _pickHomeHistoryCount(context),
        ),
      ],
    );
  }

  Widget _fontSlider(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        activeTrackColor: tokens.primary,
        inactiveTrackColor: tokens.surfaceAlt,
        thumbColor: tokens.primary,
        // 关掉 M3 的大光晕：行高不该由它决定。
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      child: Slider(
        min: _minFontSize,
        max: _maxFontSize,
        divisions: (_maxFontSize - _minFontSize).toInt(),
        value: _fontSize,
        onChanged: (double value) =>
            setState(() => _fontSize = value.roundToDouble()),
        onChangeEnd: (double value) =>
            Provider.of<APPSettingProvider>(context, listen: false).fontSize =
                value.roundToDouble(),
      ),
    );
  }

  Future<void> _pickHomeHistoryCount(BuildContext context) async {
    final APPSettingProvider settings = context.read<APPSettingProvider>();
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

  /// 小尾巴：写内容 + 开关是否随发帖带上，都在这一张面板里。
  Future<void> _editPostTail(BuildContext context) {
    final APPSetting setting = Global.setting;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TiebananaTokens.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TiebananaMetrics.radiusXl),
        ),
      ),
      builder: (BuildContext sheetContext) => _PostTailSheet(
        initialText: setting.postTail ?? '',
        initialEnabled: setting.usePostTail ?? false,
        onSaved: (String text, bool enabled) => _commit(() {
          setting.postTail = text.isEmpty ? null : text;
          setting.usePostTail = enabled && text.isNotEmpty;
        }),
      ),
    );
  }

  /// 图片浏览模式：四个取值对应 `pictureLoadSetting` 的 0–3。
  Future<void> _pickPictureMode(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: TiebananaTokens.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TiebananaMetrics.radiusXl),
        ),
      ),
      builder: (BuildContext sheetContext) => _PictureModeSheet(
        value: Global.setting.pictureLoadSetting ?? 0,
        onPicked: (int mode) =>
            _commit(() => Global.setting.pictureLoadSetting = mode),
      ),
    );
  }

  // ------------------------------------------------------------ 通用

  Widget _generalGroup(BuildContext context) {
    final APPSetting setting = Global.setting;
    return SettingGroup(
      children: <Widget>[
        SettingRow(
          icon: Icons.web_asset_rounded,
          title: '使用内置浏览器',
          trailing: SettingSwitch(
            value: setting.useBuildinBrowser ?? true,
            onChanged: (bool value) =>
                _commit(() => setting.useBuildinBrowser = value),
          ),
        ),
        SettingRow(
          icon: Icons.warning_amber_rounded,
          title: '发帖 / 回帖风险提醒',
          subtitle: '打开编辑界面时提醒第三方客户端的封号风险',
          trailing: SettingSwitch(
            value: setting.showPostingRiskWarning,
            onChanged: (bool value) =>
                _commit(() => setting.showPostingRiskWarning = value),
          ),
        ),
        SettingRow(
          icon: Icons.system_update_alt_rounded,
          title: '自动检查更新',
          // 手动检查入口位于「关于」页。
          trailing: SettingSwitch(
            value: setting.checkUpdateAutomaticlly ?? true,
            onChanged: (bool value) =>
                _commit(() => setting.checkUpdateAutomaticlly = value),
          ),
        ),
        SettingRow(
          icon: Icons.signpost_outlined,
          title: '自动签到',
          subtitle: '打开 APP 后自动开始签到',
          trailing: SettingSwitch(
            value: setting.signAllsinceOpen ?? true,
            onChanged: (bool value) =>
                _commit(() => setting.signAllsinceOpen = value),
          ),
        ),
        SettingRow(
          icon: Icons.cached_outlined,
          title: '长期缓存收藏贴',
          subtitle: '收藏贴长期保留到取消收藏',
          trailing: SettingSwitch(
            value: setting.markedCache ?? true,
            onChanged: (bool value) =>
                _commit(() => setting.markedCache = value),
          ),
        ),
        SettingRow(
          icon: Icons.photo_library_outlined,
          title: '图片缓存',
          value: _imageCacheBytes == null
              ? '点击查看'
              : formatImageCacheSize(_imageCacheBytes!),
          showChevron: true,
          onTap: _openImageCache,
        ),
      ],
    );
  }

  // ------------------------------------------------------------ 其他

  Widget _otherGroup(BuildContext context) {
    return SettingGroup(
      children: <Widget>[
        SettingRow(
          icon: Icons.description_outlined,
          title: '日志与诊断',
          subtitle: '导出本地日志，帮助定位问题',
          showChevron: true,
          onTap: () => Navigator.of(context).push(appPageRoute<void>(
            settings: const RouteSettings(name: '/diagnostics'),
            builder: (_) => const DiagnosticsPage(),
          )),
        ),
        SettingRow(
          icon: Icons.headset_mic_outlined,
          title: '服务中心',
          showChevron: true,
          onTap: () => Navigator.pushNamed(context, PageRouter.serviceCenter),
        ),
        SettingRow(
          icon: Icons.info_outline_rounded,
          title: '关于',
          value: Version.displayVersion,
          showChevron: true,
          onTap: () => Navigator.pushNamed(context, PageRouter.about),
        ),
      ],
    );
  }
}

/// 底部面板的骨架见 `lib/shared/widgets/setting_group.dart` 的 [SettingSheetShell]。
/// 小尾巴编辑面板。文本与「发帖时带上小尾巴」一起改，保存才算数。
class _PostTailSheet extends StatefulWidget {
  const _PostTailSheet({
    required this.initialText,
    required this.initialEnabled,
    required this.onSaved,
  });

  final String initialText;
  final bool initialEnabled;
  final void Function(String text, bool enabled) onSaved;

  @override
  State<_PostTailSheet> createState() => _PostTailSheetState();
}

class _PostTailSheetState extends State<_PostTailSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);
  late bool _enabled = widget.initialEnabled;

  @override
  void initState() {
    super.initState();
    // 空尾巴时把开关置灰，所以每敲一个字都要重建一次。
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasText = _controller.text.trim().isNotEmpty;
    return Padding(
      // 键盘弹起来时把面板顶上去。
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SettingSheetShell(
        title: '我的小尾巴',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              autofocus: true,
              style: textTheme.bodyLarge?.copyWith(color: tokens.textPrimary),
              decoration: InputDecoration(
                hintText: '小尾巴',
                hintStyle:
                    textTheme.bodyLarge?.copyWith(color: tokens.textTertiary),
                filled: true,
                fillColor: tokens.fill,
                contentPadding: const EdgeInsets.all(TiebananaMetrics.gapMd),
                border: OutlineInputBorder(
                  borderRadius: TiebananaMetrics.brCtl,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: TiebananaMetrics.gapMd),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '发帖时带上小尾巴',
                    style: textTheme.bodyLarge?.copyWith(
                      color: hasText ? tokens.textPrimary : tokens.textTertiary,
                    ),
                  ),
                ),
                SettingSwitch(
                  value: _enabled && hasText,
                  onChanged: hasText
                      ? (bool value) => setState(() => _enabled = value)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: TiebananaMetrics.gapLg),
            Material(
              color: tokens.accentFill,
              borderRadius: TiebananaMetrics.brCtl,
              child: InkWell(
                borderRadius: TiebananaMetrics.brCtl,
                onTap: () {
                  widget.onSaved(
                    _controller.text.trim(),
                    _enabled && hasText,
                  );
                  Navigator.pop(context);
                },
                child: SizedBox(
                  height: 46,
                  child: Center(
                    child: Text(
                      '保存',
                      style: textTheme.labelLarge
                          ?.copyWith(color: tokens.accentOn),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 图片浏览模式单选面板。
class _PictureModeSheet extends StatelessWidget {
  const _PictureModeSheet({required this.value, required this.onPicked});

  final int value;
  final ValueChanged<int> onPicked;

  /// 顺序与 `pictureLoadSetting` 的 0–3 一一对应（见 `defaultAPPSetting`）。
  static const List<String> modes = <String>[
    '智能省流量',
    '智能无图',
    '始终高质量',
    '始终无图',
  ];

  @override
  Widget build(BuildContext context) {
    return SettingSheetShell(
      title: '图片浏览模式',
      child: RadioGroup<int>(
        groupValue: value,
        onChanged: (int? mode) {
          if (mode == null) {
            return;
          }
          onPicked(mode);
          Navigator.pop(context);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < modes.length; i++)
              RadioListTile<int>(value: i, title: Text(modes[i])),
          ],
        ),
      ),
    );
  }
}
