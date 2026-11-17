import 'package:flutter/foundation.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';

/// 分类提醒的运行时快照，数据来自消息未读接口。
class MessageReminder {
  MessageReminder._();
  static final counts =
      ValueNotifier<MessageUnreadCounts>(const MessageUnreadCounts());

  /// 私信未读：本地会话 `unread` 之和，独立于 c/s/msg 的分类提醒。
  static final ValueNotifier<int> chatUnread = ValueNotifier<int>(0);

  static int _revision = 0;
  static final Map<TiebaMessageKind, int> _clearRevisions = {};
  static bool likeOpened = false;

  /// 底栏 / 消息页角标使用的总数（分类提醒 + 私信）。
  static int get totalUnread => counts.value.total + chatUnread.value;

  static void reset() {
    likeOpened = false;
    _revision++;
    counts.value = const MessageUnreadCounts();
    chatUnread.value = 0;
  }

  /// 私信未读来自本地会话表，和 [refresh] 分开请求。
  static Future<void> refreshChat() async {
    final TiebaApi api;
    try {
      api = Global.tiebaAPI;
    } catch (_) {
      // 未完成初始化（如 widget 测试直接渲染消息页）时静默跳过。
      chatUnread.value = 0;
      return;
    }
    if (!api.isLogin || api is! TiebaChatApi) {
      chatUnread.value = 0;
      return;
    }
    try {
      final int value = await (api as TiebaChatApi).getChatUnread();
      if (identical(api, Global.tiebaAPI)) {
        setChatUnread(value);
      }
    } catch (error, stack) {
      AppLog.shared.error('messages.chat_unread_failed', error, stack);
    }
  }

  static void setChatUnread(int value) {
    chatUnread.value = value < 0 ? 0 : value;
    AccountStore.updateCurrentUnread(totalUnread);
  }

  static Future<void> refresh() async {
    final int revision = ++_revision;
    final clearRevisions = Map<TiebaMessageKind, int>.of(_clearRevisions);
    final api = Global.tiebaAPI;
    if (!api.isLogin) return;
    try {
      var result = await api.getMessageUnread();
      if (revision != _revision || !identical(api, Global.tiebaAPI)) return;
      for (final kind in TiebaMessageKind.values) {
        if (_clearRevisions[kind] != clearRevisions[kind]) {
          result = result.clear(kind);
        }
      }
      counts.value = result;
      AccountStore.updateCurrentUnread(totalUnread);
    } catch (error, stack) {
      AppLog.shared.error('messages.reminder_failed', error, stack);
      // 请求失败时保留已有角标。
      debugPrint('获取消息提醒失败: $error');
    }
  }

  /// 分类提醒清零后，进行中的刷新会把该分类的旧计数丢弃。
  static void clear(TiebaMessageKind kind) {
    _clearRevisions[kind] = (_clearRevisions[kind] ?? 0) + 1;
    counts.value = counts.value.clear(kind);
    AccountStore.updateCurrentUnread(totalUnread);
  }
}
