part of json_model;

///添加/删除收藏贴Model

///添加
class AddThreadStoreModel {
  String? errorCode;
  String? errorMsg;
  // List<Null>? info;
  ThreadStoreModelError? error;
  List<String>? data;
  String? serverTime;
  int? time;
  int? ctime;
  int? logid;

  AddThreadStoreModel(
      {this.errorCode,
      this.errorMsg,
      // this.info,
      this.error,
      this.data,
      this.serverTime,
      this.time,
      this.ctime,
      this.logid});

  AddThreadStoreModel.fromJson(Map<String, dynamic> json) {
    errorCode = json['error_code'];
    errorMsg = json['error_msg'];
    // if (json['info'] != null) {
    //   info = <Null>[];
    //   json['info'].forEach((v) {
    //     info!.add(new Null.fromJson(v));
    //   });
    // }
    error = json['error'] != null
        ? ThreadStoreModelError.fromJson(json['error'])
        : null;
    data = json['data'].cast<String>();
    serverTime = json['server_time'];
    time = json['time'];
    ctime = json['ctime'];
    logid = json['logid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['error_code'] = errorCode;
    data['error_msg'] = errorMsg;
    // if (this.info != null) {
    //   data['info'] = this.info!.map((v) => v.toJson()).toList();
    // }
    if (error != null) {
      data['error'] = error!.toJson();
    }
    data['data'] = this.data;
    data['server_time'] = serverTime;
    data['time'] = time;
    data['ctime'] = ctime;
    data['logid'] = logid;
    return data;
  }
}

class ThreadStoreModelError {
  String? errno;
  String? errmsg;
  String? usermsg;

  ThreadStoreModelError({this.errno, this.errmsg, this.usermsg});

  ThreadStoreModelError.fromJson(Map<String, dynamic> json) {
    errno = json['errno'];
    errmsg = json['errmsg'];
    usermsg = json['usermsg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['errno'] = errno;
    data['errmsg'] = errmsg;
    data['usermsg'] = usermsg;
    return data;
  }
}

///删除
class RemoveThreadStoreModel {
  ThreadStoreModelError? error;
  String? serverTime;
  int? time;
  int? ctime;
  int? logid;
  String? errorCode;

  RemoveThreadStoreModel(
      {this.error,
      this.serverTime,
      this.time,
      this.ctime,
      this.logid,
      this.errorCode});

  RemoveThreadStoreModel.fromJson(Map<String, dynamic> json) {
    error = json['error'] != null
        ? ThreadStoreModelError.fromJson(json['error'])
        : null;
    serverTime = json['server_time'];
    time = json['time'];
    ctime = json['ctime'];
    logid = json['logid'];
    errorCode = json['error_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (error != null) {
      data['error'] = error!.toJson();
    }
    data['server_time'] = serverTime;
    data['time'] = time;
    data['ctime'] = ctime;
    data['logid'] = logid;
    data['error_code'] = errorCode;
    return data;
  }
}
