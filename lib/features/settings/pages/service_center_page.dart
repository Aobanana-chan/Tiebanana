import 'package:flutter/material.dart';
import 'package:tiebanana/core/config/constants.dart';
import 'package:tiebanana/app/navigation/link_router.dart';
import 'package:tiebanana/features/browser/pages/in_app_browser_page.dart';

class ServiceCenterPage extends StatelessWidget {
  const ServiceCenterPage({super.key});

  @override
  Widget build(BuildContext context) => InAppBrowserPage(
        initialUrl: SERVICE_CENTER,
        title: '服务中心',
        onNavigation: AppUtil.handleWebViewNavigation,
      );
}
