import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/profile/state/profile_events.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/profile/pages/profile_edit_page.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/profile/pages/my_profile_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/floating_search_app_bar.dart';
import 'package:tiebanana/features/profile/widgets/user_card.dart';

class _Api extends DemoTiebaApi {
  _Api() : super(latency: Duration.zero);
  int reads = 0;

  @override
  Future<TiebaUserProfile> getUserInfo({required String uid, int pn = 1}) {
    reads++;
    return super.getUserInfo(uid: uid, pn: pn);
  }
}

void main() {
  testWidgets('我的页在服务端仍返回旧头像时显示已提交的新图片，延迟读取不回退', (tester) async {
    SharedPreferences.setMockInitialValues({'uid': '10001'});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    final api = _Api();
    Global.tiebaAPI = api;
    final controller = FloatingSearchBarController();
    addTearDown(controller.dispose);
    addTearDown(() => profileEvents.clearAvatar('10001'));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => User()),
        ChangeNotifierProvider(create: (_) => APPSettingProvider()),
      ],
      child: MaterialApp(
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        home: Scaffold(body: UserPage(controller: controller)),
      ),
    ));
    await tester.pump();
    await tester.pump();
    final bytes =
        Uint8List.fromList(img.encodePng(img.Image(width: 2, height: 2)));
    profileEvents.avatarSaved('10001', preview: bytes);
    await tester.pump();
    await tester.pump();
    Finder preview() =>
        find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage);
    expect(preview(), findsOneWidget);
    expect((tester.widget<Image>(preview()).image as MemoryImage).bytes,
        orderedEquals(bytes));
    expect(api.reads, 2);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(api.reads, 3);
    expect(preview(), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    profileEvents.clearAvatar('10001');
    expect(tester.takeException(), isNull);
  });

  Future<void> frames(WidgetTester tester) async {
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('真实我的页在资料保存后刷新，不从setState返回Future且结束保存中', (tester) async {
    SharedPreferences.setMockInitialValues({'uid': '10001'});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    final api = _Api();
    Global.tiebaAPI = api;
    final controller = FloatingSearchBarController();
    final navigator = GlobalKey<NavigatorState>();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => User()),
        ChangeNotifierProvider(create: (_) => APPSettingProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigator,
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        routes: {PageRouter.profileEdit: (_) => const ProfileEditPage()},
        home: Scaffold(body: UserPage(controller: controller)),
      ),
    ));
    await frames(tester);
    expect(api.reads, 1);

    final oldAvatar =
        tester.widget<UserCard>(find.byType(UserCard)).portraitUrl;
    profileEvents.avatarSaved('10001');
    await frames(tester);
    expect(api.reads, 2);
    final newAvatar =
        tester.widget<UserCard>(find.byType(UserCard)).portraitUrl;
    expect(newAvatar, oldAvatar);
    expect(newAvatar, startsWith('data:image/png;base64,'));

    profileEvents.saved('other-account');
    await frames(tester);
    expect(api.reads, 2);

    navigator.currentState!.pushNamed(PageRouter.profileEdit);
    await frames(tester);
    await tester.enterText(find.byType(TextFormField).first, '更新昵称');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await frames(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('保存中…'), findsNothing);
    expect(find.text('资料已保存'), findsOneWidget);
    expect(api.reads, 5); // 我的首屏、头像刷新、编辑页读取、保存后两个页面刷新。
    profileEvents.clearProfileRefresh('10001');

    await tester.pageBack();
    await frames(tester);
    expect(find.text('更新昵称'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    profileEvents.saved('10001');
    await tester.pump();
    expect(api.reads, 5); // 销毁后已移除事件监听。
    expect(tester.takeException(), isNull);
    profileEvents.clearProfileRefresh('10001');
  });
}
