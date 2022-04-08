import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/routes/routes.dart';

///主页贴合集
class TagPan extends StatefulWidget {
  const TagPan({Key? key}) : super(key: key);

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
                physics: const BouncingScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: LimitedBox(
                      maxHeight: constraints.maxHeight,
                      child: Container(
                        padding: const EdgeInsets.only(left: 10),
                        child: const IntrinsicHeight(
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
                        return ForumTag(
                          info: forumState.forums[index],
                        );
                      }, childCount: forumState.forums.length),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
  const ForumTag({Key? key, required this.info}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
    );
  }
}

///搜索页面吧Tag部件
class ForumCardRelated extends StatelessWidget {
  final SearchForumModelForum searchForumModelForum;
  const ForumCardRelated({Key? key, required this.searchForumModelForum})
      : super(key: key);
  String convertNumber(int number) {
    if (number ~/ 10000000 > 0) {
      return "${(number / 10000000).toStringAsFixed(1)}KW";
    } else if (number ~/ 10000 > 0) {
      return "${(number / 10000).toStringAsFixed(1)}W";
    } else if (number ~/ 1000 > 0) {
      return "${(number / 1000).toStringAsFixed(1)}K";
    } else {
      return number.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, PageRouter.forumHome,
            arguments: searchForumModelForum.name);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              child: Avatar(
                imgUrl: searchForumModelForum.img!,
                width: 48,
                height: 48,
              ),
            ),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${searchForumModelForum.name}吧",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
                Visibility(
                    visible: searchForumModelForum.brief != null,
                    child: Text(
                      "简介:${searchForumModelForum.brief}",
                      style: const TextStyle(color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                    )),
                Row(
                  children: [
                    Text(
                      "关注 ${convertNumber(searchForumModelForum.member!)}",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      "贴子 ${convertNumber(searchForumModelForum.post!)}",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black),
                    )
                  ],
                ),
              ],
            )),
            GradientButton(
                onPressed: () {},
                borderRadius: BorderRadius.circular(64),
                child: searchForumModelForum.isLike!
                    ? const Text("已关注")
                    : const Text("关注"))
          ],
        ),
      ),
    );
  }
}

///搜索页面吧Card部件
class ForumCard extends StatelessWidget {
  final SearchForumModelForum forum;
  const ForumCard({Key? key, required this.forum}) : super(key: key);

  String convertNumber(int number) {
    if (number ~/ 10000000 > 0) {
      return "${(number / 10000000).toStringAsFixed(1)}KW";
    } else if (number ~/ 10000 > 0) {
      return "${(number / 10000).toStringAsFixed(1)}W";
    } else if (number ~/ 1000 > 0) {
      return "${(number / 1000).toStringAsFixed(1)}K";
    } else {
      return number.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, PageRouter.forumHome,
            arguments: forum.name);
      },
      child: Card(
          margin: const EdgeInsets.all(5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: Colors.black87,
          shadowColor: Colors.yellow.shade100,
          child: Container(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  child: Avatar(
                    imgUrl: forum.img!,
                    width: 48,
                    height: 48,
                  ),
                ),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${forum.name}吧",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Visibility(
                        visible: forum.brief != null,
                        child: Text(
                          "简介:${forum.brief}",
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        )),
                    Row(
                      children: [
                        Text(
                          "关注 ${convertNumber(forum.member!)}",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          "贴子 ${convertNumber(forum.post!)}",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                  ],
                )),
                GradientButton(
                    onPressed: () {},
                    borderRadius: BorderRadius.circular(64),
                    child: forum.isLike! ? const Text("已关注") : const Text("关注"))
              ],
            ),
          )),
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
    [const Color(0xFF6F6F6F), const Color(0xFFFFFFFF)],
    [const Color(0xFFFFFFFF), const Color(0xFF6F6F6F)],
    [const Color(0xFF3AFF44), const Color(0xFF553626)],
    [const Color(0xFF281DCF), const Color(0xFFFFE7B8)],
    [const Color(0xFF753771), const Color(0xFFFDE9D6)],
    [const Color(0xFFFF8E31), const Color(0xFF3D3B02)],
  ];
  List<Color> setColor() {
    int r = int.parse(rank);
    return _rankColor[r ~/ 3];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 5, right: 5),
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
                child: const SizedBox(
                  width: 10,
                )),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
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
