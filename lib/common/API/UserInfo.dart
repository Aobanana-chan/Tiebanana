import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:json5/json5.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/common/API/Constants.dart';

///用户信息类
class UserInfomation {
  late Dio dio;
  List<LikeForumInfo>? _likes; //关注的贴吧及贴吧信息
  int? _uid;
  late String _bduss;
  UserInfomation(this.dio);
  void init(String bduss) {
    _bduss = bduss;
    //refresh();
  }

  Future<List<LikeForumInfo>?> get likes async {
    if (_likes == null) {
      await refresh();
    }
    return _likes;
  }

  Future<int?> get uid async {
    if (_uid == null) {
      await refresh();
    }
    return _uid;
  }

  Future refresh() async {
    try {
      // 手机web端获取关注贴吧方法，可以获得贴吧热度，但是不能获得贴吧签到情况
      var res = await dio.get(GET_FORUM_HOME);
      GetForumHomeData forumHomeData = GetForumHomeData.fromJson(res.data);
      if (forumHomeData.errno != 0) {
        throw Exception(
            "errno:${forumHomeData.errno}\n${forumHomeData.errmsg}");
      }
      _uid = forumHomeData.data!.userInfo!.id!;
      // _likes = forumHomeData.data!.likeForum!.list!;

      //电脑web端获取关注贴吧，请求一次消耗大约80k流量，是上面方法的10-160倍左右，但是获得的信息很全面，但内容过于冗余，作为备用方法
      // var indexData = await dio.get(TIEBA_URL,
      //     options: Options(responseType: ResponseType.plain));
      // String tiebaSigned = RegExp(
      //         r"(?<=<script>_.Module.use\('spage\/widget\/forumDirectory',)(.+?)(?=\);<\/script>)")
      //     .firstMatch(indexData.data)![0]!;

      //贴吧mini的方法，获取的信息比较折中，消耗流量大概1.5k-9k
      var body = {
        "BDUSS": _bduss,
        "like_forum": 1,
        "net_type": 1,
        "recommend": 0,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
        "topic": 0,
        "subapp_type": "mini",
        "from": "1021636m"
      };
      body["sign"] = _signArgs(body);
      var forumRecommendData = await dio.post(GET_FORUM_RECOMMEND,
          data: body,
          options: Options(
              headers: {"Content-Type": "application/x-www-from-urlencoded"}));
      var dataJson = json5Decode(forumRecommendData.data);
      if (dataJson['error_code'] != "0") {
        throw Exception(
            "error_code:${dataJson['error_code']}\n${dataJson['error_msg']}");
      }
      this._likes = [];
      for (var like in dataJson['like_forum']) {
        this._likes!.add(LikeForumInfo.fromJson(like));
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "获取用户信息失败\n$e");
    }
  }

  //排序
  Map<String, dynamic> _mapSrot(Map<String, dynamic> map) {
    var keys = map.keys.toList();
    // key排序
    keys.sort((a, b) {
      List<int> al = a.codeUnits;
      List<int> bl = b.codeUnits;
      for (int i = 0; i < al.length; i++) {
        if (bl.length <= i) return 1;
        if (al[i] > bl[i]) {
          return 1;
        } else if (al[i] < bl[i]) return -1;
      }
      return 0;
    });
    var sortedMap = Map<String, dynamic>();
    keys.forEach((element) {
      sortedMap[element] = map[element];
    });
    return sortedMap;
  }

  //sign签名算法
  String _signArgs(Map<String, dynamic> map) {
    var sortedmap = _mapSrot(map);
    var str = "";
    for (var key in sortedmap.keys) {
      str += "$key=${sortedmap[key]}";
    }
    str += "tiebaclient!!!";
    return md5.convert(utf8.encode(str)).toString();
  }
}
