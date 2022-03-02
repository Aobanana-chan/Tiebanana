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
  VideoInfo? videoInfo;
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
      this.threadPersonalized,
      this.videoInfo});

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
    videoInfo = json['video_info'] != null
        ? new VideoInfo.fromJson(json['video_info'])
        : null;
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
    if (this.videoInfo != null) {
      data['video_info'] = this.videoInfo?.toJson();
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
  String? c;
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
      this.text,
      this.c});

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
    c = json['c'];
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
    data['c'] = c;
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

class VideoInfo {
  String? auditing;
  String? formatMatched;
  String? ptid;
  String? thumbnailHeight;
  String? thumbnailPicid;
  String? thumbnailUrl;
  String? thumbnailWidth;
  String? versionH265;
  List<VideoDesc>? videoDesc;
  List<VideoDescCae3>? videoDescCae3;
  List<VideoDescH265>? videoDescH265;
  String? videoDuration;
  String? videoFormat;
  String? videoFrom;
  String? videoHeight;
  String? videoLogId;
  String? videoMd5;
  String? videoType;
  String? videoUrl;
  String? videoWidth;
  String? playCount;
  String? playTime;
  String? videoLength;
  String? isVertical;

  VideoInfo(
      {this.auditing,
      this.formatMatched,
      this.ptid,
      this.thumbnailHeight,
      this.thumbnailPicid,
      this.thumbnailUrl,
      this.thumbnailWidth,
      this.versionH265,
      this.videoDesc,
      this.videoDescCae3,
      this.videoDescH265,
      this.videoDuration,
      this.videoFormat,
      this.videoFrom,
      this.videoHeight,
      this.videoLogId,
      this.videoMd5,
      this.videoType,
      this.videoUrl,
      this.videoWidth,
      this.playCount,
      this.playTime,
      this.videoLength,
      this.isVertical});

  VideoInfo.fromJson(Map<String, dynamic> json) {
    auditing = json['auditing'];
    formatMatched = json['format_matched'];
    ptid = json['ptid'];
    thumbnailHeight = json['thumbnail_height'];
    thumbnailPicid = json['thumbnail_picid'];
    thumbnailUrl = json['thumbnail_url'];
    thumbnailWidth = json['thumbnail_width'];
    versionH265 = json['version_h265'];
    if (json['video_desc'] != null) {
      videoDesc = [];
      if (json['video_desc'] is List) {
        json['video_desc'].forEach((v) {
          videoDesc?.add(new VideoDesc.fromJson(v));
        });
      } else if (json['video_desc'] is Map) {
        json['video_desc'].forEach((v, f) {
          videoDesc?.add(new VideoDesc.fromJson({v: f}));
        });
      } else {
        throw Exception("未知视频类型");
      }
    }
    if (json['video_desc_cae3'] != null) {
      videoDescCae3 = [];
      json['video_desc_cae3'].forEach((v) {
        videoDescCae3?.add(new VideoDescCae3.fromJson(v));
      });
    }
    if (json['video_desc_h265'] != null) {
      videoDescH265 = [];
      json['video_desc_h265'].forEach((v) {
        videoDescH265?.add(new VideoDescH265.fromJson(v));
      });
    }
    videoDuration = json['video_duration'];
    videoFormat = json['video_format'];
    videoFrom = json['video_from'];
    videoHeight = json['video_height'];
    videoLogId = json['video_log_id'];
    videoMd5 = json['video_md5'];
    videoType = json['video_type'];
    videoUrl = json['video_url'];
    videoWidth = json['video_width'];
    playCount = json['play_count'];
    playTime = json['play_time'];
    videoLength = json['video_length'];
    isVertical = json['is_vertical'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['auditing'] = this.auditing;
    data['format_matched'] = this.formatMatched;
    data['ptid'] = this.ptid;
    data['thumbnail_height'] = this.thumbnailHeight;
    data['thumbnail_picid'] = this.thumbnailPicid;
    data['thumbnail_url'] = this.thumbnailUrl;
    data['thumbnail_width'] = this.thumbnailWidth;
    data['version_h265'] = this.versionH265;
    if (this.videoDesc != null) {
      data['video_desc'] = this.videoDesc?.map((v) => v.toJson()).toList();
    }
    if (this.videoDescCae3 != null) {
      data['video_desc_cae3'] =
          this.videoDescCae3?.map((v) => v.toJson()).toList();
    }
    if (this.videoDescH265 != null) {
      data['video_desc_h265'] =
          this.videoDescH265?.map((v) => v.toJson()).toList();
    }
    data['video_duration'] = this.videoDuration;
    data['video_format'] = this.videoFormat;
    data['video_from'] = this.videoFrom;
    data['video_height'] = this.videoHeight;
    data['video_log_id'] = this.videoLogId;
    data['video_md5'] = this.videoMd5;
    data['video_type'] = this.videoType;
    data['video_url'] = this.videoUrl;
    data['video_width'] = this.videoWidth;
    data['play_count'] = this.playCount;
    data['play_time'] = this.playTime;
    data['video_length'] = this.videoLength;
    data['is_vertical'] = this.isVertical;
    return data;
  }
}

class VideoDesc {
  String? videoHeight;
  String? videoId;
  String? videoSize;
  String? videoUrl;
  String? videoWidth;

  VideoDesc(
      {this.videoHeight,
      this.videoId,
      this.videoSize,
      this.videoUrl,
      this.videoWidth});

  VideoDesc.fromJson(Map<String, dynamic> json) {
    videoHeight = json['video_height'];
    videoId = json['video_id'];
    videoSize = json['video_size'];
    videoUrl = json['video_url'];
    videoWidth = json['video_width'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['video_height'] = this.videoHeight;
    data['video_id'] = this.videoId;
    data['video_size'] = this.videoSize;
    data['video_url'] = this.videoUrl;
    data['video_width'] = this.videoWidth;
    return data;
  }
}

class VideoDescCae3 {
  String? videoHeight;
  String? videoId;
  String? videoSize;
  String? videoUrl;
  String? videoWidth;

  VideoDescCae3(
      {this.videoHeight,
      this.videoId,
      this.videoSize,
      this.videoUrl,
      this.videoWidth});

  VideoDescCae3.fromJson(Map<String, dynamic> json) {
    videoHeight = json['video_height'];
    videoId = json['video_id'];
    videoSize = json['video_size'];
    videoUrl = json['video_url'];
    videoWidth = json['video_width'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['video_height'] = this.videoHeight;
    data['video_id'] = this.videoId;
    data['video_size'] = this.videoSize;
    data['video_url'] = this.videoUrl;
    data['video_width'] = this.videoWidth;
    return data;
  }
}

class VideoDescH265 {
  String? videoHeight;
  String? videoId;
  String? videoSize;
  String? videoUrl;
  String? videoWidth;

  VideoDescH265(
      {this.videoHeight,
      this.videoId,
      this.videoSize,
      this.videoUrl,
      this.videoWidth});

  VideoDescH265.fromJson(Map<String, dynamic> json) {
    videoHeight = json['video_height'];
    videoId = json['video_id'];
    videoSize = json['video_size'];
    videoUrl = json['video_url'];
    videoWidth = json['video_width'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['video_height'] = this.videoHeight;
    data['video_id'] = this.videoId;
    data['video_size'] = this.videoSize;
    data['video_url'] = this.videoUrl;
    data['video_width'] = this.videoWidth;
    return data;
  }
}
