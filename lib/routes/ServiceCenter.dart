import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/Util/AppUtil.dart';
import 'package:webview_flutter/webview_flutter.dart';

///服务中心页面~~官方摆烂系列~~
///由一个webview实现
class ServiceCenterPage extends StatefulWidget {
  const ServiceCenterPage({Key? key}) : super(key: key);

  @override
  State<ServiceCenterPage> createState() => _ServiceCenterPageState();
}

class _ServiceCenterPageState extends State<ServiceCenterPage> {
  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) {
      WebView.platform = AndroidWebView();
    }
  }

  // Future<List<WebViewCookie>> setCookie() async {
  //   var jar = Global.tiebaAPI.cookieJar;
  //   var cookies = await jar.loadForRequest(Uri.parse(SERVICE_CENTER));
  //   cookies.addAll(
  //       await jar.loadForRequest(Uri.parse("http://c.tieba.baidu.com/")));
  //   cookies.addAll(await jar.loadForRequest(Uri.parse(BAIDU_PASSPORT_URL)));
  //   cookies.addAll(await jar.loadForRequest(Uri.parse(BAIDU_URL)));
  //   List<WebViewCookie> list = [];
  //   list = cookies
  //       .map((e) => WebViewCookie(
  //           name: e.name,
  //           value: e.value,
  //           // domain: Uri.parse(SERVICE_CENTER).host,
  //           domain: e.domain ?? "",
  //           path: e.path ?? "/"))
  //       .toList();

  //   return list;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("服务中心")),
        body: WebView(
          // initialCookies: data,
          backgroundColor: Colors.white,
          initialUrl: SERVICE_CENTER,
          javascriptMode: JavascriptMode.unrestricted,
          navigationDelegate: (request) async {
            if (await AppUtil.urlRoute(mounted, context, request.url)) {
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        )

        //  FutureBuilder(
        //   future: setCookie(),
        //   initialData: null,
        //   builder: (BuildContext context, AsyncSnapshot snapshot) {
        //     if (snapshot.hasData) {
        //       var data = snapshot.data as List<WebViewCookie>;
        //       return WebView(
        //         initialCookies: data,
        //         initialUrl: SERVICE_CENTER,
        //         javascriptMode: JavascriptMode.unrestricted,
        //       );
        //     } else {
        //       return Container(
        //         color: Colors.white,
        //       );
        //     }
        //   },
        // ),
        );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
