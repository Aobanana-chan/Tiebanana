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
        json['picInfo'] != null ? new PicInfo.fromJson(json['picInfo']) : null;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['resourceId'] = this.resourceId;
    data['chunkNo'] = this.chunkNo;
    data['picId'] = this.picId;
    if (this.picInfo != null) {
      data['picInfo'] = this.picInfo?.toJson();
    }
    data['error_code'] = this.errorCode;
    data['error_msg'] = this.errorMsg;
    // if (this.info != null) {
    //   data['info'] = this.info.map((v) => v.toJson()).toList();
    // }
    data['server_time'] = this.serverTime;
    data['time'] = this.time;
    data['ctime'] = this.ctime;
    data['logid'] = this.logid;
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
        ? new OriginPic.fromJson(json['originPic'])
        : null;
    bigPic =
        json['bigPic'] != null ? new OriginPic.fromJson(json['bigPic']) : null;
    smallPic = json['smallPic'] != null
        ? new OriginPic.fromJson(json['smallPic'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.originPic != null) {
      data['originPic'] = this.originPic?.toJson();
    }
    if (this.bigPic != null) {
      data['bigPic'] = this.bigPic?.toJson();
    }
    if (this.smallPic != null) {
      data['smallPic'] = this.smallPic?.toJson();
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['width'] = this.width;
    data['height'] = this.height;
    data['type'] = this.type;
    data['picUrl'] = this.picUrl;
    return data;
  }
}
