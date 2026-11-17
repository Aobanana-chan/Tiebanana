import 'dart:async';
import 'dart:math' as math;

import 'package:extended_text/extended_text.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:tiebanana/features/message/state/chat_error.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/message/models/chat_route_data.dart';
import 'package:tiebanana/features/message/state/chat_time.dart';
import 'package:tiebanana/features/message/state/chat_content.dart';
import 'package:tiebanana/features/message/state/message_reminder.dart';
import 'package:tiebanana/features/message/widgets/chat_settings_sheet.dart';
import 'package:tiebanana/features/message/widgets/chat_notice_card.dart';
import 'package:tiebanana/shared/content/emoji_panel.dart';
import 'package:tiebanana/shared/content/special_span.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/avatar_image.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';
import 'package:url_launcher/url_launcher.dart';

/// 聊天页。
class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.data});

  final ChatRouteData data;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: ChatView(data: data),
      ),
    );
  }
}

/// 聊天正文。宽屏右栏直接复用它，不需要再套一层 Scaffold。
class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.data,
    this.embedded = false,
    this.onChanged,
  });

  final ChatRouteData data;

  /// 嵌入宽屏右栏时隐藏返回键。
  final bool embedded;

  /// 已读或发送后通知外层刷新会话列表。
  final VoidCallback? onChanged;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  TiebaChatApi? get _api {
    try {
      final TiebaApi api = Global.tiebaAPI;
      return api is TiebaChatApi ? api as TiebaChatApi : null;
    } catch (_) {
      return null;
    }
  }

  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  Timer? _poll;

  final List<TiebaChatMessage> _messages = <TiebaChatMessage>[];
  String _title = '';
  String _avatar = '';
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _emojiOpen = false;
  bool _readOnly = false;
  Object? _error;
  ChatCursor? _cursor;

  String get _currentUid =>
      AccountStore.currentUid ?? Global.profile.getString('uid') ?? '';

  String get _peerUid => widget.data.effectivePeer;

  @override
  void initState() {
    super.initState();
    _title = widget.data.title;
    _avatar = widget.data.avatar;
    _readOnly = widget.data.readOnly;
    _scroll.addListener(_onScroll);
    _input.addListener(_onInputChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadInitial();
    });
  }

  void _startPolling() {
    _poll?.cancel();
    // 推送在 headless 侧只负责更新本地缓存；聊天页用低频轮询把新消息接上，
    // 不伪造“正在输入/已读”，只合并已经落库的记录。
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_pollMessages());
    });
  }

  Future<void> _pollMessages() async {
    if (!mounted || _loading) return;
    final TiebaChatApi? api = _api;
    if (api == null) return;
    try {
      // getChatUnread 在真实后端里顺带触发 202003 增量同步。
      await MessageReminder.refreshChat();
      final ChatMessagePage page =
          await api.getChatMessages(widget.data.conversationId);
      if (!mounted || page.messages.isEmpty) return;
      bool changed = false;
      bool incoming = false;
      bool readUpdated = false;
      final Set<String> seen = <String>{};
      final List<TiebaChatMessage> merged = <TiebaChatMessage>[..._messages];
      for (final TiebaChatMessage message in page.messages) {
        final String key =
            message.id.isNotEmpty ? message.id : message.recordId;
        if (!seen.add(key)) continue;
        final int index = merged.indexWhere((TiebaChatMessage item) =>
            (item.id.isNotEmpty && item.id == message.id) ||
            (item.recordId.isNotEmpty && item.recordId == message.recordId));
        if (index >= 0) {
          final bool readChanged = merged[index].isRead != message.isRead;
          if (merged[index].status != TiebaChatMessageStatus.sent ||
              readChanged) {
            merged[index] = message;
            changed = true;
            if (readChanged) readUpdated = true;
          }
          continue;
        }
        merged.add(message);
        changed = true;
        if (message.senderUid != _currentUid) incoming = true;
      }
      if (!changed) return;
      merged.sort((TiebaChatMessage a, TiebaChatMessage b) {
        final int byTime = a.time.compareTo(b.time);
        if (byTime != 0) return byTime;
        return (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0);
      });
      final bool atBottom = !_scroll.hasClients || _scroll.offset < 80;
      setState(() {
        _messages
          ..clear()
          ..addAll(merged);
      });
      if (atBottom) _jumpToBottom();
      if (incoming) unawaited(_markRead());
      if (readUpdated) widget.onChanged?.call();
    } catch (_) {
      // 轮询失败保留当前消息，下一次继续。
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final ScrollPosition position = _scroll.position;
    // reverse 列表的 maxScrollExtent 在顶部。
    if (position.pixels > position.maxScrollExtent - 80) {
      _loadOlder();
    }
  }

  Future<void> _loadInitial() async {
    final TiebaChatApi? api = _api;
    if (api == null) {
      setState(() {
        _loading = false;
        _error = StateError('当前后端不支持私信');
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!(api as TiebaApi).isLogin) {
        throw StateError('未登录');
      }
      if (_title.isEmpty || _avatar.isEmpty) {
        final TiebaConversation? peer =
            await api.getChatPeer(widget.data.conversationId);
        if (peer != null) {
          _title = _title.isEmpty ? peer.title : _title;
          _avatar = _avatar.isEmpty ? peer.avatar : _avatar;
        }
      }
      final ChatMessagePage page =
          await api.getChatMessages(widget.data.conversationId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(page.messages);
        _hasMore = page.hasMore;
        _cursor = page.nextCursor;
        _loading = false;
        _error = null;
      });
      _jumpToBottom();
      unawaited(_markRead());
      _startPolling();
    } catch (error, stack) {
      AppLog.shared.error('chat.messages_failed', error, stack);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _loadOlder() async {
    if (_loadingMore || !_hasMore || _loading) return;
    final TiebaChatApi? api = _api;
    if (api == null) return;
    final double oldPixels = _scroll.hasClients ? _scroll.position.pixels : 0;
    final double oldMax =
        _scroll.hasClients ? _scroll.position.maxScrollExtent : 0;
    setState(() => _loadingMore = true);
    try {
      final ChatMessagePage page = await api.getChatMessages(
        widget.data.conversationId,
        cursor: _cursor,
      );
      if (!mounted) return;
      setState(() {
        _messages.insertAll(0, page.messages);
        _hasMore = page.hasMore;
        _cursor = page.nextCursor;
        _loadingMore = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        final double delta = _scroll.position.maxScrollExtent - oldMax;
        _scroll.jumpTo(
            (oldPixels + delta).clamp(0.0, _scroll.position.maxScrollExtent));
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _markRead() async {
    final TiebaChatApi? api = _api;
    if (api == null) return;
    String? lastId;
    for (final TiebaChatMessage message in _messages.reversed) {
      if (message.id.isNotEmpty && message.senderUid != _currentUid) {
        lastId = message.id;
        break;
      }
    }
    if (lastId == null) return;
    try {
      await api.markChatRead(widget.data.conversationId, lastId);
      await MessageReminder.refreshChat();
      widget.onChanged?.call();
    } catch (_) {
      // 已读上报失败不回滚本地，下次进入会再次对齐。
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  Future<void> _send() async {
    // 官方只读会话（userType 3/4）没有输入框，这里再兜底一次。
    if (_readOnly) return;
    final String text = _input.text.trim();
    if (text.isEmpty) return;
    final String recordId = '${DateTime.now().microsecondsSinceEpoch}';
    final TiebaChatMessage local = TiebaChatMessage(
      id: '',
      localId: recordId,
      recordId: recordId,
      conversationId: widget.data.conversationId,
      senderUid: _currentUid,
      content: text,
      time: DateTime.now(),
      status: TiebaChatMessageStatus.sending,
    );
    setState(() {
      _messages.add(local);
      _input.clear();
      _emojiOpen = false;
    });
    _jumpToBottom();
    await _deliver(local);
  }

  void _insertNewline() {
    final TextEditingValue value = _input.value;
    final TextSelection selection = value.selection;
    final int start = selection.isValid ? selection.start : value.text.length;
    final int end = selection.isValid ? selection.end : value.text.length;
    final String text = value.text.replaceRange(start, end, '\n');
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + 1),
    );
  }

  Future<void> _retry(TiebaChatMessage message) async {
    if (message.status != TiebaChatMessageStatus.failed) return;
    final int index = _messages
        .indexWhere((TiebaChatMessage item) => identical(item, message));
    if (index < 0) return;
    final TiebaChatMessage sending = message.copyWith(
      status: TiebaChatMessageStatus.sending,
      time: DateTime.now(),
    );
    setState(() => _messages[index] = sending);
    await _deliver(sending);
  }

  Future<void> _deliver(TiebaChatMessage local) async {
    // 切号瞬间不要用旧页面把消息发到新账号下。
    final String? account = AccountStore.currentUid;
    if (account != null && account.isNotEmpty && account != local.senderUid) {
      _markFailed(local.recordId);
      return;
    }
    final TiebaChatApi? api = _api;
    if (api == null) {
      _markFailed(local.recordId);
      return;
    }
    try {
      final ChatSendResult result = await api.sendChatMessage(
        widget.data.conversationId,
        ChatDraft(
          text: local.content,
          type: local.type,
          recordId: local.recordId,
        ),
      );
      if (!mounted) return;
      final int index = _messages.indexWhere(
          (TiebaChatMessage item) => item.recordId == local.recordId);
      if (index < 0) return;
      setState(() {
        _messages[index] = result.blocked
            ? result.message.copyWith(status: TiebaChatMessageStatus.failed)
            : result.message;
      });
      if (result.blocked) {
        await _showBlocked(result.block!);
      } else {
        widget.onChanged?.call();
      }
    } catch (_) {
      _markFailed(local.recordId);
    }
  }

  void _markFailed(String recordId) {
    if (!mounted) return;
    final int index = _messages
        .indexWhere((TiebaChatMessage item) => item.recordId == recordId);
    if (index < 0) return;
    setState(() {
      _messages[index] =
          _messages[index].copyWith(status: TiebaChatMessageStatus.failed);
    });
  }

  Future<void> _showBlocked(ChatBlockInfo block) async {
    final String? action = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('消息没有发出去'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                block.message.isEmpty ? '对方暂时不接收你的私信' : block.message,
              ),
              if (block.dealUrl.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context, 'open'),
                  child: const Text('查看原因'),
                ),
              ],
            ],
          ),
          actions: <Widget>[
            if (block.cancel.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: Text(block.cancel),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'confirm'),
              child: Text(block.confirm.isEmpty ? '知道了' : block.confirm),
            ),
          ],
        );
      },
    );
    if (action == 'open' && block.dealUrl.isNotEmpty) {
      final Uri? uri = Uri.tryParse(block.dealUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _openPeerProfile() {
    if (_peerUid.isEmpty) return;
    Navigator.pushNamed(context, PageRouter.user, arguments: _peerUid);
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    if (_error != null && _messages.isEmpty) {
      final bool notLoggedIn =
          _error is StateError && '$_error'.contains('未登录');
      final bool unsupported =
          _error is StateError && '$_error'.contains('不支持');
      return Column(
        children: <Widget>[
          _header(tokens),
          Expanded(
            child: _state(
              icon: notLoggedIn
                  ? Icons.person_outline
                  : unsupported
                      ? Icons.chat_bubble_outline
                      : Icons.wifi_off_outlined,
              title: notLoggedIn
                  ? '登录后才能看消息'
                  : unsupported
                      ? '当前版本暂不支持私信'
                      : '私信加载失败',
              body: notLoggedIn
                  ? '私信需要登录后同步，聊天记录按账号隔离'
                  : unsupported
                      ? '切换到支持私信的贴吧后端后再试'
                      : chatErrorBody(_error),
              primaryLabel: notLoggedIn ? '去登录' : (unsupported ? null : '重试'),
              onPrimary: notLoggedIn
                  ? () async {
                      await Navigator.pushNamed(context, PageRouter.login);
                      if (mounted) await _loadInitial();
                    }
                  : (unsupported ? null : _loadInitial),
            ),
          ),
        ],
      );
    }
    return Column(
      children: <Widget>[
        _header(tokens),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _messageList(tokens),
        ),
        _composerOrNotice(tokens),
        if (_emojiOpen && !_readOnly)
          Container(
            color: tokens.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: <Widget>[
                      Text(
                        '贴吧表情',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: tokens.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ],
                  ),
                ),
                EmojiPanel(controller: _input, height: 268),
              ],
            ),
          ),
      ],
    );
  }

  Widget _header(TiebananaTokens tokens) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      height: TiebananaMetrics.appBarHeight,
      decoration: BoxDecoration(
        color: tokens.bar,
        border: Border(bottom: BorderSide(color: tokens.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: <Widget>[
          if (!widget.embedded)
            _CircleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: '返回',
              onTap: () => Navigator.maybePop(context),
            )
          else
            const SizedBox(width: 4),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              borderRadius: TiebananaMetrics.brSm,
              onTap: _openPeerProfile,
              child: Row(
                children: <Widget>[
                  _ChatAvatar(url: _avatar, size: 32),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _title.isEmpty ? '贴吧用户' : _title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _CircleButton(
            icon: Icons.more_horiz,
            tooltip: '会话设置',
            onTap: () => showChatSettings(
              context,
              ChatRouteData(
                conversationId: widget.data.conversationId,
                peerUid: _peerUid,
                title: _title,
                avatar: _avatar,
                isMuted: widget.data.isMuted,
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageList(TiebananaTokens tokens) {
    if (_messages.isEmpty) {
      return Center(
        child: StateView(
          icon: Icons.chat_bubble_outline,
          title: '还没有消息',
          body: '发一条消息，开始这段对话',
        ),
      );
    }
    final List<_ChatRow> rows = _buildRows();
    final int extra = _boundaryRow ? 1 : 0;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side = constraints.maxWidth >= 700 ? 48 : 14;
        return ListView.builder(
          reverse: true,
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(side, 10, side, 14),
          itemCount: rows.length + extra,
          itemBuilder: (BuildContext context, int index) {
            if (index >= rows.length) {
              return _boundary(tokens);
            }
            final _ChatRow row = rows[rows.length - 1 - index];
            switch (row.kind) {
              case _ChatRowKind.date:
                return _datePill(tokens, row.time!);
              case _ChatRowKind.message:
                return _messageLine(tokens, row.message!, row);
            }
          },
        );
      },
    );
  }

  bool get _boundaryRow => !_hasMore || _loadingMore;

  Widget _boundary(TiebananaTokens tokens) {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: <Widget>[
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '已经到最早的本机记录',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: tokens.textTertiary),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _datePill(TiebananaTokens tokens, DateTime time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: tokens.fill,
            borderRadius: TiebananaMetrics.brPill,
          ),
          child: Text(
            chatDateLabel(time),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: tokens.textTertiary, fontSize: 11.5),
          ),
        ),
      ),
    );
  }

  Widget _messageLine(
      TiebananaTokens tokens, TiebaChatMessage message, _ChatRow row) {
    if (message.type == 7) {
      final List<ChatNoticeCardData> cards = chatNoticeCards(message.content);
      if (cards.isNotEmpty) {
        return Column(children: [
          for (final card in cards)
            ChatNoticeCard(data: card, blockLinks: _readOnly)
        ]);
      }
    }
    final bool mine = message.senderUid == _currentUid;
    final bool lastOfGroup = row.lastOfGroup;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final Widget bubble = GestureDetector(
      onTap: message.status == TiebaChatMessageStatus.failed
          ? () => _retry(message)
          : null,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: math.min(520.0, MediaQuery.sizeOf(context).width * 0.76),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: message.status == TiebaChatMessageStatus.failed
              ? tokens.surface
              : (mine ? tokens.accentFill : tokens.surface),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(mine ? 20 : 7),
            bottomRight: Radius.circular(mine ? 7 : 20),
          ),
          border: message.status == TiebaChatMessageStatus.failed
              ? Border.all(color: tokens.danger, width: 1.5)
              : (mine ? null : Border.all(color: tokens.line)),
          boxShadow: message.status == TiebaChatMessageStatus.failed
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: tokens.shadow,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Opacity(
          opacity: message.status == TiebaChatMessageStatus.sending ? .78 : 1,
          child: ExtendedText(
            chatDisplayText(message.type, message.content),
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14.5,
              height: 1.56,
              color: message.status == TiebaChatMessageStatus.failed
                  ? tokens.textPrimary
                  : (mine ? tokens.accentOn : tokens.textPrimary),
            ),
            specialTextSpanBuilder: TiebaSpanBuilder(),
          ),
        ),
      ),
    );

    final List<Widget> children = <Widget>[
      if (!mine)
        SizedBox(
          width: 35,
          child: lastOfGroup
              ? Align(
                  alignment: Alignment.bottomLeft,
                  child: _ChatAvatar(url: _avatar, size: 28),
                )
              : null,
        ),
      Flexible(
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                if (mine && message.status == TiebaChatMessageStatus.sending)
                  const Padding(
                    padding: EdgeInsets.only(right: 7, bottom: 8),
                    child: SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (mine && message.status == TiebaChatMessageStatus.failed)
                  Padding(
                    padding: const EdgeInsets.only(right: 7, bottom: 6),
                    child: Container(
                      width: 19,
                      height: 19,
                      decoration: BoxDecoration(
                        color: tokens.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '!',
                          style: TextStyle(
                            color: tokens.onImage,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                Flexible(child: bubble),
              ],
            ),
            if (lastOfGroup)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: _stamp(tokens, message, mine: mine),
              ),
          ],
        ),
      ),
      if (mine) const SizedBox(width: 4),
    ];

    return Padding(
      padding: EdgeInsets.only(top: row.groupStart ? 14 : 4),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: children,
      ),
    );
  }

  /// 消息组末尾的状态行：发送中 / 未发送 / 时间（己方附带对方已读状态）。
  Widget _stamp(
    TiebananaTokens tokens,
    TiebaChatMessage message, {
    required bool mine,
  }) {
    final TextStyle? base = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(fontSize: 10.5, color: tokens.textTertiary);
    final bool sending = message.status == TiebaChatMessageStatus.sending;
    final bool failed = message.status == TiebaChatMessageStatus.failed;
    if (sending || failed) {
      return Text(
        sending ? '发送中…' : '未发送 · 点此重发',
        style: base?.copyWith(
          color: failed ? tokens.danger : tokens.textTertiary,
          fontWeight: failed ? FontWeight.w600 : null,
        ),
      );
    }
    if (!mine) {
      return Text(chatClock(message.time), style: base);
    }
    final bool read = message.isRead;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(chatClock(message.time), style: base),
        Text(' · ', style: base),
        Text(
          read ? '已读' : '未读',
          style: base?.copyWith(
            color: read ? tokens.primary : tokens.textSecondary,
            fontWeight: read ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }

  List<_ChatRow> _buildRows() {
    final List<_ChatRow> rows = <_ChatRow>[];
    for (int i = 0; i < _messages.length; i++) {
      final TiebaChatMessage message = _messages[i];
      final TiebaChatMessage? previous = i == 0 ? null : _messages[i - 1];
      final TiebaChatMessage? next =
          i == _messages.length - 1 ? null : _messages[i + 1];
      final bool newDate = previous == null ||
          message.type == 7 ||
          previous.type == 7 ||
          !isSameChatDay(previous.time, message.time);
      if (newDate) {
        rows.add(_ChatRow.date(message.time));
      }
      final bool groupStart =
          newDate || previous.senderUid != message.senderUid;
      final bool lastOfGroup = next == null ||
          next.senderUid != message.senderUid ||
          !isSameChatDay(message.time, next.time);
      rows.add(_ChatRow.message(
        message,
        groupStart: groupStart,
        lastOfGroup: lastOfGroup,
      ));
    }
    return rows;
  }

  Widget _composerOrNotice(TiebananaTokens tokens) {
    if (!_readOnly) return _composer(tokens);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      key: const Key('chat-read-only-bar'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 15),
      decoration: BoxDecoration(
        color: tokens.bar,
        border: Border(top: BorderSide(color: tokens.line)),
      ),
      child: Text(
        '该会话仅接收消息',
        textAlign: TextAlign.center,
        style: textTheme.bodySmall?.copyWith(color: tokens.textTertiary),
      ),
    );
  }

  Widget _composer(TiebananaTokens tokens) {
    final bool canSend = _input.text.trim().isNotEmpty;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Widget field = Container(
      constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brPill,
        boxShadow: tokens.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: ExtendedTextField(
        specialTextSpanBuilder: TiebaSpanBuilder(),
        controller: _input,
        focusNode: _inputFocus,
        minLines: 1,
        maxLines: 5,
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
        onTap: () {
          if (_emojiOpen) setState(() => _emojiOpen = false);
        },
        style: textTheme.bodyMedium?.copyWith(
          fontSize: 13.5,
          color: tokens.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: '发消息…',
          hintStyle: textTheme.bodyMedium?.copyWith(
            fontSize: 13.5,
            color: tokens.textTertiary,
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 14),
      decoration: BoxDecoration(
        color: tokens.bar,
        border: Border(top: BorderSide(color: tokens.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          _CircleButton(
            icon: _emojiOpen
                ? Icons.keyboard_alt_outlined
                : Icons.emoji_emotions_outlined,
            tooltip: '贴吧表情',
            tint: _emojiOpen,
            onTap: () {
              final bool open = !_emojiOpen;
              setState(() => _emojiOpen = open);
              if (open) {
                FocusManager.instance.primaryFocus?.unfocus();
              } else {
                _inputFocus.requestFocus();
              }
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: CallbackShortcuts(
                  bindings: <ShortcutActivator, VoidCallback>{
                    const SingleActivator(LogicalKeyboardKey.enter): _send,
                    const SingleActivator(LogicalKeyboardKey.numpadEnter):
                        _send,
                    const SingleActivator(LogicalKeyboardKey.enter,
                        shift: true): _insertNewline,
                    const SingleActivator(LogicalKeyboardKey.numpadEnter,
                        shift: true): _insertNewline,
                  },
                  child: field,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: canSend ? tokens.accentFill : tokens.accentFill,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: canSend ? _send : null,
              child: Opacity(
                opacity: canSend ? 1 : .45,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.send_rounded,
                    size: 19,
                    color: tokens.accentOn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _state({
    required IconData icon,
    required String title,
    required String body,
    String? primaryLabel,
    VoidCallback? onPrimary,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: StateView(
                icon: icon,
                title: title,
                body: body,
                primaryLabel: primaryLabel,
                primaryIcon: onPrimary == null ? null : Icons.refresh,
                onPrimary: onPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.tint = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool tint;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: tint ? tokens.primaryContainer : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 21,
              color: tint ? tokens.onPrimaryContainer : tokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tokens.fill, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? Icon(Icons.person_outline,
              color: tokens.textTertiary, size: size * .55)
          : AvatarImage(url: url),
    );
  }
}

enum _ChatRowKind { date, message }

class _ChatRow {
  const _ChatRow.date(this.time)
      : kind = _ChatRowKind.date,
        message = null,
        groupStart = false,
        lastOfGroup = false;

  const _ChatRow.message(
    this.message, {
    required this.groupStart,
    required this.lastOfGroup,
  })  : kind = _ChatRowKind.message,
        time = null;

  final _ChatRowKind kind;
  final DateTime? time;
  final TiebaChatMessage? message;
  final bool groupStart;
  final bool lastOfGroup;
}
