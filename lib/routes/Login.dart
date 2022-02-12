import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/AuthWidgetVerify.dart';
import 'package:tiebanana/Widgets/CustomUnderlineTabIndicator.dart';
import 'package:tiebanana/Widgets/PassMachine.dart';
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
  List tabs = ["账号密码登录", "短信登录"];
  TextEditingController user =
      TextEditingController.fromValue(TextEditingValue(text: ""));
  TextEditingController pwd =
      TextEditingController.fromValue(TextEditingValue.empty);
  TextEditingController phoneNumber =
      TextEditingController.fromValue(TextEditingValue.empty);
  TextEditingController verifyCode =
      TextEditingController.fromValue(TextEditingValue.empty);
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment(0, -0.2),
              colors: [
            Color(0xFF4E6EF2),
            Color(0xFF4E6EF2),
            Color(0xFF4E6EF2),
            Color(0xFF4E6EF2),
            Color(0xFFF5F5F5)
          ])),
      child: SingleChildScrollView(
          child: Column(
        children: [
          Container(
            // color: Colors.blue,
            padding: EdgeInsets.only(top: 50),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "登录百度帐号",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 25,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]),
          ),
          Container(
            // color: Colors.blue,
            padding: EdgeInsets.only(bottom: 30),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "精彩永相随",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 25,
                      height: 1.5,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]),
          ),
          Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(32)),
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.only(left: 10, right: 10),
              constraints: BoxConstraints(maxHeight: 300),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 10),
                    child: TabBar(
                      tabs: tabs
                          .map((e) => Tab(
                                text: e,
                              ))
                          .toList(),
                      indicator: CustomUnderlineTabIndicator(
                          wantWidth: 36,
                          insets: EdgeInsets.only(left: 15, right: 15),
                          borderSide:
                              BorderSide(width: 4, color: Colors.green)),
                      labelColor: Colors.black,
                      labelStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      controller: _tabController,
                    ),
                  ),
                  Expanded(
                      child: TabBarView(
                          physics: NeverScrollableScrollPhysics(),
                          controller: _tabController,
                          children: [
                        _PasswordLogin(user: user, pwd: pwd),
                        _PhoneNumberLogin(
                          phoneNumber: phoneNumber,
                          verifyCode: verifyCode,
                        )
                      ]))
                ],
              ))
        ],
      )),
    );
  }
}

class _PasswordLogin extends StatelessWidget {
  final TextEditingController user;
  final TextEditingController pwd;
  const _PasswordLogin({Key? key, required this.user, required this.pwd})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(bottom: 20),
          child: TextField(
            autofocus: false,
            decoration: InputDecoration(
              hintText: "手机号/用户名/邮箱",
              prefixIcon: Icon(
                Icons.person,
              ),
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              filled: true,
              fillColor: Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(64),
                  borderSide: BorderSide.none),
            ),
            controller: user,
          ),
        ),
        Container(
          padding: EdgeInsets.only(bottom: 30),
          child: TextField(
            autofocus: false,
            decoration: InputDecoration(
              // labelText: "密码",
              hintText: "密码",
              prefixIcon: Icon(Icons.lock),
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              filled: true,
              fillColor: Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(64),
                  borderSide: BorderSide.none),
            ),
            controller: pwd,
            obscureText: true,
          ),
        ),
        Container(
          // margin: EdgeInsets.only(left: 20, right: 20),
          child: GradientButton(
            padding: const EdgeInsets.all(16.0),
            borderRadius: BorderRadius.circular(64),
            child: Center(
              child: Text(
                "登录",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            onPressed: () async {
              if (user.text == "") {
                Fluttertoast.showToast(msg: "请输入用户名");
                return;
              } else if (pwd.text == "") {
                Fluttertoast.showToast(msg: "密码不能为空");
                return;
              }
              Fluttertoast.showToast(msg: "正在登陆...");
              //登录
              var loginres =
                  await Global.tiebaAPI.loginByPassword(user.text, pwd.text);
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
                    context: context, builder: (builder) => Authwidgetverify());
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
                Provider.of<User>(context, listen: false).login();
                Provider.of<ForumState>(context, listen: false).refresh();
              } else {
                Fluttertoast.showToast(
                    msg: "登录失败错误码(err:${loginres.errcode}\n${loginres.msg})");
              }
            },
          ),
        )
      ],
    );
  }
}

class _PhoneNumberLogin extends StatefulWidget {
  final TextEditingController phoneNumber;
  final TextEditingController verifyCode;
  _PhoneNumberLogin(
      {Key? key, required this.phoneNumber, required this.verifyCode})
      : super(key: key);

  @override
  State<_PhoneNumberLogin> createState() => __PhoneNumberLoginState();
}

