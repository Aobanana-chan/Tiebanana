/// 与发布 tag 对齐的容错版本解析。
///
/// 支持 `v0.2.1`、`0.1`（按 `0.1.0` 处理）、`1.2.3-beta.1+build` 这类写法。
/// 用于比较线上版本是否比当前版本新。
/// - 解析失败返回 null，由调用方决定是否提示；
/// - 缺少的段按 0 补齐，兼容 `v0.1` 这类历史 tag。
class AppSemanticVersion implements Comparable<AppSemanticVersion> {
  AppSemanticVersion._(this.parts, this.preRelease);

  /// 主版本号，至少三段。
  final List<int> parts;

  /// 预发布标识（`-beta.1` → `['beta', '1']`），空表示正式版。
  final List<String> preRelease;

  static final RegExp _pattern = RegExp(
    r'^[vV]?(\d+(?:\.\d+)*)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$',
  );

  static AppSemanticVersion? tryParse(String raw) {
    final Match? match = _pattern.firstMatch(raw.trim());
    if (match == null) {
      return null;
    }

    final List<int> core = <int>[];
    for (final String segment in match.group(1)!.split('.')) {
      final int? number = int.tryParse(segment);
      if (number == null) {
        return null;
      }
      core.add(number);
    }
    // 统一按三段比较：0.1 == 0.1.0。
    while (core.length < 3) {
      core.add(0);
    }

    final String? pre = match.group(2);
    final List<String> preRelease =
        pre == null || pre.isEmpty ? const <String>[] : pre.split('.');
    return AppSemanticVersion._(
      List<int>.unmodifiable(core),
      List<String>.unmodifiable(preRelease),
    );
  }

  @override
  int compareTo(AppSemanticVersion other) {
    final int length =
        parts.length > other.parts.length ? parts.length : other.parts.length;
    for (int i = 0; i < length; i++) {
      final int a = i < parts.length ? parts[i] : 0;
      final int b = i < other.parts.length ? other.parts[i] : 0;
      if (a != b) {
        return a.compareTo(b);
      }
    }

    // 同一主版本下，正式版高于任何预发布版（semver 规则）。
    if (preRelease.isEmpty && other.preRelease.isNotEmpty) {
      return 1;
    }
    if (preRelease.isNotEmpty && other.preRelease.isEmpty) {
      return -1;
    }

    final int preLength = preRelease.length < other.preRelease.length
        ? preRelease.length
        : other.preRelease.length;
    for (int i = 0; i < preLength; i++) {
      final String a = preRelease[i];
      final String b = other.preRelease[i];
      final int? aNumber = int.tryParse(a);
      final int? bNumber = int.tryParse(b);
      final int result;
      if (aNumber != null && bNumber != null) {
        result = aNumber.compareTo(bNumber);
      } else if (aNumber != null) {
        result = -1; // 数字标识优先级低于字母标识
      } else if (bNumber != null) {
        result = 1;
      } else {
        result = a.compareTo(b);
      }
      if (result != 0) {
        return result;
      }
    }
    return preRelease.length.compareTo(other.preRelease.length);
  }

  @override
  String toString() {
    final String core = parts.join('.');
    return preRelease.isEmpty ? core : '$core-${preRelease.join('.')}';
  }
}

/// [latest] 是否严格新于 [current]。
///
/// 任一侧无法解析时返回 `false`，防止误报更新。
bool isNewerVersion(String current, String latest) {
  final AppSemanticVersion? currentVersion =
      AppSemanticVersion.tryParse(current);
  final AppSemanticVersion? latestVersion = AppSemanticVersion.tryParse(latest);
  if (currentVersion == null || latestVersion == null) {
    return false;
  }
  return latestVersion.compareTo(currentVersion) > 0;
}
