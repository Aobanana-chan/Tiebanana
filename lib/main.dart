import 'package:flutter/material.dart';

import 'package:tieba_flutter/common/API/net.dart';

void main() async {
  runApp(App());
  var test = TiebaAPI();
  await test.init();
  test.loginByPassword("username", "password");
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
