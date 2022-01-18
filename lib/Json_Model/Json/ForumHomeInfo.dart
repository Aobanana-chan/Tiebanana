part of json_model;

class ForumHomeInfo {
  String? thirdStatisticsParam;
  List<ForumThreadList>? threadList;
  Forum? forum;
  String? fortuneBag;
  String? fortuneDesc;
  UserExtend? userExtend;
  String? videoAutoPlay;
  String? filterSwanThread;
  List? smartAppAvatar;
  String? voiceRoomConfig;
  List? starEnter;
  HotUserEntry? hotUserEntry;
  String? voiceRoomList;
  GconAccount? gconAccount;
  Anti? anti;
  ForumUser? user;
  // BusinessPromot businessPromot;
  // ItemInfo itemInfo;
  ForumPage? page;
  PrivateForumActiveInfo? privateForumActiveInfo;
  FrsStar? frsStar;
  String? gameDefaultTabId;
  List? threadIdList;
  String? isNewUrl;
  List? userPolledRecord;
  List? activityhead;
  // AgreeBanner agreeBanner;
  List<FrsTabInfo>? frsTabInfo;
  String? frsTabDefault;
  String? alaLiveCount;
  List? recomPostTopic;
  List? alaStageList;
  List? bannerThreadList;
  String? showAdsense;
  String? aspShownInfo;
  String? twzhiboPos;
  String? sortType;
  String? needLog;
  String? partialVisibleToast;
  List<UserList>? userList;
  List? frsGameTabInfo;
  String? serverTime;
  int? time;
  int? ctime;
  int? logid;
  String? errorCode;

  ForumHomeInfo(
      {this.thirdStatisticsParam,
      this.threadList,
      this.forum,
      this.fortuneBag,
      this.fortuneDesc,
      this.userExtend,
      this.videoAutoPlay,
      this.filterSwanThread,
      this.smartAppAvatar,
      this.voiceRoomConfig,
      this.starEnter,
      this.hotUserEntry,
      this.voiceRoomList,
      this.gconAccount,
      this.anti,
      this.user,
      // this.businessPromot,
      // this.itemInfo,
      this.page,
      this.privateForumActiveInfo,
      this.frsStar,
      this.gameDefaultTabId,
      this.threadIdList,
      this.isNewUrl,
      this.userPolledRecord,
      this.activityhead,
      // this.agreeBanner,
      this.frsTabInfo,
      this.frsTabDefault,
      this.alaLiveCount,
      this.recomPostTopic,
      this.alaStageList,
      this.bannerThreadList,
      this.showAdsense,
      this.aspShownInfo,
      this.twzhiboPos,
      this.sortType,
      this.needLog,
      this.partialVisibleToast,
      this.userList,
      this.frsGameTabInfo,
      this.serverTime,
      this.time,
      this.ctime,
      this.logid,
      this.errorCode});

