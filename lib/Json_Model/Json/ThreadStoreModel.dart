part of json_model;

class ThreadStoreModel {
  Error? error;
  List<StoreThread>? storeThread;
  String? serverTime;
  int? time;
  int? ctime;
  int? logid;
  String? errorCode;

  ThreadStoreModel(
      {this.error,
      this.storeThread,
      this.serverTime,
      this.time,
      this.ctime,
      this.logid,
      this.errorCode});

  ThreadStoreModel.fromJson(Map<String, dynamic> json) {
    error = json['error'] != null ? Error.fromJson(json['error']) : null;
    if (json['store_thread'] != null) {
      storeThread = <StoreThread>[];
      json['store_thread'].forEach((v) {
        storeThread!.add(StoreThread.fromJson(v));
      });
    }
    serverTime = json['server_time'];
    time = json['time'];
    ctime = json['ctime'];
    logid = json['logid'];
    errorCode = json['error_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (error != null) {
      data['error'] = error!.toJson();
    }
    if (storeThread != null) {
      data['store_thread'] = storeThread!.map((v) => v.toJson()).toList();
    }
    data['server_time'] = serverTime;
    data['time'] = time;
    data['ctime'] = ctime;
    data['logid'] = logid;
    data['error_code'] = errorCode;
    return data;
  }
}

class Error {
  String? errno;
  String? errmsg;

  Error({this.errno, this.errmsg});

  Error.fromJson(Map<String, dynamic> json) {
    errno = json['errno'];
    errmsg = json['errmsg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['errno'] = errno;
    data['errmsg'] = errmsg;
    return data;
  }
}

class StoreThread {
  String? threadId;
  String? title;
  String? forumName;
  AuthorThreadStored? author;
  List<Media>? media;
  String? god;
  String? isFollow;
  String? isDeleted;
  String? postNo;
  String? postNoMsg;
  String? lastTime;
  String? type;
  String? status;
  String? maxPid;
  String? minPid;
  String? count;
  String? markPid;
  String? markStatus;
  String? replyNum;
  String? floorNum;
  String? createTime;
  String? threadType;

  StoreThread(
      {this.threadId,
      this.title,
      this.forumName,
      this.author,
      this.media,
      this.god,
      this.isFollow,
      this.isDeleted,
      this.postNo,
      this.postNoMsg,
      this.lastTime,
      this.type,
      this.status,
      this.maxPid,
      this.minPid,
      this.count,
      this.markPid,
      this.markStatus,
      this.replyNum,
      this.floorNum,
      this.createTime,
      this.threadType});

  StoreThread.fromJson(Map<String, dynamic> json) {
    threadId = json['thread_id'];
    title = json['title'];
    forumName = json['forum_name'];
    author = json['author'] != null
        ? AuthorThreadStored.fromJson(json['author'])
        : null;
    if (json['media'] != null) {
      media = <Media>[];
      json['media'].forEach((v) {
        media!.add(Media.fromJson(v));
      });
    }
    god = json['god'];
    isFollow = json['is_follow'];
    isDeleted = json['is_deleted'];
    postNo = json['post_no'];
    postNoMsg = json['post_no_msg'];
    lastTime = json['last_time'];
    type = json['type'];
    status = json['status'];
    maxPid = json['max_pid'];
    minPid = json['min_pid'];
    count = json['count'];
    markPid = json['mark_pid'];
    markStatus = json['mark_status'];
    replyNum = json['reply_num'];
    floorNum = json['floor_num'];
    createTime = json['create_time'];
    threadType = json['thread_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['thread_id'] = threadId;
    data['title'] = title;
    data['forum_name'] = forumName;
    if (author != null) {
      data['author'] = author!.toJson();
    }
    if (media != null) {
      data['media'] = media!.map((v) => v.toJson()).toList();
    }
    data['god'] = god;
    data['is_follow'] = isFollow;
    data['is_deleted'] = isDeleted;
    data['post_no'] = postNo;
    data['post_no_msg'] = postNoMsg;
    data['last_time'] = lastTime;
    data['type'] = type;
    data['status'] = status;
    data['max_pid'] = maxPid;
    data['min_pid'] = minPid;
    data['count'] = count;
    data['mark_pid'] = markPid;
    data['mark_status'] = markStatus;
    data['reply_num'] = replyNum;
    data['floor_num'] = floorNum;
    data['create_time'] = createTime;
    data['thread_type'] = threadType;
    return data;
  }
}

class AuthorThreadStored {
  String? lzUid;
  String? name;
  String? nameShow;
  String? userPortrait;

  AuthorThreadStored({this.lzUid, this.name, this.nameShow, this.userPortrait});

  AuthorThreadStored.fromJson(Map<String, dynamic> json) {
    lzUid = json['lz_uid'];
    name = json['name'];
    nameShow = json['name_show'];
    userPortrait = json['user_portrait'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lz_uid'] = lzUid;
    data['name'] = name;
    data['name_show'] = nameShow;
    data['user_portrait'] = userPortrait;
    return data;
  }
}

// class Media {
//   String? type;
//   String? size;
//   String? width;
//   String? height;
//   String? waterPic;
//   String? smallPic;
//   String? bigPic;
//   String? src;
//   String? vsrc;
//   String? vhsrc;
//   String? vpic;

//   Media(
//       {this.type,
//       this.size,
//       this.width,
//       this.height,
//       this.waterPic,
//       this.smallPic,
//       this.bigPic,
//       this.src,
//       this.vsrc,
//       this.vhsrc,
//       this.vpic});

//   Media.fromJson(Map<String, dynamic> json) {
//     type = json['type'];
//     size = json['size'];
//     width = json['width'];
//     height = json['height'];
//     waterPic = json['water_pic'];
//     smallPic = json['small_pic'];
//     bigPic = json['big_pic'];
//     src = json['src'];
//     vsrc = json['vsrc'];
//     vhsrc = json['vhsrc'];
//     vpic = json['vpic'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['type'] = type;
//     data['size'] = size;
//     data['width'] = width;
//     data['height'] = height;
//     data['water_pic'] = waterPic;
//     data['small_pic'] = smallPic;
//     data['big_pic'] = bigPic;
//     data['src'] = src;
//     data['vsrc'] = vsrc;
//     data['vhsrc'] = vhsrc;
//     data['vpic'] = vpic;
//     return data;
//   }
// }
