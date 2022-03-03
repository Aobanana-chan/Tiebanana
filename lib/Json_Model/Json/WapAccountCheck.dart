part of json_model;

class WapAccountCheck {
  int? errno;
  String? errmsg;
  WapAccountCheckData? data;
  String? traceid;

  WapAccountCheck({this.errno, this.errmsg, this.data, this.traceid});

  WapAccountCheck.fromJson(Map<String, dynamic> json) {
    errno = (json['errno'] as num).toInt();
    errmsg = json['errmsg'];
    data = json['data'] != null
        ? new WapAccountCheckData.fromJson(json['data'])
        : null;
    traceid = json['traceid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['errno'] = this.errno;
    data['errmsg'] = this.errmsg;
    if (this.data != null) {
      data['data'] = this.data?.toJson();
    }
    data['traceid'] = this.traceid;
    return data;
  }
}

class WapAccountCheckData {
  String? uid;
  bool? isMobile;
  List<String>? loginTypes;
  int? onekeyed;
  bool? canLogin;
  // Null? userNameUid;
  // Null? userNameLoginTypes;
  int? userNameOneKeyed;
  String? mobile;
  String? displayname;
  bool? countryCode;
  int? jumpReg;
  int? hasSecRisk;
  bool? enableLoginTypeRec;
  int? smsForceSend;
  int? isHasPassword;
  String? maskedMobile;
  bool? enableLoginSelectSkip;

  WapAccountCheckData(
      {this.uid,
      this.isMobile,
      this.loginTypes,
      this.onekeyed,
      this.canLogin,
      // this.userNameUid,
      // this.userNameLoginTypes,
      this.userNameOneKeyed,
      this.mobile,
      this.displayname,
      this.countryCode,
      this.jumpReg,
      this.hasSecRisk,
      this.enableLoginTypeRec,
      this.smsForceSend,
      this.isHasPassword,
      this.maskedMobile,
      this.enableLoginSelectSkip});

  WapAccountCheckData.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    isMobile = json['isMobile'];
    loginTypes = json['loginTypes'].cast<String>();
    onekeyed = json['onekeyed'];
    canLogin = json['canLogin'];
    // userNameUid = json['userNameUid'];
    // userNameLoginTypes = json['userNameLoginTypes'];
    userNameOneKeyed = json['userNameOneKeyed'];
    mobile = json['mobile'];
    displayname = json['displayname'];
    countryCode = json['countryCode'] == "" ? false : json['countryCode'];
    jumpReg = json['jumpReg'];
    hasSecRisk = json['hasSecRisk'];
    enableLoginTypeRec = json['enableLoginTypeRec'];
    smsForceSend = json['smsForceSend'];
    if (json['isHasPassword'] is num) {
      isHasPassword = (json['isHasPassword'] as num).toInt();
    } else if (json['isHasPassword'] is bool) {
      isHasPassword = json['isHasPassword'] == false ? 0 : 1;
    }

    maskedMobile = json['maskedMobile'];
    enableLoginSelectSkip = json['enableLoginSelectSkip'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['uid'] = this.uid;
    data['isMobile'] = this.isMobile;
    data['loginTypes'] = this.loginTypes;
    data['onekeyed'] = this.onekeyed;
    data['canLogin'] = this.canLogin;
    // data['userNameUid'] = this.userNameUid;
    // data['userNameLoginTypes'] = this.userNameLoginTypes;
    data['userNameOneKeyed'] = this.userNameOneKeyed;
    data['mobile'] = this.mobile;
    data['displayname'] = this.displayname;
    data['countryCode'] = this.countryCode;
    data['jumpReg'] = this.jumpReg;
    data['hasSecRisk'] = this.hasSecRisk;
    data['enableLoginTypeRec'] = this.enableLoginTypeRec;
    data['smsForceSend'] = this.smsForceSend;
    data['isHasPassword'] = this.isHasPassword;
    data['maskedMobile'] = this.maskedMobile;
    data['enableLoginSelectSkip'] = this.enableLoginSelectSkip;
    return data;
  }
}
