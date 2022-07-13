import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/provider.dart';

import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/routes.dart';

///主页搜索栏Widget
class SearchBar extends StatefulWidget {
  final double? maxHeight;
  final FloatingSearchBarController? barController;
  const SearchBar(
      {Key? key, this.maxHeight = double.infinity, this.barController})
      : super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  bool isFocused = false;
  String searchTXT = "";
  late FloatingSearchBarController barController;
  bool showBody = false;
  AnimationController? controller;
  @override
  void initState() {
    super.initState();
    barController = widget.barController ?? FloatingSearchBarController();
  }

  Widget? _buildBody() {
    if (!showBody) {
      return null;
    }
    return const AnimatedDropDown();
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
    Navigator.pushNamed(context, PageRouter.search, arguments: searchTXT);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
          top: showBody ? 0 : MediaQuery.of(context).viewPadding.top),
      child: FloatingSearchAppBar(
        color: Theme.of(context).appBarTheme.backgroundColor,
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
              icon: const Icon(Icons.search),
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
            shape: const CircleBorder(),
            onPressed: () async {
              Fluttertoast.showToast(msg: "签到开始，可前往通知栏查看签到进度");
              await Global.tiebaAPI.signAll();
              if (mounted) {
                Provider.of<ForumState>(context, listen: false).refresh();
              }
            },
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: const [
                Icon(
                  Icons.circle_outlined,
                  size: 32,
                ),
                Center(
                  child: Text(
                    "签",
                    style: TextStyle(fontWeight: FontWeight.bold),
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
      ),
    );
  }
}

class AnimatedDropDown extends StatefulWidget {
  final Duration duration;
  final double barHeight;
  const AnimatedDropDown(
      {Key? key,
      this.duration = const Duration(milliseconds: 400),
      this.barHeight = 56})
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
  ScrollController scrollController = ScrollController();
  late RenderBox overlay;
  double? realheight;
  double? prevheight;
  void getHistory() {
    var local = Global.profile.getStringList("searchHistory");
    history = local ?? [];
  }

  @override
  void initState() {
    super.initState();
    getHistory();
    overlay = Overlay.of(context)!.context.findRenderObject() as RenderBox;
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
  }

  @override
  void didUpdateWidget(covariant AnimatedDropDown oldWidget) {
    super.didUpdateWidget(oldWidget);
    var historyLen = history.length;
    getHistory();
    if (history.length != historyLen) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        realheight = scrollController.position.viewportDimension;
        setState(() {});
      });
    }
  }

  List<Widget> getListWidget() {
    //获取历史记录添加到列表
    List<Widget> historyWidgetList = history.map((item) {
      return MaterialButton(
        padding: const EdgeInsets.all(20),
        onPressed: () {
          if (bar!.barController.query != item) {
            bar!.barController.query = item;
          } else {
            bar!.search(context, item);
          }

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
              shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              items: [
                PopupMenuItem(
                  // padding: EdgeInsets.zero,
                  onTap: () {
                    //删除该历史搜索
                    history.remove(item);
                    Global.profile.setStringList("searchHistory", history);
                    setState(() {});
                  },
                  child: const Align(
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
            style: const TextStyle(fontSize: 18),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }).toList();
    //若有历史记录，添加清除历史记录按钮
    if (historyWidgetList.isNotEmpty) {
      historyWidgetList.add(MaterialButton(
        padding: const EdgeInsets.all(20),
        onPressed: () {
          Global.profile.setStringList("searchHistory", []);
          setState(() {
            realheight = null;
            getHistory();
          });
        },
        child: const Align(
          alignment: Alignment.center,
          child: Text(
            "清除历史搜索记录",
            style: TextStyle(fontSize: 18),
          ),
        ),
      ));
    }
    return historyWidgetList;
  }

  @override
  void dispose() {
    bar!.controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (realheight == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        realheight = scrollController.position.maxScrollExtent;
        setState(() {});
      });
    }
    return AnimatedBuilder(
      animation: animation,
      child: FadeInDown(
          duration: widget.duration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Material(
                // color: Colors.white,
                elevation: 4.0,
                child: Listener(
                  child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      children: getListWidget()),
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
            maxHeight: bar!.widget.maxHeight! - widget.barHeight,
          ),
          child: child,
        );
      },
    );
  }
}