  ForumHomeInfo.fromJson(Map<String, dynamic> json) {
    thirdStatisticsParam = json['third_statistics_param'];
    if (json['thread_list'] != null) {
      threadList = [];
      json['thread_list'].forEach((v) {
        threadList?.add(new ForumThreadList.fromJson(v));
      });
    }
    forum = json['forum'] != null ? new Forum.fromJson(json['forum']) : null;
    fortuneBag = json['fortune_bag'];
    fortuneDesc = json['fortune_desc'];
    userExtend = json['user_extend'] != null
        ? new UserExtend.fromJson(json['user_extend'])
        : null;
    videoAutoPlay = json['video_auto_play'];
    filterSwanThread = json['filter_swan_thread'];
    // if (json['smart_app_avatar'] != null) {
    //   smartAppAvatar = [];
    //   json['smart_app_avatar'].forEach((v) {
    //     smartAppAvatar?.add(new Null.fromJson(v));
    //   });
    // }
    voiceRoomConfig = json['voice_room_config'];
    // if (json['star_enter'] != null) {
    //   starEnter = [];
    //   json['star_enter'].forEach((v) {
    //     starEnter?.add(new Null.fromJson(v));
    //   });
    // }
    hotUserEntry = json['hot_user_entry'] != null
        ? new HotUserEntry.fromJson(json['hot_user_entry'])
        : null;
    voiceRoomList = json['voice_room_list'];
    gconAccount = json['gcon_account'] != null
        ? new GconAccount.fromJson(json['gcon_account'])
        : null;
    anti = json['anti'] != null ? new Anti.fromJson(json['anti']) : null;
    user = json['user'] != null ? new ForumUser.fromJson(json['user']) : null;
    // businessPromot = json['business_promot'] != null
    //     ? new BusinessPromot.fromJson(json['business_promot'])
    //     : null;
    // itemInfo = json['item_info'] != null
    //     ? new ItemInfo.fromJson(json['item_info'])
    //     : null;
    page = json['page'] != null ? new ForumPage.fromJson(json['page']) : null;
    privateForumActiveInfo = json['private_forum_active_info'] != null
        ? new PrivateForumActiveInfo.fromJson(json['private_forum_active_info'])
        : null;
    frsStar = json['frs_star'] != null
        ? new FrsStar.fromJson(json['frs_star'])
        : null;
    gameDefaultTabId = json['game_default_tab_id'];
    if (json['thread_id_list'] != null) {
      threadIdList = [];
      json['thread_id_list'].forEach((v) {
        threadIdList?.add(v);
      });
    }
    isNewUrl = json['is_new_url'];
    if (json['user_polled_record'] != null) {
      userPolledRecord = [];
      json['user_polled_record'].forEach((v) {
        userPolledRecord?.add(v);
      });
    }
    if (json['activityhead'] != null) {
      activityhead = [];
      json['activityhead'].forEach((v) {
        activityhead?.add(v);
      });
    }
    // agreeBanner = json['agree_banner'] != null
    //     ? new AgreeBanner.fromJson(json['agree_banner'])
    //     : null;
    if (json['frs_tab_info'] != null) {
      frsTabInfo = [];
      //json['frs_tab_info']有时是Map有时是List，加一个判断
      if (json['frs_tab_info'] is List) {
        (json['frs_tab_info']).forEach((v) {
          frsTabInfo?.add(new FrsTabInfo.fromJson(v));
        });
      } else if (json['frs_tab_info'] is Map) {
        (json['frs_tab_info']).forEach((v, f) {
          frsTabInfo?.add(new FrsTabInfo.fromJson(f));
        });
      } else {
        throw Exception("未知形态frs_tab_info");
      }
    }
    frsTabDefault = json['frs_tab_default'];
    alaLiveCount = json['ala_live_count'];
    if (json['recom_post_topic'] != null) {
      recomPostTopic = [];
      json['recom_post_topic'].forEach((v) {
        recomPostTopic?.add(v);
      });
    }
    if (json['ala_stage_list'] != null) {
      alaStageList = [];
      json['ala_stage_list'].forEach((v) {
        alaStageList?.add(v);
      });
    }
    if (json['banner_thread_list'] != null) {
      bannerThreadList = [];
      json['banner_thread_list'].forEach((v) {
        bannerThreadList?.add(v);
      });
    }
    showAdsense = json['show_adsense'];
    aspShownInfo = json['asp_shown_info'];
    twzhiboPos = json['twzhibo_pos'];
    sortType = json['sort_type'];
    needLog = json['need_log'];
    partialVisibleToast = json['partial_visible_toast'];
    if (json['user_list'] != null) {
      userList = [];
      json['user_list'].forEach((v) {
        userList?.add(new UserList.fromJson(v));
      });
    }
    if (json['frs_game_tab_info'] != null) {
      frsGameTabInfo = [];
      json['frs_game_tab_info'].forEach((v) {
        frsGameTabInfo?.add(v);
      });
    }
    serverTime = json['server_time'];
    time = (json['time'] as double).toInt();
    ctime = json['ctime'];
    logid = (json['logid'] as double).toInt();
    errorCode = json['error_code'];
    for (var thread in threadList ?? []) {
      for (var user in userList ?? []) {
        if (thread.authorId == user.id) {
          thread.author = user;
          break;
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['third_statistics_param'] = this.thirdStatisticsParam;
    if (this.threadList != null) {
      data['thread_list'] = this.threadList?.map((v) => v.toJson()).toList();
    }
    if (this.forum != null) {
      data['forum'] = this.forum?.toJson();
    }
    data['fortune_bag'] = this.fortuneBag;
    data['fortune_desc'] = this.fortuneDesc;
    if (this.userExtend != null) {
      data['user_extend'] = this.userExtend?.toJson();
    }
    data['video_auto_play'] = this.videoAutoPlay;
    data['filter_swan_thread'] = this.filterSwanThread;
    if (this.smartAppAvatar != null) {
      data['smart_app_avatar'] =
          this.smartAppAvatar?.map((v) => v.toJson()).toList();
    }
    data['voice_room_config'] = this.voiceRoomConfig;
    if (this.starEnter != null) {
      data['star_enter'] = this.starEnter?.map((v) => v.toJson()).toList();
    }
    if (this.hotUserEntry != null) {
      data['hot_user_entry'] = this.hotUserEntry?.toJson();
    }
    data['voice_room_list'] = this.voiceRoomList;
    if (this.gconAccount != null) {
      data['gcon_account'] = this.gconAccount?.toJson();
    }
    if (this.anti != null) {
      data['anti'] = this.anti?.toJson();
    }
    if (this.user != null) {
      data['user'] = this.user?.toJson();
    }
    // if (this.businessPromot != null) {
    //   data['business_promot'] = this.businessPromot.toJson();
    // }
    // if (this.itemInfo != null) {
    //   data['item_info'] = this.itemInfo.toJson();
    // }
    if (this.page != null) {
      data['page'] = this.page?.toJson();
    }
    if (this.privateForumActiveInfo != null) {
      data['private_forum_active_info'] = this.privateForumActiveInfo?.toJson();
    }
    if (this.frsStar != null) {
      data['frs_star'] = this.frsStar?.toJson();
    }
    data['game_default_tab_id'] = this.gameDefaultTabId;
    if (this.threadIdList != null) {
      data['thread_id_list'] =
          this.threadIdList?.map((v) => v.toJson()).toList();
    }
    data['is_new_url'] = this.isNewUrl;
    if (this.userPolledRecord != null) {
      data['user_polled_record'] =
          this.userPolledRecord?.map((v) => v.toJson()).toList();
    }
    if (this.activityhead != null) {
      data['activityhead'] = this.activityhead?.map((v) => v.toJson()).toList();
    }
    // if (this.agreeBanner != null) {
    //   data['agree_banner'] = this.agreeBanner.toJson();
    // }
    if (this.frsTabInfo != null) {
      data['frs_tab_info'] = this.frsTabInfo?.map((v) => v.toJson()).toList();
    }
    data['frs_tab_default'] = this.frsTabDefault;
    data['ala_live_count'] = this.alaLiveCount;
    if (this.recomPostTopic != null) {
      data['recom_post_topic'] =
          this.recomPostTopic?.map((v) => v.toJson()).toList();
    }
    if (this.alaStageList != null) {
      data['ala_stage_list'] =
          this.alaStageList?.map((v) => v.toJson()).toList();
    }
    if (this.bannerThreadList != null) {
      data['banner_thread_list'] =
          this.bannerThreadList?.map((v) => v.toJson()).toList();
    }
    data['show_adsense'] = this.showAdsense;
    data['asp_shown_info'] = this.aspShownInfo;
    data['twzhibo_pos'] = this.twzhiboPos;
    data['sort_type'] = this.sortType;
    data['need_log'] = this.needLog;
    data['partial_visible_toast'] = this.partialVisibleToast;
    if (this.userList != null) {
      data['user_list'] = this.userList?.map((v) => v.toJson()).toList();
    }
    if (this.frsGameTabInfo != null) {
      data['frs_game_tab_info'] =
          this.frsGameTabInfo?.map((v) => v.toJson()).toList();
    }
    data['server_time'] = this.serverTime;
    data['time'] = this.time;
    data['ctime'] = this.ctime;
    data['logid'] = this.logid;
    data['error_code'] = this.errorCode;
    return data;
  }
}

class ForumThreadList extends ThreadRecommendSummary {
  // String id;
  // String tid;
  String? nid;
  String? threadId;
  String? originalTid;
  // String title;
  // String replyNum;
  // String viewNum;
  String? lastTime;
  // String lastTimeInt;
  String? threadTypes;
  // String createTime;
  String? tShareImg;
  String? agreeNum;
  String? disagreeNum;
  String? isPartialVisible;
  String? shareNum;
  String? isProThread;
  String? tiebaplusCantDelete;
  List<FirstPostContent>? firstPostContent;
  String? topAgreePostId;
  String? isTop;
  String? isGood;
  String? isNtitle;
  String? isMembertop;
  String? isNovel;
  String? isNovelThank;
  String? isNovelReward;
  String? isBookChapter;
  // List<Null> bookChapter;
  String? isNotice;
  String? commentNum;
  String? isProtal;
  String? isBakan;
  String? isVote;
  // String mediaNum;
  String? meizhiPic;
  List<Media>? media;
  List<Abstract>? abstract;
  String? firstPostId;
  // String? zan;
  // List<Null> location;
  String? isVoiceThread;
  String? threadType;
  List? voiceInfo;
  String? isActivity;
  Agree? agree;
  // String fid;
  String? postList;
  String? authorId;
  String? tabId;
  String? tabName;

  ForumThreadList({
    // this.id,
    // this.tid,
    // this.nid,
    this.threadId,
    // this.originalTid,
    // this.title,
    // this.replyNum,
    // this.viewNum,
    this.lastTime,
    // this.lastTimeInt,
    this.threadTypes,
    // this.createTime,
    this.tShareImg,
    this.agreeNum,
    // this.disagreeNum,
    this.isPartialVisible,
    // this.shareNum,
    // this.isProThread,
    // this.tiebaplusCantDelete,
    // this.firstPostContent,
    // this.topAgreePostId,
    this.isTop,
    // this.isGood,
    // this.isNtitle,
    this.isMembertop,
    // this.isNovel,
    this.isNovelThank,
    // this.isNovelReward,
    this.isBookChapter,
    // this.bookChapter,
    // this.isNotice,
    // this.commentNum,
    this.isProtal,
    // this.isBakan,
    this.isVote,
    // this.mediaNum,
    // this.meizhiPic,
    this.media,
    // this.abstract,
    this.firstPostId,
    // this.zan,
    // this.location,
    // this.isVoiceThread,
    // this.threadType,
    this.voiceInfo,
    // this.isActivity,
    this.agree,
    // this.fid,
    this.postList,
    // this.authorId,
    this.tabId,
    this.tabName,
  });
  ForumThreadList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tid = json['tid'];
    nid = json['nid'];
    threadId = json['thread_id'];
    originalTid = json['original_tid'];
    title = json['title'];
    replyNum = json['reply_num'];
    viewNum = json['view_num'];
    lastTime = json['last_time'];
    lastTimeInt = json['last_time_int'];
    threadTypes = json['thread_types'];
    createTime = json['create_time'];
    tShareImg = json['t_share_img'];
    agreeNum = json['agree_num'];
    disagreeNum = json['disagree_num'];
    isPartialVisible = json['is_partial_visible'];
    shareNum = json['share_num'];
    isProThread = json['is_pro_thread'];
    tiebaplusCantDelete = json['tiebaplus_cant_delete'];
    if (json['first_post_content'] != "") {
      firstPostContent = [];
      json['first_post_content'].forEach((v) {
        firstPostContent?.add(new FirstPostContent.fromJson(v));
      });
    }
    topAgreePostId = json['top_agree_post_id'];
    isTop = json['is_top'];
    isGood = json['is_good'];
    isNtitle = json['is_ntitle'];
    isMembertop = json['is_membertop'];
    isNovel = json['is_novel'];
    isNovelThank = json['is_novel_thank'];
    isNovelReward = json['is_novel_reward'];
    isBookChapter = json['is_book_chapter'];
    // if (json['book_chapter'] != null) {
    //   bookChapter = [];
    //   json['book_chapter'].forEach((v) {
    //     bookChapter.add(v);
    //   });
    // }
    isNotice = json['is_notice'];
    commentNum = json['comment_num'];
    isProtal = json['is_protal'];
    isBakan = json['is_bakan'];
    isVote = json['is_vote'];
    mediaNum = json['media_num'] == "" ? null : json['media_num'];
    meizhiPic = json['meizhi_pic'];
    if (json['media'] != "") {
      media = [];
      json['media'].forEach((v) {
        media?.add(new Media.fromJson(v));
      });
    }
    if (json['abstract'] != null) {
      abstract = [];
      json['abstract'].forEach((v) {
        abstract?.add(new Abstract.fromJson(v));
      });
    }
    firstPostId = json['first_post_id'];
    // zan = json['zan'];
    // if (json['location'] != null) {
    //   location = new List<Null>();
    //   json['location'].forEach((v) {
    //     location.add(new Null.fromJson(v));
    //   });
    // }
    isVoiceThread = json['is_voice_thread'];
    threadType = json['thread_type'];
    if (json['voice_info'] is String && json['voice_info'] != "") {
      voiceInfo = [];
      json['voice_info'].forEach((v) {
        voiceInfo?.add(v);
      });
    }
    isActivity = json['is_activity'];
    agree = json['agree'] != "" ? new Agree.fromJson(json['agree']) : null;
    fid = json['fid'];
    postList = json['post_list'];
    authorId = json['author_id'];
    tabId = json['tab_id'];
    tabName = json['tab_name'];
    videoInfo = json['video_info'] != ""
        ? new VideoInfo.fromJson(json['video_info'])
        : null;
    userId = json['user_id'];
    fname = json['fname'];

    agree = Agree(agreeNum: agreeNum, disagreeNum: disagreeNum);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['tid'] = this.tid;
    data['nid'] = this.nid;
    data['thread_id'] = this.threadId;
    data['original_tid'] = this.originalTid;
    data['title'] = this.title;
    data['reply_num'] = this.replyNum;
    data['view_num'] = this.viewNum;
    data['last_time'] = this.lastTime;
    data['last_time_int'] = this.lastTimeInt;
    data['thread_types'] = this.threadTypes;
    data['create_time'] = this.createTime;
    data['t_share_img'] = this.tShareImg;
    data['agree_num'] = this.agreeNum;
    data['disagree_num'] = this.disagreeNum;
    data['is_partial_visible'] = this.isPartialVisible;
    data['share_num'] = this.shareNum;
    data['is_pro_thread'] = this.isProThread;
    data['tiebaplus_cant_delete'] = this.tiebaplusCantDelete;
    if (this.firstPostContent != null) {
      data['first_post_content'] =
          this.firstPostContent?.map((v) => v.toJson()).toList();
    }
    data['top_agree_post_id'] = this.topAgreePostId;
    data['is_top'] = this.isTop;
    data['is_good'] = this.isGood;
    data['is_ntitle'] = this.isNtitle;
    data['is_membertop'] = this.isMembertop;
    data['is_novel'] = this.isNovel;
    data['is_novel_thank'] = this.isNovelThank;
    data['is_novel_reward'] = this.isNovelReward;
    data['is_book_chapter'] = this.isBookChapter;
    // if (this.bookChapter != null) {
    //   data['book_chapter'] = this.bookChapter.map((v) => v.toJson()).toList();
    // }
    data['is_notice'] = this.isNotice;
    data['comment_num'] = this.commentNum;
    data['is_protal'] = this.isProtal;
    data['is_bakan'] = this.isBakan;
    data['is_vote'] = this.isVote;
    data['media_num'] = this.mediaNum;
    data['meizhi_pic'] = this.meizhiPic;
    if (this.media != null) {
      data['media'] = this.media?.map((v) => v.toJson()).toList();
    }
    if (this.abstract != null) {
      data['abstract'] = this.abstract?.map((v) => v.toJson()).toList();
    }
    data['first_post_id'] = this.firstPostId;
    // data['zan'] = this.zan;
    // if (this.location != null) {
    //   data['location'] = this.location.map((v) => v.toJson()).toList();
    // }
    data['is_voice_thread'] = this.isVoiceThread;
    data['thread_type'] = this.threadType;
    if (this.voiceInfo != null) {
      data['voice_info'] = this.voiceInfo?.map((v) => v.toJson()).toList();
    }
    data['is_activity'] = this.isActivity;
    if (this.agree != null) {
      data['agree'] = this.agree?.toJson();
    }
    data['fid'] = this.fid;
    data['post_list'] = this.postList;
    data['author_id'] = this.authorId;
    data['tab_id'] = this.tabId;
    data['tab_name'] = this.tabName;
    return data;
  }
}

class Abstract {
  String? type;
  String? text;

  Abstract({this.type, this.text});

  Abstract.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    text = json['text'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['text'] = this.text;
    return data;
  }
}

class Forum {
  // List<Null> badges;
  String? accelerateCotent;
  String? canUseAccelerate;
  String? id;
  String? name;
  String? fShareImg;
  String? firstClass;
  String? secondClass;
  String? isLike;
  String? userLevel;
  String? levelId;
  String? levelName;
  String? curScore;
  String? levelupScore;
  String? memberNum;
  String? isExists;
  String? threadNum;
  String? postNum;
  List<GoodClassify>? goodClassify;
  List<Managers>? managers;
  SignInInfo? signInInfo;
  String? albumOpenPhotoFrs;
  String? isReadonly;
  String? isSearchPeople;
  String? isStageForum;
  ForumvipShowIcon? forumvipShowIcon;
  String? isLiveGameForum;
  String? isNewGameForum;
  String? forumGameLabel;
  // List<Null> topNotice;
  String? slogan;
  String? avatar;
  String? hasGame;
  String? hasFrsStar;
  // ThemeColor? themeColor;
  // ForumButton? forumButton;
  // AnchorPower? anchorPower;
  // List<Null> forumSignCalendar;
  TagInfo? tagInfo;
  // Banner? banner;
  String? isShowAllTopThread;
  BannerList? bannerList;
  String? tids;

  Forum(
      {
      // this.badges,
      this.accelerateCotent,
      this.canUseAccelerate,
      this.id,
      this.name,
      this.fShareImg,
      this.firstClass,
      this.secondClass,
      this.isLike,
      this.userLevel,
      this.levelId,
      this.levelName,
      this.curScore,
      this.levelupScore,
      this.memberNum,
      this.isExists,
      this.threadNum,
      this.postNum,
      this.goodClassify,
      this.managers,
      this.signInInfo,
      this.albumOpenPhotoFrs,
      this.isReadonly,
      this.isSearchPeople,
      this.isStageForum,
      this.forumvipShowIcon,
      this.isLiveGameForum,
      this.isNewGameForum,
      this.forumGameLabel,
      // this.topNotice,
      this.slogan,
      this.avatar,
      this.hasGame,
      this.hasFrsStar,
      // this.themeColor,
      // this.forumButton,
      // this.anchorPower,
      // this.forumSignCalendar,
      this.tagInfo,
      // this.banner,
      this.isShowAllTopThread,
      this.bannerList,
      this.tids});

  Forum.fromJson(Map<String, dynamic> json) {
    // if (json['badges'] != null) {
    //   badges = new List<Null>();
    //   json['badges'].forEach((v) {
    //     badges.add(new Null.fromJson(v));
    //   });
    // }
    accelerateCotent = json['accelerate_cotent'];
    canUseAccelerate = json['can_use_accelerate'];
    id = json['id'];
    name = json['name'];
    fShareImg = json['f_share_img'];
    firstClass = json['first_class'];
    secondClass = json['second_class'];
    isLike = json['is_like'];
    userLevel = json['user_level'];
    levelId = json['level_id'];
    levelName = json['level_name'];
    curScore = json['cur_score'];
    levelupScore = json['levelup_score'];
    memberNum = json['member_num'];
    isExists = json['is_exists'];
    threadNum = json['thread_num'];
    postNum = json['post_num'];
    if (json['good_classify'] != null) {
      goodClassify = [];
      json['good_classify'].forEach((v) {
        goodClassify?.add(new GoodClassify.fromJson(v));
      });
    }
    if (json['managers'] != null) {
      managers = [];
      json['managers'].forEach((v) {
        managers?.add(new Managers.fromJson(v));
      });
    }
    signInInfo = json['sign_in_info'] != null
        ? new SignInInfo.fromJson(json['sign_in_info'])
        : null;
    albumOpenPhotoFrs = json['album_open_photo_frs'];
    isReadonly = json['is_readonly'];
    isSearchPeople = json['is_search_people'];
    isStageForum = json['is_stage_forum'];
    forumvipShowIcon = json['forumvip_show_icon'] != null
        ? new ForumvipShowIcon.fromJson(json['forumvip_show_icon'])
        : null;
    isLiveGameForum = json['is_live_game_forum'];
    isNewGameForum = json['is_new_game_forum'];
    forumGameLabel = json['forum_game_label'];
    // if (json['top_notice'] != null) {
    //   topNotice = new List<Null>();
    //   json['top_notice'].forEach((v) {
    //     topNotice.add(new Null.fromJson(v));
    //   });
    // }
    slogan = json['slogan'];
    avatar = json['avatar'];
    hasGame = json['has_game'];
    hasFrsStar = json['has_frs_star'];
    // themeColor = json['theme_color'] != null
    //     ? new ThemeColor.fromJson(json['theme_color'])
    //     : null;
    // forumButton = json['forum_button'] != null
    //     ? new ForumButton.fromJson(json['forum_button'])
    //     : null;
    // anchorPower = json['anchor_power'] != null
    //     ? new AnchorPower.fromJson(json['anchor_power'])
    //     : null;
    // if (json['forum_sign_calendar'] != null) {
    //   forumSignCalendar = new List<Null>();
    //   json['forum_sign_calendar'].forEach((v) {
    //     forumSignCalendar.add(new Null.fromJson(v));
    //   });
    // }
    tagInfo =
        json['tag_info'] != "" ? new TagInfo.fromJson(json['tag_info']) : null;
    // banner =
    //     json['banner'] != null ? new Banner.fromJson(json['banner']) : null;
    isShowAllTopThread = json['is_show_all_top_thread'];
    bannerList = json['banner_list'] != null
        ? new BannerList.fromJson(json['banner_list'])
        : null;
    tids = json['tids'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    // if (this.badges != null) {
    //   data['badges'] = this.badges.map((v) => v.toJson()).toList();
    // }
    data['accelerate_cotent'] = this.accelerateCotent;
    data['can_use_accelerate'] = this.canUseAccelerate;
    data['id'] = this.id;
    data['name'] = this.name;
    data['f_share_img'] = this.fShareImg;
    data['first_class'] = this.firstClass;
    data['second_class'] = this.secondClass;
    data['is_like'] = this.isLike;
    data['user_level'] = this.userLevel;
    data['level_id'] = this.levelId;
    data['level_name'] = this.levelName;
    data['cur_score'] = this.curScore;
    data['levelup_score'] = this.levelupScore;
    data['member_num'] = this.memberNum;
    data['is_exists'] = this.isExists;
    data['thread_num'] = this.threadNum;
    data['post_num'] = this.postNum;
    if (this.goodClassify != null) {
      data['good_classify'] =
          this.goodClassify?.map((v) => v.toJson()).toList();
    }
    if (this.managers != null) {
      data['managers'] = this.managers?.map((v) => v.toJson()).toList();
    }
    if (this.signInInfo != null) {
      data['sign_in_info'] = this.signInInfo?.toJson();
    }
    data['album_open_photo_frs'] = this.albumOpenPhotoFrs;
    data['is_readonly'] = this.isReadonly;
    data['is_search_people'] = this.isSearchPeople;
    data['is_stage_forum'] = this.isStageForum;
    if (this.forumvipShowIcon != null) {
      data['forumvip_show_icon'] = this.forumvipShowIcon?.toJson();
    }
    data['is_live_game_forum'] = this.isLiveGameForum;
    data['is_new_game_forum'] = this.isNewGameForum;
    data['forum_game_label'] = this.forumGameLabel;
    // if (this.topNotice != null) {
    //   data['top_notice'] = this.topNotice.map((v) => v.toJson()).toList();
    // }
    data['slogan'] = this.slogan;
    data['avatar'] = this.avatar;
    data['has_game'] = this.hasGame;
    data['has_frs_star'] = this.hasFrsStar;
    // if (this.themeColor != null) {
    //   data['theme_color'] = this.themeColor?.toJson();
    // }
    // if (this.forumButton != null) {
    //   data['forum_button'] = this.forumButton?.toJson();
    // }
    // if (this.anchorPower != null) {
    //   data['anchor_power'] = this.anchorPower?.toJson();
    // }
    // if (this.forumSignCalendar != null) {
    //   data['forum_sign_calendar'] =
    //       this.forumSignCalendar.map((v) => v.toJson()).toList();
    // }
    if (this.tagInfo != null) {
      data['tag_info'] = this.tagInfo?.toJson();
    }
    // if (this.banner != null) {
    //   data['banner'] = this.banner?.toJson();
    // }
    data['is_show_all_top_thread'] = this.isShowAllTopThread;
    if (this.bannerList != null) {
      data['banner_list'] = this.bannerList?.toJson();
    }
    data['tids'] = this.tids;
    return data;
  }
}

class GoodClassify {
  String? classId;
  String? className;

  GoodClassify({this.classId, this.className});

  GoodClassify.fromJson(Map<String, dynamic> json) {
    classId = json['class_id'];
    className = json['class_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['class_id'] = this.classId;
    data['class_name'] = this.className;
    return data;
  }
}

class Managers {
  String? id;
  String? name;
  String? showName;
  String? portrait;

  Managers({this.id, this.name, this.showName, this.portrait});

  Managers.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    showName = json['show_name'];
    portrait = json['portrait'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['show_name'] = this.showName;
    data['portrait'] = this.portrait;
    return data;
  }
}

class SignInInfo {
  ForumUserInfo? userInfo;
  ForumInfo? forumInfo;

  SignInInfo({this.userInfo, this.forumInfo});

  SignInInfo.fromJson(Map<String, dynamic> json) {
    userInfo = json['user_info'] != null
        ? new ForumUserInfo.fromJson(json['user_info'])
        : null;
    forumInfo = json['forum_info'] != null
        ? new ForumInfo.fromJson(json['forum_info'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.userInfo != null) {
      data['user_info'] = this.userInfo?.toJson();
    }
    if (this.forumInfo != null) {
      data['forum_info'] = this.forumInfo?.toJson();
    }
    return data;
  }
}

class ForumUserInfo {
  String? userId;
  String? isSignIn;
  String? userSignRank;
  String? signTime;
  String? contSignNum;
  String? coutTotalSingNum;
  String? hunSignNum;
  String? totalResignNum;
  String? isOrgDisabled;
  String? cSignNum;
  String? missSignNum;

  ForumUserInfo(
      {this.userId,
      this.isSignIn,
      this.userSignRank,
      this.signTime,
      this.contSignNum,
      this.coutTotalSingNum,
      this.hunSignNum,
      this.totalResignNum,
      this.isOrgDisabled,
      this.cSignNum,
      this.missSignNum});

  ForumUserInfo.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    isSignIn = json['is_sign_in'];
    userSignRank = json['user_sign_rank'];
    signTime = json['sign_time'];
    contSignNum = json['cont_sign_num'];
    coutTotalSingNum = json['cout_total_sing_num'];
    hunSignNum = json['hun_sign_num'];
    totalResignNum = json['total_resign_num'];
    isOrgDisabled = json['is_org_disabled'];
    cSignNum = json['c_sign_num'];
    missSignNum = json['miss_sign_num'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['is_sign_in'] = this.isSignIn;
    data['user_sign_rank'] = this.userSignRank;
    data['sign_time'] = this.signTime;
    data['cont_sign_num'] = this.contSignNum;
    data['cout_total_sing_num'] = this.coutTotalSingNum;
    data['hun_sign_num'] = this.hunSignNum;
    data['total_resign_num'] = this.totalResignNum;
    data['is_org_disabled'] = this.isOrgDisabled;
    data['c_sign_num'] = this.cSignNum;
    data['miss_sign_num'] = this.missSignNum;
    return data;
  }
}

class ForumInfo {
  String? isOn;
  String? isFilter;
  CurrentRankInfo? currentRankInfo;

  ForumInfo({this.isOn, this.isFilter, this.currentRankInfo});

  ForumInfo.fromJson(Map<String, dynamic> json) {
    isOn = json['is_on'];
    isFilter = json['is_filter'];
    currentRankInfo = json['current_rank_info'] != null
        ? new CurrentRankInfo.fromJson(json['current_rank_info'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_on'] = this.isOn;
    data['is_filter'] = this.isFilter;
    if (this.currentRankInfo != null) {
      data['current_rank_info'] = this.currentRankInfo?.toJson();
    }
    return data;
  }
}

class CurrentRankInfo {
  String? signCount;
  String? signRank;

  CurrentRankInfo({this.signCount, this.signRank});

  CurrentRankInfo.fromJson(Map<String, dynamic> json) {
    signCount = json['sign_count'];
    signRank = json['sign_rank'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sign_count'] = this.signCount;
    data['sign_rank'] = this.signRank;
    return data;
  }
}

class ForumvipShowIcon {
  String? icon;
  String? name;
  String? url;

  ForumvipShowIcon({this.icon, this.name, this.url});

  ForumvipShowIcon.fromJson(Map<String, dynamic> json) {
    icon = json['icon'];
    name = json['name'];
    url = json['url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['icon'] = this.icon;
    data['name'] = this.name;
    data['url'] = this.url;
    return data;
  }
}

// class ThemeColor {
//   Dark dark;
//   Dark day;
//   Dark night;

//   ThemeColor({this.dark, this.day, this.night});

//   ThemeColor.fromJson(Map<String, dynamic> json) {
//     dark = json['dark'] != null ? new Dark.fromJson(json['dark']) : null;
//     day = json['day'] != null ? new Dark.fromJson(json['day']) : null;
//     night = json['night'] != null ? new Dark.fromJson(json['night']) : null;
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.dark != null) {
//       data['dark'] = this.dark.toJson();
//     }
//     if (this.day != null) {
//       data['day'] = this.day.toJson();
//     }
//     if (this.night != null) {
//       data['night'] = this.night.toJson();
//     }
//     return data;
//   }
// }

// class Dark {
//   String commonColor;
//   String darkColor;
//   String fontColor;
//   String lightColor;
//   String patternImage;

//   Dark(
//       {this.commonColor,
//       this.darkColor,
//       this.fontColor,
//       this.lightColor,
//       this.patternImage});

//   Dark.fromJson(Map<String, dynamic> json) {
//     commonColor = json['common_color'];
//     darkColor = json['dark_color'];
//     fontColor = json['font_color'];
//     lightColor = json['light_color'];
//     patternImage = json['pattern_image'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['common_color'] = this.commonColor;
//     data['dark_color'] = this.darkColor;
//     data['font_color'] = this.fontColor;
//     data['light_color'] = this.lightColor;
//     data['pattern_image'] = this.patternImage;
//     return data;
//   }
// }

// class ForumButton {
//   String isBlueV;

//   ForumButton({this.isBlueV});

//   ForumButton.fromJson(Map<String, dynamic> json) {
//     isBlueV = json['is_blueV'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['is_blueV'] = this.isBlueV;
//     return data;
//   }
// }

// class AnchorPower {
//   String havePower;
//   String anchorMessage;

//   AnchorPower({this.havePower, this.anchorMessage});

//   AnchorPower.fromJson(Map<String, dynamic> json) {
//     havePower = json['have_power'];
//     anchorMessage = json['anchor_message'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['have_power'] = this.havePower;
//     data['anchor_message'] = this.anchorMessage;
//     return data;
//   }
// }

class TagInfo {
  String? tagId;
  String? tagName;
  String? color;

  TagInfo({this.tagId, this.tagName, this.color});

  TagInfo.fromJson(Map<String, dynamic> json) {
    tagId = json['tag_id'];
    tagName = json['tag_name'];
    color = json['color'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tag_id'] = this.tagId;
    data['tag_name'] = this.tagName;
    data['color'] = this.color;
    return data;
  }
}

// class Banner {
//   String? type;
//   String? desc;

//   Banner({this.type, this.desc});

//   Banner.fromJson(Map<String, dynamic> json) {
//     type = json['type'];
//     desc = json['desc'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['type'] = this.type;
//     data['desc'] = this.desc;
//     return data;
//   }
// }

class BannerList {
  List<App>? app;

  BannerList({this.app});

  BannerList.fromJson(Map<String, dynamic> json) {
    if (json['app'] != null) {
      app = [];
      json['app'].forEach((v) {
        app?.add(new App.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.app != null) {
      data['app'] = this.app?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class App {
  String? id;
  String? name;
  String? urlType;
  String? url;
  String? iosUrl;
  String? apkUrl;
  String? deepUrl;
  String? apkName;
  String? posName;
  String? firstName;
  String? secondName;
  String? cpid;
  String? abtest;
  String? planId;
  String? userId;
  String? price;
  String? verify;
  String? extInfo;
  List<GoodsInfo>? goodsInfo;
  String? locCode;
  String? appTime;

  App(
      {this.id,
      this.name,
      this.urlType,
      this.url,
      this.iosUrl,
      this.apkUrl,
      this.deepUrl,
      this.apkName,
      this.posName,
      this.firstName,
      this.secondName,
      this.cpid,
      this.abtest,
      this.planId,
      this.userId,
      this.price,
      this.verify,
      this.extInfo,
      this.goodsInfo,
      this.locCode,
      this.appTime});

  App.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    urlType = json['url_type'];
    url = json['url'];
    iosUrl = json['ios_url'];
    apkUrl = json['apk_url'];
    deepUrl = json['deep_url'];
    apkName = json['apk_name'];
    posName = json['pos_name'];
    firstName = json['first_name'];
    secondName = json['second_name'];
    cpid = json['cpid'];
    abtest = json['abtest'];
    planId = json['plan_id'];
    userId = json['user_id'];
    price = json['price'];
    verify = json['verify'];
    extInfo = json['ext_info'];
    if (json['goods_info'] != null) {
      goodsInfo = [];
      json['goods_info'].forEach((v) {
        goodsInfo?.add(new GoodsInfo.fromJson(v));
      });
    }
    locCode = json['loc_code'];
    appTime = json['app_time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['url_type'] = this.urlType;
    data['url'] = this.url;
    data['ios_url'] = this.iosUrl;
    data['apk_url'] = this.apkUrl;
    data['deep_url'] = this.deepUrl;
    data['apk_name'] = this.apkName;
    data['pos_name'] = this.posName;
    data['first_name'] = this.firstName;
    data['second_name'] = this.secondName;
    data['cpid'] = this.cpid;
    data['abtest'] = this.abtest;
    data['plan_id'] = this.planId;
    data['user_id'] = this.userId;
    data['price'] = this.price;
    data['verify'] = this.verify;
    data['ext_info'] = this.extInfo;
    if (this.goodsInfo != null) {
      data['goods_info'] = this.goodsInfo?.map((v) => v.toJson()).toList();
    }
    data['loc_code'] = this.locCode;
    data['app_time'] = this.appTime;
    return data;
  }
}

class GoodsInfo {
  String? id;
  String? userName;
  String? userPortrait;
  String? threadTitle;
  String? threadPic;
  String? popWindowText;
  String? goodsStyle;
  String? labelVisible;
  String? labelText;
  String? buttonText;
  String? buttonUrl;
  String? adSource;
  String? legoCard;
  String? cardDesc;
  String? cardTag;
  String? width;
  String? height;
  String? labelMeasure;
  String? tagName;
  String? tagNameUrl;
  String? tagNameWh;
  CloseInfo? closeInfo;

  GoodsInfo(
      {this.id,
      this.userName,
      this.userPortrait,
      this.threadTitle,
      this.threadPic,
      this.popWindowText,
      this.goodsStyle,
      this.labelVisible,
      this.labelText,
      this.buttonText,
      this.buttonUrl,
      this.adSource,
      this.legoCard,
      this.cardDesc,
      this.cardTag,
      this.width,
      this.height,
      this.labelMeasure,
      this.tagName,
      this.tagNameUrl,
      this.tagNameWh,
      this.closeInfo});

  GoodsInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userName = json['user_name'];
    userPortrait = json['user_portrait'];
    threadTitle = json['thread_title'];
    threadPic = json['thread_pic'];
    popWindowText = json['pop_window_text'];
    goodsStyle = json['goods_style'];
    labelVisible = json['label_visible'];
    labelText = json['label_text'];
    buttonText = json['button_text'];
    buttonUrl = json['button_url'];
    adSource = json['ad_source'];
    legoCard = json['lego_card'];
    cardDesc = json['card_desc'];
    cardTag = json['card_tag'];
    width = json['width'];
    height = json['height'];
    labelMeasure = json['label_measure'];
    tagName = json['tag_name'];
    tagNameUrl = json['tag_name_url'];
    tagNameWh = json['tag_name_wh'];
    closeInfo = json['close_info'] != null
        ? new CloseInfo.fromJson(json['close_info'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_name'] = this.userName;
    data['user_portrait'] = this.userPortrait;
    data['thread_title'] = this.threadTitle;
    data['thread_pic'] = this.threadPic;
    data['pop_window_text'] = this.popWindowText;
    data['goods_style'] = this.goodsStyle;
    data['label_visible'] = this.labelVisible;
    data['label_text'] = this.labelText;
    data['button_text'] = this.buttonText;
    data['button_url'] = this.buttonUrl;
    data['ad_source'] = this.adSource;
    data['lego_card'] = this.legoCard;
    data['card_desc'] = this.cardDesc;
    data['card_tag'] = this.cardTag;
    data['width'] = this.width;
    data['height'] = this.height;
    data['label_measure'] = this.labelMeasure;
    data['tag_name'] = this.tagName;
    data['tag_name_url'] = this.tagNameUrl;
    data['tag_name_wh'] = this.tagNameWh;
    if (this.closeInfo != null) {
      data['close_info'] = this.closeInfo?.toJson();
    }
    return data;
  }
}

class CloseInfo {
  String? supportClose;
  List<String>? reasons;
  ActionControl? actionControl;

  CloseInfo({this.supportClose, this.reasons, this.actionControl});

  CloseInfo.fromJson(Map<String, dynamic> json) {
    supportClose = json['support_close'];
    reasons = json['reasons'].cast<String>();
    actionControl = json['action_control'] != null
        ? new ActionControl.fromJson(json['action_control'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['support_close'] = this.supportClose;
    data['reasons'] = this.reasons;
    if (this.actionControl != null) {
      data['action_control'] = this.actionControl?.toJson();
    }
    return data;
  }
}

class ActionControl {
  String? url;
  String? name;
  String? textColor;
  String? textColorPressed;

  ActionControl({this.url, this.name, this.textColor, this.textColorPressed});

  ActionControl.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    name = json['name'];
    textColor = json['text_color'];
    textColorPressed = json['text_color_pressed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['url'] = this.url;
    data['name'] = this.name;
    data['text_color'] = this.textColor;
    data['text_color_pressed'] = this.textColorPressed;
    return data;
  }
}

class UserExtend {
  String? tips;
  String? userExtendStorey;
  // List<Null> data;

  UserExtend({
    this.tips,
    this.userExtendStorey,
    // this.data
  });

  UserExtend.fromJson(Map<String, dynamic> json) {
    tips = json['tips'];
    userExtendStorey = json['user_extend_storey'];
    // if (json['data'] != null) {
    //   data = new List<Null>();
    //   json['data'].forEach((v) {
    //     data.add(new Null.fromJson(v));
    //   });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tips'] = this.tips;
    data['user_extend_storey'] = this.userExtendStorey;
    // if (this.data != null) {
    //   data['data'] = this.data.map((v) => v.toJson()).toList();
    // }
    return data;
  }
}

class HotUserEntry {
  List<HotUser>? hotUser;
  String? moduleName;

  HotUserEntry({this.hotUser, this.moduleName});

  HotUserEntry.fromJson(Map<String, dynamic> json) {
    if (json['hot_user'] != null) {
      hotUser = [];
      json['hot_user'].forEach((v) {
        hotUser?.add(new HotUser.fromJson(v));
      });
    }
    moduleName = json['module_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.hotUser != null) {
      data['hot_user'] = this.hotUser?.map((v) => v.toJson()).toList();
    }
    data['module_name'] = this.moduleName;
    return data;
  }
}

class HotUser {
  String? userId;
  String? portrait;

  HotUser({this.userId, this.portrait});

  HotUser.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    portrait = json['portrait'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['portrait'] = this.portrait;
    return data;
  }
}

class GconAccount {
  String? hasAccount;
  String? menuName;

  GconAccount({this.hasAccount, this.menuName});

  GconAccount.fromJson(Map<String, dynamic> json) {
    hasAccount = json['has_account'];
    menuName = json['menu_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['has_account'] = this.hasAccount;
    data['menu_name'] = this.menuName;
    return data;
  }
}

class Anti {
  String? tbs;
  String? ifpost;
  String? ifposta;
  String? forbidFlag;
  String? forbidInfo;
  String? hideStat;
  String? vcodeStat;
  String? daysTofree;
  String? hasChance;
  String? ifxiaoying;
  String? pollMessage;
  String? videoMessage;
  String? videoLocalMessage;
  String? pollLevel;
  String? blockStat;
  BlockPopInfo? blockPopInfo;
  List<DelThreadText>? delThreadText;
  String? multiDelthread;
  String? ifvoice;
  String? voiceMessage;
  String? canGoods;

  Anti(
      {this.tbs,
      this.ifpost,
      this.ifposta,
      this.forbidFlag,
      this.forbidInfo,
      this.hideStat,
      this.vcodeStat,
      this.daysTofree,
      this.hasChance,
      this.ifxiaoying,
      this.pollMessage,
      this.videoMessage,
      this.videoLocalMessage,
      this.pollLevel,
      this.blockStat,
      this.blockPopInfo,
      this.delThreadText,
      this.multiDelthread,
      this.ifvoice,
      this.voiceMessage,
      this.canGoods});

  Anti.fromJson(Map<String, dynamic> json) {
    tbs = json['tbs'];
    ifpost = json['ifpost'];
    ifposta = json['ifposta'];
    forbidFlag = json['forbid_flag'];
    forbidInfo = json['forbid_info'];
    hideStat = json['hide_stat'];
    vcodeStat = json['vcode_stat'];
    daysTofree = json['days_tofree'];
    hasChance = json['has_chance'];
    ifxiaoying = json['ifxiaoying'];
    pollMessage = json['poll_message'];
    videoMessage = json['video_message'];
    videoLocalMessage = json['video_local_message'];
    pollLevel = json['poll_level'];
    blockStat = json['block_stat'];
    blockPopInfo = json['block_pop_info'] != null
        ? new BlockPopInfo.fromJson(json['block_pop_info'])
        : null;
    if (json['del_thread_text'] != null) {
      delThreadText = [];
      json['del_thread_text'].forEach((v) {
        delThreadText?.add(new DelThreadText.fromJson(v));
      });
    }
    multiDelthread = json['multi_delthread'];
    ifvoice = json['ifvoice'];
    voiceMessage = json['voice_message'];
    canGoods = json['can_goods'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tbs'] = this.tbs;
    data['ifpost'] = this.ifpost;
    data['ifposta'] = this.ifposta;
    data['forbid_flag'] = this.forbidFlag;
    data['forbid_info'] = this.forbidInfo;
    data['hide_stat'] = this.hideStat;
    data['vcode_stat'] = this.vcodeStat;
    data['days_tofree'] = this.daysTofree;
    data['has_chance'] = this.hasChance;
    data['ifxiaoying'] = this.ifxiaoying;
    data['poll_message'] = this.pollMessage;
    data['video_message'] = this.videoMessage;
    data['video_local_message'] = this.videoLocalMessage;
    data['poll_level'] = this.pollLevel;
    data['block_stat'] = this.blockStat;
    if (this.blockPopInfo != null) {
      data['block_pop_info'] = this.blockPopInfo?.toJson();
    }
    if (this.delThreadText != null) {
      data['del_thread_text'] =
          this.delThreadText?.map((v) => v.toJson()).toList();
    }
    data['multi_delthread'] = this.multiDelthread;
    data['ifvoice'] = this.ifvoice;
    data['voice_message'] = this.voiceMessage;
    data['can_goods'] = this.canGoods;
    return data;
  }
}

class BlockPopInfo {
  String? canPost;
  String? blockInfo;
  String? aheadInfo;
  String? aheadUrl;
  String? okInfo;
  String? aheadType;
  String? appealStatus;
  String? appealMsg;

  BlockPopInfo(
      {this.canPost,
      this.blockInfo,
      this.aheadInfo,
      this.aheadUrl,
      this.okInfo,
      this.aheadType,
      this.appealStatus,
      this.appealMsg});

  BlockPopInfo.fromJson(Map<String, dynamic> json) {
    canPost = json['can_post'];
    blockInfo = json['block_info'];
    aheadInfo = json['ahead_info'];
    aheadUrl = json['ahead_url'];
    okInfo = json['ok_info'];
    aheadType = json['ahead_type'];
    appealStatus = json['appeal_status'];
    appealMsg = json['appeal_msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['can_post'] = this.canPost;
    data['block_info'] = this.blockInfo;
    data['ahead_info'] = this.aheadInfo;
    data['ahead_url'] = this.aheadUrl;
    data['ok_info'] = this.okInfo;
    data['ahead_type'] = this.aheadType;
    data['appeal_status'] = this.appealStatus;
    data['appeal_msg'] = this.appealMsg;
    return data;
  }
}

class DelThreadText {
  String? textId;
  String? textInfo;

  DelThreadText({this.textId, this.textInfo});

  DelThreadText.fromJson(Map<String, dynamic> json) {
    textId = json['text_id'];
    textInfo = json['text_info'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['text_id'] = this.textId;
    data['text_info'] = this.textInfo;
    return data;
  }
}

class ForumUser {
  String? isLogin;
  String? id;
  String? name;
  String? nameShow;
  String? portrait;
  String? noUn;
  String? isManager;
  String? type;
  String? userhide;
  Balv? balv;
  String? isBawu;
  String? bawuType;
  String? bimgUrl;
  String? iosBimgFormat;
  String? isMem;
  String? isSelectTail;
  String? privThread;
  // List<Null> businessAccountInfo;

  ForumUser({
    this.isLogin,
    this.id,
    this.name,
    this.nameShow,
    this.portrait,
    this.noUn,
    this.isManager,
    this.type,
    this.userhide,
    this.balv,
    this.isBawu,
    this.bawuType,
    this.bimgUrl,
    this.iosBimgFormat,
    this.isMem,
    this.isSelectTail,
    this.privThread,
    // this.businessAccountInfo
  });

  ForumUser.fromJson(Map<String, dynamic> json) {
    isLogin = json['is_login'];
    id = json['id'];
    name = json['name'];
    nameShow = json['name_show'];
    portrait = json['portrait'];
    noUn = json['no_un'];
    isManager = json['is_manager'];
    type = json['type'];
    userhide = json['userhide'];
    balv = json['balv'] != null ? new Balv.fromJson(json['balv']) : null;
    isBawu = json['is_bawu'];
    bawuType = json['bawu_type'];
    bimgUrl = json['bimg_url'];
    iosBimgFormat = json['ios_bimg_format'];
    isMem = json['is_mem'];
    isSelectTail = json['is_select_tail'];
    privThread = json['priv_thread'];
    // if (json['business_account_info'] != null) {
    //   businessAccountInfo = new List<Null>();
    //   json['business_account_info'].forEach((v) {
    //     businessAccountInfo.add(new Null.fromJson(v));
    //   });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_login'] = this.isLogin;
    data['id'] = this.id;
    data['name'] = this.name;
    data['name_show'] = this.nameShow;
    data['portrait'] = this.portrait;
    data['no_un'] = this.noUn;
    data['is_manager'] = this.isManager;
    data['type'] = this.type;
    data['userhide'] = this.userhide;
    if (this.balv != null) {
      data['balv'] = this.balv?.toJson();
    }
    data['is_bawu'] = this.isBawu;
    data['bawu_type'] = this.bawuType;
    data['bimg_url'] = this.bimgUrl;
    data['ios_bimg_format'] = this.iosBimgFormat;
    data['is_mem'] = this.isMem;
    data['is_select_tail'] = this.isSelectTail;
    data['priv_thread'] = this.privThread;
    // if (this.businessAccountInfo != null) {
    //   data['business_account_info'] =
    //       this.businessAccountInfo.map((v) => v.toJson()).toList();
    // }
    return data;
  }
}

class Balv {
  String? isBlock;
  String? isBlack;
  String? daysTofree;

  Balv({this.isBlock, this.isBlack, this.daysTofree});

  Balv.fromJson(Map<String, dynamic> json) {
    isBlock = json['is_block'];
    isBlack = json['is_black'];
    daysTofree = json['days_tofree'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_block'] = this.isBlock;
    data['is_black'] = this.isBlack;
    data['days_tofree'] = this.daysTofree;
    return data;
  }
}

// class BusinessPromot {
//   String id;
//   String title;
//   String img;
//   String imgPopup;
//   String type;
//   String threadId;
//   String url;
//   String joinNum;
//   String threadType;

//   BusinessPromot(
//       {this.id,
//       this.title,
//       this.img,
//       this.imgPopup,
//       this.type,
//       this.threadId,
//       this.url,
//       this.joinNum,
//       this.threadType});

//   BusinessPromot.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     title = json['title'];
//     img = json['img'];
//     imgPopup = json['img_popup'];
//     type = json['type'];
//     threadId = json['thread_id'];
//     url = json['url'];
//     joinNum = json['join_num'];
//     threadType = json['thread_type'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['title'] = this.title;
//     data['img'] = this.img;
//     data['img_popup'] = this.imgPopup;
//     data['type'] = this.type;
//     data['thread_id'] = this.threadId;
//     data['url'] = this.url;
//     data['join_num'] = this.joinNum;
//     data['thread_type'] = this.threadType;
//     return data;
//   }
// }

// class ItemInfo {
//   String id;
//   String name;
//   String iconUrl;
//   String iconSize;
//   String brief;
//   List<String> tags;
//   List<ItemOptions> itemOptions;
//   Score score;
//   String isSchool;
//   String forumName;
//   String buttonName;
//   String buttonLink;
//   String itemAppid;
//   String apkName;
//   String buttonLinkType;
//   List<Null> apkDetail;
//   String itemGameInfo;

//   ItemInfo(
//       {this.id,
//       this.name,
//       this.iconUrl,
//       this.iconSize,
//       this.brief,
//       this.tags,
//       this.itemOptions,
//       this.score,
//       this.isSchool,
//       this.forumName,
//       this.buttonName,
//       this.buttonLink,
//       this.itemAppid,
//       this.apkName,
//       this.buttonLinkType,
//       this.apkDetail,
//       this.itemGameInfo});

//   ItemInfo.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     name = json['name'];
//     iconUrl = json['icon_url'];
//     iconSize = json['icon_size'];
//     brief = json['brief'];
//     tags = json['tags'].cast<String>();
//     if (json['item_options'] != null) {
//       itemOptions = new List<ItemOptions>();
//       json['item_options'].forEach((v) {
//         itemOptions.add(new ItemOptions.fromJson(v));
//       });
//     }
//     score = json['score'] != null ? new Score.fromJson(json['score']) : null;
//     isSchool = json['is_school'];
//     forumName = json['forum_name'];
//     buttonName = json['button_name'];
//     buttonLink = json['button_link'];
//     itemAppid = json['item_appid'];
//     apkName = json['apk_name'];
//     buttonLinkType = json['button_link_type'];
//     if (json['apk_detail'] != null) {
//       apkDetail = new List<Null>();
//       json['apk_detail'].forEach((v) {
//         apkDetail.add(new Null.fromJson(v));
//       });
//     }
//     itemGameInfo = json['item_game_info'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['name'] = this.name;
//     data['icon_url'] = this.iconUrl;
//     data['icon_size'] = this.iconSize;
//     data['brief'] = this.brief;
//     data['tags'] = this.tags;
//     if (this.itemOptions != null) {
//       data['item_options'] = this.itemOptions.map((v) => v.toJson()).toList();
//     }
//     if (this.score != null) {
//       data['score'] = this.score.toJson();
//     }
//     data['is_school'] = this.isSchool;
//     data['forum_name'] = this.forumName;
//     data['button_name'] = this.buttonName;
//     data['button_link'] = this.buttonLink;
//     data['item_appid'] = this.itemAppid;
//     data['apk_name'] = this.apkName;
//     data['button_link_type'] = this.buttonLinkType;
//     if (this.apkDetail != null) {
//       data['apk_detail'] = this.apkDetail.map((v) => v.toJson()).toList();
//     }
//     data['item_game_info'] = this.itemGameInfo;
//     return data;
//   }
// }

class ItemOptions {
  String? key;
  Value? value;

  ItemOptions({this.key, this.value});

  ItemOptions.fromJson(Map<String, dynamic> json) {
    key = json['key'];
    value = json['value'] != null ? new Value.fromJson(json['value']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['key'] = this.key;
    if (this.value != null) {
      data['value'] = this.value?.toJson();
    }
    return data;
  }
}

class Value {
  String? publishTime;
  String? category2;
  String? category3;
  String? price;
  // List<Image>? image;
  // List<Null>? video;

  Value({
    this.publishTime,
    this.category2,
    this.category3,
    this.price,
    // this.image,
    // this.video
  });

  Value.fromJson(Map<String, dynamic> json) {
    publishTime = json['publish_time'];
    category2 = json['category2'];
    category3 = json['category3'];
    price = json['price'];
    // if (json['image'] != null) {
    //   image = [];
    //   json['image'].forEach((v) {
    //     image?.add(new Image.fromJson(v));
    //   });
    // }
    // if (json['video'] != null) {
    //   video = new List<Null>();
    //   json['video'].forEach((v) {
    //     video.add(new Null.fromJson(v));
    //   });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['publish_time'] = this.publishTime;
    data['category2'] = this.category2;
    data['category3'] = this.category3;
    data['price'] = this.price;
    // if (this.image != null) {
    //   data['image'] = this.image?.map((v) => v.toJson()).toList();
    // }
    // if (this.video != null) {
    //   data['video'] = this.video.map((v) => v.toJson()).toList();
    // }
    return data;
  }
}

// class Image {
//   String? url;
//   String? thumbUrl;
//   String? pid;

//   Image({this.url, this.thumbUrl, this.pid});

//   Image.fromJson(Map<String, dynamic> json) {
//     url = json['url'];
//     thumbUrl = json['thumb_url'];
//     pid = json['pid'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['url'] = this.url;
//     data['thumb_url'] = this.thumbUrl;
//     data['pid'] = this.pid;
//     return data;
//   }
// }

class Score {
  String? totalPointNum;
  List<ItemPoint>? itemPoint;
  // List<Null> itemPlot;

  Score({
    this.totalPointNum,
    this.itemPoint,
    // this.itemPlot
  });

  Score.fromJson(Map<String, dynamic> json) {
    totalPointNum = json['total_point_num'];
    if (json['item_point'] != null) {
      itemPoint = [];
      json['item_point'].forEach((v) {
        itemPoint?.add(new ItemPoint.fromJson(v));
      });
    }
    // if (json['item_plot'] != null) {
    //   itemPlot = new List<Null>();
    //   json['item_plot'].forEach((v) {
    //     itemPlot.add(new Null.fromJson(v));
    //   });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total_point_num'] = this.totalPointNum;
    if (this.itemPoint != null) {
      data['item_point'] = this.itemPoint?.map((v) => v.toJson()).toList();
    }
    // if (this.itemPlot != null) {
    //   data['item_plot'] = this.itemPlot.map((v) => v.toJson()).toList();
    // }
    return data;
  }
}

class ItemPoint {
  String? timeIntval;
  String? point;

  ItemPoint({this.timeIntval, this.point});

  ItemPoint.fromJson(Map<String, dynamic> json) {
    timeIntval = json['time_intval'];
    point = json['point'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['time_intval'] = this.timeIntval;
    data['point'] = this.point;
    return data;
  }
}

class ForumPage {
  String? pageSize;
  String? offset;
  String? currentPage;
  String? totalCount;
  String? totalPage;
  String? hasMore;
  String? hasPrev;
  String? curGoodId;

  ForumPage(
      {this.pageSize,
      this.offset,
      this.currentPage,
      this.totalCount,
      this.totalPage,
      this.hasMore,
      this.hasPrev,
      this.curGoodId});

  ForumPage.fromJson(Map<String, dynamic> json) {
    pageSize = json['page_size'];
    offset = json['offset'];
    currentPage = json['current_page'];
    totalCount = json['total_count'];
    totalPage = json['total_page'];
    hasMore = json['has_more'];
    hasPrev = json['has_prev'];
    curGoodId = json['cur_good_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['page_size'] = this.pageSize;
    data['offset'] = this.offset;
    data['current_page'] = this.currentPage;
    data['total_count'] = this.totalCount;
    data['total_page'] = this.totalPage;
    data['has_more'] = this.hasMore;
    data['has_prev'] = this.hasPrev;
    data['cur_good_id'] = this.curGoodId;
    return data;
  }
}

class PrivateForumActiveInfo {
  String? forumBrief;
  String? forumShareUrl;

  PrivateForumActiveInfo({this.forumBrief, this.forumShareUrl});

  PrivateForumActiveInfo.fromJson(Map<String, dynamic> json) {
    forumBrief = json['forum_brief'];
    forumShareUrl = json['forum_share_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['forum_brief'] = this.forumBrief;
    data['forum_share_url'] = this.forumShareUrl;
    return data;
  }
}

class FrsStar {
  String? hasFrsStar;
  String? starForumHeadimg;
  String? top;
  String? topSize;
  String? head;
  String? headSize;
  String? gender;
  String? fans;
  // List<Null> trade;

  FrsStar({
    this.hasFrsStar,
    this.starForumHeadimg,
    this.top,
    this.topSize,
    this.head,
    this.headSize,
    this.gender,
    this.fans,
    // this.trade
  });

  FrsStar.fromJson(Map<String, dynamic> json) {
    hasFrsStar = json['has_frs_star'];
    starForumHeadimg = json['star_forum_headimg'];
    top = json['top'];
    topSize = json['top_size'];
    head = json['head'];
    headSize = json['head_size'];
    gender = json['gender'];
    fans = json['fans'];
    // if (json['trade'] != null) {
    //   trade = new List<Null>();
    //   json['trade'].forEach((v) {
    //     trade.add(new Null.fromJson(v));
    //   });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['has_frs_star'] = this.hasFrsStar;
    data['star_forum_headimg'] = this.starForumHeadimg;
    data['top'] = this.top;
    data['top_size'] = this.topSize;
    data['head'] = this.head;
    data['head_size'] = this.headSize;
    data['gender'] = this.gender;
    data['fans'] = this.fans;
    // if (this.trade != null) {
    //   data['trade'] = this.trade.map((v) => v.toJson()).toList();
    // }
    return data;
  }
}

// class AgreeBanner {
//   String text;
//   String iconUrl;
//   String url;
//   List<TopAgreeUser> topAgreeUser;

//   AgreeBanner({this.text, this.iconUrl, this.url, this.topAgreeUser});

//   AgreeBanner.fromJson(Map<String, dynamic> json) {
//     text = json['text'];
//     iconUrl = json['icon_url'];
//     url = json['url'];
//     if (json['top_agree_user'] != null) {
//       topAgreeUser = new List<TopAgreeUser>();
//       json['top_agree_user'].forEach((v) {
//         topAgreeUser.add(new TopAgreeUser.fromJson(v));
//       });
//     }
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['text'] = this.text;
//     data['icon_url'] = this.iconUrl;
//     data['url'] = this.url;
//     if (this.topAgreeUser != null) {
//       data['top_agree_user'] =
//           this.topAgreeUser.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }

class TopAgreeUser {
  String? userId;
  String? agreeNum;
  String? rank;
  String? userName;
  String? nameShow;
  String? gender;
  String? portrait;

  TopAgreeUser(
      {this.userId,
      this.agreeNum,
      this.rank,
      this.userName,
      this.nameShow,
      this.gender,
      this.portrait});

  TopAgreeUser.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    agreeNum = json['agree_num'];
    rank = json['rank'];
    userName = json['user_name'];
    nameShow = json['name_show'];
    gender = json['gender'];
    portrait = json['portrait'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['agree_num'] = this.agreeNum;
    data['rank'] = this.rank;
    data['user_name'] = this.userName;
    data['name_show'] = this.nameShow;
    data['gender'] = this.gender;
    data['portrait'] = this.portrait;
    return data;
  }
}

class FrsTabInfo {
  String? tabName;
  String? tabUrl;
  String? tabType;
  String? tabId;

  FrsTabInfo({this.tabName, this.tabUrl, this.tabType, this.tabId});

  FrsTabInfo.fromJson(Map<String, dynamic> json) {
    tabName = json['tab_name'];
    tabUrl = json['tab_url'];
    tabType = json['tab_type'];
    tabId = json['tab_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tab_name'] = this.tabName;
    data['tab_url'] = this.tabUrl;
    data['tab_type'] = this.tabType;
    data['tab_id'] = this.tabId;
    return data;
  }
}

class UserList extends Author {
  String? id;
  String? portrait;
  String? name;
  String? nameShow;
  String? sex;
  String? gender;
  String? type;
  List<Iconinfo>? iconinfo;
  // List<ForumIconinfo>? iconinfo;
  // List<TshowIcon> tshowIcon;
  // List<NewTshowIcon> newTshowIcon;
  String? isMem;
  String? fansNum;
  String? fansNickname;
  String? godData;
  ForumPrivSets? privSets;
  // ThemeCard? themeCard;
  // List<Null> tbVip;
  String? isBawu;
  String? bawuType;
  String? baijiahaoInfo;
  // Pendant? pendant;
  // AlaInfo? alaInfo;
  String? sealPrefix;
  String? isVideobiggie;
  // String? bazhuGrade;
  String? displayAuthType;
  // String? workCreatorInfo;
  String? isDefaultAvatar;
  // NewGodData? newGodData;
  // List<Null> businessAccountInfo;

  UserList({
    this.id,
    this.portrait,
    this.name,
    this.nameShow,
    this.sex,
    this.gender,
    this.type,
    this.iconinfo,
    // this.tshowIcon,
    // this.newTshowIcon,
    this.isMem,
    this.fansNum,
    this.fansNickname,
    this.godData,
    this.privSets,
    // this.themeCard,
    // this.tbVip,
    this.isBawu,
    this.bawuType,
    this.baijiahaoInfo,
    // this.pendant,
    // this.alaInfo,
    this.sealPrefix,
    this.isVideobiggie,
    // this.bazhuGrade,
    this.displayAuthType,
    // this.workCreatorInfo,
    this.isDefaultAvatar,
    // this.newGodData,
    // this.businessAccountInfo
  });

  UserList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    portrait = json['portrait'];
    name = json['name'];
    nameShow = json['name_show'];
    sex = json['sex'];
    gender = json['gender'];
    type = json['type'];
    if (json['iconinfo'] != null) {
      iconinfo = [];
      json['iconinfo'].forEach((v) {
        // iconinfo?.add(new ForumIconinfo.fromJson(v));
        iconinfo?.add(new Iconinfo.fromJson(v));
      });
    }
    // if (json['tshow_icon'] != null) {
    //   tshowIcon = new List<TshowIcon>();
    //   json['tshow_icon'].forEach((v) {
    //     tshowIcon.add(new TshowIcon.fromJson(v));
    //   });
    // }
    // if (json['new_tshow_icon'] != null) {
    //   newTshowIcon = new List<NewTshowIcon>();
    //   json['new_tshow_icon'].forEach((v) {
    //     newTshowIcon.add(new NewTshowIcon.fromJson(v));
    //   });
    // }
    isMem = json['is_mem'];
    fansNum = json['fans_num'];
    fansNickname = json['fans_nickname'];
    godData = json['god_data'];
    privSets = json['priv_sets'] != ""
        ? new ForumPrivSets.fromJson(json['priv_sets'])
        : null;
    // themeCard = json['theme_card'] != null
    //     ? new ThemeCard.fromJson(json['theme_card'])
    //     : null;
    // if (json['tb_vip'] != null) {
    //   tbVip = new List<Null>();
    //   json['tb_vip'].forEach((v) {
    //     tbVip.add(new Null.fromJson(v));
    //   });
    // }
    isBawu = json['is_bawu'];
    bawuType = json['bawu_type'];
    baijiahaoInfo = json['baijiahao_info'];
    // pendant =
    //     json['pendant'] != null ? new Pendant.fromJson(json['pendant']) : null;
    // alaInfo = json['ala_info'] != null
    //     ? new AlaInfo.fromJson(json['ala_info'])
    //     : null;
    sealPrefix = json['seal_prefix'];
    isVideobiggie = json['is_videobiggie'];
    // bazhuGrade = json['bazhu_grade'];
    displayAuthType = json['display_auth_type'];
    // workCreatorInfo = json['work_creator_info'];
    isDefaultAvatar = json['is_default_avatar'];
    // newGodData = json['new_god_data'] != null
    //     ? new NewGodData.fromJson(json['new_god_data'])
    //     : null;
    // if (json['business_account_info'] != null) {
    //   businessAccountInfo = new List<Null>();
    //   json['business_account_info'].forEach((v) {
    //     businessAccountInfo.add(new Null.fromJson(v));
    //   });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['portrait'] = this.portrait;
    data['name'] = this.name;
    data['name_show'] = this.nameShow;
    data['sex'] = this.sex;
    data['gender'] = this.gender;
    data['type'] = this.type;
    if (this.iconinfo != null) {
      data['iconinfo'] = this.iconinfo?.map((v) => v.toJson()).toList();
    }
    // if (this.tshowIcon != null) {
    //   data['tshow_icon'] = this.tshowIcon.map((v) => v.toJson()).toList();
    // }
    // if (this.newTshowIcon != null) {
    //   data['new_tshow_icon'] =
    //       this.newTshowIcon.map((v) => v.toJson()).toList();
    // }
    data['is_mem'] = this.isMem;
    data['fans_num'] = this.fansNum;
    data['fans_nickname'] = this.fansNickname;
    data['god_data'] = this.godData;
    if (this.privSets != null) {
      data['priv_sets'] = this.privSets?.toJson();
    }
    // if (this.themeCard != null) {
    //   data['theme_card'] = this.themeCard?.toJson();
    // }
    // if (this.tbVip != null) {
    //   data['tb_vip'] = this.tbVip.map((v) => v.toJson()).toList();
    // }
    data['is_bawu'] = this.isBawu;
    data['bawu_type'] = this.bawuType;
    data['baijiahao_info'] = this.baijiahaoInfo;
    // if (this.pendant != null) {
    //   data['pendant'] = this.pendant?.toJson();
    // }
    // if (this.alaInfo != null) {
    //   data['ala_info'] = this.alaInfo?.toJson();
    // }
    data['seal_prefix'] = this.sealPrefix;
    data['is_videobiggie'] = this.isVideobiggie;
    // data['bazhu_grade'] = this.bazhuGrade;
    data['display_auth_type'] = this.displayAuthType;
    // data['work_creator_info'] = this.workCreatorInfo;
    data['is_default_avatar'] = this.isDefaultAvatar;
    // if (this.newGodData != null) {
    //   data['new_god_data'] = this.newGodData?.toJson();
    // }
    // if (this.businessAccountInfo != null) {
    //   data['business_account_info'] =
    //       this.businessAccountInfo.map((v) => v.toJson()).toList();
    // }
    return data;
  }
}

// class ForumIconinfo {
//   String? name;
//   String? value;
//   String? weight;
//   Terminal? terminal;
//   // Position? position;
//   // Sprite? sprite;
//   String? icon;

//   ForumIconinfo(
//       {this.name,
//       this.value,
//       this.weight,
//       this.terminal,
//       // this.position,
//       // this.sprite,
//       this.icon});

//   ForumIconinfo.fromJson(Map<String, dynamic> json) {
//     name = json['name'];
//     value = json['value'];
//     weight = json['weight'];
//     terminal = json['terminal'] != null
//         ? new Terminal.fromJson(json['terminal'])
//         : null;
//     // position = json['position'] != null
//     //     ? new Position.fromJson(json['position'])
//     //     : null;
//     // sprite =
//     //     json['sprite'] != null ? new Sprite.fromJson(json['sprite']) : null;
//     icon = json['icon'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['name'] = this.name;
//     data['value'] = this.value;
//     data['weight'] = this.weight;
//     if (this.terminal != null) {
//       data['terminal'] = this.terminal?.toJson();
//     }
//     // if (this.position != null) {
//     //   data['position'] = this.position.toJson();
//     // }
//     // if (this.sprite != null) {
//     //   data['sprite'] = this.sprite.toJson();
//     // }
//     data['icon'] = this.icon;
//     return data;
//   }
// }

class Terminal {
  String? client;
  String? pc;
  String? wap;

  Terminal({this.client, this.pc, this.wap});

  Terminal.fromJson(Map<String, dynamic> json) {
    client = json['client'];
    pc = json['pc'];
    wap = json['wap'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['client'] = this.client;
    data['pc'] = this.pc;
    data['wap'] = this.wap;
    return data;
  }
}

// class Position {
//   String? card;
//   String? frs;
//   String? home;
//   String? pb;

//   Position({this.card, this.frs, this.home, this.pb});

//   Position.fromJson(Map<String, dynamic> json) {
//     card = json['card'];
//     frs = json['frs'];
//     home = json['home'];
//     pb = json['pb'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['card'] = this.card;
//     data['frs'] = this.frs;
//     data['home'] = this.home;
//     data['pb'] = this.pb;
//     return data;
//   }
// }

// class Sprite {
//   String s1;
//   String s2;
//   String s3;
//   String s4;
//   String s5;
//   String s6;

//   Sprite({this.s1, this.s2, this.s3, this.s4, this.s5, this.s6});

//   Sprite.fromJson(Map<String, dynamic> json) {
//     s1 = json['1'];
//     s2 = json['2'];
//     s3 = json['3'];
//     s4 = json['4'];
//     s5 = json['5'];
//     s6 = json['6'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['1'] = this.s1;
//     data['2'] = this.s2;
//     data['3'] = this.s3;
//     data['4'] = this.s4;
//     data['5'] = this.s5;
//     data['6'] = this.s6;
//     return data;
//   }
// }

class ForumPrivSets {
  String? group;
  String? like;
  String? live;
  String? location;
  String? post;
  String? reply;

  ForumPrivSets(
      {this.group, this.like, this.live, this.location, this.post, this.reply});

  ForumPrivSets.fromJson(Map<String, dynamic> json) {
    group = json['group'];
    like = json['like'];
    live = json['live'];
    location = json['location'];
    post = json['post'];
    reply = json['reply'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['group'] = this.group;
    data['like'] = this.like;
    data['live'] = this.live;
    data['location'] = this.location;
    data['post'] = this.post;
    data['reply'] = this.reply;
    return data;
  }
}

// class ThemeCard {
//   String imgAndroid;
//   String imgIos;
//   String level;
//   String propsId;
//   String endTime;

//   ThemeCard(
//       {this.imgAndroid, this.imgIos, this.level, this.propsId, this.endTime});

//   ThemeCard.fromJson(Map<String, dynamic> json) {
//     imgAndroid = json['img_android'];
//     imgIos = json['img_ios'];
//     level = json['level'];
//     propsId = json['props_id'];
//     endTime = json['end_time'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['img_android'] = this.imgAndroid;
//     data['img_ios'] = this.imgIos;
//     data['level'] = this.level;
//     data['props_id'] = this.propsId;
//     data['end_time'] = this.endTime;
//     return data;
//   }
// }

// class Pendant {
//   String propsId;
//   String imgUrl;

//   Pendant({this.propsId, this.imgUrl});

//   Pendant.fromJson(Map<String, dynamic> json) {
//     propsId = json['props_id'];
//     imgUrl = json['img_url'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['props_id'] = this.propsId;
//     data['img_url'] = this.imgUrl;
//     return data;
//   }
// }

// class AlaInfo {
//   String anchorLevelPresent;
//   String anchorLevelPrevious;
//   String location;
//   String showName;
//   String anchorLive;

//   AlaInfo(
//       {this.anchorLevelPresent,
//       this.anchorLevelPrevious,
//       this.location,
//       this.showName,
//       this.anchorLive});

//   AlaInfo.fromJson(Map<String, dynamic> json) {
//     anchorLevelPresent = json['anchor_level_present'];
//     anchorLevelPrevious = json['anchor_level_previous'];
//     location = json['location'];
//     showName = json['show_name'];
//     anchorLive = json['anchor_live'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['anchor_level_present'] = this.anchorLevelPresent;
//     data['anchor_level_previous'] = this.anchorLevelPrevious;
//     data['location'] = this.location;
//     data['show_name'] = this.showName;
//     data['anchor_live'] = this.anchorLive;
//     return data;
//   }
// }

// class NewGodData {
//   String applySource;
//   String field;
//   String fieldName;
//   List<String> level1Dir;
//   String status;
//   String updateTime;
//   String fieldId;

//   NewGodData(
//       {this.applySource,
//       this.field,
//       this.fieldName,
//       this.level1Dir,
//       this.status,
//       this.updateTime,
//       this.fieldId});

//   NewGodData.fromJson(Map<String, dynamic> json) {
//     applySource = json['apply_source'];
//     field = json['field'];
//     fieldName = json['field_name'];
//     level1Dir = json['level_1_dir'].cast<String>();
//     status = json['status'];
//     updateTime = json['update_time'];
//     fieldId = json['field_id'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['apply_source'] = this.applySource;
//     data['field'] = this.field;
//     data['field_name'] = this.fieldName;
//     data['level_1_dir'] = this.level1Dir;
//     data['status'] = this.status;
//     data['update_time'] = this.updateTime;
//     data['field_id'] = this.fieldId;
//     return data;
//   }
// }
