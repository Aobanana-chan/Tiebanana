part of json_model;

///贴页面数据Model
class ThreadPageData {
  String? hasFloor;
  String? isNewUrl;
  List? newsInfo;
  Forum? forum;
  DisplayForum? displayForum;
  ThreadUser? user;
  Anti? anti;
  ThreadPage? page;
  List<PostList>? postList;
  Thread? thread;
  List<AlaInfo>? alaInfo;
  List<UserList>? userList;
  // BusinessPromotInfo businessPromotInfo;
  String? switchReadOpen;
  String? isOfficialForum;
  String? isPurchase;
  // TwzhiboAnti twzhiboAnti;
  List? sampleSidsTemp;
  String? showAdsense;
  String? isBlackWhite;
  BannerList? bannerList;
  String? hasFoldComment;
  String? partialVisibleToast;
  String? foldTip;
  String? sortType;
  List<PbSortInfo>? pbSortInfo;
  String? serverTime;
  int? time;
  int? ctime;
  int? logid;
  String? errorCode;

  ThreadPageData(
      {this.hasFloor,
      this.isNewUrl,
      this.newsInfo,
      this.forum,
      this.displayForum,
      this.user,
      this.anti,
      this.page,
      this.postList,
      this.thread,
      this.alaInfo,
      this.userList,
      // this.businessPromotInfo,
      this.switchReadOpen,
      this.isOfficialForum,
      this.isPurchase,
      // this.twzhiboAnti,
      this.sampleSidsTemp,
      this.showAdsense,
      this.isBlackWhite,
      this.bannerList,
      this.hasFoldComment,
      this.partialVisibleToast,
      this.foldTip,
      this.sortType,
      this.pbSortInfo,
      this.serverTime,
      this.time,
      this.ctime,
      this.logid,
      this.errorCode});

  ThreadPageData.fromJson(Map<String, dynamic> json) {
    hasFloor = json['has_floor'];
    isNewUrl = json['is_new_url'];
    if (json['news_info'] != null) {
      newsInfo = [];
      json['news_info'].forEach((v) {
        newsInfo?.add(v);
      });
    }
    forum = json['forum'] != null ? new Forum.fromJson(json['forum']) : null;
    displayForum = json['display_forum'] != null
        ? new DisplayForum.fromJson(json['display_forum'])
        : null;
    user = json['user'] != null ? new ThreadUser.fromJson(json['user']) : null;
    anti = json['anti'] != null ? new Anti.fromJson(json['anti']) : null;
    page = json['page'] != null ? new ThreadPage.fromJson(json['page']) : null;
    if (json['post_list'] != null) {
      postList = [];
      json['post_list'].forEach((v) {
        postList?.add(new PostList.fromJson(v));
      });
    }
    thread =
        json['thread'] != null ? new Thread.fromJson(json['thread']) : null;
    if (json['ala_info'] != null) {
      alaInfo = [];
      json['ala_info'].forEach((v) {
        alaInfo?.add(v);
      });
    }
    if (json['user_list'] != null) {
      userList = [];
      json['user_list'].forEach((v) {
        userList?.add(new UserList.fromJson(v));
      });
    }
    // businessPromotInfo = json['business_promot_info'] != null
    //     ? new BusinessPromotInfo.fromJson(json['business_promot_info'])
    //     : null;
    switchReadOpen = json['switch_read_open'];
    isOfficialForum = json['is_official_forum'];
    isPurchase = json['is_purchase'];
    // twzhiboAnti = json['twzhibo_anti'] != null
    //     ? new TwzhiboAnti.fromJson(json['twzhibo_anti'])
    //     : null;
    if (json['sample_sids_temp'] != null) {
      sampleSidsTemp = [];
      json['sample_sids_temp'].forEach((v) {
        sampleSidsTemp?.add(v);
      });
    }
    showAdsense = json['show_adsense'];
    isBlackWhite = json['is_black_white'];
    bannerList = json['banner_list'] != null
        ? new BannerList.fromJson(json['banner_list'])
        : null;
    hasFoldComment = json['has_fold_comment'];
    partialVisibleToast = json['partial_visible_toast'];
    foldTip = json['fold_tip'];
    sortType = json['sort_type'];
    if (json['pb_sort_info'] != null) {
      pbSortInfo = [];
      json['pb_sort_info'].forEach((v) {
        pbSortInfo?.add(new PbSortInfo.fromJson(v));
      });
    }
    serverTime = json['server_time'];
    time = (json['time'] as double).toInt();
    ctime = json['ctime'];
    logid = (json['logid'] as double).toInt();
    errorCode = json['error_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['has_floor'] = this.hasFloor;
    data['is_new_url'] = this.isNewUrl;
    if (this.newsInfo != null) {
      data['news_info'] = this.newsInfo?.map((v) => v.toJson()).toList();
    }
    if (this.forum != null) {
      data['forum'] = this.forum?.toJson();
    }
    if (this.displayForum != null) {
      data['display_forum'] = this.displayForum?.toJson();
    }
    if (this.user != null) {
      data['user'] = this.user?.toJson();
    }
    if (this.anti != null) {
      data['anti'] = this.anti?.toJson();
    }
    if (this.page != null) {
      data['page'] = this.page?.toJson();
    }
    if (this.postList != null) {
      data['post_list'] = this.postList?.map((v) => v.toJson()).toList();
    }
    if (this.thread != null) {
      data['thread'] = this.thread?.toJson();
    }
    if (this.alaInfo != null) {
      data['ala_info'] = this.alaInfo?.map((v) => v.toJson()).toList();
    }
    if (this.userList != null) {
      data['user_list'] = this.userList?.map((v) => v.toJson()).toList();
    }
    // if (this.businessPromotInfo != null) {
    //   data['business_promot_info'] = this.businessPromotInfo.toJson();
    // }
    data['switch_read_open'] = this.switchReadOpen;
    data['is_official_forum'] = this.isOfficialForum;
    data['is_purchase'] = this.isPurchase;
    // if (this.twzhiboAnti != null) {
    //   data['twzhibo_anti'] = this.twzhiboAnti.toJson();
    // }
    if (this.sampleSidsTemp != null) {
      data['sample_sids_temp'] =
          this.sampleSidsTemp?.map((v) => v.toJson()).toList();
    }
    data['show_adsense'] = this.showAdsense;
    data['is_black_white'] = this.isBlackWhite;
    if (this.bannerList != null) {
      data['banner_list'] = this.bannerList?.toJson();
    }
    data['has_fold_comment'] = this.hasFoldComment;
    data['partial_visible_toast'] = this.partialVisibleToast;
    data['fold_tip'] = this.foldTip;
    data['sort_type'] = this.sortType;
    if (this.pbSortInfo != null) {
      data['pb_sort_info'] = this.pbSortInfo?.map((v) => v.toJson()).toList();
    }
    data['server_time'] = this.serverTime;
    data['time'] = this.time;
    data['ctime'] = this.ctime;
    data['logid'] = this.logid;
    data['error_code'] = this.errorCode;
    return data;
  }
}

// class Forum {
//   String id;
//   String name;
//   String avatar;
//   String firstClass;
//   String secondClass;
//   String isLiked;
//   String isBrandForum;

//   Forum(
//       {this.id,
//       this.name,
//       this.avatar,
//       this.firstClass,
//       this.secondClass,
//       this.isLiked,
//       this.isBrandForum});

//   Forum.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     name = json['name'];
//     avatar = json['avatar'];
//     firstClass = json['first_class'];
//     secondClass = json['second_class'];
//     isLiked = json['is_liked'];
//     isBrandForum = json['is_brand_forum'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['name'] = this.name;
//     data['avatar'] = this.avatar;
//     data['first_class'] = this.firstClass;
//     data['second_class'] = this.secondClass;
//     data['is_liked'] = this.isLiked;
//     data['is_brand_forum'] = this.isBrandForum;
//     return data;
//   }
// }

class DisplayForum {
  String? id;
  String? name;
  String? isExists;
  String? avatar;
  String? firstClass;
  String? secondClass;
  String? isLiked;
  String? isBrandForum;

