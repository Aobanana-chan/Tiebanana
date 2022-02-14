import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/ExtendedNestedScrollViewEx.dart';
import 'package:tiebanana/Widgets/ThreadFirstComment.dart';
import 'package:tiebanana/Widgets/ThreadFloorCard.dart';
import 'package:tiebanana/Widgets/ThreadReplyBar.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/routes.dart';

///贴页面

class ThreadPageRoute extends StatefulWidget {
  final String kz;
  ThreadPageRoute({Key? key, required this.kz}) : super(key: key);

  @override
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPageRoute> {
  Future<ThreadPageData>? initThread;
  void init() async {
    initThread = Global.tiebaAPI.getThreadPage(widget.kz);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: FutureBuilder(
        future: initThread,
        initialData: null,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              body: ThreadPageMain(kz: widget.kz, initInfo: snapshot.data),
            );
          } else if (snapshot.hasError) {
            //TODO:以后添加收藏贴缓存
            Fluttertoast.showToast(msg: snapshot.error.toString());
            Navigator.pop(context);
          }
          return Container(
            color: Colors.white,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}

class ThreadPageMain extends StatefulWidget {
  final String kz;
  final ThreadPageData initInfo;
  ThreadPageMain({Key? key, required this.kz, required this.initInfo})
      : super(key: key);

  @override
  _ThreadPageMainState createState() => _ThreadPageMainState();
}

class _ThreadPageMainState extends State<ThreadPageMain> {
  late List<Widget> appBarAction;
  ScrollController _controller = ScrollController();

  bool lz = false; //只看楼主
  late List<PostList> postList;
  Map<String, UserList> userListSet = {};
  String title = "";
  List<String> imgs = []; // 贴中所有图片列表
  List<String> imgsOrgSrc = []; // 贴中所有高清图片列表
  VideoInfo? videoInfo;
  double scrollOffset = 0;

  late int topPn;
  late int bottomPn;
  late bool hasMore;
  late bool hasPrev;
  @override
  void initState() {
    super.initState();
    appBarAction = [
      StatefulBuilder(
        builder: (BuildContext context, setState) {
          return IconButton(
              padding: EdgeInsets.all(6),
              onPressed: () {
                //TODO:只看楼主
                setState(() {
                  lz = !lz;
                });
              },
              icon: Container(
                padding: EdgeInsets.all(1),
                decoration: BoxDecoration(
                  border: Border.all(
                      width: 2, color: lz ? Colors.blue : Colors.black),
                  borderRadius: BorderRadius.circular(5),
                  color: lz ? Colors.blue : Colors.white,
                ),
                child: Text(
                  "楼主",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: lz ? Colors.white : Colors.black),
                ),
              ));
        },
      ),
      IconButton(
          onPressed: () {
            //TODO:更多菜单
          },
          icon: Icon(Icons.more_vert)),
    ];
    postList = widget.initInfo.postList ?? [];
    title = widget.initInfo.thread!.title!;
    videoInfo = widget.initInfo.thread?.videoInfo;
    //处理用户列表映射关系
    for (UserList user in widget.initInfo.userList ?? []) {
      userListSet[user.id!] = user;
    }

    collectImages();

    //设置标题
    _controller.addListener(() {
      if ((scrollOffset > 36 && _controller.offset <= 36) ||
          (scrollOffset < 36 && _controller.offset >= 36)) {
        setState(() {
          scrollOffset = _controller.offset;
        });
      } else {
        scrollOffset = _controller.offset;
      }
    });

    //设置页码
    topPn = int.parse(widget.initInfo.page!.currentPage!);
    bottomPn = topPn;
    hasMore = widget.initInfo.page?.hasMore == "1";
    hasPrev = widget.initInfo.page?.hasPrev == "1";

    //快滑到页面底部加载下一页
    _controller.addListener(() {
      if (_controller.positions.toList()[0].pixels >
          _controller.positions.toList()[0].maxScrollExtent -
              _controller.positions.toList()[0].viewportDimension) {
        Throttle.seconds(5, nextPage);
      }
    });

    //快滑到页面顶部加载前一页
    _controller.addListener(() {
      if (_controller.positions.toList()[0].pixels <
          _controller.positions.toList()[0].viewportDimension) {
        Throttle.seconds(5, prevPage);
      }
    });
  }

  //TODO:页面加载完成后清除Throttle,以便快速滑动
  //下一页
  void nextPage() async {
    if (hasMore) {
      bottomPn++;
      var l = await Global.tiebaAPI
          .getThreadPage(widget.kz, pn: bottomPn, onlyLz: lz);
      postList.addAll(l.postList!);
      hasMore = l.page?.hasMore == "1";
      //添加新的user列表
      for (UserList user in l.userList ?? []) {
        userListSet[user.id!] = user;
      }
      setState(() {
        collectImages();
      });
    }
  }

  //上一页
  void prevPage() async {
    if (hasPrev) {
      topPn++;
      var l =
          await Global.tiebaAPI.getThreadPage(widget.kz, pn: topPn, onlyLz: lz);
      postList.addAll(l.postList!);
      hasPrev = l.page?.hasPrev == "1";
      //添加新的user列表
      for (UserList user in l.userList ?? []) {
        userListSet[user.id!] = user;
      }
      setState(() {
        collectImages();
      });
    }
  }

  void collectImages() {
    //整理图片
    for (PostList post in postList) {
      for (Content content in post.content ?? []) {
        if ((content.type == "4" && content.originSrc != null) ||
            content.type == "3") {
          //type4可能是富文本
          imgs.add(content.text ?? content.bigCdnSrc ?? content.originSrc!);
          imgsOrgSrc.add(content.originSrc!);
        }
      }
    }
  }

  List<Widget> buildFloor() {
    List<Widget> w = [];
    for (var floor in postList) {
      if (floor.floor != "1") {
        w.add(ThreadFloorComment(
          allImgs: imgs,
          allOrgImgs: imgsOrgSrc,
          author: userListSet[floor.authorId!]!,
          postMain: floor,
          userList: userListSet,
          threadID: widget.initInfo.thread!.id!,
        ));
      }
    }
    return w;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFF2F2F5),
      child: Column(
        children: [
          Expanded(
              child: CustomScrollView(
            physics: BouncingScrollPhysics(),
            controller: _controller,
            slivers: <Widget>[
              SliverAppBar(
                //issue：#32563，expandedHeight要大于collapsedHeight，不然可能会无法滑动
                // expandedHeight: .00001,
                elevation: 0.5,
                pinned: true,
                snap: true,
                floating: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                actions: appBarAction,
                title: AnimatedOpacity(
                  alwaysIncludeSemantics: true,
                  opacity: scrollOffset < 36 ? 0 : 1,
                  duration: Duration(milliseconds: 200),
                  child: GestureDetector(
                      onTap: () {
                        _controller.animateTo(0,
                            duration: Duration(milliseconds: 200),
                            curve: Curves.easeIn);
                      },
                      child: Text(
                        widget.initInfo.thread!.title!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 17),
                      )),
                ),
              ),
              SliverToBoxAdapter(
                child: Visibility(
                    visible: postList[0].floor! == "1",
                    child: ThreadFirstComment(
                      postMain: postList[0],
                      author: userListSet[postList[0].authorId!]!,
                      videoInfo: videoInfo,
                      allImgs: imgs,
                      allOrgImgs: imgsOrgSrc,
                      threadID: widget.initInfo.thread!.id!,
                      thread: widget.initInfo.thread!,
                    )),
              ),
              SliverToBoxAdapter(
                child: FourmBar(
                  avatar: widget.initInfo.forum!.avatar!,
                  name: widget.initInfo.forum!.name!,
                ),
              ),
              SliverList(delegate: SliverChildListDelegate(buildFloor()))
            ],
          )),
          //回贴条
          ThreadReplyBar()
        ],
      ),
      // ExtendedNestedScrollViewEx(
      //   initStateCallback: (p0) {
      //     innerController = p0.innerController;
      //     outerController = p0.outerController;
      //   },
      //   floatHeaderSlivers: true,
      //   headerSliverBuilder: (context, innerBoxIsScrolled) {
      //     return <Widget>[
      //       SliverOverlapAbsorber(
      //         handle: ExtendedNestedScrollViewEx.sliverOverlapAbsorberHandleFor(
      //             context),
      //         sliver: ,
      //       ),
      //     ];
      //   },
      //   body: Builder(
      //     builder: (context) => CustomScrollView(
      //       shrinkWrap: true,
      //       physics: BouncingScrollPhysics(),
      //       slivers: <Widget>[
      //         SliverOverlapInjector(
      //             handle:
      //                 ExtendedNestedScrollViewEx.sliverOverlapAbsorberHandleFor(
      //                     context)),
      //         SliverToBoxAdapter(
      //           child: Visibility(
      //               visible: postList[0].floor! == "1",
      //               child: ThreadFirstComment(
      //                 postMain: postList[0],
      //                 author: userListSet[postList[0].authorId!]!,
      //                 videoInfo: videoInfo,
      //                 allImgs: imgs,
      //                 allOrgImgs: imgsOrgSrc,
      //               )),
      //         ),
      //         SliverToBoxAdapter(
      //           child: FourmBar(
      //             avatar: widget.initInfo.forum!.avatar!,
      //             name: widget.initInfo.forum!.name!,
      //           ),
      //         ),
      //         SliverList(delegate: SliverChildListDelegate(buildFloor()))
      //       ],
      //     ),
      //   ),
      // ),
    );
  }
}

class FourmBar extends StatelessWidget {
  final String name;
  final String avatar;
  const FourmBar({Key? key, required this.name, required this.avatar})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 5, bottom: 5),
      color: Colors.white,
      child: MaterialButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.pushNamed(context, PageRouter.forumHome, arguments: name);
        },
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.all(5),
              height: 40,
              width: 40,
              child: ClipOval(
                child: ExtendedImage.network(avatar),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 5),
              child: Text(
                "$name吧",
                style: TextStyle(fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }
}
