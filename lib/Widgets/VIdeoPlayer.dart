import 'package:fijkplayer/fijkplayer.dart';
import 'package:fijkplayer_skin/fijkplayer_skin.dart';
import 'package:fijkplayer_skin/schema.dart';
import 'package:flutter/material.dart';

class PlayerShowConfig implements ShowConfigAbs {
  @override
  bool drawerBtn = false;
  @override
  bool nextBtn = false;
  @override
  bool speedBtn = true;
  @override
  bool topBar = true;
  @override
  bool lockBtn = true;
  @override
  bool autoNext = false;
  @override
  bool bottomPro = true;
  @override
  bool stateAuto = true;
  @override
  bool isAutoPlay = false;
}

class VideoPlayer extends StatefulWidget {
  final String? cover;
  final String url;
  VideoPlayer({this.cover, required this.url});

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoPlayer> {
  // FijkPlayer实例
  final FijkPlayer player = FijkPlayer();
  ShowConfigAbs vCfg = PlayerShowConfig();
  int _curTabIdx = 0;
  // 当前选中的tablist index，默认0
  int _curActiveIdx = 0;
  // 视频源列表，请参考当前videoList完整例子
  Map<String, List<Map<String, dynamic>>> videoList = {};
  VideoSourceFormat? _videoSourceTabs;
  @override
  void initState() {
    super.initState();
    // 格式化json转对象
    player.setDataSource(widget.url);
    // 这句不能省，必须有
    speed = 1.0;

    videoList["video"] = [
      {
        "name": "Video",
        "list": [
          {"url": widget.url, "name": "veido"}
        ]
      }
    ];
    _videoSourceTabs = VideoSourceFormat.fromJson(videoList);
  }

  void onChangeVideo(int curTabIdx, int curActiveIdx) {
    this.setState(() {
      _curTabIdx = curTabIdx;
      _curActiveIdx = curActiveIdx;
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 这里 FijkView 开始为自定义 UI 部分
      child: FijkView(
        cover: widget.cover == null ? null : NetworkImage(widget.cover!),
        color: Colors.black,
        fit: FijkFit.cover,
        player: player,
        panelBuilder: (
          FijkPlayer player,
          FijkData data,
          BuildContext playercontext,
          Size viewSize,
          Rect texturePos,
        ) {
          /// 使用自定义的布局
          return CustomFijkPanel(
            player: player,
            // 传递 context 用于左上角返回箭头关闭当前页面，不要传递错误 context，
            // 如果要点击箭头关闭当前的页面，那必须传递当前组件的根 context
            pageContent: playercontext,
            viewSize: viewSize,
            texturePos: texturePos,
            // 标题 当前页面顶部的标题部分，可以不传，默认空字符串
            playerTitle: "",
            // 当前视频改变钩子，简单模式，单个视频播放，可以不传
            // onChangeVideo: onChangeVideo,
            // 当前视频源tabIndex
            curTabIdx: _curTabIdx,
            // 当前视频源activeIndex
            curActiveIdx: _curActiveIdx,
            // 显示的配置
            showConfig: vCfg,
            // json格式化后的视频数据
            videoFormat: _videoSourceTabs,
          );
        },
      ),
    );
  }
}