  DisplayForum(
      {this.id,
      this.name,
      this.isExists,
      this.avatar,
      this.firstClass,
      this.secondClass,
      this.isLiked,
      this.isBrandForum});

  DisplayForum.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    isExists = json['is_exists'];
    avatar = json['avatar'];
    firstClass = json['first_class'];
    secondClass = json['second_class'];
    isLiked = json['is_liked'];
    isBrandForum = json['is_brand_forum'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['is_exists'] = this.isExists;
    data['avatar'] = this.avatar;
    data['first_class'] = this.firstClass;
    data['second_class'] = this.secondClass;
    data['is_liked'] = this.isLiked;
    data['is_brand_forum'] = this.isBrandForum;
    return data;
  }
}

class ThreadUser {
  String? isManager;
  String? bimgEndTime;
  String? isSelectTail;
  String? muteUser;
  String? leftCallNum;
  // CallFansInfo? callFansInfo;
  String? forumToolAuth;
  String? showPbPrivateFlag;

  ThreadUser(
      {this.isManager,
      this.bimgEndTime,
      this.isSelectTail,
      this.muteUser,
      this.leftCallNum,
      // this.callFansInfo,
      this.forumToolAuth,
      this.showPbPrivateFlag});

  ThreadUser.fromJson(Map<String, dynamic> json) {
    isManager = json['is_manager'];
    bimgEndTime = json['bimg_end_time'];
    isSelectTail = json['is_select_tail'];
    muteUser = json['mute_user'];
    leftCallNum = json['left_call_num'];
    // callFansInfo = json['call_fans_info'] != null
    //     ? new CallFansInfo.fromJson(json['call_fans_info'])
    //     : null;
    forumToolAuth = json['forum_tool_auth'];
    showPbPrivateFlag = json['show_pb_private_flag'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_manager'] = this.isManager;
    data['bimg_end_time'] = this.bimgEndTime;
    data['is_select_tail'] = this.isSelectTail;
    data['mute_user'] = this.muteUser;
    data['left_call_num'] = this.leftCallNum;
    // if (this.callFansInfo != null) {
    //   data['call_fans_info'] = this.callFansInfo?.toJson();
    // }
    data['forum_tool_auth'] = this.forumToolAuth;
    data['show_pb_private_flag'] = this.showPbPrivateFlag;
    return data;
  }
}

// class CallFansInfo {
//   String canCall;

//   CallFansInfo({this.canCall});

//   CallFansInfo.fromJson(Map<String, dynamic> json) {
//     canCall = json['can_call'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['can_call'] = this.canCall;
//     return data;
//   }
// }

// class Anti {
//   String ifvoice;
//   String voiceMessage;
//   String tbs;
//   String videoMessage;
//   String ifaddition;
//   String forbidFlag;
//   String forbidInfo;
//   String ifpost;
//   String ifxiaoying;
//   BlockPopInfo blockPopInfo;
//   String replyPrivateFlag;

//   Anti(
//       {this.ifvoice,
//       this.voiceMessage,
//       this.tbs,
//       this.videoMessage,
//       this.ifaddition,
//       this.forbidFlag,
//       this.forbidInfo,
//       this.ifpost,
//       this.ifxiaoying,
//       this.blockPopInfo,
//       this.replyPrivateFlag});

//   Anti.fromJson(Map<String, dynamic> json) {
//     ifvoice = json['ifvoice'];
//     voiceMessage = json['voice_message'];
//     tbs = json['tbs'];
//     videoMessage = json['video_message'];
//     ifaddition = json['ifaddition'];
//     forbidFlag = json['forbid_flag'];
//     forbidInfo = json['forbid_info'];
//     ifpost = json['ifpost'];
//     ifxiaoying = json['ifxiaoying'];
//     blockPopInfo = json['block_pop_info'] != null
//         ? new BlockPopInfo.fromJson(json['block_pop_info'])
//         : null;
//     replyPrivateFlag = json['reply_private_flag'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['ifvoice'] = this.ifvoice;
//     data['voice_message'] = this.voiceMessage;
//     data['tbs'] = this.tbs;
//     data['video_message'] = this.videoMessage;
//     data['ifaddition'] = this.ifaddition;
//     data['forbid_flag'] = this.forbidFlag;
//     data['forbid_info'] = this.forbidInfo;
//     data['ifpost'] = this.ifpost;
//     data['ifxiaoying'] = this.ifxiaoying;
//     if (this.blockPopInfo != null) {
//       data['block_pop_info'] = this.blockPopInfo.toJson();
//     }
//     data['reply_private_flag'] = this.replyPrivateFlag;
//     return data;
//   }
// }

// class BlockPopInfo {
//   String canPost;
//   String blockInfo;
//   String subBlockInfo;

//   BlockPopInfo({this.canPost, this.blockInfo, this.subBlockInfo});

//   BlockPopInfo.fromJson(Map<String, dynamic> json) {
//     canPost = json['can_post'];
//     blockInfo = json['block_info'];
//     subBlockInfo = json['sub_block_info'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['can_post'] = this.canPost;
//     data['block_info'] = this.blockInfo;
//     data['sub_block_info'] = this.subBlockInfo;
//     return data;
//   }
// }

class ThreadPage {
  String? reqNum;
  String? pageSize;
  String? offset;
  String? currentPage;
  String? totalPage;
  String? totalNum;
  String? pnum;
  String? tnum;
  String? newTotalPage;
  String? hasMore;
  String? hasPrev;

  ThreadPage(
      {this.reqNum,
      this.pageSize,
      this.offset,
      this.currentPage,
      this.totalPage,
      this.totalNum,
      this.pnum,
      this.tnum,
      this.newTotalPage,
      this.hasMore,
      this.hasPrev});

  ThreadPage.fromJson(Map<String, dynamic> json) {
    reqNum = json['req_num'];
    pageSize = json['page_size'];
    offset = json['offset'];
    currentPage = json['current_page'];
    totalPage = json['total_page'];
    totalNum = json['total_num'];
    pnum = json['pnum'];
    tnum = json['tnum'];
    newTotalPage = json['new_total_page'];
    hasMore = json['has_more'];
    hasPrev = json['has_prev'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['req_num'] = this.reqNum;
    data['page_size'] = this.pageSize;
    data['offset'] = this.offset;
    data['current_page'] = this.currentPage;
    data['total_page'] = this.totalPage;
    data['total_num'] = this.totalNum;
    data['pnum'] = this.pnum;
    data['tnum'] = this.tnum;
    data['new_total_page'] = this.newTotalPage;
    data['has_more'] = this.hasMore;
    data['has_prev'] = this.hasPrev;
    return data;
  }
}

class PostList {
  String? id;
  String? title;
  String? floor;
  String? time;
  List<Content>? content;
  String? subPostNumber;
  List<SubPostList>? subPostList;
  String? bimgUrl;
  String? iosBimgFormat;
  String? addPostList;
  String? hasSignature;
  Signature? signature;
  // List<Null>? tailInfo;
  LbsInfo? lbsInfo;
  String? zan;
  String? isGiftpost;
  String? tpointPost;
  String? actPost;
  String? present;
  String? extTails;
  String? pbDealInfo;
  String? skinInfo;
  Agree? agree;
  String? fromForum;
  String? isPostVisible;
  String? isFirstFloor;
  String? needLog;
  String? isFold;
  String? isTopAgreePost;
  String? showSquared;
  String? isWonderfulPost;
  String? item;
  String? outerItem;
  String? itemStar;
  String? advertisement;
  String? foldCommentStatus;
  String? foldCommentApplyUrl;
  String? novelInfo;
  String? authorId;
  String? foldTip;

