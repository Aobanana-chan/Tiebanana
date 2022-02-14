import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/ForumTag.dart';
import 'package:tiebanana/Widgets/SearchBar.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/Login.dart';
import 'package:tiebanana/routes/Message.dart';
import 'package:tiebanana/routes/Recommend.dart';
import 'package:tiebanana/routes/User.dart';

///首页
var page = <Widget>[
  KeepAliveWrapper(child: _Home()),
  KeepAliveWrapper(child: _Recommand()),
  KeepAliveWrapper(child: _Notifaction()),
  KeepAliveWrapper(child: _UserAndSettings())
];

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _currentPage = 0;
  late ForumState forumState;
  PageController controller = PageController();
  DateTime? lastPopTime;
  @override
  void initState() {
    super.initState();
    forumState = ForumState();
  }

  @override
  Widget build(BuildContext context) {
    Widget childpage;
    if (Global.tiebaAPI.isLogin == false) {
      childpage = Scaffold(
        body: ChangeNotifierProvider.value(
          value: forumState,
          builder: (context, child) => LoginPage(),
        ),
      );
    } else {
      childpage = Scaffold(
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
                backgroundColor: Colors.white,
                icon: Icon(Icons.home_outlined),
                label: "首页",
                activeIcon: Icon(Icons.home)),
            BottomNavigationBarItem(
              backgroundColor: Colors.white,
              icon: Icon(Icons.circle_notifications_outlined),
              activeIcon: Icon(Icons.circle_notifications_rounded),
              label: "动态",
            ),
            BottomNavigationBarItem(
                backgroundColor: Colors.white,
                icon: Icon(Icons.reply),
                activeIcon: Icon(Icons.reply_all),
                label: "消息"),
            BottomNavigationBarItem(
                backgroundColor: Colors.white,
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: "个人")
          ],
          currentIndex: _currentPage,
          onTap: (index) {
            setState(() {
              _currentPage = index;
              controller.animateToPage(_currentPage,
                  duration: Duration(milliseconds: 200), curve: Curves.easeIn);
            });
          },
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey.shade800,
        ),
        body: ChangeNotifierProvider.value(
          value: forumState,
          builder: (context, child) => PageView(
            physics: NeverScrollableScrollPhysics(),
            controller: controller,
            children: page,
          ),
        ),
      );
    }
    return WillPopScope(
        child: childpage,
        onWillPop: () async {
          // 点击返回键的操作
          if (lastPopTime == null ||
              DateTime.now().difference(lastPopTime!) > Duration(seconds: 2)) {
            lastPopTime = DateTime.now();
            Fluttertoast.showToast(msg: '请再按一次退出！');
            return false;
          } else {
            lastPopTime = DateTime.now();
            // 退出app
            return true;
          }
        });
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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Color(0xFFF2F2F5)),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchBar(
                maxHeight: constraints.maxHeight,
              ),
              Expanded(
                child: TagPan(),
              )
            ],
          );
        },
      ),
    );
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
    return RecommendPan();
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
    return MessagePan();
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
    return UserPage();
  }
}