class __PhoneNumberLoginState extends State<_PhoneNumberLogin> {
  bool smsSend = false;
  String smsCodeStr = "";
  String smsCodeSign = "";
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(bottom: 20),
          child: TextField(
            autofocus: false,
            decoration: InputDecoration(
              hintText: "请输入手机号",
              prefixIcon: Icon(
                Icons.phone_android,
              ),
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              filled: true,
              fillColor: Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(64),
                  borderSide: BorderSide.none),
            ),
            controller: widget.phoneNumber,
          ),
        ),
        Container(
          padding: EdgeInsets.only(bottom: 30),
          child: LeftRightBox(
            left: Container(
              child: TextField(
                autofocus: false,
                decoration: InputDecoration(
                  hintText: "验证码",
                  prefixIcon: Icon(Icons.lock),
                  isCollapsed: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  filled: true,
                  fillColor: Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(64),
                      borderSide: BorderSide.none),
                ),
                controller: widget.verifyCode,
              ),
            ),
            right: Container(
                margin: EdgeInsets.only(left: 20, right: 20),
                child: SendVerifyButton(
                  sendVerify: () async {
                    if (widget.phoneNumber.text == "") {
                      Fluttertoast.showToast(msg: "请输入手机号");
                      return false;
                    }
                    var status = await Global.tiebaAPI
                        .checkRegPhone(widget.phoneNumber.text);
                    if (status.errInfo?.no == "3" &&
                        status.data?.jumpReg == "1") {
                      Fluttertoast.showToast(msg: "手机号未注册或已被运营商二次放号，请重新注册新帐号");
                      return true;
                    } else if (status.errInfo?.no == "3") {
                      Fluttertoast.showToast(msg: "您的手机号码尚未注册或未开启手机号登录");
                      return true;
                    } else if (status.errInfo?.no == "0") {
                      //尝试正常发送
                      var sendPass = await Global.tiebaAPI
                          .sendPass(widget.phoneNumber.text);
                      //需要输入验证码
                      if (sendPass.errno == 18 || sendPass.errno == 19) {
                        smsCodeSign = sendPass.vcodesign!;
                        smsCodeStr = sendPass.vcodestr!;
                        showDialog(
                          context: context,
                          builder: (context) => WordPassMachine(
                            vcodestr: sendPass.vcodestr!,
                            verifyFunction:
                                (TextEditingController controller) async {
                              if (controller.text == "") {
                                Fluttertoast.showToast(msg: "请输入验证码");
                                return false;
                              }
                              var res = await Global.tiebaAPI.sendPass(
                                  widget.phoneNumber.text,
                                  needVerify: true,
                                  vcodesign: smsCodeSign,
                                  vcodestr: smsCodeStr,
                                  verifycode: controller.text);
                              if (res.errno == 0) {
                                smsSend = true;
                                Fluttertoast.showToast(msg: "发送成功");
                                return true;
                              } else {
                                if (res.errno == 18 || res.errno == 19) {
                                  smsCodeSign = res.vcodesign!;
                                  smsCodeStr = res.vcodestr!;
                                }
                                Fluttertoast.showToast(msg: "${res.msg}");
                                return false;
                              }
                            },
                          ),
                        );
                      } else {
                        if (sendPass.errno == 0) {
                          smsSend = true;
                        }
                        Fluttertoast.showToast(msg: "${sendPass.msg}");
                      }
                    } else {
                      Fluttertoast.showToast(msg: "${status.errInfo?.msg}");
                    }
                    return true;
                  },
                )),
            verticalAlign: VerticalAlign.center,
          ),
        ),
        // Container(
        //   padding: EdgeInsets.only(bottom: 10),
        //   child: Text(
        //     "验证即登录，未注册将自动创建百度帐号",
        //     style: TextStyle(color: Colors.grey),
        //   ),
        // ),
        Container(
          child: GradientButton(
            padding: const EdgeInsets.all(16.0),
            borderRadius: BorderRadius.circular(64),
            child: Center(
              child: Text(
                "登录",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            onPressed: () async {
              if (widget.phoneNumber.text == "") {
                Fluttertoast.showToast(msg: "请输入用户名");
                return;
              } else if (widget.verifyCode.text == "") {
                Fluttertoast.showToast(msg: "请输入验证码");
                return;
              }
              if (!smsSend) {
                Fluttertoast.showToast(msg: "请先获取验证码");
                return;
              }
              var login = await Global.tiebaAPI.loginByPhone(
                  widget.phoneNumber.text, widget.verifyCode.text,
                  smsvcodesign: smsCodeSign, smsvcodestr: smsCodeStr);
              //是否成功登录
              if (login.errcode == "0") {
                Fluttertoast.showToast(msg: "登录成功");
                Provider.of<User>(context, listen: false).login();
                Provider.of<ForumState>(context, listen: false).refresh();
              } else if (login.errcode == "20") {
                var wapLogin = await Global.tiebaAPI.wapLoginByPhone(
                  widget.phoneNumber.text,
                  widget.verifyCode.text,
                );
                if (wapLogin.errcode == "110000") {
                  Fluttertoast.showToast(msg: "登录成功");
                  Provider.of<User>(context, listen: false).login();
                  Provider.of<ForumState>(context, listen: false).refresh();
                } else {
                  Fluttertoast.showToast(
                      msg: "登录失败错误码(err:${wapLogin.errcode}\n${wapLogin.msg})");
                }
              } else {
                Fluttertoast.showToast(
                    msg: "登录失败错误码(err:${login.errcode}\n${login.msg})");
              }
            },
          ),
        )
      ],
    );
  }
}
