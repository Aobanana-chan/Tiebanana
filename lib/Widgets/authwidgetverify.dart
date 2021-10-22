import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:select_form_field/select_form_field.dart';
import 'package:tiebanana/common/Global.dart';

///登录手机验证码安全验证Widget
class Authwidgetverify extends StatefulWidget {
  Authwidgetverify({Key? key}) : super(key: key);

  @override
  _AuthwidgetverifyState createState() => _AuthwidgetverifyState();
}

class _AuthwidgetverifyState extends State<Authwidgetverify> {
  TextEditingController _controller =
      TextEditingController.fromValue(TextEditingValue.empty);
  String verifyType = "";
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Dialog(
        child: SingleChildScrollView(
          child: Column(
            children: [
              AppBar(
                title: Text("安全验证"),
                leading: Icon(Icons.lock),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  children: [
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      "您的帐号可能存在安全风险，为了确保为您本人操作，请先进行安全验证。",
                      style: TextStyle(color: Color(0xFF606060), fontSize: 14),
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    Row(
                      children: [
                        Text(
                          "验证方式",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        )
                      ],
                    ),
                    _VerifyTypeDropDown(),
                    Row(
                      children: [
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _controller,
                          ),
                        ),
                        Spacer(),
                        SendVerifyButton(),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                        onPressed: () async {
                          var respone = await Global.tiebaAPI.authVerifyManager
                              .Verify(verifyType, _controller.text);

                          //验证成功
                          if (respone.errcode == "110000") {
                            if (respone.msg != "") {
                              Fluttertoast.showToast(msg: respone.msg!);
                            } else {
                              Fluttertoast.showToast(msg: "验证成功");
                            }
                            Navigator.pop(context, true);
                          } else {
                            Fluttertoast.showToast(
                                msg:
                                    "验证失败,错误码(err:${respone.errcode}\n${respone.msg})");
                          }
                        },
                        child: Center(
                          child: Text("确定"),
                        ))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

///验证方式选择下拉菜单
class _VerifyTypeDropDown extends StatefulWidget {
  _VerifyTypeDropDown({Key? key}) : super(key: key);

  @override
  __VerifyTypeDropDownState createState() => __VerifyTypeDropDownState();
}

class __VerifyTypeDropDownState extends State<_VerifyTypeDropDown> {
  List<Map<String, dynamic>> _items = [];
  TextEditingController controller =
      TextEditingController.fromValue(TextEditingValue(text: "正在获取验证方式"));
  Future _getVerifySolution() async {
    var res = await Global.tiebaAPI.authVerifyManager.getVerifyData();
    if (res.errno == "110000") {
      var data = res.data!.toJson();
      for (var type in data.keys) {
        if (data[type] != Null && data[type].length != 0) if (data[type]
            is String) {
          _items.add({"value": type, "label": data[type]});
        }
        // else if(data[type] is List)
        // {
        //   //银行卡号List
        //   for (var card in data[type]) {

        //   }
        // }

      }
      setState(() {
        controller.text = _items.length > 0 ? _items[0]["label"] : "";
        context.findAncestorStateOfType<_AuthwidgetverifyState>()!.verifyType =
            _items.length > 0 ? _items[0]["value"] : "";
      });
    } else {
      Fluttertoast.showToast(
          msg: "获取验证方式错误，错误代码(errno):${res.errno}\n${res.msg}");
      Navigator.pop(context, false);
    }
  }

  @override
  void initState() {
    super.initState();
    _getVerifySolution();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SelectFormField(
        items: _items,
        labelText: controller.text,
        controller: controller,
        onChanged: (val) {
          context
              .findAncestorStateOfType<_AuthwidgetverifyState>()!
              .verifyType = val;
          if (val != "mobile") {
            Fluttertoast.showToast(msg: "建议验证方式选择手机短信验证，目前不保证其他验证方式正常工作");
          }
        },
      ),
    );
  }
}

class SendVerifyButton extends StatefulWidget {
  SendVerifyButton({Key? key}) : super(key: key);

  @override
  _SendVerifyButtonState createState() => _SendVerifyButtonState();
}

//发送验证码按钮
class _SendVerifyButtonState extends State<SendVerifyButton> {
  int cooldown = 0; //按钮冷却
  bool isClicked = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      child: ElevatedButton(
        onPressed: cooldown > 0
            ? null
            : () {
                var type = context
                    .findAncestorStateOfType<_AuthwidgetverifyState>()!
                    .verifyType;
                Global.tiebaAPI.authVerifyManager.sendVerify(type);
                isClicked = true;
                cooldown = 60;
                //设置倒计时
                Timer.periodic(Duration(seconds: 1), (timer) {
                  cooldown--;
                  if (cooldown <= 0) {
                    timer.cancel();
                  }
                  setState(() {});
                });

                // //获取输入的验证码
                // var i = context.findAncestorStateOfType<_AuthwidgetverifyState>();
                // var vcode = i!._controller.text;
                // Global.tiebaAPI.authVerifyManager.Verify(type, vcode)
              },
        child: Builder(
          builder: (context) {
            if (!isClicked) {
              return Text("发送验证码");
            } else if (cooldown > 0) {
              return Text(
                "重新发送($cooldown秒)",
              );
            } else {
              return Text("重新发送");
            }
          },
        ),
      ),
    );
  }
}
