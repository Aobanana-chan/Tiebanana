import 'package:flutter/material.dart';
import 'package:tiebanana/routes/ForumHomePage.dart';
import 'package:tiebanana/routes/HomePage.dart';
import 'package:tiebanana/routes/ThreadPage.dart';

///命名路由表
class PageRouter {
  static Map<String, WidgetBuilder> routes = {
    "/": (builder) => HomePage(),
    "forumHome": (builder) {
      return ForumHomePage(
        kw: ModalRoute.of(builder)!.settings.arguments as String,
      );
    },
    "threadPage": (buidler) {
      return ThreadPageRoute(
        kz: ModalRoute.of(buidler)!.settings.arguments as String,
      );
    }
  };
  static String home = "/";
  static String forumHome = "forumHome";
  static String threadPage = "threadPage";
}
