import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/SpecialSpan.dart';
import 'package:tiebanana/Widgets/ThreadFirstComment.dart';
import 'package:tiebanana/Widgets/ThreadReplyBar.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/API/TiebaParser.dart';
import 'package:tiebanana/common/Global.dart';

///帖子-楼层组件
class ThreadFloorComment extends StatelessWidget {
  final Forum forum;
  final PostList postMain;
  // final SubPostList? subPostList;
  final UserList author;
  final VideoInfo? videoInfo;
  final List<String> allImgs;
  final List<String> allOrgImgs;
  final Map<String, UserList> userList;
  final String threadID;
  const ThreadFloorComment({
    Key? key,
    required this.author,
    this.videoInfo,
    required this.allImgs,
    required this.allOrgImgs,
    required this.postMain,
    required this.userList,
    required this.threadID,
    required this.forum,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) {
              return ReplyBottomSheet(
                replyText:
                    "${author.nameShow ?? author.name}： ${TiebaParser.parserContentString(postMain.content)}",
                kw: forum.name!,
                fid: forum.id!,
                tid: threadID,
                floorId: postMain.id,
                isReplyThread: false,
              );
            });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        padding: EdgeInsets.only(left: 8, right: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //作者
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 7),
                  child: Avatar(
                    imgUrl: AUTHOR_AVATAR + author.portrait!,
                    height: 35,
                    width: 35,
                  ),
                ),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Row(
                        children: [
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: <Widget>[
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text("${author.nameShow}"),
                                      ),
                                    ] +
                                    (TiebaParser.processIcon(author) ??
                                        <Widget>[]) +
                                    [
                                      Container(
                                        margin: EdgeInsets.only(left: 5),
                                        child: Rank(
                                          rank: author.levelID,
                                        ),
                                      )
                                    ],
                              ),
                              Row(
                                //楼层数
                                children: [
                                  Text(
                                    "${postMain.floor}楼",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  //发帖时间
                                  Text(
                                    TiebaParser.getPostTime(
                                        strTime: postMain.time),
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),

                                  Expanded(
                                      child: Container(
                                    constraints: BoxConstraints(
                                        maxHeight: 1000, maxWidth: 1000),
                                    child: Visibility(
                                        visible: postMain.lbsInfo != null,
                                        child: Text("${postMain.lbsInfo?.name}",
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14))),
                                  ))
                                ],
                              )
                            ],
                          )),
                          AgreeAndDisagreeBar(
                            agreeNum: int.parse(postMain.agree!.agreeNum!),
                            disagreeNum:
                                int.parse(postMain.agree!.disagreeNum!),
                            agreeType: int.parse(postMain.agree!.agreeType!),
                            postID: postMain.id!,
                            threadID: threadID,
                            objType: 1,
                            hasAgree: postMain.agree!.hasAgree!,
                          )
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //正文
                        Container(
                          padding: EdgeInsets.all(5),
                          child: Wrap(
                            children: TiebaParser.parserContent(
                                postMain.content, allImgs, allOrgImgs,
                                selectable: true),
                          ),
                        ),
                        Visibility(
                            visible: postMain.subPostList != null,
                            child: Row(
                              children: [
                                Expanded(
                                    child: Container(
                                  child: InnerFloor(
                                    subPostList: postMain.subPostList ?? [],
                                    userlist: userList,
                                    subPostNumber: postMain.subPostNumber!,
                                    floorNum: postMain.floor!,
                                    kz: threadID,
                                    pid: postMain.id!,
                                    forum: forum,
                                  ),
                                ))
                              ],
                            )),
                        Divider()
                      ],
                    )
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

///楼中楼
class InnerFloor extends StatelessWidget {
  final Map<String, UserList> userlist;
  final List<SubPostList> subPostList;
  final String subPostNumber;
  final String floorNum;
  final String kz;
  final String pid;
  final Forum forum;
  const InnerFloor({
    Key? key,
    required this.subPostList,
    required this.userlist,
    required this.subPostNumber,
    required this.floorNum,
    required this.kz,
    required this.pid,
    required this.forum,
  }) : super(key: key);

  List<Widget> buildSubPost(BuildContext context) {
    List<Widget> subposts = <Widget>[];
    for (var i = 0; i < subPostList.length; i++) {
      var post = subPostList[i];
      if (post.isVoice == "1") {
        print("音频回复");
      }
      subposts.add(InnerPost(
        author: userlist[post.authorId!]!,
        posts: post.content!,
        floorNum: floorNum,
        kz: kz,
        pid: pid,
        spid: subPostList[i].id!,
        forum: forum,
      ));
    }
    if (subPostList.length < int.parse(subPostNumber)) {
      subposts.add(GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => InnerFloorBottomSheet(
              floorNum: floorNum,
              kz: kz,
              pid: pid,
              forum: forum,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(5),
          child: Text(
            "查看剩余${int.parse(subPostNumber) - subPostList.length}条回复",
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
      ));
    }
    return subposts;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Color(0xFFF0F1F2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: buildSubPost(context),
      ),
    );
  }
}

