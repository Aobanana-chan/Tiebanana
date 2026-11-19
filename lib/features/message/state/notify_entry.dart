/// 通知区的一条提醒。
///
/// 只描述「怎么显示」，不持有原始 protobuf / Map；数据由
/// `NotificationReminder` 从本地状态和通知概览组装。
library;

/// 行的类型。类型只决定图标、角标口径和点击去向，不改变行的骨架。
enum NotifyEntryKind {
  mutualHelp,
  broadcast,
}

/// 尾部状态：数字角标 / 红点 / 什么都没有。
enum NotifyBadgeKind {
  none,
  count,
  dot,
}

class NotifyEntry {
  const NotifyEntry({
    required this.kind,
    required this.title,
    required this.summary,
    this.time,
    this.badge = NotifyBadgeKind.none,
    this.count = 0,
    this.muted = false,
  });

  final NotifyEntryKind kind;

  /// 行标题：会话名或本地固定文案。
  final String title;

  /// 一行摘要。没有摘要时为空字符串，不补「暂无」。
  final String summary;

  /// 最近时间；没有就不显示时间。
  final DateTime? time;

  final NotifyBadgeKind badge;

  /// 仅 [NotifyBadgeKind.count] 有意义。
  final int count;

  /// 弱化显示（已屏蔽 / 无数据）。
  final bool muted;

  String get id => kind.name;
}
