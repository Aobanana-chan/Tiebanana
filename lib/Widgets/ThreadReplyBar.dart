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
      child: Row(
        children: [
          Expanded(child: TextField()),
          LikeButton(
            likeBuilder: (isLiked) {
              if (isLiked) {
                return Icon(Icons.star_border);
              } else {
                return Icon(Icons.star);
              }
            },
          )
        ],
      ),
    );
  }
}