class InnerPost extends StatelessWidget {
  final String floorNum;
  final String kz;
  final String pid;
  final String spid;
  final Author author;
  final List<Content> posts;
  final Forum forum;
  const InnerPost(
      {Key? key,
      required this.author,
      required this.posts,
      required this.floorNum,
      required this.kz,
      required this.pid,
      required this.spid,
      required this.forum})
      : super(key: key);
  List<Widget> buildContent() {
    List<InlineSpan> w = [];
    w.add(AtUserSpan(
      text: "${author.nameShow} :",
      style: TextStyle(color: Colors.blue),
    ));
    for (Content content in posts) {
      //用户
      if ((content.uid != null || content.uid != null) && content.type == "0") {
        w.add(TextSpan(
          text: "${content.text}",
          style: TextStyle(color: Colors.blue),
        ));
      } else if (content.type == "0") {
        w.add(TextSpan(
          text: "${content.text}",
        ));
      } else if (content.type == "2") {
        w.add(EmojiSpan(
          content.text!,
          imageWidth: 18,
          imageHeight: 18,
        ));
      }
    }
    return [
      RichText(
          text: TextSpan(
              children: w, style: TextStyle(color: Colors.black, fontSize: 15)))
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => InnerFloorBottomSheet(
              floorNum: floorNum,
              kz: kz,
              pid: pid,
              spid: spid,
              forum: forum,
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(3),
          child: Row(
            children: [
              Expanded(
                  child: Wrap(
                children: buildContent(),
              )),
            ],
          ),
        ));
  }
}

///展开楼中楼
class InnerFloorBottomSheet extends StatefulWidget {
  final String floorNum;
  final String kz;
  final String pid;
  final String spid;
  final int pn;
  final Forum forum;
  InnerFloorBottomSheet(
      {Key? key,
      required this.floorNum,
      required this.kz,
      required this.pid,
      this.spid = "",
      this.pn = 1,
      required this.forum})
      : super(key: key);

  @override
  State<InnerFloorBottomSheet> createState() => _InnerFloorBottomSheetState();
}

