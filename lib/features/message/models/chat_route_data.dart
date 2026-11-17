/// 聊天页路由参数。
///
/// [conversationId] 个人会话等于对方 uid；[title] / [avatar] 来自会话缓存或
/// 通知内容，用于在 205003 资料到达前先把标题画出来。
class ChatRouteData {
  const ChatRouteData({
    required this.conversationId,
    this.peerUid = '',
    this.title = '',
    this.avatar = '',
    this.isMuted = false,
  });

  final String conversationId;
  final String peerUid;
  final String title;
  final String avatar;
  final bool isMuted;

  String get effectivePeer => peerUid.isEmpty ? conversationId : peerUid;
}