  PostList(
      {this.id,
      this.title,
      this.floor,
      this.time,
      this.content,
      this.subPostNumber,
      this.subPostList,
      this.bimgUrl,
      this.iosBimgFormat,
      this.addPostList,
      this.hasSignature,
      this.signature,
      // this.tailInfo,
      this.lbsInfo,
      this.zan,
      this.isGiftpost,
      this.tpointPost,
      this.actPost,
      this.present,
      this.extTails,
      this.pbDealInfo,
      this.skinInfo,
      this.agree,
      this.fromForum,
      this.isPostVisible,
      this.isFirstFloor,
      this.needLog,
      this.isFold,
      this.isTopAgreePost,
      this.showSquared,
      this.isWonderfulPost,
      this.item,
      this.outerItem,
      this.itemStar,
      this.advertisement,
      this.foldCommentStatus,
      this.foldCommentApplyUrl,
      this.novelInfo,
      this.authorId,
      this.foldTip});

  PostList.fromJson(Map<String, dynamic> json) {
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
    subPostNumber = json['sub_post_number'];
    if (json['sub_post_list'] is Map) {
      if (json['sub_post_list']['sub_post_list'] is List &&
          json['sub_post_list']['sub_post_list'].length > 0) {
        subPostList = [];
        json['sub_post_list']['sub_post_list'].forEach((v) {
          subPostList?.add(SubPostList.fromJson(v));
        });
      } else {
        throw Exception("未知类型");
      }
    }

    bimgUrl = json['bimg_url'];
    iosBimgFormat = json['ios_bimg_format'];
    addPostList = json['add_post_list'];
    hasSignature = json['has_signature'];
    if (json['signature'] is Map) {
      signature = json['signature'] != null
          ? new Signature.fromJson(json['signature'])
          : null;
    } else if (json['signature'] is List) {
      if (json['signature'].length == 0) {
        signature = null;
      }
    } else {
      throw Exception("未知数据类型");
    }

    // if (json['tail_info'] != null) {
    //   tailInfo = [];
    //   json['tail_info'].forEach((v) {
    //     tailInfo?.add(v);
    //   });
    // }
    if (json['lbs_info'] != null) {
      if (json['lbs_info'] is Map) {
        lbsInfo = LbsInfo.fromJson(json['lbs_info']);
      } else if (json['lbs_info'] is List && json['lbs_info'].length == 0) {
        lbsInfo = null;
      } else {
        throw Exception("未知数据类型");
      }
    }
    zan = json['zan'];
    isGiftpost = json['is_giftpost'];
    tpointPost = json['tpoint_post'];
    actPost = json['act_post'];
    present = json['present'];
    extTails = json['ext_tails'];
    pbDealInfo = json['pb_deal_info'];
    skinInfo = json['skin_info'];
    agree = json['agree'] != null ? new Agree.fromJson(json['agree']) : null;
    fromForum = json['from_forum'];
    isPostVisible = json['is_post_visible'];
    isFirstFloor = json['is_first_floor'];
    needLog = json['need_log'];
    isFold = json['is_fold'];
    isTopAgreePost = json['is_top_agree_post'];
    showSquared = json['show_squared'];
    isWonderfulPost = json['is_wonderful_post'];
    item = json['item'];
    outerItem = json['outer_item'];
    itemStar = json['item_star'];
    advertisement = json['advertisement'];
    foldCommentStatus = json['fold_comment_status'];
    foldCommentApplyUrl = json['fold_comment_apply_url'];
    novelInfo = json['novel_info'];
    authorId = json['author_id'];
    foldTip = json['fold_tip'];
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
    data['sub_post_number'] = this.subPostNumber;
    if (this.subPostList != null) {
      data['sub_post_list'] = this.subPostList?.map((v) => v.toJson()).toList();
    }
    data['bimg_url'] = this.bimgUrl;
    data['ios_bimg_format'] = this.iosBimgFormat;
    data['add_post_list'] = this.addPostList;
    data['has_signature'] = this.hasSignature;
    if (this.signature != null) {
      data['signature'] = this.signature?.toJson();
    }
    // if (this.tailInfo != null) {
    //   // data['tail_info'] = this.tailInfo?.map((v) => v.toJson()).toList();
    // }
    if (this.lbsInfo != null) {
      data['lbs_info'] = this.lbsInfo!.toJson();
    }
    data['zan'] = this.zan;
    data['is_giftpost'] = this.isGiftpost;
    data['tpoint_post'] = this.tpointPost;
    data['act_post'] = this.actPost;
    data['present'] = this.present;
    data['ext_tails'] = this.extTails;
    data['pb_deal_info'] = this.pbDealInfo;
    data['skin_info'] = this.skinInfo;
    if (this.agree != null) {
      data['agree'] = this.agree?.toJson();
    }
    data['from_forum'] = this.fromForum;
    data['is_post_visible'] = this.isPostVisible;
    data['is_first_floor'] = this.isFirstFloor;
    data['need_log'] = this.needLog;
    data['is_fold'] = this.isFold;
    data['is_top_agree_post'] = this.isTopAgreePost;
    data['show_squared'] = this.showSquared;
    data['is_wonderful_post'] = this.isWonderfulPost;
    data['item'] = this.item;
    data['outer_item'] = this.outerItem;
    data['item_star'] = this.itemStar;
    data['advertisement'] = this.advertisement;
    data['fold_comment_status'] = this.foldCommentStatus;
    data['fold_comment_apply_url'] = this.foldCommentApplyUrl;
    data['novel_info'] = this.novelInfo;
    data['author_id'] = this.authorId;
    data['fold_tip'] = this.foldTip;
    return data;
  }
}

class Content {
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
  String? isNativeApp;
  List? nativeApp;
  String? text;
  String? c;
  String? uid;
  String? uname;
  Content(
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
      this.isNativeApp,
      this.nativeApp,
      this.text,
      this.c,
      this.uid,
      this.uname});

  Content.fromJson(Map<String, dynamic> json) {
    uid = json["uid"];
    uname = json["uid"];
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
    isNativeApp = json['is_native_app'];
    if (json['native_app'] != null) {
      nativeApp = [];
      json['native_app'].forEach((v) {
        nativeApp?.add(v);
      });
    }
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
    data['is_native_app'] = this.isNativeApp;
    data["uid"] = uid;
    data["uname"] = uname;
    if (this.nativeApp != null) {
      // data['native_app'] = this.nativeApp.map((v) => v.toJson()).toList();
    }
    data['text'] = this.text;
    data['c'] = this.c;
    return data;
  }
}

class Signature {
  List<Content>? content;
  String? signatureId;
  String? fontKeyName;
  String? fontColor;

