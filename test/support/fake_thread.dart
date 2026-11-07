// 测试夹具：用契约数据类造推荐流数据。
import 'package:tieba_contract/tieba_contract.dart';

/// 造一个作者。
TiebaAuthor fakeAuthor({String uid = '7', String name = '青葉ナナ'}) =>
    TiebaAuthor(
      icons: const [],
      levelID: '7',
      nameShow: name,
      portrait: 'tb.1.avatar',
      uid: uid,
      username: name,
    );

/// 造一条推荐流帖子（对齐 `TiebaThreadInfo`）。
TiebaThreadInfo fakeThreadInfo({
  String tid = '1',
  String title = 'Flutter 3.47 升级踩坑记录，附完整迁移清单',
  String fname = 'Flutter',
  String text = '正文摘要，够两行就行',
  int hoursAgo = 2,
}) {
  final DateTime now = DateTime.now();
  return TiebaThreadInfo(
    id: tid,
    title: title,
    fname: fname,
    createTime:
        '${now.subtract(Duration(hours: hoursAgo + 6)).millisecondsSinceEpoch ~/ 1000}',
    lastTimeInt:
        '${now.subtract(Duration(hours: hoursAgo)).millisecondsSinceEpoch ~/ 1000}',
    viewNum: '12000',
    replyNum: '46',
    agreeNum: '128',
    disagreeNum: '3',
    isTop: false,
    author: fakeAuthor(),
    firstPostContent: [TiebaTextContent(text: text, uid: '7')],
  );
}

/// 推荐流一条帖子（旧名，保持测试可读性）。
TiebaThreadInfo fakeRecommendThread({
  String tid = '1',
  String title = 'Flutter 3.47 升级踩坑记录，附完整迁移清单',
  String fname = 'Flutter',
  String text = '正文摘要，够两行就行',
  int hoursAgo = 2,
}) =>
    fakeThreadInfo(
        tid: tid, title: title, fname: fname, text: text, hoursAgo: hoursAgo);

/// 一页推荐响应。
RecommendPage fakeRecommendPage(List<TiebaThreadInfo> threads) =>
    RecommendPage(threads: threads);
