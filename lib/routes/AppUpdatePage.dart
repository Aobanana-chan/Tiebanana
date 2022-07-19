import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:tiebanana/common/Config/Version.dart';
import 'package:url_launcher/url_launcher_string.dart';

///App更新页面

class UpdatePage extends StatefulWidget {
  const UpdatePage({Key? key}) : super(key: key);

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  @override
  void initState() {
    super.initState();
    if (Version().hasUpdate == null) {
      Version().checkUpdate().then((value) {
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("更新APP"),
      ),
      body: Container(
          padding: const EdgeInsets.all(10),
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Theme.of(context).backgroundColor,
          child: Column(
            children: [
              Center(
                child: Image.asset(
                  "assets/icon/ic_launcher_round.png",
                  height: 50,
                  width: 50,
                ),
              ),
              const Text("当前版本： ${Version.version}"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("最新版本：${Version().lastestVersion}"),
                  Visibility(
                      visible: Version().hasUpdate == true,
                      child: const Icon(
                        Icons.brightness_1,
                        color: Colors.red,
                        size: 8,
                      ))
                ],
              ),
              Version().hasUpdate == true
                  ? Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child:
                          Markdown(shrinkWrap: true, data: Version().changeLog),
                    )
                  : Container(),
              Version().hasUpdate == true
                  ? const Expanded(child: _DownloadLink())
                  : const Text("已经是最新版本")
            ],
          )),
    );
  }
}

class _DownloadLink extends StatelessWidget {
  const _DownloadLink({Key? key}) : super(key: key);

  Widget buildLink(BuildContext context, String name) {
    var t = TextSpan(text: "$name:  ", children: [
      TextSpan(
          text: Version().downloadUrl[name],
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              launchUrlString(Version().downloadUrl[name]!,
                  mode: LaunchMode.externalApplication,
                  webViewConfiguration: const WebViewConfiguration());
            },
          style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.blue
                  : Theme.of(context).colorScheme.primary))
    ]);
    return Text.rich(t);
  }

  @override
  Widget build(BuildContext context) {
    final List arch = ["arm64-v8a", "armeabi-v7a", "x86_64"];
    return Column(
      children: arch.map((e) => buildLink(context, e)).toList() +
          [
            Expanded(
                child: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return SimpleDialog(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                child: const Text(
                                    '''         大部分2016年以后的主流手机都可选择arm64-v8a,使用arm64-v8a可获得最佳的性能。
        几乎所有的手机都可使用armeabi-v7a,若无法使用arm64-v8a,可使用armeabi-v7a。
        x86_64设备很少,而且一般为平板,若不是确定设备为x86_64架构,请优先使用其他版本。'''),
                              )
                            ],
                          );
                        },
                      );
                    },
                    child: const Text("如何选择?")))
          ],
    );
  }
}
