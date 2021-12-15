part of json_model;

//个人信息Model
class MyUserInfo {
  int? no;
  String? error;
  MyUserData? data;

  MyUserInfo({this.no, this.error, this.data});

  MyUserInfo.fromJson(Map<String, dynamic> json) {
    no = json['no'];
    error = json['error'];
    data = json['data'] != null ? new MyUserData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['no'] = this.no;
    data['error'] = this.error;
    if (this.data != null) {
      data['data'] = this.data?.toJson();
    }
    return data;
  }
}

class MyUserData {
  int? id;
  String? name;
  String? nameShow;
  String? nameLink;
  bool? isLogin;
  String? noUn;
  String? mobilephone;
  String? email;
  int? isHalfUser;
  String? tempName;
  int? sourceId;
  bool? isVerify;
  String? portrait;
  int? uid;
  String? sid;
  int? likeForumNum;
  int? postNum;
  int? concernNum;
  int? fansNum;
  String? intro;
  String? portraitUrl;
  int? userSex;
  int? isBusinessAccount;
  List? mParrProps;
  String? tbs;
  String? itbTbs;
  String? indextk;
  String? profileIndex;
  String? ubsSampleIds;
  List<UbsAbtestConfig>? ubsAbtestConfig;

  MyUserData(
      {this.id,
      this.name,
      this.nameShow,
      this.nameLink,
      this.isLogin,
      this.noUn,
      this.mobilephone,
      this.email,
      this.isHalfUser,
      this.tempName,
      this.sourceId,
      this.isVerify,
      this.portrait,
      this.uid,
      this.sid,
      this.likeForumNum,
      this.postNum,
      this.concernNum,
      this.fansNum,
      this.intro,
      this.portraitUrl,
      this.userSex,
      this.isBusinessAccount,
      this.mParrProps,
      this.tbs,
      this.itbTbs,
      this.indextk,
      this.profileIndex,
      this.ubsSampleIds,
      this.ubsAbtestConfig});

  MyUserData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    nameShow = json['name_show'];
    nameLink = json['name_link'];
    isLogin = json['is_login'];
    noUn = json['no_un'];
    mobilephone = json['mobilephone'];
    email = json['email'];
    isHalfUser = json['is_half_user'];
    tempName = json['temp_name'];
    sourceId = json['source_id'];
    isVerify = json['is_verify'];
    portrait = json['portrait'];
    uid = json['uid'];
    sid = json['sid'];
    likeForumNum = json['like_forum_num'];
    postNum = json['post_num'];
    concernNum = json['concern_num'];
    fansNum = json['fans_num'];
    intro = json['intro'];
    portraitUrl = json['portrait_url'];
    userSex = json['user_sex'];
    isBusinessAccount = json['is_business_account'];
    if (json['mParr_props'] != null) {
      mParrProps = [];
      json['mParr_props'].forEach((v) {
        mParrProps?.add(v);
      });
    }
    tbs = json['tbs'];
    itbTbs = json['itb_tbs'];
    indextk = json['indextk'];
    profileIndex = json['profile_index'];
    ubsSampleIds = json['ubs_sample_ids'];
    if (json['ubs_abtest_config'] != null) {
      ubsAbtestConfig = [];
      json['ubs_abtest_config'].forEach((v) {
        ubsAbtestConfig?.add(new UbsAbtestConfig.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['name_show'] = this.nameShow;
    data['name_link'] = this.nameLink;
    data['is_login'] = this.isLogin;
    data['no_un'] = this.noUn;
    data['mobilephone'] = this.mobilephone;
    data['email'] = this.email;
    data['is_half_user'] = this.isHalfUser;
    data['temp_name'] = this.tempName;
    data['source_id'] = this.sourceId;
    data['is_verify'] = this.isVerify;
    data['portrait'] = this.portrait;
    data['uid'] = this.uid;
    data['sid'] = this.sid;
    data['like_forum_num'] = this.likeForumNum;
    data['post_num'] = this.postNum;
    data['concern_num'] = this.concernNum;
    data['fans_num'] = this.fansNum;
    data['intro'] = this.intro;
    data['portrait_url'] = this.portraitUrl;
    data['user_sex'] = this.userSex;
    data['is_business_account'] = this.isBusinessAccount;
    if (this.mParrProps != null) {
      data['mParr_props'] = this.mParrProps?.map((v) => v.toJson()).toList();
    }
    data['tbs'] = this.tbs;
    data['itb_tbs'] = this.itbTbs;
    data['indextk'] = this.indextk;
    data['profile_index'] = this.profileIndex;
    data['ubs_sample_ids'] = this.ubsSampleIds;
    if (this.ubsAbtestConfig != null) {
      data['ubs_abtest_config'] =
          this.ubsAbtestConfig?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
