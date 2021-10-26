import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:tiebanana/common/Global.dart';

///主页搜索栏Widget
class SearchBar extends StatefulWidget {
  SearchBar({Key? key}) : super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late List searchHistory;
  @override
  void initState() {
    super.initState();
    var local = Global.profile.getStringList("searchHistory");
    searchHistory = local == null ? [] : local;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Material(
          child: Row(
        children: [DropdownSearch()],
      )),
    );
  }
}
