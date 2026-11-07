import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'thread_cache_codec.dart';
import '../../../core/diagnostics/app_log.dart';

/// 每个账号、帖子一个快照。写入串行化并原子替换；读取不延长有效期。
/// 有效期以最近一次成功获取内容的时间为准。
class ThreadCache {
  ThreadCache({DateTime Function()? now}) : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  final Lock _lock = Lock();
  Directory? _directory;
  static const ttl = Duration(days: 1);

  Future<void> init(String documentsPath) async {
    _directory = await Directory('$documentsPath/thread_cache_v1')
        .create(recursive: true);
    await cleanup();
  }

  String _key(String uid, String tid) =>
      '${base64Url.encode(utf8.encode(uid))}_${base64Url.encode(utf8.encode(tid))}';
  File? _file(String uid, String tid) => _directory == null
      ? null
      : File('${_directory!.path}/${_key(uid, tid)}.json');
  bool _expired(Map<String, dynamic> j) =>
      j['stored'] != true &&
      _now().millisecondsSinceEpoch - (j['updated'] as int) >=
          ttl.inMilliseconds;

  Future<Map<String, dynamic>?> _read(String uid, String tid) async {
    final file = _file(uid, tid);
    if (file == null || !await file.exists()) return null;
    try {
      final j = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (j['version'] != 1 || _expired(j)) return null;
      return j;
    } catch (e, stack) {
      AppLog.shared.error('cache.read_failed', e, stack);
      debugPrint('读取帖子缓存失败：$e');
      return null;
    }
  }

