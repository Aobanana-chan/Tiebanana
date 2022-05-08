part of json_model;

class UserPostModel {
  List<PostList>? postList;
  String? hidePost;
  String? maskType;
  String? viewCardNum;
  String? reddotDeletedThread;
  String? serverTime;
  int? time;
  int? ctime;
  int? logid;
  String? errorCode;

  UserPostModel(
      {this.postList,
      this.hidePost,
      this.maskType,
      this.viewCardNum,
      this.reddotDeletedThread,
      this.serverTime,
      this.time,
      this.ctime,
      this.logid,
      this.errorCode});

  UserPostModel.fromJson(Map<String, dynamic> json) {
    if (json['post_list'] != null) {
      postList = <PostList>[];
      json['post_list'].forEach((v) {
        postList?.add(PostList.fromJson(v));
      });
    }
    hidePost = json['hide_post'];
    maskType = json['mask_type'];
    viewCardNum = json['view_card_num'];
    reddotDeletedThread = json['reddot_deleted_thread'];
    serverTime = json['server_time'];
    time = json['time'];
    ctime = json['ctime'];
    logid = json['logid'];
    errorCode = json['error_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (postList != null) {
      data['post_list'] = postList?.map((v) => v.toJson()).toList();
    }
    data['hide_post'] = hidePost;
    data['mask_type'] = maskType;
    data['view_card_num'] = viewCardNum;
    data['reddot_deleted_thread'] = reddotDeletedThread;
    data['server_time'] = serverTime;
    data['time'] = time;
    data['ctime'] = ctime;
    data['logid'] = logid;
    data['error_code'] = errorCode;
    return data;
  }
}

// class PostList {
//   String forumId;
//   String threadId;
//   String postId;
//   String isThread;
//   String threadType;
//   String createTime;
//   String forumName;
//   String title;
//   List<Content> content;
//   String userName;
//   Quota quota;
//   String ptype;
//   String isPostDeleted;
//   String isPostView;
//   String isRemain;
//   String isViewYear;
//   String replyNum;
//   String freqNum;
//   String userId;
//   String nameShow;
//   String privSets;
//   String userPortrait;
//   BaijiahaoInfo baijiahaoInfo;
//   String postType;
//   String isAuthorView;
//   String vForumId;

//   PostList(
//       {this.forumId,
//       this.threadId,
//       this.postId,
//       this.isThread,
//       this.threadType,
//       this.createTime,
//       this.forumName,
//       this.title,
//       this.content,
//       this.userName,
//       this.quota,
//       this.ptype,
//       this.isPostDeleted,
//       this.isPostView,
//       this.isRemain,
//       this.isViewYear,
//       this.replyNum,
//       this.freqNum,
//       this.userId,
//       this.nameShow,
//       this.privSets,
//       this.userPortrait,
//       this.baijiahaoInfo,
//       this.postType,
//       this.isAuthorView,
//       this.vForumId});

