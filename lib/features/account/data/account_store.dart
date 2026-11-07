/// 本机多账号仓库：账号元数据 + 每个账号独立的 cookie 快照。
///
/// 协议层仍然只有一个 cookie 仓库（`<documents>/cookies/`），所以这里在
/// **账号切换时把当前仓库整份快照到 `<documents>/accounts/<uid>/cookies/`**，
/// 切回来时再整份还原，两个账号的凭证各自独立。
///
/// 账号列表与当前账号都落在 [SharedPreferences]：
/// - `tiebanana.accounts.v1`：账号元数据（uid / 昵称 / 头像 / 缓存的未读数）；
/// - `uid`：当前账号，沿用旧版本已有的键，老用户的个人页和收藏页继续可读。
library;

import 'dart:convert';
import 'dart:io';

import 'package:tiebanana/core/diagnostics/app_log.dart';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/account/data/webview_cookie_util.dart';

/// 一个已登录过的本机账号。
class TiebananaAccount {
  const TiebananaAccount({
    required this.uid,
    required this.name,
    required this.portraitUrl,
    this.unread = 0,
  });

  final String uid;

  /// 昵称（优先 `name_show`，没有时退回 `name`）。
  final String name;

  final String portraitUrl;

  /// 最近一次在消息页看到的未读数，切换账号时用于展示。
  final int unread;

  TiebananaAccount copyWith({
    String? name,
    String? portraitUrl,
    int? unread,
  }) {
    return TiebananaAccount(
      uid: uid,
      name: name ?? this.name,
      portraitUrl: portraitUrl ?? this.portraitUrl,
      unread: unread ?? this.unread,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'name': name,
        'portraitUrl': portraitUrl,
        'unread': unread,
      };

  factory TiebananaAccount.fromJson(Map<String, dynamic> json) {
    return TiebananaAccount(
      uid: '${json['uid'] ?? ''}',
      name: '${json['name'] ?? ''}',
      portraitUrl: '${json['portraitUrl'] ?? ''}',
      unread: int.tryParse('${json['unread'] ?? 0}') ?? 0,
    );
  }
}

/// 账号仓库。所有方法都只依赖 [Global.profile] 与文档目录，界面直接调用。
class AccountStore {
  AccountStore._();

  /// 账号列表的存储键。带版本号，字段变化时与旧数据区分。
  static const String accountsKey = 'tiebanana.accounts.v1';

  /// 当前账号 uid。沿用旧键 `uid`（个人页 / 收藏页都在读它）。
  static const String currentUidKey = 'uid';

  /// 账号身份变化（登录、切换、退出、移除）时 +1。
  ///
  /// 首页用它刷新「我关注的吧」；账号面板本身在打开时重新读取列表。
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static List<TiebananaAccount> get accounts {
    final String? raw = Global.profile.getString(accountsKey);
    if (raw == null || raw.isEmpty) {
      return <TiebananaAccount>[];
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <TiebananaAccount>[];
      }
      return <TiebananaAccount>[
        for (final Object? item in decoded)
          if (item is Map)
            TiebananaAccount.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return <TiebananaAccount>[];
    }
  }

  static String? get currentUid {
    final String? uid = Global.profile.getString(currentUidKey);
    if (uid == null || uid.isEmpty) {
      return null;
    }
    return uid;
  }

  static TiebananaAccount? get current {
    final String? uid = currentUid;
    if (uid == null) {
      return null;
    }
    for (final TiebananaAccount account in accounts) {
      if (account.uid == uid) {
        return account;
      }
    }
    return null;
  }

  static void _save(List<TiebananaAccount> list) {
    Global.profile.setString(
      accountsKey,
      jsonEncode(<Map<String, dynamic>>[
        for (final TiebananaAccount account in list) account.toJson(),
      ]),
    );
  }

  /// 登录成功 / 启动时同步当前账号：更新元数据并快照当前 cookie。
  static Future<void> rememberLogin(MyUserData info,
      {bool notify = true}) async {
    final int rawUid = info.id > 0 ? info.id : info.uid;
    final String uid = '$rawUid';
    if (rawUid <= 0 || uid.isEmpty) {
      return;
    }
    final String name = info.nameShow.isNotEmpty ? info.nameShow : info.name;
    final List<TiebananaAccount> list = accounts;
    final int index = list.indexWhere((TiebananaAccount e) => e.uid == uid);
    final TiebananaAccount account = TiebananaAccount(
      uid: uid,
      name: name,
      portraitUrl: info.portraitUrl,
      // 同一个账号重新登录时保留上一次缓存的未读数。
      unread: index >= 0 ? list[index].unread : 0,
    );
    if (index >= 0) {
      list[index] = account;
    } else {
      list.add(account);
    }
    _save(list);
    Global.profile.setString(currentUidKey, uid);
    await _snapshotActiveCookies(uid);
    if (notify) {
      changes.value++;
    }
  }

  /// 主动把当前 cookie 落一份快照。
  ///
  /// 「添加账号」会清空并覆盖当前 cookie 仓库，进入登录页之前先调用一次，
  /// 把当前账号的凭证更新为最新快照。
  static Future<void> snapshotCurrent() async {
    final String? uid = currentUid;
    if (uid != null) {
      await _snapshotActiveCookies(uid);
    }
  }

