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
  List<Content>? firstPostContent;
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
    id = json['id'].toString();
    tid = json['tid'].toString();
    title = json['title'];
    replyNum = json['reply_num'].toString();
    viewNum = json['view_num'].toString();
    lastTimeInt = json['last_time_int'].toString();
    createTime = json['create_time'].toString();
    userId = json['user_id'];
    isDeleted = json['is_deleted'].toString();
    mediaNum = json['media_num'] != "" && json['media_num'] != null
        ? MediaNum.fromJson(json['media_num'])
        : null;
    author = json['author'] != null ? Author.fromJson(json['author']) : null;
    if (json['media'] != null) {
      media = <Media>[];
      json['media'].forEach((v) {
        media!.add(Media.fromJson(v));
      });
    }
    agree = json['agree'] != null ? Agree.fromJson(json['agree']) : null;
    shareNum = json['share_num'].toString();
    fid = json['fid'].toString();
    fname = json['fname'];
    if (json['first_post_content'] != null) {
      firstPostContent = <Content>[];
      json['first_post_content'].forEach((v) {
        firstPostContent!.add(Content.fromJson(v));
      });
    }
    if (json['thread_personalized'] != null) {
      threadPersonalized = <ThreadPersonalized>[];
      json['thread_personalized'].forEach((v) {
        threadPersonalized!.add(ThreadPersonalized.fromJson(v));
      });
    }
    videoInfo = json['video_info'] != null
        ? VideoInfo.fromJson(json['video_info'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['tid'] = tid;
    data['title'] = title;
    data['reply_num'] = replyNum;
    data['view_num'] = viewNum;
    data['last_time_int'] = lastTimeInt;
    data['create_time'] = createTime;
    data['user_id'] = userId;
    data['is_deleted'] = isDeleted;
    if (mediaNum != null) {
      data['media_num'] = mediaNum!.toJson();
    }
    if (author != null) {
      data['author'] = author!.toJson();
    }
    if (media != null) {
      data['media'] = media!.map((v) => v.toJson()).toList();
    }
    if (agree != null) {
      data['agree'] = agree!.toJson();
    }
    data['share_num'] = shareNum;
    data['fid'] = fid;
    data['fname'] = fname;
    if (firstPostContent != null) {
      data['first_post_content'] =
          firstPostContent!.map((v) => v.toJson()).toList();
    }
    if (threadPersonalized != null) {
      data['thread_personalized'] =
          threadPersonalized!.map((v) => v.toJson()).toList();
    }
    if (videoInfo != null) {
      data['video_info'] = videoInfo?.toJson();
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pic'] = pic;
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
    id = json['id'].toString();
    name = json['name'];
    gender = json['gender'].toString();
    nameShow = json['name_show'];
    portrait = json['portrait'];
    if (json['iconinfo'] != null) {
      iconinfo = <Iconinfo>[];
      json['iconinfo'].forEach((v) {
        iconinfo!.add(Iconinfo.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['gender'] = gender;
    data['name_show'] = nameShow;
    data['portrait'] = portrait;
    if (iconinfo != null) {
      data['iconinfo'] = iconinfo!.map((v) => v.toJson()).toList();
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['icon'] = icon;
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

  String? size;

  String? waterPic;
  String? smallPic;

  String? src;
  String? vsrc;
  String? vhsrc;
  String? vpic;

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
      this.hthMidLoc,
      this.size,
      this.waterPic,
      this.smallPic,
      this.src,
      this.vsrc,
      this.vhsrc,
      this.vpic});

  Media.fromJson(Map<String, dynamic> json) {
    type = json['type'].toString();
    width = json['width'].toString();
    height = json['height'].toString();
    showOriginalBtn = json['show_original_btn'].toString();
    isLongPic = json['is_long_pic'].toString();
    bigPic = json['big_pic'];
    dynamicPic = json['dynamic_pic'];
    srcPic = json['src_pic'];
    originPic = json['origin_pic'];
    originSize = json['origin_size'].toString();
    postId = json['post_id'].toString();
    wthMidLoc = json['wth_mid_loc'].toString();
    hthMidLoc = json['hth_mid_loc'].toString();

    size = json['size'];

    waterPic = json['water_pic'];
    smallPic = json['small_pic'];

    src = json['src'];
    vsrc = json['vsrc'];
    vhsrc = json['vhsrc'];
    vpic = json['vpic'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['width'] = width;
    data['height'] = height;
    data['show_original_btn'] = showOriginalBtn;
    data['is_long_pic'] = isLongPic;
    data['big_pic'] = bigPic;
    data['dynamic_pic'] = dynamicPic;
    data['src_pic'] = srcPic;
    data['origin_pic'] = originPic;
    data['origin_size'] = originSize;
    data['post_id'] = postId;
    data['wth_mid_loc'] = wthMidLoc;
    data['hth_mid_loc'] = hthMidLoc;

    data['size'] = size;

    data['water_pic'] = waterPic;
    data['small_pic'] = smallPic;

    data['src'] = src;
    data['vsrc'] = vsrc;
    data['vhsrc'] = vhsrc;
    data['vpic'] = vpic;
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
    agreeNum = json['agree_num'].toString();
    hasAgree = json['has_agree'].toString();
    agreeType = json['agree_type'].toString();
    disagreeNum = json['disagree_num'].toString();
    diffAgreeNum = json['diff_agree_num'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['agree_num'] = agreeNum;
    data['has_agree'] = hasAgree;
    data['agree_type'] = agreeType;
    data['disagree_num'] = disagreeNum;
    data['diff_agree_num'] = diffAgreeNum;
    return data;
  }
}

// class FirstPostContent {
//   String? type;
//   String? bsize;
//   String? size;
//   String? originSrc;
//   String? originSize;
//   String? isLongPic;
//   String? showOriginalBtn;
//   String? cdnSrc;
//   String? cdnSrcActive;
//   String? bigCdnSrc;
//   String? text;
//   String? c;
//   FirstPostContent(
//       {this.type,
//       this.bsize,
//       this.size,
//       this.originSrc,
//       this.originSize,
//       this.isLongPic,
//       this.showOriginalBtn,
//       this.cdnSrc,
//       this.cdnSrcActive,
//       this.bigCdnSrc,
//       this.text,
//       this.c});

//   FirstPostContent.fromJson(Map<String, dynamic> json) {
//     //0 - 文字
//     //2 - 图片表情?
//     //3 - 图片
//     //5 - 视频
//     type = json['type'].toString();
//     bsize = json['bsize'];
//     size = json['size'];
//     originSrc = json['origin_src'];
//     originSize = json['origin_size'].toString();
//     isLongPic = json['is_long_pic'];
//     showOriginalBtn = json['show_original_btn'];
//     cdnSrc = json['cdn_src'];
//     cdnSrcActive = json['cdn_src_active'];
//     bigCdnSrc = json['big_cdn_src'];
//     text = json['text'];
//     c = json['c'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['type'] = type;
//     data['bsize'] = bsize;
//     data['size'] = size;
//     data['origin_src'] = originSrc;
//     data['origin_size'] = originSize;
//     data['is_long_pic'] = isLongPic;
//     data['show_original_btn'] = showOriginalBtn;
//     data['cdn_src'] = cdnSrc;
//     data['cdn_src_active'] = cdnSrcActive;
//     data['big_cdn_src'] = bigCdnSrc;
//     data['text'] = text;
//     data['c'] = c;
//     return data;
//   }
// }

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
        dislikeResource!.add(DislikeResource.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tid'] = tid;
    data['weight'] = weight;
    data['source'] = source;
    data['abtest_tag'] = abtestTag;
    data['extra'] = extra;
    if (dislikeResource != null) {
      data['dislike_resource'] =
          dislikeResource!.map((v) => v.toJson()).toList();
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['dislike_reason'] = dislikeReason;
    data['dislike_id'] = dislikeId;
    data['extra'] = extra;
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
    thumbnailHeight = json['thumbnail_height'].toString();
    thumbnailPicid = json['thumbnail_picid'];
    thumbnailUrl = json['thumbnail_url'];
    thumbnailWidth = json['thumbnail_width'].toString();
    versionH265 = json['version_h265'];
    if (json['video_desc'] != null) {
      videoDesc = [];
      if (json['video_desc'] is List) {
        json['video_desc'].forEach((v) {
          videoDesc?.add(VideoDesc.fromJson(v));
        });
      } else if (json['video_desc'] is Map) {
        json['video_desc'].forEach((v, f) {
          videoDesc?.add(VideoDesc.fromJson({v: f}));
        });
      } else {
        throw Exception("未知视频类型");
      }
    }
    if (json['video_desc_cae3'] != null) {
      videoDescCae3 = [];
      json['video_desc_cae3'].forEach((v) {
        videoDescCae3?.add(VideoDescCae3.fromJson(v));
      });
    }
    if (json['video_desc_h265'] != null) {
      videoDescH265 = [];
      json['video_desc_h265'].forEach((v) {
        videoDescH265?.add(VideoDescH265.fromJson(v));
      });
    }
    videoDuration = json['video_duration'].toString();
    videoFormat = json['video_format'];
    videoFrom = json['video_from'];
    videoHeight = json['video_height'].toString();
    videoLogId = json['video_log_id'].toString();
    videoMd5 = json['video_md5'];
    videoType = json['video_type'].toString();
    videoUrl = json['video_url'];
    videoWidth = json['video_width'].toString();
    playCount = json['play_count'].toString();
    playTime = json['play_time'].toString();
    videoLength = json['video_length'].toString();
    isVertical = json['is_vertical'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['auditing'] = auditing;
    data['format_matched'] = formatMatched;
    data['ptid'] = ptid;
    data['thumbnail_height'] = thumbnailHeight;
    data['thumbnail_picid'] = thumbnailPicid;
    data['thumbnail_url'] = thumbnailUrl;
    data['thumbnail_width'] = thumbnailWidth;
    data['version_h265'] = versionH265;
    if (videoDesc != null) {
      data['video_desc'] = videoDesc?.map((v) => v.toJson()).toList();
    }
    if (videoDescCae3 != null) {
      data['video_desc_cae3'] = videoDescCae3?.map((v) => v.toJson()).toList();
    }
    if (videoDescH265 != null) {
      data['video_desc_h265'] = videoDescH265?.map((v) => v.toJson()).toList();
    }
    data['video_duration'] = videoDuration;
    data['video_format'] = videoFormat;
    data['video_from'] = videoFrom;
    data['video_height'] = videoHeight;
    data['video_log_id'] = videoLogId;
    data['video_md5'] = videoMd5;
    data['video_type'] = videoType;
    data['video_url'] = videoUrl;
    data['video_width'] = videoWidth;
    data['play_count'] = playCount;
    data['play_time'] = playTime;
    data['video_length'] = videoLength;
    data['is_vertical'] = isVertical;
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
    videoId = json['video_id'].toString();
    videoSize = json['video_size'];
    videoUrl = json['video_url'];
    videoWidth = json['video_width'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['video_height'] = videoHeight;
    data['video_id'] = videoId;
    data['video_size'] = videoSize;
    data['video_url'] = videoUrl;
    data['video_width'] = videoWidth;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['video_height'] = videoHeight;
    data['video_id'] = videoId;
    data['video_size'] = videoSize;
    data['video_url'] = videoUrl;
    data['video_width'] = videoWidth;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['video_height'] = videoHeight;
    data['video_id'] = videoId;
    data['video_size'] = videoSize;
    data['video_url'] = videoUrl;
    data['video_width'] = videoWidth;
    return data;
  }
}
