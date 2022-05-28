part of json_model;

///回复消息
class ReplyMe {
  String? isFloor;
  String? type;
  Replyer? replyer;
  QuoteUser? quoteUser;
  String? title;
  String? content;
  String? quoteContent;
  String? threadId;
  String? postId;
  String? time;
  String? fname;
  String? quotePid;
  String? threadType;
  String? unread;
  String? postFrom;
  String? threadImgUrl;
  ThreadAuthorUser? threadAuthorUser;

  ReplyMe(
      {this.isFloor,
      this.type,
      this.replyer,
      this.quoteUser,
      this.title,
      this.content,
      this.quoteContent,
      this.threadId,
      this.postId,
      this.time,
      this.fname,
      this.quotePid,
      this.threadType,
      this.unread,
      this.postFrom,
      this.threadImgUrl,
      this.threadAuthorUser});

  ReplyMe.fromJson(Map<String, dynamic> json) {
    isFloor = json['is_floor'];
    type = json['type'];
    replyer =
        json['replyer'] != null ? Replyer.fromJson(json['replyer']) : null;
    quoteUser = json['quote_user'] != null
        ? QuoteUser.fromJson(json['quote_user'])
        : null;
    title = json['title'];
    content = json['content'];
    quoteContent = json['quote_content'];
    threadId = json['thread_id'];
    postId = json['post_id'];
    time = json['time'];
    fname = json['fname'];
    quotePid = json['quote_pid'];
    threadType = json['thread_type'];
    unread = json['unread'];
    postFrom = json['post_from'];
    threadImgUrl = json['thread_img_url'];
    threadAuthorUser = json['thread_author_user'] != null
        ? ThreadAuthorUser.fromJson(json['thread_author_user'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_floor'] = isFloor;
    data['type'] = type;
    if (replyer != null) {
      data['replyer'] = replyer?.toJson();
    }
    if (quoteUser != null) {
      data['quote_user'] = quoteUser?.toJson();
    }
    data['title'] = title;
    data['content'] = content;
    data['quote_content'] = quoteContent;
    data['thread_id'] = threadId;
    data['post_id'] = postId;
    data['time'] = time;
    data['fname'] = fname;
    data['quote_pid'] = quotePid;
    data['thread_type'] = threadType;
    data['unread'] = unread;
    data['post_from'] = postFrom;
    data['thread_img_url'] = threadImgUrl;
    if (threadAuthorUser != null) {
      data['thread_author_user'] = threadAuthorUser?.toJson();
    }
    return data;
  }
}

class Replyer {
  String? id;
  String? name;
  String? portrait;
  String? displayAuthType;
  // String? workCreatorInfo;
  PrivSets? privSets;
  // List? bazhuGrade;
  String? isFriend;
  String? isFans;
  String? nameShow;

  Replyer(
      {this.id,
      this.name,
      this.portrait,
      this.displayAuthType,
      // this.workCreatorInfo,
      this.privSets,
      // this.bazhuGrade,
      this.isFriend,
      this.isFans,
      this.nameShow});

  Replyer.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    portrait = json['portrait'];
    displayAuthType = json['display_auth_type'];
    // workCreatorInfo = json['work_creator_info'];
    privSets =
        json['priv_sets'] != "" ? PrivSets.fromJson(json['priv_sets']) : null;
    // bazhuGrade = json['bazhu_grade'];
    isFriend = json['is_friend'];
    isFans = json['is_fans'];
    nameShow = json['name_show'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['portrait'] = portrait;

    data['display_auth_type'] = displayAuthType;
    // data['work_creator_info'] = this.workCreatorInfo;
    if (privSets != null) {
      data['priv_sets'] = privSets?.toJson();
    }
    // data['bazhu_grade'] = this.bazhuGrade;
    data['is_friend'] = isFriend;
    data['is_fans'] = isFans;
    data['name_show'] = nameShow;
    return data;
  }
}

class PrivSets {
  String? like;
  String? location;
  String? post;
  String? reply;

  PrivSets({this.like, this.location, this.post, this.reply});

  PrivSets.fromJson(Map<String, dynamic> json) {
    like = json['like'];
    location = json['location'];
    post = json['post'];
    reply = json['reply'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['like'] = like;
    data['location'] = location;
    data['post'] = post;
    data['reply'] = reply;
    return data;
  }
}

class QuoteUser {
  String? id;
  String? name;
  String? portrait;
  String? nameShow;

  QuoteUser({this.id, this.name, this.portrait, this.nameShow});

  QuoteUser.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    portrait = json['portrait'];
    nameShow = json['name_show'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['portrait'] = portrait;
    data['name_show'] = nameShow;
    return data;
  }
}

class ThreadAuthorUser {
  String? id;
  String? portrait;

  ThreadAuthorUser({this.id, this.portrait});

  ThreadAuthorUser.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    portrait = json['portrait'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['portrait'] = portrait;
    return data;
  }
}
