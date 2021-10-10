import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Json_Model/provider.dart';

import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/routes.dart';

void main() async {
  runApp(App());
  await Global.tiebaAPI.init();
  LoginErrCode test = await Global.tiebaAPI.loginByPassword("test", "test");
  print(test.errcode);
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            );
          },
        ));
  }
}
