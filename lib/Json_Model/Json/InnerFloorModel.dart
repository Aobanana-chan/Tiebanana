part of json_model;

///楼中楼数据Model
class InnerFloorModel extends ThreadPageData {
  List<SubpostList>? subpostList;
  List<PostList>? postList;
  InnerFloorPost? post;
  Anti? anti;
  // Page? page;
  Thread? thread;
  Forum? forum;
  // List<UserList>? user;
  PermModel? perm;
  DisplayForum? displayForum;
  String? isBlackWhite;
  String? serverTime;
  int? time;
  int? ctime;
  int? logid;
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
        subpostList?.add(new SubpostList.fromJson(v));
      });
    }
    if (json['post_list'] != null) {
      postList = [];
      json['post_list'].forEach((v) {
        postList?.add(new PostList.fromJson(v));
      });
    }
    post =
        json['post'] != null ? new InnerFloorPost.fromJson(json['post']) : null;
    anti = json['anti'] != null ? new Anti.fromJson(json['anti']) : null;
    page = json['page'] != null ? new ThreadPage.fromJson(json['page']) : null;
    thread =
        json['thread'] != null ? new Thread.fromJson(json['thread']) : null;
    forum = json['forum'] != null ? new Forum.fromJson(json['forum']) : null;
    if (json['user'] != null) {
      if (json['user'] is List && json['user'].length != 0) {
        user = ThreadUser.fromJson(json['user']);
      }
    }
    perm = json['perm'] != null ? new PermModel.fromJson(json['perm']) : null;
    displayForum = json['display_forum'] != null
        ? new DisplayForum.fromJson(json['display_forum'])
        : null;
    isBlackWhite = json['is_black_white'];
    serverTime = json['server_time'];
    time = (json['time'] as num).toInt();
    ctime = json['ctime'];
    logid = (json['logid'] as num).toInt();
    errorCode = json['error_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.subpostList != null) {
      data['subpost_list'] = this.subpostList?.map((v) => v.toJson()).toList();
    }
    if (this.postList != null) {
      data['post_list'] = this.postList?.map((v) => v.toJson()).toList();
    }
    if (this.post != null) {
      data['post'] = this.post?.toJson();
    }
    if (this.anti != null) {
      data['anti'] = this.anti?.toJson();
    }
    if (this.page != null) {
      data['page'] = this.page?.toJson();
    }
    if (this.thread != null) {
      data['thread'] = this.thread?.toJson();
    }
    if (this.forum != null) {
      data['forum'] = this.forum?.toJson();
    }
    if (this.user != null) {
      data['user'] = this.user?.toJson();
    }
    if (this.perm != null) {
      data['perm'] = this.perm?.toJson();
    }
    if (this.displayForum != null) {
      data['display_forum'] = this.displayForum?.toJson();
    }
    data['is_black_white'] = this.isBlackWhite;
    data['server_time'] = this.serverTime;
    data['time'] = this.time;
    data['ctime'] = this.ctime;
    data['logid'] = this.logid;
    data['error_code'] = this.errorCode;
    return data;
  }
}

class SubpostList extends SubPostList {
  String? id;
  List<Content>? content;
  String? time;
  String? ptype;
  String? isGiftpost;
  Agree? agree;
  // List<Null> location;
  UserList? author;
  String? isAuthorView;
  String? title;
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
        content?.add(new Content.fromJson(v));
      });
    }
    time = json['time'];
    ptype = json['ptype'];
    isGiftpost = json['is_giftpost'];
    agree = json['agree'] != null ? new Agree.fromJson(json['agree']) : null;
    // if (json['location'] != null) {
    //   location = new List<Null>();
    //   json['location'].forEach((v) {
    //     location.add(new Null.fromJson(v));
    //   });
    // }
    author =
        json['author'] != null ? new UserList.fromJson(json['author']) : null;
    isAuthorView = json['is_author_view'];
    title = json['title'];
    floor = json['floor'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    if (this.content != null) {
      data['content'] = this.content?.map((v) => v.toJson()).toList();
    }
    data['time'] = this.time;
    data['ptype'] = this.ptype;
    data['is_giftpost'] = this.isGiftpost;
    if (this.agree != null) {
      data['agree'] = this.agree?.toJson();
    }
    // if (this.location != null) {
    //   data['location'] = this.location.map((v) => v.toJson()).toList();
    // }
    if (this.author != null) {
      data['author'] = this.author?.toJson();
    }
    data['is_author_view'] = this.isAuthorView;
    data['title'] = this.title;
    data['floor'] = this.floor;
    return data;
  }
}