  Signature({this.content, this.signatureId, this.fontKeyName, this.fontColor});

  Signature.fromJson(Map<String, dynamic> json) {
    if (json['content'] != null) {
      content = [];
      json['content'].forEach((v) {
        content?.add(new Content.fromJson(v));
      });
    }
    signatureId = json['signature_id'];
    fontKeyName = json['fontKeyName'];
    fontColor = json['fontColor'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.content != null) {
      data['content'] = this.content?.map((v) => v.toJson()).toList();
    }
    data['signature_id'] = this.signatureId;
    data['fontKeyName'] = this.fontKeyName;
    data['fontColor'] = this.fontColor;
    return data;
  }
}

// class Content {
//   String type;
//   String text;

//   Content({this.type, this.text});

//   Content.fromJson(Map<String, dynamic> json) {
//     type = json['type'];
//     text = json['text'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['type'] = this.type;
//     data['text'] = this.text;
//     return data;
//   }
// }

// class Agree {
//   String agreeNum;
//   String disagreeNum;
//   String diffAgreeNum;
//   String hasAgree;
//   String agreeType;

//   Agree(
//       {this.agreeNum,
//       this.disagreeNum,
//       this.diffAgreeNum,
//       this.hasAgree,
//       this.agreeType});

//   Agree.fromJson(Map<String, dynamic> json) {
//     agreeNum = json['agree_num'];
//     disagreeNum = json['disagree_num'];
//     diffAgreeNum = json['diff_agree_num'];
//     hasAgree = json['has_agree'];
//     agreeType = json['agree_type'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['agree_num'] = this.agreeNum;
//     data['disagree_num'] = this.disagreeNum;
//     data['diff_agree_num'] = this.diffAgreeNum;
//     data['has_agree'] = this.hasAgree;
//     data['agree_type'] = this.agreeType;
//     return data;
//   }
// }

class Thread {
  String? id;
  String? title;
  String? replyNum;
  String? collectStatus;
  String? collectMarkPid;
  Author? author;
  String? isGood;
  String? isTop;
  Topic? topic;
  Zan? zan;
  String? postId;
  String? createTime;
  String? isNtitle;
  List? location;
  String? actInfo;
  String? isActivity;
  String? lastTimeInt;
  String? storecount;
  String? livecoverSrc;
  // TwzhiboInfo? twzhiboInfo;
  String? pollInfo;
  VideoInfo? videoInfo;
  String? videoChannelInfo;
  String? threadType;
  String? taskInfo;
  String? jid;
  String? categoryName;
  String? yulePostActivity;
  String? extTails;
  String? pushStatus;
  String? cartoonInfo;
  String? richTitle;
  String? originThreadInfo;
  String? isShareThread;
  String? richAbstract;
  String? declareList;
  Agree? agree;
  String? isMultiforumThread;
  String? isLinkThread;
  String? linkInfo;
  String? shareNum;
  String? isCalled;
  String? swanInfo;
  String? noSmartPb;
  String? tShareImg;
  String? isBazhuApply;
  String? threadShareLink;
  String? nid;
  String? pbLinkInfo;
  String? pbGoodsInfo;
  String? worksInfo;
  String? collectNum;
  String? isFrsMask;
  String? isPartialVisible;

  Thread(
      {this.id,
      this.title,
      this.replyNum,
      this.collectStatus,
      this.collectMarkPid,
      this.author,
      this.isGood,
      this.isTop,
      this.topic,
      this.zan,
      this.postId,
      this.createTime,
      this.isNtitle,
      this.location,
      this.actInfo,
      this.isActivity,
      this.lastTimeInt,
      this.storecount,
      this.livecoverSrc,
      // this.twzhiboInfo,
      this.pollInfo,
      this.videoInfo,
      this.videoChannelInfo,
      this.threadType,
      this.taskInfo,
      this.jid,
      this.categoryName,
      this.yulePostActivity,
      this.extTails,
      this.pushStatus,
      this.cartoonInfo,
      this.richTitle,
      this.originThreadInfo,
      this.isShareThread,
      this.richAbstract,
      this.declareList,
      this.agree,
      this.isMultiforumThread,
      this.isLinkThread,
      this.linkInfo,
      this.shareNum,
      this.isCalled,
      this.swanInfo,
      this.noSmartPb,
      this.tShareImg,
      this.isBazhuApply,
      this.threadShareLink,
      this.nid,
      this.pbLinkInfo,
      this.pbGoodsInfo,
      this.worksInfo,
      this.collectNum,
      this.isFrsMask,
      this.isPartialVisible});

  Thread.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    replyNum = json['reply_num'];
    collectStatus = json['collect_status'];
    collectMarkPid = json['collect_mark_pid'];
    author =
        json['author'] != null ? new Author.fromJson(json['author']) : null;
    isGood = json['is_good'];
    isTop = json['is_top'];
    topic = json['topic'] != null ? new Topic.fromJson(json['topic']) : null;
    zan = json['zan'] != null ? new Zan.fromJson(json['zan']) : null;
    postId = json['post_id'];
    createTime = json['create_time'];
    isNtitle = json['is_ntitle'];
    if (json['location'] != null) {
      location = [];
      json['location'].forEach((v) {
        location?.add(v);
      });
    }
    actInfo = json['act_info'];
    isActivity = json['is_activity'];
    lastTimeInt = json['last_time_int'];
    storecount = json['storecount'];
    livecoverSrc = json['livecover_src'];
    // twzhiboInfo = json['twzhibo_info'] != null
    //     ? new TwzhiboInfo.fromJson(json['twzhibo_info'])
    //     : null;
    pollInfo = json['poll_info'];
    if (json['video_info'] != null && json['video_info'] != "") {
      videoInfo = VideoInfo.fromJson(json['video_info']);
    }

