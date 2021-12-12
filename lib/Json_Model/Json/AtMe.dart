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
        json['replyer'] != null ? new Replyer.fromJson(json['replyer']) : null;
    quoteUser = json['quote_user'] != null
        ? new QuoteUser.fromJson(json['quote_user'])
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.replyer != null) {
      data['replyer'] = this.replyer?.toJson();
    }
    if (this.quoteUser != null) {
      data['quote_user'] = this.quoteUser?.toJson();
    }
    data['title'] = this.title;
    data['content'] = this.content;
    data['thread_id'] = this.threadId;
    data['post_id'] = this.postId;
    data['time'] = this.time;
    data['quote_content'] = this.quoteContent;
    data['fname'] = this.fname;
    data['is_floor'] = this.isFloor;
    data['thread_type'] = this.threadType;
    data['is_bjh'] = this.isBjh;
    data['baijiahao'] = this.baijiahao;
    return data;
  }
}
