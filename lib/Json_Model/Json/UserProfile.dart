part of json_model;

class UserProfileModel {
  NicknameInfo? nicknameInfo;
  AntiStat? antiStat;
  UserProfileModelAnti? anti;
  UserProfileModelUser? user;
  // List<Null> concernedForumList;
  // List<Null> alaLiveInfo;
  // List<Null> alaLiveRecord;
  // List<Null> highs;
  // List<Null> window;
  String? maskType;
  // List<Null> postList;
  // List<Null> dynamicList;
  // List<Null> newestDynamicList;
  Tainfo? tainfo;
  // List<Null> userGodInfo;
  // List<Null> newGodRankinfo;
  // List<Null> tbbookrack;
  UcCard? ucCard;
  VideoChannelInfo? videoChannelInfo;
  UserAgreeInfo? userAgreeInfo;
  List<UrlMap>? urlMap;
  // List<Null> recomSwanList;
  Duxiaoman? duxiaoman;
  GoodsWin? goodsWin;
  String? uk;
  String? isBlackWhite;
  BlockInfo? blockInfo;
  String? serverTime;
  int? time;
  int? ctime;
  int? logid;
  String? errorCode;

  UserProfileModel(
      {this.nicknameInfo,
      this.antiStat,
      this.anti,
      this.user,
      // this.concernedForumList,
      // this.alaLiveInfo,
      // this.alaLiveRecord,
      // this.highs,
      // this.window,
      this.maskType,
      // this.postList,
      // this.dynamicList,
      // this.newestDynamicList,
      this.tainfo,
      // this.userGodInfo,
      // this.newGodRankinfo,
      // this.tbbookrack,
      this.ucCard,
      this.videoChannelInfo,
      this.userAgreeInfo,
      this.urlMap,
      // this.recomSwanList,
      this.duxiaoman,
      this.goodsWin,
      this.uk,
      this.isBlackWhite,
      this.blockInfo,
      this.serverTime,
      this.time,
      this.ctime,
      this.logid,
      this.errorCode});

