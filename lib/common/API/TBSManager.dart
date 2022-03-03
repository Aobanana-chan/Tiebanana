import 'package:dio/dio.dart';
import 'package:json5/json5.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/common/API/Constants.dart';

///频繁获取TBS参数会导致失败，tbs可以重复使用，故设置一个类用于管理
class TBSMagager {
  late Dio dio;
  var _tbs = "";
  var _maxlifetime = Duration(seconds: 10); //tbs有效期，暂定为10秒
  DateTime? _time; //最近一次获取的时间

  TBSMagager(this.dio);

  Future<String> getTBS() async {
    if (_time == null || _time!.add(_maxlifetime).isBefore(DateTime.now())) {
      var res = await dio.get(TBS_URL);
      _time = DateTime.now();
      TBS r = TBS.fromJson(json5Decode(res.data));
      _tbs = r.tbs!;
    }
    return _tbs;
  }
}
