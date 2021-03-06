part of json_model;

class SearchForumModel {
  int? no;
  String? forumList;
  SearchForumModelData? data;

  SearchForumModel({this.no, this.forumList, this.data});

  SearchForumModel.fromJson(Map<String, dynamic> json) {
    no = json['no'];
    forumList = json['forum_list'];
    data = json['data'] != null && json['data'].length != 0
        ? SearchForumModelData.fromJson(json['data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['no'] = no;
    data['forum_list'] = forumList;
    if (this.data != null) {
      data['data'] = this.data?.toJson();
    }
    return data;
  }
}

class SearchForumModelData {
  int? no;
  SearchForumModelMainData? data;
  String? error;

  SearchForumModelData({this.no, this.data, this.error});

  SearchForumModelData.fromJson(Map<String, dynamic> json) {
    no = json['no'];
    data = json['data'] != null
        ? SearchForumModelMainData.fromJson(json['data'])
        : null;
    error = json['error'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['no'] = no;
    if (this.data != null) {
      data['data'] = this.data?.toJson();
    }
    data['error'] = error;
    return data;
  }
}

class SearchForumModelMainData {
  String? tbs;
  String? searchWhat;
  bool? illegal;
  bool? isPrecise;
  List<SearchForumModelForum>? forum;
  int? regNum;
  int? searchTime;
  String? searchKey;
  SearchForumModelPage? page;

  SearchForumModelMainData(
      {this.tbs,
      this.searchWhat,
      this.illegal,
      this.isPrecise,
      this.forum,
      this.regNum,
      this.searchTime,
      this.searchKey,
      this.page});

  SearchForumModelMainData.fromJson(Map<String, dynamic> json) {
    tbs = json['tbs'];
    searchWhat = json['search_what'];
    illegal = json['illegal'];
    isPrecise = json['is_precise'];
    if (json['forum'] != null) {
      forum = [];
      json['forum'].forEach((v) {
        forum?.add(SearchForumModelForum.fromJson(v));
      });
    }
    regNum = (json['reg_num'] as num).toInt();
    searchTime = (json['search_time'] as num).toInt();
    searchKey = json['search_key'];
    page = json['page'] != null
        ? SearchForumModelPage.fromJson(json['page'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tbs'] = tbs;
    data['search_what'] = searchWhat;
    data['illegal'] = illegal;
    data['is_precise'] = isPrecise;
    if (forum != null) {
      data['forum'] = forum?.map((v) => v.toJson()).toList();
    }
    data['reg_num'] = regNum;
    data['search_time'] = searchTime;
    data['search_key'] = searchKey;
    if (page != null) {
      data['page'] = page?.toJson();
    }
    return data;
  }
}

class SearchForumModelForum {
  int? id;
  String? name;
  String? img;
  String? brief;
  int? hotValue;
  Dir? dir;
  int? member;
  int? post;
  List<Tags>? tags;
  bool? isLike;

  SearchForumModelForum(
      {this.id,
      this.name,
      this.img,
      this.brief,
      this.hotValue,
      this.dir,
      this.member,
      this.post,
      this.tags,
      this.isLike});

  SearchForumModelForum.fromJson(Map<String, dynamic> json) {
    id = (json['id'] as num).toInt();
    name = json['name'];
    img = json['img'];
    brief = json['brief'];
    hotValue = (json['hot_value'] as num).toInt();
    dir = json['dir'] != null ? Dir.fromJson(json['dir']) : null;
    member = (json['member'] as num).toInt();
    post = (json['post'] as num).toInt();
    if (json['tags'] != null) {
      tags = [];
      json['tags'].forEach((v) {
        tags?.add(Tags.fromJson(v));
      });
    }
    isLike = json['is_like'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['img'] = img;
    data['brief'] = brief;
    data['hot_value'] = hotValue;
    if (dir != null) {
      data['dir'] = dir?.toJson();
    }
    data['member'] = member;
    data['post'] = post;
    if (tags != null) {
      data['tags'] = tags?.map((v) => v.toJson()).toList();
    }
    data['is_like'] = isLike;
    return data;
  }
}

class Dir {
  String? level1Name;
  String? level2Name;

  Dir({this.level1Name, this.level2Name});

  Dir.fromJson(Map<String, dynamic> json) {
    level1Name = json['level_1_name'];
    level2Name = json['level_2_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['level_1_name'] = level1Name;
    data['level_2_name'] = level2Name;
    return data;
  }
}

class Tags {
  String? name;
  String? id;

  Tags({this.name, this.id});

  Tags.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['id'] = id;
    return data;
  }
}

class SearchForumModelPage {
  String? curPage;
  int? totalPage;
  int? totalNum;
  String? pageSize;

  SearchForumModelPage(
      {this.curPage, this.totalPage, this.totalNum, this.pageSize});

  SearchForumModelPage.fromJson(Map<String, dynamic> json) {
    if (json['cur_page'] is String) {
      curPage = json['cur_page'];
    } else {
      curPage = (json['cur_page'] as num).toInt().toString();
    }

    totalPage = (json['total_page'] as num).toInt();
    totalNum = (json['total_num'] as num).toInt();
    if (json['page_size'] is String) {
      pageSize = json['page_size'];
    } else {
      pageSize = (json['page_size'] as num).toInt().toString();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cur_page'] = curPage;
    data['total_page'] = totalPage;
    data['total_num'] = totalNum;
    data['page_size'] = pageSize;
    return data;
  }
}
