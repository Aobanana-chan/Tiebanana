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
        ? new SearchThreadModelData.fromJson(json['data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['no'] = this.no;
    data['thread_list'] = this.threadList;
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
        ? new SearchThreadModelMainData.fromJson(json['data'])
        : null;
    error = json['error'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['no'] = this.no;
    if (this.data != null) {
      data['data'] = this.data?.toJson();
    }
    data['error'] = this.error;
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
        ? new SearchForumModelPage.fromJson(json['page'])
        : null;
    // forum = json['forum'] != null ? new Forum.fromJson(json['forum']) : null;
    searchWhat = json['search_what'];
    if (json['post'] != null) {
      post = [];
      json['post'].forEach((v) {
        post?.add(new SearchThreadPost.fromJson(v));
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['illegal'] = this.illegal;
    if (this.page != null) {
      data['page'] = this.page?.toJson();
    }
    // if (this.forum != null) {
    //   data['forum'] = this.forum?.toJson();
    // }
    data['search_what'] = this.searchWhat;
    if (this.post != null) {
      data['post'] = this.post?.map((v) => v.toJson()).toList();
    }
    data['reg_num'] = this.regNum;
    data['search_key'] = this.searchKey;
    data['search_turn'] = this.searchTurn;
    data['tbs'] = this.tbs;
    data['total_num'] = this.totalNum;
    data['kw'] = this.kw;
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
    author =
        json['author'] != null ? new Author.fromJson(json['author']) : null;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tid'] = this.tid;
    data['pid'] = this.pid;
    data['title'] = this.title;
    data['brief'] = this.brief;
    data['time'] = this.time;
    data['url'] = this.url;
    data['forum'] = this.forum;
    data['is_replay'] = this.isReplay;
    if (this.author != null) {
      data['author'] = this.author?.toJson();
    }
    data['replay'] = this.replay;
    // if (this.video != null) {
    //   data['video'] = this.video.map((v) => v.toJson()).toList();
    // }
    // if (this.audio != null) {
    //   data['audio'] = this.audio.map((v) => v.toJson()).toList();
    // }
    data['img'] = this.img;
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
        ? new SearchPostModelData.fromJson(json['data'])
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
        postList?.add(new SearchPostModelPostList.fromJson(v));
      });
    }
    // cuid = json['cuid'];
    sampleSwitch = json['sample_switch'] != null
        ? new SampleSwitch.fromJson(json['sample_switch'])
        : null;
    tagId = json['tag_id'];
    logId = (json['log_id'] as num).toInt();
    ubsSampleIds = json['ubs_sample_ids'];
    if (json['ubs_abtest_config'] != null) {
      ubsAbtestConfig = [];
      json['ubs_abtest_config'].forEach((v) {
        ubsAbtestConfig?.add(new SearchPostModelUbsAbtestConfig.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['has_more'] = this.hasMore;
    data['current_page'] = this.currentPage;
    if (this.postList != null) {
      data['post_list'] = this.postList?.map((v) => v.toJson()).toList();
    }
    // data['cuid'] = this.cuid;
    if (this.sampleSwitch != null) {
      data['sample_switch'] = this.sampleSwitch?.toJson();
    }
    data['tag_id'] = this.tagId;
    data['log_id'] = this.logId;
    data['ubs_sample_ids'] = this.ubsSampleIds;
    if (this.ubsAbtestConfig != null) {
      data['ubs_abtest_config'] =
          this.ubsAbtestConfig?.map((v) => v.toJson()).toList();
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
        ? new SearchPostModelUser.fromJson(json['user'])
        : null;
    if (json['post_num'] is String) {
      postNum = json['post_num'];
    } else if (json['post_num'] is num) {
      postNum = (json['post_num'] as num).toString();
    }

    if (json['media'] != null) {
      media = [];
      json['media'].forEach((v) {
        media?.add(new SearchPostModelMedia.fromJson(v));
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
        ? new SearchPostModelForumInfo.fromJson(json['forum_info'])
        : null;
    mainPost = json['main_post'] != null
        ? new MainPost.fromJson(json['main_post'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tid'] = this.tid;
    data['pid'] = this.pid;
    data['cid'] = this.cid;
    data['is_copytwzhibo'] = this.isCopytwzhibo;
    data['title'] = this.title;
    data['content'] = this.content;
    data['time'] = this.time;
    if (this.user != null) {
      data['user'] = this.user?.toJson();
    }
    data['post_num'] = this.postNum;
    if (this.media != null) {
      data['media'] = this.media?.map((v) => v.toJson()).toList();
    }
    data['thread_types'] = this.threadTypes;
    data['like_num'] = this.likeNum;
    data['share_num'] = this.shareNum;
    data['duration'] = this.duration;
    data['play_count'] = this.playCount;
    data['basicWeight'] = this.basicWeight;
    data['forum_id'] = this.forumId;
    data['pb_url'] = this.pbUrl;
    data['forum_name'] = this.forumName;
    data['type'] = this.type;
    data['thread_type'] = this.threadType;
    if (this.forumInfo != null) {
      data['forum_info'] = this.forumInfo?.toJson();
    }
    if (this.mainPost != null) {
      data['main_post'] = this.mainPost?.toJson();
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
        json['vipInfo'] != null ? new VipInfo.fromJson(json['vipInfo']) : null;
    showNickname = json['show_nickname'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_name'] = this.userName;
    data['user_id'] = this.userId;
    data['portrait'] = this.portrait;
    data['portraith'] = this.portraith;
    if (this.vipInfo != null) {
      data['vipInfo'] = this.vipInfo?.toJson();
    }
    data['show_nickname'] = this.showNickname;
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

    eTime = json['e_time'];
    extScore = json['ext_score'];
    iconUrl = json['icon_url'];
    if (json['n_score'] is String) {
      nScore = int.parse(json['n_score']);
    } else if (json['n_score'] is num) {
      nScore = (json['n_score'] as num).toInt();
    }
    sTime = json['s_time'];
    if (json['v_level'] is String) {
      vLevel = json['v_level'];
    } else if (json['v_level'] is num) {
      vLevel = (json['v_level'] as num).toInt().toString();
    }

    vStatus = json['v_status'];
    yScore = (json['y_score'] as num?)?.toInt();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['a_score'] = this.aScore;
    data['e_time'] = this.eTime;
    data['ext_score'] = this.extScore;
    data['icon_url'] = this.iconUrl;
    data['n_score'] = this.nScore;
    data['s_time'] = this.sTime;
    data['v_level'] = this.vLevel;
    data['v_status'] = this.vStatus;
    data['y_score'] = this.yScore;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['size'] = this.size;
    data['width'] = this.width;
    data['height'] = this.height;
    data['water_pic'] = this.waterPic;
    data['small_pic'] = this.smallPic;
    data['big_pic'] = this.bigPic;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['forum_name'] = this.forumName;
    data['avatar'] = this.avatar;
    data['post_num'] = this.postNum;
    data['concern_num'] = this.concernNum;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['content'] = this.content;
    data['title'] = this.title;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['card_style_optimize'] = this.cardStyleOptimize;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sid'] = this.sid;
    return data;
  }
}
