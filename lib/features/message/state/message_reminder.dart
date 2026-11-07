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
  static int _revision = 0;
  static final Map<TiebaMessageKind, int> _clearRevisions = {};
  static bool likeOpened = false;

  static void reset() {
    likeOpened = false;
    _revision++;
    counts.value = const MessageUnreadCounts();
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
      AccountStore.updateCurrentUnread(result.total);
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
    AccountStore.updateCurrentUnread(counts.value.total);
  }
}
