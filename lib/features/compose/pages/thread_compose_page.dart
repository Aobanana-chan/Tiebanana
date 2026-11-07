import 'dart:async';

import 'package:extended_text_field/extended_text_field.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/platform/official_tieba.dart';
import 'package:tiebanana/features/media/state/image_upload.dart';
import 'package:tiebanana/features/compose/models/thread_compose_draft.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/features/media/pages/image_picker_page.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/compose/pages/compose_topic_page.dart';
import 'package:tiebanana/features/compose/pages/compose_score_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/features/compose/widgets/compose_poll_editor.dart';
import 'package:tiebanana/shared/content/emoji_panel.dart';
import 'package:tiebanana/shared/content/posting_risk_warning.dart';
import 'package:tiebanana/shared/widgets/setting_group.dart';
import 'package:tiebanana/shared/content/special_span.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';

/// 发帖界面，提交正文、配图、话题和投票。
class ThreadComposePage extends StatefulWidget {
  const ThreadComposePage({
    super.key,
    required this.fid,
    required this.forumName,
    this.topicId = '',
    this.topicName = '',
  });
  final String fid;
  final String forumName;
  final String topicId;
  final String topicName;

  @override
  State<ThreadComposePage> createState() => _ThreadComposePageState();
}

class _ThreadComposePageState extends State<ThreadComposePage>
    with WidgetsBindingObserver {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _bodyFocus = FocusNode();
  late final _images = ImageUploadProviderModel(widget.forumName);
  late final String _account = Global.profile.getString('uid') ?? '';
  late final String _draftKey = 'threadCompose.v1.$_account.${widget.fid}';
  late String _tail = Global.setting.postTail ?? '';
  late bool _useTail =
      (Global.setting.usePostTail ?? false) && _tail.isNotEmpty;
  ComposePoll? _poll;
  ComposeScore? _score;
  late final _scoreImages = ImageUploadProviderModel(widget.forumName);
  List<ImageUploadTask> get _allImageTasks =>
      [..._images.tasks, ..._scoreImages.tasks];
  bool get _scoreReady =>
      _score == null ||
      _score!.items.every((item) => _scoreImages.tasks
          .any((task) => task.asset.id == item.assetId && task.result != null));
  TiebaComposeTopic? _topic;
  bool _hideFromProfile = false;
  String _contentStatement = '';
  TiebaPublisherConfig? _publisherConfig;
  String? _configError;
  bool _configLoading = true;
  final List<ComposeAttachment> _unavailableImages = [];
  Timer? _saveTimer;
  Future<void> _saveQueue = Future.value();
  bool _loading = true;
  bool _saving = false;
  bool _allowPop = false;
  bool _closing = false;
  bool _emoji = false;
  bool _dirty = false;
  bool _draftSaved = false;
  bool _restoreFailed = false;
  bool _publishing = false;
  bool _publishUncertain = false;
  TiebaPublishResult? _published;
  String? _publishError;
  String? _storageError;
  int _revision = 0;

  bool get _sameAccount => (Global.profile.getString('uid') ?? '') == _account;
  bool get _active =>
      !_loading && !_closing && !_publishing && _published == null;

  ThreadComposeDraft get _draft => ThreadComposeDraft(
        title: _title.text,
        body: _body.text,
        tail: _tail,
        useTail: _useTail,
        poll: _poll,
        topicId: _topic?.id,
        topicName: _topic?.name,
        hideFromProfile: _hideFromProfile,
        contentStatement: _contentStatement,
        score: _score,
        attachments: [
          for (final task in _images.tasks)
            ComposeAttachment(task.asset.id, task.saveOrigin),
          ..._unavailableImages,
        ],
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _title.addListener(_changed);
    _body.addListener(_changed);
    _images.addListener(_uploadChanged);
    _scoreImages.addListener(_uploadChanged);
    _bodyFocus.addListener(_focusChanged);
    _restore();
    _loadPublisherConfig();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showPostingRiskWarning(
            context, OfficialTiebaTarget(forumName: widget.forumName));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _title.dispose();
    _body.dispose();
    _bodyFocus.dispose();
    _images.removeListener(_uploadChanged);
    _images.dispose();
    _scoreImages.removeListener(_uploadChanged);
    _scoreImages.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive &&
        _dirty &&
        !_closing &&
        !_publishing) {
      _saveTimer?.cancel();
      unawaited(_save());
    }
  }

  void _focusChanged() {
    if (_bodyFocus.hasFocus && _emoji) setState(() => _emoji = false);
  }

  void _uploadChanged() {
    if (mounted) setState(() {});
  }

  void _changed() {
    if (_loading || _closing) return;
    _revision++;
    setState(() {
      _dirty = true;
      _draftSaved = false;
    });
    _saveTimer?.cancel();
    if (!_restoreFailed) {
      _saveTimer = Timer(const Duration(milliseconds: 800), () {
        _save();
      });
    }
  }

  Future<void> _restore() async {
    _publishUncertain = Global.profile.getBool('$_draftKey.pending') ?? false;
    if (_publishUncertain) {
      _publishError = '上次发布的结果尚未确认，请先到个人主页核对，不要重复发送。';
    }
    final source = Global.profile.getString(_draftKey);
    try {
      if (source != null) {
        final draft = ThreadComposeDraft.decode(source);
        _title.text = draft.title;
        _body.text = draft.body;
        _tail = draft.tail;
        _useTail = draft.useTail;
        _poll = draft.poll;
        _score = draft.score;
        _hideFromProfile = draft.hideFromProfile;
        _contentStatement = draft.contentStatement;
        if (draft.topicId != null && draft.topicName != null) {
          _topic =
              TiebaComposeTopic(id: draft.topicId!, name: draft.topicName!);
        }
        for (final attachment in draft.attachments) {
          AssetEntity? asset;
          try {
            asset = await AssetEntity.fromId(attachment.assetId);
          } catch (_) {/* 权限可能已收回。 */}
          if (!mounted) return;
          if (asset == null) {
            _unavailableImages.add(attachment);
          } else {
            // 重启后不信任旧上传结果；由用户重试，重新取得服务端图片标识。
            _images.enqueue(asset, attachment.original);
          }
        }
        for (final item in _score?.items ?? <ComposeScoreItem>[]) {
          AssetEntity? asset;
          try {
            asset = await AssetEntity.fromId(item.assetId);
          } catch (_) {/* 失效图片留在打分项中。 */}
          if (!mounted) return;
          if (asset != null) _scoreImages.enqueue(asset, false);
        }
        _draftSaved = true;
      }
    } catch (_) {
      _restoreFailed = true;
      _storageError = '本机草稿暂时无法恢复，原草稿仍保留。请勿覆盖后再尝试恢复。';
    }
    // 话题页「发帖」带入的话题：草稿里没有时才用，避免覆盖用户后来改过的选择。
    if (_topic == null && widget.topicName.trim().isNotEmpty) {
      _topic = TiebaComposeTopic(
        id: widget.topicId.trim(),
        name: _cleanTopicName(widget.topicName),
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  /// 去掉话题名两侧的 `#`，与发布时的 `#(topic)#` 格式分开处理。
  String _cleanTopicName(String value) {
    String name = value.trim();
    if (name.length > 2 && name.startsWith('#') && name.endsWith('#')) {
      name = name.substring(1, name.length - 1);
    }
    return name.trim();
  }

  Future<bool> _save() async {
    if (!_sameAccount || _restoreFailed) return false;
    final revision = _revision;
    final encoded = _draft.encode();
    if (mounted) setState(() => _saving = true);
    bool success = false;
    // 顺序写入，避免旧的自动保存覆盖较新的退出保存。
    _saveQueue = _saveQueue.then((_) async {
      try {
        success = await Global.profile.setString(_draftKey, encoded);
      } catch (_) {
        success = false;
      }
    });
    await _saveQueue;
    if (mounted) {
      setState(() {
        _saving = false;
        if (success && revision == _revision) {
          _dirty = false;
          _draftSaved = true;
          _storageError = null;
        } else if (!success) {
          _storageError = '草稿保存失败，请保留页面并重试';
        }
      });
    }
    return success;
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _leave() async {
    if (_publishing) {
      _message('正在发布，请等待结果，避免重复提交');
      return;
    }
    if (_published != null) {
      _pop();
      return;
    }
    if (_loading || _closing) return;
    if (_emoji) {
      setState(() => _emoji = false);
      return;
    }
    if (!_draft.hasContent && !_dirty && _storageError == null) {
      _pop();
      return;
    }
    setState(() => _closing = true);
    _saveTimer?.cancel();
    final decision = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('把这次灵感留下来？'),
              content: Text(_allImageTasks.any((t) => t.uploading)
                  ? '图片还在上传，离开将停止后续处理。保存草稿后，下次需重新上传配图。'
                  : '帖子还没有发布。保存为本机草稿，下次可以接着写。'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, 'discard'),
                    child: const Text('不保存，退出')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('继续编辑')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, 'save'),
                    child: const Text('保存草稿并退出')),
              ],
            ));
    if (!mounted) return;
    if (decision == 'save') {
      if (!_sameAccount) {
        _message('当前账号已改变，请返回原账号后保存');
      } else if (await _save()) {
        if (mounted) _pop();
        return;
      }
    } else if (decision == 'discard') {
      await _saveQueue;
      try {
        final removed = await Global.profile.remove(_draftKey);
        await Global.profile.remove('$_draftKey.pending');
        if (!removed) throw StateError('删除草稿失败');
        if (mounted) _pop();
        return;
      } catch (_) {
        _message('无法移除本机草稿，请重试');
      }
    }
    if (mounted) setState(() => _closing = false);
  }

  void _pop() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<T?> _sheet<T>(String title, Widget content) {
    FocusScope.of(context).unfocus();
    setState(() => _emoji = false);
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: TiebananaTokens.of(context).surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .75),
          child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                    child:
                        Text(title, style: Theme.of(ctx).textTheme.titleLarge)),
                IconButton(
                    tooltip: '关闭面板',
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 12),
              content
            ],
          )),
        ),
      ),
    );
  }

  Future<void> _unavailable(String title, String text) => _sheet<void>(
      title,
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
        Text('此项尚未接入，不会向贴吧提交此设置。',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: TiebananaTokens.of(context).textTertiary)),
      ]));

  Future<void> _interactions() => _sheet<void>(
      '添加互动组件',
      Column(children: [
        _actionCard(Icons.poll_outlined, '投票', '收集大家的选择 · 可编辑并保存草稿', () {
          Navigator.pop(context);
          _editPoll();
        }),
        const SizedBox(height: 12),
        _actionCard(Icons.star_outline_rounded, '打分', '选图创建打分项，邀请吧友评价', () {
          Navigator.pop(context);
          _editScore();
        }),
      ]));

  Widget _actionCard(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    final tokens = TiebananaTokens.of(context);
    return Material(
        color: tokens.fill,
        borderRadius: TiebananaMetrics.brMd,
        child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: TiebananaMetrics.brMd),
            leading: Icon(icon, color: tokens.primary),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap));
  }

  Future<void> _editPoll() async {
    if (_scoreImages.tasks.any((t) => t.uploading)) {
      _message('请先等待打分图片上传结束');
      return;
    }
    FocusScope.of(context).unfocus();
    final poll = await Navigator.push<ComposePoll>(context,
        appPageRoute(builder: (_) => ComposePollEditor(initial: _poll)));
    if (mounted && poll != null) {
      if (_score != null && !await _confirmReplace('打分')) return;
      if (!mounted) return;
      _poll = poll;
      _score = null;
      _clearScoreImages();
      _changed();
    }
  }

  Future<bool> _confirmReplace(String existing) async =>
      await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text('替换互动组件？'),
                  content: Text('投票和打分不能同时添加，继续将移除原有$existing。'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('保留原组件')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('确认替换'))
                  ])) ??
      false;

  void _clearScoreImages() {
    for (final task in List<ImageUploadTask>.of(_scoreImages.tasks)) {
      if (!task.uploading) _scoreImages.remove(task);
    }
  }

  Future<void> _editScore() async {
    if (_configLoading) {
      _message('正在读取官方互动组件配置');
      return;
    }
    if (_configError != null) {
      await _loadPublisherConfig();
      if (!mounted) return;
    }
    if (!(_publisherConfig?.scoreEnabled ?? false)) {
      await _unavailable('当前吧暂不支持打分', '官方配置没有向当前吧开放打分组件，不能强行提交。稍后可重试读取配置。');
      return;
    }
    if (_scoreImages.tasks.any((t) => t.uploading)) {
      _message('请先等待打分图片上传结束');
      return;
    }
    final score = await Navigator.push<ComposeScore>(context,
        appPageRoute(builder: (_) => ComposeScorePage(initial: _score)));
    if (!mounted || score == null || !_active) return;
    if (_poll != null && !await _confirmReplace('投票')) return;
    if (!mounted) return;
    _clearScoreImages();
    _score = score;
    _poll = null;
    _changed();
    for (final item in score.items) {
      AssetEntity? asset;
      try {
        asset = await AssetEntity.fromId(item.assetId);
      } catch (_) {/* 由卡片提示。 */}
      if (!mounted) return;
      if (asset != null) {
        final task = _scoreImages.enqueue(asset, false);
        unawaited(_scoreImages.upload(task));
      }
    }
  }

  Future<void> _removeScore() async {
    if (_scoreImages.tasks.any((t) => t.uploading)) {
      _message('请先等待打分图片上传结束');
      return;
    }
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('删除打分组件？'),
                content: const Text('打分项会被移除，正文和配图保留。'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('取消')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('删除'))
                ]));
    if (confirmed == true && mounted) {
      _score = null;
      _clearScoreImages();
      _changed();
    }
  }

  Future<void> _selectTopic() async {
    FocusScope.of(context).unfocus();
    final topic = await Navigator.push<TiebaComposeTopic>(context,
        appPageRoute(builder: (_) => ComposeTopicPage(fid: widget.fid)));
    if (mounted && topic != null && _active) {
      _topic = topic;
      _changed();
    }
  }

  Future<void> _loadPublisherConfig() async {
    setState(() {
      _configLoading = true;
      _configError = null;
    });
    try {
      final config = await Global.tiebaAPI.getPublisherConfig(fid: widget.fid);
      if (mounted) {
        setState(() {
          _publisherConfig = config;
          _configLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _configLoading = false;
          _configError = '暂时无法读取官方内容声明列表';
        });
      }
    }
  }

  Future<void> _selectRange() async {
    final result = await _sheet<bool>(
        '设置展示范围',
        Column(children: [
          for (final option in [
            (hide: false, label: '全场景可见', description: '吧内、个人主页均可见'),
            (hide: true, label: '个人主页不可见', description: '个人主页中该贴对其他用户不展示'),
          ])
            ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option.label),
                subtitle: Text(option.description),
                trailing: Icon(
                    _hideFromProfile == option.hide
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: TiebananaTokens.of(context).primary),
                onTap: () => Navigator.pop(context, option.hide)),
        ]));
    if (mounted && result != null && _active) {
      _hideFromProfile = result;
      _changed();
    }
  }

  Future<void> _selectStatement() async {
    if (_configLoading) {
      _message('正在读取官方发布配置，请稍候');
      return;
    }
    if (_configError != null) {
      await _sheet<void>(
          '内容声明',
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(_configError!),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadPublisherConfig();
                },
                child: const Text('重试读取')),
          ]));
      return;
    }
    final result = await _sheet<String>(
        '内容声明',
        Column(children: [
          const Text('选择一项内容声明，再次点击已选项可取消。'),
          for (final statement in _publisherConfig?.statements ?? <String>[])
            ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(statement),
                trailing: Icon(
                    _contentStatement == statement
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: TiebananaTokens.of(context).primary),
                onTap: () => Navigator.pop(
                    context, _contentStatement == statement ? '' : statement)),
          if (_contentStatement.isNotEmpty)
            TextButton(
                onPressed: () => Navigator.pop(context, ''),
                child: const Text('取消声明')),
          if (_publisherConfig?.statements.isEmpty ?? true)
            const Text('当前没有可选声明'),
        ]));
    if (mounted && result != null && _active) {
      _contentStatement = result;
      _changed();
    }
  }

  Future<void> _removePoll() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('确认要删除投票吗'),
                content: const Text('删除后已填写的投票内容不可恢复，正文与照片会保留。'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('取消')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('删除'))
                ]));
    if (confirmed == true && mounted) {
      _poll = null;
      _changed();
    }
  }

  Future<void> _editTail() async {
    final controller = TextEditingController(text: _tail);
    final result = await _sheet<({String text, bool enabled})>(
        '本帖的小尾巴',
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('放在正文末尾的一句话。此次修改仅用于本帖，不改变全局设置。'),
          const SizedBox(height: 16),
          TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(hintText: '留一句自己的话')),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: () => Navigator.pop(context, (
                    text: controller.text.trim(),
                    enabled: controller.text.trim().isNotEmpty
                  )),
              child: const Text('使用这个小尾巴')),
          TextButton(
              onPressed: () => Navigator.pop(
                  context, (text: controller.text.trim(), enabled: false)),
              child: const Text('本帖不添加')),
        ]));
    // modal 离场动画结束后再释放 TextField 控制器。
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (result != null && mounted) {
      _tail = result.text;
      _useTail = result.enabled;
      _changed();
    }
  }

  Future<void> _pickImages() async {
    if (!_sameAccount) {
      _message('当前账号已改变，请重新进入发帖页');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _emoji = false);
    final selection = await Navigator.push<List<dynamic>>(
        context, appPageRoute(builder: (_) => const ImagePickerRoute()));
    if (!mounted || selection == null || !_sameAccount) return;
    final assets = selection[0] as Set<AssetEntity>;
    final original = selection[1] as bool;
    for (final asset in assets) {
      final task = _images.enqueue(asset, original);
      unawaited(_images.upload(task));
    }
    if (assets.isNotEmpty) _changed();
  }

  Future<void> _publish() async {
    if (!_active || _publishUncertain) return;
    if (!_sameAccount || !Global.tiebaAPI.isLogin) {
      _message('当前登录状态已改变，请返回后重新登录');
      return;
    }
    if (_contentStatement.isNotEmpty &&
        (_configLoading ||
            _configError != null ||
            !(_publisherConfig?.statements.contains(_contentStatement) ??
                false))) {
      _message('请先重新读取官方配置并确认内容声明');
      return;
    }
    if (_images.hasPending || !_scoreReady || _unavailableImages.isNotEmpty) {
      _message('请先完成图片上传，或移除失败、失效的图片');
      return;
    }
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty ||
        (body.isEmpty &&
            _images.tasks.isEmpty &&
            _poll == null &&
            _score == null)) {
      _message('请填写标题和帖子内容');
      return;
    }
    final poll = _poll;
    if (_score != null &&
        (!(_publisherConfig?.scoreEnabled ?? false) ||
            ComposeScore.validate(_score!.items) != null)) {
      _message('请检查打分项或重新读取官方互动组件配置');
      return;
    }
    if (poll != null &&
        ComposePoll.validate(poll.title, poll.options) != null) {
      _message('请检查投票选项');
      return;
    }
    final content = StringBuffer(body);
    if (_topic != null && !body.contains('#${_topic!.name}#')) {
      content.write('\n#${_topic!.name}#');
    }
    for (final task in _images.tasks) {
      content.write(
          '\n${TiebaParser.contentBuilder(ContentBuilderType.Picture, image: task.result!)}');
    }
    if (_useTail && _tail.trim().isNotEmpty) content.write('\n\n$_tail');
    _saveTimer?.cancel();
    setState(() {
      _publishing = true;
      _publishError = null;
    });
    if (!await _save()) {
      if (mounted) {
        setState(() => _publishing = false);
        _message('请先成功保存草稿再发布，避免内容丢失');
      }
      return;
    }
    if (!mounted) return;
    if (!_sameAccount || !Global.tiebaAPI.isLogin) {
      setState(() => _publishing = false);
      _message('当前账号已改变，未提交帖子');
      return;
    }
    try {
      final protected =
          await Global.profile.setBool('$_draftKey.pending', true);
      if (!protected) throw StateError('无法保存发布保护状态，未发送请求');
      final result = await Global.tiebaAPI.publishThread(
          fid: widget.fid,
          forumName: widget.forumName,
          title: title,
          content: content.toString(),
          imageCount: _images.tasks.length,
          poll: poll == null
              ? null
              : TiebaPublishPoll(
                  title: poll.title,
                  options: List.of(poll.options),
                  multiple: poll.multiple,
                  days: poll.days),
          topicId: _topic?.id,
          hideFromProfile: _hideFromProfile,
          contentStatement: _contentStatement,
          score: _score == null
              ? null
              : TiebaPublishScore(levelLimit: _score!.levelLimit, items: [
                  for (final item in _score!.items)
                    (() {
                      final image = _scoreImages.tasks
                          .firstWhere((t) => t.asset.id == item.assetId)
                          .result!;
                      return TiebaPublishScoreItem(
                          title: item.title,
                          content: item.content,
                          image: TiebaParser.contentBuilder(
                              ContentBuilderType.Picture,
                              image: image),
                          imageSource: image.url ?? '');
                    })()
                ]));
      if (result.tid.isEmpty || !RegExp(r'^[1-9]\d*$').hasMatch(result.tid)) {
        throw const TiebaPublishUncertain('未取得有效帖子 ID，请先查看个人主页，避免重复提交。');
      }
      _published = result;
      bool removed = false;
      try {
        removed = await Global.profile.remove(_draftKey);
        if (removed) await Global.profile.remove('$_draftKey.pending');
      } catch (_) {/* 不重复发布。 */}
      if (!mounted) return;
      setState(() {
        _publishing = false;
        _dirty = false;
        _publishError = removed ? null : '帖子已发布，但本机草稿未能清除，请勿重复发布。';
      });
      if (!_sameAccount) {
        _message('原账号的帖子已提交，当前账号已切换；帖子 ID：${result.tid}');
        return;
      }
      if (!removed) return;
      if (result.message.isNotEmpty) _message(result.message);
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, PageRouter.threadPage,
            arguments: ThreadPageRouterData(kz: result.tid, pid: null));
      });
    } catch (error, stack) {
      AppLog.shared.error('publish.thread_failed', error, stack);
      if (!mounted) return;
      setState(() {
        _publishing = false;
        _publishUncertain = error is TiebaPublishUncertain;
        _publishError = error is NetAPIError
            ? error.errorMessage ?? '发布失败，请稍后重试'
            : error.toString();
      });
      if (!_publishUncertain) {
        try {
          await Global.profile.remove('$_draftKey.pending');
        } catch (_) {/* 下次保守提示确认。 */}
      }
    }
  }

  Future<void> _confirmRetry() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('确认未产生新帖子？'),
                content: const Text(
                    '请先检查个人主页及目标吧。审核中的帖子可能暂时不可见，重新发布仍有重复风险。确定未发布后才解除保护。'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('继续核对')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('确认未发布，解除保护'))
                ]));
    if (confirmed != true || !mounted) return;
    try {
      final removed = await Global.profile.remove('$_draftKey.pending');
      if (!removed) throw StateError('解除保护失败');
      if (mounted) {
        setState(() {
          _publishUncertain = false;
          _publishError = null;
        });
      }
    } catch (_) {
      _message('无法解除发布保护，请稍后重试');
    }
  }

  Future<void> _preview() => _sheet<void>(
      '发布前，先看一眼',
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${widget.forumName}吧 · 帖子预览',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: TiebananaTokens.of(context).primary)),
        const SizedBox(height: 16),
        Text(_title.text.isEmpty ? '还没有标题' : _title.text,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        ExtendedText(_body.text.isEmpty ? '还没有正文' : _body.text,
            specialTextSpanBuilder: TiebaSpanBuilder(),
            style: Theme.of(context).textTheme.bodyLarge),
        if (_topic != null)
          Text('#${_topic!.name}#',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: TiebananaTokens.of(context).primary)),
        if (_images.tasks.isNotEmpty) ...[
          const SizedBox(height: 16),
          _imageGrid(preview: true),
        ],
        if (_poll != null) _pollCard(preview: true),
        if (_score != null) _scoreCard(preview: true),
        if (_useTail && _tail.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text('—— $_tail',
                  style: Theme.of(context).textTheme.bodySmall)),
        const SizedBox(height: 24),
        Text(_hideFromProfile ? '个人主页不可见' : '全场景可见',
            style: Theme.of(context).textTheme.bodySmall),
        if (_contentStatement.isNotEmpty)
          Text(_contentStatement, style: Theme.of(context).textTheme.bodySmall),
        Text('发布前内容预览，尚未提交到贴吧。',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: TiebananaTokens.of(context).textTertiary)),
      ]));

  @override
  Widget build(BuildContext context) {
    final tokens = TiebananaTokens.of(context);
    final text = Theme.of(context).textTheme;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final canPublish = _active &&
        !_publishUncertain &&
        _title.text.trim().isNotEmpty &&
        (_body.text.trim().isNotEmpty ||
            _images.tasks.isNotEmpty ||
            _poll != null ||
            _score != null) &&
        !_images.hasPending &&
        _scoreReady &&
        _unavailableImages.isEmpty;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: tokens.bg,
        appBar: AppBar(
          backgroundColor: tokens.bg,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
              tooltip: '关闭发帖',
              onPressed: _active ? _leave : null,
              icon: const Icon(Icons.close_rounded)),
          title: const Text('发帖'),
          centerTitle: false,
          actions: [
            Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                    onPressed: canPublish ? _publish : null,
                    icon: _publishing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_outlined, size: 16),
                    label: Text(_publishing ? '发布中' : '发布')))
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                Expanded(
                    child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                      Padding(
                          padding: const EdgeInsets.fromLTRB(19, 8, 19, 18),
                          child: Row(children: [
                            Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                    color: tokens.primaryContainer,
                                    borderRadius: TiebananaMetrics.brCtl),
                                child: Icon(Icons.forum_outlined,
                                    color: tokens.primary)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('发布到',
                                      style: text.labelSmall?.copyWith(
                                          color: tokens.textTertiary)),
                                  Text('${widget.forumName}吧',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.titleSmall),
                                ])),
                            const SizedBox(width: 8),
                            Chip(
                                label: Text('当前吧', style: text.labelSmall),
                                side: BorderSide.none,
                                backgroundColor: tokens.fill,
                                visualDensity: VisualDensity.compact),
                          ])),
                      Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                          decoration: BoxDecoration(
                              color: tokens.surface,
                              borderRadius: TiebananaMetrics.brXl,
                              boxShadow: tokens.cardShadow),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                    key: const ValueKey('compose-title'),
                                    controller: _title,
                                    enabled: _active,
                                    minLines: 1,
                                    maxLines: null,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) =>
                                        _bodyFocus.requestFocus(),
                                    style: text.headlineSmall,
                                    decoration: _inputDecoration('给你的帖子起个标题')),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    child:
                                        Divider(height: 1, color: tokens.line)),
                                ExtendedTextField(
                                    key: const ValueKey('compose-body'),
                                    controller: _body,
                                    focusNode: _bodyFocus,
                                    readOnly: !_active,
                                    minLines: keyboard ? 3 : 5,
                                    maxLines: null,
                                    specialTextSpanBuilder: TiebaSpanBuilder(),
                                    style: text.bodyLarge?.copyWith(
                                        height: 1.9,
                                        color: tokens.textSecondary),
                                    decoration:
                                        _inputDecoration('分享新鲜事，也记录小日常…')),
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                        onPressed:
                                            _active ? _selectTopic : null,
                                        icon: const Icon(Icons.tag, size: 17),
                                        label: const Text('添加话题'))),
                                if (_topic != null)
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: InputChip(
                                          label: Text('# ${_topic!.name}'),
                                          onDeleted: _active
                                              ? () {
                                                  _topic = null;
                                                  _changed();
                                                }
                                              : null)),
                                if (_images.tasks.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text('配图 · ${_images.tasks.length} 张',
                                      style: text.labelSmall?.copyWith(
                                          color: tokens.textTertiary)),
                                  const SizedBox(height: 10),
                                  _imageGrid(),
                                ],
                                if (_unavailableImages.isNotEmpty)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                '${_unavailableImages.length} 张草稿图片已失效或没有访问权限，请重新选择。',
                                                style: text.bodySmall?.copyWith(
                                                    color: tokens.danger)),
                                            TextButton(
                                                onPressed: () {
                                                  _unavailableImages.clear();
                                                  _changed();
                                                },
                                                child: const Text('移除失效图片引用')),
                                          ])),
                                if (_poll != null) _pollCard(),
                                if (_score != null) _scoreCard(),
                                const SizedBox(height: 14),
                                Row(children: [
                                  Icon(
                                      _draftSaved && !_dirty
                                          ? Icons.check_rounded
                                          : Icons.edit_outlined,
                                      size: 13,
                                      color: tokens.primary),
                                  const SizedBox(width: 5),
                                  Expanded(
                                      child: Text(
                                          _saving
                                              ? '正在保存…'
                                              : _storageError != null
                                                  ? '草稿未保存'
                                                  : _draftSaved && !_dirty
                                                      ? '草稿已暂存 · 仅本机'
                                                      : _dirty
                                                          ? '未保存的修改'
                                                          : '仅自己可见的创作空间',
                                          style: text.labelSmall?.copyWith(
                                              color: tokens.textTertiary))),
                                  Text('${_body.text.runes.length} 字',
                                      style: text.labelSmall?.copyWith(
                                          color: tokens.textTertiary)),
                                ]),
                              ])),
                      if (_publishError != null)
                        Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_publishError!,
                                      style: text.bodySmall
                                          ?.copyWith(color: tokens.danger)),
                                  if (_publishUncertain)
                                    const Text(
                                        '结果未确认，已暂停再次发布。请先到个人主页核对，草稿仍保留。'),
                                  if (_publishUncertain)
                                    TextButton(
                                        onPressed: _confirmRetry,
                                        child: const Text('已核对主页，申请重新发布')),
                                  if (_published != null)
                                    Text('帖子 ID：${_published!.tid}'),
                                ])),
                      if (_storageError != null)
                        Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(children: [
                              Text(_storageError!,
                                  style: text.bodySmall
                                      ?.copyWith(color: tokens.danger)),
                              if (_dirty)
                                TextButton(
                                    onPressed: _saving ? null : _save,
                                    child: const Text('重试保存')),
                            ])),
                      if (!keyboard) ...[
                        SettingGroup(children: [
                          SettingRow(
                              icon: Icons.poll_outlined,
                              title: '互动组件',
                              value: _score != null
                                  ? '已添加打分'
                                  : _poll == null
                                      ? '投票 / 打分'
                                      : '已添加投票',
                              showChevron: true,
                              onTap: _active ? _interactions : null)
                        ]),
                        SettingGroup(children: [
                          SettingRow(
                              icon: Icons.visibility_outlined,
                              title: '展示范围',
                              value: _hideFromProfile ? '个人主页不可见' : '全场景可见',
                              showChevron: true,
                              onTap: _active ? _selectRange : null),
                          SettingRow(
                              icon: Icons.verified_user_outlined,
                              title: '内容声明',
                              value: _contentStatement.isNotEmpty
                                  ? _contentStatement
                                  : _configLoading
                                      ? '读取中'
                                      : _configError != null
                                          ? '读取失败'
                                          : '不声明',
                              showChevron: true,
                              onTap: _active ? _selectStatement : null),
                        ]),
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: SettingRow(
                                icon: Icons.sell_outlined,
                                title: '小尾巴',
                                subtitle: _useTail ? _tail : '本帖不添加',
                                showChevron: true,
                                onTap: _active ? _editTail : null)),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                                _published != null
                                    ? '帖子已提交，请勿重复发布'
                                    : '发布即提交到贴吧，请确认内容与配图',
                                style: text.labelSmall
                                    ?.copyWith(color: tokens.textTertiary))),
                      ],
                    ])),
                _toolbar(keyboard),
              ]),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: TiebananaTokens.of(context).textTertiary),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      );

  Widget _toolbar(bool keyboard) {
    final tokens = TiebananaTokens.of(context);
    return Container(
      decoration: BoxDecoration(
          color: tokens.bar,
          border: Border(top: BorderSide(color: tokens.line))),
      child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(children: [
                  IconButton(
                      tooltip: '添加图片',
                      onPressed: _active ? _pickImages : null,
                      color: tokens.primary,
                      icon: const Icon(Icons.image_outlined)),
                  IconButton(
                      tooltip: '表情',
                      onPressed: _active
                          ? () {
                              FocusScope.of(context).unfocus();
                              setState(() => _emoji = !_emoji);
                            }
                          : null,
                      icon: const Icon(Icons.emoji_emotions_outlined)),
                  IconButton(
                      tooltip: '互动组件',
                      onPressed: _active ? _interactions : null,
                      icon: const Icon(Icons.add_circle_outline)),
                  const Spacer(),
                  if (keyboard || _emoji)
                    IconButton(
                        tooltip: '收起键盘',
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          setState(() => _emoji = false);
                        },
                        icon: const Icon(Icons.keyboard_hide_outlined))
                  else
                    TextButton.icon(
                        onPressed: _active ? _preview : null,
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('预览')),
                ])),
            if (_emoji)
              SizedBox(
                  height: 240,
                  child: EmojiPanel(controller: _body, height: 240)),
          ])),
    );
  }

  Widget _scoreCard({bool preview = false}) {
    final score = _score!;
    final tokens = TiebananaTokens.of(context);
    return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: tokens.fill, borderRadius: TiebananaMetrics.brMd),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: Text('打分 · ${score.items.length} 项',
                    style: Theme.of(context).textTheme.titleSmall)),
            if (!preview) ...[
              IconButton(
                  tooltip: '编辑打分',
                  onPressed: _active ? _editScore : null,
                  icon: const Icon(Icons.edit_outlined, size: 18)),
              IconButton(
                  tooltip: '删除打分',
                  onPressed: _active ? _removeScore : null,
                  icon: const Icon(Icons.close, size: 18))
            ]
          ]),
          for (final item in score.items)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: 64,
                          height: 64,
                          child: Builder(builder: (context) {
                            final tasks = _scoreImages.tasks
                                .where((t) => t.asset.id == item.assetId);
                            if (tasks.isEmpty) {
                              return Icon(Icons.broken_image_outlined,
                                  color: tokens.danger);
                            }
                            return _ComposeImageTile(
                                key: ValueKey('score.${item.assetId}'),
                                task: tasks.first,
                                index: score.items.indexOf(item),
                                preview: preview,
                                onRemove: () {},
                                allowRemove: false,
                                onRetry: () {
                                  if (_active && _sameAccount) {
                                    unawaited(_scoreImages.upload(tasks.first));
                                  }
                                });
                          })),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(item.title,
                                style: Theme.of(context).textTheme.bodyMedium),
                            if (item.content.isNotEmpty)
                              Text(item.content,
                                  style: Theme.of(context).textTheme.bodySmall),
                          ]))
                    ])),
          Text(
              score.levelLimit == 0
                  ? '所有人均可打分'
                  : 'Lv.${score.levelLimit} 及以上吧友可打分',
              style: Theme.of(context).textTheme.labelSmall),
          if (!_scoreReady && !preview)
            Text('请上传所有打分图片；失效图片请重新编辑组件。',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: tokens.danger)),
        ]));
  }

  Widget _pollCard({bool preview = false}) {
    final poll = _poll!;
    final tokens = TiebananaTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: tokens.fill,
            borderRadius: TiebananaMetrics.brMd,
            border: Border.all(color: tokens.line)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(Icons.poll_outlined, size: 16, color: tokens.primary),
            const SizedBox(width: 6),
            Expanded(
                child: Text('投票 · ${poll.multiple ? '多选' : '单选'}',
                    style: text.labelMedium)),
            if (!preview) ...[
              IconButton(
                  tooltip: '编辑投票',
                  onPressed: _active ? _editPoll : null,
                  icon: const Icon(Icons.edit_outlined, size: 18)),
              IconButton(
                  tooltip: '删除投票',
                  onPressed: _active ? _removePoll : null,
                  icon: const Icon(Icons.close, size: 18)),
            ],
          ]),
          Text(poll.title, style: text.titleSmall),
          const SizedBox(height: 10),
          for (int i = 0; i < poll.options.length; i++)
            Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: tokens.surface, borderRadius: TiebananaMetrics.brSm),
                child: Row(children: [
                  Text('${i + 1}', style: text.labelSmall),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(poll.options[i], style: text.bodyMedium)),
                  Icon(
                      poll.multiple
                          ? Icons.check_box_outline_blank
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: tokens.textTertiary),
                ])),
          Text('${poll.days == -1 ? '不限时' : '${poll.days} 天有效'} · 仅本机草稿',
              style: text.labelSmall?.copyWith(color: tokens.textTertiary)),
        ]));
  }

  Widget _imageGrid({bool preview = false}) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: _images.tasks.length,
        itemBuilder: (context, index) {
          final task = _images.tasks[index];
          return _ComposeImageTile(
              key: ValueKey(task.asset.id),
              task: task,
              index: index,
              preview: preview,
              onRetry: () {
                if (_sameAccount && _active) {
                  unawaited(_images.upload(task));
                }
              },
              onRemove: () {
                if (_active) {
                  _images.remove(task);
                  _changed();
                }
              });
        },
      );
}

