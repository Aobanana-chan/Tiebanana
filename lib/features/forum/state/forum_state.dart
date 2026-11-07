import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';

///吧状态Model
class ForumState with ChangeNotifier {
  Object? error;
  Future<void>? _refreshTask;
  bool _disposed = false;
  final List<LikeForumInfo> _forums = [];
  List<LikeForumInfo> get forums {
    return _forums;
  }

  ForumState() {
    Global.signEvents.addListener(_onForumSigned);
    refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    Global.signEvents.removeListener(_onForumSigned);
    super.dispose();
  }

  /// 后端每签完一个吧都会广播一次：把本地的「已签到」标识原地改掉，
  /// 首页据此更新，无需等待整轮签到结束。
  void _onForumSigned() {
    final SignForumResult? result = Global.signEvents.last;
    if (result == null || !result.success) {
      return;
    }
    bool changed = false;
    for (int i = 0; i < _forums.length; i++) {
      final LikeForumInfo forum = _forums[i];
      if (forum.forumName == result.forumName && forum.isSign != '1') {
        _forums[i] = LikeForumInfo(
          forumId: forum.forumId,
          forumName: forum.forumName,
          avatar: forum.avatar,
          levelId: forum.levelId,
          isSign: '1',
        );
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// 首页吧排序按账号隔离：`homeForumOrder.<uid>` 存 forumId 列表。
  static const String orderKeyPrefix = 'homeForumOrder.';

  String get _orderKey {
    final String uid = Global.profile.getString('uid') ?? '';
    return '$orderKeyPrefix$uid';
  }

  List<String> get _savedOrder =>
      Global.profile.getStringList(_orderKey) ?? <String>[];

  // 未登录分支没有 await，直接调用会先执行 finally 清空任务，再被 ??=
  // 写回已完成 Future，导致随后登录时永远复用空刷新、不请求关注列表。
  Future<void> refresh() => _refreshTask ??= Future<void>.microtask(_refresh);

  Future<void> _refresh() async {
    try {
      error = null;
      if (Global.tiebaAPI.isLogin) {
        await Global.tiebaAPI.refreshLikes();
        final List<LikeForumInfo> likes = await Global.tiebaAPI.getLikes();
        final List<LikeForumInfo> loaded = likes.toList();
        _forums
          ..clear()
          ..addAll(_applyOrder(loaded));
      }
    } catch (e) {
      // 保留旧列表，错误交给调用方展示。
      error = e;
    } finally {
      _refreshTask = null;
      if (!_disposed) notifyListeners();
    }
  }

  /// 按本地保存的顺序重排：保存过的按顺序在前，新关注的按服务端顺序追加，
  /// 已取关的自然消失。
  List<LikeForumInfo> _applyOrder(List<LikeForumInfo> list) {
    final List<String> order = _savedOrder;
    if (order.isEmpty) {
      return list;
    }
    final Map<String, LikeForumInfo> byId = <String, LikeForumInfo>{
      for (final LikeForumInfo f in list) f.forumId: f
    };
    final List<LikeForumInfo> ordered = <LikeForumInfo>[];
    for (final String id in order) {
      final LikeForumInfo? f = byId.remove(id);
      if (f != null) {
        ordered.add(f);
      }
    }
    ordered
        .addAll(list.where((LikeForumInfo f) => byId.containsKey(f.forumId)));
    return ordered;
  }

  /// 保存用户拖动后的顺序（按账号）。
  void saveForumOrder(List<LikeForumInfo> ordered) {
    _forums
      ..clear()
      ..addAll(ordered);
    Global.profile.setStringList(
        _orderKey, ordered.map((LikeForumInfo e) => e.forumId).toList());
    notifyListeners();
  }
}