//   PostList.fromJson(Map<String, dynamic> json) {
//     forumId = json['forum_id'];
//     threadId = json['thread_id'];
//     postId = json['post_id'];
//     isThread = json['is_thread'];
//     threadType = json['thread_type'];
//     createTime = json['create_time'];
//     forumName = json['forum_name'];
//     title = json['title'];
//     if (json['content'] != null) {
//       content = <Content>[];
//       json['content'].forEach((v) {
//         content.add(Content.fromJson(v));
//       });
//     }
//     userName = json['user_name'];
//     quota = json['quota'] != null ? Quota.fromJson(json['quota']) : null;
//     ptype = json['ptype'];
//     isPostDeleted = json['is_post_deleted'];
//     isPostView = json['is_post_view'];
//     isRemain = json['is_remain'];
//     isViewYear = json['is_view_year'];
//     replyNum = json['reply_num'];
//     freqNum = json['freq_num'];
//     userId = json['user_id'];
//     nameShow = json['name_show'];
//     privSets = json['priv_sets'];
//     userPortrait = json['user_portrait'];
//     baijiahaoInfo = json['baijiahao_info'] != null
//         ? BaijiahaoInfo.fromJson(json['baijiahao_info'])
//         : null;
//     postType = json['post_type'];
//     isAuthorView = json['is_author_view'];
//     vForumId = json['v_forum_id'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['forum_id'] = forumId;
//     data['thread_id'] = threadId;
//     data['post_id'] = postId;
//     data['is_thread'] = isThread;
//     data['thread_type'] = threadType;
//     data['create_time'] = createTime;
//     data['forum_name'] = forumName;
//     data['title'] = title;
//     if (content != null) {
//       data['content'] = content.map((v) => v.toJson()).toList();
//     }
//     data['user_name'] = userName;
//     if (quota != null) {
//       data['quota'] = quota.toJson();
//     }
//     data['ptype'] = ptype;
//     data['is_post_deleted'] = isPostDeleted;
//     data['is_post_view'] = isPostView;
//     data['is_remain'] = isRemain;
//     data['is_view_year'] = isViewYear;
//     data['reply_num'] = replyNum;
//     data['freq_num'] = freqNum;
//     data['user_id'] = userId;
//     data['name_show'] = nameShow;
//     data['priv_sets'] = privSets;
//     data['user_portrait'] = userPortrait;
//     if (baijiahaoInfo != null) {
//       data['baijiahao_info'] = baijiahaoInfo.toJson();
//     }
//     data['post_type'] = postType;
//     data['is_author_view'] = isAuthorView;
//     data['v_forum_id'] = vForumId;
//     return data;
//   }
// }

// class Content {
//   List<PostContent> postContent;
//   String createTime;
//   String postType;
//   String postId;
//   String isAuthorView;

//   Content(
//       {this.postContent,
//       this.createTime,
//       this.postType,
//       this.postId,
//       this.isAuthorView});

//   Content.fromJson(Map<String, dynamic> json) {
//     if (json['post_content'] != null) {
//       postContent = <PostContent>[];
//       json['post_content'].forEach((v) {
//         postContent.add(PostContent.fromJson(v));
//       });
//     }
//     createTime = json['create_time'];
//     postType = json['post_type'];
//     postId = json['post_id'];
//     isAuthorView = json['is_author_view'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     if (postContent != null) {
//       data['post_content'] = postContent.map((v) => v.toJson()).toList();
//     }
//     data['create_time'] = createTime;
//     data['post_type'] = postType;
//     data['post_id'] = postId;
//     data['is_author_view'] = isAuthorView;
//     return data;
//   }
// }

class PostContent {
  String? type;
  String? text;
  String? un;
  String? uid;
  String? src;
  String? bsize;

  PostContent({this.type, this.text, this.un, this.uid, this.src, this.bsize});

  PostContent.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    text = json['text'];
    un = json['un'];
    uid = json['uid'];
    src = json['src'];
    bsize = json['bsize'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['text'] = text;
    data['un'] = un;
    data['uid'] = uid;
    data['src'] = src;
    data['bsize'] = bsize;
    return data;
  }
}

class Quota {
  String? postId;
  String? userName;
  String? userId;
  String? ip;
  String? content;

  Quota({this.postId, this.userName, this.userId, this.ip, this.content});

  Quota.fromJson(Map<String, dynamic> json) {
    postId = json['post_id'];
    userName = json['user_name'];
    userId = json['user_id'];
    ip = json['ip'];
    content = json['content'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['post_id'] = postId;
    data['user_name'] = userName;
    data['user_id'] = userId;
    data['ip'] = ip;
    data['content'] = content;
    return data;
  }
}

// class BaijiahaoInfo {
//   String? avatar;
//   String? authId;
//   String? authDesc;

//   BaijiahaoInfo({this.avatar, this.authId, this.authDesc});

//   BaijiahaoInfo.fromJson(Map<String, dynamic> json) {
//     avatar = json['avatar'];
//     authId = json['auth_id'];
//     authDesc = json['auth_desc'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['avatar'] = avatar;
//     data['auth_id'] = authId;
//     data['auth_desc'] = authDesc;
//     return data;
//   }
// }
