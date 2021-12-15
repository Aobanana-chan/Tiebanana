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
      child: Column(
        children: [MaterialButton(onPressed: () {})],
      ),
    );
  }
}