  UserProfileModel.fromJson(Map<String, dynamic> json) {
    nicknameInfo = json['nickname_info'] != null
        ? NicknameInfo.fromJson(json['nickname_info'])
        : null;
    antiStat =
        json['anti_stat'] != null ? AntiStat.fromJson(json['anti_stat']) : null;
    anti = json['anti'] != null
        ? UserProfileModelAnti.fromJson(json['anti'])
        : null;
    user = json['user'] != null
        ? UserProfileModelUser.fromJson(json['user'])
        : null;
    // if (json['concerned_forum_list'] != null) {
    //   concernedForumList = new List<Null>();
    //   json['concerned_forum_list'].forEach((v) {
    //     concernedForumList.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['ala_live_info'] != null) {
    //   alaLiveInfo = new List<Null>();
    //   json['ala_live_info'].forEach((v) {
    //     alaLiveInfo.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['ala_live_record'] != null) {
    //   alaLiveRecord = new List<Null>();
    //   json['ala_live_record'].forEach((v) {
    //     alaLiveRecord.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['highs'] != null) {
    //   highs = new List<Null>();
    //   json['highs'].forEach((v) {
    //     highs.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['window'] != null) {
    //   window = new List<Null>();
    //   json['window'].forEach((v) {
    //     window.add(new Null.fromJson(v));
    //   });
    // }
    maskType = json['mask_type'];
    // if (json['post_list'] != null) {
    //   postList = new List<Null>();
    //   json['post_list'].forEach((v) {
    //     postList.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['dynamic_list'] != null) {
    //   dynamicList = new List<Null>();
    //   json['dynamic_list'].forEach((v) {
    //     dynamicList.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['newest_dynamic_list'] != null) {
    //   newestDynamicList = new List<Null>();
    //   json['newest_dynamic_list'].forEach((v) {
    //     newestDynamicList.add(new Null.fromJson(v));
    //   });
    // }
    tainfo = json['tainfo'] != null ? Tainfo.fromJson(json['tainfo']) : null;
    // if (json['user_god_info'] != null) {
    //   userGodInfo = new List<Null>();
    //   json['user_god_info'].forEach((v) {
    //     userGodInfo.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['new_god_rankinfo'] != null) {
    //   newGodRankinfo = new List<Null>();
    //   json['new_god_rankinfo'].forEach((v) {
    //     newGodRankinfo.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['tbbookrack'] != null) {
    //   tbbookrack = new List<Null>();
    //   json['tbbookrack'].forEach((v) {
    //     tbbookrack.add(new Null.fromJson(v));
    //   });
    // }
    ucCard = json['uc_card'] != null ? UcCard.fromJson(json['uc_card']) : null;
    videoChannelInfo = json['video_channel_info'] != null
        ? VideoChannelInfo.fromJson(json['video_channel_info'])
        : null;
    userAgreeInfo = json['user_agree_info'] != null
        ? UserAgreeInfo.fromJson(json['user_agree_info'])
        : null;
    if (json['url_map'] != null) {
      urlMap = [];
      json['url_map'].forEach((v) {
        urlMap?.add(UrlMap.fromJson(v));
      });
    }
    // if (json['recom_swan_list'] != null) {
    //   recomSwanList = new List<Null>();
    //   json['recom_swan_list'].forEach((v) {
    //     recomSwanList.add(new Null.fromJson(v));
    //   });
    // }
    duxiaoman = json['duxiaoman'] != null
        ? Duxiaoman.fromJson(json['duxiaoman'])
        : null;
    goodsWin =
        json['goods_win'] != null ? GoodsWin.fromJson(json['goods_win']) : null;
    uk = json['uk'];
    isBlackWhite = json['is_black_white'];
    blockInfo = json['block_info'] != null
        ? BlockInfo.fromJson(json['block_info'])
        : null;
    serverTime = json['server_time'];
    time = json['time'];
    ctime = json['ctime'];
    logid = json['logid'];
    errorCode = json['error_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (nicknameInfo != null) {
      data['nickname_info'] = nicknameInfo?.toJson();
    }
    if (antiStat != null) {
      data['anti_stat'] = antiStat?.toJson();
    }
    if (anti != null) {
      data['anti'] = anti?.toJson();
    }
    if (user != null) {
      data['user'] = user?.toJson();
    }
    // if (this.concernedForumList != null) {
    //   data['concerned_forum_list'] =
    //       this.concernedForumList.map((v) => v.toJson()).toList();
    // }
    // if (this.alaLiveInfo != null) {
    //   data['ala_live_info'] = this.alaLiveInfo.map((v) => v.toJson()).toList();
    // }
    // if (this.alaLiveRecord != null) {
    //   data['ala_live_record'] =
    //       this.alaLiveRecord.map((v) => v.toJson()).toList();
    // }
    // if (this.highs != null) {
    //   data['highs'] = this.highs.map((v) => v.toJson()).toList();
    // }
    // if (this.window != null) {
    //   data['window'] = this.window.map((v) => v.toJson()).toList();
    // }
    // data['mask_type'] = this.maskType;
    // if (this.postList != null) {
    //   data['post_list'] = this.postList.map((v) => v.toJson()).toList();
    // }
    // if (this.dynamicList != null) {
    //   data['dynamic_list'] = this.dynamicList.map((v) => v.toJson()).toList();
    // }
    // if (this.newestDynamicList != null) {
    //   data['newest_dynamic_list'] =
    //       this.newestDynamicList.map((v) => v.toJson()).toList();
    // }
    if (tainfo != null) {
      data['tainfo'] = tainfo?.toJson();
    }
    // if (this.userGodInfo != null) {
    //   data['user_god_info'] = this.userGodInfo.map((v) => v.toJson()).toList();
    // }
    // if (this.newGodRankinfo != null) {
    //   data['new_god_rankinfo'] =
    //       this.newGodRankinfo.map((v) => v.toJson()).toList();
    // }
    // if (this.tbbookrack != null) {
    //   data['tbbookrack'] = this.tbbookrack.map((v) => v.toJson()).toList();
    // }
    if (ucCard != null) {
      data['uc_card'] = ucCard?.toJson();
    }
    if (videoChannelInfo != null) {
      data['video_channel_info'] = videoChannelInfo?.toJson();
    }
    if (userAgreeInfo != null) {
      data['user_agree_info'] = userAgreeInfo?.toJson();
    }
    if (urlMap != null) {
      data['url_map'] = urlMap?.map((v) => v.toJson()).toList();
    }
    // if (this.recomSwanList != null) {
    //   data['recom_swan_list'] =
    //       this.recomSwanList.map((v) => v.toJson()).toList();
    // }
    if (duxiaoman != null) {
      data['duxiaoman'] = duxiaoman?.toJson();
    }
    if (goodsWin != null) {
      data['goods_win'] = goodsWin?.toJson();
    }
    data['uk'] = uk;
    data['is_black_white'] = isBlackWhite;
    if (blockInfo != null) {
      data['block_info'] = blockInfo?.toJson();
    }
    data['server_time'] = serverTime;
    data['time'] = time;
    data['ctime'] = ctime;
    data['logid'] = logid;
    data['error_code'] = errorCode;
    return data;
  }
}

class NicknameInfo {
  String? leftDays;

  NicknameInfo({this.leftDays});

  NicknameInfo.fromJson(Map<String, dynamic> json) {
    leftDays = json['left_days'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['left_days'] = leftDays;
    return data;
  }
}

class AntiStat {
  String? blockStat;
  String? vcodeStat;
  String? hideStat;
  String? daysTofree;
  String? hasChance;

  AntiStat(
      {this.blockStat,
      this.vcodeStat,
      this.hideStat,
      this.daysTofree,
      this.hasChance});

  AntiStat.fromJson(Map<String, dynamic> json) {
    blockStat = json['block_stat'];
    vcodeStat = json['vcode_stat'];
    hideStat = json['hide_stat'];
    daysTofree = json['days_tofree'];
    hasChance = json['has_chance'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['block_stat'] = blockStat;
    data['vcode_stat'] = vcodeStat;
    data['hide_stat'] = hideStat;
    data['days_tofree'] = daysTofree;
    data['has_chance'] = hasChance;
    return data;
  }
}

class UserProfileModelAnti {
  String? tbs;

