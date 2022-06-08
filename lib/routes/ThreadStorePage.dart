import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/PageModel/ThreadStorePageModel.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/StoredThreadWidget.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/Global.dart';

///我的收藏页面
class ThreadStorePage extends StatefulWidget {
  const ThreadStorePage({Key? key}) : super(key: key);

  @override
  State<ThreadStorePage> createState() => _ThreadStorePageState();
}

class _ThreadStorePageState extends State<ThreadStorePage> {
  int offset = 0;
  final int rn = 20;
  late String myUid;
  List<StoredThread> threads = [];
  bool deleteMode = false;
  ScrollController controller = ScrollController();
  bool hasMore = true;

  void init() async {
    myUid = Provider.of<User>(context, listen: false).uid;
    await refresh();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    init();
    controller.addListener(() {
      if (controller.offset >
          controller.position.maxScrollExtent -
              controller.position.viewportDimension) {
        if (hasMore) {
          Throttle.milliseconds(500, loadNextPage);
        }
      }
    });
  }

  Future<void> refresh() async {
    threads.clear();
    offset = 0;
    hasMore = true;
    var result = await Global.tiebaAPI.getThreadStore(offset, myUid, rn: rn);
    if (result.error?.errno == "0") {
      for (var i in result.storeThread!) {
        threads.add(StoredThread(
            id: i.threadId!,
            title: i.title!,
            isDeleted: i.isDeleted == "1",
            isFollowed: i.isFollow == "1",
            portrait: AUTHOR_AVATAR + i.author!.userPortrait!,
            uid: i.author!.lzUid!,
            postNo: i.postNo,
            postNoMsg: i.postNoMsg,
            media: i.media,
            nameShow: i.author!.nameShow,
            username: i.author!.name,
            count: i.count,
            pid: i.markPid!));
      }
      offset += rn;
    }
  }

  Future<void> loadNextPage() async {
    var result = await Global.tiebaAPI.getThreadStore(offset, myUid, rn: rn);
    if (result.error?.errno == "0") {
      if (result.storeThread!.isNotEmpty) {
        for (var i in result.storeThread!) {
          threads.add(StoredThread(
              id: i.threadId!,
              title: i.title!,
              isDeleted: i.isDeleted == "1",
              isFollowed: i.isFollow == "1",
              portrait: AUTHOR_AVATAR + i.author!.userPortrait!,
              uid: i.author!.lzUid!,
              postNo: i.postNo,
              postNoMsg: i.postNoMsg,
              media: i.media,
              nameShow: i.author!.nameShow,
              username: i.author!.name,
              count: i.count,
              pid: i.markPid!));
        }
        offset += rn;
      } else {
        hasMore = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //去重，当删除后刷新，会同时触发Refresh和loadNextPage
    threads = threads.toSet().toList();

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          title: const Text("我的收藏"),
          actions: [
            MaterialButton(
                onPressed: () {
                  setState(() {
                    deleteMode = !deleteMode;
                  });
                },
                child: deleteMode ? const Text("取消") : const Text("编辑"))
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await refresh();
            setState(() {});
          },
          child: ListView.builder(
            controller: controller,
            physics: const BouncingScrollPhysics(),
            itemCount: threads.length,
            itemBuilder: (BuildContext context, int index) {
              return Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.none,
                  child: StoredThreadWidget(
                    info: threads[index],
                    deleteMode: deleteMode,
                    deleteFromList: () {
                      setState(() {
                        threads.removeAt(index);
                      });
                    },
                  ));
            },
          ),
        ));
  }
}
