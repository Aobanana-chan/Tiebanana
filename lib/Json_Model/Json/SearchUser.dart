part of json_model;

class SearchUserModel {
  int? no;
  String? error;
  SearchUserModelData? data;

  SearchUserModel({this.no, this.error, this.data});

  SearchUserModel.fromJson(Map<String, dynamic> json) {
    no = json['no'];
    error = json['error'];
    data = json['data'] != null
        ? new SearchUserModelData.fromJson(json['data'])
        : null;
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

class SearchUserModelData {
  int? pn;
  int? hasMore;
  ExactMatch? exactMatch;
  List<FuzzyMatch>? fuzzyMatch;
  String? ubsSampleIds;
  List<UbsAbtestConfig>? ubsAbtestConfig;

  SearchUserModelData(
      {this.pn,
      this.hasMore,
      this.exactMatch,
      this.fuzzyMatch,
      this.ubsSampleIds,
      this.ubsAbtestConfig});

  SearchUserModelData.fromJson(Map<String, dynamic> json) {
    pn = json['pn'];
    hasMore = json['has_more'];
    exactMatch = json['exactMatch'] != null
        ? new ExactMatch.fromJson(json['exactMatch'])
        : null;
    if (json['fuzzyMatch'] != null) {
      fuzzyMatch = [];
      json['fuzzyMatch'].forEach((v) {
        fuzzyMatch?.add(new FuzzyMatch.fromJson(v));
      });
    }
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
    data['pn'] = this.pn;
    data['has_more'] = this.hasMore;
    if (this.exactMatch != null) {
      data['exactMatch'] = this.exactMatch?.toJson();
    }
    if (this.fuzzyMatch != null) {
      data['fuzzyMatch'] = this.fuzzyMatch?.map((v) => v.toJson()).toList();
    }
    data['ubs_sample_ids'] = this.ubsSampleIds;
    if (this.ubsAbtestConfig != null) {
      data['ubs_abtest_config'] =
          this.ubsAbtestConfig?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ExactMatch extends UserMatch {
  int? id;
  String? intro;
  String? userNickname;
  String? name;
  String? showNickname;
  String? portrait;
  String? encryUid;
  int? fansNum;
  int? isBjh;
  String? bjhVIntro;
  int? isGod;
  // Null businessAccountInfo;
  // Null bazhuGrade;
  // Null displayAuthType;
  // Null workCreatorInfo;
  AlaInfo? alaInfo;
  int? isExact;
  int? hasConcerned;

  ExactMatch(
      {this.id,
      this.intro,
      this.userNickname,
      this.name,
      this.showNickname,
      this.portrait,
      this.encryUid,
      this.fansNum,
      this.isBjh,
      this.bjhVIntro,
      this.isGod,
      // this.businessAccountInfo,
      // this.bazhuGrade,
      // this.displayAuthType,
      // this.workCreatorInfo,
      this.alaInfo,
      this.isExact,
      this.hasConcerned});

  ExactMatch.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    intro = json['intro'];
    userNickname = json['user_nickname'];
    name = json['name'];
    showNickname = json['show_nickname'];
    portrait = json['portrait'];
    encryUid = json['encry_uid'];
    fansNum = json['fans_num'];
    isBjh = json['is_bjh'];
    bjhVIntro = json['bjh_v_intro'];
    isGod = json['is_god'];
    // businessAccountInfo = json['business_account_info'];
    // bazhuGrade = json['bazhu_grade'];
    // displayAuthType = json['display_auth_type'];
    // workCreatorInfo = json['work_creator_info'];
    alaInfo = json['ala_info'] != null
        ? new AlaInfo.fromJson(json['ala_info'])
        : null;
    isExact = json['is_exact'];
    hasConcerned = json['has_concerned'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['intro'] = this.intro;
    data['user_nickname'] = this.userNickname;
    data['name'] = this.name;
    data['show_nickname'] = this.showNickname;
    data['portrait'] = this.portrait;
    data['encry_uid'] = this.encryUid;
    data['fans_num'] = this.fansNum;
    data['is_bjh'] = this.isBjh;
    data['bjh_v_intro'] = this.bjhVIntro;
    data['is_god'] = this.isGod;
    // data['business_account_info'] = this.businessAccountInfo;
    // data['bazhu_grade'] = this.bazhuGrade;
    // data['display_auth_type'] = this.displayAuthType;
    // data['work_creator_info'] = this.workCreatorInfo;
    if (this.alaInfo != null) {
      data['ala_info'] = this.alaInfo?.toJson();
    }
    data['is_exact'] = this.isExact;
    data['has_concerned'] = this.hasConcerned;
    return data;
  }
}

// class AlaInfo {
//   int isYy;

//   AlaInfo({this.isYy});

//   AlaInfo.fromJson(Map<String, dynamic> json) {
//     isYy = json['is_yy'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['is_yy'] = this.isYy;
//     return data;
//   }
// }

class FuzzyMatch extends UserMatch {
  int? id;
  String? intro;
  String? userNickname;
  String? name;
  String? showNickname;
  String? portrait;
  String? encryUid;
  int? fansNum;
  int? isBjh;
  String? bjhVIntro;
  int? isGod;
  // Null businessAccountInfo;
  // Null bazhuGrade;
  // Null displayAuthType;
  // Null workCreatorInfo;
  AlaInfo? alaInfo;
  int? hasConcerned;

  FuzzyMatch(
      {this.id,
      this.intro,
      this.userNickname,
      this.name,
      this.showNickname,
      this.portrait,
      this.encryUid,
      this.fansNum,
      this.isBjh,
      this.bjhVIntro,
      this.isGod,
      // this.businessAccountInfo,
      // this.bazhuGrade,
      // this.displayAuthType,
      // this.workCreatorInfo,
      this.alaInfo,
      this.hasConcerned});

  FuzzyMatch.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    intro = json['intro'];
    userNickname = json['user_nickname'];
    name = json['name'];
    showNickname = json['show_nickname'];
    portrait = json['portrait'];
    encryUid = json['encry_uid'];
    fansNum = json['fans_num'];
    isBjh = json['is_bjh'];
    bjhVIntro = json['bjh_v_intro'];
    isGod = json['is_god'];
    // businessAccountInfo = json['business_account_info'];
    // bazhuGrade = json['bazhu_grade'];
    // displayAuthType = json['display_auth_type'];
    // workCreatorInfo = json['work_creator_info'];
    alaInfo = json['ala_info'] != null
        ? new AlaInfo.fromJson(json['ala_info'])
        : null;
    hasConcerned = json['has_concerned'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['intro'] = this.intro;
    data['user_nickname'] = this.userNickname;
    data['name'] = this.name;
    data['show_nickname'] = this.showNickname;
    data['portrait'] = this.portrait;
    data['encry_uid'] = this.encryUid;
    data['fans_num'] = this.fansNum;
    data['is_bjh'] = this.isBjh;
    data['bjh_v_intro'] = this.bjhVIntro;
    data['is_god'] = this.isGod;
    // data['business_account_info'] = this.businessAccountInfo;
    // data['bazhu_grade'] = this.bazhuGrade;
    // data['display_auth_type'] = this.displayAuthType;
    // data['work_creator_info'] = this.workCreatorInfo;
    if (this.alaInfo != null) {
      data['ala_info'] = this.alaInfo?.toJson();
    }
    data['has_concerned'] = this.hasConcerned;
    return data;
  }
}

// class AlaInfo {
//   String anchorLive;
//   String enterLive;
//   String lat;
//   String lng;
//   String location;
//   int isYy;
//   String showName;

//   AlaInfo(
//       {this.anchorLive,
//       this.enterLive,
//       this.lat,
//       this.lng,
//       this.location,
//       this.isYy,
//       this.showName});

//   AlaInfo.fromJson(Map<String, dynamic> json) {
//     anchorLive = json['anchor_live'];
//     enterLive = json['enter_live'];
//     lat = json['lat'];
//     lng = json['lng'];
//     location = json['location'];
//     isYy = json['is_yy'];
//     showName = json['show_name'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['anchor_live'] = this.anchorLive;
//     data['enter_live'] = this.enterLive;
//     data['lat'] = this.lat;
//     data['lng'] = this.lng;
//     data['location'] = this.location;
//     data['is_yy'] = this.isYy;
//     data['show_name'] = this.showName;
//     return data;
//   }
// }

// class UbsAbtestConfig {
//   String sid;

//   UbsAbtestConfig({this.sid});

//   UbsAbtestConfig.fromJson(Map<String, dynamic> json) {
//     sid = json['sid'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['sid'] = this.sid;
//     return data;
//   }
// }

class UserMatch {
  int? id;
  String? intro;
  String? userNickname;
  String? name;
  String? showNickname;
  String? portrait;
  String? encryUid;
  int? fansNum;
  int? isBjh;
  String? bjhVIntro;
  int? isGod;
  // Null businessAccountInfo;
  // Null bazhuGrade;
  // Null displayAuthType;
  // Null workCreatorInfo;
  AlaInfo? alaInfo;
  int? hasConcerned;

  UserMatch(
      {this.id,
      this.intro,
      this.userNickname,
      this.name,
      this.showNickname,
      this.portrait,
      this.encryUid,
      this.fansNum,
      this.isBjh,
      this.bjhVIntro,
      this.isGod,
      // this.businessAccountInfo,
      // this.bazhuGrade,
      // this.displayAuthType,
      // this.workCreatorInfo,
      this.alaInfo,
      this.hasConcerned});

  UserMatch.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    intro = json['intro'];
    userNickname = json['user_nickname'];
    name = json['name'];
    showNickname = json['show_nickname'];
    portrait = json['portrait'];
    encryUid = json['encry_uid'];
    fansNum = json['fans_num'];
    isBjh = json['is_bjh'];
    bjhVIntro = json['bjh_v_intro'];
    isGod = json['is_god'];
    // businessAccountInfo = json['business_account_info'];
    // bazhuGrade = json['bazhu_grade'];
    // displayAuthType = json['display_auth_type'];
    // workCreatorInfo = json['work_creator_info'];
    alaInfo = json['ala_info'] != null
        ? new AlaInfo.fromJson(json['ala_info'])
        : null;
    hasConcerned = json['has_concerned'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['intro'] = this.intro;
    data['user_nickname'] = this.userNickname;
    data['name'] = this.name;
    data['show_nickname'] = this.showNickname;
    data['portrait'] = this.portrait;
    data['encry_uid'] = this.encryUid;
    data['fans_num'] = this.fansNum;
    data['is_bjh'] = this.isBjh;
    data['bjh_v_intro'] = this.bjhVIntro;
    data['is_god'] = this.isGod;
    // data['business_account_info'] = this.businessAccountInfo;
    // data['bazhu_grade'] = this.bazhuGrade;
    // data['display_auth_type'] = this.displayAuthType;
    // data['work_creator_info'] = this.workCreatorInfo;
    if (this.alaInfo != null) {
      data['ala_info'] = this.alaInfo?.toJson();
    }
    data['has_concerned'] = this.hasConcerned;
    return data;
  }
}
