import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

import 'package:tiebanana/common/Global.dart';

///主页搜索栏Widget
class SearchBar extends StatefulWidget {
  SearchBar({Key? key}) : super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  bool isFocused = false;
  String searchTXT = "";
  FloatingSearchBarController barController = FloatingSearchBarController();
  @override
  void initState() {
    super.initState();
  }

  Widget? _buildBody() {
    if (!isFocused) {
      return null;
    }
    return AnimatedDropDown();
  }

  void search(BuildContext context, String searchText) {
    //记录历史记录
    var cache = Global.profile.getStringList("searchHistory");
    if (cache == null) {
      cache = [searchText];
    } else {
      cache.add(searchText);
    }
    Global.profile.setStringList("searchHistory", cache);
    //跳转到搜索页面
    // Navigator.push(context, route)
  }

  @override
  Widget build(BuildContext context) {
    return FloatingSearchAppBar(
      controller: barController,
      clearQueryOnClose: false,
      onSubmitted: (searchText) {
        search(context, searchText);
      },
      onQueryChanged: (str) => searchTXT = str,
      // hideKeyboardOnDownScroll: true,
      leadingActions: [
        FloatingSearchBarAction.icon(
            icon: Icon(Icons.search),
            onTap: () {
              search(context, searchTXT);
            })
      ],
      hint: "搜索吧、贴、用户",
      body: _buildBody(),
      actions: [
        RawMaterialButton(
          shape: CircleBorder(),
          onPressed: () {
            Fluttertoast.showToast(msg: "签到开始，可前往通知栏查看签到进度");
            Global.tiebaAPI.signAll();
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
                      color: Colors.blueGrey.shade800,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        )
      ],

      onFocusChanged: (focused) {
        isFocused = focused;
        setState(() {});
      },
    );
  }
}

class AnimatedDropDown extends StatefulWidget {
  AnimatedDropDown({Key? key}) : super(key: key);

  @override
  _AnimatedDropDownState createState() => _AnimatedDropDownState();
}

class _AnimatedDropDownState extends State<AnimatedDropDown> {
  late _SearchBarState? bar;
  late List history;

  void getHistory() {
    var local = Global.profile.getStringList("searchHistory");
    history = local == null ? [] : local;
  }

  @override
  void initState() {
    super.initState();
    getHistory();
  }

  @override
  Widget build(BuildContext context) {
    bar = context.findAncestorStateOfType<_SearchBarState>();
    List<Widget> historyWidgetList = history.map((item) {
      return MaterialButton(
        padding: EdgeInsets.all(20),
        onPressed: () {
          bar!.barController.query = item;
          // bar!.barController.close();
        },
        child: Container(
          color: Color(0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }).toList();
    if (historyWidgetList.length != 0) {
      historyWidgetList.add(MaterialButton(
        padding: EdgeInsets.all(20),
        onPressed: () {
          Global.profile.setStringList("searchHistory", []);
          setState(() {
            getHistory();
          });
        },
        child: Align(
          alignment: Alignment.center,
          child: Text(
            "清除历史搜索记录",
            style: TextStyle(fontSize: 18),
          ),
        ),
      ));
    }
    return FadeInDown(
        duration: Duration(milliseconds: 400),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: Colors.white,
            elevation: 4.0,
            child: SingleChildScrollView(
              child: Column(children: historyWidgetList),
            ),
          ),
        ));
  }
}
