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
        ? SearchUserModelData.fromJson(json['data'])
        : null;
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
        ? ExactMatch.fromJson(json['exactMatch'])
        : null;
    if (json['fuzzyMatch'] != null) {
      fuzzyMatch = [];
      json['fuzzyMatch'].forEach((v) {
        fuzzyMatch?.add(FuzzyMatch.fromJson(v));
      });
    }
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
    data['pn'] = pn;
    data['has_more'] = hasMore;
    if (exactMatch != null) {
      data['exactMatch'] = exactMatch?.toJson();
    }
    if (fuzzyMatch != null) {
      data['fuzzyMatch'] = fuzzyMatch?.map((v) => v.toJson()).toList();
    }
    data['ubs_sample_ids'] = ubsSampleIds;
    if (ubsAbtestConfig != null) {
      data['ubs_abtest_config'] =
          ubsAbtestConfig?.map((v) => v.toJson()).toList();
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
    alaInfo =
        json['ala_info'] != null ? AlaInfo.fromJson(json['ala_info']) : null;
    isExact = json['is_exact'];
    hasConcerned = json['has_concerned'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['intro'] = intro;
    data['user_nickname'] = userNickname;
    data['name'] = name;
    data['show_nickname'] = showNickname;
    data['portrait'] = portrait;
    data['encry_uid'] = encryUid;
    data['fans_num'] = fansNum;
    data['is_bjh'] = isBjh;
    data['bjh_v_intro'] = bjhVIntro;
    data['is_god'] = isGod;
    // data['business_account_info'] = this.businessAccountInfo;
    // data['bazhu_grade'] = this.bazhuGrade;
    // data['display_auth_type'] = this.displayAuthType;
    // data['work_creator_info'] = this.workCreatorInfo;
    if (alaInfo != null) {
      data['ala_info'] = alaInfo?.toJson();
    }
    data['is_exact'] = isExact;
    data['has_concerned'] = hasConcerned;
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
    if (json['fans_num'] is num) {
      fansNum = (json['fans_num'] as num).toInt();
    } else if (json['fans_num'] is String) {
      fansNum = int.tryParse(json['fans_num']);
      if (fansNum == null) {
        var mul = 1;
        var numstr = "";
        var m = (json['fans_num'] as String).split('');
        for (var e in m) {
          if (e == "." || int.tryParse(e) != null) {
            numstr += e;
          } else {
            if (e.toLowerCase() == "k") {
              mul *= 1000;
            } else if (e.toLowerCase() == "w") {
              mul *= 10000;
            } else if (e.toLowerCase() == "m") {
              mul *= 1000000;
            }
          }
        }
        fansNum = (num.parse(numstr) * mul).toInt();
      }
    }

    isBjh = json['is_bjh'];
    bjhVIntro = json['bjh_v_intro'];
    isGod = json['is_god'];
    // businessAccountInfo = json['business_account_info'];
    // bazhuGrade = json['bazhu_grade'];
    // displayAuthType = json['display_auth_type'];
    // workCreatorInfo = json['work_creator_info'];
    alaInfo =
        json['ala_info'] != null ? AlaInfo.fromJson(json['ala_info']) : null;
    hasConcerned = json['has_concerned'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['intro'] = intro;
    data['user_nickname'] = userNickname;
    data['name'] = name;
    data['show_nickname'] = showNickname;
    data['portrait'] = portrait;
    data['encry_uid'] = encryUid;
    data['fans_num'] = fansNum;
    data['is_bjh'] = isBjh;
    data['bjh_v_intro'] = bjhVIntro;
    data['is_god'] = isGod;
    // data['business_account_info'] = this.businessAccountInfo;
    // data['bazhu_grade'] = this.bazhuGrade;
    // data['display_auth_type'] = this.displayAuthType;
    // data['work_creator_info'] = this.workCreatorInfo;
    if (alaInfo != null) {
      data['ala_info'] = alaInfo?.toJson();
    }
    data['has_concerned'] = hasConcerned;
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
    alaInfo =
        json['ala_info'] != null ? AlaInfo.fromJson(json['ala_info']) : null;
    hasConcerned = json['has_concerned'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['intro'] = intro;
    data['user_nickname'] = userNickname;
    data['name'] = name;
    data['show_nickname'] = showNickname;
    data['portrait'] = portrait;
    data['encry_uid'] = encryUid;
    data['fans_num'] = fansNum;
    data['is_bjh'] = isBjh;
    data['bjh_v_intro'] = bjhVIntro;
    data['is_god'] = isGod;
    // data['business_account_info'] = this.businessAccountInfo;
    // data['bazhu_grade'] = this.bazhuGrade;
    // data['display_auth_type'] = this.displayAuthType;
    // data['work_creator_info'] = this.workCreatorInfo;
    if (alaInfo != null) {
      data['ala_info'] = alaInfo?.toJson();
    }
    data['has_concerned'] = hasConcerned;
    return data;
  }
}
