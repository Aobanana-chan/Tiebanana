import 'package:tiebanana/features/compose/models/thread_compose_route_data.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/features/settings/pages/about_page.dart';
import 'package:tiebanana/features/settings/pages/app_setting_page.dart';
import 'package:tiebanana/features/update/pages/app_update_page.dart';
import 'package:tiebanana/features/forum/pages/forum_home_page.dart';
import 'package:tiebanana/features/forum/pages/forum_broadcast_page.dart';
import 'package:tiebanana/features/forum/pages/forum_search_page.dart';
import 'package:tiebanana/features/message/pages/broadcast_feed_page.dart';
import 'package:tiebanana/features/home/pages/home_page.dart';
import 'package:tiebanana/features/media/pages/image_picker_page.dart';
import 'package:tiebanana/features/message/models/chat_route_data.dart';
import 'package:tiebanana/features/message/pages/chat_page.dart';
import 'package:tiebanana/features/account/pages/login_page.dart';
import 'package:tiebanana/features/profile/pages/profile_edit_page.dart';
import 'package:tiebanana/features/search/pages/search_page.dart';
import 'package:tiebanana/features/settings/pages/service_center_page.dart';
import 'package:tiebanana/features/settings/pages/theme_change_page.dart';
import 'package:tiebanana/features/thread/pages/thread_page.dart';
import 'package:tiebanana/features/compose/pages/thread_compose_page.dart';
import 'package:tiebanana/features/favorites/pages/thread_store_page.dart';
import 'package:tiebanana/features/topic/pages/topic_page.dart';
import 'package:tiebanana/features/profile/pages/user_profile_page.dart';
import 'package:tiebanana/features/history/pages/view_history_page.dart';

import 'route_names.dart';

/// 页面装配表；功能组件只引用 route_names.dart。
abstract class AppRouter {
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
    "threadCompose": (context) {
      final data =
          ModalRoute.of(context)!.settings.arguments as ThreadComposeRouteData;
      return ThreadComposePage(
        fid: data.fid,
        forumName: data.forumName,
        topicId: data.topicId,
        topicName: data.topicName,
      );
    },
    "topic": (context) {
      final data =
          ModalRoute.of(context)!.settings.arguments as TopicPageRouterData;
      return TopicPageRoute(data: data);
    },
    "login": (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      // arguments == true 表示「添加账号」：保留当前账号的凭证，登录后返回。
      return LoginPage(
        addAccount: args == true,
        relogin: args is LoginRouteOptions && args.relogin,
      );
    },
    "search": (context) {
      return SearchPage(
        searchWords: ModalRoute.of(context)!.settings.arguments as String,
      );
    },
    "forumSearch": (context) {
      return ForumSearchPage(
        forumName: ModalRoute.of(context)!.settings.arguments as String,
      );
    },
    "forumBroadcast": (context) {
      final data =
          ModalRoute.of(context)!.settings.arguments as ForumBroadcastRouteData;
      return ForumBroadcastPage(data: data);
    },
    "broadcastFeed": (context) => const BroadcastFeedPage(),
    "imagePicker": (context) {
      return const ImagePickerRoute();
    },
    "user": (context) {
      return UserVisitor(
          uid: ModalRoute.of(context)!.settings.arguments as String);
    },
    "chat": (context) {
      final data = ModalRoute.of(context)!.settings.arguments as ChatRouteData;
      return ChatPage(data: data);
    },
    "profileEdit": (context) => const ProfileEditPage(),
    "threadStore": (context) {
      return const ThreadStorePageRoute();
    },
    "viewHistory": (context) {
      return const ViewHistoryPage();
    },
    "themeChange": (context) {
      return const ThemeChangePage();
    },
    "serviceCenter": (context) {
      return const ServiceCenterPage();
    },
    "appSetting": (context) {
      return const AppSettingPage();
    },
    "about": (context) {
      return const AboutPage();
    },
    "appUpdate": (context) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      return UpdatePage(
        initialPlatform: args is String ? args : null,
      );
    }
  };
}
