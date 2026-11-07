import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:image/image.dart' as img;
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/profile/state/profile_events.dart';
import 'package:tiebanana/features/profile/pages/profile_edit_page.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';

class _ProfileApi extends DemoTiebaApi {
  bool fail = false;
  Completer<TiebaUserProfile>? pending;
  int calls = 0;
  int saves = 0;
  String name = '原来的昵称';
  String signature = '原来的签名';
  String gender = '1';
  bool saveFails = false;
  bool nicknameEditing = false;
  bool pendingAfterSave = false;
  Completer<void>? pendingSave;
  String? sentNickname;
  String? sentIntro;
  String? sentSex;
  int avatars = 0;
  bool avatarFails = false;
  bool avatarPending = false;
  String? uploadedPath;
  Uint8List? uploadedBytes;

  @override
  Future<TiebaAvatarUpdateResult> updateAvatar(UploadFile image) async {
    avatars++;
    uploadedPath = image.path;
    uploadedBytes = await File(image.path).readAsBytes();
    if (avatarFails) {
      throw NetAPIError(
          type: NetAPIErrorType.actionFalied,
          redoTimes: 0,
          errorMessage: '头像审核未通过');
    }
    image.onProgress?.call(uploadedBytes!.length, uploadedBytes!.length);
    return TiebaAvatarUpdateResult(
        portraitUrl: '',
        pendingReview: avatarPending,
        message: avatarPending ? '头像已上传，审核中；审核通过后生效' : '头像已更新');
  }

  @override
  Future<TiebaProfileUpdateResult> updateUserProfile(
      {String? nickname, String? intro, String? sex}) async {
    saves++;
    sentNickname = nickname;
    sentIntro = intro;
    sentSex = sex;
    if (pendingSave != null) await pendingSave!.future;
    if (saveFails) {
      throw NetAPIError(
          type: NetAPIErrorType.actionFalied,
          redoTimes: 0,
          errorMessage: '昵称修改次数不足');
    }
    name = nickname ?? name;
    signature = intro ?? signature;
    gender = sex ?? gender;
    nicknameEditing = pendingAfterSave;
    return TiebaProfileUpdateResult(
        message: '资料已提交到贴吧', nicknamePending: pendingAfterSave);
  }

  @override
  Future<TiebaUserProfile> getUserInfo(
      {required String uid, int pn = 1}) async {
    calls++;
    if (fail) throw StateError('offline');
    if (pending != null) return pending!.future;
    return TiebaUserProfile(
      uid: uid,
      nameShow: name,
      nicknameEditing: nicknameEditing,
      editingNickname: nicknameEditing ? '审核昵称' : '',
      portraitUrl: '',
      intro: signature,
      sex: gender,
      tbAge: '8.2年',
      concernNum: '0',
      fansNum: '0',
      likeForumNum: '0',
      postNum: '0',
      rePostNum: '0',
      totalAgreeNum: '0',
    );
  }
}

class _Paths extends PathProviderPlatform {
  _Paths(this.path);
  final String path;
  @override
  Future<String?> getTemporaryPath() async => path;
}

