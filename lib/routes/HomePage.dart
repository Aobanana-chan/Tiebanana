import 'package:flutter/material.dart';
import 'package:tiebanana/Widgets/searchBar.dart';
import 'package:tiebanana/routes/Login.dart';

///首页
var page = <Widget>[_Home(), _Recommand(), _Notifaction(), _UserAndSettings()];

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _currentPage = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              backgroundColor: Colors.purpleAccent[700],
              icon: Icon(Icons.home_outlined),
              label: "首页",
              activeIcon: Icon(Icons.home)),
          BottomNavigationBarItem(
            backgroundColor: Colors.purpleAccent[700],
            icon: Icon(Icons.circle_notifications_outlined),
            activeIcon: Icon(Icons.circle_notifications_rounded),
            label: "动态",
          ),
          BottomNavigationBarItem(
              backgroundColor: Colors.purpleAccent[700],
              icon: Icon(Icons.reply),
              activeIcon: Icon(Icons.reply_all),
              label: "消息"),
          BottomNavigationBarItem(
              backgroundColor: Colors.purpleAccent[700],
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "个人")
        ],
        currentIndex: _currentPage,
        onTap: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        fixedColor: Colors.white,
      ),
      body: page[_currentPage],
    );
  }
}

//Home界面
class _Home extends StatefulWidget {
  _Home({Key? key}) : super(key: key);

  @override
  __HomeState createState() => __HomeState();
}

class __HomeState extends State<_Home> {
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(color: Color(0xFFF2F2F5)),
        child: Column(
          children: [
            AppBar(
              leading: null,
              title: SearchBar(),
              actions: [
                RawMaterialButton(
                  shape: CircleBorder(),
                  onPressed: () {
                    //TODO:签到
                  },
                  child: Stack(
                    alignment: AlignmentDirectional.center,
                    children: [
                      Icon(
                        Icons.circle_outlined,
                        size: 32,
                      ),
                      Center(
                        child: Text(
                          "签",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            Container(
              decoration: BoxDecoration(color: Colors.white),
              child: Row(
                children: [],
              ),
            )
          ],
        ));
  }
}

//动态界面（推荐贴）
class _Recommand extends StatefulWidget {
  _Recommand({Key? key}) : super(key: key);

  @override
  __RecommandState createState() => __RecommandState();
}

class __RecommandState extends State<_Recommand> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

//消息回复和@页
class _Notifaction extends StatefulWidget {
  _Notifaction({Key? key}) : super(key: key);

  @override
  __NotifactionState createState() => __NotifactionState();
}

class __NotifactionState extends State<_Notifaction> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

//个人界面与软件设置
class _UserAndSettings extends StatefulWidget {
  _UserAndSettings({Key? key}) : super(key: key);

  @override
  __UserAndSettingsState createState() => __UserAndSettingsState();
}

class __UserAndSettingsState extends State<_UserAndSettings> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: LoginPage(),
    );
  }
}
