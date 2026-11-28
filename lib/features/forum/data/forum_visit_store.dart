import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiebanana/app/global.dart';

/// 单个吧的本地访问统计（进入该吧 + 进入该吧的贴子合计次数）。
class ForumVisitRecord {
  const ForumVisitRecord({
    required this.forumName,
    required this.count,
    required this.lastVisitAt,
    this.avatar = '',
  });

  final String forumName;
  final int count;
  final int lastVisitAt;
  final String avatar;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'count': count,
        'lastVisitAt': lastVisitAt,
        if (avatar.isNotEmpty) 'avatar': avatar,
      };

  factory ForumVisitRecord.fromJson(
    String forumName,
    Map<String, dynamic> json,
  ) {
    final int count = int.tryParse('${json['count'] ?? 0}') ?? 0;
    final int lastVisitAt = int.tryParse('${json['lastVisitAt'] ?? 0}') ?? 0;
    final String avatar = '${json['avatar'] ?? ''}'.trim();
    return ForumVisitRecord(
      forumName: forumName,
      count: count < 0 ? 0 : count,
      lastVisitAt: lastVisitAt < 0 ? 0 : lastVisitAt,
      avatar: avatar,
    );
  }
}

/// 本地吧访问次数仓库（按账号隔离，持久化在 [Global.profile]）。
///
/// 每次进入某个吧（吧主页）或该吧下的帖子详情，都会给对应吧累加一次访问计数，
/// 桌面侧边栏「常逛的吧」据此排序。
class ForumVisitStore {
  ForumVisitStore._();

  static const String storageKeyPrefix = 'forumVisitStats.';

  /// 任意吧访问计数变化时 +1，供桌面侧边栏实时刷新。
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static SharedPreferences? _prefs() {
    try {
      return Global.profile;
    } catch (_) {
      return null;
    }
  }

  static String _storageKey(SharedPreferences prefs, [String? uid]) {
    final String owner = uid ?? (prefs.getString('uid') ?? '');
    return '$storageKeyPrefix$owner';
  }

  /// 读取指定账号（默认当前账号）的吧访问统计。
  static Map<String, ForumVisitRecord> load({String? uid}) {
    final SharedPreferences? prefs = _prefs();
    if (prefs == null) {
      return <String, ForumVisitRecord>{};
    }
    final String? raw = prefs.getString(_storageKey(prefs, uid));
    if (raw == null || raw.isEmpty) {
      return <String, ForumVisitRecord>{};
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, ForumVisitRecord>{};
      }
      final Map<String, ForumVisitRecord> result = <String, ForumVisitRecord>{};
      for (final MapEntry<Object?, Object?> entry in decoded.entries) {
        final String name = '${entry.key ?? ''}'.trim();
        if (name.isEmpty || entry.value is! Map) {
          continue;
        }
        final ForumVisitRecord record = ForumVisitRecord.fromJson(
          name,
          Map<String, dynamic>.from(entry.value as Map),
        );
        if (record.count > 0) {
          result[name] = record;
        }
      }
      return result;
    } catch (_) {
      return <String, ForumVisitRecord>{};
    }
  }

  /// 记录一次访问（进入吧主页或进入该吧的贴子）。
  static void recordVisit(
    String forumName, {
    String avatar = '',
    String? uid,
    DateTime? now,
  }) {
    final String name = forumName.trim();
    if (name.isEmpty) {
      return;
    }
    final SharedPreferences? prefs = _prefs();
    if (prefs == null) {
      return;
    }
    final Map<String, ForumVisitRecord> records = load(uid: uid);
    final ForumVisitRecord? existing = records[name];
    final String trimmedAvatar = avatar.trim();
    final String nextAvatar =
        trimmedAvatar.isNotEmpty ? trimmedAvatar : (existing?.avatar ?? '');
    final int timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
    records[name] = ForumVisitRecord(
      forumName: name,
      count: (existing?.count ?? 0) + 1,
      lastVisitAt: timestamp,
      avatar: nextAvatar,
    );
    prefs.setString(
      _storageKey(prefs, uid),
      jsonEncode(<String, dynamic>{
        for (final MapEntry<String, ForumVisitRecord> e in records.entries)
          e.key: e.value.toJson(),
      }),
    );
    changes.value++;
  }

  /// 清空指定账号（默认当前账号）的访问统计。
  static void clear({String? uid}) {
    final SharedPreferences? prefs = _prefs();
    if (prefs == null) {
      return;
    }
    prefs.remove(_storageKey(prefs, uid));
    changes.value++;
  }
}
