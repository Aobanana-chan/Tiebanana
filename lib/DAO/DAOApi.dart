import 'package:tiebanana/Json_Model/Database/ViewHistory.dart';
import 'package:tiebanana/objectbox.g.dart';

class DAOAPI {
  late final Store _store;
  Future<void> init() async {
    _store = await openStore();
  }

  ///获取历史记录
  List<ViewHistoryDatabase> getHistoryList({int? offset, int? limit}) {
    final box = _store.box<ViewHistoryDatabase>();
    var qBuilder = box.query()
      ..order(ViewHistoryDatabase_.latestViewTime,
          flags: Order.descending | Order.caseSensitive);
    var query = qBuilder.build();
    if (offset == null && limit == null) {
      return query.find();
    } else {
      query
        ..offset = offset!
        ..limit = limit!;
      return query.find();
    }
  }

  ///更新历史记录
  void storeViewHistory(String tid, String titile, String forumName) {
    final box = _store.box<ViewHistoryDatabase>();
    var time = DateTime.now();
    box.put(ViewHistoryDatabase(
      forumName: forumName,
      tid: tid,
      title: titile,
      latestViewTime: time,
    ));
  }

  ///删除历史记录
  void deleteViewHistory(int id) {
    final box = _store.box<ViewHistoryDatabase>();
    box.remove(id);
  }

  ///清空历史记录
  void removeAllViewHistory() {
    final box = _store.box<ViewHistoryDatabase>();
    box.removeAll();
  }
}
