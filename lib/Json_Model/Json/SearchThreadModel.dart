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
    regNum = json['reg_num'];
    searchKey = json['search_key'];
    searchTurn = json['search_turn'];
    tbs = json['tbs'];
    totalNum = json['total_num'];
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
    replay = json['replay'];
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
