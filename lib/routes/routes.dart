import 'package:flutter/material.dart';
import 'package:tiebanana/routes/ForumHomePage.dart';
import 'package:tiebanana/routes/HomePage.dart';
import 'package:tiebanana/routes/ImagePicker.dart';
import 'package:tiebanana/routes/Login.dart';
import 'package:tiebanana/routes/Search.dart';
import 'package:tiebanana/routes/ThreadPage.dart';
import 'package:tiebanana/routes/ThreadStorePage.dart';
import 'package:tiebanana/routes/UserVisitor.dart';
import 'package:tiebanana/routes/ViewHistoryPage.dart';

///命名路由表
class PageRouter {
  static Map<String, WidgetBuilder> routes = {
    "/": (context) => const HomePage(),
    "forumHome": (context) {
      return ForumHomePage(
        kw: ModalRoute.of(context)!.settings.arguments as String,
      );
    },
    "threadPage": (context) {
      var data =
          ModalRoute.of(context)!.settings.arguments as ThreadPageRouterData;
      return ThreadPageRoute(kz: data.kz, pid: data.pid);
    },
    "login": (context) {
      return const LoginPage();
    },
    "search": (context) {
      return SearchPage(
        searchWords: ModalRoute.of(context)!.settings.arguments as String,
      );
    },
    "imagePicker": (context) {
      return const ImagePickerRoute();
    },
    "user": (context) {
      return UserVisitor(
          uid: ModalRoute.of(context)!.settings.arguments as String);
    },
    "threadStore": (context) {
      return const ThreadStorePage();
    },
    "viewHistory": (context) {
      return const ViewHistoryPage();
    }
  };
  static const String home = "/";
  static const String forumHome = "forumHome";
  static const String threadPage = "threadPage";
  static const String login = "login";
  static const String search = "search";
  static const String imagePicker = "imagePicker";
  static const String user = "user";
  static const String threadStore = "threadStore";
  static const String viewHistory = "viewHistory";
}

///贴界面路由传值
class ThreadPageRouterData {
  ///帖子的id
  String kz;

  ///不需要情况下填null
  String? pid;
  // bool isStored;
  ThreadPageRouterData({required this.kz, required this.pid});
}
