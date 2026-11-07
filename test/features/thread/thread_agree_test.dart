import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/features/thread/widgets/thread_common.dart';

class _RecordingAgreeApi extends DemoTiebaApi {
  _RecordingAgreeApi() : super(latency: Duration.zero);

  final calls = <List<Object?>>[];
  bool reject = false;

  @override
  Future<void> agreePost(String postID, String threadID, int objType,
      {String? forumId, int agreeType = 2, int opType = 0}) async {
    calls.add([postID, threadID, objType, forumId, agreeType, opType]);
    if (reject) throw StateError('点赞对象类型错误');
  }
}

void main() {
  for (final objType in [1, 2, 3]) {
    test('类型 $objType 赞踩和取消均保留目标、主题与吧 ID', () async {
      final api = _RecordingAgreeApi();
      Global.tiebaAPI = api;
      addTearDown(() => Global.tiebaAPI = DemoTiebaApi());
      final controller = ThreadAgreeController(
        postId: '123',
        threadId: '456',
        forumId: '789',
        objType: objType,
        agreeNum: 0,
        disagreeNum: 0,
        hasAgree: '0',
        agreeType: 0,
      );
      addTearDown(controller.dispose);

      await controller.toggleLike();
      await controller.toggleDislike();
      await controller.toggleLike();
      await controller.toggleLike();

      expect(api.calls, [
        ['123', '456', objType, '789', 2, 0],
        ['123', '456', objType, '789', 2, 1],
        ['123', '456', objType, '789', 5, 0],
        ['123', '456', objType, '789', 5, 1],
        ['123', '456', objType, '789', 2, 0],
        ['123', '456', objType, '789', 2, 1],
      ]);
      expect(controller.liked, isFalse);
      expect(controller.disliked, isFalse);
      expect(controller.agreeNum, 0);
      expect(controller.disagreeNum, 0);
    });
    test('类型 $objType 请求失败不改变点赞状态，且可再次操作', () async {
      final api = _RecordingAgreeApi()..reject = true;
      Global.tiebaAPI = api;
      addTearDown(() => Global.tiebaAPI = DemoTiebaApi());
      final controller = ThreadAgreeController(
        postId: '123',
        threadId: '456',
        objType: objType,
        agreeNum: 10,
        disagreeNum: 0,
        hasAgree: '0',
        agreeType: 0,
      );
      addTearDown(controller.dispose);
      await expectLater(controller.toggleLike(), throwsStateError);
      expect(controller.liked, isFalse);
      expect(controller.agreeNum, 10);
      expect(controller.busy, isFalse);
      expect(api.calls, hasLength(1));
      api.reject = false;
      await controller.toggleLike();
      expect(controller.liked, isTrue);
      expect(controller.agreeNum, 11);
    });
    testWidgets('类型 $objType 点赞按钮传递目标类型与吧 ID', (tester) async {
      final api = _RecordingAgreeApi();
      Global.tiebaAPI = api;
      addTearDown(() => Global.tiebaAPI = DemoTiebaApi());
      await tester.pumpWidget(MaterialApp(
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        home: Scaffold(
          body: ThreadVoteBar(
            postId: '123',
            threadId: '456',
            forumId: '789',
            objType: objType,
            agreeNum: 0,
            disagreeNum: 0,
            hasAgree: '0',
            agreeType: 0,
          ),
        ),
      ));
      await tester.tap(find.byTooltip('点赞'));
      await tester.pump();
      await tester.tap(find.byTooltip('取消点赞'));
      await tester.pump();
      expect(api.calls, [
        ['123', '456', objType, '789', 2, 0],
        ['123', '456', objType, '789', 2, 1],
      ]);
    });
  }
}
