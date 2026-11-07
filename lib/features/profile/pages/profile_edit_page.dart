import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/profile/state/profile_events.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/media/pages/image_picker_page.dart';
import 'package:tiebanana/features/profile/pages/avatar_crop_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';
import 'package:tiebanana/shared/widgets/setting_group.dart';

/// 方向 A：当前头像卡 → 基本资料表单 → 只读账号信息。
///
/// 保存调用当前账号的资料修改接口，失败时保留输入。
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key, this.avatarPicker});

  /// 可替换选图/裁切入口，生产默认走本机相册与正方形裁切页。
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
  double? _avatarProgress;
  Uint8List? _avatarPreview;
  int _profileRead = 0;

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

  Future<Uint8List?> _pickAvatar() async {
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
    final bytes = await file.readAsBytes();
    if (!mounted) return null;
    return Navigator.push<Uint8List>(
        context,
        appPageRoute(
            builder: (_) => AvatarCropPage(
                imageBytes: bytes, outputSize: 960, quality: 80)));
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

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return PopScope<Object?>(
      canPop: _allowPop || (!_dirty && !_busy),
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
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
          titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
          title: const Text('编辑资料'),
          actions: <Widget>[
            TextButton(
              onPressed: _dirty && !_busy && !_saveUnconfirmed ? _save : null,
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
  }

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

  Widget _identityCard(BuildContext context, TiebaUserProfile profile) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme text = Theme.of(context).textTheme;
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
          child: _avatarPreview != null
              ? Image.memory(_avatarPreview!,
                  width: 72, height: 72, fit: BoxFit.cover)
              : profile.portraitUrl.isEmpty
                  ? _avatarPlaceholder(tokens)
                  : Image(
                      image: _avatarProvider(
                          profileEvents.avatarUrl(_uid, profile.portraitUrl)),
                      width: TiebananaMetrics.avatarXl + TiebananaMetrics.gapLg,
                      height:
                          TiebananaMetrics.avatarXl + TiebananaMetrics.gapLg,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (_, error, stackTrace) =>
                          _avatarPlaceholder(tokens),
                    ),
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

  InputDecoration _inputDecoration(BuildContext context, String hint) {
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

  Widget _genderChoice(BuildContext context, String value, String label) {
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
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(TiebananaTokens tokens) => Container(
        width: TiebananaMetrics.avatarXl + TiebananaMetrics.gapLg,
        height: TiebananaMetrics.avatarXl + TiebananaMetrics.gapLg,
        color: tokens.fill,
        child: Icon(Icons.person_outline_rounded,
            color: tokens.primary, size: TiebananaMetrics.avatarMd),
      );
}
