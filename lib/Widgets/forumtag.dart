import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/routes.dart';

///主页贴合集
class TagPan extends StatefulWidget {
  TagPan({Key? key}) : super(key: key);

  @override
  _TagPanState createState() => _TagPanState();
}

class _TagPanState extends State<TagPan> {
  List<LikeForumInfo> likeForumInfo = [];
  Future<void> getLikes() async {
    Provider.of<ForumState>(context, listen: false).refresh();
    // likeForumInfo = (await Global.tiebaAPI.userInfomation.likes)!;
    // setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // getLikes();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return RefreshIndicator(
            triggerMode: RefreshIndicatorTriggerMode.anywhere,
            onRefresh: () async {
              getLikes();
            },
            child: Consumer<ForumState>(builder: (builder, forumState, _) {
              return CustomScrollView(
                physics: BouncingScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: LimitedBox(
                      maxHeight: constraints.maxHeight,
                      child: Container(
                        padding: EdgeInsets.only(left: 10),
                        child: IntrinsicHeight(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "我关注的吧",
                              style: TextStyle(
                                  color: Color(0xFF6F6F6F), fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverGrid(
                      delegate: SliverChildBuilderDelegate((builder, index) {
                        return Container(
                          child: ForumTag(
                            info: forumState.forums[index],
                          ),
                        );
                      }, childCount: forumState.forums.length),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          mainAxisExtent: 50,
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          mainAxisSpacing: 5,
                          crossAxisSpacing: 5))
                ],
              );
            }));
      },
    );
  }
}

///主页贴吧tag部件
class ForumTag extends StatelessWidget {
  final LikeForumInfo info;
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
            Navigator.pushNamed(context, PageRouter.forumHome,
                arguments: info.forumName);
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
  final String rank;
  final bool isSigned;
  _Rank({Key? key, required this.rank, required this.isSigned})
      : super(key: key);
  //[字体,背景色]
  final List<List<Color>> _rankColor = [
    [Color(0xFF6F6F6F), Color(0xFFFFFFFF)],
    [Color(0xFFFFFFFF), Color(0xFF6F6F6F)],
    [Color(0xFF3AFF44), Color(0xFF553626)],
    [Color(0xFF281DCF), Color(0xFFFFE7B8)],
    [Color(0xFF753771), Color(0xFFFDE9D6)],
    [Color(0xFFFF8E31), Color(0xFF3D3B02)],
  ];
  List<Color> setColor() {
    int r = int.parse(rank);
    return _rankColor[r ~/ 3];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 5, right: 5),
      decoration: BoxDecoration(
          color: setColor()[1], borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        // borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Text(
              rank,
              style: TextStyle(color: setColor()[0]),
            ),
            Visibility(
                visible: isSigned,
                child: SizedBox(
                  width: 10,
                )),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: Visibility(
                visible: isSigned,
                child: Icon(
                  Icons.check_circle,
                  key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
                  color: Colors.green,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
