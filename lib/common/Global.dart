import 'package:tieba_flutter/common/API/net.dart';

class Global {
  static TiebaAPI tiebaAPI = TiebaAPI();
  //判断是否是Release版
  static bool get isRelease => bool.fromEnvironment("dart.vm.product");
}
