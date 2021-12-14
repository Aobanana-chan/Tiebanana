import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/CustomUnderlineTabIndicator.dart';
import 'package:tiebanana/Widgets/MessageCard.dart';
import 'package:tiebanana/Widgets/searchBar.dart';
import 'package:tiebanana/common/Global.dart';

///消息页
class MessagePan extends StatefulWidget {
  MessagePan({Key? key}) : super(key: key);

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
  Widget _tabBar(double maxHeight, double realHeight) {
    return Container(
      height: 56,
      color: Colors.white,
      child: TabBar(
          controller: _controller,
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          labelColor: Colors.green,
          unselectedLabelColor: Colors.black26,
          indicator: CustomUnderlineTabIndicator(
              wantWidth: 36,
              insets: EdgeInsets.only(
                left: 15,
                right: 15,
              ),
              borderSide: BorderSide(
                width: 4,
                color: Colors.green
                    .withAlpha((255 * (realHeight / maxHeight)).toInt()),
              )),
          tabs: tabs
              .map((e) => Tab(
                    text: e,
                  ))
              .toList()),
    );
  }

  Future nextReply() async {
    if (hasNextReply == true) {
      var message = await Global.tiebaAPI.getReply(++replypn);
      replyMessage.addAll(message.reply!);
      hasNextReply = message.page!.hasMore == "1" ? true : false;
      setState(() {});
    } else
      Fluttertoast.showToast(msg: "没有更多了");
  }

  Future nextAtMe() async {
    if (hasNextAtMe == true) {
      var message = await Global.tiebaAPI.getAtMe(++atMepn);
      atMeMessage.addAll(message.atMe!);
      hasNextAtMe = message.messagePage!.hasMore == "1" ? true : false;
      setState(() {});
    } else
      Fluttertoast.showToast(msg: "没有更多了");
  }

  Widget buildReply() {
    return FutureBuilder(
      future: _initReply,
      initialData: null,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return Container(
              child: Center(
                child: Text("初始化中..."),
              ),
            );
          case ConnectionState.active:
            return Container(
              child: Center(
                child: Text("加载中..."),
              ),
            );
          default:
            if (snapshot.hasData) {
              if (replyMessage.length == 0) {
                replyMessage = ((snapshot.data as ReplyMessage).reply!);
                hasNextReply =
                    (snapshot.data as ReplyMessage).page!.hasMore == "1"
                        ? true
                        : false;
              }
              return ListView.builder(
                  controller: controllerReply,
                  itemCount: replyMessage.length,
                  physics: BouncingScrollPhysics(),
                  itemBuilder: (itemBuilder, index) {
                    return MessageCard(replyMe: replyMessage[index]);
                  });
            } else if (snapshot.hasError) {
              return GestureDetector(
                onTap: () {
                  setState(() {});
                },
                child: Container(
                  child: Center(
                    child: Text("发生了错误...点击重试"),
                  ),
                ),
              );
            }
        }
        return Container();
      },
    );
  }

  Widget buildAtMe() {
    return FutureBuilder(
      future: _initAtMe,
      initialData: null,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return Container(
              child: Center(
                child: Text("初始化中..."),
              ),
            );
          case ConnectionState.active:
            return Container(
              child: Center(
                child: Text("加载中..."),
              ),
            );
          default:
            if (snapshot.hasData) {
              if (atMeMessage.length == 0) {
                atMeMessage = ((snapshot.data as AtMeMessage).atMe!);
                hasNextAtMe =
                    (snapshot.data as AtMeMessage).messagePage!.hasMore == "1"
                        ? true
                        : false;
              }
              return ListView.builder(
                  controller: controllerAtme,
                  itemCount: replyMessage.length,
                  physics: BouncingScrollPhysics(),
                  itemBuilder: (itemBuilder, index) {
                    return MessageCard(atME: atMeMessage[index]);
                  });
            } else if (snapshot.hasError) {
              return GestureDetector(
                onTap: () {
                  setState(() {});
                },
                child: Container(
                  child: Center(
                    child: Text("发生了错误...点击重试"),
                  ),
                ),
              );
            }
        }
        return Container();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: tabs.length,
      vsync: this,
    );
    _initReply = Global.tiebaAPI.getReply(1);
    _initAtMe = Global.tiebaAPI.getAtMe(1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints topConstraints) {
        return Container(
          child: Column(
            children: [
              SearchBar(
                maxHeight: topConstraints.maxHeight,
              ),
              Expanded(child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Column(
                    children: [
                      LimitedBox(
                        maxHeight: constraints.maxHeight,
                        child: _tabBar(
                            topConstraints.maxHeight, constraints.maxHeight),
                      ),
                      Expanded(
                          child: TabBarView(
                        controller: _controller,
                        physics: BouncingScrollPhysics(),
                        children: [buildReply(), buildAtMe()],
                      ))
                    ],
                  );
                },
              )),
            ],
          ),
        );
      },
    );
  }
}