import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/forum/state/forum_state.dart';

class _FailedForumApi extends DemoTiebaApi {
  final pending = Completer<void>();
  int refreshCalls = 0;
  int readCalls = 0;

  @override
  bool get isLogin => true;

  @override
  Future<void> refreshLikes() async {
    refreshCalls++;
    await pending.future;
    throw StateError('1990006 请重新登录');
  }

  @override
  Future<List<LikeForumInfo>> getLikes() async {
    readCalls++;
    return const [];
  }
}

class _LoginTransitionApi extends DemoTiebaApi {
  bool sessionActive = false;
  int refreshCalls = 0;

  @override
  bool get isLogin => sessionActive;

  @override
  Future<void> refreshLikes() async {
    refreshCalls++;
  }

  @override
  Future<List<LikeForumInfo>> getLikes() async => [
        LikeForumInfo(
            forumId: '1', forumName: 'followed', avatar: '',
            isSign: '0', levelId: '1'),
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('关注列表失败保留旧数据，合并并发刷新，不隐式读取重试', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    final api = _FailedForumApi();
    Global.tiebaAPI = api;
    final state = ForumState();
    addTearDown(state.dispose);
    final forum = LikeForumInfo(
      forumId: '1',
      forumName: 'cached',
      avatar: '',
      isSign: '0',
      levelId: '1',
    );
    state.forums.add(forum);
    final first = state.refresh();
    final second = state.refresh();
    api.pending.complete();
    await Future.wait([first, second]);

    expect(api.refreshCalls, 1);
    expect(api.readCalls, 0);
    expect(state.error, isA<StateError>());
    expect(state.forums.single, same(forum));
  });

  test('未登录刷新完成后，登录仍会请求关注列表，后续刷新不被锁住', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    final api = _LoginTransitionApi();
    Global.tiebaAPI = api;
    final state = ForumState();
    addTearDown(state.dispose);
    await state.refresh();
    expect(api.refreshCalls, 0);

    api.sessionActive = true;
    await state.refresh();
    expect(api.refreshCalls, 1);
    expect(state.forums.single.forumName, 'followed');
    expect(state.error, isNull);

    await state.refresh();
    expect(api.refreshCalls, 2);
  });
}
