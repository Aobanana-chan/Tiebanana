import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_throttle_it/just_throttle_it.dart';

import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/ThreadFirstComment.dart';
import 'package:tiebanana/Widgets/ThreadReplyBar.dart';
import 'package:tiebanana/Widgets/common/AlterDialog.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/routes.dart';

import '../Json_Model/WidgetModel/PostContentModel.dart';
import '../Json_Model/WidgetModel/ThreadCommentModel.dart';
import '../Widgets/ThreadFloorCard.dart';
import '../Json_Model/WidgetModel/ThreadPageModel.dart';

///贴页面

class ThreadPageRoute extends StatefulWidget {
  final String kz;
  final String? pid;
  const ThreadPageRoute({Key? key, required this.kz, this.pid})
      : super(key: key);

  @override
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPageRoute> {
  Future<ThreadPageData>? initThread;
  void init() async {
    initThread = Global.tiebaAPI.getThreadPage(widget.kz, pid: widget.pid);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initThread,
      initialData: null,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          ThreadPageData data = snapshot.data;

          var list = <ThreadPagePost>[];
          for (var i in data.postList!) {
            var t = ThreadPagePost.fromPostList(i);

            list.add(t);
          }
          //记录历史记录
          Global.daoapi.storeViewHistory(
              data.thread!.id!, data.thread!.title!, data.forum!.name!);

          return Scaffold(
            body: ThreadPageMain(
              kz: widget.kz,
              hasMore: data.page!.hasMore == "1`",
              hasPrev: data.page!.hasPrev == "1",
              pid: null,
              pn: int.parse(data.page!.currentPage!),
              title: data.thread!.title!,
              userList: data.userList,
              videoInfo: data.thread?.videoInfo,
              avatar: data.forum!.avatar!,
              fid: data.forum!.id!,
              forumName: data.forum!.name!,
              tid: data.thread!.id!,
              forum: ForumData.fromForm(data.forum!),
              thread: ThreadData.fromThread(data.thread!),
              initPost: list,
              isStored: data.thread!.collectStatus != "0",
            ),
          );
        } else if (snapshot.hasError) {
          //TODO:以后添加收藏贴缓存
          Fluttertoast.showToast(msg: snapshot.error.toString());
          Navigator.pop(context);
        }
        return const Scaffold(
          // color: Colors.white,
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

class ThreadPageMain extends StatefulWidget {
  final String kz;

  final bool hasMore;
  final bool hasPrev;
  final String title;
  // final ThreadPageData initInfo;
  final VideoInfo? videoInfo;
  final List<UserList>? userList;
  final int? pn;
  final String? pid;
  final String avatar; //吧头像
  final String fid;
  final String forumName;
  final String tid;
  final ThreadData thread;
  final List<ThreadPagePost> initPost;
  final ForumData forum;
  final bool isStored;
  const ThreadPageMain(
      {Key? key,
      required this.kz,
      required this.hasMore,
      required this.hasPrev,
      required this.title,
      required this.videoInfo,
      required this.userList,
      required this.pn,
      required this.pid,
      required this.avatar,
      required this.fid,
      required this.forumName,
      required this.tid,
      required this.forum,
      required this.thread,
      required this.initPost,
      required this.isStored})
      : super(key: key);

  @override
  ThreadPageMainState createState() => ThreadPageMainState();
}

class ThreadPageMainState extends State<ThreadPageMain> {
  late ThreadPageModel info;
  ThreadPageModel? prevState;

  late List<Widget> appBarAction;
  final ScrollController _controller = ScrollController();

  bool lz = false; //只看楼主

  double scrollOffset = 0;

  ///目前滑到的pid
  String pid = "";

  bool isStored = false;

  @override
  void initState() {
    super.initState();
    appBarAction = [
      StatefulBuilder(
        builder: (BuildContext context, setState) {
          var colors = ColorScheme.fromSeed(
              seedColor: Theme.of(context).primaryColor,
              brightness: Theme.of(context).brightness);
          return IconButton(
              padding: const EdgeInsets.all(6),
              onPressed: () {
                //TODO:只看楼主
                setState(() {
                  lz = !lz;
                });
                onlyLz();
              },
              icon: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  border: Border.all(width: 2, color: colors.primary),
                  borderRadius: BorderRadius.circular(5),
                  color: !lz ? colors.onPrimary : colors.primary,
                ),
                child: Text(
                  "楼主",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: !lz ? colors.primary : colors.onPrimary),
                ),
              ));
        },
      ),
      IconButton(
          onPressed: () {
            //TODO:更多菜单
          },
          icon: const Icon(Icons.more_vert)),
    ];

    info = ThreadPageModel(
      title: widget.title,
      videoInfo: widget.videoInfo == null
          ? null
          : VedioInfoWidgetModel.fromVideoInfo(widget.videoInfo!),
      hasMore: widget.hasMore,
      hasPrev: widget.hasPrev,
      initPid: widget.pid,
      bottomPn: widget.pn,
      topPn: widget.pn,
      avatar: widget.avatar,
      fid: widget.fid,
      forumName: widget.forumName,
      tid: widget.tid,
      isStored: widget.isStored,
    );
    info.postPage[widget.pn!] = widget.initPost;
    // postList = widget.initInfo.postList ?? [];
    // title = widget.initInfo.thread!.title!;
    // videoInfo = widget.initInfo.thread?.videoInfo;
    //处理用户列表映射关系
    for (UserList user in widget.userList ?? []) {
      info.userListSet[user.id!] = AuthorWidgetModel.fromData(user);
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

    // //设置页码
    // topPn = int.parse(widget.initInfo.page!.currentPage!);
    // bottomPn = topPn;

    // hasMore = widget.initInfo.page?.hasMore == "1";
    // hasPrev = widget.initInfo.page?.hasPrev == "1";

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

    isStored = widget.isStored;
  }

  //TODO:页面加载完成后清除Throttle,以便快速滑动
  //下一页
  void nextPage() async {
    if (info.hasMore) {
      info.bottomPn = info.bottomPn! + 1;
      var l = await Global.tiebaAPI
          .getThreadPage(widget.kz, pn: info.bottomPn!, onlyLz: lz);

      var list = <ThreadPagePost>[];
      for (var i in l.postList!) {
        var t = ThreadPagePost.fromPostList(i);

        list.add(t);
      }
      info.postPage[info.bottomPn! * (lz ? -1 : 1)] = list;

      // postList.addAll(l.postList!);
      info.hasMore = l.page?.hasMore == "1";
      // hasMore = l.page?.hasMore == "1";
      //添加新的user列表
      for (UserList user in l.userList ?? []) {
        info.userListSet[user.id!] = AuthorWidgetModel.fromData(user);
      }
      setState(() {
        collectImages();
      });
    }
  }

  //上一页
  void prevPage() async {
    if (info.hasPrev) {
      info.topPn = info.topPn! - 1;
      var l = await Global.tiebaAPI
          .getThreadPage(widget.kz, pn: info.topPn!, onlyLz: lz);

      var list = <ThreadPagePost>[];
      for (var i in l.postList!) {
        var t = ThreadPagePost.fromPostList(i);

        list.add(t);
      }
      info.postPage[info.topPn! * (lz ? -1 : 1)] = list;
      // postList.addAll(l.postList!);
      info.hasPrev = l.page?.hasPrev == "1";
      // hasPrev = l.page?.hasPrev == "1";
      //添加新的user列表
      for (UserList user in l.userList ?? []) {
        info.userListSet[user.id!] = AuthorWidgetModel.fromData(user);
      }
      setState(() {
        collectImages();
      });
    }
  }

  ///只看楼主
  void onlyLz() {
    if (prevState != null) {
      var t = prevState;
      prevState = info;
      info = t!;
      setState(() {});
    } else {
      prevState = info;
      refresh();
    }
  }

  void refresh() async {
    info.topPn = 1;
    info.bottomPn = 1;
    info.hasMore = true;
    //TODO:改为合并
    info.postPage.clear();
    var l = await Global.tiebaAPI
        .getThreadPage(widget.kz, pn: info.topPn!, onlyLz: lz);

    var list = <ThreadPagePost>[];
    for (var i in l.postList!) {
      var t = ThreadPagePost.fromPostList(i);

      list.add(t);
    }
    info.postPage[info.topPn! * (lz ? -1 : 1)] = list;
    // postList.addAll(l.postList!);
    info.hasPrev = l.page?.hasPrev == "1";
    // hasPrev = l.page?.hasPrev == "1";
    //添加新的user列表
    for (UserList user in l.userList ?? []) {
      info.userListSet[user.id!] = AuthorWidgetModel.fromData(user);
    }
    setState(() {
      collectImages();
    });
  }

  void collectImages() {
    //整理图片
    for (ThreadPagePost post in info.postList) {
      // for (PostContentBaseWidgetModel content in post.content) {
      //   if ((content.type == "4" && content.originSrc != null) ||
      //       content.type == "3") {
      //     //type4可能是富文本
      //     info.imgs
      //         .add(content.text ?? content.bigCdnSrc ?? content.originSrc!);
      //     info.imgsOrgSrc.add(content.originSrc!);
      //   }
      // }
      for (PostContentBaseWidgetModel content in post.content) {
        if (content.type == "3") {
          info.imgs.add((content as ImageContentWidgetModel).bigCdnSrc ??
              content.originSrc!);
          info.imgsOrgSrc.add(content.originSrc!);
        }
      }
    }
  }

  List<Widget> buildFloor() {
    List<Widget> w = [];
    for (var floor in lz ? info.lzPostList : info.postList) {
      if (floor.floor != "1") {
        w.add(ThreadFloorComment(
          allImgs: info.imgs,
          allOrgImgs: info.imgsOrgSrc,
          author: info.userListSet[floor.uid]!,
          postMain: floor,
          userList: () {
            var result = <String, AuthorWidgetModel>{};
            for (var k in info.userListSet.keys) {
              result[k] = info.userListSet[k]!;
            }
            return result;
          }(),
          threadID: info.tid,
          forum: widget.forum,
        ));
      }
    }
    return w;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (isStored) {
            bool? q = await showDialog(
                context: context,
                builder: (builder) =>
                    const TiebaAlterDialog(title: "本次阅读到这里，是否更新收藏楼层?"));
            if (q == null) {
              return false;
            } else if (q == true) {
              Global.tiebaAPI.threadAddStore(widget.tid, pid);
            }
          }

          return true;
        },
        child: Column(
          children: [
            Expanded(
                child: CustomScrollView(
              controller: _controller,
              slivers: <Widget>[
                SliverAppBar(
                  //issue：#32563，expandedHeight要大于collapsedHeight，不然可能会无法滑动
                  // expandedHeight: .00001,
                  elevation: 0.5,
                  pinned: true,
                  snap: true,
                  floating: true,
                  actions: appBarAction,
                  title: AnimatedOpacity(
                    alwaysIncludeSemantics: true,
                    opacity: scrollOffset < 36 ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                        onTap: () {
                          _controller.animateTo(0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeIn);
                        },
                        child: Text(
                          info.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 17),
                        )),
                  ),
                ),

                //一楼
                SliverToBoxAdapter(
                  child: Visibility(
                      visible: info.postList[0].floor! == "1",
                      child: ThreadFirstComment(
                        postMain: info.postList[0],
                        author: info.userListSet[info.postList[0].uid]!,
                        videoInfo: info.videoInfo,
                        allImgs: info.imgs,
                        allOrgImgs: info.imgsOrgSrc,
                        threadID: info.tid,
                        thread: widget.thread,
                      )),
                ),
                SliverToBoxAdapter(
                  child: FourmBar(
                    avatar: info.avatar,
                    name: info.forumName,
                  ),
                ),

                //其他楼
                SliverList(delegate: SliverChildListDelegate(buildFloor()))
              ],
            )),
            //回复条
            ThreadReplyBar(
              fid: info.fid,
              tid: info.tid,
              kw: info.forumName,
              replyText: info.title,
              isThreadStored: info.isStored,
            )
          ],
        ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      margin: const EdgeInsets.only(top: 5, bottom: 5),
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Theme.of(context).backgroundColor,
      child: MaterialButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.pushNamed(context, PageRouter.forumHome, arguments: name);
        },
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.all(5),
              height: 40,
              width: 40,
              child: ClipOval(
                child: ExtendedImage.network(avatar),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 5),
              child: Text(
                "$name吧",
                style: const TextStyle(fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }
}
