import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/threadSummary.dart';
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
    recommend.addAll(await Global.tiebaAPI.getRecommThread(15, pn));
    pn++;
    recommend.insert(0, null);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> threadwidgets = [];
    for (var i = 1; i < recommend.length; i++) {
      if (recommend[i] != null) {
        threadwidgets.add(ThreadSummary(info: recommend[i]!));
      } else {
        //TODO:上次阅读到这里widget
      }
    }
    return Container(
      child: RefreshIndicator(
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        onRefresh: refresh,
        child: ListView(
          physics: BouncingScrollPhysics(),
          children: threadwidgets,
        ),
      ),
    );
  }
}
