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
    this.userType = 0,
  });

  final String conversationId;
  final String peerUid;
  final String title;
  final String avatar;
  final bool isMuted;

  /// 官方账号类型；3/4 为只读会话（只接收消息，无输入框）。
  final int userType;

  /// 与官方一致：仅接收消息，不提供回复框。
  bool get readOnly => userType == 3 || userType == 4;

  String get effectivePeer => peerUid.isEmpty ? conversationId : peerUid;
}
