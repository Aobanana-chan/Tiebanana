import 'package:flutter/material.dart';

class SettingPanel extends StatefulWidget {
  SettingPanel({Key? key}) : super(key: key);

  @override
  _SettingPanelState createState() => _SettingPanelState();
}

class _SettingPanelState extends State<SettingPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          MaterialButton(
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            disabledElevation: 0,
            color: Colors.white,
            onPressed: () {},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star),
                SizedBox(
                  width: 5,
                ),
                Text("我的收藏")
              ],
            ),
          ),
          MaterialButton(
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            disabledElevation: 0,
            color: Colors.white,
            onPressed: () {},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history),
                SizedBox(
                  width: 5,
                ),
                Text("浏览历史")
              ],
            ),
          ),
          MaterialButton(
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            disabledElevation: 0,
            color: Colors.white,
            onPressed: () {},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.brush),
                SizedBox(
                  width: 5,
                ),
                Text("主题切换")
              ],
            ),
          ),
          MaterialButton(
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            disabledElevation: 0,
            color: Colors.white,
            onPressed: () {},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_repair_service_rounded),
                SizedBox(
                  width: 5,
                ),
                Text("服务中心")
              ],
            ),
          ),
          MaterialButton(
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            disabledElevation: 0,
            color: Colors.white,
            onPressed: () {},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.settings),
                SizedBox(
                  width: 5,
                ),
                Text("设置")
              ],
            ),
          ),
        ],
      ),
    );
  }
}
