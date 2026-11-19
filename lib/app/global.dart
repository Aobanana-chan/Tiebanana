import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tiebanana/shared/widgets/app_toast.dart';
import 'package:json5/json5.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/backend.dart';
import 'package:tiebanana/features/history/data/dao_api.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/features/update/data/version.dart';
import 'package:tiebanana/features/account/data/credential_store.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/features/account/state/login_failure.dart';
import 'package:tiebanana/features/thread/data/thread_cache.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';

/// 单吧签到结果事件：吧名 + 是否成功。
class SignForumResult {
  const SignForumResult(this.forumName, this.success);

  final String forumName;
  final bool success;
}

/// 签到结果广播。
///
/// 后端每签完一个吧就 [emit] 一次，首页据此原地更新「已签到」标识。
class SignEventBus extends ChangeNotifier {
  SignForumResult? last;

  void emit(String forumName, bool success) {
    last = SignForumResult(forumName, success);
    notifyListeners();
  }
}

class Global {
  static final loginFailures = LoginFailureController();
  //网络状态
  static List<ConnectivityResult> netStatus = [ConnectivityResult.mobile];

  /// 单吧签到结果广播（见 [SignEventBus]）。
  static final SignEventBus signEvents = SignEventBus();

  /// 贴吧后端：界面与业务的唯一入口（具体实现见 `lib/app/backend.dart`）。
  ///
  /// 宿主只提供凭证存储（cookie 目录 + KeyValueStore）与副作用回调，
  /// 在 [init] 中构建（`Global.init()` 之后才可访问）。
  static late TiebaApi tiebaAPI;

  /// 应用文档目录（`<documents>`），多账号的 cookie 快照放在它下面。
  static String? documentsPath;

  /// 当前账号使用的 cookie 仓库。切换账号时会整份替换这个目录。
  static String get cookieStoragePath => '$documentsPath/cookies/';

  // 可选的主题列表见 lib/shared/theme/tiebanana_seed.dart 的 tiebananaSeeds

  //APP配置信息
  static late SharedPreferences profile;
  static late APPSetting setting;
  static FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  //DAOAPI
  static DAOAPI daoapi = DAOAPI();
  static ThreadCache threadCache = ThreadCache();

  //Global类初始化
  static Future init() async {
    // 版本号来自构建产物（pubspec / --build-name），先读出来供界面与更新检查使用。
    await Version.init();
    profile = await SharedPreferences.getInstance();
    var settingload = profile.getString("APPSetting");

    //读取APP设置
    if (settingload == null) {
      //没有存储过的设置就设置默认设置
      setting = APPSetting.fromJson(defaultAPPSetting);
    } else {
      setting = APPSetting.fromJson(json5Decode(settingload));
    }

    await initializeNotifications();

    //初始化贴吧后端：cookie 目录与设备指纹存储由宿主提供，
    //提示/通知等副作用以回调注入（契约包不含 UI 依赖）。
    final documents = await getApplicationDocumentsDirectory();
    documentsPath = documents.path;
    await threadCache.init(documents.path);
    tiebaAPI = _createTiebaApi();

    await tiebaAPI.init();
    await refreshLoggedInUser();

    //初始化数据库
    await daoapi.init();
  }