  UserProfileModelAnti({this.tbs});

  UserProfileModelAnti.fromJson(Map<String, dynamic> json) {
    tbs = json['tbs'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tbs'] = tbs;
    return data;
  }
}

class UserProfileModelUser {
  String? id;
  String? name;
  String? nameShow;
  String? portrait;
  String? isDefaultAvatar;
  String? portraith;
  // List<Null> userPics;
  PrivSets? privSets;
  String? intro;
  String? sex;
  String? outerId;
  String? postNum;
  String? repostNum;
  String? threadNum;
  String? totalAgreeNum;
  // List<Null> iconinfo;
  // List<Null> tshowIcon;
  String? tbAge;
  String? isMask;
  String? isMem;
  String? bookmarkCount;
  String? bookmarkNewCount;
  String? bgPic;
  VipCloseAd? vipCloseAd;
  String? hasBottleEnter;
  // List<Null> tbVip;
  BaijiahaoInfo? baijiahaoInfo;
  NewGodData? newGodData;
  String? eachOtherFriend;
  String? canModifyAvatar;
  String? modifyAvatarDesc;
  // List<Null> pendant;
  String? sealPrefix;
  String? visitorNum;
  String? totalVisitorNum;
  AlaInfo? alaInfo;
  // List<Null> themeCard;
  // List<Null> newTshowIcon;
  PayMemberInfo? payMemberInfo;
  VipInfo? vipInfo;
  VipShowInfo? vipShowInfo;
  // List<Null> consumeInfo;
  String? myLikeNum;
  String? likeForumNum;
  String? concernNum;
  String? fansNum;
  String? hasConcerned;
  TwAnchorInfo? twAnchorInfo;
  String? profitList;
  BusinessAccountInfo? businessAccountInfo;
  String? displayAuthType;
  // String? workCreatorInfo;
  String? isFans;
  List<UserProfileModelLikeForum>? likeForum;
  // List<Null> groupList;
  String? giftNum;
  List<GiftList>? giftList;
  String? bazhuGrade;
  String? friendNum;
  // List<Null> parrScores;
  String? isInvited;
  String? isShowRedpacket;
  CallFansInfo? callFansInfo;
  CreationData? creationData;
  String? favoriteNum;
  // List<Null> liveRoomInfo;
  String? tiebaUid;

  UserProfileModelUser(
      {this.id,
      this.name,
      this.nameShow,
      this.portrait,
      this.isDefaultAvatar,
      this.portraith,
      // this.userPics,
      this.privSets,
      this.intro,
      this.sex,
      this.outerId,
      this.postNum,
      this.repostNum,
      this.threadNum,
      this.totalAgreeNum,
      // this.iconinfo,
      // this.tshowIcon,
      this.tbAge,
      this.isMask,
      this.isMem,
      this.bookmarkCount,
      this.bookmarkNewCount,
      this.bgPic,
      this.vipCloseAd,
      this.hasBottleEnter,
      // this.tbVip,
      this.baijiahaoInfo,
      this.newGodData,
      this.eachOtherFriend,
      this.canModifyAvatar,
      this.modifyAvatarDesc,
      // this.pendant,
      this.sealPrefix,
      this.visitorNum,
      this.totalVisitorNum,
      this.alaInfo,
      // this.themeCard,
      // this.newTshowIcon,
      this.payMemberInfo,
      this.vipInfo,
      this.vipShowInfo,
      // this.consumeInfo,
      this.myLikeNum,
      this.likeForumNum,
      this.concernNum,
      this.fansNum,
      this.hasConcerned,
      this.twAnchorInfo,
      this.profitList,
      this.businessAccountInfo,
      this.displayAuthType,
      // this.workCreatorInfo,
      this.isFans,
      this.likeForum,
      // this.groupList,
      this.giftNum,
      this.giftList,
      this.bazhuGrade,
      this.friendNum,
      // this.parrScores,
      this.isInvited,
      this.isShowRedpacket,
      this.callFansInfo,
      this.creationData,
      this.favoriteNum,
      // this.liveRoomInfo,
      this.tiebaUid});