  Future<void> _write(String uid, String tid, Map<String, dynamic> j) async {
    final file = _file(uid, tid);
    if (file == null) return;
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(j), flush: true);
    await temp.rename(file.path);
  }

  /// 缓存损坏或磁盘写满时记录日志，在线阅读和收藏继续。
  Future<void> _safeWrite(Future<void> Function() action) async {
    try {
      await _lock.synchronized(action);
    } catch (e, stack) {
      AppLog.shared.error('cache.write_failed', e, stack);
      debugPrint('写入帖子缓存失败：$e');
    }
  }

  Future<TiebaThreadPage?> read(String uid, String tid) async {
    try {
      final j = await _lock.synchronized(() => _read(uid, tid));
      if (j == null || j['page'] == null) return null;
      final page = ThreadCacheCodec.readPage(j['page']);
      final normal = page.postPage.keys.where((k) => k > 0).toList()..sort();
      if (normal.isNotEmpty) {
        final pn = normal.contains(page.page.currentPage)
            ? page.page.currentPage
            : normal.first;
        page.posts = page.postPage[pn]!;
        final bounds = j['bounds'] as Map<String, dynamic>?;
        page.page = bounds?['$pn'] == null
            ? TiebaPageInfo(
                currentPage: pn, hasMore: page.hasMore, hasPrev: pn > 1)
            : ThreadCacheCodec.readPageInfo(bounds!['$pn']);
      }
      return page;
    } catch (e, stack) {
      AppLog.shared.error('cache.decode_failed', e, stack);
      debugPrint('解析帖子缓存失败：$e');
      return null;
    }
  }

  /// 同 ID 更新时保留旧楼层和回复，服务端未返回的条目标记为已删除。
  ///
  /// [markMissingDeleted] 为 true 时表示 [fresh] 是同一页的完整响应：旧列表里
  /// 没被返回、也不在 [aliveIds]（同一模式下其它已缓存页）中的条目标记为已删除。
  /// 缓存内容继续保留，界面据此提示删除状态。
  static List<T> mergePosts<T extends TiebaPost>(List<T> old, List<T> fresh,
      {bool markMissingDeleted = false,
      Set<String> aliveIds = const <String>{}}) {
    final Set<String> freshIds = <String>{for (final p in fresh) p.id};
    if (markMissingDeleted) {
      for (final T p in old) {
        if (!freshIds.contains(p.id) && !aliveIds.contains(p.id)) {
          p.isDeleted = true;
        }
      }
    }
    final result = <String, T>{for (final p in old) p.id: p};
    for (final p in fresh) {
      final previous = result[p.id];
      if (p is TiebaThreadPagePost && previous is TiebaThreadPagePost) {
        // 楼中楼预览通常只下发前几条；数量已齐全时，缺失的旧回复才标记为删除，
        // 未展开的旧回复保持原状。
        p.subPostList = mergePosts(previous.subPostList, p.subPostList,
            markMissingDeleted: markMissingDeleted && _subPostsComplete(p));
      }
      result[p.id] = p;
    }
    final merged = result.values.toList();
    if (merged.isNotEmpty && merged.first is TiebaThreadPagePost) {
      merged.sort((a, b) =>
          (int.tryParse((a as TiebaThreadPagePost).floor ?? '') ?? 0).compareTo(
              int.tryParse((b as TiebaThreadPagePost).floor ?? '') ?? 0));
    }
    return merged;
  }

  /// 服务端返回的楼中楼是否已包含全部回复。
  static bool _subPostsComplete(TiebaThreadPagePost p) {
    final int? declared = int.tryParse(p.subPostNumber);
    return declared != null && p.subPostList.length >= declared;
  }

  Future<void> savePage(String uid, TiebaThreadPage fresh,
          {bool onlyLz = false, bool? stored, bool completePage = true}) =>
      _safeWrite(() async {
        final j = await _read(uid, fresh.tid) ??
            <String, dynamic>{'version': 1, 'inner': <String, dynamic>{}};
        final old =
            j['page'] == null ? null : ThreadCacheCodec.readPage(j['page']);
        final pages = old?.postPage ?? fresh.postPage;
        final key = fresh.page.currentPage * (onlyLz ? -1 : 1);
        final Set<String> aliveIds = <String>{
          for (final MapEntry<int, List<TiebaThreadPagePost>> entry
              in pages.entries)
            if (entry.key != key && (entry.key < 0) == (key < 0))
              for (final TiebaThreadPagePost p in entry.value) p.id,
        };
        final posts = mergePosts<TiebaThreadPagePost>(
            pages[key] ?? [], fresh.posts,
            markMissingDeleted: completePage, aliveIds: aliveIds);
        // 新响应对象不与磁盘读出的对象共享聚合状态。
        final snapshot =
            ThreadCacheCodec.readPage(ThreadCacheCodec.page(fresh));
        snapshot.postPage.addAll(pages);
        snapshot.postPage[key] = posts;
        snapshot.userListSet = {...?old?.userListSet, ...fresh.userListSet};
        snapshot.videoInfo ??= old?.videoInfo;
        final bounds = j.putIfAbsent('bounds', () => <String, dynamic>{})
            as Map<String, dynamic>;
        bounds['$key'] = ThreadCacheCodec.pageInfo(fresh.page);
        final normal = snapshot.postPage.keys.where((k) => k > 0).toList()
          ..sort();
        if (normal.isNotEmpty) {
          snapshot.hasMore = bounds['${normal.last}']?['hasMore'] ?? true;
          snapshot.hasPrev =
              bounds['${normal.first}']?['hasPrev'] ?? (normal.first > 1);
        }
        j['page'] = ThreadCacheCodec.page(snapshot);
        j['stored'] = stored ?? fresh.isStored;
        j['updated'] = _now().millisecondsSinceEpoch;
        await _write(uid, fresh.tid, j);
      });

  Future<void> setStored(String uid, String tid, bool stored,
          {bool keepLongTerm = true}) =>
      _safeWrite(() async {
        final j = await _read(uid, tid);
        if (j == null) return;
        j['stored'] = stored && keepLongTerm;
        j['page']['isStored'] = stored;
        // 取消收藏后给予一天短期保留期。
        if (!stored) j['updated'] = _now().millisecondsSinceEpoch;
        await _write(uid, tid, j);
      });

  /// 收藏列表网络失败时仍可进入长期保存的帖子。
  Future<List<TiebaStoredThread>> storedThreads(String uid) async {
    return _lock.synchronized(() async {
      final result = <TiebaStoredThread>[];
      if (_directory == null) return result;
      final prefix = '${base64Url.encode(utf8.encode(uid))}_';
      await for (final entry in _directory!.list()) {
        if (entry is! File ||
            !entry.uri.pathSegments.last.startsWith(prefix) ||
            !entry.path.endsWith('.json')) {
          continue;
        }
        try {
          final j =
              jsonDecode(await entry.readAsString()) as Map<String, dynamic>;
          if (j['stored'] != true || j['version'] != 1) continue;
          final p = ThreadCacheCodec.readPage(j['page']);
          final post = p.postList.firstOrNull ?? p.posts.firstOrNull;
          result.add(TiebaStoredThread(
              id: p.tid,
              pid: '',
              isFollowed: true,
              isDeleted: false,
              postNo: null,
              postNoMsg: '本地缓存',
              title: p.title,
              media: null,
              count: '0',
              portrait: post?.portrait ?? '',
              uid: post?.uid ?? '',
              nameShow: post?.nameShow,
              username: post?.username));
        } catch (e) {
          debugPrint('读取本地收藏失败：$e');
        }
      }
      result.sort((a, b) => a.id.compareTo(b.id));
      return result;
    });
  }

  Future<Map<int, InnerFloor>> readInner(
      String uid, String tid, String pid) async {
    try {
      final j = await _lock.synchronized(() => _read(uid, tid));
      final pages = (j?['inner']?[pid] as Map<String, dynamic>?) ?? {};
      return pages
          .map((k, v) => MapEntry(int.parse(k), ThreadCacheCodec.readInner(v)));
    } catch (e) {
      debugPrint('解析楼中楼缓存失败：$e');
      return {};
    }
  }

  Future<void> saveInner(String uid, String tid, String pid, InnerFloor floor,
          {bool completePage = true}) =>
      _safeWrite(() async {
        final j = await _read(uid, tid);
        if (j == null) return;
        final inner = j['inner'] as Map<String, dynamic>;
        final pages = inner.putIfAbsent(pid, () => <String, dynamic>{})
            as Map<String, dynamic>;
        final key = '${floor.page.currentPage}';
        final old =
            pages[key] == null ? null : ThreadCacheCodec.readInner(pages[key]);
        final Set<String> aliveIds = <String>{
          for (final MapEntry<String, dynamic> entry in pages.entries)
            if (entry.key != key)
              for (final TiebaSubPost p
                  in ThreadCacheCodec.readInner(entry.value).subposts)
                p.id,
        };
        pages[key] = ThreadCacheCodec.inner(InnerFloor(
            post: floor.post,
            subposts: mergePosts(old?.subposts ?? [], floor.subposts,
                markMissingDeleted: completePage, aliveIds: aliveIds),
            page: floor.page,
            thread: floor.thread,
            authors: {...?old?.authors, ...floor.authors}));
        j['updated'] = _now().millisecondsSinceEpoch;
        await _write(uid, tid, j);
      });

  /// 启动时清理过期普通帖、损坏/旧版本快照和中断写入的临时文件。
  Future<void> cleanup() => _safeWrite(() async {
        if (_directory == null) return;
        await for (final entry in _directory!.list()) {
          if (entry is! File) continue;
          try {
            final j =
                jsonDecode(await entry.readAsString()) as Map<String, dynamic>;
            if (entry.path.endsWith('.tmp') ||
                j['version'] != 1 ||
                _expired(j)) {
              await entry.delete();
            } else {
              ThreadCacheCodec.readPage(j['page']);
            }
          } catch (_) {
            if (await entry.exists()) await entry.delete();
          }
        }
      });
}

/// 同一次阅读中，主帖与楼中楼共享请求熔断状态。
class ThreadReadSession extends ChangeNotifier {
  bool paused = false;
  String? error;
  void fail(Object e) {
    paused = true;
    error = e.toString();
    notifyListeners();
  }

  void retry() {
    paused = false;
    error = null;
    notifyListeners();
  }
}
