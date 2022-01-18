import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/common/Global.dart';

//角度转弧度
double radians(double degree) {
  return (degree / 180) * 3.1415926;
}

void record(e) {
  Global.tiebaAPI.passMachine.recordAction(
      "mv",
      MoveActionData(
              fx: e.localPosition.dx.toInt(),
              fy: e.localPosition.dy.toInt(),
              t: DateTime.now().millisecondsSinceEpoch)
          .toJson());
}

///验证码Widget
///验证成功返回true
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
        //图未加载完成就加载进度条
        return Container(
            child: Center(
          child: SizedBox(
              height: 75,
              width: 75,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.blue),
                backgroundColor: Colors.grey[200],
                strokeWidth: 3,
              )),
        ));
      }
    });
  }
}

class _Rotateableimg extends StatelessWidget {
  final double rotateDegree;
  final img;
  _Rotateableimg({Key? key, required this.rotateDegree, required this.img})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        // transform: Matrix4.rotationZ(radians(rotateDegree)),
        child: Padding(
            padding: EdgeInsets.fromLTRB(0, 28, 0, 24),
            child: Transform.rotate(
                angle: radians(rotateDegree),
                child: SizedBox(
                  height: 152,
                  width: 152,
                  child: ClipOval(
                    child: Image.memory(img),
                  ),
                ))));
  }
}

//旋转验证码主界面
class _Maincontainer extends StatefulWidget {
  _Maincontainer({Key? key}) : super(key: key);

  @override
  __MaincontainerState createState() => __MaincontainerState();
}

class __MaincontainerState extends State<_Maincontainer> {
  var img;
  double rotateDegree = 0;
  @override
  void initState() {
    super.initState();
    img = context.findAncestorStateOfType<_PassMachineWidgetState>()!.img;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 40, 16, 18),
      decoration:
          BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(125))),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              "安全验证",
              style: TextStyle(color: Color(0xFFB8B8B8), fontSize: 14),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "拖动滑块，使图片角度为正",
              style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 18),
            ),
            _Rotateableimg(
              img: img,
              rotateDegree: rotateDegree,
            ),
            Listener(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 10,
                  inactiveTrackColor: Color(0xFFF5F5F5),
                  //thumbShape: _CaptchaSliderThumb()
                ),
                child: Slider(
                  // label: rotateDegree.toString(),
                  value: rotateDegree / 360,
                  onChanged: (value) {
                    setState(() {
                      rotateDegree = value * 360;
                    });
                  },
                  onChangeEnd: (value) async {
                    print(value);
                    Global.tiebaAPI.passMachine.setAcc(value);
                    if (await Global.tiebaAPI.passMachine.verify() == true) {
                      //验证成功就返回
                      Navigator.of(context).pop(true);
                    } else {
                      rotateDegree = 0;
                      img = await Global.tiebaAPI.passMachine.getCaptchaImg();
                      setState(() {});
                    }
                  },
                  divisions: 100,
                ),
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
                Throttle.milliseconds(200, record, [e]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

//TODO:滑块样式(待完成)
class _CaptchaSliderThumb extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    throw UnimplementedError();
  }

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {}
}
