import 'package:dio/dio.dart';
import 'package:tiebanana/Json_Model/Json/GithunGetLatestVersion.dart';

///APP版本

class Version {
  static const String version = "v0.2.1";

  static final Version _instance = Version._init();

  //最新stable版
  final String _latestUrl =
      "https://api.github.com/repos/Aobanana-chan/Tiebanana/releases/latest";

  //最新版，包括Pre版
  final String _latestUrlPreInclude =
      "https://api.github.com/repos/Aobanana-chan/Tiebanana/releases";

  final Dio _dio = Dio();

  factory Version() {
    return _instance;
  }
  Version._init();

  bool? hasUpdate;
  String? lastestVersion;

  Map<String, String> downloadUrl = {};
  late String changeLog;

  Future<void> checkUpdate({bool pre = false}) async {
    Response res;
    if (pre) {
      res = await _dio.get(
        _latestUrlPreInclude,
      );
    } else {
      res = await _dio.get(
        _latestUrl,
      );
    }

    VersionBase resJson = GetLatestVersion.fromJson(res.data);
    lastestVersion = resJson.name;
    if (resJson.name != version) {
      hasUpdate = true;
      final List arch = ["arm64-v8a", "armeabi-v7a", "x86_64"];
      for (Assets i in resJson.assets ?? []) {
        for (var j in arch) {
          if (i.name!.contains(j)) {
            downloadUrl[j] = i.browserDownloadUrl!;
            break;
          }
        }
      }
      changeLog = resJson.body!;
    } else {
      hasUpdate = false;
    }
  }
}
