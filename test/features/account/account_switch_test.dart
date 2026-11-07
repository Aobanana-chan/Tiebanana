// 多账号仓库 + 切换面板回归。
//
// 目的：
// 1. 账号元数据 / 当前 uid / 未读缓存的读写不串账号；
// 2. 「切换账号」面板能按设计列出账号、当前账号打勾，并提供添加入口。
//
// 渲染检查在系统没有黑体时自动跳过（CI 上不会因此失败）。
import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/features/settings/widgets/setting_panel.dart';

const String _fontPath = r'C:\Windows\Fonts\simhei.ttf';
const String _iconFontPath =
    r'D:\Software\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf';
const String _family = 'CJK';

const Size _phone = Size(390, 844);

Future<void> _loadFontFrom(String path, String family) async {
  final File f = File(path);
  if (!f.existsSync()) return;
  final FontLoader loader = FontLoader(family)
    ..addFont(f
        .readAsBytes()
        .then((List<int> b) => ByteData.view(Uint8List.fromList(b).buffer)));
  await loader.load();
}

Future<bool> _loadFont() async {
  if (!File(_fontPath).existsSync()) return false;
  await _loadFontFrom(_fontPath, _family);
  await _loadFontFrom(_iconFontPath, 'MaterialIcons');
  return true;
}

MyUserData _user(int uid, String name) => MyUserData(
      id: uid,
      uid: uid,
      name: name,
      nameShow: name,
      isLogin: true,
      isVerify: false,
      portrait: 'tb.$uid',
      portraitUrl: '${AUTHOR_AVATAR}tb.$uid',
      likeForumNum: 1,
      postNum: 2,
      concernNum: 3,
      fansNum: 4,
      intro: '',
      userSex: 1,
    );

