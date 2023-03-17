part of json_model;

class SearchThreadModel {
  int? no;
  String? threadList;
  SearchThreadModelData? data;

  SearchThreadModel({this.no, this.threadList, this.data});

  SearchThreadModel.fromJson(Map<String, dynamic> json) {
    no = json['no'];
    threadList = json['thread_list'];
    data = json['data'] != null
        ? SearchThreadModelData.fromJson(json['data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['no'] = no;
    data['thread_list'] = threadList;
    if (this.data != null) {
      data['data'] = this.data?.toJson();
    }
    return data;
  }
}

class SearchThreadModelData {
  int? no;
  SearchThreadModelMainData? data;
  String? error;

  SearchThreadModelData({this.no, this.data, this.error});

  SearchThreadModelData.fromJson(Map<String, dynamic> json) {
    no = json['no'];
    data = json['data'] != null
        ? SearchThreadModelMainData.fromJson(json['data'])
        : null;
    error = json['error'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['no'] = no;
    if (this.data != null) {
      data['data'] = this.data?.toJson();
    }
    data['error'] = error;
    return data;
  }
}

class SearchThreadModelMainData {
  bool? illegal;
  SearchForumModelPage? page;
  // Forum? forum;
  String? searchWhat;
  List<SearchThreadPost>? post;
  int? regNum;
  String? searchKey;
  String? searchTurn;
  String? tbs;
  int? totalNum;
  String? kw;

  SearchThreadModelMainData(
      {this.illegal,
      this.page,
      // this.forum,
      this.searchWhat,
      this.post,
      this.regNum,
      this.searchKey,
      this.searchTurn,
      this.tbs,
      this.totalNum,
      this.kw});

  SearchThreadModelMainData.fromJson(Map<String, dynamic> json) {
    illegal = json['illegal'];
    page = json['page'] != null
        ? SearchForumModelPage.fromJson(json['page'])
        : null;
    // forum = json['forum'] != null ? new Forum.fromJson(json['forum']) : null;
    searchWhat = json['search_what'];
    if (json['post'] != null) {
      post = [];
      json['post'].forEach((v) {
        post?.add(SearchThreadPost.fromJson(v));
      });
    }
    regNum = (json['reg_num'] as num).toInt();
    searchKey = json['search_key'];
    searchTurn = json['search_turn'];
    tbs = json['tbs'];
    totalNum = (json['total_num'] as num).toInt();
    kw = json['kw'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['illegal'] = illegal;
    if (page != null) {
      data['page'] = page?.toJson();
    }
    // if (this.forum != null) {
    //   data['forum'] = this.forum?.toJson();
    // }
    data['search_what'] = searchWhat;
    if (post != null) {
      data['post'] = post?.map((v) => v.toJson()).toList();
    }
    data['reg_num'] = regNum;
    data['search_key'] = searchKey;
    data['search_turn'] = searchTurn;
    data['tbs'] = tbs;
    data['total_num'] = totalNum;
    data['kw'] = kw;
    return data;
  }
}

class SearchThreadPost {
  String? tid;
  String? pid;
  String? title;
  String? brief;
  String? time;
  String? url;
  String? forum;
  bool? isReplay;
  Author? author;
  int? replay;
  // List<Null> video;
  // List<Null> audio;
  List<String>? img;

  SearchThreadPost(
      {this.tid,
      this.pid,
      this.title,
      this.brief,
      this.time,
      this.url,
      this.forum,
      this.isReplay,
      this.author,
      this.replay,
      // this.video,
      // this.audio,
      this.img});

  SearchThreadPost.fromJson(Map<String, dynamic> json) {
    tid = json['tid'];
    pid = json['pid'];
    title = json['title'];
    brief = json['brief'];
    time = json['time'];
    url = json['url'];
    forum = json['forum'];
    isReplay = json['is_replay'];
    author = json['author'] != null ? Author.fromJson(json['author']) : null;
    replay = (json['replay'] as num).toInt();
    // if (json['video'] != null) {
    //   video =[];
    //   json['video'].forEach((v) {
    //     video.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['audio'] != null) {
    //   audio = new List<Null>();
    //   json['audio'].forEach((v) {
    //     audio.add(new Null.fromJson(v));
    //   });
    // }
    img = json['img'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tid'] = tid;
    data['pid'] = pid;
    data['title'] = title;
    data['brief'] = brief;
    data['time'] = time;
    data['url'] = url;
    data['forum'] = forum;
    data['is_replay'] = isReplay;
    if (author != null) {
      data['author'] = author?.toJson();
    }
    data['replay'] = replay;
    // if (this.video != null) {
    //   data['video'] = this.video.map((v) => v.toJson()).toList();
    // }
    // if (this.audio != null) {
    //   data['audio'] = this.audio.map((v) => v.toJson()).toList();
    // }
    data['img'] = img;
    return data;
  }
}

///////////////////////////////////////////////////////////////////////////////////
///                       新的搜贴Model
///
///////////////////////////////////////////////////////////////////////////////////

class SearchPostModel {
  int? no;
  String? error;
  SearchPostModelData? data;

  SearchPostModel({this.no, this.error, this.data});

  SearchPostModel.fromJson(Map<String, dynamic> json) {
    no = json['no'];
    error = json['error'];
    data = json['data'] != null
        ? SearchPostModelData.fromJson(json['data'])
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

class SearchPostModelData {
  int? hasMore;
  int? currentPage;
  List<SearchPostModelPostList>? postList;
  // Null? cuid;
  SampleSwitch? sampleSwitch;
  String? tagId;
  int? logId;
  String? ubsSampleIds;
  List<SearchPostModelUbsAbtestConfig>? ubsAbtestConfig;

  SearchPostModelData(
      {this.hasMore,
      this.currentPage,
      this.postList,
      // this.cuid,
      this.sampleSwitch,
      this.tagId,
      this.logId,
      this.ubsSampleIds,
      this.ubsAbtestConfig});

  SearchPostModelData.fromJson(Map<String, dynamic> json) {
    hasMore = (json['has_more'] as num).toInt();
    currentPage = (json['current_page'] as num).toInt();
    if (json['post_list'] != null) {
      postList = [];
      json['post_list'].forEach((v) {
        postList?.add(SearchPostModelPostList.fromJson(v));
      });
    }
    // cuid = json['cuid'];
    sampleSwitch = json['sample_switch'] != null
        ? SampleSwitch.fromJson(json['sample_switch'])
        : null;
    tagId = json['tag_id'];
    logId = (json['log_id'] as num?)?.toInt();
    ubsSampleIds = json['ubs_sample_ids'];
    if (json['ubs_abtest_config'] != null) {
      ubsAbtestConfig = [];
      json['ubs_abtest_config'].forEach((v) {
        ubsAbtestConfig?.add(SearchPostModelUbsAbtestConfig.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['has_more'] = hasMore;
    data['current_page'] = currentPage;
    if (postList != null) {
      data['post_list'] = postList?.map((v) => v.toJson()).toList();
    }
    // data['cuid'] = this.cuid;
    if (sampleSwitch != null) {
      data['sample_switch'] = sampleSwitch?.toJson();
    }
    data['tag_id'] = tagId;
    data['log_id'] = logId;
    data['ubs_sample_ids'] = ubsSampleIds;
    if (ubsAbtestConfig != null) {
      data['ubs_abtest_config'] =
          ubsAbtestConfig?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SearchPostModelPostList {
  String? tid;
  String? pid;
  String? cid;
  int? isCopytwzhibo;
  String? title;
  String? content;
  String? time;
  SearchPostModelUser? user;
  String? postNum;
  List<SearchPostModelMedia>? media;
  int? threadTypes;
  int? likeNum;
  int? shareNum;
  int? duration;
  int? playCount;
  int? basicWeight;
  String? forumId;
  String? pbUrl;
  String? forumName;
  int? type;
  int? threadType;
  SearchPostModelForumInfo? forumInfo;
  MainPost? mainPost;

  SearchPostModelPostList(
      {this.tid,
      this.pid,
      this.cid,
      this.isCopytwzhibo,
      this.title,
      this.content,
      this.time,
      this.user,
      this.postNum,
      this.media,
      this.threadTypes,
      this.likeNum,
      this.shareNum,
      this.duration,
      this.playCount,
      this.basicWeight,
      this.forumId,
      this.pbUrl,
      this.forumName,
      this.type,
      this.threadType,
      this.forumInfo,
      this.mainPost});

  SearchPostModelPostList.fromJson(Map<String, dynamic> json) {
    tid = json['tid'];
    if (json['pid'] is num) {
      pid = (json['pid'] as num).toInt().toString();
    } else if (json['pid'] is String) {
      pid = json['pid'];
    }
    cid = json['cid'];
    isCopytwzhibo = json['is_copytwzhibo'];
    title = json['title'];
    content = json['content'];
    time = json['time'];
    user = json['user'] != null
        ? SearchPostModelUser.fromJson(json['user'])
        : null;
    if (json['post_num'] is String) {
      postNum = json['post_num'];
    } else if (json['post_num'] is num) {
      postNum = (json['post_num'] as num).toString();
    }

    if (json['media'] != null) {
      media = [];
      json['media'].forEach((v) {
        media?.add(SearchPostModelMedia.fromJson(v));
      });
    }
    threadTypes = (json['thread_types'] as num).toInt();
    likeNum = (json['like_num'] as num).toInt();
    shareNum = (json['share_num'] as num).toInt();
    duration = (json['duration'] as num).toInt();
    playCount = (json['play_count'] as num).toInt();
    basicWeight = (json['basicWeight'] as num).toInt();
    if (json['forum_id'] is String) {
      forumId = json['forum_id'];
    } else if (json['forum_id'] is num) {
      forumId = (json['forum_id'] as num).toInt().toString();
    }

    pbUrl = json['pb_url'];
    forumName = json['forum_name'];
    type = (json['type'] as num).toInt();
    threadType = (json['thread_type'] as num).toInt();
    forumInfo = json['forum_info'] != null
        ? SearchPostModelForumInfo.fromJson(json['forum_info'])
        : null;
    mainPost =
        json['main_post'] != null ? MainPost.fromJson(json['main_post']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tid'] = tid;
    data['pid'] = pid;
    data['cid'] = cid;
    data['is_copytwzhibo'] = isCopytwzhibo;
    data['title'] = title;
    data['content'] = content;
    data['time'] = time;
    if (user != null) {
      data['user'] = user?.toJson();
    }
    data['post_num'] = postNum;
    if (media != null) {
      data['media'] = media?.map((v) => v.toJson()).toList();
    }
    data['thread_types'] = threadTypes;
    data['like_num'] = likeNum;
    data['share_num'] = shareNum;
    data['duration'] = duration;
    data['play_count'] = playCount;
    data['basicWeight'] = basicWeight;
    data['forum_id'] = forumId;
    data['pb_url'] = pbUrl;
    data['forum_name'] = forumName;
    data['type'] = type;
    data['thread_type'] = threadType;
    if (forumInfo != null) {
      data['forum_info'] = forumInfo?.toJson();
    }
    if (mainPost != null) {
      data['main_post'] = mainPost?.toJson();
    }
    return data;
  }
}

class SearchPostModelUser {
  String? userName;
  int? userId;
  String? portrait;
  String? portraith;
  VipInfo? vipInfo;
  String? showNickname;

  SearchPostModelUser(
      {this.userName,
      this.userId,
      this.portrait,
      this.portraith,
      this.vipInfo,
      this.showNickname});

  SearchPostModelUser.fromJson(Map<String, dynamic> json) {
    userName = json['user_name'];
    userId = (json['user_id'] as num?)?.toInt();
    portrait = json['portrait'];
    portraith = json['portraith'];
    vipInfo =
        json['vipInfo'] != null ? VipInfo.fromJson(json['vipInfo']) : null;
    showNickname = json['show_nickname'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_name'] = userName;
    data['user_id'] = userId;
    data['portrait'] = portrait;
    data['portraith'] = portraith;
    if (vipInfo != null) {
      data['vipInfo'] = vipInfo?.toJson();
    }
    data['show_nickname'] = showNickname;
    return data;
  }
}

class VipInfo {
  String? aScore;
  String? eTime;
  String? extScore;
  String? iconUrl;
  int? nScore;
  String? sTime;
  String? vLevel;
  String? vStatus;
  int? yScore;

  VipInfo(
      {this.aScore,
      this.eTime,
      this.extScore,
      this.iconUrl,
      this.nScore,
      this.sTime,
      this.vLevel,
      this.vStatus,
      this.yScore});

  VipInfo.fromJson(Map<String, dynamic> json) {
    if (json['a_score'] is String) {
      aScore = json['a_score'];
    } else if (json['a_score'] is num) {
      aScore = (json['a_score'] as num).toInt().toString();
    }

    eTime = json['e_time'].toString();
    extScore = json['ext_score'].toString();
    iconUrl = json['icon_url'];
    if (json['n_score'] is String) {
      nScore = int.parse(json['n_score']);
    } else if (json['n_score'] is num) {
      nScore = (json['n_score'] as num).toInt();
    }
    sTime = json['s_time'].toString();
    if (json['v_level'] is String) {
      vLevel = json['v_level'];
    } else if (json['v_level'] is num) {
      vLevel = (json['v_level'] as num).toInt().toString();
    }

    vStatus = json['v_status'].toString();
    yScore = (json['y_score'] as num?)?.toInt();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['a_score'] = aScore;
    data['e_time'] = eTime;
    data['ext_score'] = extScore;
    data['icon_url'] = iconUrl;
    data['n_score'] = nScore;
    data['s_time'] = sTime;
    data['v_level'] = vLevel;
    data['v_status'] = vStatus;
    data['y_score'] = yScore;
    return data;
  }
}

class SearchPostModelMedia {
  String? type;
  String? size;
  String? width;
  String? height;
  String? waterPic;
  String? smallPic;
  String? bigPic;

  SearchPostModelMedia(
      {this.type,
      this.size,
      this.width,
      this.height,
      this.waterPic,
      this.smallPic,
      this.bigPic});

  SearchPostModelMedia.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    size = json['size'];
    if (json['width'] is num) {
      width = (json['width'] as num).toInt().toString();
    } else if (json['width'] is String) {
      width = json['width'];
    }
    if (json['height'] is num) {
      height = (json['height'] as num).toInt().toString();
    } else if (json['height'] is String) {
      height = json['height'];
    }
    waterPic = json['water_pic'];
    smallPic = json['small_pic'];
    bigPic = json['big_pic'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['size'] = size;
    data['width'] = width;
    data['height'] = height;
    data['water_pic'] = waterPic;
    data['small_pic'] = smallPic;
    data['big_pic'] = bigPic;
    return data;
  }
}

class SearchPostModelForumInfo {
  String? forumName;
  String? avatar;
  String? postNum;
  String? concernNum;

  SearchPostModelForumInfo(
      {this.forumName, this.avatar, this.postNum, this.concernNum});

  SearchPostModelForumInfo.fromJson(Map<String, dynamic> json) {
    forumName = json['forum_name'];
    avatar = json['avatar'];
    if (json['post_num'] is String) {
      postNum = json['post_num'];
    } else if (json['post_num'] is num) {
      postNum = (json['post_num'] as num).toInt().toString();
    }

    if (json['concern_num'] is num) {
      concernNum = (json['concern_num'] as num).toString();
    } else if (json['concern_num'] is String) {
      concernNum = json['concern_num'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['forum_name'] = forumName;
    data['avatar'] = avatar;
    data['post_num'] = postNum;
    data['concern_num'] = concernNum;
    return data;
  }
}

class MainPost {
  String? content;
  String? title;

  MainPost({this.content, this.title});

  MainPost.fromJson(Map<String, dynamic> json) {
    content = json['content'];
    title = json['title'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['content'] = content;
    data['title'] = title;
    return data;
  }
}

class SampleSwitch {
  int? cardStyleOptimize;

  SampleSwitch({this.cardStyleOptimize});

  SampleSwitch.fromJson(Map<String, dynamic> json) {
    cardStyleOptimize = (json['card_style_optimize'] as num).toInt();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['card_style_optimize'] = cardStyleOptimize;
    return data;
  }
}

class SearchPostModelUbsAbtestConfig {
  String? sid;

  SearchPostModelUbsAbtestConfig({this.sid});

  SearchPostModelUbsAbtestConfig.fromJson(Map<String, dynamic> json) {
    sid = json['sid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sid'] = sid;
    return data;
  }
}
