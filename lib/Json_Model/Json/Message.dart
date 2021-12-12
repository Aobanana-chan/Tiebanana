part of json_model;

class MessagePage {
  String? currentPage;
  String? hasMore;
  String? hasPrev;

  MessagePage({this.currentPage, this.hasMore, this.hasPrev});

  MessagePage.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'];
    hasMore = json['has_more'];
    hasPrev = json['has_prev'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['current_page'] = this.currentPage;
    data['has_more'] = this.hasMore;
    data['has_prev'] = this.hasPrev;
    return data;
  }
}

class NewMessages {
  String? fans;
  String? evaluate;
  String? money;
  String? replyme;
  String? feature;
  String? guess;
  String? anti;
  String? atme;
  String? recycle;
  String? storethread;

  NewMessages(
      {this.fans,
      this.evaluate,
      this.money,
      this.replyme,
      this.feature,
      this.guess,
      this.anti,
      this.atme,
      this.recycle,
      this.storethread});

  NewMessages.fromJson(Map<String, dynamic> json) {
    fans = json['fans'];
    evaluate = json['evaluate'];
    money = json['money'];
    replyme = json['replyme'];
    feature = json['feature'];
    guess = json['guess'];
    anti = json['anti'];
    atme = json['atme'];
    recycle = json['recycle'];
    storethread = json['storethread'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['fans'] = this.fans;
    data['evaluate'] = this.evaluate;
    data['money'] = this.money;
    data['replyme'] = this.replyme;
    data['feature'] = this.feature;
    data['guess'] = this.guess;
    data['anti'] = this.anti;
    data['atme'] = this.atme;
    data['recycle'] = this.recycle;
    data['storethread'] = this.storethread;
    return data;
  }
}

class ReplyMessage {
  String? errorCode;
  NewMessages? message;
  MessagePage? page;
  List<ReplyMe>? reply;

  ReplyMessage({this.errorCode, this.message, this.page, this.reply});

  ReplyMessage.fromJson(Map<String, dynamic> json) {
    errorCode = json['error_code'];
    message = json['message'] != null
        ? new NewMessages.fromJson(json['message'])
        : null;
    page = json['page'] != null ? new MessagePage.fromJson(json['page']) : null;
    if (json['reply_list'] != null) {
      reply = [];
      json['reply_list'].forEach((v) {
        reply?.add(new ReplyMe.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['error_code'] = this.errorCode;
    if (this.message != null) {
      data['message'] = this.message?.toJson();
    }
    if (this.page != null) {
      data['page'] = this.page?.toJson();
    }
    if (this.reply != null) {
      data['reply_list'] = this.reply?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class AtMeMessage {
  String? errorCode;
  NewMessages? newMessages;
  MessagePage? messagePage;
  List<AtMe>? atMe;

  AtMeMessage({this.errorCode, this.newMessages, this.messagePage, this.atMe});

  AtMeMessage.fromJson(Map<String, dynamic> json) {
    errorCode = json['error_code'];
    newMessages = json['message'] != null
        ? new NewMessages.fromJson(json['message'])
        : null;
    messagePage =
        json['page'] != null ? new MessagePage.fromJson(json['page']) : null;
    if (json['at_list'] != null) {
      atMe = [];
      json['at_list'].forEach((v) {
        atMe?.add(new AtMe.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['error_code'] = this.errorCode;
    if (this.newMessages != null) {
      data['message'] = this.newMessages?.toJson();
    }
    if (this.messagePage != null) {
      data['page'] = this.messagePage?.toJson();
    }
    if (this.atMe != null) {
      data['at_list'] = this.atMe?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
