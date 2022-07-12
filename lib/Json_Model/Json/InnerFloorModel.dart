part of json_model;

///楼中楼数据Model
class InnerFloorModel implements ThreadPageData {
  List<SubpostList>? subpostList;
  @override
  List<PostList>? postList;
  InnerFloorPost? post;
  @override
  Anti? anti;
  // Page? page;
  @override
  Thread? thread;
  @override
  Forum? forum;
  // List<UserList>? user;
  PermModel? perm;
  @override
  DisplayForum? displayForum;
  @override
  String? isBlackWhite;
  @override
  String? serverTime;
  @override
  int? time;
  @override
  int? ctime;
  @override
  int? logid;
  @override
  String? errorCode;

  InnerFloorModel(
      {this.subpostList,
      this.postList,
      this.post,
      this.anti,
      // this.page,
      this.thread,
      this.forum,
      // this.user,
      this.perm,
      this.displayForum,
      this.isBlackWhite,
      this.serverTime,
      this.time,
      this.ctime,
      this.logid,
      this.errorCode});

  InnerFloorModel.fromJson(Map<String, dynamic> json) {
    if (json['subpost_list'] != null) {
      subpostList = [];
      json['subpost_list'].forEach((v) {
        subpostList?.add(SubpostList.fromJson(v));
      });
    }
    if (json['post_list'] != null) {
      postList = [];
      json['post_list'].forEach((v) {
        postList?.add(PostList.fromJson(v));
      });
    }
    post = json['post'] != null ? InnerFloorPost.fromJson(json['post']) : null;
    anti = json['anti'] != null ? Anti.fromJson(json['anti']) : null;
    page = json['page'] != null ? ThreadPage.fromJson(json['page']) : null;
    thread = json['thread'] != null ? Thread.fromJson(json['thread']) : null;
    forum = json['forum'] != null ? Forum.fromJson(json['forum']) : null;
    if (json['user'] != null) {
      if (json['user'] is List && json['user'].length != 0) {
        user = ThreadUser.fromJson(json['user']);
      }
    }
    perm = json['perm'] != null ? PermModel.fromJson(json['perm']) : null;
    displayForum = json['display_forum'] != null
        ? DisplayForum.fromJson(json['display_forum'])
        : null;
    isBlackWhite = json['is_black_white'];
    serverTime = json['server_time'];
    time = (json['time'] as num).toInt();
    ctime = json['ctime'];
    logid = (json['logid'] as num).toInt();
    errorCode = json['error_code'];
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (subpostList != null) {
      data['subpost_list'] = subpostList?.map((v) => v.toJson()).toList();
    }
    if (postList != null) {
      data['post_list'] = postList?.map((v) => v.toJson()).toList();
    }
    if (post != null) {
      data['post'] = post?.toJson();
    }
    if (anti != null) {
      data['anti'] = anti?.toJson();
    }
    if (page != null) {
      data['page'] = page?.toJson();
    }
    if (thread != null) {
      data['thread'] = thread?.toJson();
    }
    if (forum != null) {
      data['forum'] = forum?.toJson();
    }
    if (user != null) {
      data['user'] = user?.toJson();
    }
    if (perm != null) {
      data['perm'] = perm?.toJson();
    }
    if (displayForum != null) {
      data['display_forum'] = displayForum?.toJson();
    }
    data['is_black_white'] = isBlackWhite;
    data['server_time'] = serverTime;
    data['time'] = time;
    data['ctime'] = ctime;
    data['logid'] = logid;
    data['error_code'] = errorCode;
    return data;
  }

  @override
  List<AlaInfo>? alaInfo;

  @override
  BannerList? bannerList;

  @override
  String? foldTip;

  @override
  String? hasFloor;

  @override
  String? hasFoldComment;

  @override
  String? isNewUrl;

  @override
  String? isOfficialForum;

  @override
  String? isPurchase;

  @override
  List? newsInfo;

  @override
  ThreadPage? page;

  @override
  String? partialVisibleToast;

  @override
  List<PbSortInfo>? pbSortInfo;

  @override
  List? sampleSidsTemp;

