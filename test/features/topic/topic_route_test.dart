import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/app/navigation/link_router.dart';
import 'package:tiebanana/app/navigation/route_names.dart';

void main() {
  group('话题链接路由', () {
    test('旧 hotMessage 链接：topic_id=0 也进话题页', () {
      final TopicPageRouterData? data = AppUtil.topicRouteData(
        'https://tieba.baidu.com/mo/q/hotMessage?topic_id=0&fid=17019292'
        '&topic_name=s16%E5%88%86%E9%94%85%E6%8A%95%E7%A5%A8&is_video_topic=0',
        forumName: '抗压背锅',
      );

      expect(data, isNotNull);
      expect(data!.name, 's16分锅投票');
      expect(data.topicId, '');
      expect(data.fid, '17019292');
      expect(data.forumName, '抗压背锅');
    });

    test('hottopic 链接：保留真实 ID，去掉两侧 #', () {
      final TopicPageRouterData? data = AppUtil.topicRouteData(
        'https://tieba.baidu.com/hottopic/browse/hottopic'
        '?topic_id=28367975&topic_name=%23s16%E5%88%86%E9%94%85%E6%8A%95%E7%A5%A8%23',
      );

      expect(data, isNotNull);
      expect(data!.name, 's16分锅投票');
      expect(data.topicId, '28367975');
    });

    test('naTopicDetail 链接也能识别', () {
      final TopicPageRouterData? data = AppUtil.topicRouteData(
        'https://tieba.baidu.com/mo/q/hybrid-usergrow-base/naTopicDetail'
        '?from=1&topic_id=28369272&topic_name=BLG%E4%B8%89%E5%B1%80%E9%9B%B6%E5%B0%81DK',
      );

      expect(data, isNotNull);
      expect(data!.topicId, '28369272');
      expect(data.name, 'BLG三局零封DK');
    });

    test('普通帖子 / 吧链接不抢路由', () {
      expect(
        AppUtil.topicRouteData('https://tieba.baidu.com/p/123456'),
        isNull,
      );
      expect(
        AppUtil.topicRouteData(
            'https://tieba.baidu.com/f?kw=%E6%8A%97%E5%8E%8B'),
        isNull,
      );
    });
  });
}
