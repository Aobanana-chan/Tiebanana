import 'package:flutter/material.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/WidgetModel/PostContentModel.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/SearchBar.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/common/Global.dart';

import '../Json_Model/WidgetModel/ThreadCommentModel.dart';

class RecommendPan extends StatefulWidget {
  final FloatingSearchBarController controller;
  const RecommendPan({Key? key, required this.controller}) : super(key: key);

  @override
  _RecommendPanState createState() => _RecommendPanState();
}

class _RecommendPanState extends State<RecommendPan> {
  List<ThreadRecommendSummary?> recommend = [];
  int pn = 1;
  ScrollController controller = ScrollController();
  Future<void> refresh() async {
    if (recommend.isNotEmpty) {
      recommend.remove(null);
      recommend.insert(0, null);
    }

    var newThread = await Global.tiebaAPI.getRecommThread(15, 1);
    recommend.insertAll(0, newThread);
    // pn++;
    setState(() {});
  }

  Future nextPage() async {
    var newThread = await Global.tiebaAPI.getRecommThread(15, ++pn);
    recommend.addAll(newThread);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    refresh();

    controller.addListener(() {
      if (controller.position.pixels >
          controller.position.maxScrollExtent -
              controller.position.viewportDimension) {
        Throttle.seconds(2, nextPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> threadwidgets = [];

    for (var i = 0; i < recommend.length; i++) {
      if (recommend[i] != null) {
        threadwidgets.add(ThreadSummary(
          firstPostContent: () {
            var result = <PostContentBaseWidgetModel>[];
            for (Content element in recommend[i]!.firstPostContent!) {
              result.add(createContentModel(element));
            }
            return result;
          }(),
          author: AuthorWidgetModel(
            icons: () {
              var icon = <String>[];
              for (Iconinfo element in recommend[i]!.author!.iconinfo ?? []) {
                icon.add(element.icon!);
              }
              return icon;
            }(),
            nameShow: recommend[i]!.author!.nameShow,
            username: recommend[i]!.author!.name,
            uid: recommend[i]!.author!.id!,
            portrait: recommend[i]!.author!.portrait!,
            levelID: "",
          ),
          createTime: recommend[i]!.createTime!,
          latestTime: recommend[i]!.lastTimeInt!,
          tid: recommend[i]!.id!,
          fname: recommend[i]!.fname!,
          viewNum: recommend[i]!.viewNum!,
          title: recommend[i]!.title!,
          agreeNum: recommend[i]!.agree!.agreeNum!,
          disagreeNum: recommend[i]!.agree!.disagreeNum!,
          replyNum: recommend[i]!.replyNum!,
        ));
      } else {
        threadwidgets.add(ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: GestureDetector(
            onTap: () async {
              refresh();
              controller.animateTo(0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut);
            },
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Provider.of<APPSettingProvider>(context).materialTheme,
                // border: Border.all(width: 0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                  Text(
                    "上次读到这里,点击刷新",
                    style: TextStyle(color: Colors.white),
                  )
                ],
              ),
            ),
          ),
        ));
      }
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          children: [
            SearchBar(
              maxHeight: constraints.maxHeight,
              barController: widget.controller,
            ),
            Expanded(
                child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: (() => widget.controller.close()),
                    child: Container(
                      padding: const EdgeInsets.only(left: 5, right: 5),
                      child: RefreshIndicator(
                        triggerMode: RefreshIndicatorTriggerMode.anywhere,
                        onRefresh: refresh,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          controller: controller,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: threadwidgets,
                        ),
                      ),
                    )))
          ],
        );
      },
    );
  }
}
