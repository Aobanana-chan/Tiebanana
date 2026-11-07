part of json_model;

///图片上传Model
class UploadImageModel {
  String? resourceId;
  String? chunkNo;
  String? picId;
  PicInfo? picInfo;
  String? errorCode;
  String? errorMsg;
  // List<Null> info;
  String? serverTime;
  int? time;
  int? ctime;
  int? logid;

  UploadImageModel(
      {this.resourceId,
      this.chunkNo,
      this.picId,
      this.picInfo,
      this.errorCode,
      this.errorMsg,
      // this.info,
      this.serverTime,
      this.time,
      this.ctime,
      this.logid});

  UploadImageModel.fromJson(Map<String, dynamic> json) {
    resourceId = json['resourceId'];
    chunkNo = json['chunkNo'];
    picId = json['picId'];
    picInfo =
        json['picInfo'] != null ? PicInfo.fromJson(json['picInfo']) : null;
    errorCode = json['error_code'];
    errorMsg = json['error_msg'];
    // if (json['info'] != null) {
    //   info = new List<Null>();
    //   json['info'].forEach((v) {
    //     info.add(new Null.fromJson(v));
    //   });
    // }
    serverTime = json['server_time'];
    time = (json['time'] as num).toInt();
    ctime = json['ctime'];
    logid = (json['logid'] as num).toInt();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['resourceId'] = resourceId;
    data['chunkNo'] = chunkNo;
    data['picId'] = picId;
    if (picInfo != null) {
      data['picInfo'] = picInfo?.toJson();
    }
    data['error_code'] = errorCode;
    data['error_msg'] = errorMsg;
    // if (this.info != null) {
    //   data['info'] = this.info.map((v) => v.toJson()).toList();
    // }
    data['server_time'] = serverTime;
    data['time'] = time;
    data['ctime'] = ctime;
    data['logid'] = logid;
    return data;
  }
}

class PicInfo {
  OriginPic? originPic;
  OriginPic? bigPic;
  OriginPic? smallPic;

  PicInfo({this.originPic, this.bigPic, this.smallPic});

  PicInfo.fromJson(Map<String, dynamic> json) {
    originPic = json['originPic'] != null
        ? OriginPic.fromJson(json['originPic'])
        : null;
    bigPic = json['bigPic'] != null ? OriginPic.fromJson(json['bigPic']) : null;
    smallPic =
        json['smallPic'] != null ? OriginPic.fromJson(json['smallPic']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (originPic != null) {
      data['originPic'] = originPic?.toJson();
    }
    if (bigPic != null) {
      data['bigPic'] = bigPic?.toJson();
    }
    if (smallPic != null) {
      data['smallPic'] = smallPic?.toJson();
    }
    return data;
  }
}

class OriginPic {
  String? width;
  String? height;
  String? type;
  String? picUrl;

  OriginPic({this.width, this.height, this.type, this.picUrl});

  OriginPic.fromJson(Map<String, dynamic> json) {
    width = json['width'];
    height = json['height'];
    type = json['type'];
    picUrl = json['picUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['width'] = width;
    data['height'] = height;
    data['type'] = type;
    data['picUrl'] = picUrl;
    return data;
  }
}