    videoChannelInfo = json['video_channel_info'];
    threadType = json['thread_type'];
    taskInfo = json['task_info'];
    jid = json['jid'];
    categoryName = json['category_name'];
    yulePostActivity = json['yule_post_activity'];
    extTails = json['ext_tails'];
    pushStatus = json['push_status'];
    cartoonInfo = json['cartoon_info'];
    //TODO:有bug,案例json
    //[{type: 18, text: #刀剑神域进击篇#, link: http://tieba.baidu.com/mo/q/hotMessage?topic_id=0&fid=7012688&topic_name=刀剑神域进击篇&is_video_topic=0}, {type: 0, text:   《无星之夜的咏叹调》先蹲起来 二楼补脑}]
    //部分贴会带有话题Tag,不带话题Tag时候是String
    // richTitle = json['rich_title'];
    originThreadInfo = json['origin_thread_info'];
    isShareThread = json['is_share_thread'];
    richAbstract = json['rich_abstract'];
    declareList = json['declare_list'];
    agree = json['agree'] != null ? new Agree.fromJson(json['agree']) : null;
    isMultiforumThread = json['is_multiforum_thread'];
    isLinkThread = json['is_link_thread'];
    linkInfo = json['link_info'];
    shareNum = json['share_num'];
    isCalled = json['is_called'];
    swanInfo = json['swan_info'];
    noSmartPb = json['no_smart_pb'];
    tShareImg = json['t_share_img'];
    isBazhuApply = json['is_bazhu_apply'];
    threadShareLink = json['thread_share_link'];
    nid = json['nid'];
    pbLinkInfo = json['pb_link_info'];
    pbGoodsInfo = json['pb_goods_info'];
    worksInfo = json['works_info'];
    collectNum = json['collect_num'];
    isFrsMask = json['is_frs_mask'];
    isPartialVisible = json['is_partial_visible'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['reply_num'] = this.replyNum;
    data['collect_status'] = this.collectStatus;
    data['collect_mark_pid'] = this.collectMarkPid;
    if (this.author != null) {
      data['author'] = this.author?.toJson();
    }
    data['is_good'] = this.isGood;
    data['is_top'] = this.isTop;
    if (this.topic != null) {
      data['topic'] = this.topic?.toJson();
    }
    if (this.zan != null) {
      data['zan'] = this.zan?.toJson();
    }
    data['post_id'] = this.postId;
    data['create_time'] = this.createTime;
    data['is_ntitle'] = this.isNtitle;
    if (this.location != null) {
      data['location'] = this.location?.map((v) => v.toJson()).toList();
    }
    data['act_info'] = this.actInfo;
    data['is_activity'] = this.isActivity;
    data['last_time_int'] = this.lastTimeInt;
    data['storecount'] = this.storecount;
    data['livecover_src'] = this.livecoverSrc;
    // if (this.twzhiboInfo != null) {
    //   data['twzhibo_info'] = this.twzhiboInfo?.toJson();
    // }
    data['poll_info'] = this.pollInfo;
    data['video_info'] = this.videoInfo;
    data['video_channel_info'] = this.videoChannelInfo;
    data['thread_type'] = this.threadType;
    data['task_info'] = this.taskInfo;
    data['jid'] = this.jid;
    data['category_name'] = this.categoryName;
    data['yule_post_activity'] = this.yulePostActivity;
    data['ext_tails'] = this.extTails;
    data['push_status'] = this.pushStatus;
    data['cartoon_info'] = this.cartoonInfo;
    data['rich_title'] = this.richTitle;
    data['origin_thread_info'] = this.originThreadInfo;
    data['is_share_thread'] = this.isShareThread;
    data['rich_abstract'] = this.richAbstract;
    data['declare_list'] = this.declareList;
    if (this.agree != null) {
      data['agree'] = this.agree?.toJson();
    }
    data['is_multiforum_thread'] = this.isMultiforumThread;
    data['is_link_thread'] = this.isLinkThread;
    data['link_info'] = this.linkInfo;
    data['share_num'] = this.shareNum;
    data['is_called'] = this.isCalled;
    data['swan_info'] = this.swanInfo;
    data['no_smart_pb'] = this.noSmartPb;
    data['t_share_img'] = this.tShareImg;
    data['is_bazhu_apply'] = this.isBazhuApply;
    data['thread_share_link'] = this.threadShareLink;
    data['nid'] = this.nid;
    data['pb_link_info'] = this.pbLinkInfo;
    data['pb_goods_info'] = this.pbGoodsInfo;
    data['works_info'] = this.worksInfo;
    data['collect_num'] = this.collectNum;
    data['is_frs_mask'] = this.isFrsMask;
    data['is_partial_visible'] = this.isPartialVisible;
    return data;
  }
}

// class Author {
//   String name;
//   String nameShow;
//   String id;
//   String type;
//   String portrait;
//   String levelId;
//   String isLike;
//   List<Iconinfo> iconinfo;
//   List<TshowIcon> tshowIcon;
//   List<NewTshowIcon> newTshowIcon;
//   String isBawu;
//   String bawuType;
//   String gender;
//   String hasConcerned;
//   String fansNickname;
//   String fansNum;
//   String agreeNum;
//   String threadNum;
//   String godData;
//   String giftNum;
//   List<Null> tbVip;
//   Pendant pendant;
//   AlaInfo alaInfo;
//   String alaLiveInfo;
//   String sealPrefix;
//   List<Null> springVirtualUser;
//   String esportData;
//   PrivSets privSets;
//   String baijiahaoInfo;
//   String godInfo;
//   String bazhuGrade;
//   NewGodData newGodData;
//   List<Null> businessAccountInfo;
//   String displayAuthType;
//   String workCreatorInfo;

//   Author(
//       {this.name,
//       this.nameShow,
//       this.id,
//       this.type,
//       this.portrait,
//       this.levelId,
//       this.isLike,
//       this.iconinfo,
//       this.tshowIcon,
//       this.newTshowIcon,
//       this.isBawu,
//       this.bawuType,
//       this.gender,
//       this.hasConcerned,
//       this.fansNickname,
//       this.fansNum,
//       this.agreeNum,
//       this.threadNum,
//       this.godData,
//       this.giftNum,
//       this.tbVip,
//       this.pendant,
//       this.alaInfo,
//       this.alaLiveInfo,
//       this.sealPrefix,
//       this.springVirtualUser,
//       this.esportData,
//       this.privSets,
//       this.baijiahaoInfo,
//       this.godInfo,
//       this.bazhuGrade,
//       this.newGodData,
//       this.businessAccountInfo,
//       this.displayAuthType,
//       this.workCreatorInfo});

//   Author.fromJson(Map<String, dynamic> json) {
//     name = json['name'];
//     nameShow = json['name_show'];
//     id = json['id'];
//     type = json['type'];
//     portrait = json['portrait'];
//     levelId = json['level_id'];
//     isLike = json['is_like'];
//     if (json['iconinfo'] != null) {
//       iconinfo = new List<Iconinfo>();
//       json['iconinfo'].forEach((v) {
//         iconinfo.add(new Iconinfo.fromJson(v));
//       });
//     }
//     if (json['tshow_icon'] != null) {
//       tshowIcon = new List<TshowIcon>();
//       json['tshow_icon'].forEach((v) {
//         tshowIcon.add(new TshowIcon.fromJson(v));
//       });
//     }
//     if (json['new_tshow_icon'] != null) {
//       newTshowIcon = new List<NewTshowIcon>();
//       json['new_tshow_icon'].forEach((v) {
//         newTshowIcon.add(new NewTshowIcon.fromJson(v));
//       });
//     }
//     isBawu = json['is_bawu'];
//     bawuType = json['bawu_type'];
//     gender = json['gender'];
//     hasConcerned = json['has_concerned'];
//     fansNickname = json['fans_nickname'];
//     fansNum = json['fans_num'];
//     agreeNum = json['agree_num'];
//     threadNum = json['thread_num'];
//     godData = json['god_data'];
//     giftNum = json['gift_num'];
//     if (json['tb_vip'] != null) {
//       tbVip = new List<Null>();
//       json['tb_vip'].forEach((v) {
//         tbVip.add(new Null.fromJson(v));
//       });
//     }
//     pendant =
//         json['pendant'] != null ? new Pendant.fromJson(json['pendant']) : null;
//     alaInfo = json['ala_info'] != null
//         ? new AlaInfo.fromJson(json['ala_info'])
//         : null;
//     alaLiveInfo = json['ala_live_info'];
//     sealPrefix = json['seal_prefix'];
//     if (json['spring_virtual_user'] != null) {
//       springVirtualUser = new List<Null>();
//       json['spring_virtual_user'].forEach((v) {
//         springVirtualUser.add(new Null.fromJson(v));
//       });
//     }
//     esportData = json['esport_data'];
//     privSets = json['priv_sets'] != null
//         ? new PrivSets.fromJson(json['priv_sets'])
//         : null;
//     baijiahaoInfo = json['baijiahao_info'];
//     godInfo = json['god_info'];
//     bazhuGrade = json['bazhu_grade'];
//     newGodData = json['new_god_data'] != null
//         ? new NewGodData.fromJson(json['new_god_data'])
//         : null;
//     if (json['business_account_info'] != null) {
//       businessAccountInfo = new List<Null>();
//       json['business_account_info'].forEach((v) {
//         businessAccountInfo.add(new Null.fromJson(v));
//       });
//     }
//     displayAuthType = json['display_auth_type'];
//     workCreatorInfo = json['work_creator_info'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['name'] = this.name;
//     data['name_show'] = this.nameShow;
//     data['id'] = this.id;
//     data['type'] = this.type;
//     data['portrait'] = this.portrait;
//     data['level_id'] = this.levelId;
//     data['is_like'] = this.isLike;
//     if (this.iconinfo != null) {
//       data['iconinfo'] = this.iconinfo.map((v) => v.toJson()).toList();
//     }
//     if (this.tshowIcon != null) {
//       data['tshow_icon'] = this.tshowIcon.map((v) => v.toJson()).toList();
//     }
//     if (this.newTshowIcon != null) {
//       data['new_tshow_icon'] =
//           this.newTshowIcon.map((v) => v.toJson()).toList();
//     }
//     data['is_bawu'] = this.isBawu;
//     data['bawu_type'] = this.bawuType;
//     data['gender'] = this.gender;
//     data['has_concerned'] = this.hasConcerned;
//     data['fans_nickname'] = this.fansNickname;
//     data['fans_num'] = this.fansNum;
//     data['agree_num'] = this.agreeNum;
//     data['thread_num'] = this.threadNum;
//     data['god_data'] = this.godData;
//     data['gift_num'] = this.giftNum;
//     if (this.tbVip != null) {
//       data['tb_vip'] = this.tbVip.map((v) => v.toJson()).toList();
//     }
//     if (this.pendant != null) {
//       data['pendant'] = this.pendant.toJson();
//     }
//     if (this.alaInfo != null) {
//       data['ala_info'] = this.alaInfo.toJson();
//     }
//     data['ala_live_info'] = this.alaLiveInfo;
//     data['seal_prefix'] = this.sealPrefix;
//     if (this.springVirtualUser != null) {
//       data['spring_virtual_user'] =
//           this.springVirtualUser.map((v) => v.toJson()).toList();
//     }
//     data['esport_data'] = this.esportData;
//     if (this.privSets != null) {
//       data['priv_sets'] = this.privSets.toJson();
//     }
//     data['baijiahao_info'] = this.baijiahaoInfo;
//     data['god_info'] = this.godInfo;
//     data['bazhu_grade'] = this.bazhuGrade;
//     if (this.newGodData != null) {
//       data['new_god_data'] = this.newGodData.toJson();
//     }
//     if (this.businessAccountInfo != null) {
//       data['business_account_info'] =
//           this.businessAccountInfo.map((v) => v.toJson()).toList();
//     }
//     data['display_auth_type'] = this.displayAuthType;
//     data['work_creator_info'] = this.workCreatorInfo;
//     return data;
//   }
// }

// class Iconinfo {
//   String name;
//   String value;
//   String weight;
//   Terminal terminal;
//   Position position;
//   Sprite sprite;
//   String icon;

//   Iconinfo(
//       {this.name,
//       this.value,
//       this.weight,
//       this.terminal,
//       this.position,
//       this.sprite,
//       this.icon});

//   Iconinfo.fromJson(Map<String, dynamic> json) {
//     name = json['name'];
//     value = json['value'];
//     weight = json['weight'];
//     terminal = json['terminal'] != null
//         ? new Terminal.fromJson(json['terminal'])
//         : null;
//     position = json['position'] != null
//         ? new Position.fromJson(json['position'])
//         : null;
//     sprite =
//         json['sprite'] != null ? new Sprite.fromJson(json['sprite']) : null;
//     icon = json['icon'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['name'] = this.name;
//     data['value'] = this.value;
//     data['weight'] = this.weight;
//     if (this.terminal != null) {
//       data['terminal'] = this.terminal.toJson();
//     }
//     if (this.position != null) {
//       data['position'] = this.position.toJson();
//     }
//     if (this.sprite != null) {
//       data['sprite'] = this.sprite.toJson();
//     }
//     data['icon'] = this.icon;
//     return data;
//   }
// }

// class Terminal {
//   String pc;
//   String wap;
//   String client;

//   Terminal({this.pc, this.wap, this.client});

//   Terminal.fromJson(Map<String, dynamic> json) {
//     pc = json['pc'];
//     wap = json['wap'];
//     client = json['client'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['pc'] = this.pc;
//     data['wap'] = this.wap;
//     data['client'] = this.client;
//     return data;
//   }
// }

class Position {
  String? frs;
  String? pb;
  String? home;
  String? card;

