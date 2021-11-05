import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/common/Global.dart';

///主页贴合集
class TagPan extends StatefulWidget {
  TagPan({Key? key}) : super(key: key);

  @override
  _TagPanState createState() => _TagPanState();
}

class _TagPanState extends State<TagPan> {
  List<LikeForumInfo> likeForumInfo = [];
  Future<void> getLikes() async {
    likeForumInfo = (await Global.tiebaAPI.userInfomation.likes)!;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getLikes();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Stack(
      children: [
        RefreshIndicator(
            child: GridView(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisExtent: 50,
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5),
              children: likeForumInfo.map((e) {
                return ForumTag(
                  info: e,
                );
              }).toList(),
            ),
            onRefresh: () async {})
      ],
    ));
  }
}

///主页贴吧tag部件
class ForumTag extends StatelessWidget {
  LikeForumInfo info;
  ForumTag({Key? key, required this.info}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: DecoratedBox(
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(width: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: MaterialButton(
          onPressed: () {
            //TODO:进入贴吧路由
          },
          onLongPress: () {
            //TODO:弹出贴吧操作菜单
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                  child: Text(
                info.forumName!,
                overflow: TextOverflow.ellipsis,
              )),
              _Rank(
                rank: info.levelId!,
                isSigned: info.isSign == "0" ? false : true,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _Rank extends StatelessWidget {
  String rank;
  bool isSigned;
  _Rank({Key? key, required this.rank, required this.isSigned})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(rank),
    );
  }
}
