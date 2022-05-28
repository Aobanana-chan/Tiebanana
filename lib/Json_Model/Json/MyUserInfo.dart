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
    data = json['data'] != null ? MyUserData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['no'] = no;
    data['error'] = error;
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
        ubsAbtestConfig?.add(UbsAbtestConfig.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['name_show'] = nameShow;
    data['name_link'] = nameLink;
    data['is_login'] = isLogin;
    data['no_un'] = noUn;
    data['mobilephone'] = mobilephone;
    data['email'] = email;
    data['is_half_user'] = isHalfUser;
    data['temp_name'] = tempName;
    data['source_id'] = sourceId;
    data['is_verify'] = isVerify;
    data['portrait'] = portrait;
    data['uid'] = uid;
    data['sid'] = sid;
    data['like_forum_num'] = likeForumNum;
    data['post_num'] = postNum;
    data['concern_num'] = concernNum;
    data['fans_num'] = fansNum;
    data['intro'] = intro;
    data['portrait_url'] = portraitUrl;
    data['user_sex'] = userSex;
    data['is_business_account'] = isBusinessAccount;
    if (mParrProps != null) {
      data['mParr_props'] = mParrProps?.map((v) => v.toJson()).toList();
    }
    data['tbs'] = tbs;
    data['itb_tbs'] = itbTbs;
    data['indextk'] = indextk;
    data['profile_index'] = profileIndex;
    data['ubs_sample_ids'] = ubsSampleIds;
    if (ubsAbtestConfig != null) {
      data['ubs_abtest_config'] =
          ubsAbtestConfig?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
