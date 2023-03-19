// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/ThemeExtension/QuoteTheme.dart';
import 'package:tiebanana/Widgets/SpecialSpan.dart';
import 'package:tiebanana/Widgets/ThreadFirstComment.dart';
import 'package:tiebanana/Widgets/ThreadReplyBar.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/API/TiebaParser.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/ThreadPage.dart';
import 'package:tiebanana/routes/routes.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../Json_Model/WidgetModel/PostContentModel.dart';
import '../Json_Model/json.dart';
import '../common/Util/AppUtil.dart';
import '../Json_Model/WidgetModel/ThreadCommentModel.dart';
import '../Json_Model/WidgetModel/ThreadPageModel.dart';

//TODO:标识楼主，标识吧主
///帖子-楼层组件
class ThreadFloorComment extends StatelessWidget {
  final ForumData forum;
  final ThreadPagePost postMain;
  // final SubPostList? subPostList;
  final AuthorWidgetModel author;
  final VedioInfoWidgetModel? videoInfo;
  final List<String> allImgs;
  final List<String> allOrgImgs;
  final Map<String, AuthorWidgetModel> userList;
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
    if (kDebugMode) {
      print("正在浏览PID:${postMain.id},第${postMain.floor}楼");
    }
    var readingHistoryPid =
        context.findAncestorStateOfType<ThreadPageMainState>();
    readingHistoryPid?.pid = postMain.id;
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
                kw: forum.forumName,
                fid: forum.fid,
                tid: threadID,
                floorId: postMain.id,
                isReplyThread: false,
              );
            });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : null,
        ),
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //作者
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 7),
                  child: Avatar(
                    imgUrl: AUTHOR_AVATAR + author.portrait,
                    height: 35,
                    width: 35,
                    onTap: () {
                      Navigator.pushNamed(context, PageRouter.user,
                          arguments: author.id);
                    },
                  ),
                ),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
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
                                        margin: const EdgeInsets.only(left: 5),
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
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  //发帖时间
                                  Text(
                                    TiebaParser.getPostTime(
                                        strTime: postMain.createTime),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),

                                  Expanded(
                                      child: Container(
                                    constraints: const BoxConstraints(
                                        maxHeight: 1000, maxWidth: 1000),
                                    child: Visibility(
                                        visible: postMain.lbsInfo != null,
                                        child: Text("${postMain.lbsInfo}",
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14))),
                                  ))
                                ],
                              )
                            ],
                          )),
                          AgreeAndDisagreeBar(
                            agreeNum: int.parse(postMain.agreeNum!),
                            disagreeNum: int.parse(postMain.disagreeNum!),
                            agreeType: int.parse(postMain.agreeType!),
                            postID: postMain.id,
                            threadID: threadID,
                            objType: 1,
                            hasAgree: postMain.hasAgree!,
                          )
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //正文
                        Container(
                          padding: const EdgeInsets.all(5),
                          child: Wrap(
                            children: TiebaParser.parseContent(
                                context, postMain.content, allImgs, allOrgImgs,
                                selectable: true),
                          ),
                        ),
                        Visibility(
                            visible: postMain.subPostList.isNotEmpty,
                            child: Row(
                              children: [
                                Expanded(
                                    child: InnerFloor(
                                  subPostList: postMain.subPostList,
                                  userlist: userList,
                                  subPostNumber: postMain.subPostNumber,
                                  floorNum: postMain.floor.toString(),
                                  kz: threadID,
                                  pid: postMain.id,
                                  forum: forum,
                                ))
                              ],
                            )),
                        const Divider()
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
  final Map<String, AuthorWidgetModel> userlist;
  final List<SubPost> subPostList;
  final String subPostNumber;
  final String floorNum;
  final String kz;
  final String pid;
  final ForumData forum;
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
      if (post.isVoice) {
        if (kDebugMode) {
          print("音频回复");
        }
      }
      subposts.add(InnerPost(
        author: userlist[post.uid]!,
        posts: post.content,
        floorNum: floorNum,
        kz: kz,
        pid: pid,
        spid: subPostList[i].id,
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
          padding: const EdgeInsets.all(5),
          child: Text(
            "查看剩余${int.parse(subPostNumber) - subPostList.length}条回复",
            style: TextStyle(
                color: Theme.of(context).extension<QuoteTheme>()!.textColor,
                fontWeight: FontWeight.bold),
          ),
        ),
      ));
    }
    return subposts;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: Theme.of(context).extension<QuoteTheme>()!.backgorund!,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFF0F1F2))),
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
  final AuthorWidgetModel author;
  final List<PostContentBaseWidgetModel> posts;
  final ForumData forum;
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
  List<Widget> buildContent(BuildContext context) {
    List<InlineSpan> w = [];
    w.add(AtUserSpan(
      context,
      uid: author.id,
      text: "${author.name} :",
      style: const TextStyle(color: Colors.blue),
    ));

    for (PostContentBaseWidgetModel content in posts) {
      //用户
      if (content is TextContentWidgetModel) {
        if (content.uid != null) {
          w.add(TextSpan(
              text: content.text,
              style: const TextStyle(color: Colors.blue),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.pushNamed(context, PageRouter.user,
                      arguments: content.uid);
                }));
        } else {
          w.add(TextSpan(
            text: content.text,
          ));
        }
      } else if (content is EmojiContentWidgetModel) {
        w.add(EmojiSpan(
          content.text,
          imageWidth: Provider.of<APPSettingProvider>(context).fontSize + 2,
          imageHeight: Provider.of<APPSettingProvider>(context).fontSize + 2,
        ));
      } else if (content is LinkContentWidgetModel) {
        w.add(TextSpan(
            text: content.text,
            style: TextStyle(
                fontSize: Provider.of<APPSettingProvider>(context).fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                if (await AppUtil.urlRoute(
                      context,
                      content.link,
                    ) ==
                    false) {
                  Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (builder) => WebViewWidget(
                                // initialCookies: data,
                                controller: WebViewController()
                                  ..setBackgroundColor(Colors.white)
                                  ..setJavaScriptMode(
                                      JavaScriptMode.unrestricted)
                                  ..setNavigationDelegate(NavigationDelegate(
                                      onNavigationRequest: (request) async {
                                    if (await AppUtil.urlRoute(
                                      context,
                                      request.url,
                                    )) {
                                      return NavigationDecision.prevent;
                                    }

                                    return NavigationDecision.navigate;
                                  }))
                                  ..loadRequest(Uri.parse(content.link)),
                              )));
                }
              }));
      } else if (content is PhoneNumberContentWidgetModel) {
        w.add(TextSpan(
          text: content.text,
          style: TextStyle(fontSize: Global.setting.fontSize),
        ));
      } else if (content is AtContentWidgetModel) {
        //楼中楼@用户
        w.add(AtUserSpan(context, text: content.text, uid: content.uid));
      } else if (content is VoiceContentWidgetModel) {
        throw Exception("楼语音");
        //TODO:语音
        // player
      } else {
        throw Exception("未知类型");
      }
    }
    return [
      RichText(
          text: TextSpan(
              children: w,
              style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                  fontSize:
                      Provider.of<APPSettingProvider>(context).fontSize - 1)))
    ];
  }

  @override
  Widget build(BuildContext context) {
    // if (Platform.isAndroid) {
    //   WebView.platform = AndroidWebView();
    // }
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
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              Expanded(
                  child: Wrap(
                children: buildContent(context),
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
  final ForumData forum;
  const InnerFloorBottomSheet(
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
  late List<SubPost> subPosts;
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
        duration: const Duration(milliseconds: 100));

    //TODO:连续加载下/上一页
  }

  void loadPage(int pageNum) async {
    //只刷新未加载的页面和头(非第一页)/尾
    if (!floorPages.containsKey(pageNum) ||
        (floorPages.keys.toSet().last == pageNum) ||
        (floorPages.keys.toSet().first == pageNum && pageNum != 1)) {
      dataLoader = Global.tiebaAPI
          .getInnerFloor(widget.kz, widget.pid, spid: widget.spid, pn: pn)
          .then((value) {
        pn = int.parse(value.page!.currentPage!);
        floorPages[pn] = value;
        return value;
      });
    }
  }

  List<Widget> buildFloor() {
    List<Widget> w = [];
    floorPages.forEach((key, value) {
      if (w.isEmpty) {
        w.add(
          Container(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: InnerFloorCard(
                author: AuthorWidgetModel.fromData(value.post!.author!),
                postMain: PostListWidgetModel.fromInnerFloorPost(value.post!),
                threadID: value.thread!.id!,
                isSpid: false,
                forum: widget.forum,
                floorId: value.post!.id!,
              )),
        );
        w.add(Container(
          height: 10,
          color: const Color.fromARGB(15, 185, 185, 185),
        ));
        w.add(Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          alignment: Alignment.centerLeft,
          child: Text("${value.subpostList!.length}条回复"),
        ));
      }
      for (SubpostList subpost in value.subpostList ?? []) {
        w.add(
          InnerFloorCard(
            author: AuthorWidgetModel.fromData(subpost.author!),
            postMain: PostListWidgetModel.fromSubpostList(subpost),
            threadID: value.thread!.id!,
            isSpid: subpost.id == widget.spid,
            forum: widget.forum,
            floorId: value.post!.id!,
          ),
        );
        w.add(const Divider());
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
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : Theme.of(context).colorScheme.background),
          child: child,
        );
      },
      child: Column(
        children: [
          //头部
          Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.only(
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
                      child: const Icon(Icons.close),
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
          const Divider(),
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
                        child: ListView.builder(
                          controller: controller,
                          physics: animationcontroller.value > 0
                              ? const NeverScrollableScrollPhysics()
                              : const ClampingScrollPhysics(),
                          itemCount: floors.length,
                          itemBuilder: (BuildContext context, int index) {
                            return floors[index];
                          },
                        ),
                      ),
                    )),
                    //底部回复条
                    Builder(
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
                            author: AuthorWidgetModel.fromData(author),
                            postMain:
                                PostListWidgetModel.fromPostList(postMain),
                            threadID: threadID,
                            forum: widget.forum,
                          );
                        } else {
                          return Container();
                        }
                      },
                    )
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
  final AuthorWidgetModel author;
  final PostListWidgetModel postMain;
  final String threadID;
  final bool isSpid;
  final ForumData forum;
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

  List<String> _imgCollect() {
    List<String> l = [];
    // for (PostContentBaseWidgetModel content in postMain.content) {
    //   if (content.type == "3" ||
    //       (content.type == "4" && content.originSrc != null)) {
    //     l.add(content.bigCdnSrc!);
    //   }
    // }
    for (PostContentBaseWidgetModel content in postMain.content) {
      if (content is ImageContentWidgetModel) {
        l.add(content.bigCdnSrc!);
      }
    }
    return l;
  }

  List<String> _originImgCollect() {
    List<String> l = [];
    for (PostContentBaseWidgetModel content in postMain.content) {
      if (content is ImageContentWidgetModel) {
        l.add(content.originSrc!);
      }
    }
    return l;
  }

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
                    "${author.name}： ${TiebaParser.parserContentString(postMain.content)}",
                kw: forum.forumName,
                fid: forum.fid,
                tid: threadID,
                floorId: floorId,
                isReplyThread: false,
                replyUser: author,
              );
            });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSpid
              ? Colors.amber.shade100
              : (Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : Theme.of(context).colorScheme.background),
        ),
        padding: const EdgeInsets.only(left: 18, right: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //作者
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 7),
                  child: Avatar(
                    imgUrl: AUTHOR_AVATAR + author.portrait,
                    height: 35,
                    width: 35,
                  ),
                ),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
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
                                    [
                                      ...(TiebaParser.processIcon(author) ??
                                          <Widget>[]),
                                      Container(
                                        margin: const EdgeInsets.only(left: 5),
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
                                        strTime: postMain.createTime),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                ],
                              )
                            ],
                          )),
                          AgreeAndDisagreeBar(
                            agreeNum: int.parse(postMain.agreeNum),
                            disagreeNum: int.parse(postMain.disagreeNum),
                            agreeType: int.parse(postMain.agreeType),
                            postID: postMain.id,
                            threadID: threadID,
                            objType: 2,
                            hasAgree: postMain.hasAgree,
                          )
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //正文
                        Container(
                          padding: const EdgeInsets.all(5),
                          child: Wrap(
                            children: TiebaParser.parseContent(
                                context,
                                postMain.content,
                                _imgCollect(),
                                _originImgCollect(),
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
