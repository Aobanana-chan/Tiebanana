import 'package:flutter/material.dart';
import 'package:tiebanana/routes/ForumHomePage.dart';
import 'package:tiebanana/routes/HomePage.dart';
import 'package:tiebanana/routes/ImagePicker.dart';
import 'package:tiebanana/routes/Login.dart';
import 'package:tiebanana/routes/Search.dart';
import 'package:tiebanana/routes/ThreadPage.dart';

///命名路由表
class PageRouter {
  static Map<String, WidgetBuilder> routes = {
    "/": (builder) => const HomePage(),
    "forumHome": (builder) {
      return ForumHomePage(
        kw: ModalRoute.of(builder)!.settings.arguments as String,
      );
    },
    "threadPage": (builder) {
      return ThreadPageRoute(
        kz: ModalRoute.of(builder)!.settings.arguments as String,
      );
    },
    "login": (builder) {
      return const LoginPage();
    },
    "search": (builder) {
      return SearchPage(
        searchWords: ModalRoute.of(builder)!.settings.arguments as String,
      );
    },
    "imagePicker": (builder) {
      return const ImagePickerRoute();
    }
  };
  static String home = "/";
  static String forumHome = "forumHome";
  static String threadPage = "threadPage";
  static String login = "login";
  static String search = "search";
  static String imagePicker = "imagePicker";
}