  UserProfileModelUser.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    nameShow = json['name_show'];
    portrait = json['portrait'];
    isDefaultAvatar = json['is_default_avatar'];
    portraith = json['portraith'];
    // if (json['user_pics'] != null) {
    //   userPics = <Null>[];
    //   json['user_pics'].forEach((v) {
    //     userPics.add(Null.fromJson(v));
    //   });
    // }
    privSets =
        json['priv_sets'] != null ? PrivSets.fromJson(json['priv_sets']) : null;
    intro = json['intro'];
    sex = json['sex'];
    outerId = json['outer_id'];
    postNum = json['post_num'];
    repostNum = json['repost_num'];
    threadNum = json['thread_num'];
    totalAgreeNum = json['total_agree_num'];
    // if (json['iconinfo'] != null) {
    //   iconinfo = <Null>[];
    //   json['iconinfo'].forEach((v) {
    //     iconinfo.add(Null.fromJson(v));
    //   });
    // }
    // if (json['tshow_icon'] != null) {
    //   tshowIcon = <Null>[];
    //   json['tshow_icon'].forEach((v) {
    //     tshowIcon.add(Null.fromJson(v));
    //   });
    // }
    tbAge = json['tb_age'];
    isMask = json['is_mask'];
    isMem = json['is_mem'];
    bookmarkCount = json['bookmark_count'];
    bookmarkNewCount = json['bookmark_new_count'];
    bgPic = json['bg_pic'];
    vipCloseAd = json['vip_close_ad'] != null
        ? VipCloseAd.fromJson(json['vip_close_ad'])
        : null;
    hasBottleEnter = json['has_bottle_enter'];
    // if (json['tb_vip'] != null) {
    //   tbVip = <Null>[];
    //   json['tb_vip'].forEach((v) {
    //     tbVip.add(Null.fromJson(v));
    //   });
    // }
    baijiahaoInfo = json['baijiahao_info'] != null
        ? BaijiahaoInfo.fromJson(json['baijiahao_info'])
        : null;
    newGodData = json['new_god_data'] != null
        ? NewGodData.fromJson(json['new_god_data'])
        : null;
    eachOtherFriend = json['each_other_friend'];
    canModifyAvatar = json['can_modify_avatar'];
    modifyAvatarDesc = json['modify_avatar_desc'];
    // if (json['pendant'] != null) {
    //   pendant = <Null>[];
    //   json['pendant'].forEach((v) {
    //     pendant.add(Null.fromJson(v));
    //   });
    // }
    sealPrefix = json['seal_prefix'];
    visitorNum = json['visitor_num'];
    totalVisitorNum = json['total_visitor_num'];
    alaInfo =
        json['ala_info'] != null ? AlaInfo.fromJson(json['ala_info']) : null;
    // if (json['theme_card'] != null) {
    //   themeCard = <Null>[];
    //   json['theme_card'].forEach((v) {
    //     themeCard.add(Null.fromJson(v));
    //   });
    // }
    // if (json['new_tshow_icon'] != null) {
    //   newTshowIcon = <Null>[];
    //   json['new_tshow_icon'].forEach((v) {
    //     newTshowIcon.add(Null.fromJson(v));
    //   });
    // }
    payMemberInfo = json['pay_member_info'] != null
        ? PayMemberInfo.fromJson(json['pay_member_info'])
        : null;
    vipInfo =
        json['vipInfo'] != null ? VipInfo.fromJson(json['vipInfo']) : null;
    vipShowInfo = json['vip_show_info'] != null
        ? VipShowInfo.fromJson(json['vip_show_info'])
        : null;
    // if (json['consume_info'] != null) {
    //   consumeInfo = <Null>[];
    //   json['consume_info'].forEach((v) {
    //     consumeInfo.add(Null.fromJson(v));
    //   });
    // }
    myLikeNum = json['my_like_num'];
    likeForumNum = json['like_forum_num'];
    concernNum = json['concern_num'];
    fansNum = json['fans_num'];
    hasConcerned = json['has_concerned'];
    twAnchorInfo = json['tw_anchor_info'] != null
        ? TwAnchorInfo.fromJson(json['tw_anchor_info'])
        : null;
    profitList = json['profit_list'];
    businessAccountInfo = json['business_account_info'] != null
        ? BusinessAccountInfo.fromJson(json['business_account_info'])
        : null;
    displayAuthType = json['display_auth_type'];
    // workCreatorInfo = json['work_creator_info'];
    isFans = json['is_fans'];
    if (json['likeForum'] != null) {
      likeForum = <UserProfileModelLikeForum>[];
      json['likeForum'].forEach((v) {
        likeForum?.add(UserProfileModelLikeForum.fromJson(v));
      });
    }
    // if (json['groupList'] != null) {
    //   groupList = <Null>[];
    //   json['groupList'].forEach((v) {
    //     groupList.add(Null.fromJson(v));
    //   });
    // }
    giftNum = json['gift_num'];
    if (json['gift_list'] != null) {
      giftList = <GiftList>[];
      json['gift_list'].forEach((v) {
        giftList?.add(GiftList.fromJson(v));
      });
    }
    if (json['bazhu_grade'] is List) {
      if ((json['bazhu_grade'] as List).isNotEmpty) {
        throw Exception("数据类型不匹配");
      }
    } else {
      bazhuGrade = json['bazhu_grade'];
    }

