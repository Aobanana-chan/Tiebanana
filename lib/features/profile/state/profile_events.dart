import 'dart:async';

import 'package:flutter/foundation.dart';

/// 只广播服务端已接受的资料修改，让已打开的个人页重新拉取真实资料。
class ProfileEvents extends ChangeNotifier {
  String? uid;
  final Map<String, int> _avatarVersions = {};
  final Map<String, Uint8List> _avatarPreviews = {};
  final Map<String, List<Timer>> _avatarRefreshes = {};
  final Map<String, List<Timer>> _profileRefreshes = {};

  /// 资料修改被接受后，按 2/5/15/60/180 秒补读服务端数据。
  void profileSaved(String userId) {
    clearProfileRefresh(userId);
    saved(userId);
    _profileRefreshes[userId] = [
      for (final seconds in [2, 5, 15, 60, 180])
        Timer(Duration(seconds: seconds), () => saved(userId)),
    ];
  }

  void clearProfileRefresh(String userId) {
    for (final timer in _profileRefreshes.remove(userId) ?? <Timer>[]) {
      timer.cancel();
    }
  }

  /// 上传接口已接受的本地头像预览。
  Uint8List? avatarPreview(String userId) => _avatarPreviews[userId];

  /// 为头像 URL 追加版本参数，让客户端重新请求图片。
  String avatarUrl(String userId, String url) {
    final version = _avatarVersions[userId];
    if (version == null || url.isEmpty) return url;
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return url;
    }
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      '_avatar_v': '$version',
    }).toString();
  }

  void avatarSaved(String userId, {Uint8List? preview}) {
    clearAvatar(userId);
    if (preview != null) _avatarPreviews[userId] = Uint8List.fromList(preview);
    _avatarVersions[userId] = DateTime.now().microsecondsSinceEpoch;
    saved(userId);
    // 首次读取可能早于 CDN 更新，之后定时补发读取通知。
    if (preview != null) {
      _avatarRefreshes[userId] = [
        for (final seconds in [2, 5, 15])
          Timer(Duration(seconds: seconds), () {
            _avatarVersions[userId] = DateTime.now().microsecondsSinceEpoch;
            saved(userId);
          }),
      ];
    }
  }

  void clearAvatar(String userId) {
    for (final timer in _avatarRefreshes.remove(userId) ?? <Timer>[]) {
      timer.cancel();
    }
    _avatarPreviews.remove(userId);
    _avatarVersions.remove(userId);
  }

  @override
  void dispose() {
    for (final userId in _profileRefreshes.keys.toList()) {
      clearProfileRefresh(userId);
    }
    for (final userId in _avatarRefreshes.keys.toList()) {
      clearAvatar(userId);
    }
    super.dispose();
  }

  void saved(String userId) {
    uid = userId;
    notifyListeners();
  }
}

final ProfileEvents profileEvents = ProfileEvents();
