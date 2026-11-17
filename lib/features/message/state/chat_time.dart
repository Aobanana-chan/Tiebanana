/// 私信列表与聊天页的时间文案。
library;

String chatClock(DateTime time) {
  final DateTime local = time.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

bool isSameChatDay(DateTime a, DateTime b) {
  final DateTime x = a.toLocal();
  final DateTime y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

/// 会话列表右上角：当日 21:04 / 昨天 / 前天 / N日前（N ≤ 7）/ 2026-11-12。
String conversationTime(DateTime? time) {
  if (time == null) return '';
  final DateTime local = time.toLocal();
  final int diff = _dayDiff(local, DateTime.now());
  if (diff <= 0) return chatClock(local);
  if (diff == 1) return '昨天';
  if (diff == 2) return '前天';
  if (diff <= 7) return '$diff日前';
  return _chatDate(local);
}

/// 消息流里的日期胶囊：今天 / 昨天 / 前天 / N日前（N ≤ 7）/ 2026-11-12。
String chatDateLabel(DateTime time) {
  final DateTime local = time.toLocal();
  final int diff = _dayDiff(local, DateTime.now());
  if (diff <= 0) return '今天';
  if (diff == 1) return '昨天';
  if (diff == 2) return '前天';
  if (diff <= 7) return '$diff日前';
  return _chatDate(local);
}

/// 按自然日计算差距；用 UTC 日期避免夏令时导致 23 小时被算成 0 天。
int _dayDiff(DateTime local, DateTime now) {
  return DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(local.year, local.month, local.day))
      .inDays;
}

String _chatDate(DateTime local) {
  return '${local.year}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
