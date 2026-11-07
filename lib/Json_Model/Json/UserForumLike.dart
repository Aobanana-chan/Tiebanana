///用户关注贴吧model
part of json_model;

class UserForumLikeModel {
  ForumList? forumList;
  String? hasMore;
  String? serverTime;
  int? time;
  int? ctime;
  int? logid;
  String? errorCode;

  UserForumLikeModel(
      {this.forumList,
      this.hasMore,
      this.serverTime,
      this.time,
      this.ctime,
      this.logid,
      this.errorCode});

  UserForumLikeModel.fromJson(Map<String, dynamic> json) {
    forumList = json['forum_list'] != null
        ? ForumList.fromJson(json['forum_list'])
        : null;
    hasMore = json['has_more'];
    serverTime = json['server_time'];
    time = json['time'];
    ctime = json['ctime'];
    logid = json['logid'];
    errorCode = json['error_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (forumList != null) {
      data['forum_list'] = forumList!.toJson();
    }
    data['has_more'] = hasMore;
    data['server_time'] = serverTime;
    data['time'] = time;
    data['ctime'] = ctime;
    data['logid'] = logid;
    data['error_code'] = errorCode;
    return data;
  }
}

class ForumList {
  List<NonGconforum>? nonGconforum;

  ForumList({this.nonGconforum});

  ForumList.fromJson(Map<String, dynamic> json) {
    if (json['non-gconforum'] != null) {
      nonGconforum = <NonGconforum>[];
      json['non-gconforum'].forEach((v) {
        nonGconforum!.add(NonGconforum.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (nonGconforum != null) {
      data['non-gconforum'] = nonGconforum!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class NonGconforum {
  String? id;
  String? name;
  String? favoType;
  String? levelId;
  String? levelName;
  String? curScore;
  String? levelupScore;
  String? avatar;
  String? slogan;
  String? memberCount;

  NonGconforum(
      {this.id,
      this.name,
      this.favoType,
      this.levelId,
      this.levelName,
      this.curScore,
      this.levelupScore,
      this.avatar,
      this.slogan,
      this.memberCount});

  NonGconforum.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    favoType = json['favo_type'];
    levelId = json['level_id'];
    levelName = json['level_name'];
    curScore = json['cur_score'];
    levelupScore = json['levelup_score'];
    avatar = json['avatar'];
    slogan = json['slogan'];
    memberCount = json['member_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['favo_type'] = favoType;
    data['level_id'] = levelId;
    data['level_name'] = levelName;
    data['cur_score'] = curScore;
    data['levelup_score'] = levelupScore;
    data['avatar'] = avatar;
    data['slogan'] = slogan;
    data['member_count'] = memberCount;
    return data;
  }
}
