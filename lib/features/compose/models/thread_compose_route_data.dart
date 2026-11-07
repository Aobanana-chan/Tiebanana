class ThreadComposeRouteData {
  const ThreadComposeRouteData({
    required this.fid,
    required this.forumName,
    this.topicId = '',
    this.topicName = '',
  });
  final String fid;
  final String forumName;

  /// 话题页「发帖」带入的话题；topicId 可能为空（只有话题名）。
  final String topicId;
  final String topicName;
}
