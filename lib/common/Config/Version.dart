import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tiebanana/Json_Model/Json/GithunGetLatestVersion.dart';

///APP版本

class Version {
  static const String version = "v0.1";

  static final Version _instance = Version.init();

  //最新stable版
  final String _latestUrl =
      "https://api.github.com/repos/Aobanana-chan/Tiebanana/releases/latest";

  //最新版，包括Pre版
  final String _latestUrlPreInclude =
      "https://api.github.com/repos/Aobanana-chan/Tiebanana/releases";

  Dio _dio = Dio();

  factory Version() {
    return _instance;
  }
  Version.init();

  bool hasUpdate = false;
  List<String> downloadUrl = [];
  late String changeLog;

  void checkUpdate() async {
    var res = await _dio.get(
      _latestUrl,
    );

    var resJson = GetLatestVersion.fromJson(jsonDecode(res.data));
    if (resJson.name != version) {
      hasUpdate = true;
      for (Assets i in resJson.assets ?? []) {
        downloadUrl.add(i.browserDownloadUrl!);
      }
      changeLog = resJson.body!;
    }
  }
}
