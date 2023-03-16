import 'package:animate_do/animate_do.dart';
import 'package:extended_image/extended_image.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/SpecialSpan.dart';
import 'package:tiebanana/Widgets/ThreadSummary.dart';
import 'package:tiebanana/Widgets/VIdeoPlayer.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/common/Util/AppUtil.dart';
import 'package:tiebanana/routes/routes.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../Json_Model/WidgetModel/PostContentModel.dart';
import '../../Json_Model/WidgetModel/QuotaModel.dart';
import '../../Json_Model/WidgetModel/ThreadCommentModel.dart';
import '../../Json_Model/WidgetModel/commonModel.dart';

///贴吧数据生成Widget工具类
class TiebaParser {
  //获取图片的index
  static int _getImgIndex(String img, List<String> allImgs) {
    if (allImgs.isEmpty) {
      return 0;
    }
    for (var i = 0; i < allImgs.length; i++) {
      if (img == allImgs[i]) {
        return i;
      }
    }
    return 0;
  }

  ///通用Content生成Widget
  static List<Widget> parseContent(
      BuildContext context,
      List<PostContentBaseWidgetModel>? contents,
      List<String> allImgs,
      List<String> allOrgImgs,
      {VedioInfoWidgetModel? videoInfo,
      bool selectable = false,
      int mediaLimit = 1 << 31,
      bool isRecommend = false}) {
    List<InlineSpan> richText = [];

    //=======主页推荐贴
    List<Widget> media = <Widget>[];
    List<String> images = [];
    List<String>? imgsOriginSrc = [];
    Widget imgLeft = const SizedBox(
      width: 0,
      height: 0,
    );
    //=======
    int index = 0;
    int? offset;
    int mediaNum = 0;
    for (PostContentBaseWidgetModel elem in contents ?? []) {
      if (elem is TextContentWidgetModel) //文字内容
      {
        richText.add(TextSpan(
          text: (elem).text,
          style: TextStyle(fontSize: Global.setting.fontSize),
        ));
      } else if (elem is ImageContentWidgetModel) {
        //媒体数量限制
        if (mediaNum >= mediaLimit) {
          continue;
        }

        //图片
        switch (Global.setting.pictureLoadSetting) {
          //智能省流量
          case 0:
            offset ??=
                _getImgIndex((elem).bigCdnSrc ?? elem.originSrc!, allImgs);
            ExtendedPageController controller =
                ExtendedPageController(initialPage: index + offset);
            if (isRecommend) {
              images.add((elem).bigCdnSrc ?? elem.originSrc!);
              imgsOriginSrc.add(elem.originSrc!);
            } else {
              richText.add(ExtendedWidgetSpan(
                  child: Container(
                    margin: const EdgeInsets.only(top: 3, bottom: 3),
                    child: Thumbnail(
                      imgs: allImgs,
                      controller: controller,
                      img: (elem).bigCdnSrc ?? elem.originSrc!,
                      imgsOriginSrc: allOrgImgs,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  actualText: "#(图片)"));
            }
            index++;
            mediaNum++;
            break;
          //智能无图
          case 1:
            offset ??=
                _getImgIndex((elem).bigCdnSrc ?? elem.originSrc!, allImgs);
            if (int.parse((elem).bsize!.replaceAll(",", "")) < 0x100000) {
              //小于1mb就加载
              if (isRecommend) {
                images.add((elem).bigCdnSrc ?? elem.originSrc!);
                imgsOriginSrc.add(elem.originSrc!);
              } else {
                ExtendedPageController controller =
                    ExtendedPageController(initialPage: index + offset);
                richText.add(ExtendedWidgetSpan(
                    child: Container(
                      margin: const EdgeInsets.only(top: 3, bottom: 3),
                      child: Thumbnail(
                        imgs: allImgs,
                        controller: controller,
                        img: elem.bigCdnSrc ?? elem.originSrc!,
                        imgsOriginSrc: allOrgImgs,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                    actualText: "#(图片)"));
              }

              index++;
              mediaNum++;
            }
            break;
          //始终高质量
          case 2:
            offset ??=
                _getImgIndex((elem).bigCdnSrc ?? elem.originSrc!, allImgs);
            ExtendedPageController controller =
                ExtendedPageController(initialPage: index + offset);
            if (isRecommend) {
              images.add(elem.bigCdnSrc ?? elem.originSrc!);
              imgsOriginSrc.add(elem.originSrc!);
            } else {
              richText.add(ExtendedWidgetSpan(
                  child: Container(
                    margin: const EdgeInsets.only(top: 3, bottom: 3),
                    child: Thumbnail(
                      imgs: allImgs,
                      controller: controller,
                      img: (elem).originSrc!,
                      imgsOriginSrc: allOrgImgs,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  actualText: "#(图片)"));
            }

            index++;
            mediaNum++;
            break;

          default:
        }
      } else if (elem is AtContentWidgetModel) {
        richText.add(TextSpan(
          text: (elem).text,
          style: const TextStyle(color: Colors.blue),
        ));
      } else if (elem is VideoContentWidgetModel) {
        //视频
        // print("find vedio");
        if (videoInfo?.videoUrl == null) {
          richText.add(ExtendedWidgetSpan(
              child: VideoPlayer(
                cover: elem.cover,
                url: elem.link!,
              ),
              actualText: "#(视频)"));
        } else {
          richText.add(ExtendedWidgetSpan(
              child: VideoPlayer(
                cover: videoInfo!.thumbnailUrl,
                url: videoInfo.videoUrl!,
              ),
              actualText: "#(视频)"));
        }
      } else if (elem is EmojiContentWidgetModel) {
        //表情包

        richText.add(EmojiSpan((elem).text,
            cache: true,
            imageHeight: 18,
            imageWidth: 18,
            actualText: "#(${elem.c})"));
      } else if (elem is LinkContentWidgetModel) {
        // if (Platform.isAndroid) {
        //   WebView.platform = AndroidWebView();
        // }
        //type1-链接
        //type18-话题
        richText.add(TextSpan(
            text: (elem).text,
            style: TextStyle(
                fontSize: Provider.of<APPSettingProvider>(context).fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                if (!context.mounted) return;
                // ignore: use_build_context_synchronously
                if (await AppUtil.urlRoute(context, elem.link) == false) {
                  if (context.mounted) {
                    Navigator.push(context,
                        CupertinoPageRoute(builder: (builder) {
                      return WebViewWidget(
                        controller: WebViewController()
                          ..setBackgroundColor(Colors.white)
                          ..setJavaScriptMode(JavaScriptMode.unrestricted)
                          ..setNavigationDelegate(NavigationDelegate(
                              onNavigationRequest: (request) async {
                            // ignore: use_build_context_synchronously
                            if (await AppUtil.urlRoute(
                              context,
                              request.url,
                            )) {
                              return NavigationDecision.prevent;
                            }

                            return NavigationDecision.navigate;
                          }))
                          ..loadRequest(Uri.parse(elem.link)),
                      );
                    }));
                  }
                }
              }));
      } else if (elem is ForumQuickLinkContentWidgetModel) {
        //TODO:范例 kz=7919486246 kz = 7909655252
        richText.add(TextSpan(
            text: elem.text,
            children: [
              ExtendedWidgetSpan(
                child: const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: Colors.blue,
                ),
                actualText: "",
              )
            ],
            style: TextStyle(
                fontSize: Provider.of<APPSettingProvider>(context).fontSize,
                color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.pushNamed(context, PageRouter.forumHome,
                    arguments: elem.text);
              }));
      } else if (elem is PhoneNumberContentWidgetModel) {
        richText.add(TextSpan(
          text: (elem).text,
          style: TextStyle(fontSize: Global.setting.fontSize),
        ));
      } else if (elem is UnknownontentWidgetModel) {
        richText.add(TextSpan(
          text: (elem).text,
          style: TextStyle(fontSize: Global.setting.fontSize),
        ));
      }
    }

    if (isRecommend) {
      index = 0;
      for (var img in images) {
        ExtendedPageController controller =
            ExtendedPageController(initialPage: index);

        media.add(Expanded(
            child: Thumbnail(
          imgs: images,
          controller: controller,
          img: img,
          imgsOriginSrc: imgsOriginSrc,
        )));
        index++;
      }

      if (allImgs.length > 3) {
        imgLeft = Container(
          padding: const EdgeInsets.all(5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Color(0x8E8E8E8E)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_size_select_actual_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  Text(
                    "${allImgs.length}",
                    style: const TextStyle(color: Colors.white),
                  )
                ],
              ),
            ),
          ),
        );
      }

      return [
        Text.rich(
          TextSpan(children: richText),
          style: TextStyle(
              fontSize: Provider.of<APPSettingProvider>(context).fontSize),
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          maxLines: 12,
        ),
        Offstage(
          offstage: media.isEmpty,
          child: LimitedBox(
              maxHeight: 160,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: media,
                  ),
                  imgLeft
                ],
              )),
        )
      ];
    } else {
      return [
        ExtendedText.rich(
          TextSpan(children: richText),
          selectionEnabled: selectable,
        ),
      ];
    }
  }

  ///生成回复贴Widget
  static List<Widget> parseReplyContent(
      BuildContext context,
      QuotaModel? quota,
      List<PostContentBaseWidgetModel>? contents,
      String title,
      List<String> allImgs,
      List<String> allOrgImgs,
      {VideoInfo? videoInfo,
      bool selectable = false,
      int mediaLimit = 1 << 31}) {
    List<Widget> richText = [];
    //TODO:回复跳转

    //引用
    if (quota != null) {
      richText.add(Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 5),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            color: const Color(0xFFF0F3F5),
            borderRadius: BorderRadius.circular(3)),
        child: Wrap(
          children: [
            ExtendedText(
              quota.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              specialTextSpanBuilder: TiebaSpanBuilder(),
            )
          ],
        ),
      ));
    } else {
      richText.add(Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 5),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: const Color(0xFFF0F3F5),
              borderRadius: BorderRadius.circular(3)),
          child: Wrap(children: [
            ExtendedText(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              specialTextSpanBuilder: TiebaSpanBuilder(),
            )
          ])));
    }

    //回复
    richText.add(Container(
      padding: const EdgeInsets.all(5),
      child: Column(
          children: parseContent(context, contents, allImgs, allOrgImgs)),
    ));

    return richText;
  }

  static List<Widget>? processIcon(UserIconData author) {
    List<Widget>? icons = author.icons.map((e) {
      return FadeIn(
          child: ExtendedImage.network(
        e,
        width: 16,
        height: 16,
        cache: true,
      ));
    }).toList();
    return icons;
  }

  static String getPostTime(
      {String? strTime, int? intTime, DateTime? dateTime}) {
    DateTime time;
    if (strTime != null) {
      time = DateTime.fromMillisecondsSinceEpoch(int.parse(strTime) * 1000);
    } else if (intTime != null) {
      time = DateTime.fromMillisecondsSinceEpoch(intTime * 1000);
    } else if (dateTime != null) {
      time = dateTime;
    } else {
      throw Exception("至少要有一个参数不为null");
    }
    var create = DateTime.now().difference(time);
    Map timeGranularity = {0: "天", 1: "小时", 2: "分钟", 3: "秒"};
    var f = 0;
    late String createText;
    if (create.inDays > 30) {
      createText = "${time.year}年${time.month}月${time.day}日";
    } else {
      for (var t in [
        create.inDays,
        create.inHours,
        create.inMinutes,
        create.inSeconds
      ]) {
        if (t != 0) {
          createText = "$t${timeGranularity[f]}前";
          break;
        }
        f++;
      }
      if (f == 4) {
        createText = "0秒前";
      }
    }
    return createText;
  }

  static String parserContentString(
      List<PostContentBaseWidgetModel>? contents) {
    String text = "";

    for (PostContentBaseWidgetModel elem in contents ?? []) {
      if (elem.type == "0") //文字内容
      {
        text += (elem as TextContentWidgetModel).text;
        // } else if (elem.type == "4" || elem.type == "3") {
        //   //图片
        //   if (elem.type == "4" && elem.originSrc == null) {
        //     //@用户
        //     text += elem.text!;
        //   } else {
        //     text += "#(图片)";
        //   }
      } else if (elem.type == "3") {
        text += "#(图片)";
      } else if (elem.type == "4") {
        text += (elem as AtContentWidgetModel).text;
      } else if (elem.type == "5") {
        text += "#(视频)";
      } else if (elem.type == "2") {
        //表情包
        text += "#(${(elem as EmojiContentWidgetModel).c})";
      }
    }
    return text;
  }

  static String contentBuilder(ContentBuilderType type,
      {AuthorWidgetModel? replyUser, UploadImageModel? image}) {
    switch (type) {
      case ContentBuilderType.Reply:
        return "回复 #(reply, ${replyUser!.portrait}, ${replyUser.nameShow ?? replyUser.name}) :";
      case ContentBuilderType.Picture:
        return "#(pic,${image!.picId},${image.picInfo!.originPic!.width},${image.picInfo!.originPic!.height})";
      default:
    }
    return "";
  }

  ///数字转字符串缩写
  static String numberConvertString(int number) {
    double left = number.toDouble();

    if (left >= 10000000) {
      left /= 10000000;
      return "${left.toStringAsFixed(2)}KW";
    } else if (left >= 10000) {
      left /= 10000;
      return "${left.toStringAsFixed(2)}W";
    } else if (left >= 1000) {
      left /= 1000;
      return "${left.toStringAsFixed(2)}K";
    }
    return number.toString();
  }
}

// ignore: constant_identifier_names
enum ContentBuilderType { Emoji, Reply, Picture }
