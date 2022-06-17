import 'package:extended_image/extended_image.dart';
import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiebanana/Json_Model/PageModel/ThreadStorePageModel.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/Widgets/common/AlterDialog.dart';
import 'package:tiebanana/common/API/TiebaParser.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/routes.dart';

///收藏贴小部件
class StoredThreadWidget extends StatefulWidget {
  final StoredThread info;
  final bool deleteMode;
  final void Function()? deleteFromList;
  const StoredThreadWidget(
      {Key? key,
      required this.info,
      required this.deleteMode,
      this.deleteFromList})
      : super(key: key);

  @override
  State<StoredThreadWidget> createState() => _StoredThreadWidgetState();
}

class _StoredThreadWidgetState extends State<StoredThreadWidget> {
  late StoredThread info;

  @override
  void initState() {
    info = widget.info;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, PageRouter.threadPage,
            arguments: ThreadPageRouterData(kz: info.id, pid: info.pid));
      },
      child: Container(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Theme.of(context).colorScheme.background,
        margin: const EdgeInsets.only(top: 3, bottom: 3),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Visibility(
                visible: widget.deleteMode,
                child: Container(
                  padding: const EdgeInsets.only(right: 5),
                  child: Center(
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        //取消收藏
                        var q = await showDialog(
                            context: context,
                            builder: (builder) =>
                                const TiebaAlterDialog(title: "确认取消收藏?"));
                        if (q == true) {
                          var res =
                              await Global.tiebaAPI.threadRemoveStore(info.id);
                          if (res.error?.errno == "0") {
                            widget.deleteFromList?.call();
                          } else {
                            Fluttertoast.showToast(msg: "操作失败");
                          }
                        }
                      },
                      // Icons.delete,
                      // color: Colors.red,
                    ),
                  ),
                )),
            Expanded(
                child: Column(children: [
              Container(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Avatar(
                      imgUrl: info.portrait,
                      width: 35,
                      height: 35,
                      onTap: () {
                        Navigator.pushNamed(context, PageRouter.user,
                            arguments: info.uid);
                      },
                    ),
                    Expanded(
                        child: Text(
                      info.name,
                      overflow: TextOverflow.ellipsis,
                    )),
                    GradientButton(
                        onPressed: () async {
                          if (info.isFollowed) {
                            //TODO:取消关注
                          } else {
                            //TODO:关注用户
                          }
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(64),
                        child: !info.isFollowed
                            ? const Text(
                                "关注",
                                style: TextStyle(color: Colors.white),
                              )
                            : const Text("已关注"))
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                      visible: info.getImage != null,
                      child: SizedBox(
                        height: 70,
                        width: 70,
                        child: Thumbnail(
                          controller: ExtendedPageController(),
                          imgs: info.getImage != null ? [info.getImage!] : [],
                          img: info.getImage ?? '',
                          fit: BoxFit.cover,
                        ),
                      )),
                  Expanded(
                      child: Text(
                    info.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                        fontSize:
                            DefaultTextStyle.of(context).style.fontSize! + 1),
                  ))
                ],
              ),
              Visibility(
                  visible: info.bottomVisiable,
                  child: Container(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Text(
                          info.bottomMsg,
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize:
                                  DefaultTextStyle.of(context).style.fontSize! -
                                      2),
                        ),
                        Visibility(
                            visible: info.haveNew,
                            child: const Icon(
                              Icons.brightness_1,
                              color: Colors.red,
                              size: 10,
                            ))
                      ],
                    ),
                  ))
            ]))
          ],
        ),
      ),
    );
  }
}