  @override
  String? showAdsense;

  @override
  String? sortType;

  @override
  String? switchReadOpen;

  @override
  ThreadUser? user;

  @override
  List<UserList>? userList;
}

class SubpostList implements SubPostList {
  @override
  String? id;
  @override
  List<Content>? content;
  @override
  String? time;
  @override
  String? ptype;
  String? isGiftpost;
  Agree? agree;
  // List<Null> location;
  UserList? author;
  String? isAuthorView;
  @override
  String? title;
  @override
  String? floor;

  SubpostList(
      {this.id,
      this.content,
      this.time,
      this.ptype,
      this.isGiftpost,
      this.agree,
      // this.location,
      this.author,
      this.isAuthorView,
      this.title,
      this.floor});

  SubpostList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    if (json['content'] != null) {
      content = [];
      json['content'].forEach((v) {
        content?.add(Content.fromJson(v));
      });
    }
    time = json['time'];
    ptype = json['ptype'];
    isGiftpost = json['is_giftpost'];
    agree = json['agree'] != null ? Agree.fromJson(json['agree']) : null;
    // if (json['location'] != null) {
    //   location = new List<Null>();
    //   json['location'].forEach((v) {
    //     location.add(new Null.fromJson(v));
    //   });
    // }
    author = json['author'] != null ? UserList.fromJson(json['author']) : null;
    isAuthorView = json['is_author_view'];
    title = json['title'];
    floor = json['floor'];
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (content != null) {
      data['content'] = content?.map((v) => v.toJson()).toList();
    }
    data['time'] = time;
    data['ptype'] = ptype;
    data['is_giftpost'] = isGiftpost;
    if (agree != null) {
      data['agree'] = agree?.toJson();
    }
    // if (this.location != null) {
    //   data['location'] = this.location.map((v) => v.toJson()).toList();
    // }
    if (author != null) {
      data['author'] = author?.toJson();
    }
    data['is_author_view'] = isAuthorView;
    data['title'] = title;
    data['floor'] = floor;
    return data;
  }

  @override
  String? authorId;

  @override
  String? isVoice;
}

class InnerFloorPost implements SubpostList {
  @override
  String? id;
  @override
  String? title;
  @override
  String? floor;
  @override
  String? time;
  @override
  List<Content>? content;
  // List<Null> lbsInfo;
  String? isVote;
  @override
  String? ptype;
  // List<Null> voiceInfo;
  @override
  Agree? agree;
  String? showSquared;
  String? baijiahaoInfo;
  String? isPostVisible;
  @override
  String? isVoice;
  // List<Null> arrVideo;
  String? isBubbleThread;
  String? isColorfullThread;
  @override
  UserList? author;
  String? bimgUrl;
  String? iosBimgFormat;
  String? tpointPost;
  String? skinInfo;

  InnerFloorPost(
      {this.id,
      this.title,
      this.floor,
      this.time,
      this.content,
      // this.lbsInfo,
      this.isVote,
      this.ptype,
      // this.voiceInfo,
      this.agree,
      this.showSquared,
      this.baijiahaoInfo,
      this.isPostVisible,
      this.isVoice,
      // this.arrVideo,
      this.isBubbleThread,
      this.isColorfullThread,
      this.author,
      this.bimgUrl,
      this.iosBimgFormat,
      this.tpointPost,
      this.skinInfo});

