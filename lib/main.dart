import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/routes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Global.init();
  runApp(App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (BuildContext context) => User()),
          ChangeNotifierProvider(create: (context) => APPTheme()),
        ],
        builder: (context, child) => Consumer2<APPTheme, User>(
              builder: (BuildContext context, theme, user, Widget? child) {
                return MaterialApp(
                  initialRoute: PageRouter.home,
                  //配置命名路由
                  onGenerateRoute: (settings) {
                    if (PageRouter.routes.containsKey(settings.name)) {
                      return CupertinoPageRoute(
                          settings: settings,
                          builder: (context) =>
                              PageRouter.routes[settings.name]!(context));
                    }
                    return null;
                  },
                  theme: ThemeData(primaryColor: theme.theme),
                  darkTheme: Global.setting.darkModel == 0
                      ? ThemeData(
                          brightness: Brightness.dark,
                        )
                      : null,
                  localizationsDelegates: [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                  ],
                  supportedLocales: [
                    const Locale('zh', 'CN'),
                    const Locale('en', 'US'),
                  ],
                );
              },
            ));
  }
}
