import 'dart:math';

import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_notification/pull_to_refresh_notification.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/ExtendedNestedScrollViewEx.dart';
import 'package:tiebanana/Widgets/ForumHeader.dart';
import 'package:tiebanana/Widgets/GlowNotificationWidget.dart';
import 'package:tiebanana/Widgets/ThreadControlBar.dart';
import 'package:tiebanana/Widgets/TopThread.dart';
import 'package:tiebanana/Widgets/PushToRefreshHeader.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/common/Global.dart';

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

  late List<Widget> appBarAction;
  void Function(void Function())? threadState;
  int pn = 1;
  int sortType = 0;
  GoodClassifyProviderModel goodClassify = GoodClassifyProviderModel();
  Future<ForumHomeInfo>? initForum;
  List<ForumThreadList>? forumThreadList; //普通贴
  late ThreadListProviderModel goodThreadList; //精品贴

  Future init() async {
    pn = 1;
    initForum =
        Global.tiebaAPI.getForumPage(kw: widget.kw, pn: pn, sortType: sortType);
    goodThreadList = ThreadListProviderModel();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    //初始化用户设置-分类
    sortType = Global.profile.getInt("ThreadSortType") ?? 0;

    appBarAction = [
      IconButton(
          onPressed: () {
            //TODO:进入吧内搜索界面
          },
          icon: const Icon(Icons.search)),
      IconButton(
          onPressed: () {
            //TODO:更多菜单
          },
          icon: const Icon(Icons.more_vert)),
    ];
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initForum,
      initialData: null,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          forumThreadList ??= (snapshot.data as ForumHomeInfo).threadList;
          return ChangeNotifierProvider.value(
            value: APPBarTitle(),
            child: Scaffold(
              appBar: AppBar(
                elevation: 0.5,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                actions: appBarAction,
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
                    color: const Color(0xFFF2F2F5),
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
                                        info: forumThreadList![index]);
                                  } else {
                                    //不是置顶帖
                                    return ThreadSummary(
                                        info: forumThreadList![index]);
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
                          builder: (context, child) =>
                              ExtendedNestedScrollViewEx(
                            onlyOneScrollInBody: true,
                            initStateCallback: (state) {
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
                                  if (innerController.positions.length == 2) {
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
                            floatHeaderSlivers: false,
                            headerSliverBuilder: (context, innerBoxIsScrolled) {
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
                                        info: (snapshot.data as ForumHomeInfo)
                                            .forum!,
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
                                        goodClassify:
                                            (snapshot.data as ForumHomeInfo)
                                                .forum!
                                                .goodClassify,
                                        kw: widget.kw,
                                        sortType: sortType,
                                        changeSortType: changeSortType,
                                      );
                                    },
                                  ),
                                ),
                              ];
                            },
                            body: TabBarView(
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
                                                cid: goodClassify.goodClassify,
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
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.blue),
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
                                                      info: value
                                                          .threadList![index]);
                                                } else {
                                                  //不是置顶帖
                                                  return ThreadSummary(
                                                      info: value
                                                          .threadList![index]);
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
                          ),
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
}
