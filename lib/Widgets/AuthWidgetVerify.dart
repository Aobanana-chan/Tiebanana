import 'dart:async';

import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:select_form_field/select_form_field.dart';
import 'package:tiebanana/common/Global.dart';

///登录手机验证码安全验证Widget
class Authwidgetverify extends StatefulWidget {
  const Authwidgetverify({Key? key}) : super(key: key);

  @override
  _AuthwidgetverifyState createState() => _AuthwidgetverifyState();
}

class _AuthwidgetverifyState extends State<Authwidgetverify> {
  final TextEditingController _controller =
      TextEditingController.fromValue(TextEditingValue.empty);
  String verifyType = "";
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Column(
          children: [
            AppBar(
              title: const Text("安全验证"),
              leading: const Icon(Icons.lock),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    child: const Text(
                      "您的帐号可能存在安全风险，为了确保为您本人操作，请先进行安全验证。",
                      style: TextStyle(color: Color(0xFF606060), fontSize: 14),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  Row(
                    children: const [
                      Text(
                        "验证方式",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      )
                    ],
                  ),
                  const _VerifyTypeDropDown(),
                  Container(
                    margin: const EdgeInsets.only(top: 5, bottom: 20),
                    child: LeftRightBox(
                      verticalAlign: VerticalAlign.center,
                      left: Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "验证码",
                            isCollapsed: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                            filled: true,
                            // fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(64),
                                borderSide: BorderSide.none),
                          ),
                          controller: _controller,
                        ),
                      ),
                      right: SendVerifyButton(
                        sendVerify: () async {
                          Global.tiebaAPI.authVerifyManager
                              .sendVerify(verifyType);
                          return true;
                        },
                      ),
                    ),
                  ),
                  GradientButton(
                      borderRadius: BorderRadius.circular(64),
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
                      child: const Center(
                        child: Text(
                          "确定",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

///验证方式选择下拉菜单
class _VerifyTypeDropDown extends StatefulWidget {
  const _VerifyTypeDropDown({Key? key}) : super(key: key);

  @override
  __VerifyTypeDropDownState createState() => __VerifyTypeDropDownState();
}

class __VerifyTypeDropDownState extends State<_VerifyTypeDropDown> {
  final List<Map<String, dynamic>> _items = [];
  TextEditingController controller =
      TextEditingController.fromValue(const TextEditingValue(text: "正在获取验证方式"));
  Future _getVerifySolution() async {
    var res = await Global.tiebaAPI.authVerifyManager.getVerifyData();
    if (res.errno == "110000") {
      var data = res.data!.toJson();
      for (var type in data.keys) {
        if (data[type] != Null && data[type].length != 0) {
          if (data[type] is String) {
            _items.add({"value": type, "label": data[type]});
          }
        }
        // else if(data[type] is List)
        // {
        //   //银行卡号List
        //   for (var card in data[type]) {

        //   }
        // }

      }
      setState(() {
        controller.text = _items.isNotEmpty ? _items[0]["label"] : "";
        context.findAncestorStateOfType<_AuthwidgetverifyState>()!.verifyType =
            _items.isNotEmpty ? _items[0]["value"] : "";
      });
    } else {
      Fluttertoast.showToast(
          msg: "获取验证方式错误，错误代码(errno):${res.errno}\n${res.msg}");
      if (mounted) {
        Navigator.pop(context, false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getVerifySolution();
  }

  @override
  Widget build(BuildContext context) {
    return SelectFormField(
      items: _items,
      hintText: controller.text,
      controller: controller,
      onChanged: (val) {
        context.findAncestorStateOfType<_AuthwidgetverifyState>()!.verifyType =
            val;
        if (val != "mobile") {
          Fluttertoast.showToast(msg: "建议验证方式选择手机短信验证，目前不保证其他验证方式正常工作");
        }
      },
    );
  }
}

class SendVerifyButton extends StatefulWidget {
  ///按钮冷却
  final int coolDownCount;
  final Future<bool> Function() sendVerify;
  const SendVerifyButton(
      {Key? key, this.coolDownCount = 60, required this.sendVerify})
      : super(key: key);

  @override
  _SendVerifyButtonState createState() => _SendVerifyButtonState();
}

//发送验证码按钮
class _SendVerifyButtonState extends State<SendVerifyButton> {
  int cooldown = 0; //按钮冷却
  bool isClicked = false;

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      onPressed: cooldown > 0
          ? null
          : () async {
              if (await widget.sendVerify() == false) {
                return;
              }
              isClicked = true;
              cooldown = widget.coolDownCount;
              //设置倒计时
              Timer.periodic(const Duration(seconds: 1), (timer) {
                cooldown--;
                if (cooldown <= 0) {
                  timer.cancel();
                }
                setState(() {});
              });
            },
      child: Builder(
        builder: (context) {
          if (!isClicked) {
            return const Text("发送验证码");
          } else if (cooldown > 0) {
            return Text(
              "重新发送($cooldown秒)",
            );
          } else {
            return const Text("重新发送");
          }
        },
      ),
      borderRadius: BorderRadius.circular(64),
    );
  }
}
