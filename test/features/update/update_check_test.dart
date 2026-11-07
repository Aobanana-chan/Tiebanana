import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/features/update/data/github_get_latest_version.dart';
import 'package:tiebanana/features/update/data/semantic_version.dart';
import 'package:tiebanana/features/update/data/version.dart';

void main() {
  group('版本比较', () {
    test('线上版本更高时提示更新', () {
      expect(isNewerVersion('0.2.1', 'v0.2.2'), isTrue);
      expect(isNewerVersion('0.1', 'v0.2.0'), isTrue);
    });

    test('同版本、旧版本和构建元数据不提示更新', () {
      expect(isNewerVersion('0.2.1', 'v0.2.1'), isFalse);
      expect(isNewerVersion('0.2.2', 'v0.2.1'), isFalse);
      expect(isNewerVersion('0.1', 'v0.1.0'), isFalse);
      expect(isNewerVersion('0.2.1+1', 'v0.2.1+2'), isFalse);
    });

    test('预发布版本的优先级低于同号正式版', () {
      expect(isNewerVersion('0.2.1', 'v0.2.2-beta.1'), isTrue);
      expect(isNewerVersion('0.2.2-beta.1', 'v0.2.2'), isTrue);
      expect(isNewerVersion('0.2.2', 'v0.2.2-beta.1'), isFalse);
      expect(isNewerVersion('0.2.2-beta.2', 'v0.2.2-beta.1'), isFalse);
    });

    test('无法解析的版本不误报', () {
      expect(isNewerVersion('0.2.1', 'latest'), isFalse);
      expect(isNewerVersion('', 'v0.2.2'), isFalse);
      expect(isNewerVersion('0.2.1', ''), isFalse);
    });

    test('解析历史两段式 tag', () {
      final AppSemanticVersion? version = AppSemanticVersion.tryParse('v0.1');
      expect(version, isNotNull);
      expect(version!.toString(), '0.1.0');
    });
  });

  group('Release 资产映射', () {
    test('按 ABI 选取 APK，忽略其他文件和空字段', () {
      final Map<String, AndroidUpdateAsset> result =
          mapAndroidAssetsByAbi(<Assets>[
        Assets(
          name: 'app-arm64-v8a-release.apk',
          browserDownloadUrl: 'https://example.com/arm64.apk',
          digest: 'sha256:arm64digest',
        ),
        Assets(
          name: 'app-armeabi-v7a-release.apk',
          browserDownloadUrl: 'https://example.com/v7a.apk',
        ),
        Assets(
          name: 'app-x86_64-release.apk',
          browserDownloadUrl: 'https://example.com/x86_64.apk',
        ),
        Assets(
          name: 'checksums.txt',
          browserDownloadUrl: 'https://example.com/checksums.txt',
        ),
        Assets(name: 'app-universal-release.apk'),
        Assets(browserDownloadUrl: 'https://example.com/no-name.apk'),
      ]);

      expect(
          result.keys,
          containsAll(<String>[
            'arm64-v8a',
            'armeabi-v7a',
            'x86_64',
          ]));
      expect(result['arm64-v8a']!.url, 'https://example.com/arm64.apk');
      expect(result['arm64-v8a']!.sha256, 'arm64digest');
      expect(result['armeabi-v7a']!.sha256, isNull);
      expect(
        result.map((String abi, AndroidUpdateAsset asset) =>
            MapEntry<String, String>(abi, asset.url)),
        <String, String>{
          'arm64-v8a': 'https://example.com/arm64.apk',
          'armeabi-v7a': 'https://example.com/v7a.apk',
          'x86_64': 'https://example.com/x86_64.apk',
        },
      );
    });

    test('没有资产时返回空映射', () {
      expect(mapAndroidAssetsByAbi(null), isEmpty);
      expect(mapAndroidAssetsByAbi(const <Assets>[]), isEmpty);
    });

    test('SHA-256 只接受 sha256 前缀，缺失或其它算法不展示', () {
      expect(
        const AndroidUpdateAsset(
          abi: 'arm64-v8a',
          name: 'app.apk',
          url: 'https://example.com/app.apk',
          digest: 'sha256:ABCDEF',
        ).sha256,
        'ABCDEF',
      );
      expect(
        const AndroidUpdateAsset(
          abi: 'arm64-v8a',
          name: 'app.apk',
          url: 'https://example.com/app.apk',
          digest: 'md5:ABCDEF',
        ).sha256,
        isNull,
      );
      expect(
        const AndroidUpdateAsset(
          abi: 'arm64-v8a',
          name: 'app.apk',
          url: 'https://example.com/app.apk',
        ).sha256,
        isNull,
      );
    });
  });

  test('结果对象只在 available 时表示有更新', () {
    const UpdateCheckResult available = UpdateCheckResult(
      status: UpdateStatus.available,
      currentVersion: '0.2.1',
      latestVersion: 'v0.2.2',
    );
    const UpdateCheckResult upToDate = UpdateCheckResult(
      status: UpdateStatus.upToDate,
      currentVersion: '0.2.1',
      latestVersion: 'v0.2.1',
    );
    const UpdateCheckResult failed = UpdateCheckResult(
      status: UpdateStatus.failed,
      currentVersion: '0.2.1',
    );

    expect(available.hasUpdate, isTrue);
    expect(upToDate.hasUpdate, isFalse);
    expect(failed.failed, isTrue);
  });
}
