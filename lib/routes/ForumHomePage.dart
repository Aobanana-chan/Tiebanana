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
  ForumHomePage({Key? key, required this.kw}) : super(key: key);

  @override
  _ForumHomePageState createState() => _ForumHomePageState();
}

class _ForumHomePageState extends State<ForumHomePage>
    with SingleTickerProviderStateMixin {
  // ScrollController controller = ScrollController();
  late ScrollController innerController;
  late ScrollController outerController;
  late TabController tabbarController;
  List _tab = ["看帖", "精品"];

  late List<Widget> appBarAction;
  void Function(void Function())? threadState;
  int pn = 1;
  Future<ForumHomeInfo>? initForum;
  List<ForumThreadList>? forumThreadList; //普通贴
  late ThreadListProviderModel goodThreadList; //精品贴

  Future init() async {
    pn = 1;
    initForum = Global.tiebaAPI.getForumPage(kw: widget.kw, pn: pn);

    goodThreadList = ThreadListProviderModel();

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    appBarAction = [
      IconButton(
          onPressed: () {
            //TODO:进入吧内搜索界面
          },
          icon: Icon(Icons.search)),
      IconButton(
          onPressed: () {
            //TODO:更多菜单
          },
          icon: Icon(Icons.more_vert)),
    ];
    init();
    //下一页
    // controller.addListener(() {
    //   if (threadState != null) {
    //     if (controller.offset >
    //         controller.position.maxScrollExtent -
    //             controller.position.viewportDimension) {
    //       Throttle.seconds(5, nextPage);
    //       threadState?.call(() {});
    //     } else if (controller.offset >
    //         controller.position.maxScrollExtent + 40) {
    //       Throttle.seconds(5, nextPage);
    //       threadState?.call(() {});
    //     }
    //   }
    // });
    // SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
    //   var controller = _nestedKey.currentState?.innerController;
    //   innercontroller = controller!;
    //   _nestedKey.currentState?.innerController.addListener(() {
    //     if (threadState != null) {
    //       if (controller.offset >
    //           controller.position.maxScrollExtent -
    //               controller.position.viewportDimension) {
    //         Throttle.seconds(5, nextPage);
    //         threadState?.call(() {});
    //       } else if (controller.offset >
    //           controller.position.maxScrollExtent + 40) {
    //         Throttle.seconds(5, nextPage);
    //         threadState?.call(() {});
    //       }
    //     }
    //   });
    // });
    tabbarController = TabController(length: _tab.length, vsync: this);
  }

  void nextPage() async {
    pn++;
    forumThreadList?.addAll(
        (await Global.tiebaAPI.getForumPage(kw: widget.kw, pn: pn))
                .threadList ??
            []);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initForum,
      initialData: null,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          if (forumThreadList == null) {
            forumThreadList = (snapshot.data as ForumHomeInfo).threadList;
          }
          return ChangeNotifierProvider.value(
            value: APPBarTitle(),
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                actions: appBarAction,
                title: Consumer<APPBarTitle>(
                  builder: (context, value, child) {
                    return AnimatedOpacity(
                      alwaysIncludeSemantics: true,
                      opacity: value.getTitle == "" ? 0 : 1,
                      duration: Duration(milliseconds: 200),
                      child: GestureDetector(
                          onTap: () {
                            // innerController.animateTo(0,
                            //     duration: Duration(milliseconds: 200),
                            //     curve: Curves.easeIn);
                            outerController.animateTo(0,
                                duration: Duration(milliseconds: 200),
                                curve: Curves.easeIn);
                          },
                          child: Text("${widget.kw}吧",
                              overflow: TextOverflow.ellipsis)),
                    );
                  },
                ),
              ),
              floatingActionButton: ClipOval(
                child: Container(
                  color: Colors.blue,
                  child: IconButton(
                    onPressed: () {
                      //TODO:发帖
                    },
                    icon: Icon(Icons.edit),
                    color: Colors.white,
                  ),
                ),
              ),
              body: StatefulBuilder(
                builder: (BuildContext context, setState) {
                  threadState = setState;
                  return Container(
                    color: Color(0xFFF2F2F5),
                    child: ExtendedNestedScrollViewEx(
                      onlyOneScrollInBody: true,
                      initStateCallback: (state) {
                        innerController = state.innerController;
                        outerController = state.outerController;
                        state.innerController.addListener(() {
                          if (threadState != null) {
                            if (innerController.offset >
                                innerController.position.maxScrollExtent -
                                    innerController
                                        .position.viewportDimension) {
                              Throttle.seconds(5, nextPage);
                              threadState?.call(() {});
                            } else if (innerController.offset >
                                innerController.position.maxScrollExtent + 40) {
                              Throttle.seconds(5, nextPage);
                              threadState?.call(() {});
                            }
                          }
                        });
                      },
                      // pinnedHeaderSliverHeightBuilder: () {
                      //   var controller =
                      //       _nestedKey.currentState?.innerController;

                      //       .addListener(() {
                      //     if (threadState != null) {
                      //       if (controller.offset >
                      //           controller.position.maxScrollExtent -
                      //               controller.position.viewportDimension) {
                      //         Throttle.seconds(5, nextPage);
                      //         threadState?.call(() {});
                      //       } else if (controller.offset >
                      //           controller.position.maxScrollExtent + 40) {
                      //         Throttle.seconds(5, nextPage);
                      //         threadState?.call(() {});
                      //       }
                      //     }
                      //   });
                      //   return 0;
                      // },
                      floatHeaderSlivers: false,
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return <Widget>[
                          SliverFlexibleHeader(
                            visibleExtent: 64,
                            builder: (BuildContext context, double maxExtent,
                                ScrollDirection direction) {
                              if (maxExtent == 0) {
                                //使用回调安全更新
                                SchedulerBinding.instance!
                                    .addPostFrameCallback((timeStamp) {
                                  Provider.of<APPBarTitle>(context,
                                          listen: false)
                                      .title = widget.kw + "吧";
                                });
                              } else {
                                SchedulerBinding.instance!
                                    .addPostFrameCallback((timeStamp) {
                                  Provider.of<APPBarTitle>(context,
                                          listen: false)
                                      .title = "";
                                });
                              }
                              return ForumHeader(
                                info: (snapshot.data as ForumHomeInfo).forum!,
                              );
                            },
                          ),
                          SliverToBoxAdapter(
                            child: ThreadControlBar(
                              controller: tabbarController,
                              tabs: _tab,
                              goodClassify: (snapshot.data as ForumHomeInfo)
                                  .forum!
                                  .goodClassify,
                              kw: widget.kw,
                            ),
                          ),

                          // SliverList(
                          //     delegate:
                          //         SliverChildBuilderDelegate((builder, index) {
                          //   //置顶帖
                          //   if (forumThreadList![index].isTop == "1") {
                          //     return TopThread(info: forumThreadList![index]);
                          //   } else {
                          //     //不是置顶帖
                          //     return ThreadSummary(
                          //         info: forumThreadList![index]);
                          //   }
                          // }, childCount: forumThreadList?.length ?? 0))
                        ];
                      },
                      body: TabBarView(
                        physics: BouncingScrollPhysics(),
                        controller: tabbarController,
                        children: [
                          KeepAliveWrapper(
                              child: PullToRefreshNotification(
                            onRefresh: () async {
                              pn = 1;
                              forumThreadList = (await Global.tiebaAPI
                                      .getForumPage(kw: widget.kw, pn: pn))
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
                                  return Container(
                                    height: offset,
                                    width: width,
                                    child: Center(
                                      child: RefreshProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.blue),
                                        strokeWidth: 2.0,
                                      ),
                                    ),
                                  );
                                }),
                                Expanded(
                                    child: CustomScrollView(
                                  physics: BouncingScrollPhysics(),
                                  slivers: <Widget>[
                                    SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                            (builder, index) {
                                      //置顶帖
                                      if (forumThreadList![index].isTop ==
                                          "1") {
                                        return TopThread(
                                            info: forumThreadList![index]);
                                      } else {
                                        //不是置顶帖
                                        return ThreadSummary(
                                            info: forumThreadList![index]);
                                      }
                                    },
                                            childCount:
                                                forumThreadList?.length ?? 0))
                                  ],
                                ))
                              ],
                            )),
                          )),
                          // KeepAliveWrapper(
                          //   child: ListView.builder(
                          //     physics: BouncingScrollPhysics(),
                          //     shrinkWrap: true,
                          //     itemCount: forumThreadList?.length ?? 0,
                          //     itemBuilder: (BuildContext context, int index) {
                          //       if (forumThreadList![index].isTop == "1") {
                          //         return TopThread(
                          //             info: forumThreadList![index]);
                          //       } else {
                          //         //不是置顶帖
                          //         return ThreadSummary(
                          //             info: forumThreadList![index]);
                          //       }
                          //     },
                          //   ),
                          // ),
                          KeepAliveWrapper(
                            child: ChangeNotifierProvider.value(
                              value: goodThreadList,
                              builder: (context, child) {
                                return Consumer<ThreadListProviderModel>(
                                  builder: (context, value, child) {
                                    return ListView.builder(
                                      itemCount: value.threadList?.length ?? 0,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        if (value.threadList![index].isTop ==
                                            "1") {
                                          return TopThread(
                                              info: value.threadList![index]);
                                        } else {
                                          //不是置顶帖
                                          return ThreadSummary(
                                              info: value.threadList![index]);
                                        }
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          )
                        ],
                      ),
                    ),

                    // Column(
                    //   children: [

                    //   ],
                    // ),
                  );
                },
              ),
            ),
          );
        }
        return Container(
          color: Colors.white,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
