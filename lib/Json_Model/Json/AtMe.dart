part of json_model;

///@我信息
class AtMe {
  Replyer? replyer;
  QuoteUser? quoteUser;
  String? title;
  String? content;
  String? threadId;
  String? postId;
  String? time;
  String? quoteContent;
  String? fname;
  String? isFloor;
  String? threadType;
  String? isBjh;
  String? baijiahao;

  AtMe(
      {this.replyer,
      this.quoteUser,
      this.title,
      this.content,
      this.threadId,
      this.postId,
      this.time,
      this.quoteContent,
      this.fname,
      this.isFloor,
      this.threadType,
      this.isBjh,
      this.baijiahao});

  AtMe.fromJson(Map<String, dynamic> json) {
    replyer =
        json['replyer'] != null ? Replyer.fromJson(json['replyer']) : null;
    quoteUser = json['quote_user'] != null
        ? QuoteUser.fromJson(json['quote_user'])
        : null;
    title = json['title'];
    content = json['content'];
    threadId = json['thread_id'];
    postId = json['post_id'];
    time = json['time'];
    quoteContent = json['quote_content'];
    fname = json['fname'];
    isFloor = json['is_floor'];
    threadType = json['thread_type'];
    isBjh = json['is_bjh'];
    baijiahao = json['baijiahao'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (replyer != null) {
      data['replyer'] = replyer?.toJson();
    }
    if (quoteUser != null) {
      data['quote_user'] = quoteUser?.toJson();
    }
    data['title'] = title;
    data['content'] = content;
    data['thread_id'] = threadId;
    data['post_id'] = postId;
    data['time'] = time;
    data['quote_content'] = quoteContent;
    data['fname'] = fname;
    data['is_floor'] = isFloor;
    data['thread_type'] = threadType;
    data['is_bjh'] = isBjh;
    data['baijiahao'] = baijiahao;
    return data;
  }
}
