import 'package:flutter/material.dart';

///页面标题Model
class APPBarTitle with ChangeNotifier {
  String _title = "";
  set title(String title) {
    if (title != _title) {
      _title = title;
      notifyListeners();
    }
  }

  String get getTitle {
    return _title;
  }
}
