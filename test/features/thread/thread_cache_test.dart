import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/thread/data/thread_cache.dart';
import 'package:tiebanana/features/thread/data/thread_cache_codec.dart';

TiebaSubPost reply(String id) => TiebaSubPost(
    id: id,
    title: '',
    isVoice: false,
    content: [TiebaTextContent(text: 'reply $id')],
    createTime: '1',
    isInnerFloor: true,
    portrait: '',
    uid: 'u',
    nameShow: '用户',
    username: 'user');

TiebaThreadPagePost post(String id, {String text = '正文'}) =>
    TiebaThreadPagePost(
        id: id,
        title: '',
        floor: id,
        lbsInfo: '',
        ipLocation: '上海',
        subPostList: [reply('s$id')],
        subPostNumber: '1',
        content: [TiebaTextContent(text: text)],
        createTime: '1',
        isFirstFloor: id == '1',
        isInnerFloor: false,
        portrait: '',
        uid: 'u',
        nameShow: '用户',
        username: 'user');

TiebaThreadPage page(
        {int pn = 1,
        bool stored = false,
        List<String> ids = const ['1', '2']}) =>
    TiebaThreadPage(
        posts: ids.map(post).toList(),
        page: TiebaPageInfo(currentPage: pn, hasMore: true, hasPrev: pn > 1),
        thread: TiebaThreadData(agreeType: '0', storeCount: 10, authorUid: 'u'),
        userListSet: {
          'u': TiebaAuthor(
              icons: ['x'],
              levelID: '3',
              forumRole: TiebaForumRole.assistant,
              nameShow: '用户',
              portrait: '',
              uid: 'u',
              username: 'user')
        },
        videoInfo: TiebaVideoInfo(videoUrl: 'video', thumbnailUrl: 'cover'),
        isStored: stored,
        tid: '123',
        title: '缓存测试',
        fid: '9',
        forumName: '测试',
        avatar: '');

