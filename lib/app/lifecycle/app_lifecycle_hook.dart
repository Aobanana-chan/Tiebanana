import 'package:flutter/widgets.dart';

abstract class APPStateCallback {
  bool done = false;
  void afterInit();
  void onRoute(RouteSettings settings);
  void onHomeFormPageCreate(BuildContext context);
}
