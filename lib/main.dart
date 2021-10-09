import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';

import 'package:tiebanana/common/Global.dart';

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
    return Container();
  }
}