  InnerFloorPost.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    floor = json['floor'];
    time = json['time'];
    if (json['content'] != null) {
      content = [];
      json['content'].forEach((v) {
        content?.add(Content.fromJson(v));
      });
    }
    // if (json['lbs_info'] != null) {
    //   lbsInfo = new List<Null>();
    //   json['lbs_info'].forEach((v) {
    //     lbsInfo.add(new Null.fromJson(v));
    //   });
    // }
    // isVote = json['is_vote'];
    // ptype = json['ptype'];
    // if (json['voice_info'] != null) {
    //   voiceInfo = new List<Null>();
    //   json['voice_info'].forEach((v) {
    //     voiceInfo.add(new Null.fromJson(v));
    //   });
    // }
    agree = json['agree'] != null ? Agree.fromJson(json['agree']) : null;
    showSquared = json['show_squared'];
    baijiahaoInfo = json['baijiahao_info'];
    isPostVisible = json['is_post_visible'];
    isVoice = json['is_voice'];
    // if (json['arr_video'] != null) {
    //   arrVideo = new List<Null>();
    //   json['arr_video'].forEach((v) {
    //     arrVideo.add(new Null.fromJson(v));
    //   });
    // }
    isBubbleThread = json['is_bubble_thread'];
    isColorfullThread = json['is_colorfull_thread'];
    author = json['author'] != null ? UserList.fromJson(json['author']) : null;
    bimgUrl = json['bimg_url'];
    iosBimgFormat = json['ios_bimg_format'];
    tpointPost = json['tpoint_post'];
    skinInfo = json['skin_info'];
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['floor'] = floor;
    data['time'] = time;
    if (content != null) {
      data['content'] = content?.map((v) => v.toJson()).toList();
    }
    // if (this.lbsInfo != null) {
    //   data['lbs_info'] = this.lbsInfo.map((v) => v.toJson()).toList();
    // }
    // data['is_vote'] = this.isVote;
    // data['ptype'] = this.ptype;
    // if (this.voiceInfo != null) {
    //   data['voice_info'] = this.voiceInfo.map((v) => v.toJson()).toList();
    // }
    if (agree != null) {
      data['agree'] = agree?.toJson();
    }
    data['show_squared'] = showSquared;
    data['baijiahao_info'] = baijiahaoInfo;
    data['is_post_visible'] = isPostVisible;
    data['is_voice'] = isVoice;
    // if (this.arrVideo != null) {
    //   data['arr_video'] = this.arrVideo.map((v) => v.toJson()).toList();
    // }
    data['is_bubble_thread'] = isBubbleThread;
    data['is_colorfull_thread'] = isColorfullThread;
    if (author != null) {
      data['author'] = author?.toJson();
    }
    data['bimg_url'] = bimgUrl;
    data['ios_bimg_format'] = iosBimgFormat;
    data['tpoint_post'] = tpointPost;
    data['skin_info'] = skinInfo;
    return data;
  }

  @override
  String? authorId;

  @override
  String? isAuthorView;

  @override
  String? isGiftpost;
}

class PermModel {
  Perm? perm;
  String? uegType;
  String? blockType;
  // List<Null> tip;
  Grade? grade;

  PermModel({this.perm, this.uegType, this.blockType, this.grade});

  PermModel.fromJson(Map<String, dynamic> json) {
    perm = json['perm'] != null ? Perm.fromJson(json['perm']) : null;
    uegType = json['ueg_type'];
    blockType = json['block_type'];
    // if (json['tip'] != null) {
    //   tip = new List<Null>();
    //   json['tip'].forEach((v) {
    //     tip.add(new Null.fromJson(v));
    //   });
    // }
    grade = json['grade'] != null ? Grade.fromJson(json['grade']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (perm != null) {
      data['perm'] = perm?.toJson();
    }
    data['ueg_type'] = uegType;
    data['block_type'] = blockType;
    // if (this.tip != null) {
    //   data['tip'] = this.tip.map((v) => v.toJson()).toList();
    // }
    if (grade != null) {
      data['grade'] = grade?.toJson();
    }
    return data;
  }
}

class Perm {
  String? canAddCelebrity;
  String? canAddManagerTeam;
  String? canBwsFDS;
  String? canBwsBawuCenter;
  String? canBwsBawuInfo;
  String? canBwsBawuLog;
  String? canBwsFilterIpTbs;
  String? canBwsLimitBawuLog;
  String? canCancelFilterId;
  String? canCancelMaskDelete;
  String? canCancelMaskGood;
  String? canCancelMaskTop;
  String? canDelManagerTeam;
  String? canEditBakan;
  String? canEditDaquan;
  String? canEditGconforum;
  String? canFilterId;
  String? canFilterIp;
  String? canMaskDelete;
  String? canMaskGood;
  String? canMaskTop;
  String? canMemberTop;
  String? canOpFDS;
  String? canOpAs4thmgr;
  String? canOpAsBroadcastAdmin;
  String? canOpAsCategoryEditor;
  String? canOpAsEditor;
  String? canOpAsEntertainmentManager;
  String? canOpAsOperator;
  String? canOpAsProfessionManager;
  String? canOpAsVerticalOperator;
  String? canOpCommonBawu;
  String? canOpDisk;
  String? canOpFrsbg;
  String? canOpGoodClass;
  String? canOpPic;
  String? canOpTopic;
  String? canOpVideo;
  String? canOpWiseGroup;
  String? canPaperIgnoreVcode;
  String? canPassMediaLimit;
  String? canPost;
  String? canPostFrs;
  String? canPostPb;
  String? canSendMemo;
  String? canSuper;
  String? canTobeAssist;
  String? canTobeEditor;
  String? canTobeManager;
  String? canTobePriContentAssist;
  String? canTobePriManageAssist;
  String? canTomsOperatorAltBasic;
  String? canTomsOperatorBasic;
  String? canType1AuditPost;
  String? canType2AuditPost;
  String? canType3AuditPost;
  String? canType4AuditPost;
  String? canType5AuditPost;
  String? canUnknown;
  String? canViewFreq;
  String? canVipJubao;
  String? canVote;

