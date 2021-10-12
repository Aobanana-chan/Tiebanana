import 'package:flutter/material.dart';
import 'package:tiebanana/Widgets/passmachine.dart';
import 'package:tiebanana/common/Global.dart';

///暂时为测试用登录界面,到时候会大改
class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List tabs = ["账号密码登录", "手机号登录"];
  TextEditingController user =
      TextEditingController.fromValue(TextEditingValue(text: ""));
  TextEditingController pwd =
      TextEditingController.fromValue(TextEditingValue.empty);
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          SizedBox(
            height: 50,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Text(
              "Login",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 25,
                color: Colors.black45,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Text(
              "登录",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 25,
                height: 1.5,
                color: Colors.black45,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]),
          SizedBox(height: 50),
          TextField(
            autofocus: false,
            decoration: InputDecoration(
                labelText: "账号",
                hintText: "账号",
                prefixIcon: Icon(
                  Icons.person,
                )),
            controller: user,
          ),
          SizedBox(
            height: 20,
          ),
          TextField(
            autofocus: false,
            decoration: InputDecoration(
                labelText: "密码",
                hintText: "密码",
                prefixIcon: Icon(Icons.person)),
            controller: pwd,
          ),
          SizedBox(
            height: 30,
          ),
          Builder(builder: (builder) {
            return Column(
              children: [
                ElevatedButton(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("登录"),
                  ),
                  onPressed: () async {
                    var loginres = await Global.tiebaAPI
                        .loginByPassword(user.text, pwd.text);
                    //登录
                    if (loginres.errcode == "6") {
                      if (await showDialog<bool>(
                              context: context,
                              builder: (builder) => PassMachineWidget()) ==
                          true) {
                        await Global.tiebaAPI
                            .loginByPassword(user.text, pwd.text);
                      }
                    }
                  },
                )
              ],
            );
          })
        ],
      ),
    );
  }
}
