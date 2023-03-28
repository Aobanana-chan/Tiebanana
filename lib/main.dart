import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Callback/LifeTimeCallback.dart';
import 'package:tiebanana/Exceptions/Exception.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/ThemeExtension/QuoteTheme.dart';
import 'package:tiebanana/Widgets/common/ClipBordObserve.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/routes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runZoned(() async {
    TiebananaErrorProcesser.init();
    WidgetsFlutterBinding.ensureInitialized();
    var init = false;
    while (!init) {
      try {
        await Global.init();
        init = true;
      } catch (_) {}
    }

    LifeTimeCallback().afterInit();
    runApp(const App());
  }, zoneSpecification: ZoneSpecification(
    handleUncaughtError: (self, parent, zone, error, stackTrace) {
      TiebananaErrorProcesser().handle(error);
    },
  ));
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (BuildContext context) => User()),
          ChangeNotifierProvider(create: (context) => APPSettingProvider()),
        ],
        builder: (context, child) => Consumer2<APPSettingProvider, User>(
              builder: (BuildContext context, theme, user, Widget? child) {
                ColorScheme darkThemeScheme = ColorScheme.fromSeed(
                    brightness: Brightness.dark, seedColor: Colors.black54);
                return MaterialApp(
                  title: "Tiebanana",
                  initialRoute: PageRouter.home,
                  //配置命名路由
                  onGenerateRoute: (settings) {
                    LifeTimeCallback().route(settings);
                    if (PageRouter.routes.containsKey(settings.name)) {
                      return CustomCupertinoPageRoute(
                          settings: settings,
                          builder: (context) => ClipBordObserver(
                              child:
                                  PageRouter.routes[settings.name]!(context)));
                    }
                    return null;
                  },
                  themeMode: Global.setting.darkModel == 0
                      ? ThemeMode.system
                      : Global.setting.darkModel == 1
                          ? ThemeMode.dark
                          : ThemeMode.light,
                  theme: ThemeData(
                      useMaterial3: true,
                      brightness: Brightness.light,
                      primarySwatch: theme.materialTheme,
                      primaryColor: theme.materialTheme,
                      // appBarTheme: theme.appBarTheme,
                      colorScheme: ColorScheme.fromSwatch(
                          primarySwatch: theme.materialTheme),
                      bottomNavigationBarTheme: BottomNavigationBarThemeData(
                          unselectedItemColor: Colors.black,
                          selectedItemColor: theme.materialTheme),
                      tabBarTheme: TabBarTheme(
                        labelColor: theme.materialTheme,
                        unselectedLabelColor: Colors.black26,
                      ),
                      scaffoldBackgroundColor: const Color(0xFFF2F2F5),
                      buttonTheme: const ButtonThemeData(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero),
                      textTheme: TextTheme(
                          bodyLarge: TextStyle(fontSize: theme.fontSize),
                          bodyMedium: TextStyle(fontSize: theme.fontSize - 2)),
                      extensions: [QuoteTheme.bright]),

                  darkTheme: ThemeData(
                      useMaterial3: true,
                      brightness: Brightness.dark,
                      colorSchemeSeed: Colors.black54,
                      scaffoldBackgroundColor:
                          const Color.fromARGB(137, 75, 69, 69),
                      bottomNavigationBarTheme: BottomNavigationBarThemeData(
                          selectedItemColor: darkThemeScheme.onSurface,
                          unselectedItemColor: darkThemeScheme.onPrimary),
                      tabBarTheme: TabBarTheme(
                        labelColor: darkThemeScheme.onSurface,
                        unselectedLabelColor: darkThemeScheme.onSurface,
                      ),
                      buttonTheme: const ButtonThemeData(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero),
                      extensions: [QuoteTheme.dark]),
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

//issue #14203
class CustomCupertinoPageRoute extends CupertinoPageRoute {
  @override
  bool get hasScopedWillPopCallback {
    return false;
  }

  CustomCupertinoPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
          builder: builder,
          settings: settings,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );
}
