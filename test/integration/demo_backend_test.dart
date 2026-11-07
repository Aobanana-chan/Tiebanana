import 'package:flutter_test/flutter_test.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';

void main() {
  test('演示后端各页面有连贯数据，写入操作会更新本地状态', () async {
    final DemoTiebaApi api = DemoTiebaApi(latency: Duration.zero);

    expect(await api.checkLogin(), isTrue);
    final MyUserData me = await api.getMyInfo();
    expect(me.nameShow, isNotEmpty);
    expect(me.portraitUrl, startsWith('data:image/png;base64,'));
    expect(resolveAvatarUrl(me.portraitUrl), me.portraitUrl);

    final List<LikeForumInfo> likes = await api.getLikes();
    expect(likes, isNotEmpty);
    expect(likes.any((LikeForumInfo f) => f.forumName.contains('演示')), isFalse);

    final ForumPage forum =
        await api.getForumPage(kw: likes.first.forumName, pn: 1);
    expect(forum.tabs, isNotEmpty);
    expect(forum.threads, isNotEmpty);
    expect(forum.forum.name, likes.first.forumName);

    final TiebaThreadInfo first = forum.threads.first;
    final TiebaThreadPage thread = await api.getThreadPage(first.id);
    expect(thread.title, first.title);
    expect(thread.posts, isNotEmpty);
    expect(thread.posts.first.floor, '1');
    expect(thread.page.currentPage, 1);

    final InnerFloor inner =
        await api.getInnerFloor(first.id, thread.posts[1].id);
    expect(inner.post.id, thread.posts[1].id);
    expect(inner.subposts, isNotEmpty);

    final RecommendPage recommend = await api.getRecommThread(15, 1);
    expect(recommend.threads.length, 15);

    final SearchPostPage search = await api.searchPost('照片');
    expect(search.posts, isNotEmpty);
    final SearchUserResult users = await api.searchUser('猫');
    expect(users.users, isNotEmpty);

    final MessagePage messages = await api.getReply(1);
    expect(messages.items, isNotEmpty);
    expect(messages.unread, greaterThan(0));

    final ThreadStorePage store = await api.getThreadStore(0, '${me.uid}');
    expect(store.threads, isNotEmpty);

    final TiebaTopicDetail topic = await api.getTopicDetail(name: '周末去哪儿');
    final TiebaTopicThreadPage topicThreads =
        await api.getTopicThreads(name: topic.name);
    expect(topicThreads.threads, isNotEmpty);

    final SignResult sign = await api.signOneForum(likes.first.forumName);
    expect(sign.ok, isTrue);

    await api.favoForum('999', '新吧');
    expect(
      (await api.getLikes()).any((LikeForumInfo f) => f.forumName == '新'),
      isTrue,
    );
    await api.unfavoForum(fid: '999', forumName: '新吧');
    expect(
      (await api.getLikes()).any((LikeForumInfo f) => f.forumName == '新'),
      isFalse,
    );

    await api.threadAddStore(first.id, thread.posts.first.id);
    expect(
      (await api.getThreadStore(0, '${me.uid}'))
          .threads
          .any((TiebaStoredThread t) => t.id == first.id),
      isTrue,
    );
    await api.threadRemoveStore(first.id);
    expect(
      (await api.getThreadStore(0, '${me.uid}'))
          .threads
          .any((TiebaStoredThread t) => t.id == first.id),
      isFalse,
    );
  });
}
