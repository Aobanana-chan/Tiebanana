import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/common/Global.dart';

class AppSettingPage extends StatefulWidget {
  const AppSettingPage({Key? key}) : super(key: key);

  @override
  State<AppSettingPage> createState() => _AppSettingPageState();
}

class _AppSettingPageState extends State<AppSettingPage> {
  TextEditingController controller = TextEditingController();
  late double fontSize;
  @override
  void initState() {
    super.initState();
    fontSize = Provider.of<APPSettingProvider>(context, listen: false).fontSize;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        listTileTheme: ListTileThemeData(
            iconColor: Theme.of(context).brightness == Brightness.light
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.onSurface),
      ),
      child: Scaffold(
          appBar: AppBar(
            title: const Text(
              "应用设置",
            ),
          ),
          body: ListView(
            children: [
              Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.background,
                child: ListTile(
                  title: Text(
                    "账号设置",
                    style: TextStyle(
                        fontSize:
                            Provider.of<APPSettingProvider>(context).fontSize),
                  ),
                ),
              ),
              Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.background,
                child: MaterialButton(
                  onPressed: () {
                    //TODO:进入个人资料界面
                  },
                  child: ListTile(
                    leading: Icon(Icons.person_outline_outlined),
                    title: Text("个人资料",
                        style: TextStyle(
                            fontSize: Provider.of<APPSettingProvider>(context)
                                .fontSize)),
                  ),
                ),
              ),
              Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.background,
                child: MaterialButton(
                  onPressed: () {
                    //TODO:多账号
                    Fluttertoast.showToast(msg: "多账号预计之后添加");
                  },
                  child: ListTile(
                      leading: const Icon(Icons.change_circle),
                      title: Text("切换账号",
                          style: TextStyle(
                              fontSize: Provider.of<APPSettingProvider>(context)
                                  .fontSize)),
                      subtitle: Consumer<User>(
                        builder: (context, value, child) => Text(value.name),
                      )),
                ),
              ),
              Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.background,
                margin: const EdgeInsets.only(bottom: 10),
                child: MaterialButton(
                  onPressed: () {
                    Global.tiebaAPI.logout();
                    Provider.of<User>(context).login();
                  },
                  child: ListTile(
                      leading: const Icon(Icons.exit_to_app),
                      title: Text("退出登陆",
                          style: TextStyle(
                              fontSize: Provider.of<APPSettingProvider>(context)
                                  .fontSize)),
                      subtitle: Consumer<User>(
                        builder: (context, value, child) => Text(value.name),
                      )),
                ),
              ),
              Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.background,
                child: ListTile(
                  title: Text("应用设置",
                      style: TextStyle(
                          fontSize: Provider.of<APPSettingProvider>(context)
                              .fontSize)),
                ),
              ),
              Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.background,
                child: MaterialButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (builder) => SimpleDialog(
                              title: Text("我的小尾巴",
                                  style: TextStyle(
                                      fontSize: Provider.of<APPSettingProvider>(
                                              context)
                                          .fontSize)),
                              children: [
                                Container(
                                  height: 80,
                                  margin: const EdgeInsets.all(5),
                                  child: TextField(
                                      controller: controller,
                                      expands: true,
                                      maxLines: null,
                                      minLines: null,
                                      autofocus: true,
                                      decoration: InputDecoration(
                                        hintText: "小尾巴",
                                        isCollapsed: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 10),
                                        filled: true,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: BorderSide.none),
                                      )),
                                ),
                                TextButton(
                                    onPressed: () {
                                      Global.setting.postTail = controller.text;
                                      Global.saveProfile();
                                      Navigator.pop(context);
                                      setState(() {});
                                    },
                                    child: const Text("确定"))
                              ],
                            ));
                  },
                  child: ListTile(
                    leading: const Icon(Icons.tag_outlined),
                    title: Text("小尾巴",
                        style: TextStyle(
                            fontSize: Provider.of<APPSettingProvider>(context)
                                .fontSize)),
                    subtitle: Text(Global.setting.postTail ?? "你还没有设置小尾巴"),
                    trailing: Switch(
                      value: Global.setting.usePostTail!,
                      onChanged: (value) {
                        setState(() {
                          Global.setting.usePostTail = value;
                          Global.saveProfile();
                        });
                      },
                    ),
                    // trailing: TextButton(
                    //     onPressed: () {
                    //       Global.setting.usePostTail =
                    //           !Global.setting.usePostTail!;
                    //       Global.saveProfile();
                    //       setState(() {});
                    //     },
                    //     child:  Global.setting.usePostTail == false
                    //         ? Text("未激活")
                    //         : Text("已激活")),
                  ),
                ),
              ),
              Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.background,
                child: MaterialButton(
                  onPressed: () async {
                    await showDialog(
                        context: context,
                        builder: (builder) => SimpleDialog(
                              title: Text("图片浏览模式",
                                  style: TextStyle(
                                      fontSize: Provider.of<APPSettingProvider>(
                                              context)
                                          .fontSize)),
                              children: [
                                RadioListTile<int>(
                                  value: 0,
                                  groupValue:
                                      Global.setting.pictureLoadSetting!,
                                  onChanged: (value) {
                                    Global.setting.pictureLoadSetting = value;
                                    Global.saveProfile();
                                    setState(() {});
                                    Navigator.pop(context);
                                  },
                                  title: const Text("智能省流量"),
                                ),
                                RadioListTile<int>(
                                  value: 1,
                                  groupValue:
                                      Global.setting.pictureLoadSetting!,
                                  onChanged: (value) {
                                    Global.setting.pictureLoadSetting = value;
                                    Global.saveProfile();
                                    setState(() {});
                                    Navigator.pop(context);
                                  },
                                  title: const Text("智能无图"),
                                ),
                                RadioListTile<int>(
                                  value: 2,
                                  groupValue:
                                      Global.setting.pictureLoadSetting!,
                                  onChanged: (value) {
                                    Global.setting.pictureLoadSetting = value;
                                    Global.saveProfile();
                                    setState(() {});
                                    Navigator.pop(context);
                                  },
                                  title: const Text("始终高质量"),
                                ),
                                RadioListTile<int>(
                                  value: 3,
                                  groupValue:
                                      Global.setting.pictureLoadSetting!,
                                  onChanged: (value) {
                                    Global.setting.pictureLoadSetting = value;
                                    Global.saveProfile();
                                    setState(() {});
                                    Navigator.pop(context);
                                  },
                                  title: const Text("始终无图"),
                                )
                              ],
                            ));
                  },
                  child: ListTile(
                    leading: const Icon(Icons.image_search_outlined),
                    title: Text("图片浏览模式",
                        style: TextStyle(
                            fontSize: Provider.of<APPSettingProvider>(context)
                                .fontSize)),
                    subtitle: Text(Global.setting.pictureLoadMode),
                  ),
                ),
              ),
              Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.background,
                child: MaterialButton(
                  onPressed: () {
                    //TODO:设置浏览模式
                  },
                  child: ListTile(
                    leading: const Icon(Icons.font_download_outlined),
                    title: Text("字体大小",
                        style: TextStyle(
                            fontSize: Provider.of<APPSettingProvider>(context)
                                .fontSize)),
                    trailing: Consumer<APPSettingProvider>(
                      builder: (context, value, child) => SizedBox.square(
                        dimension: 50,
                        child: Text(value.fontSize.toStringAsFixed(1)),
                      ),
                    ),
                    subtitle: Slider(
                      min: 3,
                      max: 32,
                      value: fontSize,
                      onChanged: (value) {
                        setState(() {
                          fontSize = value;
                        });
                      },
                      onChangeEnd: (value) {
                        Provider.of<APPSettingProvider>(context, listen: false)
                            .fontSize = value;
                      },
                    ),
                  ),
                ),
              ),
              Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.background,
                child: MaterialButton(
                  onPressed: () {
                    //TODO:设置浏览模式
                  },
                  child: ListTile(
                    leading: const Icon(Icons.web_asset),
                    title: Text("使用内置浏览器",
                        style: TextStyle(
                            fontSize: Provider.of<APPSettingProvider>(context)
                                .fontSize)),
                    trailing: Switch(
                      value: Global.setting.useBuildinBrowser!,
                      onChanged: (bool value) {
                        Global.setting.useBuildinBrowser = value;
                        Global.saveProfile();
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ),
              Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.background,
                child: MaterialButton(
                  onPressed: () {
                    //TODO:设置浏览模式
                  },
                  child: ListTile(
                    leading: const Icon(Icons.update),
                    title: Text("自动检查更新",
                        style: TextStyle(
                            fontSize: Provider.of<APPSettingProvider>(context)
                                .fontSize)),
                    trailing: Switch(
                      value: Global.setting.checkUpdateAutomaticlly!,
                      onChanged: (bool value) {
                        Global.setting.useBuildinBrowser = value;
                        Global.saveProfile();
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ),
              Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.background,
                child: MaterialButton(
                  onPressed: () {
                    //TODO:设置浏览模式
                  },
                  child: ListTile(
                    leading: const Icon(Icons.signpost_outlined),
                    title: Text("自动签到",
                        style: TextStyle(
                            fontSize: Provider.of<APPSettingProvider>(context)
                                .fontSize)),
                    trailing: Switch(
                      value: Global.setting.signAllsinceOpen!,
                      onChanged: (bool value) {
                        Global.setting.useBuildinBrowser = value;
                        Global.saveProfile();
                        setState(() {});
                      },
                    ),
                    subtitle: const Text("打开APP后自动开始签到"),
                  ),
                ),
              ),
              Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.background,
                child: MaterialButton(
                  onPressed: () {
                    //TODO:设置浏览模式
                  },
                  child: ListTile(
                    leading: const Icon(Icons.cached_outlined),
                    title: Text("自动缓存收藏贴",
                        style: TextStyle(
                            fontSize: Provider.of<APPSettingProvider>(context)
                                .fontSize)),
                    trailing: Switch(
                      value: Global.setting.signAllsinceOpen!,
                      onChanged: (bool value) {
                        Global.setting.useBuildinBrowser = value;
                        Global.saveProfile();
                        setState(() {});
                      },
                    ),
                    subtitle: const Text("收藏贴浏览后自动缓存（防止帖子被删后找不到内容）预计之后上线"),
                  ),
                ),
              ),
              Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.background,
                child: MaterialButton(
                  onPressed: () {
                    //TODO:关于
                  },
                  child: ListTile(
                    leading: Icon(Icons.warning_amber_outlined),
                    title: Text("关于",
                        style: TextStyle(
                            fontSize: Provider.of<APPSettingProvider>(context)
                                .fontSize)),
                  ),
                ),
              )
            ],
          )),
    );
  }
}
