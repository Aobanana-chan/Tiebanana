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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['has_more'] = hasMore;
    data['has_prev'] = hasPrev;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['fans'] = fans;
    data['evaluate'] = evaluate;
    data['money'] = money;
    data['replyme'] = replyme;
    data['feature'] = feature;
    data['guess'] = guess;
    data['anti'] = anti;
    data['atme'] = atme;
    data['recycle'] = recycle;
    data['storethread'] = storethread;
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
    message =
        json['message'] != null ? NewMessages.fromJson(json['message']) : null;
    page = json['page'] != null ? MessagePage.fromJson(json['page']) : null;
    if (json['reply_list'] != null) {
      reply = [];
      json['reply_list'].forEach((v) {
        reply?.add(ReplyMe.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['error_code'] = errorCode;
    if (message != null) {
      data['message'] = message?.toJson();
    }
    if (page != null) {
      data['page'] = page?.toJson();
    }
    if (reply != null) {
      data['reply_list'] = reply?.map((v) => v.toJson()).toList();
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
    newMessages =
        json['message'] != null ? NewMessages.fromJson(json['message']) : null;
    messagePage =
        json['page'] != null ? MessagePage.fromJson(json['page']) : null;
    if (json['at_list'] != null && json['at_list'] != "") {
      atMe = [];
      json['at_list'].forEach((v) {
        atMe?.add(AtMe.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['error_code'] = errorCode;
    if (newMessages != null) {
      data['message'] = newMessages?.toJson();
    }
    if (messagePage != null) {
      data['page'] = messagePage?.toJson();
    }
    if (atMe != null) {
      data['at_list'] = atMe?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
