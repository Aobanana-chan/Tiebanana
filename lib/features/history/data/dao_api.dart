import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/features/history/data/view_history.dart';
import 'package:tiebanana/objectbox.g.dart';

class DAOAPI {
  DAOAPI({Store? store, String? Function()? currentUid})
      : _currentUid = currentUid ?? (() => AccountStore.currentUid) {
    if (store != null) {
      _store = store;
    }
  }

  final String? Function() _currentUid;
  late final Store _store;
  Future<void> init() async {
    _store = await openStore();
  }

  ///获取历史记录
  ///
  ///[includeHidden] 为 true（默认）时返回全部，浏览历史页用；
  ///首页只查未隐藏的记录，需要传 false。
  List<ViewHistoryDatabase> getHistoryList(
      {int? offset, int? limit, bool includeHidden = true}) {
    final String? uid = _currentUid();
    if (uid == null || uid.isEmpty) return [];
    final box = _store.box<ViewHistoryDatabase>();
    final owner = ViewHistoryDatabase_.uid.equals(uid);
    final qBuilder = box.query(includeHidden
        ? owner
        : owner & ViewHistoryDatabase_.hidden.equals(false));
    qBuilder.order(ViewHistoryDatabase_.latestViewTime,
        flags: Order.descending | Order.caseSensitive);
    var query = qBuilder.build();
    if (offset != null || limit != null) {
      query
        ..offset = offset ?? 0
        ..limit = limit ?? 0;
    }
    final List<ViewHistoryDatabase> result = query.find();
    query.close();
    return result;
  }

  ///更新历史记录
  ///
  ///同一账号的同一个 tid 再次浏览时刷新时间与标题，同时保留原有的 [ViewHistoryDatabase.hidden]，
  ///隐藏状态在再次浏览后仍然有效。
  void storeViewHistory(String tid, String title, String forumName) {
    final String? uid = _currentUid();
    if (uid == null || uid.isEmpty) return;
    final box = _store.box<ViewHistoryDatabase>();
    final query = box
        .query(ViewHistoryDatabase_.uid.equals(uid) &
            ViewHistoryDatabase_.tid.equals(tid))
        .build();
    final ViewHistoryDatabase? exist = query.findFirst();
    query.close();
    var time = DateTime.now();
    final item = ViewHistoryDatabase(
      uid: uid,
      forumName: forumName,
      tid: tid,
      title: title,
      latestViewTime: time,
      hidden: exist?.hidden ?? false,
    )..id = exist?.id ?? 0;
    box.put(item);
  }

  ///删除历史记录
  void deleteViewHistory(int id) {
    final String? uid = _currentUid();
    if (uid == null || uid.isEmpty) return;
    final box = _store.box<ViewHistoryDatabase>();
    if (box.get(id)?.uid == uid) {
      box.remove(id);
    }
  }

  ///设置单条历史记录在首页的隐藏状态
  void setViewHistoryHidden(int id, bool hidden) {
    final String? uid = _currentUid();
    if (uid == null || uid.isEmpty) return;
    final box = _store.box<ViewHistoryDatabase>();
    final ViewHistoryDatabase? item = box.get(id);
    if (item == null || item.uid != uid) {
      return;
    }
    item.hidden = hidden;
    box.put(item);
  }

  ///清空历史记录
  ///
  ///[includeHidden] 为 false 时只清掉首页可见（未隐藏）的记录，
  ///隐藏的记录仍保留在浏览历史页。
  void removeAllViewHistory({bool includeHidden = true}) {
    final String? uid = _currentUid();
    if (uid == null || uid.isEmpty) return;
    final box = _store.box<ViewHistoryDatabase>();
    final owner = ViewHistoryDatabase_.uid.equals(uid);
    final query = box
        .query(includeHidden
            ? owner
            : owner & ViewHistoryDatabase_.hidden.equals(false))
        .build();
    box.removeMany(query.findIds());
    query.close();
  }
}
