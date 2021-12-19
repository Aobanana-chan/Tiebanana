import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';

///吧页面
class ForumHomePage extends StatefulWidget {
  ///吧名
  final String kw;
  ForumHomePage({Key? key, required this.kw}) : super(key: key);

  @override
  _ForumHomePageState createState() => _ForumHomePageState();
}

class _ForumHomePageState extends State<ForumHomePage> {
  Future<ForumHomeInfo>? forum;

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
