import 'package:flutter/cupertino.dart';

/// App 内所有整页跳转的唯一入口。
///
/// 统一使用 iOS 风格的左右翻页（含左缘侧滑返回），保持页面切换动画一致。
/// 新增整页跳转通过此函数构造。
PageRoute<T> appPageRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
  bool fullscreenDialog = false,
}) {
  return CupertinoPageRoute<T>(
    builder: builder,
    settings: settings,
    fullscreenDialog: fullscreenDialog,
  );
}
