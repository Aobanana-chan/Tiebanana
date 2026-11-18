/// 提醒条 / 广播入口 / 广播历史的时间文案。
///
/// 只做纯展示，不用“刚刚 / N 分钟前”的本地计时器：协议给的是绝对时间。
library;

String reminderClock(DateTime time) {
  final DateTime local = time.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

bool isSameReminderDay(DateTime a, DateTime b) {
  final DateTime x = a.toLocal();
  final DateTime y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

/// 提醒区最近时间：当日 `HH:mm`；同年 `M月d日 HH:mm`；跨年 `YYYY-MM-DD`。
String reminderTimeLabel(DateTime? time) {
  if (time == null) return '';
  final DateTime local = time.toLocal();
  final DateTime now = DateTime.now();
  if (isSameReminderDay(local, now)) return reminderClock(local);
  if (local.year == now.year) {
    return '${local.month}月${local.day}日 ${reminderClock(local)}';
  }
  return '${local.year}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

/// 广播历史卡片：`M月d日 HH:mm`；跨年 `YYYY-MM-DD`。
///
/// 秒 / 毫秒的合理性校验在转换层完成；这里只负责格式化。
String broadcastTimeLabel(DateTime? time) {
  if (time == null) return '';
  final DateTime local = time.toLocal();
  final DateTime now = DateTime.now();
  if (local.year == now.year) {
    return '${local.month}月${local.day}日 ${reminderClock(local)}';
  }
  return '${local.year}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

/// 广播聚合流的日期分组：`YYYY-MM-DD`。
String broadcastDayLabel(DateTime time) {
  final DateTime local = time.toLocal();
  return '${local.year}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

/// 「推送给 12,480 人」的千分位。
String groupedCount(int value) {
  final String digits = '$value';
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}
