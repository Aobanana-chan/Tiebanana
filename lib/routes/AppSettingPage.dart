import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/common/Global.dart';

class AppSettingPage extends StatefulWidget {
  const AppSettingPage({Key? key}) : super(key: key);

  @override
  State<AppSettingPage> createState() => _AppSettingPageState();
}

class _AppSettingPageState extends State<AppSettingPage> {
  @override
  Widget build(BuildContext context) {
    return Theme(
        data: Theme.of(context).copyWith(
            listTileTheme: ListTileThemeData(
                iconColor: Theme.of(context).brightness == Brightness.light
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.onSurface)),
        child: Scaffold(
          appBar: AppBar(
            title: const Text("应用设置"),
          ),
          body: ListView(
            children: [
              Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.background,
                child: ListTile(
                  title: Text("账号设置"),
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
                    title: Text("个人资料"),
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
                  },
                  child: ListTile(
                      leading: Icon(Icons.change_circle),
                      title: Text("切换账号"),
                      subtitle: Consumer<User>(
                        builder: (context, value, child) => Text(value.name),
                      )),
                ),
              ),
              Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.background,
                margin: EdgeInsets.only(bottom: 10),
                child: MaterialButton(
                  onPressed: () {
                    Global.tiebaAPI.logout();
                    Provider.of<User>(context).login();
                  },
                  child: ListTile(
                      leading: Icon(Icons.exit_to_app),
                      title: Text("退出登陆"),
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
                  title: Text("应用设置"),
                ),
              ),
              Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.background,
                child: MaterialButton(
                  onPressed: () {
                    //TODO:弹出小尾巴窗口
                  },

                  //TODO:添加小尾巴
                  child: ListTile(
                    leading: Icon(Icons.tag_outlined),
                    title: Text("小尾巴"),
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
                  onPressed: () {
                    //TODO:设置浏览模式
                  },
                  child: ListTile(
                    leading: Icon(Icons.image_search_outlined),
                    title: Text("图片浏览模式"),
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
                    leading: Icon(Icons.font_download_outlined),
                    title: Text("字体大小"),
                    trailing: Consumer<APPSettingProvider>(
                      builder: (context, value, child) => SizedBox.square(
                        dimension: 50,
                        child: Text(value.fontSize.toStringAsFixed(1)),
                      ),
                    ),
                    subtitle: Slider(
                        min: 1,
                        max: 32,
                        value: Provider.of<APPSettingProvider>(context,
                                listen: false)
                            .fontSize,
                        onChanged: (value) {
                          setState(() {});
                          Provider.of<APPSettingProvider>(context,
                                  listen: false)
                              .fontSize = value;
                        }),
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
                    leading: Icon(Icons.web_asset),
                    title: Text("使用内置浏览器"),
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
                    leading: Icon(Icons.update),
                    title: Text("自动检查更新"),
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
                    leading: Icon(Icons.signpost_outlined),
                    title: Text("自动签到"),
                    trailing: Switch(
                      value: Global.setting.signAllsinceOpen!,
                      onChanged: (bool value) {
                        Global.setting.useBuildinBrowser = value;
                        Global.saveProfile();
                        setState(() {});
                      },
                    ),
                    subtitle: Text("打开APP后自动开始签到"),
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
                    leading: Icon(Icons.cached_outlined),
                    title: Text("自动缓存收藏贴"),
                    trailing: Switch(
                      value: Global.setting.signAllsinceOpen!,
                      onChanged: (bool value) {
                        Global.setting.useBuildinBrowser = value;
                        Global.saveProfile();
                        setState(() {});
                      },
                    ),
                    subtitle: Text("收藏贴浏览后自动缓存（防止帖子被删后找不到内容）预计之后上线"),
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
                    title: Text("关于"),
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