    friendNum = json['friend_num'];
    // if (json['parr_scores'] != null) {
    //   parrScores = <Null>[];
    //   json['parr_scores'].forEach((v) {
    //     parrScores.add(Null.fromJson(v));
    //   });
    // }
    isInvited = json['is_invited'];
    isShowRedpacket = json['is_show_redpacket'];
    callFansInfo = json['call_fans_info'] != null
        ? CallFansInfo.fromJson(json['call_fans_info'])
        : null;
    creationData = json['creation_data'] != null
        ? CreationData.fromJson(json['creation_data'])
        : null;
    favoriteNum = json['favorite_num'];
    // if (json['live_room_info'] != null) {
    //   liveRoomInfo = <Null>[];
    //   json['live_room_info'].forEach((v) {
    //     liveRoomInfo.add(Null.fromJson(v));
    //   });
    // }
    tiebaUid = json['tieba_uid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['name_show'] = nameShow;
    data['portrait'] = portrait;
    data['is_default_avatar'] = isDefaultAvatar;
    data['portraith'] = portraith;
    // if (userPics != null) {
    //   data['user_pics'] = userPics.map((v) => v.toJson()).toList();
    // }
    if (privSets != null) {
      data['priv_sets'] = privSets?.toJson();
    }
    data['intro'] = intro;
    data['sex'] = sex;
    data['outer_id'] = outerId;
    data['post_num'] = postNum;
    data['repost_num'] = repostNum;
    data['thread_num'] = threadNum;
    data['total_agree_num'] = totalAgreeNum;
    // if (iconinfo != null) {
    //   data['iconinfo'] = iconinfo.map((v) => v.toJson()).toList();
    // }
    // if (tshowIcon != null) {
    //   data['tshow_icon'] = tshowIcon.map((v) => v.toJson()).toList();
    // }
    data['tb_age'] = tbAge;
    data['is_mask'] = isMask;
    data['is_mem'] = isMem;
    data['bookmark_count'] = bookmarkCount;
    data['bookmark_new_count'] = bookmarkNewCount;
    data['bg_pic'] = bgPic;
    if (vipCloseAd != null) {
      data['vip_close_ad'] = vipCloseAd?.toJson();
    }
    data['has_bottle_enter'] = hasBottleEnter;
    // if (tbVip != null) {
    //   data['tb_vip'] = tbVip.map((v) => v.toJson()).toList();
    // }
    if (baijiahaoInfo != null) {
      data['baijiahao_info'] = baijiahaoInfo?.toJson();
    }
    if (newGodData != null) {
      data['new_god_data'] = newGodData?.toJson();
    }
    data['each_other_friend'] = eachOtherFriend;
    data['can_modify_avatar'] = canModifyAvatar;
    data['modify_avatar_desc'] = modifyAvatarDesc;
    // if (pendant != null) {
    //   data['pendant'] = pendant.map((v) => v.toJson()).toList();
    // }
    data['seal_prefix'] = sealPrefix;
    data['visitor_num'] = visitorNum;
    data['total_visitor_num'] = totalVisitorNum;
    if (alaInfo != null) {
      data['ala_info'] = alaInfo?.toJson();
    }
    // if (themeCard != null) {
    //   data['theme_card'] = themeCard.map((v) => v.toJson()).toList();
    // }
    // if (newTshowIcon != null) {
    //   data['new_tshow_icon'] = newTshowIcon.map((v) => v.toJson()).toList();
    // }
    if (payMemberInfo != null) {
      data['pay_member_info'] = payMemberInfo?.toJson();
    }
    if (vipInfo != null) {
      data['vipInfo'] = vipInfo?.toJson();
    }
    if (vipShowInfo != null) {
      data['vip_show_info'] = vipShowInfo?.toJson();
    }
    // if (consumeInfo != null) {
    //   data['consume_info'] = consumeInfo.map((v) => v.toJson()).toList();
    // }
    data['my_like_num'] = myLikeNum;
    data['like_forum_num'] = likeForumNum;
    data['concern_num'] = concernNum;
    data['fans_num'] = fansNum;
    data['has_concerned'] = hasConcerned;
    if (twAnchorInfo != null) {
      data['tw_anchor_info'] = twAnchorInfo?.toJson();
    }
    data['profit_list'] = profitList;
    if (businessAccountInfo != null) {
      data['business_account_info'] = businessAccountInfo?.toJson();
    }
    data['display_auth_type'] = displayAuthType;
    // data['work_creator_info'] = workCreatorInfo;
    data['is_fans'] = isFans;
    if (likeForum != null) {
      data['likeForum'] = likeForum?.map((v) => v.toJson()).toList();
    }
    // if (groupList != null) {
    //   data['groupList'] = groupList.map((v) => v.toJson()).toList();
    // }
    data['gift_num'] = giftNum;
    if (giftList != null) {
      data['gift_list'] = giftList?.map((v) => v.toJson()).toList();
    }
    data['bazhu_grade'] = bazhuGrade;
    data['friend_num'] = friendNum;
    // if (parrScores != null) {
    //   data['parr_scores'] = parrScores.map((v) => v.toJson()).toList();
    // }
    data['is_invited'] = isInvited;
    data['is_show_redpacket'] = isShowRedpacket;
    if (callFansInfo != null) {
      data['call_fans_info'] = callFansInfo?.toJson();
    }
    if (creationData != null) {
      data['creation_data'] = creationData?.toJson();
    }
    data['favorite_num'] = favoriteNum;
    // if (liveRoomInfo != null) {
    //   data['live_room_info'] = liveRoomInfo.map((v) => v.toJson()).toList();
    // }
    data['tieba_uid'] = tiebaUid;
    return data;
  }
}

// class PrivSets {
//   String post;
//   String location;
//   String like;
//   String group;
//   String friend;
//   String live;
//   String reply;
//   String bazhuShowInside;
//   String bazhuShowOutside;

//   PrivSets(
//       {this.post,
//       this.location,
//       this.like,
//       this.group,
//       this.friend,
//       this.live,
//       this.reply,
//       this.bazhuShowInside,
//       this.bazhuShowOutside});

//   PrivSets.fromJson(Map<String, dynamic> json) {
//     post = json['post'];
//     location = json['location'];
//     like = json['like'];
//     group = json['group'];
//     friend = json['friend'];
//     live = json['live'];
//     reply = json['reply'];
//     bazhuShowInside = json['bazhu_show_inside'];
//     bazhuShowOutside = json['bazhu_show_outside'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = Map<String, dynamic>();
//     data['post'] = post;
//     data['location'] = location;
//     data['like'] = like;
//     data['group'] = group;
//     data['friend'] = friend;
//     data['live'] = live;
//     data['reply'] = reply;
//     data['bazhu_show_inside'] = bazhuShowInside;
//     data['bazhu_show_outside'] = bazhuShowOutside;
//     return data;
//   }
// }

class VipCloseAd {
  String? isOpen;
  String? vipClose;
  // List<Null> forumClose;

