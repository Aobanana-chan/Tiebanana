import 'package:animate_do/animate_do.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/WidgetModel/MediaModel.dart';
import 'package:tiebanana/Json_Model/WidgetModel/QuotaModel.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/CustomUnderlineTabIndicator.dart';
import 'package:tiebanana/Widgets/ForumTag.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/Widgets/UserPostWidget.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/Global.dart';

import '../Json_Model/WidgetModel/PostContentModel.dart';
import '../Json_Model/WidgetModel/ThreadCommentModel.dart';

///用户界面-访客
class UserVisitor extends StatefulWidget {
  final String uid;
  const UserVisitor({Key? key, required this.uid}) : super(key: key);

  @override
  State<UserVisitor> createState() => _UserVisitorState();
}

class _UserVisitorState extends State<UserVisitor> {
  UserProfileModel? userinfo;
  Future<UserProfileModel>? futureUserInfo;
  void init() async {
    userinfo = await Global.tiebaAPI.getUserInfo(uid: widget.uid);

    setState(() {});
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: userinfo == null
              ? const Text("")
              : Text(userinfo!.user?.nameShow ?? userinfo!.user?.name ?? ""),
          elevation: 0.5,
        ),
        body: ExtendedNestedScrollView(
          onlyOneScrollInBody: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return <Widget>[
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: _UserInfomation(userinfo: userinfo),
                ),
              )
            ];
          },
          body: Container(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Theme.of(context).scaffoldBackgroundColor,
            child: _BottomView(
              uid: widget.uid,
              myLikeNum: userinfo?.user!.myLikeNum ?? "0",
              threadNum: userinfo?.user!.threadNum ?? "0",
              rePostNum: userinfo?.user!.postNum ?? "0",
            ),
          ),
        ));
  }
}

class _UserInfomation extends StatefulWidget {
  final UserProfileModel? userinfo;
  const _UserInfomation({Key? key, required this.userinfo}) : super(key: key);

  @override
  State<_UserInfomation> createState() => __UserInfomationState();
}

class __UserInfomationState extends State<_UserInfomation> {
  @override
  Widget build(BuildContext context) {
    if (widget.userinfo == null) {
      return Container();
    }
    return FadeIn(
        child: Container(
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Theme.of(context).colorScheme.background,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: Row(
            children: [
              Avatar(
                  height: 45,
                  width: 45,
                  imgUrl: AUTHOR_AVATAR + widget.userinfo!.user!.portrait!),
              Expanded(
                  child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(widget.userinfo!.user?.nameShow ??
                        widget.userinfo!.user?.name ??
                        ""),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: widget.userinfo?.userAgreeInfo?.totalAgreeNum ??
                              widget.userinfo?.user?.totalAgreeNum ??
                              "0",
                          style: TextStyle(
                              fontSize: Provider.of<APPSettingProvider>(context)
                                      .fontSize +
                                  1)),
                      TextSpan(
                          text: " 获赞     ",
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: Provider.of<APPSettingProvider>(context)
                                      .fontSize -
                                  3)),
                      TextSpan(
                          text: widget.userinfo?.user?.fansNum ?? "0",
                          style: TextStyle(
                              fontSize: Provider.of<APPSettingProvider>(context)
                                      .fontSize +
                                  1)),
                      TextSpan(
                          text: " 粉丝     ",
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: Provider.of<APPSettingProvider>(context)
                                      .fontSize -
                                  3)),
                      TextSpan(
                          text: widget.userinfo?.user?.concernNum ?? "0",
                          style: TextStyle(
                              fontSize: Provider.of<APPSettingProvider>(context)
                                      .fontSize +
                                  1)),
                      TextSpan(
                          text: " 关注     ",
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: Provider.of<APPSettingProvider>(context)
                                      .fontSize -
                                  3)),
                    ])),
                  ),
                ],
              )),
              //TODO:关注
              GradientButton(
                  onPressed: () {},
                  borderRadius: BorderRadius.circular(32),
                  child: const Text(
                    "+关注",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ))
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : Theme.of(context).backgroundColor),
          child: Row(
            children: [
              //TODO:复制到剪切板
              Text("ID:${widget.userinfo!.user!.id}"),
              const Icon(
                Icons.copy,
                size: 15,
              ),
              const SizedBox(
                width: 10,
              ),
              Text("吧龄:${widget.userinfo!.user!.tbAge}"),
              const SizedBox(
                width: 10,
              ),
              Builder(builder: (context) {
                if (widget.userinfo?.user?.sex == "2") {
                  return Icon(
                    Icons.male,
                    color: Colors.pink.shade300,
                  );
                } else if (widget.userinfo?.user?.sex == "1") {
                  return Icon(
                    Icons.female,
                    color: Colors.blue.shade300,
                  );
                } else {
                  return Container();
                }
              })
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
              "~~ ${widget.userinfo?.user?.intro == null || widget.userinfo?.user?.intro == "" ? "这懒人没设签名喵" : widget.userinfo?.user?.intro} ~~"),
        )
      ]),
    ));
  }
}

