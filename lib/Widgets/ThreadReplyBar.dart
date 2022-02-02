import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';

///帖子-底端回复栏
class ThreadReplyBar extends StatefulWidget {
  ThreadReplyBar({Key? key}) : super(key: key);

  @override
  _ThreadReplyBarState createState() => _ThreadReplyBarState();
}

class _ThreadReplyBarState extends State<ThreadReplyBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0F1F2)))),
      child: Row(
        children: [
          Expanded(
              child: GestureDetector(
            onTap: () {
              //TODO:打开回复框
              showBottomSheet(
                context: context,
                builder: (context) => ReplyBottomSheet(),
              );
            },
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.grey.shade200,
                  border: Border.all(
                    width: 0.1,
                  )),
              padding: EdgeInsets.only(left: 10),
              margin: EdgeInsets.only(right: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "我也来评论",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              // constraints: BoxConstraints(maxHeight: 128),
              // child:
              // TextField(
              //   strutStyle: StrutStyle(),
              //   decoration: InputDecoration(
              //     hintText: "我也来评论",
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(32),
              //       gapPadding: 0,
              //       borderSide: BorderSide(width: 0.5),
              //     ),
              //     filled: true,
              //     fillColor: Colors.grey.shade200,
              //     isCollapsed: true,
              //     contentPadding:
              //         EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              //   ),
              //   keyboardType: TextInputType.multiline,
              //   maxLines: null,
              // ),
            ),
          )),
          LikeButton(
            likeBuilder: (isLiked) {
              if (!isLiked) {
                return Icon(Icons.star_border);
              } else {
                return Icon(
                  Icons.star,
                  color: Colors.yellow,
                );
              }
            },
          ),
          //TODO:帖子分享
          LikeButton(
            likeBuilder: (isLiked) {
              return Icon(Icons.share);
            },
          )
        ],
      ),
    );
  }
}

class ReplyBottomSheet extends StatefulWidget {
  final String? replyText;
  ReplyBottomSheet({Key? key, this.replyText}) : super(key: key);

  @override
  State<ReplyBottomSheet> createState() => _ReplyBottomSheetState();
}

class _ReplyBottomSheetState extends State<ReplyBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          //回复评论
          Row(),
          //回复输入
          Row(),
          //媒体输入按钮
          Row()
        ],
      ),
    );
  }
}