  VipCloseAd({
    this.isOpen,
    this.vipClose,
    // this.forumClose,
  });

  VipCloseAd.fromJson(Map<String, dynamic> json) {
    isOpen = json['is_open'];
    vipClose = json['vip_close'];
    // if (json['forum_close'] != null) {
    //   forumClose = <Null>[];
    //   json['forum_close'].forEach((v) {
    //     forumClose.add(Null.fromJson(v));
    //   });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_open'] = isOpen;
    data['vip_close'] = vipClose;
    // if (forumClose != null) {
    //   data['forum_close'] = forumClose.map((v) => v.toJson()).toList();
    // }
    return data;
  }
}

class BaijiahaoInfo {
  String? name;
  String? avatar;
  String? avatarH;
  String? brief;
  String? authId;
  String? authDesc;

  BaijiahaoInfo(
      {this.name,
      this.avatar,
      this.avatarH,
      this.brief,
      this.authId,
      this.authDesc});

  BaijiahaoInfo.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    avatar = json['avatar'];
    avatarH = json['avatar_h'];
    brief = json['brief'];
    authId = json['auth_id'];
    authDesc = json['auth_desc'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['avatar'] = avatar;
    data['avatar_h'] = avatarH;
    data['brief'] = brief;
    data['auth_id'] = authId;
    data['auth_desc'] = authDesc;
    return data;
  }
}

class NewGodData {
  String? fieldId;

  NewGodData({this.fieldId});

  NewGodData.fromJson(Map<String, dynamic> json) {
    fieldId = json['field_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['field_id'] = fieldId;
    return data;
  }
}

// class AlaInfo {
//   String alaId;
//   String liveId;
//   String levelId;
//   String levelExp;
//   String liveStatus;
//   String verifyInfoStatus;

//   AlaInfo(
//       {this.alaId,
//       this.liveId,
//       this.levelId,
//       this.levelExp,
//       this.liveStatus,
//       this.verifyInfoStatus});

//   AlaInfo.fromJson(Map<String, dynamic> json) {
//     alaId = json['ala_id'];
//     liveId = json['live_id'];
//     levelId = json['level_id'];
//     levelExp = json['level_exp'];
//     liveStatus = json['live_status'];
//     verifyInfoStatus = json['verify_info_status'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = Map<String, dynamic>();
//     data['ala_id'] = alaId;
//     data['live_id'] = liveId;
//     data['level_id'] = levelId;
//     data['level_exp'] = levelExp;
//     data['live_status'] = liveStatus;
//     data['verify_info_status'] = verifyInfoStatus;
//     return data;
//   }
// }

class PayMemberInfo {
  String? propsId;
  String? endTime;
  String? url;
  String? expireRemind;

  PayMemberInfo({this.propsId, this.endTime, this.url, this.expireRemind});

  PayMemberInfo.fromJson(Map<String, dynamic> json) {
    propsId = json['props_id'];
    endTime = json['end_time'];
    url = json['url'];
    expireRemind = json['expire_remind'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['props_id'] = propsId;
    data['end_time'] = endTime;
    data['url'] = url;
    data['expire_remind'] = expireRemind;
    return data;
  }
}

// class VipInfo {
//   String vStatus;
//   String sTime;
//   String eTime;
//   String extScore;
//   String vLevel;
//   String aScore;
//   String nScore;
//   String iconUrl;

//   VipInfo(
//       {this.vStatus,
//       this.sTime,
//       this.eTime,
//       this.extScore,
//       this.vLevel,
//       this.aScore,
//       this.nScore,
//       this.iconUrl});

//   VipInfo.fromJson(Map<String, dynamic> json) {
//     vStatus = json['v_status'];
//     sTime = json['s_time'];
//     eTime = json['e_time'];
//     extScore = json['ext_score'];
//     vLevel = json['v_level'];
//     aScore = json['a_score'];
//     nScore = json['n_score'];
//     iconUrl = json['icon_url'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = Map<String, dynamic>();
//     data['v_status'] = vStatus;
//     data['s_time'] = sTime;
//     data['e_time'] = eTime;
//     data['ext_score'] = extScore;
//     data['v_level'] = vLevel;
//     data['a_score'] = aScore;
//     data['n_score'] = nScore;
//     data['icon_url'] = iconUrl;
//     return data;
//   }
// }

class VipShowInfo {
  String? content;
  String? link;
  String? title;
  String? vipIcon;