  /// 初始化系统通知；拒绝授权或通知服务不可用不阻止应用启动。
  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(
        requestBadgePermission: false,
        requestSoundPermission: false,
        defaultPresentBadge: false,
        defaultPresentSound: false,
      ),
      windows: WindowsInitializationSettings(
        appName: 'Tiebanana',
        appUserModelId: 'Aobanana.Tiebanana',
        guid: 'd083f4f1-0ca0-4744-8baf-698421ea52b7',
      ),
    );
    try {
      await localNotifications.initialize(settings: initializationSettings);
    } catch (error, stack) {
      // 系统通知不可用不应阻止浏览与登录。
      AppLog.shared.error('notifications.initialize_failed', error, stack);
    }
  }

  /// 仅 Debug 且显式开启抓包时，读取当前平台的编译期代理地址。
  static String? get _debugProxy {
    const captureEnabled = bool.fromEnvironment('TIEBA_CAPTURE');
    if (!kDebugMode || !captureEnabled) return null;

    const androidProxy = String.fromEnvironment('TIEBA_PROXY_ANDROID');
    const windowsProxy = String.fromEnvironment('TIEBA_PROXY_WINDOWS');
    final address = switch (defaultTargetPlatform) {
      TargetPlatform.android => androidProxy.trim(),
      TargetPlatform.windows => windowsProxy.trim(),
      _ => '',
    };
    return address.isEmpty ? null : 'PROXY $address';
  }

  /// 覆盖 IM WebSocket 地址（编译期）。
  ///
  /// 默认使用官方 8000 端口的明文 WebSocket；该服务在 80/443 也接受
  /// `ws://`（但不支持 `wss://` TLS）。部分网络会阻断 8000，可改传：
  /// `--dart-define=TIEBA_IM_URL=ws://im.tieba.baidu.com:443`
  static String? get _imSocketUrl {
    const String url = String.fromEnvironment('TIEBA_IM_URL');
    final String value = url.trim();
    return value.isEmpty ? null : value;
  }

  /// 按当前设置构造后端实例。切换账号后会重新调用它（cookie 仓库已替换）。
  static TiebaApi _createTiebaApi({bool useCachedUid = true}) {
    loginFailures.reset();
    return createTiebaApi(
      host: TiebaApiHost(
        cookieStoragePath: cookieStoragePath,
        deviceIdStore: SharedPreferencesKeyValueStore(profile),
        screen: _screenInfo,
        onMessage: (msg) => Fluttertoast.showToast(msg: msg),
        onSignProgress: (current, total, title, body) =>
            showNotification(0, title, body),
        onSignProgressDone: () => localNotifications.cancel(id: 0),
        onForumSigned: (forumName, success) =>
            signEvents.emit(forumName, success),
      ),
      signUpperHex: () => setting.protocolSignUpperHex ?? true,
      enableSig: () => setting.protocolEnableSig ?? false,
      debugProxy: _debugProxy,
      imSocketUrl: _imSocketUrl,
      accountUid:
          useCachedUid ? int.tryParse(AccountStore.currentUid ?? '') : null,
      onLoginFailure: loginFailures.report,
      onDiagnostic: AppLog.shared.protocolException,
    );
  }

  /// 重建后端实例并加载当前 cookie 仓库。
  ///
  /// 多账号切换时，宿主已经把目标账号的 cookie 快照还原到 [cookieStoragePath]，
  /// 所以这里只需要换一个新实例，让它重新读取凭证。
  static Future<void> reloadTiebaApi({bool useCachedUid = true}) async {
    tiebaAPI = _createTiebaApi(useCachedUid: useCachedUid);
    await tiebaAPI.init();
  }

  /// 刷新账号元数据；服务端拒绝登录或离线时保留本地凭证。
  /// 后端和数据库的基础初始化错误仍交由启动页处理。
  static Future<void> refreshLoggedInUser() async {
    if (!tiebaAPI.isLogin) return;
    try {
      final MyUserData userInfo = await tiebaAPI.getMyInfo();
      await profile.setString("uid", userInfo.id.toString());
      await AccountStore.rememberLogin(userInfo);
    } catch (error, stackTrace) {
      AppLog.shared.error('account.refresh_failed', error, stackTrace);
      debugPrint('启动时刷新账号信息失败，保留本地账号：$error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// 屏幕信息（新协议 CommonReq 用）。
  static ScreenInfo _screenInfo() {
    try {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final dpr = view.devicePixelRatio;
      final size = view.physicalSize;
      return ScreenInfo(size.width.round(), size.height.round(), dpr);
    } catch (_) {
      return const ScreenInfo(1080, 2340, 2.75);
    }
  }

  ///保持用户APP设置
  static void saveProfile() {
    profile.setString("APPSetting", json5Encode(setting.toJson()));
  }

  ///显示通知
  static Future<void> showNotification(
      int id, String title, String body) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(id.toString(), 'Tiebanana',
            channelDescription: 'Tiebanana notification', playSound: false);

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        presentBanner: true,
        presentList: true,
      ),
      windows: const WindowsNotificationDetails(),
    );

    await Global.localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }
}
