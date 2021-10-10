import 'package:flutter/material.dart';
import 'package:tiebanana/routes/HomePage.dart';

///命名路由表
class PageRouter {
  static Map<String, WidgetBuilder> routes = {
    "/": (builder) => HomePage(),
  };
  static String home = "/";
}
