import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/core/platform/platform_capabilities.dart';
import 'package:tiebanana/features/media/pages/image_picker_page.dart';
import 'package:tiebanana/features/profile/pages/avatar_crop_page.dart';
import 'package:tiebanana/features/profile/state/profile_events.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/layout/page_wrap.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/dashed_border.dart';
import 'package:tiebanana/shared/widgets/desktop_panel.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';
import 'package:tiebanana/shared/widgets/setting_group.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';

/// 方向 A：当前头像卡 → 基本资料表单 → 只读账号信息。
///
/// 宽屏（`>= 720dp`）下纳入 [DesktopShellFrame]，采用左「头像与实时预览」+
/// 右「关于我表单」双栏布局，并使用居中裁切弹窗替代全屏裁切页。
/// 保存调用当前账号的资料修改接口，失败时保留输入。
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key, this.avatarPicker});

  /// 可替换选图/裁切入口，生产默认走本机相册与正方形裁切页（桌面走裁切弹窗）。
  final Future<Uint8List?> Function(BuildContext context)? avatarPicker;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _intro = TextEditingController();
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final String _uid = Global.profile.getString('uid') ?? '';
  TiebaUserProfile? _profile;
  ({String name, String intro, String sex})? _baseline;
  String _sex = '0';
  bool _loading = true;
  bool _failed = false;
  bool _saving = false;
  bool _allowPop = false;
  bool _confirming = false;
  bool _nicknamePending = false;
  bool _saveUnconfirmed = false;
  bool _changingAvatar = false;
  bool _avatarUnconfirmed = false;
  bool _avatarHovered = false;
  double? _avatarProgress;
  Uint8List? _avatarPreview;
  int _profileRead = 0;
  double _layoutWidth = 0;

  bool get _busy => _saving || _changingAvatar;

  ({String name, String intro, String sex}) get _values =>
      (name: _name.text, intro: _intro.text, sex: _sex);
  bool get _dirty => _baseline != null && _values != _baseline;
  bool get _sameAccount => Global.profile.getString('uid') == _uid;

  @override
  void initState() {
    super.initState();
    _name.addListener(_changed);
    _intro.addListener(_changed);
    if (_uid.isNotEmpty) _load();
    profileEvents.addListener(_onProfileSaved);
  }

  void _onProfileSaved() {
    if (profileEvents.uid == _uid && _sameAccount && !_loading && !_busy) {
      unawaited(_refreshProfileStatus());
    }
  }

  Future<void> _refreshProfileStatus() async {
    final read = ++_profileRead;
    final baseline = _baseline;
    try {
      final profile = await Global.tiebaAPI.getUserInfo(uid: _uid);
      if (!mounted ||
          !_sameAccount ||
          profile.uid != _uid ||
          read != _profileRead ||
          _busy ||
          baseline != _baseline) {
        return;
      }
      setState(() {
        _profile = profile;
        _nicknamePending = profile.nicknameEditing;
        // 后台同步只更新状态，旧响应不覆盖表单输入和基线。
      });
    } catch (_) {
      // 写操作已完成，读取失败不改变提交结果。
    }
  }

  void _changed() => setState(() {});

  Future<void> _load() async {
    _profileRead++;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final TiebaUserProfile profile =
          await Global.tiebaAPI.getUserInfo(uid: _uid);
      if (!mounted) return;
      if (profile.uid != _uid) throw StateError('资料账号不匹配');
      _name.text = profile.nicknameEditing && profile.editingNickname.isNotEmpty
          ? profile.editingNickname
          : profile.name;
      _intro.text = profile.intro;
      setState(() {
        _sex = <String>['1', '2'].contains(profile.sex) ? profile.sex! : '0';
        _baseline = _values;
        _profile = profile;
        _avatarPreview = profileEvents.avatarPreview(_uid);
        _nicknamePending = profile.nicknameEditing;
        _saveUnconfirmed = false;
        _avatarUnconfirmed = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    profileEvents.removeListener(_onProfileSaved);
    _name.dispose();
    _intro.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<Uint8List?> _pickRawAvatarBytes() async {
    if (isDesktop) {
      final PlatformFile? picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const <String>[
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'bmp',
        ],
      );
      if (!mounted || picked?.path == null) return null;
      final File file = File(picked!.path!);
      if (!await file.exists()) throw StateError('无法读取这张照片');
      if (await file.length() > 20 * 1024 * 1024) {
        throw StateError('图片过大，请选择20MB以内的照片');
      }
      return file.readAsBytes();
    }
    final selection = await Navigator.push<List<dynamic>>(
      context,
      appPageRoute(
          builder: (_) => const ImagePickerRoute(singleSelection: true)),
    );
    if (!mounted || selection == null) return null;
    final assets = selection.first as Set<AssetEntity>;
    if (assets.isEmpty) return null;
    final file = await assets.single.file;
    if (file == null) throw StateError('无法读取这张照片');
    if (await file.length() > 20 * 1024 * 1024) {
      throw StateError('图片过大，请选择20MB以内的照片');
    }
    return file.readAsBytes();
  }

  Future<Uint8List?> _pickAvatar() async {
    final bool desktopLayout = _layoutWidth > 0
        ? AppBreakpoints.isDesktopWidth(_layoutWidth)
        : AppBreakpoints.isDesktop(context);
    final Uint8List? bytes = await _pickRawAvatarBytes();
    if (!mounted || bytes == null) return null;
    if (desktopLayout) {
      return showAvatarCropDialog(
        context,
        imageBytes: bytes,
        outputSize: 960,
        quality: 80,
        onRepick: _pickRawAvatarBytes,
      );
    }
    return Navigator.push<Uint8List>(
      context,
      appPageRoute(
        builder: (_) => AvatarCropPage(
          imageBytes: bytes,
          outputSize: 960,
          quality: 80,
        ),
      ),
    );
  }

  Future<void> _changeAvatar() async {
    if (_busy || _avatarUnconfirmed || _saveUnconfirmed || !_sameAccount) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _changingAvatar = true;
      _avatarProgress = null;
    });
    Directory? temporary;
    try {
      final bytes = await (widget.avatarPicker?.call(context) ?? _pickAvatar());
      if (!mounted || bytes == null) return;
      if (!_sameAccount) {
        _message('当前账号已切换，请重新打开资料编辑');
        return;
      }
      final root = await getTemporaryDirectory();
      temporary = await root.createTemp('avatar-');
      final file = await File('${temporary.path}/portrait.jpg')
          .writeAsBytes(bytes, flush: true);
      if (!mounted || !_sameAccount) return;
      setState(() => _avatarProgress = 0);
      bool trackingProgress = true;
      final upload = Global.tiebaAPI.updateAvatar(UploadFile(
        path: file.path,
        width: 960,
        height: 960,
        resourceId: '',
        onProgress: (sent, total) {
          if (mounted && trackingProgress && _changingAvatar && total > 0) {
            setState(() => _avatarProgress = (sent / total).clamp(0, 1));
          }
        },
      ));
      // 超时不等于取消请求，文件需保留到实际上传任务结束再清理。
      final owned = temporary;
      temporary = null;
      final result = await upload
          .whenComplete(() async {
            try {
              await owned.delete(recursive: true);
            } catch (_) {}
          })
          .timeout(const Duration(seconds: 60))
          .whenComplete(() {
            trackingProgress = false;
          });
      if (!mounted || !_sameAccount) return;
      setState(() {
        if (result.portraitUrl.isNotEmpty) {
          _profile!.portraitUrl = result.portraitUrl;
        }
        _avatarPreview = bytes;
        _changingAvatar = false;
      });
      _message(result.message);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sameAccount) profileEvents.avatarSaved(_uid, preview: bytes);
      });
      // 成功响应可能不带 URL，只刷新头像字段，保留尚未保存的表单内容。
      unawaited(_refreshAvatar());
    } on TimeoutException {
      if (mounted) {
        setState(() => _avatarUnconfirmed = true);
        _message('头像提交超时，结果待确认，请先重新读取资料，不要重复上传');
      }
    } catch (error) {
      if (mounted) {
        _message(error is NetAPIError
            ? error.errorMessage ?? '头像更换失败，请重试'
            : error is StateError
                ? error.message
                : '头像处理失败，请重试');
      }
    } finally {
      if (temporary != null) {
        try {
          await temporary.delete(recursive: true);
        } catch (_) {}
      }
      if (mounted) setState(() => _changingAvatar = false);
    }
  }

  Future<void> _refreshAvatar() async {
    try {
      final profile = await Global.tiebaAPI.getUserInfo(uid: _uid);
      if (!mounted || !_sameAccount || profile.uid != _uid) return;
      setState(() => _profile!.portraitUrl = profile.portraitUrl);
    } catch (_) {
      // 上传已成功，资料读取失败时保持现有状态。
    }
  }

  void _resetToBaseline() {
    if (_baseline == null || _busy) return;
    FocusScope.of(context).unfocus();
    _name.text = _baseline!.name;
    _intro.text = _baseline!.intro;
    setState(() => _sex = _baseline!.sex);
  }

  Future<void> _save() async {
    if (_busy || _saveUnconfirmed || !_dirty) return;
    // 列表滚动后字段可能已卸载，因此直接检查输入值。
    if (_name.text.trim().isEmpty) {
      _form.currentState?.validate();
      _message('昵称不能为空，请填写后再保存');
      return;
    }
    if (_intro.text.length > 500) {
      _message('个人签名不能超过500字');
      return;
    }
    if (!(_form.currentState?.validate() ?? false)) return;
    if (!_sameAccount) {
      _message('当前账号已切换，请返回后重新打开资料编辑');
      return;
    }
    FocusScope.of(context).unfocus();
    final values = (
      name: _name.text.trim(),
      intro: _intro.text.trim(),
      sex: _sex,
    );
    if (values == _baseline) {
      _name.text = values.name;
      _intro.text = values.intro;
      return;
    }
    setState(() => _saving = true);
    _profileRead++;
    try {
      final TiebaProfileUpdateResult result = await Global.tiebaAPI
          .updateUserProfile(
            nickname: values.name != _baseline!.name ? values.name : null,
            intro: values.intro != _baseline!.intro ? values.intro : null,
            sex: values.sex != _baseline!.sex ? values.sex : null,
          )
          .timeout(const Duration(seconds: 30));
      if (!mounted || !_sameAccount) return;
      _name.text = values.name;
      _intro.text = values.intro;
      setState(() {
        _baseline = values;
        _nicknamePending = result.nicknamePending;
        _saving = false;
      });
      _message(result.message.isNotEmpty ? result.message : '资料已提交到贴吧');
      // 刷新其他页面在保存事务之外进行，完成态保持不变。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sameAccount) profileEvents.profileSaved(_uid);
      });
    } on TimeoutException {
      if (mounted) {
        setState(() => _saveUnconfirmed = true);
        _message('请求超时，保存结果待确认。请先重新读取贴吧资料，不要重复提交。');
      }
    } catch (error) {
      if (mounted) {
        final String detail = error is NetAPIError
            ? error.errorMessage ?? '网络异常，请稍后重试'
            : '网络异常，请稍后重试';
        _message('保存失败：$detail');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _leave() async {
    if (_busy || _confirming) return;
    _confirming = true;
    final bool discard = !_dirty ||
        await showDialog<bool>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('放弃未保存的修改？'),
                content: const Text('本次修改还没有提交到贴吧，离开后将丢失。'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('继续编辑'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('放弃修改'),
                  ),
                ],
              ),
            ) ==
            true;
    _confirming = false;
    if (!mounted || !discard) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  String? _desktopSubtitle() {
    if (_uid.isEmpty) return null;
    final String display = _name.text.trim().isNotEmpty
        ? _name.text.trim()
        : (_profile?.name ?? '');
    if (display.isEmpty) return '个人与设置';
    return '个人与设置 · $display';
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        _layoutWidth = width;
        final bool desktop = AppBreakpoints.isDesktopWidth(width);
        return PopScope<Object?>(
          canPop: _allowPop || (!_dirty && !_busy),
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop) _leave();
          },
          child: desktop
              ? CallbackShortcuts(
                  bindings: <ShortcutActivator, VoidCallback>{
                    const SingleActivator(LogicalKeyboardKey.keyS,
                        control: true): () {
                      if (_dirty && !_busy && !_saveUnconfirmed) _save();
                    },
                  },
                  child: DesktopShellFrame(
                    title: '编辑资料',
                    subtitle: _desktopSubtitle(),
                    activeTab: 3,
                    onBack: _leave,
                    onRefresh: _uid.isEmpty || _busy ? null : _load,
                    child: _desktopBody(context, width),
                  ),
                )
              : Scaffold(
                  backgroundColor: tokens.bg,
                  appBar: AppBar(
                    backgroundColor: tokens.bg,
                    foregroundColor: tokens.textPrimary,
                    surfaceTintColor: tokens.bg.withValues(alpha: 0),
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    toolbarHeight: TiebananaMetrics.appBarHeight +
                        (MediaQuery.textScalerOf(context).scale(20) - 20)
                            .clamp(0.0, double.infinity),
                    titleTextStyle:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                    title: const Text('编辑资料'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: _dirty && !_busy && !_saveUnconfirmed
                            ? _save
                            : null,
                        style: TextButton.styleFrom(
                          foregroundColor: tokens.primary,
                          disabledForegroundColor: tokens.textTertiary,
                          textStyle: Theme.of(context).textTheme.labelLarge,
                        ),
                        child: Text(_saving ? '保存中…' : '保存'),
                      ),
                      const SizedBox(width: TiebananaMetrics.gapSm),
                    ],
                  ),
                  body: SafeArea(top: false, child: _body(context)),
                ),
        );
      },
    );
  }

  // ================= 桌面宽屏布局（>= 720dp） =================

  Widget _desktopBody(BuildContext context, double screenWidth) {
    if (_uid.isEmpty) {
      return Center(
        child: StateView(
          icon: Icons.person_outline_rounded,
          title: '登录后编辑资料',
          body: '个人资料与你的贴吧账号关联',
          primaryLabel: '去登录',
          onPrimary: () =>
              Navigator.pushReplacementNamed(context, PageRouter.login),
        ),
      );
    }
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: '加载个人资料'),
      );
    }
    if (_failed) {
      return Center(
        child: StateView(
          icon: Icons.wifi_off_outlined,
          title: '暂时无法读取资料',
          body: '检查网络连接后再试',
          primaryLabel: '重试',
          onPrimary: _load,
        ),
      );
    }

    final TiebaUserProfile profile = _profile!;
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final bool twoCol = screenWidth >= AppBreakpoints.mediumMax;
    final double leftWidth = screenWidth >= 1100 ? 312 : 284;
    final double colGap = screenWidth >= 1100 ? 16 : 14;

    return Form(
      key: _form,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: PageWrap(
          maxWidth: AppBreakpoints.pageMaxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DesktopPageHeader(
                title: '编辑资料',
                subtitle: '头像会即时上传生效；昵称、个人签名与性别在点击保存后一并提交到贴吧',
                tools: <Widget>[
                  _desktopStatusPill(context, tokens, text),
                  OutlinedButton.icon(
                    onPressed: _dirty && !_busy ? _resetToBaseline : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      foregroundColor: tokens.textSecondary,
                      disabledForegroundColor: tokens.textTertiary,
                      side: BorderSide(color: tokens.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: text.labelMedium?.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: const Icon(Icons.undo_rounded, size: 14),
                    label: const Text('还原修改'),
                  ),
                  FilledButton.icon(
                    onPressed:
                        _dirty && !_busy && !_saveUnconfirmed ? _save : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      backgroundColor: tokens.primary,
                      foregroundColor: tokens.accentOn,
                      disabledBackgroundColor: tokens.fill,
                      disabledForegroundColor: tokens.textTertiary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: text.labelMedium?.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: Text(_saving ? '保存中…' : '保存修改'),
                  ),
                ],
              ),
              if (twoCol)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: leftWidth,
                      child: _desktopIdentityDock(
                        context,
                        profile,
                        tokens,
                        text,
                        wideSplit: false,
                      ),
                    ),
                    SizedBox(width: colGap),
                    Expanded(
                      child: _desktopFormColumn(context, tokens, text),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _desktopIdentityDock(
                      context,
                      profile,
                      tokens,
                      text,
                      wideSplit: true,
                    ),
                    const SizedBox(height: 14),
                    _desktopFormColumn(context, tokens, text),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopStatusPill(
      BuildContext context, TiebananaTokens tokens, TextTheme text) {
    final bool isDark = tokens.bg.computeLuminance() < .5;
    final Color okFg =
        isDark ? const Color(0xff6fd39b) : const Color(0xff1b7f4b);
    final Color warnFg =
        isDark ? const Color(0xfffbbf24) : const Color(0xffb45309);

    final String label;
    final Color fg;
    final Color bg;
    if (_saveUnconfirmed || _avatarUnconfirmed) {
      label = '修改结果待确认';
      fg = warnFg;
      bg = warnFg.withValues(alpha: .14);
    } else if (_changingAvatar || _nicknamePending) {
      label = _changingAvatar && _nicknamePending
          ? '头像上传中 · 昵称审核中'
          : (_changingAvatar ? '头像上传中' : '昵称审核中');
      fg = warnFg;
      bg = warnFg.withValues(alpha: .14);
    } else if (_dirty) {
      label = '有未保存修改';
      fg = tokens.onPrimaryContainer;
      bg = tokens.primaryContainer;
    } else {
      label = '已与贴吧同步';
      fg = okFg;
      bg = okFg.withValues(alpha: .13);
    }

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TiebananaMetrics.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: text.labelSmall?.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopIdentityDock(
    BuildContext context,
    TiebaUserProfile profile,
    TiebananaTokens tokens,
    TextTheme text, {
    required bool wideSplit,
  }) {
    final bool isDark = tokens.bg.computeLuminance() < .5;
    final Color okFg =
        isDark ? const Color(0xff6fd39b) : const Color(0xff1b7f4b);
    final Color warnFg =
        isDark ? const Color(0xfffbbf24) : const Color(0xffb45309);

    final String liveName =
        _name.text.trim().isEmpty ? profile.name : _name.text.trim();
    final String liveIntro = _intro.text.trim();
    final String genderLabel = switch (_sex) {
      '1' => '♂ 男',
      '2' => '♀ 女',
      _ => '未设置',
    };
    final bool canPickAvatar =
        !_busy && !_saveUnconfirmed && !_avatarUnconfirmed;

    final Widget avatarBox = Semantics(
      label: '更换头像',
      image: true,
      child: MouseRegion(
        cursor: canPickAvatar ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _avatarHovered = true),
        onExit: (_) => setState(() => _avatarHovered = false),
        child: GestureDetector(
          onTap: canPickAvatar ? _changeAvatar : null,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: TiebananaMetrics.brLg,
              border: Border.all(color: tokens.line),
              boxShadow: tokens.cardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _buildAvatarImage(profile, tokens, size: 84),
                if (_avatarHovered && canPickAvatar)
                  ColoredBox(
                    color: const Color(0x6B0A0F18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.photo_camera_outlined,
                            size: 18, color: tokens.onImage),
                        const SizedBox(height: 2),
                        Text(
                          '更换',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: tokens.onImage,
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: tokens.line),
                      boxShadow: tokens.cardShadow,
                    ),
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 13,
                      color: tokens.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final Widget bioPreviewSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              '主页签名预览',
              style: text.labelSmall?.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
                color: tokens.textTertiary,
              ),
            ),
            Text(
              '实时同步',
              style: text.labelSmall?.copyWith(
                fontSize: 10.5,
                color: tokens.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CustomPaint(
          foregroundPainter: DashedBorderPainter(
            color: tokens.lineStrong,
            radius: TiebananaMetrics.brSm,
            strokeWidth: 1,
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: tokens.bg,
              borderRadius: TiebananaMetrics.brSm,
            ),
            child: Text(
              liveIntro.isEmpty ? '暂无个人签名' : liveIntro,
              style: text.bodySmall?.copyWith(
                fontSize: 12,
                height: 1.65,
                color: liveIntro.isEmpty
                    ? tokens.textTertiary
                    : tokens.textSecondary,
                fontStyle:
                    liveIntro.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ),
      ],
    );

    final Widget accountMetaSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '只读账号信息',
          style: text.labelSmall?.copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: .6,
            color: tokens.textTertiary,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('贴吧 ID',
                style: text.bodySmall?.copyWith(color: tokens.textTertiary)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  profile.uid,
                  style: text.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: profile.uid));
                    if (mounted) _message('已复制贴吧 ID：${profile.uid}');
                  },
                  child: Container(
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      color: tokens.fill,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.copy_rounded,
                            size: 11, color: tokens.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '复制',
                          style: text.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('吧龄',
                style: text.bodySmall?.copyWith(color: tokens.textTertiary)),
            Text(
              profile.tbAge.isEmpty ? '暂无' : profile.tbAge,
              style: text.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('昵称修改',
                style: text.bodySmall?.copyWith(color: tokens.textTertiary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:
                    (_nicknamePending ? warnFg : okFg).withValues(alpha: .14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _nicknamePending ? '审核中' : '可修改',
                style: text.labelSmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: _nicknamePending ? warnFg : okFg,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return DesktopPanel(
      borderRadius: TiebananaMetrics.brXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color.lerp(tokens.primaryContainer, tokens.surface, .38)!,
                  Color.lerp(tokens.primaryContainer, tokens.surface, .84)!,
                  tokens.surface,
                ],
                stops: const <double>[0, .72, 1],
              ),
              border: Border(bottom: BorderSide(color: tokens.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    avatarBox,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            liveName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: tokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 5,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: tokens.fill,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  genderLabel,
                                  style: text.labelSmall?.copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textSecondary,
                                  ),
                                ),
                              ),
                              if (_nicknamePending)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: warnFg.withValues(alpha: .14),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '昵称审核中',
                                    style: text.labelSmall?.copyWith(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: warnFg,
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
                const SizedBox(height: 13),
                FilledButton.tonalIcon(
                  onPressed: canPickAvatar ? _changeAvatar : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 36),
                    backgroundColor: tokens.primaryContainer,
                    foregroundColor: tokens.onPrimaryContainer,
                    disabledBackgroundColor: tokens.fill,
                    disabledForegroundColor: tokens.textTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: text.labelMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: Icon(
                    _changingAvatar
                        ? Icons.cloud_upload_outlined
                        : Icons.photo_camera_outlined,
                    size: 16,
                  ),
                  label: Text(_changingAvatar
                      ? _avatarProgress == null
                          ? '正在准备头像…'
                          : '上传中 ${(_avatarProgress! * 100).round()}%'
                      : '更换头像'),
                ),
                if (_changingAvatar) ...<Widget>[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: tokens.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              _avatarProgress == null ? '正在准备头像…' : '正在上传头像…',
                              style: text.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: tokens.primary,
                              ),
                            ),
                            if (_avatarProgress != null)
                              Text(
                                '${(_avatarProgress! * 100).round()}%',
                                style: text.labelSmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.primary,
                                  fontFeatures: const <FontFeature>[
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: _avatarProgress,
                            minHeight: 5,
                            backgroundColor: tokens.fill,
                            color: tokens.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '选择图片后在居中裁切框调整，导出 960×960 JPG（20 MB 以内）',
                  style: text.bodySmall?.copyWith(
                    fontSize: 10.5,
                    height: 1.5,
                    color: tokens.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: wideSplit
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: bioPreviewSection),
                      const SizedBox(width: 14),
                      Container(
                        width: 220,
                        padding: const EdgeInsets.only(left: 14),
                        decoration: BoxDecoration(
                          border: Border(left: BorderSide(color: tokens.line)),
                        ),
                        child: accountMetaSection,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      bioPreviewSection,
                      Divider(height: 24, thickness: 1, color: tokens.line),
                      accountMetaSection,
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _desktopFormColumn(
      BuildContext context, TiebananaTokens tokens, TextTheme text) {
    final bool isDark = tokens.bg.computeLuminance() < .5;
    final Color warnFg =
        isDark ? const Color(0xfffbbf24) : const Color(0xffb45309);
    final int introLength = _intro.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_saveUnconfirmed || _avatarUnconfirmed) ...<Widget>[
          DesktopPanel(
            borderColor: warnFg.withValues(alpha: .35),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Row(
              children: <Widget>[
                Icon(Icons.warning_amber_rounded, size: 20, color: warnFg),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '修改结果待确认，暂不重复提交',
                        style: text.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '修改结果待确认，暂不重复提交。重新读取将以贴吧资料替换当前输入；昵称或头像可能仍在审核中。',
                        style: text.bodySmall?.copyWith(
                          fontSize: 11.5,
                          height: 1.5,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _load,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.textPrimary,
                    side: BorderSide(color: tokens.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('重新读取贴吧资料'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        DesktopPanel(
          borderRadius: TiebananaMetrics.brXl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 13),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: tokens.line)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            '关于我',
                            style: text.titleSmall?.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.textPrimary,
                            ),
                          ),
                          Text(
                            '让吧友更了解你',
                            style: text.bodySmall?.copyWith(
                              fontSize: 11.5,
                              color: tokens.textTertiary,
                            ),
                          ),
                        ],
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
                        'Ctrl S',
                        style: TextStyle(
                          fontSize: 10,
                          height: 1,
                          color: tokens.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '保存',
                      style: text.bodySmall?.copyWith(
                        fontSize: 10.5,
                        color: tokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _fieldLabel(
                            context,
                            '昵称',
                            _nicknamePending ? null : '别人会这样称呼你',
                          ),
                        ),
                        if (_nicknamePending)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: warnFg.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '审核中，暂不支持修改',
                              style: text.labelSmall?.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: warnFg,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: TiebananaMetrics.gapSm),
                    Semantics(
                      label: '昵称',
                      child: TextFormField(
                        controller: _name,
                        enabled: !_busy && !_nicknamePending,
                        style:
                            text.bodyLarge?.copyWith(color: tokens.textPrimary),
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          context,
                          '希望大家怎么称呼你',
                          suffixIcon: !_busy &&
                                  !_nicknamePending &&
                                  _name.text.isNotEmpty
                              ? IconButton(
                                  tooltip: '清空昵称',
                                  onPressed: () {
                                    _name.clear();
                                  },
                                  icon: Icon(Icons.close_rounded,
                                      size: 16, color: tokens.textTertiary),
                                )
                              : null,
                        ),
                        validator: (String? value) =>
                            (value?.trim().isEmpty ?? true) ? '请填写昵称' : null,
                      ),
                    ),
                    const SizedBox(height: TiebananaMetrics.gapLg),
                    _fieldLabel(context, '性别', '展示在个人资料与主页'),
                    const SizedBox(height: TiebananaMetrics.gapSm),
                    _desktopGenderSegmented(context, tokens, text),
                    const SizedBox(height: TiebananaMetrics.gapLg),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _fieldLabel(context, '个人签名', '留一句关于自己的话'),
                        ),
                        Text(
                          '$introLength / 500',
                          style: text.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: introLength > 500
                                ? tokens.danger
                                : tokens.textTertiary,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TiebananaMetrics.gapSm),
                    Semantics(
                      label: '个人签名',
                      child: TextFormField(
                        controller: _intro,
                        enabled: !_busy,
                        minLines: 4,
                        maxLines: 6,
                        maxLength: 500,
                        buildCounter: (_,
                                {required int currentLength,
                                required bool isFocused,
                                int? maxLength}) =>
                            const SizedBox.shrink(),
                        style: text.bodyLarge
                            ?.copyWith(color: tokens.textPrimary, height: 1.7),
                        decoration:
                            _inputDecoration(context, '写一点关于自己的事，也可以留空'),
                        validator: (String? value) =>
                            (value?.length ?? 0) > 500 ? '个人签名不能超过500字' : null,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                decoration: BoxDecoration(
                  color: Color.lerp(tokens.bar, tokens.surface, .45),
                  border: Border(top: BorderSide(color: tokens.line)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 14,
                  runSpacing: 10,
                  children: <Widget>[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(Icons.info_outline_rounded,
                                size: 14, color: tokens.textTertiary),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              '保存后将提交到贴吧。昵称修改可能受频率限制或需要审核，以贴吧的处理结果为准。',
                              style: text.bodySmall?.copyWith(
                                fontSize: 11,
                                height: 1.55,
                                color: tokens.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        OutlinedButton(
                          onPressed: _dirty && !_busy ? _resetToBaseline : null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            foregroundColor: tokens.textSecondary,
                            disabledForegroundColor: tokens.textTertiary,
                            side: BorderSide(color: tokens.line),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('放弃修改'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _dirty && !_busy && !_saveUnconfirmed
                              ? _save
                              : null,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            backgroundColor: tokens.primary,
                            foregroundColor: tokens.accentOn,
                            disabledBackgroundColor: tokens.fill,
                            disabledForegroundColor: tokens.textTertiary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 15),
                          label: Text(_saving ? '保存中…' : '保存修改'),
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

  Widget _desktopGenderSegmented(
    BuildContext context,
    TiebananaTokens tokens,
    TextTheme text,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: tokens.fill,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Wrap(
          spacing: 3,
          runSpacing: 3,
          children: <Widget>[
            for (final (String, String, String) option
                in <(String, String, String)>[
              ('0', '—', '未设置'),
              ('1', '♂', '男'),
              ('2', '♀', '女'),
            ])
              _desktopGenderItem(
                context,
                tokens,
                text,
                value: option.$1,
                symbol: option.$2,
                label: option.$3,
              ),
          ],
        ),
      ),
    );
  }

  Widget _desktopGenderItem(
    BuildContext context,
    TiebananaTokens tokens,
    TextTheme text, {
    required String value,
    required String symbol,
    required String label,
  }) {
    final bool selected = _sex == value;
    final Color fg = _busy
        ? tokens.textTertiary
        : (selected ? tokens.primary : tokens.textSecondary);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? tokens.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        elevation: 0,
        child: Container(
          decoration: selected
              ? BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: tokens.cardShadow,
                )
              : null,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _busy ? null : () => setState(() => _sex = value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (selected) ...<Widget>[
                    Icon(Icons.check_rounded, size: 14, color: fg),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    symbol,
                    style: text.labelLarge?.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: fg.withValues(alpha: selected ? 1 : .78),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: text.labelLarge?.copyWith(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= 移动端布局（< 720dp，保持现状） =================

  Widget _body(BuildContext context) {
    if (_uid.isEmpty) {
      return Center(
        child: StateView(
          icon: Icons.person_outline_rounded,
          title: '登录后编辑资料',
          body: '个人资料与你的贴吧账号关联',
          primaryLabel: '去登录',
          onPrimary: () =>
              Navigator.pushReplacementNamed(context, PageRouter.login),
        ),
      );
    }
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(semanticsLabel: '加载个人资料'));
    }
    if (_failed) {
      return Center(
        child: StateView(
          icon: Icons.wifi_off_outlined,
          title: '暂时无法读取资料',
          body: '检查网络连接后再试',
          primaryLabel: '重试',
          onPrimary: _load,
        ),
      );
    }
    final TiebaUserProfile profile = _profile!;
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Form(
      key: _form,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: TiebananaMetrics.gapXl),
        children: <Widget>[
          if (_saveUnconfirmed || _avatarUnconfirmed)
            Padding(
              padding: const EdgeInsets.all(TiebananaMetrics.gapLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text('修改结果待确认，暂不重复提交。重新读取将以贴吧资料替换当前输入；昵称或头像可能仍在审核中。'),
                  TextButton(onPressed: _load, child: const Text('重新读取贴吧资料')),
                ],
              ),
            ),
          _identityCard(context, profile),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TiebananaMetrics.pageGutter + TiebananaMetrics.gapXs,
              TiebananaMetrics.gapXl,
              TiebananaMetrics.pageGutter + TiebananaMetrics.gapXs,
              0,
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: TiebananaMetrics.gapMd,
              runSpacing: TiebananaMetrics.gapXs,
              children: <Widget>[
                Text('关于我',
                    style: text.titleSmall?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    )),
                Text('让吧友更了解你',
                    style:
                        text.bodySmall?.copyWith(color: tokens.textTertiary)),
              ],
            ),
          ),
          SettingCard(
            child: Padding(
              padding: const EdgeInsets.all(TiebananaMetrics.gapLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _fieldLabel(context, '昵称',
                      _nicknamePending ? '审核中，暂不支持修改' : '别人会这样称呼你'),
                  const SizedBox(height: TiebananaMetrics.gapSm),
                  Semantics(
                    label: '昵称',
                    child: TextFormField(
                      controller: _name,
                      enabled: !_busy && !_nicknamePending,
                      style:
                          text.bodyLarge?.copyWith(color: tokens.textPrimary),
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(context, '希望大家怎么称呼你'),
                      validator: (String? value) =>
                          (value?.trim().isEmpty ?? true) ? '请填写昵称' : null,
                    ),
                  ),
                  const SizedBox(height: TiebananaMetrics.gapLg),
                  _fieldLabel(context, '个人签名', '留一句关于自己的话'),
                  const SizedBox(height: TiebananaMetrics.gapSm),
                  Semantics(
                    label: '个人签名',
                    child: TextFormField(
                      controller: _intro,
                      enabled: !_busy,
                      minLines: 3,
                      maxLines: 6,
                      style: text.bodyLarge
                          ?.copyWith(color: tokens.textPrimary, height: 1.7),
                      decoration: _inputDecoration(context, '写一点关于自己的事，也可以留空'),
                      maxLength: 500,
                      validator: (String? value) =>
                          (value?.length ?? 0) > 500 ? '个人签名不能超过500字' : null,
                    ),
                  ),
                  const SizedBox(height: TiebananaMetrics.gapLg),
                  _fieldLabel(context, '性别'),
                  const SizedBox(height: TiebananaMetrics.gapSm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final (String, String) option in <(String, String)>[
                        ('0', '未设置'),
                        ('1', '男'),
                        ('2', '女')
                      ]) ...<Widget>[
                        if (option.$1 != '0')
                          const SizedBox(width: TiebananaMetrics.gapSm),
                        Expanded(
                          child: _genderChoice(context, option.$1, option.$2),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(TiebananaMetrics.gapXl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text.rich(
                  TextSpan(children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            right: TiebananaMetrics.gapSm),
                        child: Icon(Icons.info_outline_rounded,
                            color: tokens.textTertiary,
                            size: MediaQuery.textScalerOf(context)
                                .scale(TiebananaMetrics.iconSizeSmall)),
                      ),
                    ),
                    const TextSpan(
                        text: '保存后将提交到贴吧。昵称修改可能受频率限制或需要审核，以贴吧的处理结果为准。'),
                  ]),
                  style: text.bodySmall
                      ?.copyWith(color: tokens.textTertiary, height: 1.6),
                ),
                const SizedBox(height: TiebananaMetrics.gapLg),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: TiebananaMetrics.gapLg,
                  runSpacing: TiebananaMetrics.gapSm,
                  children: <Widget>[
                    Text('贴吧 ID  ${profile.uid}',
                        style: text.bodySmall
                            ?.copyWith(color: tokens.textTertiary)),
                    Text('吧龄  ${profile.tbAge.isEmpty ? '暂无' : profile.tbAge}',
                        style: text.bodySmall
                            ?.copyWith(color: tokens.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _avatarProvider(String url) {
    if (url.startsWith('data:image/')) {
      return MemoryImage(UriData.parse(url).contentAsBytes());
    }
    return NetworkImage(url);
  }

  Widget _buildAvatarImage(
    TiebaUserProfile profile,
    TiebananaTokens tokens, {
    required double size,
  }) {
    if (_avatarPreview != null) {
      return Image.memory(
        _avatarPreview!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
    if (profile.portraitUrl.isEmpty) {
      return _avatarPlaceholder(tokens, size: size);
    }
    return Image(
      image:
          _avatarProvider(profileEvents.avatarUrl(_uid, profile.portraitUrl)),
      width: size,
      height: size,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      errorBuilder: (_, error, stackTrace) =>
          _avatarPlaceholder(tokens, size: size),
    );
  }

  Widget _identityCard(BuildContext context, TiebaUserProfile profile) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final double avatarSize =
        TiebananaMetrics.avatarXl + TiebananaMetrics.gapLg;
    final Widget avatar = Semantics(
      label: '更换头像',
      image: true,
      child: InkWell(
        onTap: _busy || _saveUnconfirmed || _avatarUnconfirmed
            ? null
            : _changeAvatar,
        borderRadius: TiebananaMetrics.brLg,
        child: ClipRRect(
          borderRadius: TiebananaMetrics.brLg,
          child: _buildAvatarImage(profile, tokens, size: avatarSize),
        ),
      ),
    );
    final Widget identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _name.text.trim().isEmpty ? profile.name : _name.text.trim(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.titleLarge?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: TiebananaMetrics.gapSm),
        TextButton.icon(
          onPressed: _busy || _saveUnconfirmed || _avatarUnconfirmed
              ? null
              : _changeAvatar,
          icon: Icon(
              _changingAvatar
                  ? Icons.cloud_upload_outlined
                  : Icons.photo_camera_outlined,
              size: TiebananaMetrics.iconSizeSmall),
          label: Text(_changingAvatar
              ? _avatarProgress == null
                  ? '正在准备头像…'
                  : '上传中 ${(_avatarProgress! * 100).round()}%'
              : '更换头像'),
        ),
        if (_changingAvatar) LinearProgressIndicator(value: _avatarProgress),
      ],
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(
        TiebananaMetrics.pageGutter,
        TiebananaMetrics.gapSm,
        TiebananaMetrics.pageGutter,
        0,
      ),
      decoration: BoxDecoration(
        borderRadius: TiebananaMetrics.brXl,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(tokens.primaryContainer, tokens.surface, .25)!,
            Color.lerp(tokens.primaryContainer, tokens.surface, .65)!,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(TiebananaMetrics.gapLg),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth <
                    MediaQuery.textScalerOf(context).scale(240)) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      avatar,
                      const SizedBox(height: TiebananaMetrics.gapMd),
                      identity,
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    avatar,
                    const SizedBox(width: TiebananaMetrics.gapLg),
                    Expanded(child: identity),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String label, [String? hint]) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Wrap(
      spacing: TiebananaMetrics.gapSm,
      runSpacing: TiebananaMetrics.gapXs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(label,
            style: text.labelLarge?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w600,
            )),
        if (hint != null)
          Text(hint,
              style: text.bodySmall?.copyWith(color: tokens.textSecondary)),
      ],
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String hint, {
    Widget? suffixIcon,
  }) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: TiebananaMetrics.brCtl,
      borderSide:
          BorderSide(color: tokens.textSecondary.withValues(alpha: .16)),
    );
    return InputDecoration(
      hintText: hint,
      hintMaxLines: 3,
      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: tokens.textTertiary,
          ),
      filled: true,
      fillColor: Color.lerp(tokens.surface, tokens.fill, .72),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TiebananaMetrics.gapMd,
        vertical: TiebananaMetrics.gapMd,
      ),
      suffixIcon: suffixIcon,
      border: border,
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: tokens.primary.withValues(alpha: .65)),
      ),
      errorBorder:
          border.copyWith(borderSide: BorderSide(color: tokens.danger)),
      focusedErrorBorder:
          border.copyWith(borderSide: BorderSide(color: tokens.danger)),
      errorMaxLines: 3,
    );
  }

  Widget _genderChoice(
    BuildContext context,
    String value,
    String label, {
    String? symbol,
  }) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool selected = _sex == value;
    return Semantics(
      selected: selected,
      child: TextButton(
        onPressed: _busy ? null : () => setState(() => _sex = value),
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: TiebananaMetrics.gapXs,
            vertical: TiebananaMetrics.gapMd,
          ),
          foregroundColor: selected ? tokens.primary : tokens.textSecondary,
          disabledForegroundColor: tokens.textTertiary,
          backgroundColor: selected
              ? tokens.primaryContainer
              : Color.lerp(tokens.surface, tokens.fill, .65),
          shape: RoundedRectangleBorder(
            borderRadius: TiebananaMetrics.brSm,
            side: BorderSide(
              color: selected
                  ? tokens.primary.withValues(alpha: .3)
                  : tokens.textSecondary.withValues(alpha: .13),
            ),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: TiebananaMetrics.gapXs,
          children: <Widget>[
            if (selected)
              const Icon(Icons.check_rounded,
                  size: TiebananaMetrics.iconSizeSmall),
            if (symbol != null) Text(symbol, textAlign: TextAlign.center),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(TiebananaTokens tokens, {double? size}) {
    final double s =
        size ?? (TiebananaMetrics.avatarXl + TiebananaMetrics.gapLg);
    return Container(
      width: s,
      height: s,
      color: tokens.fill,
      child: Icon(Icons.person_outline_rounded,
          color: tokens.primary, size: TiebananaMetrics.avatarMd),
    );
  }
}