Widget _host(Widget home) {
  final ThemeData theme = TiebananaTheme.light(seedOf('blue'), 16);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: _family),
    ),
    home: Scaffold(body: SingleChildScrollView(child: home)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool hasFont;

  setUpAll(() async {
    hasFont = await _loadFont();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    // 单元测试里不碰真实文档目录，cookie 快照会自动跳过。
    Global.documentsPath = null;
    Global.tiebaAPI = DemoTiebaApi(latency: Duration.zero);
  });

  group('AccountStore', () {
    Future<Directory> cookieDirectory() async {
      final Directory temp =
          await Directory.systemTemp.createTemp('tiebanana_accounts_');
      addTearDown(() async {
        Global.documentsPath = null;
        await temp.delete(recursive: true);
      });
      Global.documentsPath = temp.path;
      return temp;
    }

    Future<void> saveCredentials(String value) async {
      final PersistCookieJar jar =
          PersistCookieJar(storage: FileStorage(Global.cookieStoragePath));
      await jar.deleteAll();
      await jar.saveFromResponse(Uri.parse('https://www.baidu.com'), <Cookie>[
        Cookie('BDUSS', value)
          ..domain = '.baidu.com'
          ..path = '/',
      ]);
    }

    Future<String> activeCredentials() async {
      final PersistCookieJar jar =
          PersistCookieJar(storage: FileStorage(Global.cookieStoragePath));
      final List<Cookie> cookies =
          await jar.loadForRequest(Uri.parse('https://www.baidu.com'));
      return cookies.singleWhere((Cookie c) => c.name == 'BDUSS').value;
    }

    test('真实 cookie_jar 子目录快照可被重新读取', () async {
      final Directory temp = await cookieDirectory();
      await saveCredentials('account-a');
      await AccountStore.rememberLogin(_user(1001, 'A'));

      final PersistCookieJar snapshot = PersistCookieJar(
          storage: FileStorage('${temp.path}/accounts/1001/cookies/'));
      final List<Cookie> cookies =
          await snapshot.loadForRequest(Uri.parse('https://www.baidu.com'));
      expect(cookies.singleWhere((Cookie c) => c.name == 'BDUSS').value,
          'account-a');
    });

    test('添加第二个账号后可来回切换，重建后端仍能读到各自凭证', () async {
      await cookieDirectory();
      await saveCredentials('account-a');
      await AccountStore.rememberLogin(_user(1001, 'A'));
      await AccountStore.snapshotCurrent();

      await saveCredentials('account-b');
      await AccountStore.rememberLogin(_user(1002, 'B'));
      await Global.reloadTiebaApi();

      final int revision = AccountStore.changes.value;
      for (final String uid in <String>['1001', '1002', '1001']) {
        await AccountStore.switchTo(uid);
        expect(AccountStore.currentUid, uid);
        expect(Global.tiebaAPI.isLogin, isTrue);
        expect(await activeCredentials(),
            uid == '1001' ? 'account-a' : 'account-b');
      }
      expect(AccountStore.changes.value, revision + 3);
    });

    test('登录后写入账号列表并设成当前账号', () async {
      await AccountStore.rememberLogin(_user(1001, '青葉ナナ'));

      expect(AccountStore.currentUid, '1001');
      expect(AccountStore.accounts.length, 1);
      expect(AccountStore.current?.name, '青葉ナナ');

      await AccountStore.rememberLogin(_user(1002, '白川みな'));

      expect(AccountStore.currentUid, '1002');
      expect(AccountStore.accounts.length, 2);
      expect(
        AccountStore.accounts.map((TiebananaAccount a) => a.uid).toList(),
        <String>['1001', '1002'],
      );
    });

    test('退出最后一个账号后重建后端不会恢复旧登录态', () async {
      await cookieDirectory();
      await saveCredentials('account-a');
      await AccountStore.rememberLogin(_user(1001, 'A'));
      await Global.reloadTiebaApi();

      await AccountStore.logoutCurrent();

      expect(AccountStore.currentUid, isNull);
      expect(AccountStore.accounts, isEmpty);
      expect(Global.tiebaAPI.isLogin, isFalse);
      await Global.reloadTiebaApi();
      expect(Global.tiebaAPI.isLogin, isFalse);
    });

    test('退出当前账号后其它账号的还原凭证不会被异步删除', () async {
      await cookieDirectory();
      await saveCredentials('account-a');
      await AccountStore.rememberLogin(_user(1001, 'A'));
      await saveCredentials('account-b');
      await AccountStore.rememberLogin(_user(1002, 'B'));
      await Global.reloadTiebaApi();

      await AccountStore.logoutCurrent();

      expect(AccountStore.currentUid, '1001');
      expect(Global.tiebaAPI.isLogin, isTrue);
      expect(await activeCredentials(), 'account-a');
      await Global.reloadTiebaApi();
      expect(Global.tiebaAPI.isLogin, isTrue);
      expect(await activeCredentials(), 'account-a');
    });

    test('未读数只记到当前账号上', () async {
      await AccountStore.rememberLogin(_user(1001, 'A'));
      await AccountStore.rememberLogin(_user(1002, 'B'));

      AccountStore.updateCurrentUnread(7);

      expect(AccountStore.accounts[0].unread, 0);
      expect(AccountStore.accounts[1].unread, 7);

      Global.profile.setString(AccountStore.currentUidKey, '1001');
      AccountStore.updateCurrentUnread(2);
      expect(AccountStore.accounts[0].unread, 2);
      expect(AccountStore.accounts[1].unread, 7);
    });

    test('移除非当前账号不会改当前账号', () async {
      await AccountStore.rememberLogin(_user(1001, 'A'));
      await AccountStore.rememberLogin(_user(1002, 'B'));

      await AccountStore.removeAccount('1001');

      expect(AccountStore.currentUid, '1002');
      expect(AccountStore.accounts.length, 1);
      expect(AccountStore.accounts.single.uid, '1002');
    });

    test('账号列表损坏时退化成空列表而不是崩溃', () async {
      Global.profile.setString(AccountStore.accountsKey, 'not json');
      expect(AccountStore.accounts, isEmpty);
    });

    test('登录时把当前 cookie 仓库快照到账号目录', () async {
      final Directory temp =
          await Directory.systemTemp.createTemp('tiebanana_accounts_');
      addTearDown(() async {
        Global.documentsPath = null;
        if (temp.existsSync()) {
          await temp.delete(recursive: true);
        }
      });
      Global.documentsPath = temp.path;
      final Directory cookies = Directory('${temp.path}/cookies/')
        ..createSync(recursive: true);
      File('${cookies.path}sample').writeAsStringSync('BDUSS=x');

      await AccountStore.rememberLogin(_user(1001, '青葉ナナ'));

      final File snapshot = File('${temp.path}/accounts/1001/cookies/sample');
      expect(snapshot.existsSync(), isTrue);
      expect(snapshot.readAsStringSync(), 'BDUSS=x');
    });
  });

  testWidgets('切换账号面板按设计列出账号与操作入口', (WidgetTester tester) async {
    if (!hasFont) {
      markTestSkipped('未找到 $_fontPath，跳过渲染检查');
      return;
    }
    await AccountStore.rememberLogin(_user(1234567, '青葉ナナ'));
    await AccountStore.rememberLogin(_user(2345678, '白川みな'));

    await tester.binding.setSurfaceSize(_phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_host(const SettingPanel()));
    await tester.pump();

    await tester.tap(find.text('切换账号'));
    // 不用 pumpAndSettle：头像的网络占位动画会一直挂起。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('青葉ナナ'), findsOneWidget);
    expect(find.text('白川みな'), findsOneWidget);
    expect(find.textContaining('当前账号'), findsOneWidget);
    expect(find.text('添加账号'), findsOneWidget);
    expect(find.text('管理账号'), findsOneWidget);
    // 底下的「我的」页也有一行「退出登录」，面板里再来一个。
    expect(find.text('退出登录'), findsWidgets);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    // 切到管理态：行尾变成移除按钮，添加入口收起。
    await tester.tap(find.text('管理账号'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('管理账号'), findsOneWidget); // 标题
    expect(find.text('添加账号'), findsNothing);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(2));
  });
}
