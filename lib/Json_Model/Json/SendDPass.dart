part of json_model;

class SendDPass {
  int? errno;
  String? msg;
  String? vcodestr;
  String? vcodesign;
  String? isslide;

  SendDPass(
      {this.errno, this.msg, this.vcodestr, this.vcodesign, this.isslide});

  SendDPass.fromJson(Map<String, dynamic> json) {
    errno = (json['errno'] as num).toInt();
    msg = json['msg'];
    vcodestr = json['vcodestr'];
    vcodesign = json['vcodesign'];
    isslide = json['isslide'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['errno'] = errno;
    data['msg'] = msg;
    data['vcodestr'] = vcodestr;
    data['vcodesign'] = vcodesign;
    data['isslide'] = isslide;
    return data;
  }
}