///底部视图
class _BottomView extends StatefulWidget {
  final String uid;
  final String rePostNum;
  final String threadNum;
  final String myLikeNum;
  const _BottomView(
      {Key? key,
      required this.uid,
      required this.rePostNum,
      required this.threadNum,
      required this.myLikeNum})
      : super(key: key);

  @override
  State<_BottomView> createState() => _BottomViewState();
}

class _BottomViewState extends State<_BottomView>
    with SingleTickerProviderStateMixin {
  late List _tab;
  late TabController _controller;
  @override
  void initState() {
    super.initState();
    _tab = [
      "贴子 ${widget.threadNum}",
      "回复 ${widget.rePostNum}",
      "关注的吧 ${widget.myLikeNum}"
    ];
    _controller = TabController(length: _tab.length, vsync: this);
    // post = Global.tiebaAPI.getUserPost(uid: widget.uid);
  }

  @override
  void didUpdateWidget(covariant _BottomView oldWidget) {
    _tab = [
      "贴子 ${widget.threadNum}",
      "回复 ${widget.rePostNum}",
      "关注的吧 ${widget.myLikeNum}"
    ];
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TabBar(
        tabs: _tab
            .map((e) => Tab(
                  text: e,
                ))
            .toList(),
        controller: _controller,
        labelColor: Theme.of(context).brightness == Brightness.light
            ? Theme.of(context).primaryColor
            : Theme.of(context).colorScheme.onSurface,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        indicator: CustomUnderlineTabIndicator(
            wantWidth: 36,
            insets: const EdgeInsets.only(left: 15, right: 15),
            borderSide: BorderSide(
                width: 4,
                color: Theme.of(context).brightness == Brightness.light
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.onSurface)),
      ),
      Expanded(
          child: TabBarView(controller: _controller, children: [
        KeepAliveWrapper(child: _ThreadView(uid: widget.uid)),
        KeepAliveWrapper(
            child: _Postview(
          uid: widget.uid,
        )),
        KeepAliveWrapper(
            child: _ForumView(
          uid: widget.uid,
        ))
      ]))
    ]);
  }
}

///贴视图
class _ThreadView extends StatefulWidget {
  final String uid;
  const _ThreadView({Key? key, required this.uid}) : super(key: key);

  @override
  State<_ThreadView> createState() => __ThreadViewState();
}

