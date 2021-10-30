import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';

///主页贴吧tag部件

class ForumTag extends StatelessWidget {
  LikeForumInfo info;
  ForumTag({Key? key, required this.info}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
            child: Row(
              children: [
                Expanded(child: Text(info.forumName!)),
                _Rank(
                  rank: int.parse(info.levelId!),
                  isSigned: info.isSign == "0" ? false : true,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Rank extends StatelessWidget {
  int rank;
  bool isSigned;
  _Rank({Key? key, required this.rank, required this.isSigned})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
