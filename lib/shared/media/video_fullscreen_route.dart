import 'package:flutter/widgets.dart';

/// 视频全屏页的路由。
///
/// 画面本身由 [Hero] 从卡片位置拉大到整屏（退出时原路缩回），
/// 这里只让黑底和控制层淡入淡出，做法与图片查看器一致。
class VideoFullScreenRoute extends PageRouteBuilder<void> {
  VideoFullScreenRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        );
}
