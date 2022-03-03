import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/CustomUnderlineTabIndicator.dart';
import 'package:tiebanana/Widgets/ForumTag.dart';

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
              FourmSearch(
                keyword: textEditingController.text,
              ),
              ThreadSearch(),
              UserSearch()
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
  @override
  void initState() {
    super.initState();
    keyword = widget.keyword;
  }

  @override
  void didUpdateWidget(covariant FourmSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (keyword != widget.keyword) {
      pn = 1;
    }
    keyword = widget.keyword;
  }

  List<Widget> buildElem() {
    List<Widget> w = [];
    SearchForumModelForum? f;
    List<SearchForumModelForum> related = [];
    for (var forum in forums) {
      if (forum.name != keyword) {
        f = forum;
      } else {
        related.add(forum);
      }
    }
    if (f != null) {
      w.add(ForumCard(forum: f));
    }
    w.add(Container(
      child: Column(
        children: related
            .map((e) => ForumTagBig(
                  searchForumModelForum: e,
                ))
            .toList(),
      ),
    ));

    return w;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: buildElem(),
      ),
    );
  }
}

class ThreadSearch extends StatefulWidget {
  ThreadSearch({Key? key}) : super(key: key);

  @override
  State<ThreadSearch> createState() => _ThreadSearchState();
}

class _ThreadSearchState extends State<ThreadSearch> {
  @override
  Widget build(BuildContext context) {
    return Container();
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