  Position({this.frs, this.pb, this.home, this.card});

  Position.fromJson(Map<String, dynamic> json) {
    frs = json['frs'];
    pb = json['pb'];
    home = json['home'];
    card = json['card'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['frs'] = this.frs;
    data['pb'] = this.pb;
    data['home'] = this.home;
    data['card'] = this.card;
    return data;
  }
}

class Sprite {
  String? s1;
  String? s2;
  String? s3;
  String? s4;

  Sprite({this.s1, this.s2, this.s3, this.s4});

  Sprite.fromJson(Map<String, dynamic> json) {
    s1 = json['1'];
    s2 = json['2'];
    s3 = json['3'];
    s4 = json['4'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['1'] = this.s1;
    data['2'] = this.s2;
    data['3'] = this.s3;
    data['4'] = this.s4;
    return data;
  }
}

class TshowIcon {
  String? icon;
  String? name;
  String? url;

  TshowIcon({this.icon, this.name, this.url});

  TshowIcon.fromJson(Map<String, dynamic> json) {
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

class Pendant {
  String? propsId;
  String? imgUrl;

  Pendant({this.propsId, this.imgUrl});

  Pendant.fromJson(Map<String, dynamic> json) {
    propsId = json['props_id'];
    imgUrl = json['img_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['props_id'] = this.propsId;
    data['img_url'] = this.imgUrl;
    return data;
  }
}

class AlaInfo {
  String? anchorLive;
  String? location;
  String? showName;

  AlaInfo({this.anchorLive, this.location, this.showName});

  AlaInfo.fromJson(Map<String, dynamic> json) {
    anchorLive = json['anchor_live'];
    location = json['location'];
    showName = json['show_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['anchor_live'] = this.anchorLive;
    data['location'] = this.location;
    data['show_name'] = this.showName;
    return data;
  }
}

// class PrivSets {
//   String? like;
//   String? post;
//   String? reply;

//   PrivSets({this.like, this.post, this.reply});

//   PrivSets.fromJson(Map<String, dynamic> json) {
//     like = json['like'];
//     post = json['post'];
//     reply = json['reply'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['like'] = this.like;
//     data['post'] = this.post;
//     data['reply'] = this.reply;
//     return data;
//   }
// }

// class NewGodData {
//   String fieldId;

//   NewGodData({this.fieldId});

//   NewGodData.fromJson(Map<String, dynamic> json) {
//     fieldId = json['field_id'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['field_id'] = this.fieldId;
//     return data;
//   }
// }

class Topic {
  String? isLpost;
  String? link;

  Topic({this.isLpost, this.link});

  Topic.fromJson(Map<String, dynamic> json) {
    isLpost = json['is_lpost'];
    link = json['link'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_lpost'] = this.isLpost;
    data['link'] = this.link;
    return data;
  }
}

class Zan {
  String? num;
  String? lastTime;
  String? isLiked;

  Zan({this.num, this.lastTime, this.isLiked});

  Zan.fromJson(Map<String, dynamic> json) {
    num = json['num'];
    lastTime = json['last_time'];
    isLiked = json['is_liked'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['num'] = this.num;
    data['last_time'] = this.lastTime;
    data['is_liked'] = this.isLiked;
    return data;
  }
}

// class TwzhiboInfo {
//   String isCopytwzhibo;
//   User user;

//   TwzhiboInfo({this.isCopytwzhibo, this.user});

//   TwzhiboInfo.fromJson(Map<String, dynamic> json) {
//     isCopytwzhibo = json['is_copytwzhibo'];
//     user = json['user'] != null ? new User.fromJson(json['user']) : null;
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['is_copytwzhibo'] = this.isCopytwzhibo;
//     if (this.user != null) {
//       data['user'] = this.user.toJson();
//     }
//     return data;
//   }
// }

// class User {
//   TwAnchorInfo twAnchorInfo;

//   User({this.twAnchorInfo});

//   User.fromJson(Map<String, dynamic> json) {
//     twAnchorInfo = json['tw_anchor_info'] != null
//         ? new TwAnchorInfo.fromJson(json['tw_anchor_info'])
//         : null;
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.twAnchorInfo != null) {
//       data['tw_anchor_info'] = this.twAnchorInfo.toJson();
//     }
//     return data;
//   }
// }

// class TwAnchorInfo {
//   String anchorLevel;
//   String inBlackList;
//   String setCover;
//   String callerMsg;
//   String follow;
//   String guide;
//   String newfloor;
//   String fansNum;
//   String monthUpdateDays;
//   String giftsNum;

//   TwAnchorInfo(
//       {this.anchorLevel,
//       this.inBlackList,
//       this.setCover,
//       this.callerMsg,
//       this.follow,
//       this.guide,
//       this.newfloor,
//       this.fansNum,
//       this.monthUpdateDays,
//       this.giftsNum});

//   TwAnchorInfo.fromJson(Map<String, dynamic> json) {
//     anchorLevel = json['anchor_level'];
//     inBlackList = json['in_black_list'];
//     setCover = json['set_cover'];
//     callerMsg = json['caller_msg'];
//     follow = json['follow'];
//     guide = json['guide'];
//     newfloor = json['newfloor'];
//     fansNum = json['fans_num'];
//     monthUpdateDays = json['month_update_days'];
//     giftsNum = json['gifts_num'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['anchor_level'] = this.anchorLevel;
//     data['in_black_list'] = this.inBlackList;
//     data['set_cover'] = this.setCover;
//     data['caller_msg'] = this.callerMsg;
//     data['follow'] = this.follow;
//     data['guide'] = this.guide;
//     data['newfloor'] = this.newfloor;
//     data['fans_num'] = this.fansNum;
//     data['month_update_days'] = this.monthUpdateDays;
//     data['gifts_num'] = this.giftsNum;
//     return data;
//   }
// }

// class UserList {
//   String id;
//   String portrait;
//   String name;
//   String nameShow;
//   List<Iconinfo> iconinfo;
//   List<TshowIcon> tshowIcon;
//   List<NewTshowIcon> newTshowIcon;
//   String levelId;
//   String isBawu;
//   String bawuType;
//   String gender;
//   String hasConcerned;
//   String fansNickname;
//   String fansNum;
//   PrivSets privSets;
//   String agreeNum;
//   String threadNum;
//   String godData;
//   String isMem;
//   String giftNum;
//   List<Null> tbVip;
//   AlaInfo alaInfo;
//   Pendant pendant;
//   String sealPrefix;
//   List<Null> springVirtualUser;
//   String baijiahaoInfo;
//   String bazhuGrade;
//   NewGodData newGodData;
//   List<Null> businessAccountInfo;
//   String displayAuthType;
//   String workCreatorInfo;

//   UserList(
//       {this.id,
//       this.portrait,
//       this.name,
//       this.nameShow,
//       this.iconinfo,
//       this.tshowIcon,
//       this.newTshowIcon,
//       this.levelId,
//       this.isBawu,
//       this.bawuType,
//       this.gender,
//       this.hasConcerned,
//       this.fansNickname,
//       this.fansNum,
//       this.privSets,
//       this.agreeNum,
//       this.threadNum,
//       this.godData,
//       this.isMem,
//       this.giftNum,
//       this.tbVip,
//       this.alaInfo,
//       this.pendant,
//       this.sealPrefix,
//       this.springVirtualUser,
//       this.baijiahaoInfo,
//       this.bazhuGrade,
//       this.newGodData,
//       this.businessAccountInfo,
//       this.displayAuthType,
//       this.workCreatorInfo});

//   UserList.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     portrait = json['portrait'];
//     name = json['name'];
//     nameShow = json['name_show'];
//     if (json['iconinfo'] != null) {
//       iconinfo = new List<Iconinfo>();
//       json['iconinfo'].forEach((v) {
//         iconinfo.add(new Iconinfo.fromJson(v));
//       });
//     }
//     if (json['tshow_icon'] != null) {
//       tshowIcon = new List<TshowIcon>();
//       json['tshow_icon'].forEach((v) {
//         tshowIcon.add(new TshowIcon.fromJson(v));
//       });
//     }
//     if (json['new_tshow_icon'] != null) {
//       newTshowIcon = new List<NewTshowIcon>();
//       json['new_tshow_icon'].forEach((v) {
//         newTshowIcon.add(new NewTshowIcon.fromJson(v));
//       });
//     }
//     levelId = json['level_id'];
//     isBawu = json['is_bawu'];
//     bawuType = json['bawu_type'];
//     gender = json['gender'];
//     hasConcerned = json['has_concerned'];
//     fansNickname = json['fans_nickname'];
//     fansNum = json['fans_num'];
//     privSets = json['priv_sets'] != null
//         ? new PrivSets.fromJson(json['priv_sets'])
//         : null;
//     agreeNum = json['agree_num'];
//     threadNum = json['thread_num'];
//     godData = json['god_data'];
//     isMem = json['is_mem'];
//     giftNum = json['gift_num'];
//     if (json['tb_vip'] != null) {
//       tbVip = new List<Null>();
//       json['tb_vip'].forEach((v) {
//         tbVip.add(new Null.fromJson(v));
//       });
//     }
//     alaInfo = json['ala_info'] != null
//         ? new AlaInfo.fromJson(json['ala_info'])
//         : null;
//     pendant =
//         json['pendant'] != null ? new Pendant.fromJson(json['pendant']) : null;
//     sealPrefix = json['seal_prefix'];
//     if (json['spring_virtual_user'] != null) {
//       springVirtualUser = new List<Null>();
//       json['spring_virtual_user'].forEach((v) {
//         springVirtualUser.add(new Null.fromJson(v));
//       });
//     }
//     baijiahaoInfo = json['baijiahao_info'];
//     bazhuGrade = json['bazhu_grade'];
//     newGodData = json['new_god_data'] != null
//         ? new NewGodData.fromJson(json['new_god_data'])
//         : null;
//     if (json['business_account_info'] != null) {
//       businessAccountInfo = new List<Null>();
//       json['business_account_info'].forEach((v) {
//         businessAccountInfo.add(new Null.fromJson(v));
//       });
//     }
//     displayAuthType = json['display_auth_type'];
//     workCreatorInfo = json['work_creator_info'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['portrait'] = this.portrait;
//     data['name'] = this.name;
//     data['name_show'] = this.nameShow;
//     if (this.iconinfo != null) {
//       data['iconinfo'] = this.iconinfo.map((v) => v.toJson()).toList();
//     }
//     if (this.tshowIcon != null) {
//       data['tshow_icon'] = this.tshowIcon.map((v) => v.toJson()).toList();
//     }
//     if (this.newTshowIcon != null) {
//       data['new_tshow_icon'] =
//           this.newTshowIcon.map((v) => v.toJson()).toList();
//     }
//     data['level_id'] = this.levelId;
//     data['is_bawu'] = this.isBawu;
//     data['bawu_type'] = this.bawuType;
//     data['gender'] = this.gender;
//     data['has_concerned'] = this.hasConcerned;
//     data['fans_nickname'] = this.fansNickname;
//     data['fans_num'] = this.fansNum;
//     if (this.privSets != null) {
//       data['priv_sets'] = this.privSets.toJson();
//     }
//     data['agree_num'] = this.agreeNum;
//     data['thread_num'] = this.threadNum;
//     data['god_data'] = this.godData;
//     data['is_mem'] = this.isMem;
//     data['gift_num'] = this.giftNum;
//     if (this.tbVip != null) {
//       data['tb_vip'] = this.tbVip.map((v) => v.toJson()).toList();
//     }
//     if (this.alaInfo != null) {
//       data['ala_info'] = this.alaInfo.toJson();
//     }
//     if (this.pendant != null) {
//       data['pendant'] = this.pendant.toJson();
//     }
//     data['seal_prefix'] = this.sealPrefix;
//     if (this.springVirtualUser != null) {
//       data['spring_virtual_user'] =
//           this.springVirtualUser.map((v) => v.toJson()).toList();
//     }
//     data['baijiahao_info'] = this.baijiahaoInfo;
//     data['bazhu_grade'] = this.bazhuGrade;
//     if (this.newGodData != null) {
//       data['new_god_data'] = this.newGodData.toJson();
//     }
//     if (this.businessAccountInfo != null) {
//       data['business_account_info'] =
//           this.businessAccountInfo.map((v) => v.toJson()).toList();
//     }
//     data['display_auth_type'] = this.displayAuthType;
//     data['work_creator_info'] = this.workCreatorInfo;
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

// class PrivSets {
//   String like;
//   String post;
//   String reply;
//   String group;
//   String live;
//   String location;

//   PrivSets(
//       {this.like, this.post, this.reply, this.group, this.live, this.location});

//   PrivSets.fromJson(Map<String, dynamic> json) {
//     like = json['like'];
//     post = json['post'];
//     reply = json['reply'];
//     group = json['group'];
//     live = json['live'];
//     location = json['location'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['like'] = this.like;
//     data['post'] = this.post;
//     data['reply'] = this.reply;
//     data['group'] = this.group;
//     data['live'] = this.live;
//     data['location'] = this.location;
//     return data;
//   }
// }

// class BusinessPromotInfo {
//   String isPromot;
//   String isHeadlinepost;
//   String isSCard;
//   List<Null> sendCardInfo;

//   BusinessPromotInfo(
//       {this.isPromot, this.isHeadlinepost, this.isSCard, this.sendCardInfo});

//   BusinessPromotInfo.fromJson(Map<String, dynamic> json) {
//     isPromot = json['is_promot'];
//     isHeadlinepost = json['is_headlinepost'];
//     isSCard = json['is_s_card'];
//     if (json['send_card_info'] != null) {
//       sendCardInfo = new List<Null>();
//       json['send_card_info'].forEach((v) {
//         sendCardInfo.add(new Null.fromJson(v));
//       });
//     }
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['is_promot'] = this.isPromot;
//     data['is_headlinepost'] = this.isHeadlinepost;
//     data['is_s_card'] = this.isSCard;
//     if (this.sendCardInfo != null) {
//       data['send_card_info'] =
//           this.sendCardInfo.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }

// class TwzhiboAnti {
//   String canAddLivePost;
//   String canDelLivePost;

//   TwzhiboAnti({this.canAddLivePost, this.canDelLivePost});

//   TwzhiboAnti.fromJson(Map<String, dynamic> json) {
//     canAddLivePost = json['can_add_live_post'];
//     canDelLivePost = json['can_del_live_post'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['can_add_live_post'] = this.canAddLivePost;
//     data['can_del_live_post'] = this.canDelLivePost;
//     return data;
//   }
// }

// class BannerList {
//   List<Null> app;
//   List<Null> pbBannerAd;
//   List<Null> videoRecommendAd;

//   BannerList({this.app, this.pbBannerAd, this.videoRecommendAd});

//   BannerList.fromJson(Map<String, dynamic> json) {
//     if (json['app'] != null) {
//       app = new List<Null>();
//       json['app'].forEach((v) {
//         app.add(new Null.fromJson(v));
//       });
//     }
//     if (json['pb_banner_ad'] != null) {
//       pbBannerAd = new List<Null>();
//       json['pb_banner_ad'].forEach((v) {
//         pbBannerAd.add(new Null.fromJson(v));
//       });
//     }
//     if (json['video_recommend_ad'] != null) {
//       videoRecommendAd = new List<Null>();
//       json['video_recommend_ad'].forEach((v) {
//         videoRecommendAd.add(new Null.fromJson(v));
//       });
//     }
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.app != null) {
//       data['app'] = this.app.map((v) => v.toJson()).toList();
//     }
//     if (this.pbBannerAd != null) {
//       data['pb_banner_ad'] = this.pbBannerAd.map((v) => v.toJson()).toList();
//     }
//     if (this.videoRecommendAd != null) {
//       data['video_recommend_ad'] =
//           this.videoRecommendAd.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }

class PbSortInfo {
  String? sortName;
  String? sortType;

  PbSortInfo({this.sortName, this.sortType});

  PbSortInfo.fromJson(Map<String, dynamic> json) {
    sortName = json['sort_name'];
    sortType = json['sort_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sort_name'] = this.sortName;
    data['sort_type'] = this.sortType;
    return data;
  }
}

class SubPostList {
  String? id;
  List<Content>? content;
  String? time;
  String? ptype;
  String? floor;
  String? title;
  String? isVoice;
  String? authorId;

  SubPostList(
      {this.id,
      this.content,
      this.time,
      this.ptype,
      this.floor,
      this.title,
      this.isVoice,
      this.authorId});

  SubPostList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    if (json['content'] != null) {
      content = [];
      json['content'].forEach((v) {
        content?.add(new Content.fromJson(v));
      });
    }
    time = json['time'];
    ptype = json['ptype'];
    floor = json['floor'];
    title = json['title'];
    isVoice = json['is_voice'];
    authorId = json['author_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    if (this.content != null) {
      data['content'] = this.content?.map((v) => v.toJson()).toList();
    }
    data['time'] = this.time;
    data['ptype'] = this.ptype;
    data['floor'] = this.floor;
    data['title'] = this.title;
    data['is_voice'] = this.isVoice;
    data['author_id'] = this.authorId;
    return data;
  }
}

//可能是地理位置
class LbsInfo {
  String? name;

  LbsInfo({this.name});

  LbsInfo.fromJson(Map<String, dynamic> json) {
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    return data;
  }
}
