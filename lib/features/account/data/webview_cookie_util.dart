import 'dart:io';

import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

///系统WebView的cookie工具类
///用于读取WebView中百度passport网页登录产生的登录凭证(BDUSS/STOKEN等)
abstract class WebviewCookieUtil {
  static const MethodChannel _channel =
      MethodChannel("tiebanana/webview_cookies");

  ///清空系统WebView的cookie库，添加账号前调用。
  static Future<void> clearCookies() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>("clearCookies");
        return;
      } on PlatformException {
        // 原生通道不可用时继续走下面的兜底实现。
      }
    }
    try {
      await WebViewCookieManager().clearCookies();
    } catch (_) {
      // 清理失败时继续加载登录页，用户可在页面内手动退出。
    }
  }

  ///读取WebView中指定站点的cookie串,形如"BDUSS=xx; yy=zz"
  ///
  ///无cookie或平台不支持时返回null
  static Future<String?> getRawCookies(String url) async {
    if (Platform.isAndroid) {
      //Android端走原生android.webkit.CookieManager读取,
      //与webview_flutter的WebView共享同一个cookie库,能读到HttpOnly的凭证,
      //且可以得到原始cookie串,避免webview_flutter解析时把含"="的cookie值截断
      try {
        return await _channel.invokeMethod<String>(
          "getCookies",
          {"url": url},
        );
      } on PlatformException {
        return null;
      }
    }
    //其他平台兜底使用webview_flutter自带的cookie管理器
    try {
      var cookies =
          await WebViewCookieManager().getCookies(domain: Uri.parse(url));
      if (cookies.isEmpty) {
        return null;
      }
      return cookies.map((e) => "${e.name}=${e.value}").join("; ");
    } catch (e) {
      return null;
    }
  }
}