class InnerFloorPost extends SubpostList {
  String? id;
  String? title;
  String? floor;
  String? time;
  List<Content>? content;
  // List<Null> lbsInfo;
  String? isVote;
  String? ptype;
  // List<Null> voiceInfo;
  Agree? agree;
  String? showSquared;
  String? baijiahaoInfo;
  String? isPostVisible;
  String? isVoice;
  // List<Null> arrVideo;
  String? isBubbleThread;
  String? isColorfullThread;
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
        content?.add(new Content.fromJson(v));
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
    agree = json['agree'] != null ? new Agree.fromJson(json['agree']) : null;
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
    author =
        json['author'] != null ? new UserList.fromJson(json['author']) : null;
    bimgUrl = json['bimg_url'];
    iosBimgFormat = json['ios_bimg_format'];
    tpointPost = json['tpoint_post'];
    skinInfo = json['skin_info'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['floor'] = this.floor;
    data['time'] = this.time;
    if (this.content != null) {
      data['content'] = this.content?.map((v) => v.toJson()).toList();
    }
    // if (this.lbsInfo != null) {
    //   data['lbs_info'] = this.lbsInfo.map((v) => v.toJson()).toList();
    // }
    // data['is_vote'] = this.isVote;
    // data['ptype'] = this.ptype;
    // if (this.voiceInfo != null) {
    //   data['voice_info'] = this.voiceInfo.map((v) => v.toJson()).toList();
    // }
    if (this.agree != null) {
      data['agree'] = this.agree?.toJson();
    }
    data['show_squared'] = this.showSquared;
    data['baijiahao_info'] = this.baijiahaoInfo;
    data['is_post_visible'] = this.isPostVisible;
    data['is_voice'] = this.isVoice;
    // if (this.arrVideo != null) {
    //   data['arr_video'] = this.arrVideo.map((v) => v.toJson()).toList();
    // }
    data['is_bubble_thread'] = this.isBubbleThread;
    data['is_colorfull_thread'] = this.isColorfullThread;
    if (this.author != null) {
      data['author'] = this.author?.toJson();
    }
    data['bimg_url'] = this.bimgUrl;
    data['ios_bimg_format'] = this.iosBimgFormat;
    data['tpoint_post'] = this.tpointPost;
    data['skin_info'] = this.skinInfo;
    return data;
  }
}

class PermModel {
  Perm? perm;
  String? uegType;
  String? blockType;
  // List<Null> tip;
  Grade? grade;

  PermModel({this.perm, this.uegType, this.blockType, this.grade});

