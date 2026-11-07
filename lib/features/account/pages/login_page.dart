// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/features/forum/state/forum_state.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/core/config/constants.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/account/data/webview_cookie_util.dart';
import 'package:fluttertoast/fluttertoast.dart';

///手机版登录网站的UA,使登录页面进入手机端适配
const String _mobileLoginUA =
    "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36";

///移动版登录页面所在的站点
const String _wapPassportOrigin = "https://wappass.baidu.com";

///登录界面
///全屏WebView打开百度passport网页进行登录(密码登录/短信登录/扫码登录等均由网页自身支持)
///登录成功后从WebView的cookie中读取登录凭证(BDUSS/STOKEN等)保存到应用cookie仓库,完成整个应用的登录
class LoginPage extends StatefulWidget {
  /// 是否为「添加账号」进入。
  ///
  /// 为 true 时先清空系统 WebView 的 cookie；
  /// 登录成功后返回账号面板。
  final bool addAccount;
  final bool relogin;

  const LoginPage({
    super.key,
    this.addAccount = false,
    this.relogin = false,
  });

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late WebViewController _webViewController;
  bool _loading = true;
  //凭证正在保存
  bool _saving = false;
  //凭证已保存完成登录
  bool _saved = false;
  //校验失败提示已经出现过
  bool _failureToastShown = false;
  bool _ready = false;
  bool _tiebaPageLoaded = false;
  late Timer _watchdog;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_mobileLoginUA)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (mounted) {
            setState(() {
              _loading = true;
            });
          }
        },
        onPageFinished: (url) {
          if (Uri.tryParse(url)?.host == 'tieba.baidu.com') {
            _tiebaPageLoaded = true;
          }
          if (mounted) {
            setState(() {
              _loading = false;
            });
          }
          //每次页面加载完成后检查WebView中是否已产生登录凭证
          _trySaveLogin();
        },
      ));
    //按设备分辨率渲染,不允许WebView使用宽屏(桌面)视口进行整体缩放适配
    if (Platform.isAndroid) {
      (_webViewController.platform as AndroidWebViewController)
          .setUseWideViewPort(false);
    }
    _openLoginPage();
    //passport页面登录成功时可能不产生页面跳转(扫描二维码确认登录等场景),定时兜底检查凭证
    _watchdog = Timer.periodic(
        const Duration(seconds: 3), ((timer) => _trySaveLogin()));
  }

  /// 添加账号时先清空 WebView 的百度 cookie，让 passport 重新进入登录流程。
  Future<void> _openLoginPage() async {
    if (widget.addAccount || widget.relogin) {
      await WebviewCookieUtil.clearCookies();
    }
    await _webViewController.loadRequest(Uri.parse(LOGIN_GET_URL));
    _ready = true;
  }

  ///检查系统WebView中是否已产生登录凭证,产生则保存凭证完成登录
  Future<void> _trySaveLogin() async {
    if (!_ready || !_tiebaPageLoaded || _saved || _saving || !mounted) {
      return;
    }
    _saving = true;
    try {
      var cookies = await WebviewCookieUtil.getRawCookies(BAIDU_URL);
      final tiebaCookies =
          await WebviewCookieUtil.getRawCookies('https://tieba.baidu.com');
      //没有BDUSS凭证说明还没登录成功
      if (!(cookies ?? '').contains('BDUSS=') &&
          !(tiebaCookies ?? '').contains('BDUSS=')) {
        return;
      }
      var passportCookies =
          await WebviewCookieUtil.getRawCookies(BAIDU_PASSPORT_URL);
      var wapCookies =
          await WebviewCookieUtil.getRawCookies(_wapPassportOrigin);
      var loginSuccessful = await Global.tiebaAPI.applyWebviewLogin({
        BAIDU_URL: cookies ?? '',
        BAIDU_PASSPORT_URL: passportCookies ?? "",
        _wapPassportOrigin: wapCookies ?? "",
        'https://tieba.baidu.com': tiebaCookies ?? "",
      });
      if (!mounted) {
        return;
      }
      if (loginSuccessful) {
        // 写入 cookie 后旧实例仍保留协议上下文、本人 uid 和关注列表缓存；
        // 这里先从新凭证构造后端，再查询本人信息。
        await Global.reloadTiebaApi(useCachedUid: false);
        final MyUserData userInfo = await Global.tiebaAPI.getMyInfo();
        await AccountStore.rememberLogin(userInfo);
        _saved = true;
        _watchdog.cancel();
        Fluttertoast.showToast(msg: widget.addAccount ? "账号已添加" : "登录成功");
        if (!mounted) {
          return;
        }
        Provider.of<User>(context, listen: false).refreshAccount(force: true);
        // 从设置页 / 账号面板进来时，ForumState 不在当前路由的 Provider 树里；
        // 首页会监听 AccountStore.changes 自行刷新，这里拿不到就跳过。
        try {
          Provider.of<ForumState>(context, listen: false).refresh();
        } catch (_) {}
        if ((widget.addAccount || widget.relogin) &&
            mounted &&
            Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      } else {
        if (!_failureToastShown) {
          _failureToastShown = true;
          Fluttertoast.showToast(msg: "登录凭证校验失败,请在页面中重新登录");
        }
      }
    } catch (_) {
      // 凭证已写入但账号信息未获取成功时，等待下一轮检查重试。
      if (mounted && !_failureToastShown) {
        _failureToastShown = true;
        Fluttertoast.showToast(msg: "账号信息保存失败，请检查网络后重试");
      }
    } finally {
      _saving = false;
    }
  }

  @override
  void dispose() {
    _watchdog.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          //加载进度条
          if (_loading)
            const Positioned(
                top: 0, left: 0, right: 0, child: LinearProgressIndicator())
        ],
      ),
    );
  }
}
