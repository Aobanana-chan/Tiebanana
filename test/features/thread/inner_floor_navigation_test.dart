import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/profile/pages/user_profile_page.dart';
import 'package:tiebanana/features/thread/data/thread_cache.dart';
import 'package:tiebanana/features/thread/widgets/thread_floor_card.dart';
import 'package:tiebanana/shared/content/special_span.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

Widget _host(Widget child, {void Function(RouteSettings)? onRoute}) {
  return ChangeNotifierProvider<APPSettingProvider>(
    create: (_) => APPSettingProvider(),
    child: MaterialApp(
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      onGenerateRoute: onRoute == null
          ? null
          : (RouteSettings settings) {
              onRoute(settings);
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const Scaffold(body: Text('用户资料')),
              );
            },
      home: Scaffold(body: child),
    ),
  );
}

TiebaSubPost _subPost(String id, String text, String uid) => TiebaSubPost(
      id: id,
      title: '',
      isVoice: false,
      content: <TiebaPostContent>[TiebaTextContent(text: text, uid: uid)],
      createTime: '',
      isInnerFloor: true,
      portrait: '',
      uid: uid,
      nameShow: '用户$uid',
      username: '用户$uid',
    );

class _CountingApi extends DemoTiebaApi {
  _CountingApi() : super(latency: Duration.zero);
  int userCalls = 0;

  @override
  Future<TiebaUserProfile> getUserInfo({required String uid, int pn = 1}) {
    userCalls++;
    return super.getUserInfo(uid: uid, pn: pn);
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
  });

  testWidgets('楼中楼正文不跳用户页，只有 @ 段可跳转', (tester) async {
    RouteSettings? opened;
    final TiebaSubPost post =
        _subPost('s1', '普通正文', '123');
    await tester.pumpWidget(_host(
      InnerPost(posts: post.content),
      onRoute: (RouteSettings settings) => opened = settings,
    ));

    await tester.tap(find.text('普通正文', findRichText: true));
    await tester.pumpAndSettle();
    expect(opened, isNull, reason: '正文文字不应打开用户页');

    opened = null;
    await tester.pumpWidget(_host(
      InnerPost(
        posts: <TiebaPostContent>[
          TiebaAtContent(text: '@某人', uid: '456'),
        ],
      ),
      onRoute: (RouteSettings settings) => opened = settings,
    ));
    await tester.tap(find.text('@某人', findRichText: true));
    await tester.pumpAndSettle();
    expect(opened?.name, PageRouter.user);
    expect(opened?.arguments, '456');
  });

  testWidgets('非法 uid 的 @ 段不挂跳转识别器', (tester) async {
    await tester.pumpWidget(_host(const SizedBox()));
    final BuildContext context = tester.element(find.byType(Scaffold));
    expect(AtUserSpan(context, text: '@空', uid: '').recognizer, isNull);
    expect(AtUserSpan(context, text: '@零', uid: '0').recognizer, isNull);
    expect(AtUserSpan(context, text: '@某人', uid: '456').recognizer, isNotNull);
  });

  testWidgets('无效 uid 的用户页直接提示，不发请求', (tester) async {
    final _CountingApi api = _CountingApi();
    Global.tiebaAPI = api;
    await tester.pumpWidget(_host(const UserVisitor(uid: '0')));
    await tester.pump();

    expect(find.text('找不到该用户'), findsOneWidget);
    expect(api.userCalls, 0);
  });

  testWidgets('点击楼中楼预览正文打开面板并带上锚点回复', (tester) async {
    Global.tiebaAPI = DemoTiebaApi(latency: Duration.zero);
    final TiebaThreadPage page = await Global.tiebaAPI.getThreadPage('123');
    final TiebaAuthor author = page.userListSet.values.first;
    final TiebaSubPost post = _subPost('s1', '楼中楼正文', author.uid);

    await tester.pumpWidget(_host(
      InnerFloorEntry(
        subPostList: <TiebaSubPost>[post],
        userlist: <String, TiebaAuthor>{author.uid: author},
        subPostNumber: '1',
        floorNum: '2',
        kz: '123',
        pid: page.posts.first.id,
        forum: page,
        threadTitle: page.title,
        threadOwnerUid: '',
      ),
    ));

    await tester.tap(find.text('楼中楼正文', findRichText: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final InnerFloorBottomSheet sheet =
        tester.widget<InnerFloorBottomSheet>(find.byType(InnerFloorBottomSheet));
    expect(sheet.spid, 's1');
  });

  testWidgets('打开面板后滚动到锚点回复并高亮', (tester) async {
    Global.tiebaAPI = DemoTiebaApi(latency: Duration.zero);
    final TiebaThreadPage page = await Global.tiebaAPI.getThreadPage('123');
    final InnerFloor floor = await Global.tiebaAPI.getInnerFloor('123', '2');
    final TiebaAuthor author = floor.authors.values.first;
    final TiebaThreadPagePost parent = floor.post
      ..subPostList = <TiebaSubPost>[
        for (int i = 1; i <= 30; i++)
          _subPost('s$i', '第 $i 条回复', author.uid),
      ];
    final ThreadReadSession session = ThreadReadSession()..fail('离线');
    addTearDown(session.dispose);

    await tester.pumpWidget(_host(
      InnerFloorBottomSheet(
        floorNum: '2',
        kz: '123',
        pid: '2',
        spid: 's30',
        forum: page,
        session: session,
        cacheUid: 'a',
        cachedPost: parent,
        cachedAuthors: <String, TiebaAuthor>{author.uid: author},
      ),
    ));
    await tester.pump();
    await tester.pumpAndSettle();

    final Finder target = find.byWidgetPredicate(
      (Widget widget) =>
          widget is InnerFloorCard && widget.postMain.id == 's30',
    );
    expect(target, findsOneWidget);
    final Rect viewport = tester.getRect(find.byType(SingleChildScrollView));
    final Rect targetRect = tester.getRect(target);
    expect(targetRect.top, greaterThanOrEqualTo(viewport.top - 1));
    expect(targetRect.bottom, lessThanOrEqualTo(viewport.bottom + 1));
    expect(tester.widget<InnerFloorCard>(target).highlighted, isTrue);

    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.widget<InnerFloorCard>(target).highlighted, isFalse);
  });
}
