import 'package:flutter/material.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/SearchBar.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/common/Global.dart';

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
        threadwidgets.add(ThreadSummary(info: recommend[i]!));
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
                color: Provider.of<APPTheme>(context).theme,
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
                          physics: const BouncingScrollPhysics(),
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
