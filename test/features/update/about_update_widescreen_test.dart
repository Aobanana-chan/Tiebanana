import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/features/forum/state/forum_state.dart';
import 'package:tiebanana/features/home/pages/home_page.dart';
import 'package:tiebanana/features/settings/pages/about_page.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/features/update/data/github_get_latest_version.dart';
import 'package:tiebanana/features/update/data/version.dart';
import 'package:tiebanana/features/update/pages/app_update_page.dart';
import 'package:tiebanana/features/update/state/update_reminder.dart';
import 'package:tiebanana/shared/layout/page_wrap.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';

UpdateCheckResult _sampleResult({
  UpdateStatus status = UpdateStatus.available,
}) {
  return UpdateCheckResult(
    status: status,
    currentVersion: '1.1.1',
    latestVersion: 'v1.2.0',
    publishedAt: '2026-11-28T08:00:00Z',
    notes: '## 新特性\n\n- 支持多平台安装包切换\n- 接入桌面宽屏壳层',
    downloads: const <String, AndroidUpdateAsset>{
      'arm64-v8a': AndroidUpdateAsset(
        abi: 'arm64-v8a',
        name: 'app-arm64-v8a-release.apk',
        url: 'https://example.com/arm64.apk',
        sizeBytes: 26004684,
        digest:
            'sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      ),
      'armeabi-v7a': AndroidUpdateAsset(
        abi: 'armeabi-v7a',
        name: 'app-armeabi-v7a-release.apk',
        url: 'https://example.com/v7a.apk',
        sizeBytes: 23173529,
      ),
    },
    windowsZipUrl: 'https://example.com/Tiebanana-windows-x64.zip',
    windowsAsset: const ReleasePackageAsset(
      name: 'Tiebanana-1.2.0+1042-windows-x64.zip',
      url: 'https://example.com/Tiebanana-windows-x64.zip',
      sizeBytes: 29989273,
      digest:
          'sha256:4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a',
    ),
    iosIpaUrl: 'https://example.com/Tiebanana-ios-unsigned.ipa',
    iosAsset: const ReleasePackageAsset(
      name: 'Tiebanana-1.2.0+1042-ios-unsigned.ipa',
      url: 'https://example.com/Tiebanana-ios-unsigned.ipa',
      sizeBytes: 32715571,
      digest:
          'sha256:ef2d127de37b942baad06145e54b0c619a1f22327b2ebbcfbec78f5564afe39d',
    ),
    releasePageUrl: 'https://github.com/Aobanana-chan/Tiebanana/releases/latest',
  );
}

Widget _wrapApp(
  Widget child, {
  Future<UpdateCheckResult> Function()? checkUpdate,
}) {
  return MultiProvider(
    providers: <ChangeNotifierProvider<dynamic>>[
      ChangeNotifierProvider<APPSettingProvider>(
        create: (_) => APPSettingProvider(),
      ),
      ChangeNotifierProvider<User>(create: (_) => User()),
      ChangeNotifierProvider<ForumState>(create: (_) => ForumState()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == PageRouter.about) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const AboutPage(),
          );
        }
        if (settings.name == PageRouter.appUpdate) {
          final Object? arg = settings.arguments;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => UpdatePage(
              checkUpdate: checkUpdate ?? () async => _sampleResult(),
              initialPlatform: arg is String ? arg : null,
            ),
          );
        }
        return null;
      },
      home: child,
    ),
  );
}

