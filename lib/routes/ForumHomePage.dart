import 'dart:math';

import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_notification/pull_to_refresh_notification.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/ForumHeader.dart';
import 'package:tiebanana/Widgets/GlowNotificationWidget.dart';
import 'package:tiebanana/Widgets/ThreadControlBar.dart';
import 'package:tiebanana/Widgets/TopThread.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/Widgets/common/ExtendedNestedScrollViewWrapper.dart';
import 'package:tiebanana/common/Global.dart';

import '../Json_Model/WidgetModel/PostContentModel.dart';
import '../Json_Model/WidgetModel/ThreadCommentModel.dart';
import '../Json_Model/WidgetModel/ThreadControlBarModel.dart';

///吧页面
class ForumHomePage extends StatefulWidget {
  ///吧名
  final String kw;
  const ForumHomePage({Key? key, required this.kw}) : super(key: key);

  @override
  _ForumHomePageState createState() => _ForumHomePageState();
}

class _ForumHomePageState extends State<ForumHomePage>
    with SingleTickerProviderStateMixin {
  // ScrollController controller = ScrollController();
  late ScrollController innerController;
  late ScrollController outerController;
  late TabController tabbarController;
  final List _tab = ["看帖", "精品"];

  void Function(void Function())? threadState;
  int pn = 1;
  int sortType = 0;
  GoodClassifyProviderModel goodClassify = GoodClassifyProviderModel();
  Future<ForumHomeInfo>? initForum;
  late ForumHomeInfo forumData;
  List<ForumThreadList>? forumThreadList; //普通贴
  late ThreadListProviderModel goodThreadList; //精品贴

  late RenderBox overlay;

  final maxDragOffset = 80.0;

  void init() {
    pn = 1;
    initForum =
        Global.tiebaAPI.getForumPage(kw: widget.kw, pn: pn, sortType: sortType);
    goodThreadList = ThreadListProviderModel();
    // setState(() {});
  }

  @override
  void initState() {
    super.initState();
    //初始化用户设置-分类
    sortType = Global.profile.getInt("ThreadSortType") ?? 0;

    overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    init();
    //进入精品贴后加载精品贴页面
    tabbarController = TabController(length: _tab.length, vsync: this);
    tabbarController.addListener(initGoodThread);
    tabbarController.addListener(() {
      if (tabbarController.index == 1) {
        goodClassify.show = true;
      } else {
        goodClassify.show = false;
      }
    });
  }

  void initGoodThread() async {
    if (goodThreadList.threadList == null && tabbarController.index == 1) {
      goodThreadList.setList = (await Global.tiebaAPI.getForumPage(
        kw: widget.kw,
        pn: 1,
        isgood: true,
      ))
          .threadList;
      tabbarController.removeListener(initGoodThread);
    }
  }

  void nextPage() async {
    pn++;
    forumThreadList?.addAll(
        (await Global.tiebaAPI.getForumPage(kw: widget.kw, pn: pn))
                .threadList ??
            []);
  }

  void changeSortType(int type) async {
    Global.profile.setInt("ThreadSortType", type);
    sortType = type;
    if (threadState != null) {
      if (tabbarController.index == 0) {
        //刷新普通帖
        pn = 1;
        forumThreadList = (await Global.tiebaAPI
                .getForumPage(kw: widget.kw, pn: pn, sortType: sortType))
            .threadList;
        //进入精品贴后也重新刷新
        late void Function() refreshGood;
        refreshGood = () async {
          if (tabbarController.index == 1) {
            goodThreadList.goodpn = 1;
            goodThreadList.setList = (await Global.tiebaAPI.getForumPage(
                    kw: widget.kw,
                    pn: goodThreadList.goodpn,
                    cid: goodClassify.goodClassify,
                    sortType: sortType,
                    isgood: true))
                .threadList;
            tabbarController.removeListener(refreshGood);
          }
        };
        tabbarController.addListener(refreshGood);
        threadState?.call(() {});
      } else if (tabbarController.index == 1) {
        //刷新精品贴
        goodThreadList.goodpn = 1;
        goodThreadList.setList = (await Global.tiebaAPI.getForumPage(
                kw: widget.kw,
                pn: goodThreadList.goodpn,
                cid: goodClassify.goodClassify,
                sortType: sortType,
                isgood: true))
            .threadList;
        //进入普通贴后也重新刷新
        late void Function() refreshCommon;
        refreshCommon = () async {
          if (tabbarController.index == 0) {
            pn = 1;
            forumThreadList = (await Global.tiebaAPI
                    .getForumPage(kw: widget.kw, pn: pn, sortType: sortType))
                .threadList;
            tabbarController.removeListener(refreshCommon);
            threadState?.call(() {});
          }
        };
        tabbarController.addListener(refreshCommon);
      }
    }
  }

  List<Widget> buildAction() {
    return [
      IconButton(
          onPressed: () {
            //TODO:进入吧内搜索界面
          },
          icon: const Icon(Icons.search)),
      IconButton(
          onPressed: () {
            showMenu(
                context: context,
                position: RelativeRect.fromLTRB(overlay.size.width - 100, 0,
                    overlay.size.width, overlay.size.height),
                shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                items: [
                  PopupMenuItem(
                    // padding: EdgeInsets.zero,
                    onTap: () async {
                      if (forumData.forum?.isLike == "1") {
                        Global.tiebaAPI.unfavoForum(
                            fid: forumData.forum!.id!,
                            forumName: forumData.forum!.name!);
                      } else {
                        Global.tiebaAPI.favoForum(
                            forumData.forum!.id!, forumData.forum!.name!);
                      }
                    },
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: forumData.forum?.isLike == "1"
                          ? const Text("取消关注")
                          : const Text("关注"),
                    ),
                  ),
                  PopupMenuItem(
                    // padding: EdgeInsets.zero,
                    onTap: () async {
                      //TODO:分享贴吧
                    },
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("分享"),
                    ),
                  ),
                ]);
          },
          icon: const Icon(Icons.more_vert)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initForum,
      initialData: null,
      builder: (BuildContext context, AsyncSnapshot<ForumHomeInfo?> snapshot) {
        if (snapshot.hasData) {
          forumData = snapshot.data!;
          forumThreadList ??= (snapshot.data as ForumHomeInfo).threadList;
          return ChangeNotifierProvider.value(
            value: APPBarTitle(),
            child: Scaffold(
              appBar: AppBar(
                elevation: 0.5,
                // backgroundColor: Colors.white,
                // foregroundColor: Colors.black,
                actions: buildAction(),
                title: Consumer<APPBarTitle>(
                  builder: (context, value, child) {
                    return AnimatedOpacity(
                      alwaysIncludeSemantics: true,
                      opacity: value.getTitle == "" ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: GestureDetector(
                          onTap: () {
                            outerController.animateTo(0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeIn);
                          },
                          child: Text("${widget.kw}吧",
                              overflow: TextOverflow.ellipsis)),
                    );
                  },
                ),
              ),
              floatingActionButton: ClipOval(
                child: FloatingActionButton(
                  // color: Colors.blue,
                  onPressed: () {
                    //TODO:发帖
                  },
                  child: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              body: StatefulBuilder(
                builder: (BuildContext context, setState) {
                  threadState = setState;
                  return Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: ChangeNotifierProvider.value(
                      value: goodClassify,
                      child: KeepAliveWrapper(
                          child: PullToRefreshNotification(
                        onRefresh: () async {
                          pn = 1;
                          forumThreadList = (await Global.tiebaAPI.getForumPage(
                                  kw: widget.kw, pn: pn, sortType: sortType))
                              .threadList;
                          setState.call(() {});
                          return true;
                        },
                        maxDragOffset: maxDragOffset,
                        child: GlowNotificationWidget(Column(
                          children: [
                            PullToRefreshContainer((info) {
                              final double offset = info?.dragOffset ?? 0.0;
                              double width = min(48, offset);
                              return SizedBox(
                                height: offset,
                                width: width,
                                child: const Center(
                                  child: RefreshProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue),
                                    strokeWidth: 2.0,
                                  ),
                                ),
                              );
                            }),
                            Expanded(
                                child: CustomScrollView(
                              // physics: const BouncingScrollPhysics(),
                              slivers: <Widget>[
                                SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                        (builder, index) {
                                  //置顶帖
                                  if (forumThreadList![index].isTop == "1") {
                                    return TopThread(
                                      tid: forumThreadList![index].tid!,
                                      title: forumThreadList![index].title!,
                                    );
                                  } else {
                                    //不是置顶帖
                                    return ThreadSummary(
                                      firstPostContent: () {
                                        var result =
                                            <PostContentBaseWidgetModel>[];
                                        for (Content element
                                            in forumThreadList![index]
                                                    .firstPostContent ??
                                                []) {
                                          result
                                              .add(createContentModel(element));
                                        }
                                        return result;
                                      }(),
                                      author: AuthorWidgetModel(
                                        icons: () {
                                          var icon = <String>[];
                                          for (Iconinfo element
                                              in forumThreadList![index]
                                                      .author!
                                                      .iconinfo ??
                                                  []) {
                                            icon.add(element.icon!);
                                          }
                                          return icon;
                                        }(),
                                        nameShow: forumThreadList![index]
                                            .author!
                                            .nameShow,
                                        username: forumThreadList![index]
                                            .author!
                                            .name,
                                        uid:
                                            forumThreadList![index].author!.id!,
                                        portrait: forumThreadList![index]
                                            .author!
                                            .portrait!,
                                        levelID: "",
                                      ),
                                      createTime:
                                          forumThreadList![index].createTime!,
                                      latestTime:
                                          forumThreadList![index].lastTimeInt!,
                                      tid: forumThreadList![index].id!,
                                      fname:
                                          forumThreadList![index].fname ?? "",
                                      viewNum: forumThreadList![index].viewNum!,
                                      title: forumThreadList![index].title!,
                                      agreeNum: forumThreadList![index]
                                          .agree!
                                          .agreeNum!,
                                      disagreeNum: forumThreadList![index]
                                          .agree!
                                          .disagreeNum!,
                                      replyNum:
                                          forumThreadList![index].replyNum!,
                                    );
                                  }
                                }, childCount: forumThreadList?.length ?? 0))
                              ],
                            ))
                          ],
                        )),
                      )),
                      builder: (context, commonThreadScrollView) {
                        return ChangeNotifierProvider.value(
                          value: goodThreadList,
                          builder: (context, child) => ExtendedNestedScrollView(
                              onlyOneScrollInBody: true,
                              floatHeaderSlivers: false,
                              headerSliverBuilder:
                                  (context, innerBoxIsScrolled) {
                                return <Widget>[
                                  SliverFlexibleHeader(
                                    visibleExtent: 64,
                                    builder: (BuildContext context,
                                        double maxExtent,
                                        ScrollDirection direction) {
                                      if (maxExtent == 0) {
                                        //使用回调安全更新
                                        SchedulerBinding.instance
                                            .addPostFrameCallback((timeStamp) {
                                          Provider.of<APPBarTitle>(context,
                                                  listen: false)
                                              .title = "${widget.kw}吧";
                                        });
                                      } else {
                                        SchedulerBinding.instance
                                            .addPostFrameCallback((timeStamp) {
                                          Provider.of<APPBarTitle>(context,
                                                  listen: false)
                                              .title = "";
                                        });
                                      }
                                      return Opacity(
                                        opacity: maxExtent / 64,
                                        child: ForumHeader(
                                          avatar: snapshot
                                                  .data!.forum!.avatar ??
                                              snapshot.data!.forum!.fShareImg!,
                                          fName: snapshot.data!.forum!.name!,
                                          levelupScore: snapshot
                                              .data!.forum!.levelupScore!,
                                          curScore:
                                              snapshot.data!.forum!.curScore!,
                                          isLike:
                                              snapshot.data!.forum!.isLike !=
                                                  "0",
                                          isSigned: snapshot
                                                  .data!
                                                  .forum!
                                                  .signInInfo
                                                  ?.userInfo
                                                  ?.isSignIn !=
                                              "0",
                                          fid: snapshot.data!.forum!.id!,
                                          levelId:
                                              snapshot.data!.forum!.levelId!,
                                          levelName:
                                              snapshot.data!.forum!.levelName!,
                                        ),
                                      );
                                    },
                                  ),
                                  SliverToBoxAdapter(
                                    child: Consumer<GoodClassifyProviderModel>(
                                      builder: (context, value, child) {
                                        return ThreadControlBar(
                                          classSelect: value.goodClassify,
                                          showClass: value.shouldShow,
                                          controller: tabbarController,
                                          tabs: _tab,
                                          goodClassify: () {
                                            var cls = <GoodPostClassify>[];
                                            for (GoodClassify goodClassify
                                                in snapshot.data!.forum!
                                                        .goodClassify ??
                                                    []) {
                                              cls.add(GoodPostClassify
                                                  .fromGoodClassify(
                                                      goodClassify));
                                            }
                                            return cls;
                                          }(),
                                          kw: widget.kw,
                                          sortType: sortType,
                                          changeSortType: changeSortType,
                                        );
                                      },
                                    ),
                                  ),
                                ];
                              },
                              body: ExtendedNestedScrollViewInject(
                                initCallback: (state) {
                                  innerController = state.innerController;
                                  outerController = state.outerController;
                                  state.innerController.addListener(() {
                                    if (threadState != null) {
                                      //普通帖监听
                                      if (innerController.positions
                                              .toList()[0]
                                              .pixels >
                                          innerController.positions
                                                  .toList()[0]
                                                  .maxScrollExtent -
                                              innerController.positions
                                                  .toList()[0]
                                                  .viewportDimension) {
                                        Throttle.seconds(5, nextPage);
                                        threadState?.call(() {});
                                      } else if (innerController.positions
                                              .toList()[0]
                                              .pixels >
                                          innerController.positions
                                                  .toList()[0]
                                                  .maxScrollExtent +
                                              40) {
                                        Throttle.seconds(5, nextPage);
                                        threadState?.call(() {});
                                      }
                                      //精品贴监听
                                      if (innerController.positions.length ==
                                          2) {
                                        if (innerController.positions
                                                .toList()[1]
                                                .pixels >
                                            innerController.positions
                                                    .toList()[1]
                                                    .maxScrollExtent -
                                                innerController.positions
                                                    .toList()[1]
                                                    .viewportDimension) {
                                          Throttle.seconds(5, nextPage);
                                          threadState?.call(() {});
                                        } else if (innerController.positions
                                                .toList()[1]
                                                .pixels >
                                            innerController.positions
                                                    .toList()[1]
                                                    .maxScrollExtent +
                                                40) {
                                          Throttle.seconds(5, nextPage);
                                          threadState?.call(() {});
                                        }
                                      }
                                    }
                                  });
                                },
                                child: TabBarView(
                                  // physics: const BouncingScrollPhysics(),
                                  controller: tabbarController,
                                  children: [
                                    //普通帖列表
                                    commonThreadScrollView!,
                                    //精品贴列表
                                    KeepAliveWrapper(
                                        child: PullToRefreshNotification(
                                      onRefresh: () async {
                                        goodThreadList.goodpn = 1;
                                        goodThreadList.setList =
                                            (await Global.tiebaAPI.getForumPage(
                                                    kw: widget.kw,
                                                    pn: goodThreadList.goodpn,
                                                    cid: goodClassify
                                                        .goodClassify,
                                                    sortType: sortType,
                                                    isgood: true))
                                                .threadList;

                                        return true;
                                      },
                                      maxDragOffset: maxDragOffset,
                                      child: GlowNotificationWidget(Column(
                                        children: [
                                          PullToRefreshContainer((info) {
                                            final double offset =
                                                info?.dragOffset ?? 0.0;
                                            double width = min(48, offset);
                                            return SizedBox(
                                              height: offset,
                                              width: width,
                                              child: const Center(
                                                child: RefreshProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.blue),
                                                  strokeWidth: 2.0,
                                                ),
                                              ),
                                            );
                                          }),
                                          Expanded(child:
                                              Consumer<ThreadListProviderModel>(
                                            builder: (context, value, child) {
                                              return CustomScrollView(
                                                // physics:
                                                //     const BouncingScrollPhysics(),
                                                slivers: <Widget>[
                                                  SliverList(
                                                      delegate:
                                                          SliverChildBuilderDelegate(
                                                              (builder, index) {
                                                    //置顶帖
                                                    if (value.threadList![index]
                                                            .isTop ==
                                                        "1") {
                                                      return TopThread(
                                                        tid: value
                                                            .threadList![index]
                                                            .tid!,
                                                        title: value
                                                            .threadList![index]
                                                            .title!,
                                                      );
                                                    } else {
                                                      //不是置顶帖
                                                      return ThreadSummary(
                                                        firstPostContent: () {
                                                          var result = <
                                                              PostContentBaseWidgetModel>[];
                                                          for (Content element
                                                              in forumThreadList![
                                                                      index]
                                                                  .firstPostContent!) {
                                                            result.add(
                                                                createContentModel(
                                                                    element));
                                                          }
                                                          return result;
                                                        }(),
                                                        author:
                                                            AuthorWidgetModel(
                                                          icons: () {
                                                            var icon =
                                                                <String>[];
                                                            for (var element
                                                                in value
                                                                    .threadList![
                                                                        index]
                                                                    .author!
                                                                    .iconinfo!) {
                                                              icon.add(element
                                                                  .icon!);
                                                            }
                                                            return icon;
                                                          }(),
                                                          nameShow: value
                                                              .threadList![
                                                                  index]
                                                              .author!
                                                              .nameShow,
                                                          username: value
                                                              .threadList![
                                                                  index]
                                                              .author!
                                                              .name,
                                                          uid: value
                                                              .threadList![
                                                                  index]
                                                              .author!
                                                              .id!,
                                                          portrait: value
                                                              .threadList![
                                                                  index]
                                                              .author!
                                                              .portrait!,
                                                          levelID: "",
                                                        ),
                                                        createTime: value
                                                            .threadList![index]
                                                            .createTime!,
                                                        latestTime: value
                                                            .threadList![index]
                                                            .lastTimeInt!,
                                                        tid: value
                                                            .threadList![index]
                                                            .id!,
                                                        fname: value
                                                                .threadList![
                                                                    index]
                                                                .fname ??
                                                            "",
                                                        viewNum: value
                                                            .threadList![index]
                                                            .viewNum!,
                                                        title: value
                                                            .threadList![index]
                                                            .title!,
                                                        agreeNum: value
                                                            .threadList![index]
                                                            .agree!
                                                            .agreeNum!,
                                                        disagreeNum: value
                                                            .threadList![index]
                                                            .agree!
                                                            .disagreeNum!,
                                                        replyNum: value
                                                            .threadList![index]
                                                            .replyNum!,
                                                      );
                                                    }
                                                  },
                                                              childCount: value
                                                                      .threadList
                                                                      ?.length ??
                                                                  0))
                                                ],
                                              );
                                            },
                                          ))
                                        ],
                                      )),
                                    )),
                                  ],
                                ),
                              )),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          );
        }
        return Container(
          color: Colors.white,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // innerController.dispose();
    // outerController.dispose();
    tabbarController.dispose();
    super.dispose();
  }
}
