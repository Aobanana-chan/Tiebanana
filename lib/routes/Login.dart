import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/authwidgetverify.dart';
import 'package:tiebanana/Widgets/passmachine.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:fluttertoast/fluttertoast.dart';

///暂时为测试用登录界面,到时候会大改(应该)
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
      child: SingleChildScrollView(
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
                  prefixIcon: Icon(Icons.lock)),
              controller: pwd,
              obscureText: true,
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
                      //登录
                      var loginres = await Global.tiebaAPI
                          .loginByPassword(user.text, pwd.text);
                      //验证码
                      while (loginres.errcode == "6") {
                        Fluttertoast.showToast(msg: "需要输入验证码");
                        bool? verify = await showDialog<bool>(
                            context: context,
                            builder: (builder) => PassMachineWidget());
                        if (verify == true) {
                          loginres = await Global.tiebaAPI
                              .loginByPassword(user.text, pwd.text);
                        } else if (verify == null) {
                          return;
                        }
                      }
                      //短信验证码(触发条件不明,猜测应该是fuid或者是dv值变动)
                      while (loginres.errcode == "120021") {
                        Fluttertoast.showToast(msg: "需要进行安全验证");
                        bool? safeVerify = await showDialog(
                            context: context,
                            builder: (builder) => Authwidgetverify());
                        if (safeVerify == true) {
                          loginres = await Global.tiebaAPI
                              .loginByPassword(user.text, pwd.text);
                        }
                        if (safeVerify == null) {
                          return;
                        }
                      }
                      //是否成功登录
                      if (loginres.errcode == "0") {
                        Fluttertoast.showToast(msg: "登录成功");
                        Provider.of<User>(builder, listen: false).login();
                      } else {
                        Fluttertoast.showToast(
                            msg:
                                "登录失败错误码(err:${loginres.errcode}\n${loginres.msg})");
                      }
                    },
                  )
                ],
              );
            })
          ],
        ),
      ),
    );
  }
}
