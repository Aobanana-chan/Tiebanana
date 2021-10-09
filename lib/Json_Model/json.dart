///TBS随机参数
class TBS {
  String? tbs;
  int? isLogin;

  TBS({this.tbs, this.isLogin});

  TBS.fromJson(Map<String, dynamic> json) {
    tbs = json['tbs'];
    isLogin = json['is_login'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tbs'] = this.tbs;
    data['is_login'] = this.isLogin;
    return data;
  }
}

///服务器返回的rsakey
class RSAKEY {
  String? errno;
  String? msg;
  String? pubkey;
  String? key;
  String? traceid;

  RSAKEY({this.errno, this.msg, this.pubkey, this.key, this.traceid});

  RSAKEY.fromJson(Map<String, dynamic> json) {
    errno = json['errno'];
    msg = json['msg'];
    pubkey = json['pubkey'];
    key = json['key'];
    traceid = json['traceid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['errno'] = this.errno;
    data['msg'] = this.msg;
    data['pubkey'] = this.pubkey;
    data['key'] = this.key;
    data['traceid'] = this.traceid;
    return data;
  }
}

///初始化时候viewlog返回的数据
class ViewlogData {
  int? code;
  Data? data;

  ViewlogData({this.code, this.data});

  ViewlogData.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = this.code;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? tk;
  String? as;
  String? ds;
  Feedback? feedback;

  Data({this.tk, this.as, this.ds, this.feedback});

  Data.fromJson(Map<String, dynamic> json) {
    tk = json['tk'];
    as = json['as'];
    ds = json['ds'];
    feedback = json['feedback'] != null
        ? new Feedback.fromJson(json['feedback'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tk'] = this.tk;
    data['as'] = this.as;
    data['ds'] = this.ds;
    if (this.feedback != null) {
      data['feedback'] = this.feedback!.toJson();
    }
    return data;
  }
}

class Feedback {
  String? wap;
  String? pc;

  Feedback({this.wap, this.pc});

  Feedback.fromJson(Map<String, dynamic> json) {
    wap = json['wap'];
    pc = json['pc'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['wap'] = this.wap;
    data['pc'] = this.pc;
    return data;
  }
}

//用户操作记录
class ClickActionData {
  int? x;
  int? y;
  int? t;

  ClickActionData({this.x, this.y, this.t});

  ClickActionData.fromJson(Map<String, dynamic> json) {
    x = json['x'];
    y = json['y'];
    t = json['t'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['x'] = this.x;
    data['y'] = this.y;
    data['t'] = this.t;
    return data;
  }
}

class MoveActionData {
  int? fx;
  int? fy;
  int? t;

  MoveActionData({this.fx, this.fy, this.t});

  MoveActionData.fromJson(Map<String, dynamic> json) {
    fx = json['fx'];
    fy = json['fy'];
    t = json['t'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['fx'] = this.fx;
    data['fy'] = this.fy;
    data['t'] = this.t;
    return data;
  }
}

///getstyle请求返回的数据
class Getstyle {
  int? code;
  GetstyleData? getstyleData;

  Getstyle({this.code, this.getstyleData});

  Getstyle.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    getstyleData = json['getstyleData'] != null
        ? new GetstyleData.fromJson(json['getstyleData'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = this.code;
    if (this.getstyleData != null) {
      data['getstyleData'] = this.getstyleData!.toJson();
    }
    return data;
  }
}

class GetstyleData {
  String? type;
  String? backstr;
  Ext? ext;

  GetstyleData({this.type, this.backstr, this.ext});

  GetstyleData.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    backstr = json['backstr'];
    ext = json['ext'] != null ? new Ext.fromJson(json['ext']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['backstr'] = this.backstr;
    if (this.ext != null) {
      data['ext'] = this.ext!.toJson();
    }
    return data;
  }
}

class Ext {
  String? img;
  String? info;
  int? sup;

  Ext({this.img, this.info, this.sup});

  Ext.fromJson(Map<String, dynamic> json) {
    img = json['img'];
    info = json['info'];
    sup = json['sup'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['img'] = this.img;
    data['info'] = this.info;
    data['sup'] = this.sup;
    return data;
  }
}

class ViewlogVerify {
  int? code;
  Dsdata? dsdata;

  ViewlogVerify({this.code, this.dsdata});

  ViewlogVerify.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    dsdata =
        json['dsdata'] != null ? new Dsdata.fromJson(json['dsdata']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = this.code;
    if (this.dsdata != null) {
      data['dsdata'] = this.dsdata!.toJson();
    }
    return data;
  }
}

class Dsdata {
  String? tk;
  String? as;
  String? ds;
  int? op;

  Dsdata({this.tk, this.as, this.ds, this.op});

  Dsdata.fromJson(Map<String, dynamic> json) {
    tk = json['tk'];
    as = json['as'];
    ds = json['ds'];
    op = json['op'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tk'] = this.tk;
    data['as'] = this.as;
    data['ds'] = this.ds;
    data['op'] = this.op;
    return data;
  }
}

class LoginErrCode {
  String? errcode;
  String? msg;

  LoginErrCode({this.errcode, this.msg});

  LoginErrCode.fromJson(Map<String, dynamic> json) {
    errcode = json['errcode'];
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['errcode'] = this.errcode;
    data['msg'] = this.msg;
    return data;
  }
}
