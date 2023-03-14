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
  String? ctime;
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
    hasFloor = json['has_floor'].toString();
    isNewUrl = json['is_new_url'].toString();
    if (json['news_info'] != null) {
      newsInfo = [];
      json['news_info'].forEach((v) {
        newsInfo?.add(v);
      });
    }
    forum = json['forum'] != null ? Forum.fromJson(json['forum']) : null;
    displayForum = json['display_forum'] != null
        ? DisplayForum.fromJson(json['display_forum'])
        : null;
    user = json['user'] != null ? ThreadUser.fromJson(json['user']) : null;
    anti = json['anti'] != null ? Anti.fromJson(json['anti']) : null;
    page = json['page'] != null ? ThreadPage.fromJson(json['page']) : null;
    if (json['post_list'] != null) {
      postList = [];
      json['post_list'].forEach((v) {
        postList?.add(PostList.fromJson(v));
      });
    }
    thread = json['thread'] != null ? Thread.fromJson(json['thread']) : null;
    if (json['ala_info'] != null) {
      alaInfo = [];
      json['ala_info'].forEach((v) {
        alaInfo?.add(v);
      });
    }
    if (json['user_list'] != null) {
      userList = [];
      json['user_list'].forEach((v) {
        userList?.add(UserList.fromJson(v));
      });
    }
    // businessPromotInfo = json['business_promot_info'] != null
    //     ? new BusinessPromotInfo.fromJson(json['business_promot_info'])
    //     : null;
    switchReadOpen = json['switch_read_open'].toString();
    isOfficialForum = json['is_official_forum'].toString();
    isPurchase = json['is_purchase'].toString();
    // twzhiboAnti = json['twzhibo_anti'] != null
    //     ? new TwzhiboAnti.fromJson(json['twzhibo_anti'])
    //     : null;
    if (json['sample_sids_temp'] != null) {
      sampleSidsTemp = [];
      json['sample_sids_temp'].forEach((v) {
        sampleSidsTemp?.add(v);
      });
    }
    showAdsense = json['show_adsense'].toString();
    isBlackWhite = json['is_black_white'].toString();
    bannerList = json['banner_list'] != null
        ? BannerList.fromJson(json['banner_list'])
        : null;
    hasFoldComment = json['has_fold_comment'].toString();
    partialVisibleToast = json['partial_visible_toast'];
    foldTip = json['fold_tip'];
    sortType = json['sort_type'].toString();
    if (json['pb_sort_info'] != null) {
      pbSortInfo = [];
      json['pb_sort_info'].forEach((v) {
        pbSortInfo?.add(PbSortInfo.fromJson(v));
      });
    }
    serverTime = json['server_time'].toString();
    time = (json['time'] as num).toInt();
    ctime = json['ctime'].toString();
    logid = int.tryParse(json['logid']);
    errorCode = json['error_code'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['has_floor'] = hasFloor;
    data['is_new_url'] = isNewUrl;
    if (newsInfo != null) {
      data['news_info'] = newsInfo?.map((v) => v.toJson()).toList();
    }
    if (forum != null) {
      data['forum'] = forum?.toJson();
    }
    if (displayForum != null) {
      data['display_forum'] = displayForum?.toJson();
    }
    if (user != null) {
      data['user'] = user?.toJson();
    }
    if (anti != null) {
      data['anti'] = anti?.toJson();
    }
    if (page != null) {
      data['page'] = page?.toJson();
    }
    if (postList != null) {
      data['post_list'] = postList?.map((v) => v.toJson()).toList();
    }
    if (thread != null) {
      data['thread'] = thread?.toJson();
    }
    if (alaInfo != null) {
      data['ala_info'] = alaInfo?.map((v) => v.toJson()).toList();
    }
    if (userList != null) {
      data['user_list'] = userList?.map((v) => v.toJson()).toList();
    }
    // if (this.businessPromotInfo != null) {
    //   data['business_promot_info'] = this.businessPromotInfo.toJson();
    // }
    data['switch_read_open'] = switchReadOpen;
    data['is_official_forum'] = isOfficialForum;
    data['is_purchase'] = isPurchase;
    // if (this.twzhiboAnti != null) {
    //   data['twzhibo_anti'] = this.twzhiboAnti.toJson();
    // }
    if (sampleSidsTemp != null) {
      data['sample_sids_temp'] =
          sampleSidsTemp?.map((v) => v.toJson()).toList();
    }
    data['show_adsense'] = showAdsense;
    data['is_black_white'] = isBlackWhite;
    if (bannerList != null) {
      data['banner_list'] = bannerList?.toJson();
    }
    data['has_fold_comment'] = hasFoldComment;
    data['partial_visible_toast'] = partialVisibleToast;
    data['fold_tip'] = foldTip;
    data['sort_type'] = sortType;
    if (pbSortInfo != null) {
      data['pb_sort_info'] = pbSortInfo?.map((v) => v.toJson()).toList();
    }
    data['server_time'] = serverTime;
    data['time'] = time;
    data['ctime'] = ctime;
    data['logid'] = logid;
    data['error_code'] = errorCode;
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
    id = json['id'].toString();
    name = json['name'];
    isExists = json['is_exists'].toString();
    avatar = json['avatar'];
    firstClass = json['first_class'];
    secondClass = json['second_class'];
    isLiked = json['is_liked'].toString();
    isBrandForum = json['is_brand_forum'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['is_exists'] = isExists;
    data['avatar'] = avatar;
    data['first_class'] = firstClass;
    data['second_class'] = secondClass;
    data['is_liked'] = isLiked;
    data['is_brand_forum'] = isBrandForum;
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
    isManager = json['is_manager'].toString();
    bimgEndTime = json['bimg_end_time'].toString();
    isSelectTail = json['is_select_tail'].toString();
    muteUser = json['mute_user'];
    leftCallNum = json['left_call_num'].toString();
    // callFansInfo = json['call_fans_info'] != null
    //     ? new CallFansInfo.fromJson(json['call_fans_info'])
    //     : null;
    forumToolAuth = json['forum_tool_auth'];
    showPbPrivateFlag = json['show_pb_private_flag'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_manager'] = isManager;
    data['bimg_end_time'] = bimgEndTime;
    data['is_select_tail'] = isSelectTail;
    data['mute_user'] = muteUser;
    data['left_call_num'] = leftCallNum;
    // if (this.callFansInfo != null) {
    //   data['call_fans_info'] = this.callFansInfo?.toJson();
    // }
    data['forum_tool_auth'] = forumToolAuth;
    data['show_pb_private_flag'] = showPbPrivateFlag;
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
    reqNum = json['req_num'].toString();
    pageSize = json['page_size'].toString();
    offset = json['offset'].toString();
    currentPage = json['current_page'].toString();
    totalPage = json['total_page'].toString();
    totalNum = json['total_num'].toString();
    pnum = json['pnum'].toString();
    tnum = json['tnum'].toString();
    newTotalPage = json['new_total_page'].toString();
    hasMore = json['has_more'].toString();
    hasPrev = json['has_prev'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['req_num'] = reqNum;
    data['page_size'] = pageSize;
    data['offset'] = offset;
    data['current_page'] = currentPage;
    data['total_page'] = totalPage;
    data['total_num'] = totalNum;
    data['pnum'] = pnum;
    data['tnum'] = tnum;
    data['new_total_page'] = newTotalPage;
    data['has_more'] = hasMore;
    data['has_prev'] = hasPrev;
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
  // String? outerItem;
  String? itemStar;
  // String? advertisement;
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
      // this.outerItem,
      this.itemStar,
      // this.advertisement,
      this.foldCommentStatus,
      this.foldCommentApplyUrl,
      this.novelInfo,
      this.authorId,
      this.foldTip});

  PostList.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    title = json['title'];
    floor = json['floor'].toString();
    time = json['time'].toString();
    if (json['content'] != null) {
      content = [];
      json['content'].forEach((v) {
        content?.add(Content.fromJson(v));
      });
    }
    subPostNumber = json['sub_post_number'].toString();
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
    hasSignature = json['has_signature'].toString();
    if (json['signature'] != null) {
      if (json['signature'] is Map) {
        signature = json['signature'] != null
            ? Signature.fromJson(json['signature'])
            : null;
      } else if (json['signature'] is List) {
        if (json['signature'].length == 0) {
          signature = null;
        }
      } else {
        throw Exception("未知数据类型");
      }
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
    agree = json['agree'] != null ? Agree.fromJson(json['agree']) : null;
    fromForum = json['from_forum'];
    isPostVisible = json['is_post_visible'].toString();
    isFirstFloor = json['is_first_floor'].toString();
    needLog = json['need_log'].toString();
    isFold = json['is_fold'].toString();
    isTopAgreePost = json['is_top_agree_post'].toString();
    showSquared = json['show_squared'].toString();
    isWonderfulPost = json['is_wonderful_post'].toString();
    item = json['item'];
    // outerItem = json['outer_item'];
    itemStar = json['item_star'];
    // advertisement = json['advertisement'];
    foldCommentStatus = json['fold_comment_status'];
    foldCommentApplyUrl = json['fold_comment_apply_url'];
    novelInfo = json['novel_info'];
    authorId = json['author_id'].toString();
    foldTip = json['fold_tip'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['floor'] = floor;
    data['time'] = time;
    if (content != null) {
      data['content'] = content?.map((v) => v.toJson()).toList();
    }
    data['sub_post_number'] = subPostNumber;
    if (subPostList != null) {
      data['sub_post_list'] = subPostList?.map((v) => v.toJson()).toList();
    }
    data['bimg_url'] = bimgUrl;
    data['ios_bimg_format'] = iosBimgFormat;
    data['add_post_list'] = addPostList;
    data['has_signature'] = hasSignature;
    if (signature != null) {
      data['signature'] = signature?.toJson();
    }
    // if (this.tailInfo != null) {
    //   // data['tail_info'] = this.tailInfo?.map((v) => v.toJson()).toList();
    // }
    if (lbsInfo != null) {
      data['lbs_info'] = lbsInfo!.toJson();
    }
    data['zan'] = zan;
    data['is_giftpost'] = isGiftpost;
    data['tpoint_post'] = tpointPost;
    data['act_post'] = actPost;
    data['present'] = present;
    data['ext_tails'] = extTails;
    data['pb_deal_info'] = pbDealInfo;
    data['skin_info'] = skinInfo;
    if (agree != null) {
      data['agree'] = agree?.toJson();
    }
    data['from_forum'] = fromForum;
    data['is_post_visible'] = isPostVisible;
    data['is_first_floor'] = isFirstFloor;
    data['need_log'] = needLog;
    data['is_fold'] = isFold;
    data['is_top_agree_post'] = isTopAgreePost;
    data['show_squared'] = showSquared;
    data['is_wonderful_post'] = isWonderfulPost;
    data['item'] = item;
    // data['outer_item'] = outerItem;
    data['item_star'] = itemStar;
    // data['advertisement'] = this.advertisement;
    data['fold_comment_status'] = foldCommentStatus;
    data['fold_comment_apply_url'] = foldCommentApplyUrl;
    data['novel_info'] = novelInfo;
    data['author_id'] = authorId;
    data['fold_tip'] = foldTip;
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
  String? link;
  String? duringTime;
  String? isSub;
  String? voiceMd5;
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
      this.uname,
      this.link,
      this.duringTime,
      this.isSub,
      this.voiceMd5});

  Content.fromJson(Map<String, dynamic> json) {
    uid = json["uid"].toString();
    uname = json["uid"].toString();
    type = json['type'].toString();
    bsize = json['bsize'].toString();
    size = json['size'].toString();
    originSrc = json['origin_src'];
    originSize = json['origin_size'].toString();
    isLongPic = json['is_long_pic'].toString();
    showOriginalBtn = json['show_original_btn'].toString();
    cdnSrc = json['cdn_src'];
    cdnSrcActive = json['cdn_src_active'];
    bigCdnSrc = json['big_cdn_src'];
    isNativeApp = json['is_native_app'].toString();
    if (json['native_app'] != null) {
      nativeApp = [];
      if (json['native_app'] is Map) {
        json['native_app'].forEach((k, v) {
          nativeApp?.add({k: v});
        });
      } else if (json['native_app'] is List) {
        json['native_app'].forEach((v) {
          nativeApp?.add(v);
        });
      } else {
        throw Exception("未知类型");
      }
    }
    text = json['text'];
    c = json['c'];
    link = json['link'];
    duringTime = json['during_time'];
    isSub = json['is_sub'];
    voiceMd5 = json['voice_md5'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['bsize'] = bsize;
    data['size'] = size;
    data['origin_src'] = originSrc;
    data['origin_size'] = originSize;
    data['is_long_pic'] = isLongPic;
    data['show_original_btn'] = showOriginalBtn;
    data['cdn_src'] = cdnSrc;
    data['cdn_src_active'] = cdnSrcActive;
    data['big_cdn_src'] = bigCdnSrc;
    data['is_native_app'] = isNativeApp;
    data["uid"] = uid;
    data["uname"] = uname;
    if (nativeApp != null) {
      // data['native_app'] = this.nativeApp.map((v) => v.toJson()).toList();
    }
    data['text'] = text;
    data['c'] = c;
    data['link'] = link;
    data['during_time'] = duringTime;
    data['is_sub'] = isSub;
    data['voice_md5'] = voiceMd5;
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
        content?.add(Content.fromJson(v));
      });
    }
    signatureId = json['signature_id'].toString();
    fontKeyName = json['fontKeyName'];
    fontColor = json['fontColor'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (content != null) {
      data['content'] = content?.map((v) => v.toJson()).toList();
    }
    data['signature_id'] = signatureId;
    data['fontKeyName'] = fontKeyName;
    data['fontColor'] = fontColor;
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
  // OriginThreadInfo? originThreadInfo;
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
  // String? worksInfo;
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
      // this.originThreadInfo,
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
      // this.worksInfo,
      this.collectNum,
      this.isFrsMask,
      this.isPartialVisible});

  Thread.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    title = json['title'];
    replyNum = json['reply_num'].toString();
    collectStatus = json['collect_status'].toString();
    collectMarkPid = json['collect_mark_pid'].toString();
    author = json['author'] != null ? Author.fromJson(json['author']) : null;
    isGood = json['is_good'].toString();
    isTop = json['is_top'].toString();
    topic = json['topic'] != null ? Topic.fromJson(json['topic']) : null;
    zan = json['zan'] != null ? Zan.fromJson(json['zan']) : null;
    postId = json['post_id'].toString();
    createTime = json['create_time'].toString();
    isNtitle = json['is_ntitle'].toString();
    if (json['location'] != null) {
      location = [];
      json['location'].forEach((v) {
        location?.add(v);
      });
    }
    actInfo = json['act_info'];
    isActivity = json['is_activity'].toString();
    lastTimeInt = json['last_time_int'].toString();
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
    threadType = json['thread_type'].toString();
    taskInfo = json['task_info'];
    jid = json['jid'].toString();
    categoryName = json['category_name'];
    yulePostActivity = json['yule_post_activity'];
    extTails = json['ext_tails'];
    pushStatus = json['push_status'];
    cartoonInfo = json['cartoon_info'];
    // originThreadInfo = json['origin_thread_info'] != null
    //     ? new OriginThreadInfo.fromJson(json['origin_thread_info'])
    //     : null;
    isShareThread = json['is_share_thread'].toString();
    richAbstract = json['rich_abstract'];
    declareList = json['declare_list'];
    agree = json['agree'] != null ? Agree.fromJson(json['agree']) : null;
    isMultiforumThread = json['is_multiforum_thread'].toString();
    isLinkThread = json['is_link_thread'].toString();
    linkInfo = json['link_info'];
    shareNum = json['share_num'].toString();
    isCalled = json['is_called'].toString();
    swanInfo = json['swan_info'];
    noSmartPb = json['no_smart_pb'];
    tShareImg = json['t_share_img'];
    isBazhuApply = json['is_bazhu_apply'].toString();
    threadShareLink = json['thread_share_link'];
    nid = json['nid'].toString();
    pbLinkInfo = json['pb_link_info'];
    pbGoodsInfo = json['pb_goods_info'];
    // worksInfo = json['works_info'];
    collectNum = json['collect_num'].toString();
    isFrsMask = json['is_frs_mask'].toString();
    isPartialVisible = json['is_partial_visible'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['reply_num'] = replyNum;
    data['collect_status'] = collectStatus;
    data['collect_mark_pid'] = collectMarkPid;
    if (author != null) {
      data['author'] = author?.toJson();
    }
    data['is_good'] = isGood;
    data['is_top'] = isTop;
    if (topic != null) {
      data['topic'] = topic?.toJson();
    }
    if (zan != null) {
      data['zan'] = zan?.toJson();
    }
    data['post_id'] = postId;
    data['create_time'] = createTime;
    data['is_ntitle'] = isNtitle;
    if (location != null) {
      data['location'] = location?.map((v) => v.toJson()).toList();
    }
    data['act_info'] = actInfo;
    data['is_activity'] = isActivity;
    data['last_time_int'] = lastTimeInt;
    data['storecount'] = storecount;
    data['livecover_src'] = livecoverSrc;
    // if (this.twzhiboInfo != null) {
    //   data['twzhibo_info'] = this.twzhiboInfo?.toJson();
    // }
    data['poll_info'] = pollInfo;
    data['video_info'] = videoInfo;
    data['video_channel_info'] = videoChannelInfo;
    data['thread_type'] = threadType;
    data['task_info'] = taskInfo;
    data['jid'] = jid;
    data['category_name'] = categoryName;
    data['yule_post_activity'] = yulePostActivity;
    data['ext_tails'] = extTails;
    data['push_status'] = pushStatus;
    data['cartoon_info'] = cartoonInfo;
    data['rich_title'] = richTitle;
    // if (this.originThreadInfo != null) {
    //   data['origin_thread_info'] = this.originThreadInfo?.toJson();
    // }
    data['is_share_thread'] = isShareThread;
    data['rich_abstract'] = richAbstract;
    data['declare_list'] = declareList;
    if (agree != null) {
      data['agree'] = agree?.toJson();
    }
    data['is_multiforum_thread'] = isMultiforumThread;
    data['is_link_thread'] = isLinkThread;
    data['link_info'] = linkInfo;
    data['share_num'] = shareNum;
    data['is_called'] = isCalled;
    data['swan_info'] = swanInfo;
    data['no_smart_pb'] = noSmartPb;
    data['t_share_img'] = tShareImg;
    data['is_bazhu_apply'] = isBazhuApply;
    data['thread_share_link'] = threadShareLink;
    data['nid'] = nid;
    data['pb_link_info'] = pbLinkInfo;
    data['pb_goods_info'] = pbGoodsInfo;
    // data['works_info'] = worksInfo;
    data['collect_num'] = collectNum;
    data['is_frs_mask'] = isFrsMask;
    data['is_partial_visible'] = isPartialVisible;
    return data;
  }
}

