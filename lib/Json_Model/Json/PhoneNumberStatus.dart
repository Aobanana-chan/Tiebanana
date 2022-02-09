part of json_model;

class PhoneNumberStatus {
  PhoneNumberStatusErrInfo? errInfo;
  PhoneNumberStatusData? data;
  String? traceid;

  PhoneNumberStatus({this.errInfo, this.data, this.traceid});

  PhoneNumberStatus.fromJson(Map<String, dynamic> json) {
    errInfo = json['errInfo'] != null
        ? new PhoneNumberStatusErrInfo.fromJson(json['errInfo'])
        : null;
    data = json['data'] != null
        ? new PhoneNumberStatusData.fromJson(json['data'])
        : null;
    traceid = json['traceid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.errInfo != null) {
      data['errInfo'] = this.errInfo?.toJson();
    }
    if (this.data != null) {
      data['data'] = this.data?.toJson();
    }
    data['traceid'] = this.traceid;
    return data;
  }
}

class PhoneNumberStatusErrInfo {
  String? no;
  String? msg;
  String? isPwd;

  PhoneNumberStatusErrInfo({this.no, this.msg, this.isPwd});

  PhoneNumberStatusErrInfo.fromJson(Map<String, dynamic> json) {
    no = json['no'];
    msg = json['msg'];
    isPwd = json['isPwd'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['no'] = this.no;
    data['msg'] = this.msg;
    data['isPwd'] = this.isPwd;
    return data;
  }
}

class PhoneNumberStatusData {
  String? jumpReg;

  PhoneNumberStatusData({this.jumpReg});

  PhoneNumberStatusData.fromJson(Map<String, dynamic> json) {
    jumpReg = json['jumpReg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['jumpReg'] = this.jumpReg;
    return data;
  }
}