class __ThreadViewState extends State<_ThreadView> {
  UserPostModel? info;
  List<UserPostPostList> posts = [];
  int pn = 1;
  bool hasMore = true;
  late ScrollController? _controller;
  late String? username;
  void init() async {
    info = await Global.tiebaAPI.getUserPost(uid: widget.uid, pn: pn);
    posts.addAll(info?.postList ?? []);
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {});
    });
  }

  void _loadPage(int pn) async {
    this.pn = pn;
    info = await Global.tiebaAPI.getUserPost(uid: widget.uid, pn: pn);
    // ignore: prefer_is_empty
    if (info?.postList?.length == 0) {
      hasMore = false;
    }
    posts.addAll(info?.postList ?? []);
    setState(() {});
  }

  void _loadNextPage() {
    _loadPage(++pn);
  }

  @override
  void initState() {
    init();
    var userinfo =
        context.findAncestorStateOfType<_UserVisitorState>()?.userinfo;
    username = "${userinfo?.user?.nameShow ?? userinfo?.user?.name}";
    _controller = context
        .findAncestorStateOfType<ExtendedNestedScrollViewState>()
        ?.innerController;
    _controller?.addListener(() {
      if (_controller!.positions.last.pixels >
          _controller!.positions.last.maxScrollExtent -
              _controller!.positions.last.viewportDimension) {
        if (hasMore) {
          Throttle.seconds(1, _loadNextPage);
        }
      }
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _ThreadView oldWidget) {
    _controller = context
        .findAncestorStateOfType<ExtendedNestedScrollViewState>()
        ?.innerController;
    var userinfo =
        context.findAncestorStateOfType<_UserVisitorState>()?.userinfo;
    username = "${userinfo?.user?.nameShow ?? userinfo?.user?.name}";
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (info?.hidePost == "1") {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            // // physics: const BouncingScrollPhysics(),
            child: Container(
              constraints: constraints,
              child: const Center(
                child: Text.rich(
                  TextSpan(children: [
                    WidgetSpan(
                        child: Icon(
                      Icons.lock,
                      color: Colors.grey,
                    )),
                    TextSpan(text: "这位老铁已将贴设为隐藏")
                  ]),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          );
        },
      );
    }
    return ListView.builder(
      itemCount: posts.length,
      // physics: const BouncingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        // return Container();
        return UserPostWidget(
            username: username!,
            content: () {
              var result = <PostContentBaseWidgetModel>[];
              for (var element in posts[index].content ?? []) {
                result.add(createContentModel(element));
              }
              return result;
            }(),
            images: () {
              var result = <MediaModel>[];
              for (Media element in posts[index].media ?? []) {
                result.add(MediaModel(
                    bigPic: element.bigPic!, originPic: element.originPic!));
              }
              return result;
            }(),
            videoInfo: posts[index].videoInfo == null
                ? null
                : VedioInfoWidgetModel.fromVideoInfo(posts[index].videoInfo!),
            threadId: posts[index].threadId!,
            userId: posts[index].userId!,
            userPortrait: posts[index].userPortrait!,
            isThread: posts[index].isThread != "0",
            title: posts[index].title!,
            createTime: posts[index].createTime!,
            quota: posts[index].quota == null
                ? null
                : QuotaModel(content: posts[index].quota!.content!),
            forumName: posts[index].forumName!,
            agreeNum: posts[index].agree!.agreeNum!,
            disagreeNum: posts[index].agree!.disagreeNum!,
            replyNum: posts[index].replyNum!,
            postId: posts[index].postId);
      },
    );
  }
}

///回复视图
class _Postview extends StatefulWidget {
  final String uid;
  const _Postview({Key? key, required this.uid}) : super(key: key);

  @override
  State<_Postview> createState() => __PostviewState();
}

class __PostviewState extends State<_Postview> {
  UserPostModel? info;
  List<UserPostPostList> posts = [];
  int pn = 1;
  bool hasMore = true;
  late ScrollController? _controller;
  late final String? username;
  void init() async {
    info = await Global.tiebaAPI.getUserPostLowVersion(uid: widget.uid, pn: pn);
    posts.addAll(info?.postList ?? []);
    setState(() {});
  }

  void _loadPage(int pn) async {
    this.pn = pn;
    info = await Global.tiebaAPI.getUserPostLowVersion(uid: widget.uid, pn: pn);
    // ignore: prefer_is_empty
    if (info?.postList?.length == 0) {
      hasMore = false;
    }
    posts.addAll(info?.postList ?? []);
    setState(() {});
  }

  void _loadNextPage() {
    _loadPage(++pn);
  }