  Perm(
      {this.canAddCelebrity,
      this.canAddManagerTeam,
      this.canBwsFDS,
      this.canBwsBawuCenter,
      this.canBwsBawuInfo,
      this.canBwsBawuLog,
      this.canBwsFilterIpTbs,
      this.canBwsLimitBawuLog,
      this.canCancelFilterId,
      this.canCancelMaskDelete,
      this.canCancelMaskGood,
      this.canCancelMaskTop,
      this.canDelManagerTeam,
      this.canEditBakan,
      this.canEditDaquan,
      this.canEditGconforum,
      this.canFilterId,
      this.canFilterIp,
      this.canMaskDelete,
      this.canMaskGood,
      this.canMaskTop,
      this.canMemberTop,
      this.canOpFDS,
      this.canOpAs4thmgr,
      this.canOpAsBroadcastAdmin,
      this.canOpAsCategoryEditor,
      this.canOpAsEditor,
      this.canOpAsEntertainmentManager,
      this.canOpAsOperator,
      this.canOpAsProfessionManager,
      this.canOpAsVerticalOperator,
      this.canOpCommonBawu,
      this.canOpDisk,
      this.canOpFrsbg,
      this.canOpGoodClass,
      this.canOpPic,
      this.canOpTopic,
      this.canOpVideo,
      this.canOpWiseGroup,
      this.canPaperIgnoreVcode,
      this.canPassMediaLimit,
      this.canPost,
      this.canPostFrs,
      this.canPostPb,
      this.canSendMemo,
      this.canSuper,
      this.canTobeAssist,
      this.canTobeEditor,
      this.canTobeManager,
      this.canTobePriContentAssist,
      this.canTobePriManageAssist,
      this.canTomsOperatorAltBasic,
      this.canTomsOperatorBasic,
      this.canType1AuditPost,
      this.canType2AuditPost,
      this.canType3AuditPost,
      this.canType4AuditPost,
      this.canType5AuditPost,
      this.canUnknown,
      this.canViewFreq,
      this.canVipJubao,
      this.canVote});

