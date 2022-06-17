import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/CustomUnderlineTabIndicator.dart';
import 'package:tiebanana/Widgets/ForumTag.dart';
import 'package:tiebanana/Widgets/SearchThreadCard.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/common/Util/AppUtil.dart';
import 'package:tiebanana/routes/routes.dart';

///搜索页面
class SearchPage extends StatefulWidget {
  final String searchWords;
  const SearchPage({Key? key, required this.searchWords}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final List<String> _tab = ["吧", "贴", "用户"];
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
              icon: const Icon(Icons.search))
        ],
        title: TextField(
          controller: textEditingController,
          decoration: const InputDecoration(border: InputBorder.none),
          onSubmitted: (value) {},
        ),
        elevation: 0.5,
      ),
      body: Container(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Theme.of(context).backgroundColor,
        child: Column(
          children: [
            TabBar(
              controller: controller,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              labelColor: Theme.of(context).brightness == Brightness.light
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).colorScheme.onSurface,
              indicator: CustomUnderlineTabIndicator(
                  wantWidth: 36,
                  insets: const EdgeInsets.only(left: 15, right: 15),
                  borderSide: BorderSide(
                      width: 4, color: Theme.of(context).primaryColor)),
              tabs: _tab
                  .map((e) => Tab(
                        text: e,
                      ))
                  .toList(),
            ),
            Expanded(
                child: TabBarView(
              // physics: const BouncingScrollPhysics(),
              controller: controller,
              children: [
                KeepAliveWrapper(
                    child: FourmSearch(
                  keyword: textEditingController.text,
                )),
                KeepAliveWrapper(
                    child: ThreadSearch(
                  keyword: textEditingController.text,
                )),
                KeepAliveWrapper(
                    child: UserSearch(
                  keyWord: textEditingController.text,
                ))
              ],
            ))
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    textEditingController.dispose();
    super.dispose();
  }
}

class FourmSearch extends StatefulWidget {
  final String keyword;
  const FourmSearch({Key? key, required this.keyword}) : super(key: key);

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
    Widget child;
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
      child = NestedScrollView(
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
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : Theme.of(context).backgroundColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "相关吧",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Expanded(
                  child: ListView(
                // physics: const BouncingScrollPhysics(),
                children: related
                    .map((e) => ForumCardRelated(
                          searchForumModelForum: e,
                        ))
                    .toList(),
              ))
            ],
          ),
        ),
      );
    } else {
      child = ListView(
        // physics: const BouncingScrollPhysics(),
        children: related
            .map((e) => ForumCardRelated(
                  searchForumModelForum: e,
                ))
            .toList(),
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
  const ThreadSearch({Key? key, required this.keyword}) : super(key: key);

  @override
  State<ThreadSearch> createState() => _ThreadSearchState();
}

class _ThreadSearchState extends State<ThreadSearch> {
  late String keyword;
  List<SearchPostModelPostList> thread = [];
  int pn = 1;
  bool hasMore = false;
  int filter = 1;
  ScrollController controller = ScrollController();
  Map<String, int> threadSortType = {"旧贴在前排序": 0, "新贴在前排序": 1, "相关度排序": 2};
  String threadSortSelected = "新贴在前排序";
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
        .searchPost(keyword,
            pn: pn, order: threadSortType[threadSortSelected]!, filter: filter)
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

  List<DropdownMenuItem<String>> buildSortItem() {
    return (threadSortType.keys.map((e) {
      return DropdownMenuItem<String>(value: e, child: Text(e));
    }).toList());
  }

  void nextPage() async {
    if (hasMore) {
      pn++;
      var data = (await Global.tiebaAPI.searchPost(keyword,
              pn: pn,
              order: threadSortType[threadSortSelected]!,
              filter: filter))
          .data;
      thread.addAll(data?.postList ?? []);
      hasMore = data?.hasMore == 1;
      //加载完成清除节流

      // setState(() {
      //   SchedulerBinding.instance?.addPostFrameCallback((timeStamp) {
      //     Throttle.clear(nextPage);
      //   });
      // });
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
        .searchPost(keyword,
            pn: pn, order: threadSortType[threadSortSelected]!, filter: filter)
        .then((value) {
      setState(() {
        thread = value.data?.postList ?? [];
        hasMore = value.data?.hasMore == 1 ? true : false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          // physics: const BouncingScrollPhysics(),
          controller: controller,
          slivers: <Widget>[
            //控制器
            SliverToBoxAdapter(
              child: Container(
                  constraints: const BoxConstraints(maxHeight: 48),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : Theme.of(context).backgroundColor,
                  child: Row(
                    children: [
                      Expanded(
                          child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (filter == 1) {
                                    filter = 0;
                                  } else {
                                    filter = 1;
                                  }
                                  Global.tiebaAPI
                                      .searchPost(keyword,
                                          pn: pn,
                                          order: threadSortType[
                                              threadSortSelected]!,
                                          filter: filter)
                                      .then((value) {
                                    setState(() {
                                      thread = value.data?.postList ?? [];
                                      hasMore = value.data?.hasMore == 1
                                          ? true
                                          : false;
                                    });
                                  });
                                });
                              },
                              child: Center(
                                child: Text(
                                  "仅看主题帖",
                                  style: TextStyle(
                                      color: filter == 1
                                          ? (Theme.of(context).brightness ==
                                                  Brightness.light
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface)
                                          : (Theme.of(context).brightness ==
                                                  Brightness.light
                                              ? Colors.black
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface)),
                                ),
                              ))),
                      Expanded(
                          child: Center(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            items: buildSortItem(),
                            value: threadSortSelected,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  threadSortSelected = value;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ))
                    ],
                  )),
            ),
            SliverList(
                delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
              return SearchThreadCard(
                post: thread[index],
              );
            }, childCount: thread.length))
          ],
        ),
        //TODO:浮游按钮返回顶部
      ],
    );
  }
}

class UserSearch extends StatefulWidget {
  final String keyWord;
  const UserSearch({Key? key, required this.keyWord}) : super(key: key);

  @override
  State<UserSearch> createState() => _UserSearchState();
}

class _UserSearchState extends State<UserSearch> {
  late String keyword;
  List<UserMatch> users = [];
  @override
  void initState() {
    keyword = widget.keyWord;
    Global.tiebaAPI.searchUser(keyword).then((value) {
      setState(() {
        if (value.data?.exactMatch != null) {
          users.add(value.data!.exactMatch!);
        }
        users.addAll(value.data!.fuzzyMatch!);
      });
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant UserSearch oldWidget) {
    if (keyword != widget.keyWord) {
      keyword = widget.keyWord;
      Global.tiebaAPI.searchUser(keyword).then((value) {
        setState(() {
          if (value.data?.exactMatch != null) {
            users.add(value.data!.exactMatch!);
          }
          users.addAll(value.data!.fuzzyMatch!);
        });
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // physics: const BouncingScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (BuildContext context, int index) {
        return _UserListItem(user: users[index]);
      },
    );
  }
}

class _UserListItem extends StatelessWidget {
  final UserMatch user;
  const _UserListItem({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, PageRouter.user,
            arguments: user.id!.toString());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.all(5),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Avatar(
              imgUrl: user.portrait!,
              height: 48,
              width: 48,
            ),
          ),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.showNickname ?? user.userNickname ?? user.name!,
              ),
              Text(
                user.intro ?? "",
                style: const TextStyle(overflow: TextOverflow.ellipsis),
                maxLines: 2,
              )
            ],
          )),
        ]),
      ),
    );
  }
}