void _setWindow(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    Global.tiebaAPI = DemoTiebaApi(latency: Duration.zero);
    Version.debugReset();
    Version.debugSetCurrentVersion('1.1.1', buildNumber: '7');
    UpdateReminder.restore();
  });

  test('ReleasePackageAsset 解析体积与 SHA-256，Version 支持完整版本号展示', () {
    expect(Version.displayVersion, 'v1.1.1');
    expect(Version.fullDisplayVersion, 'v1.1.1+7');

    final ReleasePackageAsset? asset = findReleaseAsset(<Assets>[
      Assets(
        name: 'Tiebanana-1.2.0-windows-x64.zip',
        browserDownloadUrl: 'https://example.com/win.zip',
        size: 1024 * 1024 * 28,
        digest: 'sha256:ABC123',
      ),
    ], '-windows-x64.zip');

    expect(asset, isNotNull);
    expect(asset!.sizeBytes, 1024 * 1024 * 28);
    expect(asset.sha256, 'ABC123');
  });

  testWidgets('1280 宽屏关于页：桌面壳层、MIT 许可弹窗与平台芯片跳转更新页', (tester) async {
    _setWindow(tester, const Size(1280, 800));
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map<Object?, Object?>)['text']
              as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(_wrapApp(const AboutPage()));
    await tester.pumpAndSettle();

    expect(find.byType(DesktopShellFrame), findsOneWidget);
    expect(find.byType(PageWrap), findsOneWidget);
    expect(find.text('关于 Tiebanana'), findsWidgets);
    expect(find.text('v1.1.1+7'), findsOneWidget);

    // 打开 MIT 许可弹窗并复制全文
    await tester.tap(find.text('开源许可'));
    await tester.pumpAndSettle();
    expect(find.text('开源许可 · MIT License'), findsOneWidget);
    await tester.tap(find.text('复制许可全文'));
    await tester.pumpAndSettle();
    expect(copiedText, contains('MIT License'));
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();

    // 点击 iOS 芯片直接跳转到更新页并选中 iOS 标签
    await tester.tap(find.text('iOS · 未签名 IPA'));
    await tester.pumpAndSettle();
    expect(find.text('更新与多平台下载'), findsWidgets);
    expect(find.text('下载未签名 IPA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('820 与 390 窗口下关于页无溢出', (tester) async {
    for (final Size size in <Size>[const Size(820, 800), const Size(390, 844)]) {
      _setWindow(tester, size);
      await tester.pumpWidget(_wrapApp(const AboutPage()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('1280 宽屏多平台更新页：三端切换、SHA-256 复制与跳过此版本', (tester) async {
    _setWindow(tester, const Size(1280, 800));
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map<Object?, Object?>)['text']
              as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(
      _wrapApp(UpdatePage(checkUpdate: () async => _sampleResult())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DesktopShellFrame), findsOneWidget);
    expect(find.text('发现新版本 v1.2.0'), findsOneWidget);
    expect(find.text('支持多平台安装包切换'), findsOneWidget);

    // 切换到 Windows 标签，显示 ZIP 与 SHA-256 并支持复制
    await tester.tap(find.text('Windows'));
    await tester.pumpAndSettle();
    expect(find.text('下载 Windows x64 ZIP'), findsOneWidget);
    await tester.tap(find.byTooltip('复制 SHA-256'));
    await tester.pumpAndSettle();
    expect(
      copiedText,
      '4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a',
    );

    // 切换到 iOS 标签
    await tester.tap(find.text('iOS'));
    await tester.pumpAndSettle();
    expect(find.text('下载未签名 IPA'), findsOneWidget);

    // 切换到 Android 标签并展开架构说明
    await tester.tap(find.text('Android'));
    await tester.pumpAndSettle();
    expect(find.text('下载 arm64-v8a 安装包'), findsOneWidget);
    final Finder abiHelp = find.text('如何选择 Android 架构（ABI）？');
    await tester.ensureVisible(abiHelp);
    await tester.pumpAndSettle();
    await tester.tap(abiHelp);
    await tester.pumpAndSettle();
    expect(find.textContaining('arm64-v8a：大多数'), findsOneWidget);

    // 跳过此版本 / 恢复提醒
    final Finder skipBtn = find.text('跳过此版本');
    await tester.ensureVisible(skipBtn);
    await tester.pumpAndSettle();
    await tester.tap(skipBtn);
    await tester.pumpAndSettle();
    expect(UpdateReminder.isIgnored('v1.2.0'), isTrue);
    expect(find.text('恢复提醒'), findsOneWidget);
    await tester.tap(find.text('恢复提醒'));
    await tester.pumpAndSettle();
    expect(UpdateReminder.isIgnored('v1.2.0'), isFalse);
  });

  testWidgets('已是最新版本仍保留日志与多平台安装包；失败态展示重试', (tester) async {
    _setWindow(tester, const Size(1280, 800));
    bool failNext = false;

    await tester.pumpWidget(
      _wrapApp(
        UpdatePage(
          checkUpdate: () async => failNext
              ? const UpdateCheckResult(
                  status: UpdateStatus.failed,
                  currentVersion: '1.1.1',
                )
              : _sampleResult(status: UpdateStatus.upToDate),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('当前已是最新版本'), findsOneWidget);
    expect(find.text('支持多平台安装包切换'), findsOneWidget);
    expect(find.text('多平台安装包'), findsOneWidget);

    failNext = true;
    await tester.tap(find.text('重新检查'));
    await tester.pumpAndSettle();
    expect(find.byType(StateView), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('宽屏主页侧边栏（1280 展开态与 820 图标轨）均可直达关于界面', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'uid': '10001',
      'userName': '烤面包边',
    });
    Global.profile = await SharedPreferences.getInstance();

    _setWindow(tester, const Size(1280, 800));
    await tester.pumpWidget(_wrapApp(const HomePage()));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }

    // 1280 展开态：点击底部「关于与更新」入口进入关于页
    expect(find.text('关于与更新'), findsOneWidget);
    await tester.tap(find.text('关于与更新'));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byType(AboutPage), findsOneWidget);

    // 1280 展开态：点击左上角应用图标与字标同样进入关于页
    _setWindow(tester, const Size(1280, 800));
    await tester.pumpWidget(_wrapApp(const HomePage()));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    final Finder topLeftBrandLogo = find.byWidgetPredicate(
      (Widget w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == 'assets/icon/ic_launcher.png',
    );
    await tester.tap(topLeftBrandLogo.first);
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byType(AboutPage), findsOneWidget);

    // 缩窄到 820 图标轨，左上角图标与底部入口均可直达关于页
    _setWindow(tester, const Size(820, 800));
    await tester.pumpWidget(_wrapApp(const HomePage()));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byTooltip('关于与更新'), findsNWidgets(2));
    await tester.tap(find.byTooltip('关于与更新').first);
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byType(AboutPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Linux 等无直装包平台与 820 半屏宽度正常排版无溢出', (tester) async {
    _setWindow(tester, const Size(820, 800));
    await tester.pumpWidget(
      _wrapApp(UpdatePage(checkUpdate: () async => _sampleResult())),
    );
    await tester.pumpAndSettle();

    expect(find.text('前往发布页'), findsOneWidget);
    expect(find.text('多平台安装包'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.linux}));
}
