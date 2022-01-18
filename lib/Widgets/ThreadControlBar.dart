import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/CustomUnderlineTabIndicator.dart';
import 'package:tiebanana/common/Global.dart';

///吧页面帖控制导航栏

class ThreadControlBar extends StatefulWidget {
  final TabController controller;
  final List tabs;
  final List<GoodClassify>? goodClassify;
  final String kw;
  ThreadControlBar(
      {Key? key,
      required this.controller,
      required this.tabs,
      required this.goodClassify,
      required this.kw})
      : super(key: key);

  @override
  _ThreadControlBarState createState() => _ThreadControlBarState();
}

class _ThreadControlBarState extends State<ThreadControlBar> {
  List sortType = ["回复时间排序", "发帖时间排序", "关注人发帖"];

  List<DropdownMenuItem<String>> buildSortItem() {
    return (sortType.map((e) {
      return DropdownMenuItem<String>(value: e, child: Text(e));
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          //贴控制

          LeftRightBox(
            left: Container(
              width: 150,
              child: TabBar(
                controller: widget.controller,
                labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                labelColor: Colors.blue,
                indicator: CustomUnderlineTabIndicator(
                    wantWidth: 36,
                    insets: EdgeInsets.only(left: 15, right: 15),
                    borderSide: BorderSide(width: 4, color: Colors.green)),
                tabs: widget.tabs
                    .map((e) => Tab(
                          text: e,
                        ))
                    .toList(),
                onTap: (value) async {
                  if (Provider.of<ThreadListProviderModel>(context,
                              listen: false)
                          .threadList ==
                      null) {
                    Provider.of<ThreadListProviderModel>(context, listen: false)
                        .setList = (await Global.tiebaAPI.getForumPage(
                      kw: widget.kw,
                      pn: 1,
                      isgood: true,
                    ))
                        .threadList;
                  }
                },
              ),
            ),
            right: Container(
              child: DropdownButton<String>(
                items: buildSortItem(),
                onChanged: (value) {},
              ),
            ),
          ),
          //精品贴分类控制
          Row()
        ],
      ),
    );
  }
}
