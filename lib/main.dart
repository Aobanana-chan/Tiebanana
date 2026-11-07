import 'package:tiebanana/app/navigation/app_router.dart';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiebanana/app/lifecycle/app_lifecycle.dart';
import 'package:tiebanana/app/navigation/app_route_observer.dart';
import 'package:tiebanana/core/cache/image_cache_manager.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/clipboard_observe.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/app/bootstrap.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tiebanana/features/account/widgets/login_failure_prompt.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:tiebanana/core/diagnostics/diagnostics.dart';

final _appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runZoned(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final previousFlutterError = FlutterError.onError;
    FlutterError.onError = (details) {
      AppLog.shared.error('uncaught.flutter', details.exception, details.stack);
      previousFlutterError?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLog.shared.error('uncaught.platform', error, stack);
      return false; // 保留引擎默认错误输出。
    };

    // 开屏先上，初始化并行跑：启动期由开屏动画覆盖，初始化在后台执行。
    // Global.init() 里最慢的是登录态那一次网络请求，正好被前四拍吃掉。
    final BootState boot = BootState();
    const splashCompletedKey = 'splash.completed';
    final preferences = SharedPreferences.getInstance();
    Future<void> initialize() => boot.initialize(() async {
          await Diagnostics.shared.initialize();
          MediaKit.ensureInitialized();
          final prefs = await preferences;
          boot.setSplashSkippable(prefs.getBool(splashCompletedKey) ?? false);
          await Global.init();
          // 缓存维护不阻塞开屏与登录初始化。
          unawaited(ImageCacheManager.shared
              .start()
              .catchError((Object error, StackTrace stack) {
            AppLog.shared.error('cache.initialize_failed', error, stack);
            debugPrint('初始化图片缓存管理失败：$error');
          }));
          LifeTimeCallback().afterInit();
        });

    Future<void> recordSplashCompleted() async {
      try {
        final prefs = await preferences;
        await prefs.setBool(splashCompletedKey, true);
      } catch (error, stack) {
        AppLog.shared.error('startup.splash_record_failed', error, stack);
        // 记录失败不影响进入应用，下次仍按首次启动完整播放。
        debugPrint('保存开屏播放记录失败：$error');
      }
    }

    runApp(BootstrapApp(
      boot: boot,
      app: const App(),
      onRetry: initialize,
      onSplashCompleted: () => unawaited(recordSplashCompleted()),
    ));
    await initialize();
  }, zoneSpecification: ZoneSpecification(
    handleUncaughtError: (self, parent, zone, error, stackTrace) {
      AppLog.shared.error('uncaught.zone', error, stackTrace);
      parent.handleUncaughtError(zone, error, stackTrace);
    },
  ));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (BuildContext context) => User()),
          ChangeNotifierProvider(create: (context) => APPSettingProvider()),
        ],
        builder: (context, child) => Consumer2<APPSettingProvider, User>(
              builder: (BuildContext context, theme, user, Widget? child) {
                final TiebananaSeed seed = seedOf(theme.theme);
                return MaterialApp(
                  navigatorKey: _appNavigatorKey,
                  // 全局监听滚动：页面内的视频在滚出可视区域时自行暂停。
                  builder: (context, child) => ScrollNotificationObserver(
                    child: LoginFailurePrompt(
                      controller: Global.loginFailures,
                      navigatorKey: _appNavigatorKey,
                      onRelogin: () async {
                        await _appNavigatorKey.currentState?.pushNamed(
                          PageRouter.login,
                          arguments: const LoginRouteOptions(relogin: true),
                        );
                      },
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                  title: "Tiebanana",
                  initialRoute: PageRouter.home,
                  navigatorObservers: <NavigatorObserver>[appRouteObserver],
                  //配置命名路由
                  onGenerateRoute: (settings) {
                    LifeTimeCallback().route(settings);
                    if (AppRouter.routes.containsKey(settings.name)) {
                      return appPageRoute(
                          settings: settings,
                          builder: (context) => ClipBordObserver(
                              child:
                                  AppRouter.routes[settings.name]!(context)));
                    }
                    return null;
                  },
                  themeMode: Global.setting.darkModel == 0
                      ? ThemeMode.system
                      : Global.setting.darkModel == 1
                          ? ThemeMode.dark
                          : ThemeMode.light,
                  // 主题只由「种子 + 用户字号」决定，见 lib/shared/theme/。
                  theme: TiebananaTheme.light(seed, theme.fontSize),
                  darkTheme: TiebananaTheme.dark(seed, theme.fontSize),
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('zh', 'CN'),
                    Locale('en', 'US'),
                  ],
                );
              },
            ));
  }
}
