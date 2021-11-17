import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/forumtag.dart';

import 'package:tiebanana/common/Global.dart';

///主页搜索栏Widget
class SearchBar extends StatefulWidget {
  final double? maxHeight;
  SearchBar({Key? key, this.maxHeight = double.infinity}) : super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  bool isFocused = false;
  String searchTXT = "";
  FloatingSearchBarController barController = FloatingSearchBarController();
  bool showBody = false;
  AnimationController? controller;
  @override
  void initState() {
    super.initState();
  }

  Widget? _buildBody() {
    if (!showBody) {
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
      if (cache.contains(searchText)) {
        //重复搜索将关键词提前
        cache.remove(searchText);
        cache.insert(0, searchText);
      } else {
        cache.insert(0, searchText);
      }
    }
    Global.profile.setStringList("searchHistory", cache);
    //TODO:跳转到搜索页面
    // Navigator.push(context, route)
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FloatingSearchAppBar(
      color: Colors.white,
      colorOnScroll: Colors.white,
      controller: barController,
      clearQueryOnClose: false,
      onSubmitted: (searchText) {
        if (searchText != "") {
          search(context, searchText);
        }
      },
      onQueryChanged: (str) => searchTXT = str,
      // hideKeyboardOnDownScroll: true,
      leadingActions: [
        FloatingSearchBarAction.icon(
            icon: Icon(Icons.search),
            onTap: () {
              if (searchTXT != "") {
                search(context, searchTXT);
              }
            })
      ],
      hint: "搜索吧、贴、用户",
      body: _buildBody(),
      actions: [
        RawMaterialButton(
          shape: CircleBorder(),
          onPressed: () async {
            Fluttertoast.showToast(msg: "签到开始，可前往通知栏查看签到进度");
            await Global.tiebaAPI.signAll();
            Provider.of<ForumState>(context, listen: false).refresh();
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
        if (focused == true) {
          showBody = true;
        } else {
          controller!.reverse();
        }
        setState(() {});
      },
    );
  }
}

class AnimatedDropDown extends StatefulWidget {
  final Duration duration;
  AnimatedDropDown(
      {Key? key, this.duration = const Duration(milliseconds: 400)})
      : super(key: key);

  @override
  _AnimatedDropDownState createState() => _AnimatedDropDownState();
}

class _AnimatedDropDownState extends State<AnimatedDropDown>
    with SingleTickerProviderStateMixin {
  late _SearchBarState? bar;
  late List<String> history;
  PointerDownEvent? tapPoint;
  late Animation<double> animation;
  bool bind = false;
  ScrollController scrollController = ScrollController();

  double? realheight;
  double? prevheight;
  double barHeight = 0;
  void getHistory() {
    var local = Global.profile.getStringList("searchHistory");
    history = local == null ? [] : local;
  }

  //TODO:该代码可以优化
  double calcHeight() {
    if (realheight == null && prevheight == null) {
      return 0;
    } else if (realheight == null && prevheight != null) {
      return animation.value * prevheight!;
    } else {
      prevheight = realheight;
      return animation.value * realheight!;
    }
  }

  @override
  void initState() {
    super.initState();
    getHistory();
  }

  @override
  void didUpdateWidget(covariant AnimatedDropDown oldWidget) {
    super.didUpdateWidget(oldWidget);
    getHistory();
    // realheight = null;
  }

  @override
  void dispose() {
    bar!.controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RenderBox overlay =
        Overlay.of(context)!.context.findRenderObject() as RenderBox;
    if (realheight == null) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        realheight = scrollController.position.maxScrollExtent;
        barHeight = bar!.context.size!.height;
        setState(() {});
      });
    }

    //动画绑定
    if (!bind) {
      bar = context.findAncestorStateOfType<_SearchBarState>();
      bar!.controller =
          AnimationController(duration: widget.duration, vsync: this);
      animation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: bar!.controller!, curve: Curves.easeOut));
      bar!.controller!.forward();
      bar!.controller!.addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          bar!.showBody = false;
          bar!.setState(() {});
          scrollController.jumpTo(0);
          bar!.barController.close();
        }
      });
      bind = true;
    }

    //获取历史记录添加到列表
    List<Widget> historyWidgetList = history.map((item) {
      return MaterialButton(
        padding: EdgeInsets.all(20),
        onPressed: () {
          bar!.barController.query = item;
          // bar!.barController.close();
        },
        onLongPress: () {
          showMenu(
              context: context,
              position: RelativeRect.fromLTRB(
                  tapPoint!.localPosition.dx,
                  tapPoint!.localPosition.dy,
                  overlay.size.width - tapPoint!.localPosition.dx,
                  overlay.size.height - tapPoint!.localPosition.dy),
              items: [
                PopupMenuItem(
                  onTap: () {
                    //删除该历史搜索
                    history.remove(item);
                    Global.profile.setStringList("searchHistory", history);
                    setState(() {});
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("删除"),
                  ),
                )
              ]);
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            item,
            style: TextStyle(fontSize: 18),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }).toList();
    //若有历史记录，添加清除历史记录按钮
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
    return AnimatedBuilder(
      animation: animation,
      child: FadeInDown(
          duration: widget.duration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Material(
                color: Colors.white,
                elevation: 4.0,
                child: Listener(
                  child: ListView(
                      controller: scrollController,
                      physics: BouncingScrollPhysics(),
                      children: historyWidgetList),
                  onPointerDown: (e) => tapPoint = e,
                )

                // SingleChildScrollView(
                //   controller: scrollController,
                //   physics: BouncingScrollPhysics(),
                //   child: Listener(
                //     child: Column(children: historyWidgetList),
                //     onPointerDown: (e) => tapPoint = e,
                //   ),
                // ),
                ),
          )),
      builder: (BuildContext context, Widget? child) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: bar!.widget.maxHeight! - barHeight,
          ),
          height: calcHeight(),
          child: child,
        );
      },
    );
  }
}
