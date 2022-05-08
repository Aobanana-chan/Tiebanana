import 'package:animate_do/animate_do.dart';
import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/CustomUnderlineTabIndicator.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:uuid/uuid.dart';

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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(children: [
        _UserInfomation(userinfo: userinfo),
        Container(
          margin: const EdgeInsets.only(top: 10),
          color: Colors.white,
          child: _BottomView(
            uid: widget.uid,
            myLikeNum: userinfo?.user!.myLikeNum ?? "0",
            threadNum: userinfo?.user!.threadNum ?? "0",
            rePostNum: userinfo?.user!.repostNum ?? "0",
          ),
        )
      ]),
    );
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
      color: Colors.white,
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
                          style: const TextStyle(
                              color: Colors.black, fontSize: 17)),
                      const TextSpan(
                          text: " 获赞     ",
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                      TextSpan(
                          text: widget.userinfo?.user?.fansNum ?? "0",
                          style: const TextStyle(
                              color: Colors.black, fontSize: 17)),
                      const TextSpan(
                          text: " 粉丝     ",
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                      TextSpan(
                          text: widget.userinfo?.user?.concernNum ?? "0",
                          style: const TextStyle(
                              color: Colors.black, fontSize: 17)),
                      const TextSpan(
                          text: " 关注     ",
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
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
              borderRadius: BorderRadius.circular(8), color: Colors.white),
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
        Text(
            "~~ ${widget.userinfo?.user?.intro == null || widget.userinfo?.user?.intro == "" ? "这懒人没设签名喵" : widget.userinfo?.user?.intro} ~~"),
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
  Future? post;
  @override
  void initState() {
    super.initState();
    _tab = [
      "贴子 ${widget.threadNum}",
      "回复 ${widget.rePostNum}",
      "关注的吧 ${widget.myLikeNum}"
    ];
    _controller = TabController(length: _tab.length, vsync: this);
    post = Global.tiebaAPI.getUserPost(uid: widget.uid);
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
    return Container(
      child: Column(children: [
        TabBar(
          tabs: _tab
              .map((e) => Tab(
                    text: e,
                  ))
              .toList(),
          controller: _controller,
          labelColor: Colors.blue,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          indicator: CustomUnderlineTabIndicator(
              wantWidth: 36,
              insets: const EdgeInsets.only(left: 15, right: 15),
              borderSide: const BorderSide(width: 4, color: Colors.green)),
        ),
      ]),
    );
  }
}

///贴视图
class _ThreadView extends StatefulWidget {
  const _ThreadView({Key? key}) : super(key: key);

  @override
  State<_ThreadView> createState() => __ThreadViewState();
}

class __ThreadViewState extends State<_ThreadView> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

///回复视图
class _Postview extends StatefulWidget {
  _Postview({Key? key}) : super(key: key);

  @override
  State<_Postview> createState() => __PostviewState();
}

class __PostviewState extends State<_Postview> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

///关注吧视图
class _ForumView extends StatefulWidget {
  _ForumView({Key? key}) : super(key: key);

  @override
  State<_ForumView> createState() => __ForumViewState();
}

class __ForumViewState extends State<_ForumView> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