  PermModel.fromJson(Map<String, dynamic> json) {
    perm = json['perm'] != null ? new Perm.fromJson(json['perm']) : null;
    uegType = json['ueg_type'];
    blockType = json['block_type'];
    // if (json['tip'] != null) {
    //   tip = new List<Null>();
    //   json['tip'].forEach((v) {
    //     tip.add(new Null.fromJson(v));
    //   });
    // }
    grade = json['grade'] != null ? new Grade.fromJson(json['grade']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.perm != null) {
      data['perm'] = this.perm?.toJson();
    }
    data['ueg_type'] = this.uegType;
    data['block_type'] = this.blockType;
    // if (this.tip != null) {
    //   data['tip'] = this.tip.map((v) => v.toJson()).toList();
    // }
    if (this.grade != null) {
      data['grade'] = this.grade?.toJson();
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['can_add_celebrity'] = this.canAddCelebrity;
    data['can_add_manager_team'] = this.canAddManagerTeam;
    data['can_bws_FDS'] = this.canBwsFDS;
    data['can_bws_bawu_center'] = this.canBwsBawuCenter;
    data['can_bws_bawu_info'] = this.canBwsBawuInfo;
    data['can_bws_bawu_log'] = this.canBwsBawuLog;
    data['can_bws_filter_ip_tbs'] = this.canBwsFilterIpTbs;
    data['can_bws_limit_bawu_log'] = this.canBwsLimitBawuLog;
    data['can_cancel_filter_id'] = this.canCancelFilterId;
    data['can_cancel_mask_delete'] = this.canCancelMaskDelete;
    data['can_cancel_mask_good'] = this.canCancelMaskGood;
    data['can_cancel_mask_top'] = this.canCancelMaskTop;
    data['can_del_manager_team'] = this.canDelManagerTeam;
    data['can_edit_bakan'] = this.canEditBakan;
    data['can_edit_daquan'] = this.canEditDaquan;
    data['can_edit_gconforum'] = this.canEditGconforum;
    data['can_filter_id'] = this.canFilterId;
    data['can_filter_ip'] = this.canFilterIp;
    data['can_mask_delete'] = this.canMaskDelete;
    data['can_mask_good'] = this.canMaskGood;
    data['can_mask_top'] = this.canMaskTop;
    data['can_member_top'] = this.canMemberTop;
    data['can_op_FDS'] = this.canOpFDS;
    data['can_op_as_4thmgr'] = this.canOpAs4thmgr;
    data['can_op_as_broadcast_admin'] = this.canOpAsBroadcastAdmin;
    data['can_op_as_category_editor'] = this.canOpAsCategoryEditor;
    data['can_op_as_editor'] = this.canOpAsEditor;
    data['can_op_as_entertainment_manager'] = this.canOpAsEntertainmentManager;
    data['can_op_as_operator'] = this.canOpAsOperator;
    data['can_op_as_profession_manager'] = this.canOpAsProfessionManager;
    data['can_op_as_vertical_operator'] = this.canOpAsVerticalOperator;
    data['can_op_common_bawu'] = this.canOpCommonBawu;
    data['can_op_disk'] = this.canOpDisk;
    data['can_op_frsbg'] = this.canOpFrsbg;
    data['can_op_good_class'] = this.canOpGoodClass;
    data['can_op_pic'] = this.canOpPic;
    data['can_op_topic'] = this.canOpTopic;
    data['can_op_video'] = this.canOpVideo;
    data['can_op_wise_group'] = this.canOpWiseGroup;
    data['can_paper_ignore_vcode'] = this.canPaperIgnoreVcode;
    data['can_pass_media_limit'] = this.canPassMediaLimit;
    data['can_post'] = this.canPost;
    data['can_post_frs'] = this.canPostFrs;
    data['can_post_pb'] = this.canPostPb;
    data['can_send_memo'] = this.canSendMemo;
    data['can_super'] = this.canSuper;
    data['can_tobe_assist'] = this.canTobeAssist;
    data['can_tobe_editor'] = this.canTobeEditor;
    data['can_tobe_manager'] = this.canTobeManager;
    data['can_tobe_pri_content_assist'] = this.canTobePriContentAssist;
    data['can_tobe_pri_manage_assist'] = this.canTobePriManageAssist;
    data['can_toms_operator_alt_basic'] = this.canTomsOperatorAltBasic;
    data['can_toms_operator_basic'] = this.canTomsOperatorBasic;
    data['can_type1_audit_post'] = this.canType1AuditPost;
    data['can_type2_audit_post'] = this.canType2AuditPost;
    data['can_type3_audit_post'] = this.canType3AuditPost;
    data['can_type4_audit_post'] = this.canType4AuditPost;
    data['can_type5_audit_post'] = this.canType5AuditPost;
    data['can_unknown'] = this.canUnknown;
    data['can_view_freq'] = this.canViewFreq;
    data['can_vip_jubao'] = this.canVipJubao;
    data['can_vote'] = this.canVote;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['forum_id'] = this.forumId;
    data['is_like'] = this.isLike;
    data['is_black'] = this.isBlack;
    data['like_num'] = this.likeNum;
    data['is_top'] = this.isTop;
    data['in_time'] = this.inTime;
    data['level_id'] = this.levelId;
    data['level_name'] = this.levelName;
    data['cur_score'] = this.curScore;
    data['score_left'] = this.scoreLeft;
    data['func_name'] = this.funcName;
    return data;
  }
}
