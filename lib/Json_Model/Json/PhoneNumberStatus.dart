part of json_model;

class PhoneNumberStatus {
  PhoneNumberStatusErrInfo? errInfo;
  PhoneNumberStatusData? data;
  String? traceid;

  PhoneNumberStatus({this.errInfo, this.data, this.traceid});

  PhoneNumberStatus.fromJson(Map<String, dynamic> json) {
    errInfo = json['errInfo'] != null
        ? PhoneNumberStatusErrInfo.fromJson(json['errInfo'])
        : null;
    data = json['data'] != null
        ? PhoneNumberStatusData.fromJson(json['data'])
        : null;
    traceid = json['traceid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (errInfo != null) {
      data['errInfo'] = errInfo?.toJson();
    }
    if (this.data != null) {
      data['data'] = this.data?.toJson();
    }
    data['traceid'] = traceid;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['no'] = no;
    data['msg'] = msg;
    data['isPwd'] = isPwd;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['jumpReg'] = jumpReg;
    return data;
  }
}