  /// 切换账号：先快照当前账号，再还原目标账号的 cookie 并重建后端。
  static Future<void> switchTo(String uid) async {
    final String? previous = currentUid;
    if (uid == previous) {
      return;
    }
    if (!accounts.any((TiebananaAccount e) => e.uid == uid)) {
      throw StateError('账号不存在');
    }
    if (previous != null) {
      await _snapshotActiveCookies(previous);
    }
    try {
      await _restoreAccountCookies(uid);
      Global.profile.setString(currentUidKey, uid);
      await Global.reloadTiebaApi();
      if (!Global.tiebaAPI.isLogin) {
        throw StateError('该账号的登录凭证已失效');
      }
    } catch (error, stack) {
      AppLog.shared.error('account.switch_failed', error, stack);
      // 目标账号还原失败时回到原来的账号。
      if (previous != null) {
        try {
          await _restoreAccountCookies(previous);
          Global.profile.setString(currentUidKey, previous);
          await Global.reloadTiebaApi();
        } catch (error, stack) {
          AppLog.shared.error('account.rollback_failed', error, stack);
          // 还原也失败时保持现状，由界面提示重新登录。
        }
      }
      rethrow;
    }
    // 账号昵称 / 头像已经有本地缓存，切换不等待网络；下次打开个人页或
    // 重新登录时再刷新。
    changes.value++;
  }

  /// 退出当前账号：删除它的 cookie 快照，有其它账号时自动切到第一个。
  static Future<void> logoutCurrent() async {
    final String? uid = currentUid;
    final List<TiebananaAccount> remaining = <TiebananaAccount>[
      for (final TiebananaAccount account in accounts)
        if (account.uid != uid) account,
    ];
    if (uid != null) {
      _save(remaining);
      await _deleteAccountCookies(uid);
    }
    // WebView 与协议端各有独立的 cookie 仓库，进入登录页前同时清理两处。
    await WebviewCookieUtil.clearCookies();
    if (Global.documentsPath != null) {
      // TiebaApi.logout 返回 void，内部异步删除无法等待；
      // 这里由宿主等待删除落盘后再重建实例。
      await PersistCookieJar(storage: FileStorage(_activeCookiePath))
          .deleteAll();
    } else {
      Global.tiebaAPI.logout();
    }
    Global.profile.remove(currentUidKey);

    if (remaining.isNotEmpty && Global.documentsPath != null) {
      final String next = remaining.first.uid;
      await _restoreAccountCookies(next);
      Global.profile.setString(currentUidKey, next);
      await Global.reloadTiebaApi();
    } else if (Global.documentsPath != null) {
      await Global.reloadTiebaApi();
    }
    changes.value++;
  }

  /// 移除一个账号。当前账号被移除时等价于退出当前账号。
  static Future<void> removeAccount(String uid) async {
    if (uid == currentUid) {
      await logoutCurrent();
      return;
    }
    final List<TiebananaAccount> remaining = <TiebananaAccount>[
      for (final TiebananaAccount account in accounts)
        if (account.uid != uid) account,
    ];
    _save(remaining);
    await _deleteAccountCookies(uid);
    // 删除其他账号时登录态不变，首页无需重建。
  }

  /// 消息页刷新后缓存当前账号的未读数，供切换面板展示。
  static void updateCurrentUnread(int unread) {
    final String? uid = currentUid;
    if (uid == null) {
      return;
    }
    final int value = unread < 0 ? 0 : unread;
    final List<TiebananaAccount> list = accounts;
    final int index = list.indexWhere((TiebananaAccount e) => e.uid == uid);
    if (index < 0 || list[index].unread == value) {
      return;
    }
    list[index] = list[index].copyWith(unread: value);
    _save(list);
  }

  // ---------------------------------------------------------------- cookie

  static String get _activeCookiePath => Global.cookieStoragePath;

  static String _accountCookiePath(String uid) =>
      '${Global.documentsPath}/accounts/$uid/cookies/';

  /// 把当前 cookie 仓库整份复制到账号快照。
  ///
  /// 没有文档目录（例如单元测试）或仓库尚未建立时直接跳过。
  static Future<void> _snapshotActiveCookies(String uid) async {
    final String? documentsPath = Global.documentsPath;
    if (documentsPath == null || uid.isEmpty) {
      return;
    }
    try {
      await _copyDirectory(
        Directory(_activeCookiePath),
        Directory(_accountCookiePath(uid)),
      );
    } catch (_) {
      // 快照失败不阻塞登录；下次启动 / 切换前还会再尝试一次。
    }
  }

  /// 用账号快照覆盖当前 cookie 仓库。
  static Future<void> _restoreAccountCookies(String uid) async {
    final Directory source = Directory(_accountCookiePath(uid));
    if (!source.existsSync()) {
      throw StateError('账号凭证不存在');
    }
    await _copyDirectory(source, Directory(_activeCookiePath));
  }

  static Future<void> _deleteAccountCookies(String uid) async {
    if (Global.documentsPath == null) {
      return;
    }
    try {
      final Directory dir = Directory(_accountCookiePath(uid));
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  static Future<void> _copyDirectory(Directory from, Directory to) async {
    if (!from.existsSync()) {
      return;
    }
    if (to.existsSync()) {
      await to.delete(recursive: true);
    }
    await to.create(recursive: true);
    final String separator = Platform.pathSeparator;
    await for (final FileSystemEntity entity in from.list(recursive: false)) {
      // Directory 的 URI 以 / 结尾，这里取最后一个非空路径段，
      // 保留 cookie_jar 的 ie0_ps1 子目录结构。
      final String name = entity.uri.pathSegments
          .lastWhere((String segment) => segment.isNotEmpty);
      final String target = '${to.path}$separator$name';
      if (entity is Directory) {
        await _copyDirectory(Directory(entity.path), Directory(target));
      } else if (entity is File) {
        await entity.copy(target);
      }
    }
  }
}
