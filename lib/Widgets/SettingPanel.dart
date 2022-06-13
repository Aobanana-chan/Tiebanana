import 'package:flutter/material.dart';
import 'package:tiebanana/routes/routes.dart';

class SettingPanel extends StatefulWidget {
  const SettingPanel({Key? key}) : super(key: key);

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
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            disabledElevation: 0,
            color: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, PageRouter.threadStore);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.star),
                SizedBox(
                  width: 5,
                ),
                Text("我的收藏")
              ],
            ),
          ),
          MaterialButton(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            disabledElevation: 0,
            color: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, PageRouter.viewHistory);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.history),
                SizedBox(
                  width: 5,
                ),
                Text("浏览历史")
              ],
            ),
          ),
          MaterialButton(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            disabledElevation: 0,
            color: Colors.white,
            onPressed: () {
              //TODO:主题切换
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.brush),
                SizedBox(
                  width: 5,
                ),
                Text("主题切换")
              ],
            ),
          ),
          MaterialButton(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            disabledElevation: 0,
            color: Colors.white,
            onPressed: () {
              //TODO：贴吧服务中心
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.home_repair_service_rounded),
                SizedBox(
                  width: 5,
                ),
                Text("服务中心")
              ],
            ),
          ),
          MaterialButton(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            disabledElevation: 0,
            color: Colors.white,
            onPressed: () {
              //TODO:软件设置
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
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