void main() {
  late _ProfileApi api;

  setUpAll(() async {
    for (final entry in <String, String>{
      'ProfilePreview': r'C:\Windows\Fonts\simhei.ttf',
      'MaterialIcons':
          r'D:\Software\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
    }.entries) {
      final file = File(entry.value);
      if (!file.existsSync()) continue;
      final loader = FontLoader(entry.key)
        ..addFont(
            file.readAsBytes().then((bytes) => ByteData.sublistView(bytes)));
      await loader.load();
    }
  });

  setUp(() async {
    profileEvents.clearAvatar('10001');
    SharedPreferences.setMockInitialValues(<String, Object>{'uid': '10001'});
    Global.profile = await SharedPreferences.getInstance();
    api = _ProfileApi();
    Global.tiebaAPI = api;
  });

  tearDown(() => profileEvents.clearAvatar('10001'));

  Future<void> pumpPage(WidgetTester tester,
      {bool dark = false,
      double fontSize = 16,
      Future<Uint8List?> Function(BuildContext)? avatarPicker}) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final ThemeData base = dark
        ? TiebananaTheme.dark(seedOf('blue'), fontSize)
        : TiebananaTheme.light(seedOf('blue'), fontSize);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
          textTheme: base.textTheme.apply(fontFamily: 'ProfilePreview')),
      routes: <String, WidgetBuilder>{
        PageRouter.profileEdit: (_) =>
            ProfileEditPage(avatarPicker: avatarPicker),
        PageRouter.login: (_) => const Scaffold(body: Text('登录入口')),
      },
      home: Builder(
          builder: (BuildContext context) => Scaffold(
                body: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, PageRouter.profileEdit),
                  child: const Text('打开编辑'),
                ),
              )),
    ));
    await tester.tap(find.text('打开编辑'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  for (final dark in <bool>[false, true]) {
    testWidgets('A版设计预览 dark=$dark', (tester) async {
      await pumpPage(tester, dark: dark);
      if (Platform.environment['GOLDEN'] == '1') {
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
                'goldens/profile_edit_${dark ? 'dark' : 'light'}.png'));
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final bool dark in <bool>[false, true]) {
    testWidgets('资料表单与大字号无溢出 dark=$dark', (WidgetTester tester) async {
      await pumpPage(tester, dark: dark, fontSize: 22.5);
      expect(find.text('更换头像'), findsOneWidget);
      expect(find.text('每一个侧面，都是你。'), findsNothing);
      expect(find.text('我的贴吧资料'), findsNothing);
      expect(find.text('关于我'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '原来的昵称'), findsOneWidget);
      expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, '保存'))
              .onPressed,
          isNull);
      await tester.scrollUntilVisible(find.textContaining('贴吧 ID'), 180,
          scrollable: find
              .descendant(
                  of: find.byType(ListView), matching: find.byType(Scrollable))
              .first);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('保存实际调用API且只提交变化的字段，不写本机草稿', (WidgetTester tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).first, '新的昵称');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(api.saves, 1);
    expect(api.sentNickname, '新的昵称');
    expect(api.sentIntro, isNull);
    expect(api.sentSex, isNull);
    expect(find.text('资料已提交到贴吧'), findsOneWidget);
    expect(
        Global.profile.getKeys(), isNot(contains('profileEditDraft.v1.10001')));
    expect(Global.profile.getString('uid'), '10001');
    expect(Global.profile.getString('name'), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开编辑'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '新的昵称'), findsOneWidget);
    expect(find.text('本机草稿'), findsNothing);
    profileEvents.clearProfileRefresh('10001');
  });

  testWidgets('保存后待审状态定时重读，审核结束解除昵称禁用且保留新输入', (tester) async {
    api.pendingAfterSave = true;
    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).first, '待审核昵称');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
        isFalse);
    await tester.enterText(find.byType(TextFormField).last, '尚未提交的新签名');
    api.nicknameEditing = false;
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(
        tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
        isTrue);
    expect(find.widgetWithText(TextFormField, '尚未提交的新签名'), findsOneWidget);
    expect(api.saves, 1);
    profileEvents.clearProfileRefresh('10001');
  });

  testWidgets('取消选头像不上传，不破坏未保存表单', (tester) async {
    await pumpPage(tester, avatarPicker: (_) async => null);
    await tester.enterText(find.byType(TextFormField).first, '未保存昵称');
    await tester.pump();
    await tester.tap(find.text('更换头像'));
    await tester.pumpAndSettle();
    expect(api.avatars, 0);
    expect(find.widgetWithText(TextFormField, '未保存昵称'), findsOneWidget);
    expect(find.text('更换头像'), findsOneWidget);
  });

  testWidgets('头像上传成功才更新预览，失败保留表单且清理临时文件', (tester) async {
    final directory =
        Directory.systemTemp.createTempSync('profile-avatar-test-');
    final previous = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(directory.path);
    addTearDown(() {
      PathProviderPlatform.instance = previous;
      directory.deleteSync(recursive: true);
    });
    final bytes = Uint8List.fromList(
        img.encodeJpg(img.Image(width: 960, height: 960), quality: 80));
    await pumpPage(tester, avatarPicker: (_) async => bytes);
    await tester.enterText(find.byType(TextFormField).first, '未保存昵称');
    await tester.pump();
    api.avatarFails = true;
    await tester.runAsync(() async {
      await tester.tap(find.text('更换头像'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('头像审核未通过'), findsOneWidget);
    expect(profileEvents.avatarPreview('10001'), isNull);
    expect(api.calls, 1);
    expect(find.widgetWithText(TextFormField, '未保存昵称'), findsOneWidget);
    expect(File(api.uploadedPath!).existsSync(), isFalse);
    ScaffoldMessenger.of(tester.element(find.byType(ProfileEditPage)))
        .clearSnackBars();
    await tester.pumpAndSettle();
    api.avatarFails = false;
    api.avatarPending = true;
    await tester.runAsync(() async {
      await tester.tap(find.text('更换头像'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(api.avatars, 2);
    expect(profileEvents.avatarPreview('10001'), orderedEquals(bytes));
    expect(api.calls, 3); // 初始读取、上传后头像读取、成功通知后状态读取。
    expect(profileEvents.avatarUrl('10001', 'https://example.test/avatar'),
        contains('_avatar_v='));
    expect(find.widgetWithText(TextFormField, '未保存昵称'), findsOneWidget);
    expect(find.text('头像已上传，审核中；审核通过后生效'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(File(api.uploadedPath!).existsSync(), isFalse);
    expect(api.saves, 0);
    expect(tester.takeException(), isNull);
    profileEvents.clearAvatar('10001');
  });

  testWidgets('空昵称阻止保存', (WidgetTester tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).first, '  ');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('请填写昵称'), findsOneWidget);
    expect(api.saves, 0);
  });

  testWidgets('未保存返回支持继续编辑与放弃', (WidgetTester tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).first, '未保存');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('放弃未保存的修改？'), findsOneWidget);
    await tester.tap(find.text('继续编辑'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '未保存'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('放弃修改'));
    await tester.pumpAndSettle();
    expect(find.text('打开编辑'), findsOneWidget);
    expect(api.saves, 0);
  });

  testWidgets('读取失败可重试', (WidgetTester tester) async {
    api.fail = true;
    await pumpPage(tester);
    expect(find.text('暂时无法读取资料'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(api.calls, 2);
  });

  testWidgets('保存失败显示服务端原因且保留输入供重试', (WidgetTester tester) async {
    api.saveFails = true;
    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).first, '新的昵称');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('保存失败：昵称修改次数不足'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '新的昵称'), findsOneWidget);
    expect(api.name, '原来的昵称');
    api.saveFails = false;
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(api.saves, 2);
    expect(api.name, '新的昵称');
    profileEvents.clearProfileRefresh('10001');
  });

  testWidgets('可清空签名，性别使用官方的男1女2', (WidgetTester tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).last, '');
    await tester.ensureVisible(find.widgetWithText(TextButton, '女'));
    await tester.tap(find.widgetWithText(TextButton, '女'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(api.sentNickname, isNull);
    expect(api.sentIntro, '');
    expect(api.sentSex, '2');
    profileEvents.clearProfileRefresh('10001');
  });

  testWidgets('旧草稿不会自动写入真实表单', (WidgetTester tester) async {
    await Global.profile.setStringList(
        'profileEditDraft.v1.10001', <String>['旧草稿', '旧签名', '2']);
    await pumpPage(tester);
    expect(find.widgetWithText(TextFormField, '原来的昵称'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '旧草稿'), findsNothing);
    expect(api.saves, 0);
  });

  testWidgets('昵称审核中展示待审昵称，禁用昵称但仍可改签名', (WidgetTester tester) async {
    api.nicknameEditing = true;
    await pumpPage(tester);
    expect(find.widgetWithText(TextFormField, '审核昵称'), findsOneWidget);
    expect(
        tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
        isFalse);
    await tester.enterText(find.byType(TextFormField).last, '更新签名');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(api.sentNickname, isNull);
    expect(api.sentIntro, '更新签名');
    profileEvents.clearProfileRefresh('10001');
  });

  testWidgets('窄屏与键盘弹出时可滚动编辑且无溢出', (WidgetTester tester) async {
    await pumpPage(tester, fontSize: 22.5);
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.ensureVisible(find.byType(TextFormField).last);
    await tester.enterText(find.byType(TextFormField).last, '窄屏签名');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('保存中禁止重复提交和离开', (WidgetTester tester) async {
    api.pendingSave = Completer<void>();
    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).first, '新的昵称');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('保存中…'), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    expect(find.text('编辑资料'), findsOneWidget);
    expect(api.saves, 1);
    api.pendingSave!.complete();
    await tester.pumpAndSettle();
    expect(find.text('资料已提交到贴吧'), findsOneWidget);
    profileEvents.clearProfileRefresh('10001');
  });

  testWidgets('请求不结束时超时解除保存中，禁止重复提交并允许重读确认', (tester) async {
    api.pendingSave = Completer<void>();
    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).first, '新的昵称');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 31));
    await tester.pump();
    expect(find.text('保存中…'), findsNothing);
    expect(find.textContaining('请求超时，保存结果待确认'), findsOneWidget);
    expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '保存'))
            .onPressed,
        isNull);
    expect(api.saves, 1);
    api.pendingSave!.complete();
    await tester.pumpAndSettle();
    // 超时后的迟到响应不能回填表单或冒充已确认结果。
    expect(find.text('资料已提交到贴吧'), findsNothing);
    await tester.tap(find.text('重新读取贴吧资料'));
    await tester.pumpAndSettle();
    expect(find.text('重新读取贴吧资料'), findsNothing);
    expect(api.calls, 2);
  });

  testWidgets('加载中离开不会在销毁后更新状态', (WidgetTester tester) async {
    api.pending = Completer<TiebaUserProfile>();
    await pumpPage(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    api.pending!.completeError(StateError('offline'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('账号切换后禁止把旧表单保存到新账号', (WidgetTester tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).first, '旧账号修改');
    await tester.pump();
    await Global.profile.setString('uid', '10002');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.textContaining('当前账号已切换'), findsOneWidget);
    expect(api.saves, 0);
  });

  testWidgets('未登录不请求资料并提供登录入口', (WidgetTester tester) async {
    await Global.profile.remove('uid');
    await pumpPage(tester);
    expect(find.text('登录后编辑资料'), findsOneWidget);
    expect(api.calls, 0);
    await tester.tap(find.text('去登录'));
    await tester.pumpAndSettle();
    expect(find.text('登录入口'), findsOneWidget);
  });
}
