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

/// 会话列表右上角：今天 21:04 / 昨天 / 周一 / 11/12。
String conversationTime(DateTime? time) {
  if (time == null) return '';
  final DateTime now = DateTime.now();
  final DateTime local = time.toLocal();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime day = DateTime(local.year, local.month, local.day);
  final int diff = today.difference(day).inDays;
  if (diff <= 0) return chatClock(local);
  if (diff == 1) return '昨天';
  if (diff < 7) {
    return const <String>[
      '周一',
      '周二',
      '周三',
      '周四',
      '周五',
      '周六',
      '周日'
    ][local.weekday - 1];
  }
  return '${local.month}/${local.day}';
}

/// 消息流里的日期胶囊。
String chatDateLabel(DateTime time) {
  final DateTime now = DateTime.now();
  final DateTime local = time.toLocal();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime day = DateTime(local.year, local.month, local.day);
  final int diff = today.difference(day).inDays;
  if (diff <= 0) return '今天';
  if (diff == 1) return '昨天';
  if (diff < 7) {
    return const <String>[
      '周一',
      '周二',
      '周三',
      '周四',
      '周五',
      '周六',
      '周日'
    ][local.weekday - 1];
  }
  if (local.year == now.year) return '${local.month}/${local.day}';
  return '${local.year}/${local.month}/${local.day}';
}
