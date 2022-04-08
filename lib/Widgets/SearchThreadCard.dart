import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/common/API/TiebaParser.dart';
import 'package:tiebanana/routes/routes.dart';

///搜索贴Widget
class SearchThreadCard extends StatelessWidget {
  final SearchPostModelPostList post;
  const SearchThreadCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        //主题帖
        if (post.type == 1) {
          Navigator.pushNamed(context, PageRouter.threadPage,
              arguments: post.tid);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          //作者
          Container(
            padding: const EdgeInsets.all(0),
            child: Row(
              children: [
                Avatar(
                  imgUrl: post.user?.portrait ?? post.user!.portraith!,
                  height: 36,
                  width: 36,
                ),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: <Widget>[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              "${post.user?.showNickname ?? post.user?.userName}"),
                        ),
                      ],
                    ),
                  ],
                ))
              ],
            ),
          ),
          //标题
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              post.title!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          //主要内容
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              post.mainPost?.content ?? post.content ?? "",
              style: const TextStyle(fontSize: 17),
            ),
          ),
          //底部
          LeftRightBox(
            left: Text("${post.forumName}吧"),
            right: Text(post.time == null
                ? ""
                : TiebaParser.getPostTime(strTime: post.time)),
          )
        ]),
      ),
    );
  }
}
