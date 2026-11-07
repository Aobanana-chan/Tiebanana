import '../json.dart';

///吧页面帖控制导航栏数据Model

class GoodPostClassify {
  late String classId;
  late String className;
  GoodPostClassify({required this.classId, required this.className});

  GoodPostClassify.fromGoodClassify(GoodClassify c) {
    classId = c.classId!;
    className = c.className!;
  }
}
