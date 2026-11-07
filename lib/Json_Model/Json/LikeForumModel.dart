part of json_model;

///关注一个吧接口Model
class LikeFourmModel {
  LikeForumModelInfo? info;
  UserPerm? userPerm;
  // List<Null>? feedForum;
  // List<Null>? recomForum;
  LikeFormModelError? error;
  String? serverTime;
  int? time;
  int? ctime;
  int? logid;
  String? errorCode;

  LikeFourmModel(
      {this.info,
      this.userPerm,
      // this.feedForum,
      // this.recomForum,
      this.error,
      this.serverTime,
      this.time,
      this.ctime,
      this.logid,
      this.errorCode});

  LikeFourmModel.fromJson(Map<String, dynamic> json) {
    info =
        json['info'] != null ? LikeForumModelInfo.fromJson(json['info']) : null;
    userPerm =
        json['user_perm'] != null ? UserPerm.fromJson(json['user_perm']) : null;
    // if (json['feed_forum'] != null) {
    //   feedForum = <Null>[];
    //   json['feed_forum'].forEach((v) {
    //     feedForum!.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['recom_forum'] != null) {
    //   recomForum = <Null>[];
    //   json['recom_forum'].forEach((v) {
    //     recomForum!.add(new Null.fromJson(v));
    //   });
    // }
    error = json['error'] != null
        ? LikeFormModelError.fromJson(json['error'])
        : null;
    serverTime = json['server_time'];
    time = json['time'];
    ctime = json['ctime'];
    logid = json['logid'];
    errorCode = json['error_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (info != null) {
      data['info'] = info!.toJson();
    }
    if (userPerm != null) {
      data['user_perm'] = userPerm!.toJson();
    }
    // if (this.feedForum != null) {
    //   data['feed_forum'] = this.feedForum!.map((v) => v.toJson()).toList();
    // }
    // if (this.recomForum != null) {
    //   data['recom_forum'] = this.recomForum!.map((v) => v.toJson()).toList();
    // }
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

class LikeForumModelInfo {
  String? curScore;
  String? levelupScore;
  String? isLike;
  String? isBlack;
  String? likeNum;
  String? levelId;
  String? levelName;
  String? memberSum;

  LikeForumModelInfo(
      {this.curScore,
      this.levelupScore,
      this.isLike,
      this.isBlack,
      this.likeNum,
      this.levelId,
      this.levelName,
      this.memberSum});

  LikeForumModelInfo.fromJson(Map<String, dynamic> json) {
    curScore = json['cur_score'];
    levelupScore = json['levelup_score'];
    isLike = json['is_like'];
    isBlack = json['is_black'];
    likeNum = json['like_num'];
    levelId = json['level_id'];
    levelName = json['level_name'];
    memberSum = json['member_sum'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cur_score'] = curScore;
    data['levelup_score'] = levelupScore;
    data['is_like'] = isLike;
    data['is_black'] = isBlack;
    data['like_num'] = likeNum;
    data['level_id'] = levelId;
    data['level_name'] = levelName;
    data['member_sum'] = memberSum;
    return data;
  }
}

class UserPerm {
  String? levelId;
  String? levelName;

  UserPerm({this.levelId, this.levelName});

  UserPerm.fromJson(Map<String, dynamic> json) {
    levelId = json['level_id'];
    levelName = json['level_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['level_id'] = levelId;
    data['level_name'] = levelName;
    return data;
  }
}

class LikeFormModelError {
  String? errno;
  String? errmsg;
  String? usermsg;

  LikeFormModelError({this.errno, this.errmsg, this.usermsg});

  LikeFormModelError.fromJson(Map<String, dynamic> json) {
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
