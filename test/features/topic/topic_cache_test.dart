import 'package:flutter_test/flutter_test.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/topic/data/topic_cache.dart';

void main() {
  tearDown(TopicCache.clear);

  test('按话题名与排序分别缓存，清空后不再命中', () {
    const TiebaTopicDetail detail = TiebaTopicDetail(
      id: '28367975',
      name: 's16分锅投票',
      postNum: '95475',
    );

    TopicCache.put(
      name: 's16分锅投票',
      sort: 1,
      detail: detail,
      threads: const <TiebaThreadInfo>[],
      hasMore: true,
      lastId: '111',
      page: 1,
    );

    expect(TopicCache.get('s16分锅投票', 1)?.detail.id, '28367975');
    expect(TopicCache.get('s16分锅投票', 2), isNull);
    expect(TopicCache.get('S16分锅投票', 1), isNotNull);

    TopicCache.clear();
    expect(TopicCache.get('s16分锅投票', 1), isNull);
  });
}