class _ComposeImageTile extends StatefulWidget {
  const _ComposeImageTile(
      {super.key,
      required this.task,
      required this.index,
      required this.onRetry,
      required this.onRemove,
      this.preview = false,
      this.allowRemove = true});
  final ImageUploadTask task;
  final int index;
  final VoidCallback onRetry;
  final VoidCallback onRemove;
  final bool preview;
  final bool allowRemove;
  @override
  State<_ComposeImageTile> createState() => _ComposeImageTileState();
}

class _ComposeImageTileState extends State<_ComposeImageTile> {
  late final _thumbnail =
      widget.task.asset.thumbnailDataWithSize(const ThumbnailSize(240, 240));
  @override
  Widget build(BuildContext context) {
    final tokens = TiebananaTokens.of(context);
    final task = widget.task;
    return ClipRRect(
        borderRadius: TiebananaMetrics.brSm,
        child: Stack(fit: StackFit.expand, children: [
          ColoredBox(
              color: tokens.fill,
              child: FutureBuilder(
                  future: _thumbnail,
                  builder: (context, snapshot) => snapshot.data == null
                      ? const Icon(Icons.image_outlined)
                      : Image.memory(snapshot.data!, fit: BoxFit.cover))),
          if (!widget.preview && task.result == null)
            ColoredBox(
                color: tokens.surface.withValues(alpha: .9),
                child: Center(
                    child: task.uploading
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  LinearProgressIndicator(
                                      value: task.total > 0
                                          ? task.sent / task.total
                                          : null),
                                  const SizedBox(height: 6),
                                  Text(
                                      task.total > 0
                                          ? '${(task.sent * 100 / task.total).floor()}%'
                                          : '上传中',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall),
                                ]))
                        : IconButton(
                            tooltip: task.error == null ? '上传图片' : '上传失败，点击重试',
                            onPressed: widget.onRetry,
                            icon: Icon(Icons.refresh,
                                color: task.error == null
                                    ? tokens.primary
                                    : tokens.danger)))),
          if (!widget.preview && widget.allowRemove && !task.uploading)
            Positioned(
                right: 0,
                top: 0,
                child: IconButton.filledTonal(
                    tooltip: '移除图片 ${widget.index + 1}',
                    constraints:
                        const BoxConstraints(minWidth: 30, minHeight: 30),
                    padding: const EdgeInsets.all(4),
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.close, size: 15))),
          Positioned(
              left: 5,
              bottom: 5,
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: TiebananaMetrics.brXs),
                  child: Text('${widget.index + 1}',
                      style: Theme.of(context).textTheme.labelSmall))),
        ]));
  }
}
