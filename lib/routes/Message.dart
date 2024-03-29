import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:provider/provider.dart';

import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/CustomUnderlineTabIndicator.dart';
import 'package:tiebanana/Widgets/MessageCard.dart';
import 'package:tiebanana/Widgets/SearchBar.dart';
import 'package:tiebanana/common/DefaultConfig.dart';
import 'package:tiebanana/common/Global.dart';

import '../Json_Model/WidgetModel/MessagePageModel.dart';

///消息页
class MessagePan extends StatefulWidget {
  final FloatingSearchBarController controller;
  const MessagePan({Key? key, required this.controller}) : super(key: key);

  @override
  _MessagePanState createState() => _MessagePanState();
}

class _MessagePanState extends State<MessagePan>
    with SingleTickerProviderStateMixin {
  List tabs = ["回复", "@我"];
  late TabController _controller;
  List<ReplyMe> replyMessage = [];
  List<AtMe> atMeMessage = [];
  int replypn = 1, atMepn = 1;
  Future<ReplyMessage>? _initReply;
  Future<AtMeMessage>? _initAtMe;
  ScrollController controllerReply = ScrollController();
  ScrollController controllerAtme = ScrollController();
  bool hasNextReply = false;
  bool hasNextAtMe = false;
  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: tabs.length,
      vsync: this,
    );
    _initReply = Global.tiebaAPI.getReply(1);
    _initAtMe = Global.tiebaAPI.getAtMe(1);

    //添加加载下一页的监听
    controllerReply.addListener(() {
      if (controllerReply.offset >
              controllerReply.position.maxScrollExtent -
                  controllerReply.position.viewportDimension &&
          hasNextReply) {
        Throttle.seconds(1, nextReply);
      } else if (controllerReply.offset >
          controllerReply.position.maxScrollExtent + 40) {
        Throttle.seconds(5, nextReply);
      }
    });
    controllerAtme.addListener(() {
      if (controllerAtme.offset >
              controllerAtme.position.maxScrollExtent -
                  controllerAtme.position.viewportDimension &&
          hasNextAtMe) {
        Throttle.seconds(1, nextAtMe);
      } else if (controllerAtme.offset >
          controllerAtme.position.maxScrollExtent + 40) {
        Throttle.seconds(5, nextAtMe);
      }
    });
  }

  Widget _tabBar(double maxHeight, double realHeight) {
    var indicatorColor = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).primaryColor
        : Theme.of(context).colorScheme.onBackground;
    return Container(
      height: 56,
      // color: Colors.white,
      // color: Theme.of(context).colorScheme.onPrimaryContainer,
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : null,
      child: TabBar(
          controller: _controller,
          labelStyle: TextStyle(
            fontSize: Provider.of<APPSettingProvider>(context).fontSize - 2,
            fontWeight: FontWeight.bold,
          ),
          // labelColor: Theme.of(context).primaryColor,
          // unselectedLabelColor: Colors.black26,
          indicator: CustomUnderlineTabIndicator(
              wantWidth: 36,
              insets: const EdgeInsets.only(
                left: 15,
                right: 15,
              ),
              borderSide: BorderSide(
                width: 4,
                color: indicatorColor
                    .withAlpha((255 * (realHeight / maxHeight)).toInt()),
              )),
          tabs: tabs
              .map((e) => Tab(
                    text: e,
                  ))
              .toList()),
    );
  }

  Future refresh() async {
    if (_controller.index == 0) {
      replypn = 1;
      var message = await Global.tiebaAPI.getReply(replypn);
      replyMessage = message.reply!;
      hasNextReply = message.page!.hasMore == "1" ? true : false;
      setState(() {});
    } else if (_controller.index == 1) {
      atMepn = 1;
      var message = await Global.tiebaAPI.getAtMe(atMepn);
      atMeMessage = message.atMe!;
      hasNextAtMe = message.messagePage!.hasMore == "1" ? true : false;
      setState(() {});
    }
  }

  Future nextReply() async {
    if (hasNextReply == true) {
      hasNextReply = false;
      var message = await Global.tiebaAPI.getReply(++replypn);
      replyMessage.addAll(message.reply!);
      hasNextReply = message.page!.hasMore == "1" ? true : false;
      setState(() {});
    } else {
      Fluttertoast.showToast(msg: "没有更多了");
    }
  }

  Future nextAtMe() async {
    if (hasNextAtMe == true) {
      hasNextAtMe = false;
      var message = await Global.tiebaAPI.getAtMe(++atMepn);
      atMeMessage.addAll(message.atMe!);
      hasNextAtMe = message.messagePage!.hasMore == "1" ? true : false;
      setState(() {});
    } else {
      Fluttertoast.showToast(msg: "没有更多了");
    }
  }

  Widget buildReply() {
    return KeepAliveWrapper(
        child: FutureBuilder(
      future: _initReply,
      initialData: null,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return const Center(
              child: Text("初始化中..."),
            );
          case ConnectionState.active:
            return const Center(
              child: Text("加载中..."),
            );
          default:
            if (snapshot.hasData) {
              if (replyMessage.isEmpty) {
                replyMessage = ((snapshot.data as ReplyMessage).reply ?? []);
                hasNextReply =
                    (snapshot.data as ReplyMessage).page!.hasMore == "1"
                        ? true
                        : false;
              }
              return RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView.builder(
                      padding: EdgeInsets.zero,
                      controller: controllerReply,
                      itemCount: replyMessage.length,
                      // physics: const BouncingScrollPhysics(),
                      itemBuilder: (itemBuilder, index) {
                        return MessageCard(
                            message: MessagePageModel.fromReplyMe(
                                replyMessage[index]));
                      }));
            } else if (snapshot.hasError) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _initReply = Global.tiebaAPI.getReply(1);
                  });
                },
                child: const Center(
                  child: Text("发生了错误...点击重试"),
                ),
              );
            }
        }
        return Container();
      },
    ));
  }

  Widget buildAtMe() {
    return KeepAliveWrapper(
        child: FutureBuilder(
      future: _initAtMe,
      initialData: null,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return const Center(
              child: Text("初始化中..."),
            );
          case ConnectionState.active:
            return const Center(
              child: Text("加载中..."),
            );
          default:
            if (snapshot.hasData) {
              if (atMeMessage.isEmpty) {
                atMeMessage = ((snapshot.data as AtMeMessage).atMe ?? []);
                hasNextAtMe =
                    (snapshot.data as AtMeMessage).messagePage!.hasMore == "1"
                        ? true
                        : false;
              }

              return RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView.builder(
                      padding: EdgeInsets.zero,
                      controller: controllerAtme,
                      itemCount: atMeMessage.length,
                      // physics: const BouncingScrollPhysics(),
                      itemBuilder: (itemBuilder, index) {
                        return MessageCard(
                            message:
                                MessagePageModel.fromAtMe(atMeMessage[index]));
                      }));
            } else if (snapshot.hasError) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _initAtMe = Global.tiebaAPI.getAtMe(1);
                  });
                },
                child: const Center(
                  child: Text("发生了错误...点击重试"),
                ),
              );
            }
        }
        return Container();
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints topConstraints) {
        return Column(
          children: [
            SearchBar(
              maxHeight: topConstraints.maxHeight,
              barController: widget.controller,
            ),
            Expanded(
                child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: (() => widget.controller.close()),
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        return Column(
                          children: [
                            LimitedBox(
                              maxHeight: constraints.maxHeight,
                              child: _tabBar(topConstraints.maxHeight,
                                  constraints.maxHeight),
                            ),
                            Expanded(
                                child: NotificationListener<
                                    OverscrollIndicatorNotification>(
                              onNotification: (OverscrollIndicatorNotification?
                                  overscroll) {
                                overscroll!.disallowIndicator();
                                return true;
                              },
                              child: TabBarView(
                                controller: _controller,
                                physics: const ClampingScrollPhysics(),
                                children: [buildReply(), buildAtMe()],
                              ),
                            ))
                          ],
                        );
                      },
                    ))),
          ],
        );
      },
    );
  }
}
