import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/common/Global.dart';

///验证码Widget

class PassMachineWidget extends StatefulWidget {
  PassMachineWidget({Key? key}) : super(key: key);

  @override
  _PassMachineWidgetState createState() => _PassMachineWidgetState();
}

class _PassMachineWidgetState extends State<PassMachineWidget> {
  late var img;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(future: () async {
      img = await Global.tiebaAPI.passMachine.getCaptchaImg();
    }(), builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        return Dialog(child: _Maincontainer());
      } else {
        return Container(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.blue),
            backgroundColor: Colors.grey[200],
          ),
        );
      }
    });
  }
}

class _Rotateableimg extends StatelessWidget {
  final double rotateRadian;
  final img;
  _Rotateableimg({Key? key, required this.rotateRadian, required this.img})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Padding(
            padding: EdgeInsets.fromLTRB(0, 28, 0, 24),
            child: Transform(
                transform: Matrix4.rotationY(rotateRadian),
                child: Image.memory(img))));
  }
}

class _Maincontainer extends StatefulWidget {
  _Maincontainer({Key? key}) : super(key: key);

  @override
  __MaincontainerState createState() => __MaincontainerState();
}

class __MaincontainerState extends State<_Maincontainer> {
  var img;
  double rotateRadian = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    img = context.findAncestorStateOfType<_PassMachineWidgetState>()!.img;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text(
            "安全验证",
            style: TextStyle(color: Color(0xB8B8B8), fontSize: 14),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            "拖动滑块，使图片角度为正",
            style: TextStyle(fontSize: 18, color: Color(0x1F1F1F)),
          ),
          _Rotateableimg(
            img: img,
            rotateRadian: rotateRadian,
          ),
          Listener(
            child: Slider(
              value: 0,
              onChanged: (value) {
                setState(() {
                  rotateRadian = value * 360;
                });
              },
              onChangeEnd: (value) async {
                Global.tiebaAPI.passMachine.setAcc(value);
                if (await Global.tiebaAPI.passMachine.verify() == true) {
                  //验证成功就返回
                  Navigator.of(context).pop(true);
                } else {
                  setState(() async {
                    value = 0;
                    img = await Global.tiebaAPI.passMachine.getCaptchaImg();
                  });
                }
              },
              divisions: 100,
            ),
            //记录操作
            onPointerDown: (e) {
              Global.tiebaAPI.passMachine.recordAction(
                  "cl",
                  ClickActionData(
                          x: e.localPosition.dx.toInt(),
                          y: e.localPosition.dy.toInt(),
                          t: DateTime.now().millisecondsSinceEpoch)
                      .toJson());
            },
            onPointerMove: (e) {
              Global.tiebaAPI.passMachine.recordAction(
                  "mv",
                  MoveActionData(
                          fx: e.localPosition.dx.toInt(),
                          fy: e.localPosition.dy.toInt(),
                          t: DateTime.now().millisecondsSinceEpoch)
                      .toJson());
            },
          ),
        ],
      ),
    );
  }
}
