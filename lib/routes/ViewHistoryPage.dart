import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/common/AlterDialog.dart';
import 'package:tiebanana/common/API/TiebaParser.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/routes.dart';

import '../Json_Model/WidgetModel/ViewHistoryPageModel.dart';

class ViewHistoryPage extends StatefulWidget {
  const ViewHistoryPage({Key? key}) : super(key: key);

  @override
  State<ViewHistoryPage> createState() => _ViewHistoryPageState();
}

class _ViewHistoryPageState extends State<ViewHistoryPage> {
  // int offset = 0;
  // final int limit = 5;
  // ScrollController controller = ScrollController();
  late List<ViewHistoryPageModel> historys;

  @override
  void initState() {
    historys = Global.daoapi
        .getHistoryList()
        .map((e) => ViewHistoryPageModel.fromViewHistoryDatabase(e))
        .toList();
    // offset += historys.length;
    // controller.addListener(loadNextPage);
    super.initState();
  }

  // void loadNextPage() {
  //   if (controller.offset >
  //       controller.position.maxScrollExtent -
  //           controller.position.viewportDimension) {
  //     var h = Global.daoapi
  //         .getHistoryList(offset, limit)
  //         .map((e) => ViewHistoryPageModel.fromViewHistoryDatabase(e))
  //         .toList();
  //     if (h.isEmpty) {
  //       controller.removeListener(loadNextPage);
  //     } else {
  //       offset += h.length;

  //       historys.addAll(h);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Colors.white,
        // foregroundColor: Colors.black,
        title: const Text("浏览历史"),
        actions: [
          MaterialButton(
              onPressed: () async {
                var q = await showDialog(
                    context: context,
                    builder: (builder) =>
                        const TiebaAlterDialog(title: "确认清空历史记录?"));
                if (q == true) {
                  Global.daoapi.removeAllViewHistory();
                  historys.clear();
                  setState(() {});
                }
              },
              child: const Text("清空"))
        ],
      ),
      body: ListView.builder(
        // physics: const BouncingScrollPhysics(),
        // controller: controller,
        itemCount: historys.length,
        itemBuilder: (BuildContext context, int index) {
          return Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red.shade400,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.only(right: 10),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            confirmDismiss: (dismissDirection) async {
              var q = await showDialog(
                  context: context,
                  builder: (builder) =>
                      const TiebaAlterDialog(title: "删除此条历史记录?"));
              if (q == true) {
                Global.daoapi.deleteViewHistory(historys[index].id);
                return true;
              } else {
                return false;
              }
            },
            child: _HistoryItem(
              info: historys[index],
            ),
          );
        },
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final ViewHistoryPageModel info;
  const _HistoryItem({Key? key, required this.info}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var fontSize =
        Provider.of<APPSettingProvider>(context, listen: false).fontSize;
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, PageRouter.threadPage,
            arguments: ThreadPageRouterData(kz: info.tid, pid: null));
      },
      child: Container(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Theme.of(context).backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(info.title,
                style:
                    TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
          ),
          LeftRightBox(
            left: Text(
              info.forumName,
              style: TextStyle(fontSize: fontSize, color: Colors.grey),
            ),
            right: Text(TiebaParser.getPostTime(dateTime: info.latestViewTime),
                style: TextStyle(fontSize: fontSize, color: Colors.grey)),
          )
        ]),
      ),
    );
  }
}
