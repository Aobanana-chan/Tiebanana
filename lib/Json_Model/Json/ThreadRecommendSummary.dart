part of json_model;

//////推荐贴信息(简略)
class ThreadRecommendSummary {
  String? id;
  String? tid;
  String? title;
  String? replyNum;
  String? viewNum;
  String? lastTimeInt;
  String? createTime;
  String? userId;
  String? isDeleted;
  MediaNum? mediaNum;
  Author? author;
  List<Media>? media;
  Agree? agree;
  String? shareNum;
  String? fid;
  String? fname;
  List<FirstPostContent>? firstPostContent;
  List<ThreadPersonalized>? threadPersonalized;
  ThreadRecommendSummary(
      {this.id,
      this.tid,
      this.title,
      this.replyNum,
      this.viewNum,
      this.lastTimeInt,
      this.createTime,
      this.userId,
      this.isDeleted,
      this.mediaNum,
      this.author,
      this.media,
      this.agree,
      this.shareNum,
      this.fid,
      this.fname,
      this.firstPostContent,
      this.threadPersonalized});

  ThreadRecommendSummary.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tid = json['tid'];
    title = json['title'];
    replyNum = json['reply_num'];
    viewNum = json['view_num'];
    lastTimeInt = json['last_time_int'];
    createTime = json['create_time'];
    userId = json['user_id'];
    isDeleted = json['is_deleted'];
    mediaNum = json['media_num'] != ""
        ? new MediaNum.fromJson(json['media_num'])
        : null;
    author =
        json['author'] != null ? new Author.fromJson(json['author']) : null;
    if (json['media'] != null) {
      media = <Media>[];
      json['media'].forEach((v) {
        media!.add(new Media.fromJson(v));
      });
    }
    agree = json['agree'] != null ? new Agree.fromJson(json['agree']) : null;
    shareNum = json['share_num'];
    fid = json['fid'];
    fname = json['fname'];
    if (json['first_post_content'] != null) {
      firstPostContent = <FirstPostContent>[];
      json['first_post_content'].forEach((v) {
        firstPostContent!.add(new FirstPostContent.fromJson(v));
      });
    }
    if (json['thread_personalized'] != null) {
      threadPersonalized = <ThreadPersonalized>[];
      json['thread_personalized'].forEach((v) {
        threadPersonalized!.add(new ThreadPersonalized.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['tid'] = this.tid;
    data['title'] = this.title;
    data['reply_num'] = this.replyNum;
    data['view_num'] = this.viewNum;
    data['last_time_int'] = this.lastTimeInt;
    data['create_time'] = this.createTime;
    data['user_id'] = this.userId;
    data['is_deleted'] = this.isDeleted;
    if (this.mediaNum != null) {
      data['media_num'] = this.mediaNum!.toJson();
    }
    if (this.author != null) {
      data['author'] = this.author!.toJson();
    }
    if (this.media != null) {
      data['media'] = this.media!.map((v) => v.toJson()).toList();
    }
    if (this.agree != null) {
      data['agree'] = this.agree!.toJson();
    }
    data['share_num'] = this.shareNum;
    data['fid'] = this.fid;
    data['fname'] = this.fname;
    if (this.firstPostContent != null) {
      data['first_post_content'] =
          this.firstPostContent!.map((v) => v.toJson()).toList();
    }
    if (this.threadPersonalized != null) {
      data['thread_personalized'] =
          this.threadPersonalized!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class MediaNum {
  String? pic;

  MediaNum({this.pic});

  MediaNum.fromJson(Map<String, dynamic> json) {
    pic = json['pic'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['pic'] = this.pic;
    return data;
  }
}

class Author {
  String? id;
  String? name;
  String? gender;
  String? nameShow;
  String? portrait;
  List<Iconinfo>? iconinfo;

  Author(
      {this.id,
      this.name,
      this.gender,
      this.nameShow,
      this.portrait,
      this.iconinfo});

  Author.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    gender = json['gender'];
    nameShow = json['name_show'];
    portrait = json['portrait'];
    if (json['iconinfo'] != null) {
      iconinfo = <Iconinfo>[];
      json['iconinfo'].forEach((v) {
        iconinfo!.add(new Iconinfo.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['gender'] = this.gender;
    data['name_show'] = this.nameShow;
    data['portrait'] = this.portrait;
    if (this.iconinfo != null) {
      data['iconinfo'] = this.iconinfo!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Iconinfo {
  String? icon;

  Iconinfo({this.icon});

  Iconinfo.fromJson(Map<String, dynamic> json) {
    icon = json['icon'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['icon'] = this.icon;
    return data;
  }
}

class Media {
  String? type;
  String? width;
  String? height;
  String? showOriginalBtn;
  String? isLongPic;
  String? bigPic;
  String? dynamicPic;
  String? srcPic;
  String? originPic;
  String? originSize;
  String? postId;
  String? wthMidLoc;
  String? hthMidLoc;

  Media(
      {this.type,
      this.width,
      this.height,
      this.showOriginalBtn,
      this.isLongPic,
      this.bigPic,
      this.dynamicPic,
      this.srcPic,
      this.originPic,
      this.originSize,
      this.postId,
      this.wthMidLoc,
      this.hthMidLoc});

  Media.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    width = json['width'];
    height = json['height'];
    showOriginalBtn = json['show_original_btn'];
    isLongPic = json['is_long_pic'];
    bigPic = json['big_pic'];
    dynamicPic = json['dynamic_pic'];
    srcPic = json['src_pic'];
    originPic = json['origin_pic'];
    originSize = json['origin_size'];
    postId = json['post_id'];
    wthMidLoc = json['wth_mid_loc'];
    hthMidLoc = json['hth_mid_loc'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['width'] = this.width;
    data['height'] = this.height;
    data['show_original_btn'] = this.showOriginalBtn;
    data['is_long_pic'] = this.isLongPic;
    data['big_pic'] = this.bigPic;
    data['dynamic_pic'] = this.dynamicPic;
    data['src_pic'] = this.srcPic;
    data['origin_pic'] = this.originPic;
    data['origin_size'] = this.originSize;
    data['post_id'] = this.postId;
    data['wth_mid_loc'] = this.wthMidLoc;
    data['hth_mid_loc'] = this.hthMidLoc;
    return data;
  }
}

class Agree {
  String? agreeNum;
  String? hasAgree;
  String? agreeType;
  String? disagreeNum;
  String? diffAgreeNum;

  Agree(
      {this.agreeNum,
      this.hasAgree,
      this.agreeType,
      this.disagreeNum,
      this.diffAgreeNum});

  Agree.fromJson(Map<String, dynamic> json) {
    agreeNum = json['agree_num'];
    hasAgree = json['has_agree'];
    agreeType = json['agree_type'];
    disagreeNum = json['disagree_num'];
    diffAgreeNum = json['diff_agree_num'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['agree_num'] = this.agreeNum;
    data['has_agree'] = this.hasAgree;
    data['agree_type'] = this.agreeType;
    data['disagree_num'] = this.disagreeNum;
    data['diff_agree_num'] = this.diffAgreeNum;
    return data;
  }
}

class FirstPostContent {
  String? type;
  String? bsize;
  String? size;
  String? originSrc;
  String? originSize;
  String? isLongPic;
  String? showOriginalBtn;
  String? cdnSrc;
  String? cdnSrcActive;
  String? bigCdnSrc;
  String? text;
  FirstPostContent(
      {this.type,
      this.bsize,
      this.size,
      this.originSrc,
      this.originSize,
      this.isLongPic,
      this.showOriginalBtn,
      this.cdnSrc,
      this.cdnSrcActive,
      this.bigCdnSrc,
      this.text});

  FirstPostContent.fromJson(Map<String, dynamic> json) {
    //0 - 文字
    //2 - 图片表情?
    //3 - 图片
    //5 - 视频
    type = json['type'];
    bsize = json['bsize'];
    size = json['size'];
    originSrc = json['origin_src'];
    originSize = json['origin_size'];
    isLongPic = json['is_long_pic'];
    showOriginalBtn = json['show_original_btn'];
    cdnSrc = json['cdn_src'];
    cdnSrcActive = json['cdn_src_active'];
    bigCdnSrc = json['big_cdn_src'];
    text = json['text'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['bsize'] = this.bsize;
    data['size'] = this.size;
    data['origin_src'] = this.originSrc;
    data['origin_size'] = this.originSize;
    data['is_long_pic'] = this.isLongPic;
    data['show_original_btn'] = this.showOriginalBtn;
    data['cdn_src'] = this.cdnSrc;
    data['cdn_src_active'] = this.cdnSrcActive;
    data['big_cdn_src'] = this.bigCdnSrc;
    data['text'] = text;
    return data;
  }
}

class ThreadPersonalized {
  String? tid;
  String? weight;
  String? source;
  String? abtestTag;
  String? extra;
  List<DislikeResource>? dislikeResource;

  ThreadPersonalized(
      {this.tid,
      this.weight,
      this.source,
      this.abtestTag,
      this.extra,
      this.dislikeResource});

  ThreadPersonalized.fromJson(Map<String, dynamic> json) {
    tid = json['tid'];
    weight = json['weight'];
    source = json['source'];
    abtestTag = json['abtest_tag'];
    extra = json['extra'];
    if (json['dislike_resource'] != null) {
      dislikeResource = <DislikeResource>[];
      json['dislike_resource'].forEach((v) {
        dislikeResource!.add(new DislikeResource.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tid'] = this.tid;
    data['weight'] = this.weight;
    data['source'] = this.source;
    data['abtest_tag'] = this.abtestTag;
    data['extra'] = this.extra;
    if (this.dislikeResource != null) {
      data['dislike_resource'] =
          this.dislikeResource!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DislikeResource {
  String? dislikeReason;
  String? dislikeId;
  String? extra;

  DislikeResource({this.dislikeReason, this.dislikeId, this.extra});

  DislikeResource.fromJson(Map<String, dynamic> json) {
    dislikeReason = json['dislike_reason'];
    dislikeId = json['dislike_id'];
    extra = json['extra'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['dislike_reason'] = this.dislikeReason;
    data['dislike_id'] = this.dislikeId;
    data['extra'] = this.extra;
    return data;
  }
}