void main() {
  late Directory dir;
  late DateTime now;
  late ThreadCache cache;
  setUp(() async {
    dir = await Directory('build').createTemp('tiebanana_thread_cache_test_');
    now = DateTime.utc(2026, 10, 28);
    cache = ThreadCache(now: () => now);
    await cache.init(dir.path);
  });
  tearDown(() async => dir.delete(recursive: true));

  test('投票随主题及楼层缓存，旧缓存没有投票字段仍可读取', () async {
    final fresh = page();
    final poll = TiebaPoll(
        title: '投票',
        multiple: true,
        participantCount: 2,
        totalVotes: 3,
        hasVoted: true,
        selectedIds: {7},
        options: const [TiebaPollOption(id: 7, text: '甲', votes: 3)]);
    fresh.thread = TiebaThreadData(agreeType: '0', poll: poll, hasPoll: true);
    final floorJson = ThreadCacheCodec.post(fresh.posts.last)
      ..['hasPoll'] = true
      ..['poll'] = ThreadCacheCodec.poll(poll);
    fresh.posts.last =
        ThreadCacheCodec.readPost(floorJson) as TiebaThreadPagePost;
    await cache.savePage('a', fresh);
    final read = (await cache.read('a', '123'))!;
    expect(read.thread.poll?.totalVotes, 3);
    expect(read.posts.last.poll?.selectedIds, {7});
    expect(read.posts.last.hasPoll, true);
    final old = ThreadCacheCodec.page(page())
      ..remove('poll')
      ..remove('hasPoll');
    expect(ThreadCacheCodec.readPage(old).thread.poll, isNull);
  });

  test('所有帖子短期缓存，读取不续期，24小时到期且启动清理', () async {
    await cache.savePage('a', page());
    now = now.add(const Duration(hours: 23));
    expect((await cache.read('a', '123'))!.title, '缓存测试');
    expect((await cache.read('a', '123'))!.thread.authorUid, 'u');
    expect((await cache.read('a', '123'))!.userListSet['u']!.forumRole,
        TiebaForumRole.assistant);
    now = now.add(const Duration(hours: 1));
    expect(await cache.read('a', '123'), isNull);
    await cache.init(dir.path);
    expect(await Directory('${dir.path}/thread_cache_v1').list().length, 0);
  });

  test('收藏长期保留，取消后降为一天，账号隔离，重建可恢复', () async {
    await cache.savePage('a', page(stored: true));
    now = now.add(const Duration(days: 100));
    cache = ThreadCache(now: () => now);
    await cache.init(dir.path);
    expect((await cache.read('a', '123'))!.isStored, isTrue);
    expect(await cache.read('b', '123'), isNull);
    expect((await cache.storedThreads('a')).single.id, '123');
    await cache.setStored('a', '123', false);
    expect((await cache.read('a', '123'))!.isStored, isFalse);
    expect(await cache.storedThreads('a'), isEmpty);
    now = now.add(const Duration(days: 1));
    expect(await cache.read('a', '123'), isNull);
  });

  test('关闭长期缓存不影响普通帖缓存和真实收藏状态', () async {
    await cache.savePage('a', page(stored: true), stored: false);
    await cache.setStored('a', '123', true, keepLongTerm: false);
    expect((await cache.read('a', '123'))!.isStored, isTrue);
    expect(await cache.storedThreads('a'), isEmpty);
    now = now.add(const Duration(days: 1));
    expect(await cache.read('a', '123'), isNull);
  });

  test('分页、只看楼主、删楼标记及同ID增量更新', () async {
    await cache.savePage('a', page());
    await cache.savePage('a', page(pn: 2, ids: ['3']));
    final fresh = page(ids: ['2']);
    fresh.posts.single.content = [TiebaTextContent(text: '更新正文')];
    fresh.posts.single.subPostList = [reply('new')];
    await cache.savePage('a', fresh);
    await cache.savePage('a', page(ids: ['1']), onlyLz: true);
    final loaded = (await cache.read('a', '123'))!;
    expect(loaded.postPage.keys, [-1, 1, 2]);
    expect(loaded.postList.map((p) => p.id), ['1', '2', '3']);
    expect(loaded.postList.first.isDeleted, isTrue);
    expect(loaded.postList[1].isDeleted, isFalse);
    expect(
        (loaded.postList[1].content.single as TiebaTextContent).text, '更新正文');
    expect(loaded.postList[1].subPostList.map((p) => p.id), ['s2', 'new']);
    expect(loaded.userListSet['u']!.levelID, '3');
    expect(loaded.videoInfo!.videoUrl, 'video');
  });

  test('楼中楼分页长期保存，同ID更新且标记被删回复', () async {
    await cache.savePage('a', page(stored: true));
    InnerFloor inner(int pn, List<String> ids) => InnerFloor(
        post: post('2'),
        subposts: ids.map(reply).toList(),
        page: TiebaPageInfo(currentPage: pn, hasMore: pn == 1, hasPrev: pn > 1),
        thread: TiebaThreadData(agreeType: '0'),
        authors: page().userListSet);
    await cache.saveInner('a', '123', '2', inner(1, ['a', 'b']));
    await cache.saveInner('a', '123', '2', inner(2, ['c']));
    await cache.saveInner('a', '123', '2', inner(1, ['b', 'd']));
    now = now.add(const Duration(days: 60));
    await cache.init(dir.path);
    final loaded = await cache.readInner('a', '123', '2');
    expect(loaded.keys, [1, 2]);
    expect(loaded[1]!.subposts.map((p) => p.id), ['a', 'b', 'd']);
    expect(loaded[1]!.subposts.first.isDeleted, isTrue);
    expect(loaded[1]!.subposts[1].isDeleted, isFalse);
    expect(loaded[2]!.subposts.single.id, 'c');
  });

  test('相邻页仍存在的楼层不因分页边界变化误标删除', () async {
    await cache.savePage('a', page(ids: ['1', '2']));
    await cache.savePage('a', page(pn: 2, ids: ['3', '4']));
    // 第 1 楼删除后，第 3 楼前移到第 1 页；第 2 页旧缓存里的 3 不是被删除。
    await cache.savePage('a', page(ids: ['2', '3']));
    await cache.savePage('a', page(pn: 2, ids: ['4', '5']));
    final loaded = (await cache.read('a', '123'))!;
    expect(loaded.postPage[1]!.map((p) => p.id), ['1', '2', '3']);
    expect(loaded.postPage[2]!.map((p) => p.id), ['3', '4', '5']);
    expect(
        loaded.postPage[2]!.firstWhere((p) => p.id == '3').isDeleted, isFalse);
    expect(
        loaded.postPage[1]!.firstWhere((p) => p.id == '1').isDeleted, isTrue);
  });

  test('不完整的楼中楼预览不把未下发的旧回复标成删除', () {
    final old = post('2')
      ..subPostNumber = '5'
      ..subPostList = [reply('a'), reply('b')];
    final fresh = post('2')
      ..subPostNumber = '5'
      ..subPostList = [reply('b'), reply('c')];
    final merged = ThreadCache.mergePosts<TiebaThreadPagePost>([old], [fresh],
        markMissingDeleted: true);
    expect(merged.single.subPostList.map((p) => p.id), ['a', 'b', 'c']);
    expect(merged.single.subPostList.first.isDeleted, isFalse);
  });

  test('全部内容段显式类型往返，图片音视频元数据不丢失', () {
    final contents = <TiebaPostContent>[
      TiebaTextContent(text: '文字', type: TiebaContentType.textPlugin),
      TiebaImageContent(
          src: 'thumb',
          originSrc: 'original',
          bsize: '10,20',
          type: TiebaContentType.meme),
      TiebaAtContent(text: '@人', uid: 'u'),
      TiebaEmojiContent(
          c: '笑',
          text: 'emoji',
          dynamicUrl: 'gif',
          type: TiebaContentType.gifEmotion),
      TiebaVideoContent(link: 'video', cover: 'cover'),
      TiebaLinkContent(
          text: '链接',
          link: 'https://example.org',
          type: TiebaContentType.tiebaPlus),
      TiebaPhoneContent(text: '123'),
      TiebaVoiceContent(text: '语音', voiceMd5: 'md5', duringTime: 10),
      TiebaTopicContent(text: '话题', link: 'topic'),
      TiebaVideoLinkContent(text: '视频', link: 'video'),
    ];
    for (final c in contents) {
      final j = ThreadCacheCodec.content(c);
      expect(ThreadCacheCodec.content(ThreadCacheCodec.readContent(j)), j);
    }
  });

  test('损坏及中断文件清理，不删除长期快照', () async {
    await cache.savePage('a', page(stored: true));
    await File('${dir.path}/thread_cache_v1/broken.json').writeAsString('bad');
    await File('${dir.path}/thread_cache_v1/interrupted.tmp')
        .writeAsString('{}');
    await cache.cleanup();
    expect(await Directory('${dir.path}/thread_cache_v1').list().length, 1);
    expect(await cache.read('a', '123'), isNotNull);
  });

  test('并发更新串行保存，不丢分页', () async {
    await Future.wait([
      for (int i = 1; i <= 8; i++) cache.savePage('a', page(pn: i, ids: ['$i']))
    ]);
    expect((await cache.read('a', '123'))!.postPage.length, 8);
  });
}