  Perm.fromJson(Map<String, dynamic> json) {
    canAddCelebrity = json['can_add_celebrity'];
    canAddManagerTeam = json['can_add_manager_team'];
    canBwsFDS = json['can_bws_FDS'];
    canBwsBawuCenter = json['can_bws_bawu_center'];
    canBwsBawuInfo = json['can_bws_bawu_info'];
    canBwsBawuLog = json['can_bws_bawu_log'];
    canBwsFilterIpTbs = json['can_bws_filter_ip_tbs'];
    canBwsLimitBawuLog = json['can_bws_limit_bawu_log'];
    canCancelFilterId = json['can_cancel_filter_id'];
    canCancelMaskDelete = json['can_cancel_mask_delete'];
    canCancelMaskGood = json['can_cancel_mask_good'];
    canCancelMaskTop = json['can_cancel_mask_top'];
    canDelManagerTeam = json['can_del_manager_team'];
    canEditBakan = json['can_edit_bakan'];
    canEditDaquan = json['can_edit_daquan'];
    canEditGconforum = json['can_edit_gconforum'];
    canFilterId = json['can_filter_id'];
    canFilterIp = json['can_filter_ip'];
    canMaskDelete = json['can_mask_delete'];
    canMaskGood = json['can_mask_good'];
    canMaskTop = json['can_mask_top'];
    canMemberTop = json['can_member_top'];
    canOpFDS = json['can_op_FDS'];
    canOpAs4thmgr = json['can_op_as_4thmgr'];
    canOpAsBroadcastAdmin = json['can_op_as_broadcast_admin'];
    canOpAsCategoryEditor = json['can_op_as_category_editor'];
    canOpAsEditor = json['can_op_as_editor'];
    canOpAsEntertainmentManager = json['can_op_as_entertainment_manager'];
    canOpAsOperator = json['can_op_as_operator'];
    canOpAsProfessionManager = json['can_op_as_profession_manager'];
    canOpAsVerticalOperator = json['can_op_as_vertical_operator'];
    canOpCommonBawu = json['can_op_common_bawu'];
    canOpDisk = json['can_op_disk'];
    canOpFrsbg = json['can_op_frsbg'];
    canOpGoodClass = json['can_op_good_class'];
    canOpPic = json['can_op_pic'];
    canOpTopic = json['can_op_topic'];
    canOpVideo = json['can_op_video'];
    canOpWiseGroup = json['can_op_wise_group'];
    canPaperIgnoreVcode = json['can_paper_ignore_vcode'];
    canPassMediaLimit = json['can_pass_media_limit'];
    canPost = json['can_post'];
    canPostFrs = json['can_post_frs'];
    canPostPb = json['can_post_pb'];
    canSendMemo = json['can_send_memo'];
    canSuper = json['can_super'];
    canTobeAssist = json['can_tobe_assist'];
    canTobeEditor = json['can_tobe_editor'];
    canTobeManager = json['can_tobe_manager'];
    canTobePriContentAssist = json['can_tobe_pri_content_assist'];
    canTobePriManageAssist = json['can_tobe_pri_manage_assist'];
    canTomsOperatorAltBasic = json['can_toms_operator_alt_basic'];
    canTomsOperatorBasic = json['can_toms_operator_basic'];
    canType1AuditPost = json['can_type1_audit_post'];
    canType2AuditPost = json['can_type2_audit_post'];
    canType3AuditPost = json['can_type3_audit_post'];
    canType4AuditPost = json['can_type4_audit_post'];
    canType5AuditPost = json['can_type5_audit_post'];
    canUnknown = json['can_unknown'];
    canViewFreq = json['can_view_freq'];
    canVipJubao = json['can_vip_jubao'];
    canVote = json['can_vote'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['can_add_celebrity'] = canAddCelebrity;
    data['can_add_manager_team'] = canAddManagerTeam;
    data['can_bws_FDS'] = canBwsFDS;
    data['can_bws_bawu_center'] = canBwsBawuCenter;
    data['can_bws_bawu_info'] = canBwsBawuInfo;
    data['can_bws_bawu_log'] = canBwsBawuLog;
    data['can_bws_filter_ip_tbs'] = canBwsFilterIpTbs;
    data['can_bws_limit_bawu_log'] = canBwsLimitBawuLog;
    data['can_cancel_filter_id'] = canCancelFilterId;
    data['can_cancel_mask_delete'] = canCancelMaskDelete;
    data['can_cancel_mask_good'] = canCancelMaskGood;
    data['can_cancel_mask_top'] = canCancelMaskTop;
    data['can_del_manager_team'] = canDelManagerTeam;
    data['can_edit_bakan'] = canEditBakan;
    data['can_edit_daquan'] = canEditDaquan;
    data['can_edit_gconforum'] = canEditGconforum;
    data['can_filter_id'] = canFilterId;
    data['can_filter_ip'] = canFilterIp;
    data['can_mask_delete'] = canMaskDelete;
    data['can_mask_good'] = canMaskGood;
    data['can_mask_top'] = canMaskTop;
    data['can_member_top'] = canMemberTop;
    data['can_op_FDS'] = canOpFDS;
    data['can_op_as_4thmgr'] = canOpAs4thmgr;
    data['can_op_as_broadcast_admin'] = canOpAsBroadcastAdmin;
    data['can_op_as_category_editor'] = canOpAsCategoryEditor;
    data['can_op_as_editor'] = canOpAsEditor;
    data['can_op_as_entertainment_manager'] = canOpAsEntertainmentManager;
    data['can_op_as_operator'] = canOpAsOperator;
    data['can_op_as_profession_manager'] = canOpAsProfessionManager;
    data['can_op_as_vertical_operator'] = canOpAsVerticalOperator;
    data['can_op_common_bawu'] = canOpCommonBawu;
    data['can_op_disk'] = canOpDisk;
    data['can_op_frsbg'] = canOpFrsbg;
    data['can_op_good_class'] = canOpGoodClass;
    data['can_op_pic'] = canOpPic;
    data['can_op_topic'] = canOpTopic;
    data['can_op_video'] = canOpVideo;
    data['can_op_wise_group'] = canOpWiseGroup;
    data['can_paper_ignore_vcode'] = canPaperIgnoreVcode;
    data['can_pass_media_limit'] = canPassMediaLimit;
    data['can_post'] = canPost;
    data['can_post_frs'] = canPostFrs;
    data['can_post_pb'] = canPostPb;
    data['can_send_memo'] = canSendMemo;
    data['can_super'] = canSuper;
    data['can_tobe_assist'] = canTobeAssist;
    data['can_tobe_editor'] = canTobeEditor;
    data['can_tobe_manager'] = canTobeManager;
    data['can_tobe_pri_content_assist'] = canTobePriContentAssist;
    data['can_tobe_pri_manage_assist'] = canTobePriManageAssist;
    data['can_toms_operator_alt_basic'] = canTomsOperatorAltBasic;
    data['can_toms_operator_basic'] = canTomsOperatorBasic;
    data['can_type1_audit_post'] = canType1AuditPost;
    data['can_type2_audit_post'] = canType2AuditPost;
    data['can_type3_audit_post'] = canType3AuditPost;
    data['can_type4_audit_post'] = canType4AuditPost;
    data['can_type5_audit_post'] = canType5AuditPost;
    data['can_unknown'] = canUnknown;
    data['can_view_freq'] = canViewFreq;
    data['can_vip_jubao'] = canVipJubao;
    data['can_vote'] = canVote;
    return data;
  }
}

class Grade {
  String? userId;
  String? forumId;
  String? isLike;
  String? isBlack;
  String? likeNum;
  String? isTop;
  String? inTime;
  String? levelId;
  String? levelName;
  String? curScore;
  String? scoreLeft;
  String? funcName;

  Grade(
      {this.userId,
      this.forumId,
      this.isLike,
      this.isBlack,
      this.likeNum,
      this.isTop,
      this.inTime,
      this.levelId,
      this.levelName,
      this.curScore,
      this.scoreLeft,
      this.funcName});

  Grade.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    forumId = json['forum_id'];
    isLike = json['is_like'];
    isBlack = json['is_black'];
    likeNum = json['like_num'];
    isTop = json['is_top'];
    inTime = json['in_time'];
    levelId = json['level_id'];
    levelName = json['level_name'];
    curScore = json['cur_score'];
    scoreLeft = json['score_left'];
    funcName = json['func_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_id'] = userId;
    data['forum_id'] = forumId;
    data['is_like'] = isLike;
    data['is_black'] = isBlack;
    data['like_num'] = likeNum;
    data['is_top'] = isTop;
    data['in_time'] = inTime;
    data['level_id'] = levelId;
    data['level_name'] = levelName;
    data['cur_score'] = curScore;
    data['score_left'] = scoreLeft;
    data['func_name'] = funcName;
    return data;
  }
}