class OriginThreadInfo {
  String? title;
  List<Media>? media;
  List<Abstract>? abstract;
  String? fname;
  String? tid;
  AlaInfo? alaInfo;
  String? fid;
  String? threadType;
  String? isDeleted;
  String? isBlocked;
  String? isUcg;
  // OriUgcInfo? oriUgcInfo;
  String? voiceInfo;
  String? videoInfo;
  // PollInfo? pollInfo;
  List<Content>? content;
  String? isNewStyle;
  Agree? agree;
  String? replyNum;
  Author? author;
  String? sharedNum;
  String? itemId;
  // Item? item;
  String? itemStar;
  String? pbLinkInfo;
  String? isFrsMask;
  String? richTitle;

  OriginThreadInfo(
      {this.title,
      this.media,
      this.abstract,
      this.fname,
      this.tid,
      this.alaInfo,
      this.fid,
      this.threadType,
      this.isDeleted,
      this.isBlocked,
      this.isUcg,
      // this.oriUgcInfo,
      this.voiceInfo,
      this.videoInfo,
      // this.pollInfo,
      this.content,
      this.isNewStyle,
      this.agree,
      this.replyNum,
      this.author,
      this.sharedNum,
      this.itemId,
      // this.item,
      this.itemStar,
      this.pbLinkInfo,
      this.isFrsMask,
      this.richTitle});

