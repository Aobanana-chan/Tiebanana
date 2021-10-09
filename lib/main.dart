import 'package:flutter/material.dart';
import 'package:tieba_flutter/Json_Model/json.dart';

import 'package:tieba_flutter/common/Global.dart';

void main() async {
  runApp(App());
  await Global.tiebaAPI.init();
  LoginErrCode test = await Global.tiebaAPI.loginByPassword("940610311", "123");
  print(test.errcode);
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
