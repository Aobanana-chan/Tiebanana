import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/SearchBar.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/common/Global.dart';

class RecommendPan extends StatefulWidget {
  RecommendPan({Key? key}) : super(key: key);

  @override
  _RecommendPanState createState() => _RecommendPanState();
}

class _RecommendPanState extends State<RecommendPan> {
  List<ThreadRecommendSummary?> recommend = [];
  int pn = 1;
  Future<void> refresh() async {
    if (recommend.length != 0) {
      recommend.remove(null);
      recommend.insert(0, null);
    }

    var newThread = await Global.tiebaAPI.getRecommThread(15, pn);
    recommend.insertAll(0, newThread);
    pn++;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    refresh();

    //TODO:下滑加载
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> threadwidgets = [];
    ScrollController controller = ScrollController();
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
                  duration: Duration(milliseconds: 300), curve: Curves.easeOut);
            },
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Provider.of<APPTheme>(context).theme,
                // border: Border.all(width: 0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
            ),
            Expanded(
                child: Container(
              padding: EdgeInsets.only(left: 5, right: 5),
              child: RefreshIndicator(
                triggerMode: RefreshIndicatorTriggerMode.anywhere,
                onRefresh: refresh,
                child: ListView(
                  padding: EdgeInsets.zero,
                  controller: controller,
                  physics: BouncingScrollPhysics(),
                  children: threadwidgets,
                ),
              ),
            ))
          ],
        );
      },
    );
  }
}