  @override
  void initState() {
    init();
    var userinfo =
        context.findAncestorStateOfType<_UserVisitorState>()?.userinfo;
    username = "${userinfo?.user?.nameShow ?? userinfo?.user?.name}";
    _controller = context
        .findAncestorStateOfType<ExtendedNestedScrollViewState>()
        ?.innerController;

    _controller?.addListener(() {
      if (_controller!.positions.last.pixels >
          _controller!.positions.last.maxScrollExtent -
              _controller!.positions.last.viewportDimension) {
        if (hasMore) {
          Throttle.seconds(1, _loadNextPage);
        }
      }
    });

    super.initState();
  }

  @override
  void didUpdateWidget(covariant _Postview oldWidget) {
    _controller = context
        .findAncestorStateOfType<ExtendedNestedScrollViewState>()
        ?.innerController;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (info?.hidePost == "1") {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            // physics: const BouncingScrollPhysics(),
            child: Container(
              constraints: constraints,
              child: const Center(
                child: Text.rich(
                  TextSpan(children: [
                    WidgetSpan(
                        child: Icon(
                      Icons.lock,
                      color: Colors.grey,
                    )),
                    TextSpan(text: "这位老铁已将回复设为隐藏")
                  ]),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          );
        },
      );
    }
    return ListView.builder(
      itemCount: posts.length,
      // physics: const BouncingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        // return Container();
        return UserPostWidget(
          username: username!,
          content: () {
            var result = <PostContentBaseWidgetModel>[];
            for (var element in posts[index].content ?? []) {
              result.add(createContentModel(element));
            }
            return result;
          }(),
          images: () {
            var result = <MediaModel>[];
            for (Media element in posts[index].media ?? []) {
              result.add(MediaModel(
                  bigPic: element.bigPic!, originPic: element.originPic!));
            }
            return result;
          }(),
          videoInfo: posts[index].videoInfo == null
              ? null
              : VedioInfoWidgetModel.fromVideoInfo(posts[index].videoInfo!),
          threadId: posts[index].threadId!,
          userId: posts[index].userId!,
          userPortrait: posts[index].userPortrait!,
          isThread: posts[index].isThread != "0",
          title: posts[index].title!,
          createTime: posts[index].createTime!,
          quota: posts[index].quota == null
              ? null
              : QuotaModel(content: posts[index].quota!.content!),
          forumName: posts[index].forumName!,
          agreeNum: posts[index].agree?.agreeNum ?? "0",
          disagreeNum: posts[index].agree?.disagreeNum ?? "0",
          replyNum: posts[index].replyNum ?? "0",
          postId: posts[index].postId,
        );
      },
    );
  }
}

///关注吧视图
class _ForumView extends StatefulWidget {
  final String uid;
  const _ForumView({Key? key, required this.uid}) : super(key: key);

  @override
  State<_ForumView> createState() => __ForumViewState();
}

class __ForumViewState extends State<_ForumView> {
  int pn = 1;
  final int pageSize = 50;
  List<NonGconforum>? forums = [];
  void init() async {
    var info = await Global.tiebaAPI.getUserForumnLike(widget.uid,
        Provider.of<User>(context, listen: false).uid, pn, pageSize);
    forums = info.forumList?.nonGconforum;

    setState(() {});
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (forums == null) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            // physics: const BouncingScrollPhysics(),
            child: Container(
              constraints: constraints,
              child: const Center(
                child: Text.rich(
                  TextSpan(children: [
                    WidgetSpan(
                        child: Icon(
                      Icons.lock,
                      color: Colors.grey,
                    )),
                    TextSpan(text: "这位老铁已将关注的吧设为隐藏")
                  ]),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          );
        },
      );
    } else {
      return GridView.builder(
        // physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          mainAxisExtent: 72,
          crossAxisCount: 2,
        ),
        itemCount: forums?.length ?? 0,
        itemBuilder: (BuildContext context, int index) {
          var i = forums![index];
          return Container(
            padding: const EdgeInsets.all(3),
            child: ForumTagMedium(
                avatarUrl: i.avatar!,
                forumName: i.name!,
                member: i.memberCount!,
                level: i.levelId!),
          );
        },
      );
    }
  }
}
