import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/features/message/state/chat_time.dart';

void main() {
  DateTime day(int daysAgo, {int hour = 21, int minute = 4}) {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute)
        .subtract(Duration(days: daysAgo));
  }

  test('会话时间：当日显示时刻', () {
    expect(conversationTime(day(0)), chatClock(day(0)));
  });

  test('会话时间：昨天 / 前天 / N日前 / YYYY-MM-DD', () {
    expect(conversationTime(day(1)), '昨天');
    expect(conversationTime(day(2)), '前天');
    expect(conversationTime(day(3)), '3日前');
    expect(conversationTime(day(7)), '7日前');
    final DateTime old = day(8);
    expect(
      conversationTime(old),
      '${old.year}-'
      '${old.month.toString().padLeft(2, '0')}-'
      '${old.day.toString().padLeft(2, '0')}',
    );
  });

  test('日期胶囊：今天 / 昨天 / 前天 / N日前 / YYYY-MM-DD', () {
    expect(chatDateLabel(day(0)), '今天');
    expect(chatDateLabel(day(1)), '昨天');
    expect(chatDateLabel(day(2)), '前天');
    expect(chatDateLabel(day(6)), '6日前');
    final DateTime old = day(30);
    expect(
      chatDateLabel(old),
      '${old.year}-'
      '${old.month.toString().padLeft(2, '0')}-'
      '${old.day.toString().padLeft(2, '0')}',
    );
  });
}
