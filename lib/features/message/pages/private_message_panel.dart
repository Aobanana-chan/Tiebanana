import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/message/models/chat_route_data.dart';
import 'package:tiebanana/features/message/pages/chat_page.dart';
import 'package:tiebanana/features/message/state/message_reminder.dart';
import 'package:tiebanana/features/message/widgets/conversation_card.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';

/// 私信页签：会话列表；宽屏（≥ 900dp）切成左右两栏。
class PrivateMessagePanel extends StatefulWidget {
  const PrivateMessagePanel({super.key, this.onBrowse});

  final VoidCallback? onBrowse;

  @override
  State<PrivateMessagePanel> createState() => _PrivateMessagePanelState();
}

class _PrivateMessagePanelState extends State<PrivateMessagePanel> {
  TiebaChatApi? get _api {
    try {
      final TiebaApi api = Global.tiebaAPI;
      return api is TiebaChatApi ? api as TiebaChatApi : null;
    } catch (_) {
      return null;
    }
  }

  final List<TiebaConversation> _items = <TiebaConversation>[];
  bool _loading = true;
  bool _refreshing = false;
  Object? _error;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!silent && _items.isEmpty && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final TiebaChatApi? api = _api;
      if (api == null) {
        throw StateError('当前后端不支持私信');
      }
      if (!(api as TiebaApi).isLogin) {
        throw StateError('未登录');
      }
      final List<TiebaConversation> conversations =
          await api.getConversations();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(conversations);
        _loading = false;
        _error = null;
      });
      MessageReminder.setChatUnread(
        conversations.fold<int>(
            0, (int sum, TiebaConversation item) => sum + item.unread),
      );
    } catch (error, stack) {
      AppLog.shared.error('chat.conversations_failed', error, stack);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _openChat(TiebaConversation conversation) async {
    await Navigator.pushNamed(
      context,
      PageRouter.chat,
      arguments: ChatRouteData(
        conversationId: conversation.id,
        peerUid: conversation.peerUid,
        title: conversation.title,
        avatar: conversation.avatar,
        isMuted: conversation.isMuted,
        userType: conversation.userType,
      ),
    );
    if (mounted) await _load(silent: true);
  }

  bool get _notLoggedIn => _error is StateError && '$_error'.contains('未登录');
  bool get _unsupported => _error is StateError && '$_error'.contains('不支持');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 900;
        if (wide) return _wide(context);
        return _list(context, scrollable: true);
      },
    );
  }

  Widget _wide(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    TiebaConversation? selected;
    for (final TiebaConversation item in _items) {
      if (item.id == _selectedId) selected = item;
    }
    return Row(
      children: <Widget>[
        SizedBox(
          width: 326,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.bg,
              border: Border(right: BorderSide(color: tokens.line)),
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    children: <Widget>[
                      Text(
                        '私信',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (MessageReminder.chatUnread.value > 0) ...<Widget>[
                        const SizedBox(width: 8),
                        UnreadCountBadge(
                          count: MessageReminder.chatUnread.value,
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '按最近消息排序',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: tokens.textTertiary),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _list(context, scrollable: false, side: true)),
              ],
            ),
          ),
        ),
        Expanded(
          child: selected == null
              ? const Center(
                  child: StateView(
                    icon: Icons.forum_outlined,
                    title: '选择一个对话',
                    body: '从左侧选择一段私信，或去用户主页发起新的对话',
                  ),
                )
              : ChatView(
                  key: ValueKey<String>(selected.id),
                  embedded: true,
                  data: ChatRouteData(
                    conversationId: selected.id,
                    peerUid: selected.peerUid,
                    title: selected.title,
                    avatar: selected.avatar,
                    isMuted: selected.isMuted,
                    userType: selected.userType,
                  ),
                  onChanged: () => _load(silent: true),
                ),
        ),
      ],
    );
  }

  Widget _list(BuildContext context,
      {required bool scrollable, bool side = false}) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    if (_notLoggedIn) {
      return _stateSheet(
        context,
        scrollable: scrollable,
        icon: Icons.person_outline,
        title: '登录后才能看消息',
        body: '私信需要登录后同步，聊天记录按账号隔离',
        primaryLabel: '去登录',
        onPrimary: () async {
          await Navigator.pushNamed(context, PageRouter.login);
          if (mounted) await _load();
        },
      );
    }
    if (_unsupported) {
      return _stateSheet(
        context,
        scrollable: scrollable,
        icon: Icons.chat_bubble_outline,
        title: '当前版本暂不支持私信',
        body: '切换到支持私信的贴吧后端后再试',
      );
    }
    if (_loading && _items.isEmpty) {
      return const _ConversationSkeleton();
    }
    if (_error != null && _items.isEmpty) {
      return _stateSheet(
        context,
        scrollable: scrollable,
        icon: Icons.wifi_off_outlined,
        title: '网络似乎有点问题',
        body: '检查一下网络连接后重试，\n已经加载过的会话仍可离线查看',
        primaryLabel: '重试',
        onPrimary: _load,
      );
    }
    if (_items.isEmpty) {
      return _stateSheet(
        context,
        scrollable: scrollable,
        icon: Icons.chat_bubble_outline,
        title: '还没有私信',
        body: '在用户主页点「发私信」，开始第一段对话',
        primaryLabel: widget.onBrowse == null ? null : '去逛逛',
        onPrimary: widget.onBrowse,
      );
    }
    final bool showFooter = _error != null;
    final Widget list = ListView.builder(
      padding: EdgeInsets.only(
          top: side ? 0 : TiebananaMetrics.gapSm,
          bottom: TiebananaMetrics.gapMd),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _items.length + (showFooter ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index >= _items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _load(),
                child: Text(
                  '同步失败，点此重试',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: tokens.primary),
                ),
              ),
            ),
          );
        }
        final TiebaConversation conversation = _items[index];
        return ConversationCard(
          conversation: conversation,
          selected: side && conversation.id == _selectedId,
          onTap: () {
            if (side) {
              setState(() => _selectedId = conversation.id);
            } else {
              _openChat(conversation);
            }
          },
        );
      },
    );
    if (!scrollable) return list;
    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () => _load(silent: true),
      child: list,
    );
  }

  Widget _stateSheet(
    BuildContext context, {
    required bool scrollable,
    required IconData icon,
    required String title,
    required String body,
    String? primaryLabel,
    VoidCallback? onPrimary,
  }) {
    final Widget view = StateView(
      icon: icon,
      title: title,
      body: body,
      primaryLabel: primaryLabel,
      primaryIcon: primaryLabel == '重试' ? Icons.refresh : null,
      onPrimary: onPrimary,
    );
    final Widget bodyWidget = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: view),
          ),
        );
      },
    );
    if (!scrollable) return bodyWidget;
    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () => _load(silent: true),
      child: bodyWidget,
    );
  }
}

class _ConversationSkeleton extends StatelessWidget {
  const _ConversationSkeleton();

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        for (int i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.fromLTRB(
                TiebananaMetrics.pageGutter, 0, TiebananaMetrics.pageGutter, 8),
            padding: const EdgeInsets.all(TiebananaMetrics.gapMd),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: TiebananaMetrics.brLg,
              boxShadow: tokens.cardShadow,
            ),
            child: Row(
              children: const <Widget>[
                SkeletonBox(width: 42, height: 42, radius: 21),
                SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SkeletonBox(width: 92, height: 13),
                      SizedBox(height: 8),
                      SkeletonBox(width: 160, height: 11),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                SkeletonBox(width: 34, height: 11),
              ],
            ),
          ),
      ],
    );
  }
}
