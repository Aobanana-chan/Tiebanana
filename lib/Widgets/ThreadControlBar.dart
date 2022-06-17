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
  final int classSelect;
  final bool showClass;
  final int sortType;
  final void Function(int) changeSortType;
  const ThreadControlBar(
      {Key? key,
      required this.controller,
      required this.tabs,
      required this.goodClassify,
      required this.kw,
      required this.classSelect,
      required this.showClass,
      required this.sortType,
      required this.changeSortType})
      : super(key: key);

  @override
  _ThreadControlBarState createState() => _ThreadControlBarState();
}

class _ThreadControlBarState extends State<ThreadControlBar> {
  List sortType = ["回复时间排序", "发帖时间排序", "关注人发帖"];
  String dropDownValue = "回复时间排序";
  @override
  void initState() {
    super.initState();
    dropDownValue = sortType[widget.sortType];
  }

  List<DropdownMenuItem<String>> buildSortItem() {
    return (sortType.map((e) {
      return DropdownMenuItem<String>(value: e, child: Text(e));
    }).toList());
  }

  List<Widget> _buildClassify() {
    List<Widget> classify = <Widget>[];
    for (GoodClassify c in widget.goodClassify ?? []) {
      classify.add(ClassifyButton(
        sortType: widget.sortType,
        kw: widget.kw,
        classify: c,
        seleted: c.classId == widget.classSelect.toString(),
      ));
    }
    return classify;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Theme.of(context).backgroundColor,
      child: Column(
        children: [
          //贴控制

          LeftRightBox(
            left: SizedBox(
              width: 150,
              child: TabBar(
                controller: widget.controller,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                labelColor: Theme.of(context).brightness == Brightness.light
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.onSurface,
                indicator: CustomUnderlineTabIndicator(
                    wantWidth: 36,
                    insets: const EdgeInsets.only(left: 15, right: 15),
                    borderSide: BorderSide(
                        width: 4,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).colorScheme.onSurface)),
                tabs: widget.tabs
                    .map((e) => Tab(
                          text: e,
                        ))
                    .toList(),
              ),
            ),
            right: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).backgroundColor,
              ),
              child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                items: buildSortItem(),
                onChanged: (value) {
                  if (value != null) {
                    for (var i = 0; i < sortType.length; i++) {
                      if (value == sortType[i]) {
                        widget.changeSortType(i);
                        break;
                      }
                    }
                    setState(() {
                      dropDownValue = value;
                    });
                  }
                },
                value: dropDownValue,
                borderRadius: BorderRadius.circular(8),
              )),
            ),
          ),
          //精品贴分类控制
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: widget.showClass
                ? const BoxConstraints(maxHeight: 128)
                : const BoxConstraints(maxHeight: 0),
            child: AnimatedOpacity(
              opacity: widget.showClass ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeIn,
              child: SingleChildScrollView(
                // physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildClassify(),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ClassifyButton extends StatelessWidget {
  final GoodClassify classify;
  final bool seleted;
  final String kw;
  final int sortType;
  const ClassifyButton(
      {Key? key,
      required this.classify,
      required this.seleted,
      required this.kw,
      required this.sortType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: EdgeInsets.all(10),
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: seleted ? Colors.blue : Colors.white,
        border: Border.all(width: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: MaterialButton(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
          onPressed: () async {
            Provider.of<GoodClassifyProviderModel>(context, listen: false)
                .changeClassify = int.parse(classify.classId!);
            Provider.of<ThreadListProviderModel>(context, listen: false)
                .setList = (await Global.tiebaAPI.getForumPage(
                    sortType: sortType,
                    kw: kw,
                    pn: 1,
                    isgood: true,
                    cid: int.parse(classify.classId!)))
                .threadList;
            Provider.of<ThreadListProviderModel>(context, listen: false)
                .goodpn = 1;
          },
          textColor: seleted ? Colors.white : Colors.black,
          // onTap: () {},
          child: Text(classify.className!),
        ),
      ),
    );
  }
}
