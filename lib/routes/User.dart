import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/SettingPanel.dart';
import 'package:tiebanana/Widgets/UserCard.dart';
import 'package:tiebanana/Widgets/searchBar.dart';
import 'package:tiebanana/common/Global.dart';

///用户信息和设置界面
class UserPage extends StatefulWidget {
  UserPage({Key? key}) : super(key: key);

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late Future<MyUserData> _myInfo;
  MyUserData? myInfo;
  @override
  void initState() {
    super.initState();
    _myInfo = Global.tiebaAPI.getMyInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return FutureBuilder(
          future: _myInfo,
          initialData: null,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return Container(
                  child: Center(
                    child: Text("初始化中..."),
                  ),
                );
              case ConnectionState.active:
                return Container(
                  child: Center(
                    child: Text("加载中..."),
                  ),
                );
              default:
                if (snapshot.hasData) {
                  myInfo = snapshot.data;
                  return Column(
                    children: [
                      SearchBar(
                        maxHeight: constraints.maxHeight,
                      ),
                      Expanded(
                          child: SingleChildScrollView(
                        child: Column(
                          children: [
                            UserCard(
                              info: myInfo!,
                            ),
                            SettingPanel()
                          ],
                        ),
                      ))
                    ],
                  );
                } else if (snapshot.hasError) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _myInfo = Global.tiebaAPI.getMyInfo();
                      });
                    },
                    child: Container(
                      child: Center(
                        child: Text("发生了错误...点击重试"),
                      ),
                    ),
                  );
                }
            }
            return Container();
          },
        );
      },
    ));
  }
}
