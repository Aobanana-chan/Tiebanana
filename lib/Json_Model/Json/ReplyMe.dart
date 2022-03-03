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
        json['replyer'] != null ? new Replyer.fromJson(json['replyer']) : null;
    quoteUser = json['quote_user'] != null
        ? new QuoteUser.fromJson(json['quote_user'])
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
        ? new ThreadAuthorUser.fromJson(json['thread_author_user'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_floor'] = this.isFloor;
    data['type'] = this.type;
    if (this.replyer != null) {
      data['replyer'] = this.replyer?.toJson();
    }
    if (this.quoteUser != null) {
      data['quote_user'] = this.quoteUser?.toJson();
    }
    data['title'] = this.title;
    data['content'] = this.content;
    data['quote_content'] = this.quoteContent;
    data['thread_id'] = this.threadId;
    data['post_id'] = this.postId;
    data['time'] = this.time;
    data['fname'] = this.fname;
    data['quote_pid'] = this.quotePid;
    data['thread_type'] = this.threadType;
    data['unread'] = this.unread;
    data['post_from'] = this.postFrom;
    data['thread_img_url'] = this.threadImgUrl;
    if (this.threadAuthorUser != null) {
      data['thread_author_user'] = this.threadAuthorUser?.toJson();
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
    privSets = json['priv_sets'] != ""
        ? new PrivSets.fromJson(json['priv_sets'])
        : null;
    // bazhuGrade = json['bazhu_grade'];
    isFriend = json['is_friend'];
    isFans = json['is_fans'];
    nameShow = json['name_show'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['portrait'] = this.portrait;

    data['display_auth_type'] = this.displayAuthType;
    // data['work_creator_info'] = this.workCreatorInfo;
    if (this.privSets != null) {
      data['priv_sets'] = this.privSets?.toJson();
    }
    // data['bazhu_grade'] = this.bazhuGrade;
    data['is_friend'] = this.isFriend;
    data['is_fans'] = this.isFans;
    data['name_show'] = this.nameShow;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['like'] = this.like;
    data['location'] = this.location;
    data['post'] = this.post;
    data['reply'] = this.reply;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['portrait'] = this.portrait;
    data['name_show'] = this.nameShow;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['portrait'] = this.portrait;
    return data;
  }
}
