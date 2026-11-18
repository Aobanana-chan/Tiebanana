import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/message/widgets/conversation_card.dart';
import 'package:tiebanana/features/share/models/share_content.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/app_toast.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';

/// 打开「分享给好友」：从私信会话里选择一位好友，把链接作为私信发出。
Future<void> showShareFriendPicker(
  BuildContext context,
  ShareContent content,
) {
  final TiebananaTokens tokens = TiebananaTokens.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: tokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(TiebananaMetrics.radiusXl),
      ),
    ),
    builder: (BuildContext sheetContext) {
      final MediaQueryData media = MediaQuery.of(sheetContext);
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.72),
          child: _ShareFriendPicker(
            content: content,
            pageContext: context,
          ),
        ),
      );
    },
  );
}

class _ShareFriendPicker extends StatefulWidget {
  const _ShareFriendPicker({
    required this.content,
    required this.pageContext,
  });

  final ShareContent content;

  /// 分享面板背后的页面，用于登录跳转。
  final BuildContext pageContext;

  @override
  State<_ShareFriendPicker> createState() => _ShareFriendPickerState();
}

class _ShareFriendPickerState extends State<_ShareFriendPicker> {
  List<TiebaConversation> _items = <TiebaConversation>[];
  bool _loading = true;
  Object? _error;
  String _query = '';
  String? _sendingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  TiebaChatApi? get _chatApi {
    try {
      final TiebaApi api = Global.tiebaAPI;
      return api is TiebaChatApi ? api as TiebaChatApi : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    try {
      final TiebaApi api;
      try {
        api = Global.tiebaAPI;
      } catch (_) {
        throw StateError('当前后端不支持私信');
      }
      if (api is! TiebaChatApi) {
        throw StateError('当前后端不支持私信');
      }
      if (!api.isLogin) {
        throw StateError('未登录');
      }
      final List<TiebaConversation> conversations =
          await (api as TiebaChatApi).getConversations();
      if (!mounted) return;
      setState(() {
        // 只保留可以发私信的个人会话；官方只读账号收不到分享。
        _items = conversations
            .where(
                (TiebaConversation item) => item.isPrivate && !item.isReadOnly)
            .toList(growable: false);
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  void _login() {
    final BuildContext pageContext = widget.pageContext;
    Navigator.pop(context);
    if (pageContext.mounted) {
      Navigator.pushNamed(pageContext, PageRouter.login);
    }
  }

  bool get _notLoggedIn => _error is StateError && '$_error'.contains('未登录');

  bool get _unsupported => _error is StateError && '$_error'.contains('不支持私信');

  List<TiebaConversation> get _filtered {
    final String query = _query.toLowerCase();
    if (query.isEmpty) return _items;
    return _items
        .where((TiebaConversation item) =>
            item.title.toLowerCase().contains(query))
        .toList(growable: false);
  }

  Future<void> _send(TiebaConversation conversation) async {
    if (_sendingId != null) return;
    final TiebaChatApi? api = _chatApi;
    if (api == null) {
      Fluttertoast.showToast(msg: '当前后端不支持私信');
      return;
    }
    setState(() => _sendingId = conversation.id);
    try {
      final ChatSendResult result = await api.sendChatMessage(
        conversation.id,
        ChatDraft(text: widget.content.shareText),
      );
      if (!mounted) return;
      setState(() => _sendingId = null);
      if (result.blocked) {
        await _showBlocked(result.block!);
        return;
      }
      final String name =
          conversation.title.isEmpty ? '好友' : conversation.title;
      Navigator.pop(context);
      Fluttertoast.showToast(msg: '已分享给 $name');
    } catch (error) {
      if (!mounted) return;
      setState(() => _sendingId = null);
      Fluttertoast.showToast(
        msg: '分享失败：${error is StateError ? error.message : error}',
      );
    }
  }

  Future<void> _showBlocked(ChatBlockInfo block) async {
    if (!mounted) return;
    final String message = block.message.trim();
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('私信没有发出去'),
        content: Text(message.isEmpty ? '对方当前无法接收这条私信。' : message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '分享给好友',
                    style: textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 21,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '选择一位好友，链接会以私信发送',
              style: textTheme.bodySmall?.copyWith(
                color: tokens.textTertiary,
              ),
            ),
          ),
          if (!_loading && _error == null && _items.isNotEmpty) ...<Widget>[
            const SizedBox(height: TiebananaMetrics.gapMd),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _searchField(tokens),
            ),
          ],
          if (_sendingId != null) ...<Widget>[
            const SizedBox(height: TiebananaMetrics.gapSm),
            LinearProgressIndicator(
              minHeight: 2,
              color: tokens.primary,
              backgroundColor: tokens.surfaceAlt,
            ),
          ],
          const SizedBox(height: TiebananaMetrics.gapSm),
          Expanded(child: _content(tokens)),
        ],
      ),
    );
  }

  Widget _searchField(TiebananaTokens tokens) {
    return TextField(
      textInputAction: TextInputAction.search,
      onChanged: (String value) => setState(() => _query = value.trim()),
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: tokens.textPrimary),
      decoration: InputDecoration(
        hintText: '搜索好友',
        hintStyle: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: tokens.textTertiary),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: tokens.textTertiary,
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 38),
        filled: true,
        fillColor: tokens.fill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TiebananaMetrics.gapMd,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: TiebananaMetrics.brPill,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: TiebananaMetrics.brPill,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: TiebananaMetrics.brPill,
          borderSide: BorderSide(color: tokens.primary),
        ),
      ),
    );
  }

  Widget _content(TiebananaTokens tokens) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(TiebananaMetrics.gapXl),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    if (_error != null) {
      if (_notLoggedIn) {
        return SingleChildScrollView(
          child: StateView(
            icon: Icons.lock_outline_rounded,
            title: '登录后分享给好友',
            body: '分享会给好友发一条私信，请先登录账号',
            primaryLabel: '去登录',
            onPrimary: _login,
          ),
        );
      }
      if (_unsupported) {
        return const SingleChildScrollView(
          child: StateView(
            icon: Icons.forum_outlined,
            title: '暂不支持分享给好友',
            body: '当前版本没有私信能力，可以改用「其他应用」分享',
          ),
        );
      }
      return SingleChildScrollView(
        child: StateView(
          icon: Icons.wifi_off_rounded,
          title: '好友列表没加载出来',
          body: '检查一下网络，或者稍后再试',
          primaryLabel: '重试',
          primaryIcon: Icons.refresh,
          onPrimary: _retry,
        ),
      );
    }
    if (_items.isEmpty) {
      return const SingleChildScrollView(
        child: StateView(
          icon: Icons.forum_outlined,
          title: '还没有私信好友',
          body: '在用户主页点「私信」开始一段对话后\n就可以把内容分享给 TA',
        ),
      );
    }
    final List<TiebaConversation> items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(TiebananaMetrics.gapXl),
          child: Text(
            '没有找到相关好友',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: tokens.textTertiary),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: TiebananaMetrics.gapXs, bottom: 12),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final TiebaConversation conversation = items[index];
        return ConversationCard(
          conversation: conversation,
          onTap: () => _send(conversation),
        );
      },
    );
  }
}
