import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/CustomUnderlineTabIndicator.dart';
import 'package:tiebanana/Widgets/ExtendedNestedScrollViewEx.dart';
import 'package:tiebanana/Widgets/ForumTag.dart';
import 'package:tiebanana/Widgets/SearchThreadCard.dart';
import 'package:tiebanana/common/Global.dart';

///搜索页面
class SearchPage extends StatefulWidget {
  final String searchWords;
  SearchPage({Key? key, required this.searchWords}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  List<String> _tab = ["吧", "贴", "用户"];
  late TabController controller;
  late TextEditingController textEditingController;
  @override
  void initState() {
    controller = TabController(length: _tab.length, vsync: this);
    textEditingController = TextEditingController(text: widget.searchWords);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                setState(() {});
              },
              icon: Icon(Icons.search))
        ],
        title: TextField(
          controller: textEditingController,
          decoration: InputDecoration(border: InputBorder.none),
          onSubmitted: (value) {},
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          TabBar(
            controller: controller,
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            labelColor: Colors.blue,
            indicator: CustomUnderlineTabIndicator(
                wantWidth: 36,
                insets: EdgeInsets.only(left: 15, right: 15),
                borderSide: BorderSide(width: 4, color: Colors.green)),
            tabs: _tab
                .map((e) => Tab(
                      text: e,
                    ))
                .toList(),
          ),
          Expanded(
              child: TabBarView(
            physics: BouncingScrollPhysics(),
            children: [
              KeepAliveWrapper(
                  child: FourmSearch(
                keyword: textEditingController.text,
              )),
              KeepAliveWrapper(
                  child: ThreadSearch(
                keyword: textEditingController.text,
              )),
              KeepAliveWrapper(child: UserSearch())
            ],
            controller: controller,
          ))
        ],
      ),
    );
  }
}

class FourmSearch extends StatefulWidget {
  final String keyword;
  FourmSearch({Key? key, required this.keyword}) : super(key: key);

  @override
  State<FourmSearch> createState() => _FourmSearchState();
}

class _FourmSearchState extends State<FourmSearch> {
  late String keyword;
  List<SearchForumModelForum> forums = [];
  int pn = 1;
  // late int totalPage;
  @override
  void initState() {
    super.initState();
    keyword = widget.keyword;
    Global.tiebaAPI.searchForum(keyword, pn).then((value) {
      setState(() {
        forums = value.data!.data!.forum!;
        // totalPage = value.data!.data!.page!.totalPage!;
      });
    });
  }

  @override
  void didUpdateWidget(covariant FourmSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (keyword != widget.keyword) {
      pn = 1;
    }
    keyword = widget.keyword;
    Global.tiebaAPI.searchForum(keyword, pn).then((value) {
      setState(() {
        forums = value.data!.data!.forum!;
      });
    });
  }

  // void nextPage() async {
  // if (pn + 1 <= totalPage) {
  // pn++;
  // var data = (await Global.tiebaAPI.searchForum(keyword, pn)).data!.data;
  // forums.addAll(data!.forum!);
  // totalPage = data.page!.totalPage!;
  //加载完成清除节流

  // setState(() {
  // SchedulerBinding.instance?.addPostFrameCallback((timeStamp) {
  //   Throttle.clear(nextPage);
  // });
  // });
  // }
  // }

  Widget buildElem() {
    var child;
    SearchForumModelForum? f;
    List<SearchForumModelForum> related = [];
    for (var forum in forums) {
      if (forum.name == keyword) {
        f = forum;
      } else {
        related.add(forum);
      }
    }

    if (f != null) {
      child = Container(
          child: NestedScrollView(
        // initStateCallback: (state) {
        //   state.innerController.addListener(() {
        //     if (state.innerController.offset >
        //         state.innerController.position.maxScrollExtent -
        //             state.innerController.position.viewportDimension) {
        //       Throttle.seconds(2, nextPage);
        //     }
        //   });
        // },
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: ForumCard(forum: f!),
          )
        ],
        body: Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8), color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "相关吧",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Expanded(
                  child: ListView(
                physics: BouncingScrollPhysics(),
                children: related
                    .map((e) => ForumCardRelated(
                          searchForumModelForum: e,
                        ))
                    .toList(),
              ))
            ],
          ),
        ),
      ));
    } else {
      child = Container(
        child: ListView(
          physics: BouncingScrollPhysics(),
          children: related
              .map((e) => ForumCardRelated(
                    searchForumModelForum: e,
                  ))
              .toList(),
        ),
      );
    }

    return child;
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: buildElem());
  }
}

class ThreadSearch extends StatefulWidget {
  final String keyword;
  ThreadSearch({Key? key, required this.keyword}) : super(key: key);

  @override
  State<ThreadSearch> createState() => _ThreadSearchState();
}

class _ThreadSearchState extends State<ThreadSearch> {
  late String keyword;
  List<SearchPostModelPostList> thread = [];
  int pn = 1;
  bool hasMore = false;
  int order = 1;
  int filter = 1;
  ScrollController controller = ScrollController();
  @override
  void initState() {
    super.initState();
    keyword = widget.keyword;
    // Global.tiebaAPI.searchThread(keyword, pn).then((value) {
    //   setState(() {
    //     thread = value.data!.data!.post!;
    //     totalPage = value.data!.data!.page!.totalPage!;
    //   });
    // });
    Global.tiebaAPI
        .searchPost(keyword, pn: pn, order: order, filter: filter)
        .then((value) {
      setState(() {
        thread = value.data?.postList ?? [];
        hasMore = value.data?.hasMore == 1;
      });
    });
    controller.addListener(() {
      if (controller.offset >
          controller.position.maxScrollExtent -
              controller.position.viewportDimension) {
        nextPage();
      }
    });
  }

  void nextPage() async {
    if (hasMore) {
      pn++;
      var data = (await Global.tiebaAPI
              .searchPost(keyword, pn: pn, order: order, filter: filter))
          .data;
      thread.addAll(data?.postList ?? []);
      hasMore = data?.hasMore == 1;
      //加载完成清除节流

      setState(() {
        SchedulerBinding.instance?.addPostFrameCallback((timeStamp) {
          Throttle.clear(nextPage);
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant ThreadSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (keyword != widget.keyword) {
      pn = 1;
    }
    keyword = widget.keyword;

    // Global.tiebaAPI.searchThread(keyword, pn).then((value) {
    //   setState(() {
    //     thread = value.data!.data!.post!;
    //     hasMore = value.data!.data!.page!.totalPage!;
    //   });
    // });
    Global.tiebaAPI
        .searchPost(keyword, pn: pn, order: order, filter: filter)
        .then((value) {
      setState(() {
        thread = value.data?.postList ?? [];
        hasMore = value.data?.hasMore == 1 ? true : false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CustomScrollView(
        physics: BouncingScrollPhysics(),
        controller: controller,
        slivers: <Widget>[
          //控制器
          SliverToBoxAdapter(
            child: Container(
                child: LeftRightBox(
              left: DropdownButton(),
            )),
          ),
          SliverList(
              delegate:
                  SliverChildBuilderDelegate((BuildContext context, int index) {
            return SearchThreadCard(
              post: thread[index],
            );
          }, childCount: thread.length))
        ],
      ),
    );
  }
}

class UserSearch extends StatefulWidget {
  UserSearch({Key? key}) : super(key: key);

  @override
  State<UserSearch> createState() => _UserSearchState();
}

class _UserSearchState extends State<UserSearch> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
