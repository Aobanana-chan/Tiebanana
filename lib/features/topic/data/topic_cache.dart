import 'package:tieba_contract/tieba_contract.dart';

/// 话题页首屏缓存（内存）。
///
/// 二次进入同一话题时先展示缓存，再在后台刷新。
/// 缓存保留 10 分钟、最多 16 条，话题头和帖子列表仍以接口数据为准。
class TopicCacheEntry {
  TopicCacheEntry({
    required this.detail,
    required this.threads,
    required this.hasMore,
    required this.lastId,
    required this.page,
    required this.savedAt,
  });

  final TiebaTopicDetail detail;
  final List<TiebaThreadInfo> threads;
  final bool hasMore;
  final String lastId;
  final int page;
  final DateTime savedAt;
}

class TopicCache {
  TopicCache._();

  static const Duration _ttl = Duration(minutes: 10);
  static const int _maxEntries = 16;

  static final Map<String, TopicCacheEntry> _entries =
      <String, TopicCacheEntry>{};

  static String _key(String name, int sort) =>
      '${name.trim().toLowerCase()}|$sort';

  static TopicCacheEntry? get(String name, int sort) {
    final TopicCacheEntry? entry = _entries[_key(name, sort)];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.savedAt) > _ttl) {
      _entries.remove(_key(name, sort));
      return null;
    }
    return entry;
  }

  static void put({
    required String name,
    required int sort,
    required TiebaTopicDetail detail,
    required List<TiebaThreadInfo> threads,
    required bool hasMore,
    required String lastId,
    required int page,
  }) {
    final String key = _key(name, sort);
    _entries.remove(key);
    _entries[key] = TopicCacheEntry(
      detail: detail,
      threads: List<TiebaThreadInfo>.unmodifiable(threads),
      hasMore: hasMore,
      lastId: lastId,
      page: page,
      savedAt: DateTime.now(),
    );
    while (_entries.length > _maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// 测试或退出登录时清空。
  static void clear() => _entries.clear();
}
