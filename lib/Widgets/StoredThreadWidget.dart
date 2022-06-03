import 'package:extended_image/extended_image.dart';
import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/PageModel/ThreadStorePageModel.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/common/API/TiebaParser.dart';

///收藏贴小部件
class StoredThreadWidget extends StatefulWidget {
  final StoredThread info;
  final bool deleteMode;
  const StoredThreadWidget(
      {Key? key, required this.info, required this.deleteMode})
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
        //TODO:进贴
      },
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.only(top: 3, bottom: 3),
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                Avatar(
                  imgUrl: info.portrait,
                  width: 35,
                  height: 35,
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
                    fontSize: DefaultTextStyle.of(context).style.fontSize! + 1),
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
                              DefaultTextStyle.of(context).style.fontSize! - 2),
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
        ]),
      ),
    );
  }
}
