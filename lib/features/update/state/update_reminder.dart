import 'package:flutter/foundation.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/update/data/semantic_version.dart';
import 'package:tiebanana/features/update/data/version.dart';

/// 更新入口共享的未读状态；弹过窗不等于看过更新页。
class UpdateReminder {
  UpdateReminder._();

  static const String _legacyReminderKey = 'latestAutoUpdateReminder';
  static const String _promptedVersionsKey = 'promptedUpdateVersions';
  static const String _detectedVersionKey = 'detectedUpdateVersion';
  static const String _viewedVersionKey = 'viewedUpdateVersion';
  static const String _ignoredVersionKey = 'ignoredUpdateVersion';

  static final ValueNotifier<bool> _showDot = ValueNotifier<bool>(false);
  static ValueListenable<bool> get showDot => _showDot;
  static String? _detectedVersion;

  /// 下次冷启动检查失败时，仍保留已发现且未读的版本提示。
  static void restore() {
    final String? version = Global.profile.getString(_detectedVersionKey);
    _detectedVersion = Version.isAndroidPlatform &&
            version != null &&
            isNewerVersion(Version.currentVersion, version)
        ? version
        : null;
    refreshDot();
  }

  static bool _isUnread(String version) =>
      version != Global.profile.getString(_ignoredVersionKey) &&
      version != Global.profile.getString(_viewedVersionKey);

  static Set<String> _promptedVersions() {
    final String? legacyReminder = Global.profile.getString(_legacyReminderKey);
    return <String>{
      ...?Global.profile.getStringList(_promptedVersionsKey),
      // 旧格式为「日期:版本」，迁移时不再按日期判断。
      if (legacyReminder != null) legacyReminder.split(':').last,
    };
  }

  static bool shouldPrompt(String version) =>
      _isUnread(version) && !_promptedVersions().contains(version);

  static Future<void> markPrompted(String version) async {
    await Global.profile.setStringList(
      _promptedVersionsKey,
      (_promptedVersions()..add(version)).toList(),
    );
  }

  static void refreshDot() {
    final String? version = _detectedVersion;
    _showDot.value = Global.setting.checkUpdateAutomaticlly &&
        version != null &&
        _isUnread(version);
  }

  static Future<void> recordCheck(UpdateCheckResult result) async {
    if (!Version.isAndroidPlatform || result.failed) return;
    final String? version = result.hasUpdate ? result.latestVersion : null;
    _detectedVersion = version;
    refreshDot();
    if (version == null) {
      await Global.profile.remove(_detectedVersionKey);
    } else {
      await Global.profile.setString(_detectedVersionKey, version);
    }
  }

  static Future<void> markViewed(UpdateCheckResult result) async {
    if (!Version.isAndroidPlatform || result.failed) return;
    final String? version = result.hasUpdate ? result.latestVersion : null;
    await Future.wait(<Future<void>>[
      // 先同步更新 SharedPreferences 的内存值，再刷新红点。
      if (version != null) Global.profile.setString(_viewedVersionKey, version),
      recordCheck(result),
    ]);
  }

  static Future<void> ignore(String version) async {
    final Future<bool> write =
        Global.profile.setString(_ignoredVersionKey, version);
    refreshDot();
    await write;
  }
}