class _InnerFloorBottomSheetState extends State<InnerFloorBottomSheet>
    with SingleTickerProviderStateMixin {
  late InnerFloor post;
  late List<SubpostList> subPosts;
  late Future<InnerFloorModel> dataLoader;
  Map<int, InnerFloorModel> floorPages = {};
  late int pn;
  ScrollController controller = ScrollController();
  late AnimationController animationcontroller;
  @override
  void initState() {
    super.initState();
    pn = widget.pn;
    loadPage(pn);
    animationcontroller = AnimationController(
        vsync: this,
        value: 0,
        upperBound: double.infinity,
        duration: Duration(milliseconds: 100));

    //TODO:连续加载下/上一页
  }

  void loadPage(int pageNum) async {
    //只刷新未加载的页面和头(非第一页)/尾
    if (!floorPages.containsKey(pageNum) ||
        (floorPages.keys.toSet().last == pageNum) ||
        (floorPages.keys.toSet().first == pageNum && pageNum != 1))
      dataLoader = Global.tiebaAPI
          .getInnerFloor(widget.kz, widget.pid, spid: widget.spid, pn: pn)
          .then((value) {
        pn = int.parse(value.page!.currentPage!);
        floorPages[pn] = value;
        return value;
      });
  }

  List<Widget> buildFloor() {
    List<Widget> w = [];
    floorPages.forEach((key, value) {
      if (w.length == 0) {
        w.add(
          Container(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: InnerFloorCard(
                author: value.post!.author!,
                postMain: value.post!,
                threadID: value.thread!.id!,
                isSpid: false,
                forum: widget.forum,
                floorId: value.post!.id!,
              )),
        );
        w.add(Container(
          height: 10,
          color: Color.fromARGB(15, 185, 185, 185),
        ));
        w.add(Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          alignment: Alignment.centerLeft,
          child: Text("${value.subpostList!.length}条回复"),
        ));
      }
      for (SubpostList subpost in value.subpostList ?? []) {
        w.add(
          Container(
              // padding: EdgeInsets.only(left: 10, right: 10),
              child: InnerFloorCard(
            author: subpost.author!,
            postMain: subpost,
            threadID: value.thread!.id!,
            isSpid: subpost.id == widget.spid,
            forum: widget.forum,
            floorId: value.post!.id!,
          )),
        );
        w.add(Divider());
      }
    });
    return w;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationcontroller,
      builder: (BuildContext context, Widget? child) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height -
                80 -
                animationcontroller.value,
          ),
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20.0),
                topRight: const Radius.circular(20.0),
              ),
              color: Colors.white),
          child: child,
        );
      },
      child: Column(
        children: [
          //头部
          Container(
            margin: EdgeInsets.only(bottom: 5),
            padding: EdgeInsets.only(
              left: 20,
              top: 20,
              right: 20,
            ),
            child: Row(
              children: [
                Expanded(
                    child: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.close),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        "${widget.floorNum}楼的回复",
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ))
              ],
            ),
          ),
          Divider(),
          //主体
          Expanded(
            child: FutureBuilder(
              future: dataLoader,
              builder: (BuildContext context,
                  AsyncSnapshot<InnerFloorModel> snapshot) {
                var floors = buildFloor();
                return Column(
                  children: [
                    Expanded(
                        child: Listener(
                      onPointerMove: (event) {
                        if (controller.offset == 0) {
                          if (event.delta.dy < 0 &&
                              animationcontroller.value != 0) {
                            setState(() {
                              controller.jumpTo(0);
                            });
                          }
                          animationcontroller.value += event.delta.dy;
                        }
                      },
                      onPointerUp: (event) {
                        if (animationcontroller.value > 170) {
                          Navigator.pop(context);
                        } else {
                          animationcontroller.reverse();
                        }
                      },
                      child:
                          NotificationListener<OverscrollIndicatorNotification>(
                        onNotification:
                            (OverscrollIndicatorNotification? overscroll) {
                          overscroll!.disallowIndicator();
                          return true;
                        },
                        child: Container(
                          child: ListView.builder(
                            controller: controller,
                            physics: animationcontroller.value > 0
                                ? NeverScrollableScrollPhysics()
                                : ClampingScrollPhysics(),
                            itemCount: floors.length,
                            itemBuilder: (BuildContext context, int index) {
                              return floors[index];
                            },
                          ),
                        ),
                      ),
                    )),
                    //底部回复条
                    Container(child: Builder(
                      builder: (context) {
                        if (snapshot.hasData) {
                          late UserList author;
                          late String threadID;
                          late PostList postMain;
                          for (var v in floorPages.values) {
                            author = v.post!.author!;
                            threadID = v.thread!.id!;
                            postMain = PostList.fromJson(v.post!.toJson());
                          }

                          return InnerFloorReplyBar(
                            author: author,
                            postMain: postMain,
                            threadID: threadID,
                            forum: widget.forum,
                          );
                        } else {
                          return Container();
                        }
                      },
                    ))
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

///楼中楼楼层组件
class InnerFloorCard extends StatelessWidget {
  final UserList author;
  final SubpostList postMain;
  final String threadID;
  final bool isSpid;
  final Forum forum;
  final String floorId;
  const InnerFloorCard(
      {Key? key,
      required this.author,
      required this.postMain,
      required this.threadID,
      required this.isSpid,
      required this.forum,
      required this.floorId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) {
              return ReplyBottomSheet(
                replyText:
                    "${author.nameShow ?? author.name}： ${TiebaParser.parserContentString(postMain.content)}",
                kw: forum.name!,
                fid: forum.id!,
                tid: threadID,
                floorId: floorId,
                isReplyThread: false,
                replyUser: author,
              );
            });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSpid ? Colors.amber.shade100 : Colors.white,
        ),
        padding: EdgeInsets.only(left: 18, right: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //作者
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 7),
                  child: Avatar(
                    imgUrl: AUTHOR_AVATAR + author.portrait!,
                    height: 35,
                    width: 35,
                  ),
                ),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Row(
                        children: [
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: <Widget>[
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text("${author.nameShow}"),
                                      ),
                                    ] +
                                    (TiebaParser.processIcon(author) ??
                                        <Widget>[]) +
                                    [
                                      Container(
                                        margin: EdgeInsets.only(left: 5),
                                        child: Rank(
                                          rank: author.levelID,
                                        ),
                                      )
                                    ],
                              ),
                              Row(
                                //楼层数
                                children: [
                                  //发帖时间
                                  Text(
                                    TiebaParser.getPostTime(
                                        strTime: postMain.time),
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                ],
                              )
                            ],
                          )),
                          AgreeAndDisagreeBar(
                            agreeNum: int.parse(postMain.agree!.agreeNum!),
                            disagreeNum:
                                int.parse(postMain.agree!.disagreeNum!),
                            agreeType: int.parse(postMain.agree!.agreeType!),
                            postID: postMain.id!,
                            threadID: threadID,
                            objType: 2,
                            hasAgree: postMain.agree!.hasAgree!,
                          )
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //正文
                        Container(
                          padding: EdgeInsets.all(5),
                          child: Wrap(
                            children: TiebaParser.parserContent(
                                postMain.content, [], [],
                                selectable: true),
                          ),
                        ),
                      ],
                    )
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
