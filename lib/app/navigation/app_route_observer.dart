import 'package:flutter/widgets.dart';

/// 全局路由观察者，页面返回时通知订阅者刷新，并记录最近返回的页面名。
final PageRouteObserver appRouteObserver = PageRouteObserver();

class PageRouteObserver extends RouteObserver<ModalRoute<void>> {
  String? lastPoppedPageName;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is! PageRoute<dynamic>) return;
    lastPoppedPageName = route.settings.name;
    super.didPop(route, previousRoute);
  }
}
