import 'package:flutter/material.dart';
import 'package:flutter_statusbar_manager/flutter_statusbar_manager.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/common/API/net.dart';

import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Global.init();
  Global.tiebaAPI.init();
  runApp(App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FlutterStatusbarManager.setColor(Color(0x0), animated: true);
    return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: User()),
          ChangeNotifierProvider.value(value: APPTheme()),
        ],
        child: Consumer2<APPTheme, User>(
          builder: (BuildContext context, theme, user, Widget? child) {
            return MaterialApp(
              initialRoute: PageRouter.home,
              routes: PageRouter.routes,
              theme: ThemeData(primaryColor: theme.theme),
              darkTheme: Global.setting.darkModel == 0
                  ? ThemeData(
                      brightness: Brightness.dark,
                    )
                  : null,
            );
          },
        ));
  }
}
