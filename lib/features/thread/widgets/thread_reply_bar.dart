import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/thread/state/reply_events.dart';
import 'package:tiebanana/core/platform/official_tieba.dart';
import 'package:tiebanana/shared/content/posting_risk_warning.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/features/media/state/image_upload.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/thread/pages/thread_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/content/emoji_panel.dart';
import 'package:tiebanana/shared/content/special_span.dart';
import 'package:tiebanana/features/thread/widgets/thread_common.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';

/// 帖子底部回复条。
///
/// 对应概念图 `design/mockups/thread.html` 的 `.tbar`：
/// 左侧是回复入口药丸，右侧是主题赞 / 踩 / 收藏（图标在上、数量在下）。
/// 发送按钮只出现在回复弹层里。
class ThreadReplyBar extends StatelessWidget {
  final String fid;
  final String tid;
  final String kw;
  final String replyText;
  final ValueNotifier<bool> storedNotifier;
  final ThreadAgreeController? agreeController;
  final int storeCount;
  final bool initiallyStored;

  const ThreadReplyBar({
    super.key,
    required this.fid,
    required this.tid,
    required this.kw,
    required this.replyText,
    required this.storedNotifier,
    this.agreeController,
    this.storeCount = 0,
    this.initiallyStored = false,
  });

  void _openReply(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => ReplyBottomSheet(
        replyText: replyText,
        threadTitle: replyText,
        kw: kw,
        fid: fid,
        tid: tid,
        isReplyThread: true,
      ),
    );
  }

  Future<void> _toggleStore(BuildContext context) async {
    final ThreadPageMainState? page =
        context.findAncestorStateOfType<ThreadPageMainState>();
    final bool next = !storedNotifier.value;
    final uid = page?.cacheUid ?? AccountStore.currentUid ?? '';
    try {
      if (next) {
        await Global.tiebaAPI.threadAddStore(tid, page?.pid ?? '');
      } else {
        await Global.tiebaAPI.threadRemoveStore(tid);
      }
      await Global.threadCache.setStored(uid, tid, next,
          keepLongTerm: Global.setting.markedCache ?? true);
      if (!context.mounted) return;
      storedNotifier.value = next;
      page?.isStored = next;
      Fluttertoast.showToast(msg: next ? '收藏成功' : '取消收藏');
    } catch (e) {
      if (!context.mounted) return;
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: tokens.bar,
        border: Border(top: BorderSide(color: tokens.line)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: tokens.shadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: _ReplyEntryPill(
                onTap: () => _openReply(context),
              ),
            ),
            if (agreeController != null) ...<Widget>[
              const SizedBox(width: TiebananaMetrics.gapSm),
              ThreadLikeAction(controller: agreeController!),
              const SizedBox(width: TiebananaMetrics.gapSm),
              ThreadLikeAction(controller: agreeController!, isDislike: true),
            ],
            const SizedBox(width: TiebananaMetrics.gapSm),
            ValueListenableBuilder<bool>(
              valueListenable: storedNotifier,
              builder: (BuildContext context, bool stored, Widget? child) {
                return _RoundAction(
                  active: stored,
                  icon: stored ? Icons.star_rounded : Icons.star_border_rounded,
                  label: threadCountText((storeCount +
                          (stored ? 1 : 0) -
                          (initiallyStored ? 1 : 0))
                      .clamp(0, 1 << 53)),
                  tooltip: stored ? '取消收藏' : '收藏',
                  onTap: () => _toggleStore(context),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 楼中楼面板里的底部回复条。
class InnerFloorReplyBar extends StatelessWidget {
  final TiebaAuthor author;
  final TiebaForum forum;
  final String threadID;
  final TiebaPost postMain;

  const InnerFloorReplyBar({
    super.key,
    required this.author,
    required this.forum,
    required this.threadID,
    required this.postMain,
  });

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: tokens.bar,
        border: Border(top: BorderSide(color: tokens.line)),
      ),
      child: SafeArea(
        top: false,
        child: _ReplyEntryPill(
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (BuildContext context) => ReplyBottomSheet(
                replyText: TiebaParser.parserContentString(postMain.content),
                targetName: author.name,
                targetMeta: '楼中楼回复',
                threadTitle: '',
                kw: forum.forumName,
                fid: forum.fid,
                tid: threadID,
                floorId: postMain.id,
                isReplyThread: false,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReplyEntryPill extends StatelessWidget {
  const _ReplyEntryPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brPill,
        boxShadow: tokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: TiebananaMetrics.brPill,
        child: InkWell(
          borderRadius: TiebananaMetrics.brPill,
          onTap: onTap,
          child: SizedBox(
            height: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Icon(Icons.edit_outlined,
                      size: 18, color: tokens.textSecondary),
                  const SizedBox(width: TiebananaMetrics.gapSm),
                  Expanded(
                    child: Text(
                      '写回复…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: tokens.textTertiary),
                    ),
                  ),
                  Icon(Icons.emoji_emotions_outlined,
                      size: 20, color: tokens.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tooltip,
  });

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Color foreground =
        active ? tokens.onPrimaryContainer : tokens.textSecondary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? tokens.primaryContainer : tokens.fill,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(height: 2),
                SizedBox(
                  width: 40,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: foreground,
                            height: 1,
                          ),
                    ),
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

/// 回复弹层。
///
/// [replyText] 是被回复的正文（引用块），[targetName] / [targetMeta] 用于标题；
/// [isReplyThread] 为 true 时表示回复主题，隐藏引用块。
class ReplyBottomSheet extends StatefulWidget {
  final String replyText;
  final String? targetName;
  final String? targetMeta;
  final String? threadTitle;
  final String kw;
  final String fid;
  final String tid;
  final bool isReplyThread;
  final String? floorId;
  final TiebaAuthor? replyUser;

  const ReplyBottomSheet({
    super.key,
    required this.replyText,
    this.targetName,
    this.targetMeta,
    this.threadTitle,
    required this.kw,
    required this.fid,
    required this.tid,
    required this.isReplyThread,
    this.floorId,
    this.replyUser,
  });

  @override
  State<ReplyBottomSheet> createState() => _ReplyBottomSheetState();
}

class _ReplyBottomSheetState extends State<ReplyBottomSheet>
    with WidgetsBindingObserver {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  late final ImageUploadProviderModel imagesUpload;
  bool emojiInputActive = false;
  bool imageInputActive = false;
  final double _keyboardHeight = 267;
  double _lastKeyboardInset = 0;
  late bool _riskAcknowledged;

  bool get showCustomKeyBoard => emojiInputActive || imageInputActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    imagesUpload = ImageUploadProviderModel(widget.kw);
    controller.addListener(_onTextChanged);
    _riskAcknowledged = !Global.setting.showPostingRiskWarning;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showPostingRiskWarning(
          context,
          OfficialTiebaTarget(
              forumName: widget.kw, tid: widget.tid, pid: widget.floorId));
      if (!mounted) return;
      setState(() => _riskAcknowledged = true);
      focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_onTextChanged);
    controller.dispose();
    focusNode.dispose();
    imagesUpload.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void didChangeMetrics() {
    final double inset = View.of(context).viewInsets.bottom;
    if (inset > _lastKeyboardInset && showCustomKeyBoard) {
      setState(() {
        emojiInputActive = false;
        imageInputActive = false;
      });
    }
    _lastKeyboardInset = inset;
  }

  void insertText(String text) {
    final TextEditingValue value = controller.value;
    final int start = value.selection.baseOffset;
    int end = value.selection.extentOffset;
    if (value.selection.isValid) {
      String newText = '';
      if (value.selection.isCollapsed) {
        if (end > 0) {
          newText += value.text.substring(0, end);
        }
        newText += text;
        if (value.text.length > end) {
          newText += value.text.substring(end, value.text.length);
        }
      } else {
        newText = value.text.replaceRange(start, end, text);
        end = start;
      }

      controller.value = value.copyWith(
        text: newText,
        selection: value.selection.copyWith(
          baseOffset: end + text.length,
          extentOffset: end + text.length,
        ),
      );
    } else {
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.fromPosition(
          TextPosition(offset: text.length),
        ),
      );
    }
  }

  void _toggleImagePanel() {
    _togglePanel(image: true);
  }

  void _toggleEmojiPanel() {
    _togglePanel(image: false);
  }

  void _togglePanel({required bool image}) {
    final bool closing = image ? imageInputActive : emojiInputActive;
    if (closing) {
      focusNode.requestFocus();
    } else {
      focusNode.unfocus();
    }
    setState(() {
      imageInputActive = image && !closing;
      emojiInputActive = !image && !closing;
    });
  }

  Future<void> _clear() async {
    final bool? action = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: TiebananaMetrics.brLg),
          title: const Text('确认'),
          content: const Text('是否清空输入？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
    if (action == true) {
      controller.clear();
    }
  }

  Future<void> _send() async {
    if (imagesUpload.hasPending) {
      Fluttertoast.showToast(msg: '请等待图片上传完成，或重试/移除失败图片');
      setState(() {
        imageInputActive = true;
        emojiInputActive = false;
      });
      return;
    }
    final String text = controller.text.trim();
    final photos = imagesUpload.pictures.keys
        .where((image) => text.contains(TiebaParser.contentBuilder(
            ContentBuilderType.Picture,
            image: image)))
        .map((image) => image.picId)
        .toList();
    if (text.isEmpty) {
      Fluttertoast.showToast(msg: '说点什么吧');
      return;
    }
    if (text.length > 2000) {
      Fluttertoast.showToast(msg: '回复最多 2000 字');
      return;
    }
    try {
      assert(!(widget.isReplyThread == false && widget.floorId == null));
      late String msg;
      if (widget.isReplyThread) {
        msg = await Global.tiebaAPI.replyThread(
          text,
          widget.kw,
          widget.fid,
          widget.tid,
          photos: photos,
        );
      } else if (widget.replyUser == null) {
        msg = await Global.tiebaAPI.replyFloor(
          text,
          widget.kw,
          widget.fid,
          widget.tid,
          widget.floorId!,
          photos: photos,
        );
      } else {
        msg = await Global.tiebaAPI.replyFloor(
          '${TiebaParser.contentBuilder(ContentBuilderType.Reply, replyUser: widget.replyUser)}'
          '$text',
          widget.kw,
          widget.fid,
          widget.tid,
          widget.floorId!,
          replyUID: widget.replyUser!.id,
          photos: photos,
        );
      }
      Fluttertoast.showToast(msg: msg.isNotEmpty ? msg : '发送成功');
      if (mounted) {
        Navigator.pop(context);
      }
      replyEvents.sent(widget.tid,
          pid: widget.isReplyThread ? null : widget.floorId);
    } catch (e, stack) {
      AppLog.shared.error('publish.reply_failed', e, stack);
      if (!mounted) return;
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  String get _headerTitle {
    if (widget.isReplyThread) {
      return '回复主题';
    }
    final String? name = widget.targetName;
    if (name == null || name.isEmpty) {
      return '回复';
    }
    return '回复 @$name';
  }

  Future<void> _uploadTask(ImageUploadTask task) async {
    final image = await imagesUpload.upload(task);
    if (!mounted || image == null) return;
    insertText(
        TiebaParser.contentBuilder(ContentBuilderType.Picture, image: image));
  }

  void _removeImage(ImageUploadTask task) {
    if (task.uploading) return;
    final image = task.result;
    if (image != null) {
      controller.text = controller.text.replaceAll(
          TiebaParser.contentBuilder(ContentBuilderType.Picture, image: image),
          '');
    }
    imagesUpload.remove(task);
  }

  String get _headerSub {
    final String meta = widget.targetMeta ?? '';
    if (meta.isNotEmpty) {
      return meta;
    }
    return widget.threadTitle ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final MediaQueryData media = MediaQuery.of(context);
    final double keyboardHeight = media.viewInsets.bottom;
    final String scene = widget.targetMeta ?? '';
    final String quoteTitle =
        scene.contains('·') ? '原回复 · ${scene.split('·').first.trim()}' : '原回复';

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        constraints: BoxConstraints(
          maxHeight:
              (media.size.height - media.viewPadding.top - keyboardHeight)
                  .clamp(0.0, double.infinity),
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(26),
          ),
        ),
        child: ChangeNotifierProvider<ImageUploadProviderModel>.value(
          value: imagesUpload,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  //标题
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (!widget.isReplyThread &&
                                  (widget.targetName?.isNotEmpty ?? false))
                                Text.rich(
                                  TextSpan(
                                    children: <InlineSpan>[
                                      const TextSpan(text: '回复 '),
                                      TextSpan(
                                        text: '@${widget.targetName}',
                                        style: TextStyle(color: tokens.primary),
                                      ),
                                    ],
                                  ),
                                  style: textTheme.titleSmall
                                      ?.copyWith(color: tokens.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              else
                                Text(
                                  _headerTitle,
                                  style: textTheme.titleSmall
                                      ?.copyWith(color: tokens.textPrimary),
                                ),
                              if (_headerSub.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 3),
                                Text(
                                  _headerSub,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelSmall
                                      ?.copyWith(color: tokens.textTertiary),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Material(
                          color: tokens.fill,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.pop(context),
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(
                                Icons.close_rounded,
                                size: 19,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  //引用
                  if (!widget.isReplyThread && widget.replyText.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: tokens.fill,
                        borderRadius: TiebananaMetrics.brCtl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            quoteTitle,
                            style: textTheme.labelSmall
                                ?.copyWith(color: tokens.textTertiary),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.replyText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall
                                ?.copyWith(color: tokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  //输入区
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 12, 10, 6),
                      decoration: BoxDecoration(
                        color: tokens.surfaceAlt,
                        borderRadius: TiebananaMetrics.brLg,
                      ),
                      child: Column(
                        children: <Widget>[
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: 62,
                              maxHeight: 160,
                            ),
                            child: Consumer<ImageUploadProviderModel>(
                              builder: (
                                BuildContext context,
                                ImageUploadProviderModel value,
                                Widget? child,
                              ) {
                                return ExtendedTextField(
                                  specialTextSpanBuilder:
                                      TiebaSpanBuilder(uploadImages: value),
                                  controller: controller,
                                  maxLines: 7,
                                  minLines: 3,
                                  style: textTheme.bodyLarge
                                      ?.copyWith(color: tokens.textPrimary),
                                  maxLength: 2000,
                                  buildCounter: (
                                    BuildContext context, {
                                    required int currentLength,
                                    required int? maxLength,
                                    required bool isFocused,
                                  }) =>
                                      null,
                                  focusNode: focusNode,
                                  autofocus: _riskAcknowledged,
                                  onTap: () {
                                    if (!showCustomKeyBoard) return;
                                    setState(() {
                                      emojiInputActive = false;
                                      imageInputActive = false;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: widget.isReplyThread
                                        ? '写点什么…'
                                        : (widget.targetName?.isNotEmpty ??
                                                false)
                                            ? '回复 @${widget.targetName}…'
                                            : '写点什么…',
                                    hintStyle: textTheme.bodyLarge
                                        ?.copyWith(color: tokens.textTertiary),
                                    isCollapsed: true,
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: <Widget>[
                              _ToolButton(
                                icon: Icons.emoji_emotions_outlined,
                                active: emojiInputActive,
                                onTap: _toggleEmojiPanel,
                              ),
                              _ToolButton(
                                icon: Icons.image_outlined,
                                active: imageInputActive,
                                onTap: _toggleImagePanel,
                              ),
                              _ToolButton(
                                icon: Icons.backspace_outlined,
                                onTap: _clear,
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  '${controller.text.length} / 2000',
                                  style: textTheme.labelSmall
                                      ?.copyWith(color: tokens.textTertiary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  //底部：提示 + 发送
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.check_circle_outline_rounded,
                            size: 14, color: tokens.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '友善发言，理性讨论',
                            style: textTheme.labelSmall
                                ?.copyWith(color: tokens.textTertiary),
                          ),
                        ),
                        _SendButton(onTap: _send),
                      ],
                    ),
                  ),
                  //表情 / 图片面板
                  if (showCustomKeyBoard)
                    Consumer<ImageUploadProviderModel>(
                      builder: (
                        BuildContext context,
                        ImageUploadProviderModel value,
                        Widget? child,
                      ) {
                        if (emojiInputActive) {
                          return child!;
                        }
                        return SizedBox(
                          height: _keyboardHeight,
                          child: ImagePanel(
                            uploaded: value.pictures,
                            tasks: value.tasks,
                            onRetry: _uploadTask,
                            onRemove: _removeImage,
                            onAddImage: () async {
                              setState(() => imageInputActive = false);
                              final dynamic data = await Navigator.pushNamed(
                                context,
                                PageRouter.imagePicker,
                              );
                              if (!mounted) return;
                              if (data != null) {
                                final Set<AssetEntity> pic =
                                    (data as List)[0] as Set<AssetEntity>;
                                final bool saveOrigin = data[1] as bool;
                                setState(() => imageInputActive = true);
                                final tasks = [
                                  for (final p in pic)
                                    imagesUpload.enqueue(p, saveOrigin),
                                ];
                                for (final task in tasks) {
                                  if (!mounted) return;
                                  await _uploadTask(task);
                                }
                              }
                            },
                          ),
                        );
                      },
                      child: SizedBox(
                        height: _keyboardHeight,
                        child: EmojiPanel(
                          controller: controller,
                          height: _keyboardHeight,
                        ),
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
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Material(
      color: active ? tokens.primaryContainer : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 20,
            color: active ? tokens.onPrimaryContainer : tokens.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Material(
      color: tokens.accentFill,
      borderRadius: TiebananaMetrics.brPill,
      child: InkWell(
        borderRadius: TiebananaMetrics.brPill,
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Center(
              child: Text(
                '发送',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: tokens.accentOn,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