  VipShowInfo({this.content, this.link, this.title, this.vipIcon});

  VipShowInfo.fromJson(Map<String, dynamic> json) {
    content = json['content'];
    link = json['link'];
    title = json['title'];
    vipIcon = json['vip_icon'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['content'] = content;
    data['link'] = link;
    data['title'] = title;
    data['vip_icon'] = vipIcon;
    return data;
  }
}

class TwAnchorInfo {
  String? anchorLevel;
  String? inBlackList;
  String? setCover;
  String? callerMsg;
  String? follow;
  String? guide;
  String? newfloor;
  String? fansNum;
  String? monthUpdateDays;
  String? giftsNum;

  TwAnchorInfo(
      {this.anchorLevel,
      this.inBlackList,
      this.setCover,
      this.callerMsg,
      this.follow,
      this.guide,
      this.newfloor,
      this.fansNum,
      this.monthUpdateDays,
      this.giftsNum});

  TwAnchorInfo.fromJson(Map<String, dynamic> json) {
    anchorLevel = json['anchor_level'];
    inBlackList = json['in_black_list'];
    setCover = json['set_cover'];
    callerMsg = json['caller_msg'];
    follow = json['follow'];
    guide = json['guide'];
    newfloor = json['newfloor'];
    fansNum = json['fans_num'];
    monthUpdateDays = json['month_update_days'];
    giftsNum = json['gifts_num'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['anchor_level'] = anchorLevel;
    data['in_black_list'] = inBlackList;
    data['set_cover'] = setCover;
    data['caller_msg'] = callerMsg;
    data['follow'] = follow;
    data['guide'] = guide;
    data['newfloor'] = newfloor;
    data['fans_num'] = fansNum;
    data['month_update_days'] = monthUpdateDays;
    data['gifts_num'] = giftsNum;
    return data;
  }
}

class BusinessAccountInfo {
  String? businessName;
  String? identifiExplain;
  String? isBusinessAccount;

  BusinessAccountInfo(
      {this.businessName, this.identifiExplain, this.isBusinessAccount});

  BusinessAccountInfo.fromJson(Map<String, dynamic> json) {
    businessName = json['business_name'];
    identifiExplain = json['identifi_explain'];
    isBusinessAccount = json['is_business_account'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['business_name'] = businessName;
    data['identifi_explain'] = identifiExplain;
    data['is_business_account'] = isBusinessAccount;
    return data;
  }
}

class UserProfileModelLikeForum {
  String? forumName;
  String? forumId;

  UserProfileModelLikeForum({this.forumName, this.forumId});

  UserProfileModelLikeForum.fromJson(Map<String, dynamic> json) {
    forumName = json['forum_name'];
    forumId = json['forum_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['forum_name'] = forumName;
    data['forum_id'] = forumId;
    return data;
  }
}

class GiftList {
  String? giftId;
  String? giftName;
  String? icon;
  String? largeThumbnailUrl;
  String? num;
  String? senderId;
  String? senderName;

  GiftList(
      {this.giftId,
      this.giftName,
      this.icon,
      this.largeThumbnailUrl,
      this.num,
      this.senderId,
      this.senderName});

  GiftList.fromJson(Map<String, dynamic> json) {
    giftId = json['gift_id'];
    giftName = json['gift_name'];
    icon = json['icon'];
    largeThumbnailUrl = json['large_thumbnail_url'];
    num = json['num'];
    senderId = json['sender_id'];
    senderName = json['sender_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['gift_id'] = giftId;
    data['gift_name'] = giftName;
    data['icon'] = icon;
    data['large_thumbnail_url'] = largeThumbnailUrl;
    data['num'] = num;
    data['sender_id'] = senderId;
    data['sender_name'] = senderName;
    return data;
  }
}

class CallFansInfo {
  String? canCall;

  CallFansInfo({this.canCall});

  CallFansInfo.fromJson(Map<String, dynamic> json) {
    canCall = json['can_call'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['can_call'] = canCall;
    return data;
  }
}

class CreationData {
  String? viewCount;
  String? agreeCount;
  String? commentCount;
  String? viewCountTrend;
  String? agreeCountTrend;
  String? commentCountTrend;

  CreationData(
      {this.viewCount,
      this.agreeCount,
      this.commentCount,
      this.viewCountTrend,
      this.agreeCountTrend,
      this.commentCountTrend});

