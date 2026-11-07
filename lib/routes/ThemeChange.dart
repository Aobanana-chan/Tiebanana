import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/common/DefaultConfig.dart';
import 'package:tiebanana/common/Global.dart';

///换肤页面

class ThemeChangePage extends StatefulWidget {
  const ThemeChangePage({Key? key}) : super(key: key);

  @override
  State<ThemeChangePage> createState() => _ThemeChangePageState();
}

class _ThemeChangePageState extends State<ThemeChangePage> {
  //可选择的主题
  late List<String> themes;

  @override
  void initState() {
    super.initState();
    themes = Global.themes.keys.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<APPSettingProvider>(
      builder: (context, value, child) => Scaffold(
        appBar: AppBar(
          // backgroundColor: Colors.white,
          // backgroundColor: value.themeColor,
          // foregroundColor: Colors.black,
          // foregroundColor: ,
          title: const Text("更换主题"),
        ),
        body: ListView.builder(
          // physics: const BouncingScrollPhysics(),
          itemCount: themes.length,
          itemBuilder: (BuildContext context, int index) {
            return _SelectThemeItem(
              theme: themes[index],
              useTheme: value.theme,
            );
          },
        ),
      ),
    );
  }
}

class _SelectThemeItem extends StatelessWidget {
  final String theme;
  final String useTheme;
  const _SelectThemeItem(
      {Key? key, required this.theme, required this.useTheme})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      highlightColor: Global.themes[theme],
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: () {
        Provider.of<APPSettingProvider>(context, listen: false).theme = theme;
      },
      child: Container(
        // color: Colors.white,
        padding: const EdgeInsets.all(5),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(64),
                color: Global.themes[theme]),
          ),
          Text(themeName[theme]!),
          const Spacer(),
          Visibility(
              visible: theme == useTheme,
              child: const Icon(
                Icons.done,
                color: Colors.green,
              ))
        ]),
      ),
    );
  }
}
