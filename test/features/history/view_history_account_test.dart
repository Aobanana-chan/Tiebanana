import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/features/history/data/dao_api.dart';
import 'package:tiebanana/features/history/data/view_history.dart';
import 'package:tiebanana/objectbox.g.dart';

void main() {
  late Directory directory;
  late Store store;
  late DAOAPI dao;
  String? uid;

  setUp(() {
    directory = Directory(
        '${Directory.current.path}/build/test_history_${DateTime.now().microsecondsSinceEpoch}')
      ..createSync(recursive: true);
    addTearDown(() => directory.deleteSync(recursive: true));
    store = Store(getObjectBoxModel(), directory: directory.path);
    addTearDown(store.close);
    uid = '1001';
    dao = DAOAPI(store: store, currentUid: () => uid);
  });

  test('同一帖子按账号独立保存，重访不覆盖另一账号或产生重复记录', () {
    dao.storeViewHistory('42', 'A 的标题', '测试吧');
    final int aId = dao.getHistoryList().single.id;
    dao.setViewHistoryHidden(aId, true);

    uid = '1002';
    expect(dao.getHistoryList(), isEmpty);
    dao.storeViewHistory('42', 'B 的标题', '测试吧');
    final int bId = dao.getHistoryList().single.id;
    expect(bId, isNot(aId));
    expect(dao.getHistoryList().single.hidden, isFalse);

    uid = '1001';
    dao.storeViewHistory('42', 'A 的新标题', '测试吧');
    expect(dao.getHistoryList().single.id, aId);
    expect(dao.getHistoryList().single.title, 'A 的新标题');
    expect(dao.getHistoryList().single.hidden, isTrue);
    expect(dao.getHistoryList(includeHidden: false), isEmpty);

    uid = '1002';
    expect(dao.getHistoryList().single.title, 'B 的标题');
    expect(store.box<ViewHistoryDatabase>().count(), 2);
  });

  test('不能通过其他账号的记录 ID 删除或修改隐藏状态', () {
    dao.storeViewHistory('42', 'A', '测试吧');
    final int aId = dao.getHistoryList().single.id;
    uid = '1002';
    dao.deleteViewHistory(aId);
    dao.setViewHistoryHidden(aId, true);

    uid = '1001';
    expect(dao.getHistoryList().single.id, aId);
    expect(dao.getHistoryList().single.hidden, isFalse);
  });

  test('分页和首页清空只作用于当前账号，完整清空也不会删除其他账号', () {
    dao.storeViewHistory('1', 'A 隐藏', '测试吧');
    dao.setViewHistoryHidden(dao.getHistoryList().single.id, true);
    dao.storeViewHistory('2', 'A 可见', '测试吧');
    uid = '1002';
    dao.storeViewHistory('3', 'B', '测试吧');
    uid = '1001';
    expect(dao.getHistoryList(offset: 1, limit: 1).length, 1);
    expect(dao.getHistoryList(offset: 2, limit: 1), isEmpty);
    dao.removeAllViewHistory(includeHidden: false);
    expect(dao.getHistoryList().single.title, 'A 隐藏');
    dao.removeAllViewHistory();
    expect(dao.getHistoryList(), isEmpty);
    uid = '1002';
    expect(dao.getHistoryList().single.title, 'B');
  });

  test('旧版无归属记录保持隔离，未登录不读写历史', () {
    final Box<ViewHistoryDatabase> box = store.box<ViewHistoryDatabase>();
    final int legacyId = box.put(ViewHistoryDatabase(
      tid: '42',
      title: '旧记录',
      forumName: '测试吧',
      latestViewTime: DateTime.now(),
    ));
    expect(dao.getHistoryList(), isEmpty);
    dao.storeViewHistory('42', 'A', '测试吧');
    final int aId = dao.getHistoryList().single.id;
    uid = null;
    expect(dao.getHistoryList(), isEmpty);
    dao.storeViewHistory('43', '未登录', '测试吧');
    dao.deleteViewHistory(aId);
    dao.setViewHistoryHidden(aId, true);
    dao.removeAllViewHistory();
    expect(box.count(), 2);
    expect(box.get(legacyId)?.title, '旧记录');
    expect(box.get(aId)?.hidden, isFalse);
    uid = '1002';
    expect(dao.getHistoryList(), isEmpty);
    dao.removeAllViewHistory();
    expect(box.count(), 2);
  });
}