  OriginThreadInfo.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    if (json['media'] != null) {
      media = [];
      json['media'].forEach((v) {
        media?.add(Media.fromJson(v));
      });
    }
    if (json['abstract'] != null) {
      abstract = [];
      json['abstract'].forEach((v) {
        abstract?.add(Abstract.fromJson(v));
      });
    }
    fname = json['fname'];
    tid = json['tid'];
    alaInfo =
        json['ala_info'] != null ? AlaInfo.fromJson(json['ala_info']) : null;
    fid = json['fid'];
    threadType = json['thread_type'];
    isDeleted = json['is_deleted'];
    isBlocked = json['is_blocked'];
    isUcg = json['is_ucg'];
    // oriUgcInfo = json['ori_ugc_info'] != null
    //     ? new OriUgcInfo.fromJson(json['ori_ugc_info'])
    //     : null;
    voiceInfo = json['voice_info'];
    videoInfo = json['video_info'];
    // pollInfo = json['poll_info'] != null
    //     ? new PollInfo.fromJson(json['poll_info'])
    //     : null;
    if (json['content'] != null) {
      content = [];
      json['content'].forEach((v) {
        content?.add(Content.fromJson(v));
      });
    }
    isNewStyle = json['is_new_style'];
    agree = json['agree'] != null ? Agree.fromJson(json['agree']) : null;
    replyNum = json['reply_num'];
    author = json['author'] != null ? Author.fromJson(json['author']) : null;
    sharedNum = json['shared_num'];
    itemId = json['item_id'];
    // item = json['item'] != null ? new Item.fromJson(json['item']) : null;
    itemStar = json['item_star'];
    pbLinkInfo = json['pb_link_info'];
    isFrsMask = json['is_frs_mask'];
    richTitle = json['rich_title'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    if (media != null) {
      data['media'] = media?.map((v) => v.toJson()).toList();
    }
    if (abstract != null) {
      data['abstract'] = abstract?.map((v) => v.toJson()).toList();
    }
    data['fname'] = fname;
    data['tid'] = tid;
    if (alaInfo != null) {
      data['ala_info'] = alaInfo?.toJson();
    }
    data['fid'] = fid;
    data['thread_type'] = threadType;
    data['is_deleted'] = isDeleted;
    data['is_blocked'] = isBlocked;
    data['is_ucg'] = isUcg;
    // if (this.oriUgcInfo != null) {
    //   data['ori_ugc_info'] = this.oriUgcInfo.toJson();
    // }
    data['voice_info'] = voiceInfo;
    data['video_info'] = videoInfo;
    // if (this.pollInfo != null) {
    //   data['poll_info'] = this.pollInfo.toJson();
    // }
    if (content != null) {
      data['content'] = content?.map((v) => v.toJson()).toList();
    }
    data['is_new_style'] = isNewStyle;
    if (agree != null) {
      data['agree'] = agree?.toJson();
    }
    data['reply_num'] = replyNum;
    if (author != null) {
      data['author'] = author?.toJson();
    }
    data['shared_num'] = sharedNum;
    data['item_id'] = itemId;
    // if (this.item != null) {
    //   data['item'] = this.item.toJson();
    // }
    data['item_star'] = itemStar;
    data['pb_link_info'] = pbLinkInfo;
    data['is_frs_mask'] = isFrsMask;
    data['rich_title'] = richTitle;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['frs'] = frs;
    data['pb'] = pb;
    data['home'] = home;
    data['card'] = card;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['1'] = s1;
    data['2'] = s2;
    data['3'] = s3;
    data['4'] = s4;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['icon'] = icon;
    data['name'] = name;
    data['url'] = url;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['props_id'] = propsId;
    data['img_url'] = imgUrl;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['anchor_live'] = anchorLive;
    data['location'] = location;
    data['show_name'] = showName;
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
    isLpost = json['is_lpost'].toString();
    link = json['link'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_lpost'] = isLpost;
    data['link'] = link;
    return data;
  }
}

class Zan {
  String? num;
  String? lastTime;
  String? isLiked;

  Zan({this.num, this.lastTime, this.isLiked});

  Zan.fromJson(Map<String, dynamic> json) {
    num = json['num'].toString();
    lastTime = json['last_time'].toString();
    isLiked = json['is_liked'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['num'] = num;
    data['last_time'] = lastTime;
    data['is_liked'] = isLiked;
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
    sortType = json['sort_type'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sort_name'] = sortName;
    data['sort_type'] = sortType;
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
    id = json['id'].toString();
    if (json['content'] != null) {
      content = [];
      json['content'].forEach((v) {
        content?.add(Content.fromJson(v));
      });
    }
    time = json['time'].toString();
    ptype = json['ptype'];
    floor = json['floor'].toString();
    title = json['title'];
    isVoice = json['is_voice'].toString();
    authorId = json['author_id'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (content != null) {
      data['content'] = content?.map((v) => v.toJson()).toList();
    }
    data['time'] = time;
    data['ptype'] = ptype;
    data['floor'] = floor;
    data['title'] = title;
    data['is_voice'] = isVoice;
    data['author_id'] = authorId;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    return data;
  }
}
