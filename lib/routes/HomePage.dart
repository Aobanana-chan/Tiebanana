import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/ForumTag.dart';
import 'package:tiebanana/Widgets/SearchBar.dart';
import 'package:tiebanana/routes/Login.dart';
import 'package:tiebanana/routes/Message.dart';
import 'package:tiebanana/routes/Recommend.dart';
import 'package:tiebanana/routes/User.dart';

///首页
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Widget> page;
  var _currentPage = 0;
  late ForumState forumState;
  PageController controller = PageController();
  DateTime? lastPopTime;
  late Future<bool> Function() onWillPop;
  List<FloatingSearchBarController> barController = [];
  @override
  void initState() {
    super.initState();
    forumState = ForumState();
    onWillPop = () async {
      if (barController[_currentPage].isOpen) {
        barController[_currentPage].close();
        return false;
      }
      // 点击返回键的操作
      if (lastPopTime == null ||
          DateTime.now().difference(lastPopTime!) >
              const Duration(seconds: 2)) {
        lastPopTime = DateTime.now();
        Fluttertoast.showToast(msg: '请再按一次退出！');
        return false;
      } else {
        lastPopTime = DateTime.now();
        // 退出app
        return true;
      }
    };
    for (var i = 0; i < 4; i++) {
      barController.add(FloatingSearchBarController());
    }
    page = <Widget>[
      KeepAliveWrapper(
          child: _Home(
        controller: barController[0],
      )),
      KeepAliveWrapper(
          child: _Recommand(
        controller: barController[1],
      )),
      KeepAliveWrapper(
          child: _Notifaction(
        controller: barController[2],
      )),
      KeepAliveWrapper(
          child: _UserAndSettings(
        controller: barController[3],
      ))
    ];
  }

  @override
  Widget build(BuildContext context) {
    Widget childpage;
    if (Provider.of<User>(context).isLogin == false) {
      childpage = Scaffold(
        body: ChangeNotifierProvider.value(
          value: forumState,
          builder: (context, child) => const LoginPage(),
        ),
      );
    } else {
      childpage = Scaffold(
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: BottomNavigationBar(
          items: const [
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
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn);
            });
          },
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey.shade800,
        ),
        body: ChangeNotifierProvider.value(
          value: forumState,
          builder: (context, child) => PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: controller,
            children: page,
          ),
        ),
      );
    }
    return WillPopScope(onWillPop: onWillPop, child: childpage);
  }
}

//Home界面
class _Home extends StatefulWidget {
  final FloatingSearchBarController controller;
  const _Home({Key? key, required this.controller}) : super(key: key);

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
      decoration: const BoxDecoration(color: Color(0xFFF2F2F5)),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchBar(
                maxHeight: constraints.maxHeight,
                barController: widget.controller,
              ),
              Expanded(
                  child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: (() => widget.controller.close()),
                child: const TagPan(),
              )),
            ],
          );
        },
      ),
    );
  }
}

//动态界面（推荐贴）
class _Recommand extends StatefulWidget {
  final FloatingSearchBarController controller;
  const _Recommand({Key? key, required this.controller}) : super(key: key);

  @override
  __RecommandState createState() => __RecommandState();
}

class __RecommandState extends State<_Recommand> {
  @override
  Widget build(BuildContext context) {
    return RecommendPan(
      controller: widget.controller,
    );
  }
}

//消息回复和@页
class _Notifaction extends StatefulWidget {
  final FloatingSearchBarController controller;
  const _Notifaction({Key? key, required this.controller}) : super(key: key);

  @override
  __NotifactionState createState() => __NotifactionState();
}

class __NotifactionState extends State<_Notifaction> {
  @override
  Widget build(BuildContext context) {
    return MessagePan(
      controller: widget.controller,
    );
  }
}

//个人界面与软件设置
class _UserAndSettings extends StatefulWidget {
  final FloatingSearchBarController controller;
  const _UserAndSettings({Key? key, required this.controller})
      : super(key: key);

  @override
  __UserAndSettingsState createState() => __UserAndSettingsState();
}

class __UserAndSettingsState extends State<_UserAndSettings> {
  @override
  Widget build(BuildContext context) {
    return UserPage(
      controller: widget.controller,
    );
  }
}