  CreationData.fromJson(Map<String, dynamic> json) {
    viewCount = json['view_count'];
    agreeCount = json['agree_count'];
    commentCount = json['comment_count'];
    viewCountTrend = json['view_count_trend'];
    agreeCountTrend = json['agree_count_trend'];
    commentCountTrend = json['comment_count_trend'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['view_count'] = viewCount;
    data['agree_count'] = agreeCount;
    data['comment_count'] = commentCount;
    data['view_count_trend'] = viewCountTrend;
    data['agree_count_trend'] = agreeCountTrend;
    data['comment_count_trend'] = commentCountTrend;
    return data;
  }
}

class Tainfo {
  String? groupnum;
  String? friendnum;
  String? isFriend;
  String? friendAddType;
  // List<Null> replyList;
  String? userIosHightestVerSion;
  String? userClientVersionIsLower;
  String? hideUserFeed;

  Tainfo(
      {this.groupnum,
      this.friendnum,
      this.isFriend,
      this.friendAddType,
      // this.replyList,
      this.userIosHightestVerSion,
      this.userClientVersionIsLower,
      this.hideUserFeed});

  Tainfo.fromJson(Map<String, dynamic> json) {
    groupnum = json['groupnum'];
    friendnum = json['friendnum'];
    isFriend = json['is_friend'];
    friendAddType = json['friend_add_type'];
    // if (json['reply_list'] != null) {
    //   replyList = <Null>[];
    //   json['reply_list'].forEach((v) {
    //     replyList.add(Null.fromJson(v));
    //   });
    // }
    userIosHightestVerSion = json['userIosHightestVerSion'];
    userClientVersionIsLower = json['userClientVersionIsLower'];
    hideUserFeed = json['hide_user_feed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['groupnum'] = groupnum;
    data['friendnum'] = friendnum;
    data['is_friend'] = isFriend;
    data['friend_add_type'] = friendAddType;
    // if (replyList != null) {
    //   data['reply_list'] = replyList.map((v) => v.toJson()).toList();
    // }
    data['userIosHightestVerSion'] = userIosHightestVerSion;
    data['userClientVersionIsLower'] = userClientVersionIsLower;
    data['hide_user_feed'] = hideUserFeed;
    return data;
  }
}

class UcCard {
  String? name;
  String? icon;
  String? doc;
  String? jmp;
  List<UcCards>? ucCards;

  UcCard({this.name, this.icon, this.doc, this.jmp, this.ucCards});

  UcCard.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    icon = json['icon'];
    doc = json['doc'];
    jmp = json['jmp'];
    if (json['uc_cards'] != null) {
      ucCards = <UcCards>[];
      json['uc_cards'].forEach((v) {
        ucCards?.add(UcCards.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['icon'] = icon;
    data['doc'] = doc;
    data['jmp'] = jmp;
    if (ucCards != null) {
      data['uc_cards'] = ucCards?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class UcCards {
  String? title;
  String? pic;
  String? jmp;
  String? tip;
  String? st;

  UcCards({this.title, this.pic, this.jmp, this.tip, this.st});

  UcCards.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    pic = json['pic'];
    jmp = json['jmp'];
    tip = json['tip'];
    st = json['st'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['pic'] = pic;
    data['jmp'] = jmp;
    data['tip'] = tip;
    data['st'] = st;
    return data;
  }
}

class VideoChannelInfo {
  String? manChannel;
  String? followChannel;

  VideoChannelInfo({this.manChannel, this.followChannel});

  VideoChannelInfo.fromJson(Map<String, dynamic> json) {
    manChannel = json['man_channel'];
    followChannel = json['follow_channel'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['man_channel'] = manChannel;
    data['follow_channel'] = followChannel;
    return data;
  }
}

class UserAgreeInfo {
  String? totalAgreeNum;

  UserAgreeInfo({this.totalAgreeNum});

  UserAgreeInfo.fromJson(Map<String, dynamic> json) {
    totalAgreeNum = json['total_agree_num'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_agree_num'] = totalAgreeNum;
    return data;
  }
}

class UrlMap {
  String? id;
  String? name;
  String? url;

  UrlMap({this.id, this.name, this.url});

  UrlMap.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    url = json['url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['url'] = url;
    return data;
  }
}

class Duxiaoman {
  String? totalCash;
  String? isEnd;

  Duxiaoman({this.totalCash, this.isEnd});

  Duxiaoman.fromJson(Map<String, dynamic> json) {
    totalCash = json['total_cash'];
    isEnd = json['is_end'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_cash'] = totalCash;
    data['is_end'] = isEnd;
    return data;
  }
}

class GoodsWin {
  String? goodsUrl;
  String? show;

  GoodsWin({this.goodsUrl, this.show});

  GoodsWin.fromJson(Map<String, dynamic> json) {
    goodsUrl = json['goods_url'];
    show = json['show'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['goods_url'] = goodsUrl;
    data['show'] = show;
    return data;
  }
}

class BlockInfo {
  String? isPermanentBan;
  String? isAutoPay;

  BlockInfo({this.isPermanentBan, this.isAutoPay});

  BlockInfo.fromJson(Map<String, dynamic> json) {
    isPermanentBan = json['is_permanent_ban'];
    isAutoPay = json['is_auto_pay'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_permanent_ban'] = isPermanentBan;
    data['is_auto_pay'] = isAutoPay;
    return data;
  }
}
