import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';

import 'CustomUnderlineTabIndicator.dart';

class UserCard extends StatefulWidget {
  //控制器回调
  final TabController? controllerl;
  final MyUserData info;
  const UserCard({Key? key, required this.info, this.controllerl})
      : super(key: key);

  @override
  _UserCardState createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  List<Widget> buildButton(context) {
    List<Widget> body = [];
    List<Map<String, dynamic>> bodyinfo = [
      {
        "text": "关注",
        "num": widget.info.concernNum,
        "onPress": () {
          //TODO:跳转界面
          //Navigator.push(context, route)
        }
      },
      {
        "text": "粉丝",
        "num": widget.info.fansNum,
        "onPress": () {
          //TODO:跳转界面
          //Navigator.push(context, route)
        }
      },
      {
        "text": "关注的吧",
        "num": widget.info.likeForumNum,
        "onPress": () {
          //TODO:跳转界面
          //Navigator.push(context, route)
        }
      },
      {
        "text": "帖子",
        "num": widget.info.postNum,
        "onPress": () {
          //TODO:跳转界面
          //Navigator.push(context, route)
        }
      },
    ];
    if (widget.controllerl == null) {
      //没有控制器则构建按钮
      for (var i in bodyinfo) {
        body.add(Expanded(
            child: MaterialButton(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.all(8),
                onPressed: i["onPress"],
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Center(
                          child: Text(
                            i["text"],
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ))
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              i["num"].toString(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ))));
      }
    } else {
      body.add(TabBar(
          controller: widget.controllerl,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          labelColor: Colors.green,
          unselectedLabelColor: Colors.black26,
          indicator: CustomUnderlineTabIndicator(
              wantWidth: 36,
              insets: const EdgeInsets.only(
                left: 15,
                right: 15,
              ),
              borderSide: const BorderSide(
                width: 4,
                color: Colors.white,
              )),
          tabs: bodyinfo
              .map((e) => Tab(
                    child: Column(children: [Text(e["text"]), Text(e["num"])]),
                  ))
              .toList()));
    }
    return body;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(20),
      color: Colors.green,
      shadowColor: Colors.yellow.shade100,
      child: Column(
        children: [
          Row(
            children: [
              //头像
              Container(
                padding: const EdgeInsets.all(5),
                child: Avatar(
                  imgUrl: widget.info.portraitUrl!,
                  height: 45,
                  width: 45,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //用户名
                  Row(
                    children: [
                      Text(
                        widget.info.name!,
                        style: const TextStyle(color: Colors.white),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        widget.info.intro!,
                        style: const TextStyle(color: Colors.white),
                      )
                    ],
                  ),
                ],
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right_outlined,
                color: Colors.white,
              )
            ],
          ),
          Container(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Row(
              children: buildButton(context),
            ),
          )
        ],
      ),
    );
  }
}
