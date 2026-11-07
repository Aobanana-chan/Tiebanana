// ignore_for_file: constant_identifier_names, use_build_context_synchronously

import 'package:animate_do/animate_do.dart';
import 'package:extended_image/extended_image.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/shared/content/special_span.dart';
import 'package:tiebanana/shared/content/post_link_span.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/shared/media/video_player.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/link_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

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

  ///链接 / 话题 / 视频播放链接共用的可点文字 span（无法路由时回退 WebView）。
  static TextSpan _buildLinkSpan(BuildContext context, String text, String link,
      {String forumName = ''}) {
    return TextSpan(
        text: text,
        style: TextStyle(
            fontSize: Provider.of<APPSettingProvider>(context).fontSize,
            fontWeight: FontWeight.bold,
            color: TiebananaTokens.of(context).primary),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            if (await AppUtil.urlRoute(context, link, forumName: forumName) ==
                false) {
              Navigator.push(context, appPageRoute(builder: (builder) {
                return WebViewWidget(
                  controller: WebViewController()
                    ..setBackgroundColor(Colors.white)
                    ..setJavaScriptMode(JavaScriptMode.unrestricted)
                    ..setNavigationDelegate(NavigationDelegate(
                        onNavigationRequest: (request) async {
                      if (await AppUtil.urlRoute(
                        context,
                        request.url,
                      )) {
                        return NavigationDecision.prevent;
                      }

                      return NavigationDecision.navigate;
                    }))
                    ..loadRequest(Uri.parse(link)),
                );
              }));
            }
          });
  }

  ///通用Content生成Widget
  static List<Widget> parseContent(
      BuildContext context,
      List<TiebaPostContent>? contents,
      List<String> allImgs,
      List<String> allOrgImgs,
      {TiebaVideoInfo? videoInfo,
      bool selectable = false,
      int mediaLimit = 1 << 31,
      bool isRecommend = false,
      String forumName = ''}) {
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
    for (TiebaPostContent elem in contents ?? []) {
      if (elem is TiebaTextContent) //文字内容
      {
        richText.add(TextSpan(
          text: (elem).text,
          style: TextStyle(fontSize: Global.setting.fontSize),
        ));
      } else if (elem is TiebaVoteBadgeContent) {
        // 投票阵营徽章由楼层卡在正文上方单独渲染，正文里不重复。
      } else if (elem is TiebaImageContent) {
        //媒体数量限制
        if (mediaNum >= mediaLimit) {
          continue;
        }

        //图片
        switch (Global.setting.pictureLoadSetting) {
          //智能省流量
          case 0:
            offset ??= _getImgIndex(elem.displaySrc, allImgs);
            ExtendedPageController controller =
                ExtendedPageController(initialPage: index + offset);
            if (isRecommend) {
              images.add(elem.displaySrc);
              imgsOriginSrc.add(elem.originalSrc);
            } else {
              richText.add(ExtendedWidgetSpan(
                  child: Container(
                    margin: const EdgeInsets.only(top: 3, bottom: 3),
                    child: Thumbnail(
                      imgs: allImgs,
                      controller: controller,
                      img: elem.lowFlowSrc,
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
            offset ??= _getImgIndex(elem.displaySrc, allImgs);
            if (elem.bsizeValue < 0x100000) {
              //小于1mb就加载
              if (isRecommend) {
                images.add(elem.displaySrc);
                imgsOriginSrc.add(elem.originalSrc);
              } else {
                ExtendedPageController controller =
                    ExtendedPageController(initialPage: index + offset);
                richText.add(ExtendedWidgetSpan(
                    child: Container(
                      margin: const EdgeInsets.only(top: 3, bottom: 3),
                      child: Thumbnail(
                        imgs: allImgs,
                        controller: controller,
                        img: elem.lowFlowSrc,
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
            offset ??= _getImgIndex(elem.displaySrc, allImgs);
            ExtendedPageController controller =
                ExtendedPageController(initialPage: index + offset);
            if (isRecommend) {
              images.add(elem.displaySrc);
              imgsOriginSrc.add(elem.originalSrc);
            } else {
              richText.add(ExtendedWidgetSpan(
                  child: Container(
                    margin: const EdgeInsets.only(top: 3, bottom: 3),
                    child: Thumbnail(
                      imgs: allImgs,
                      controller: controller,
                      img: elem.originalSrc,
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
      } else if (elem is TiebaAtContent) {
        richText.add(TextSpan(
          text: (elem).text,
          style: TextStyle(color: TiebananaTokens.of(context).primary),
        ));
      } else if (elem is TiebaVideoContent) {
        //视频
        final TiebaVideoInfo? info = videoInfo;
        final bool fromVideoInfo = info?.videoUrl != null;
        final double aspectRatio = normalizeVideoAspectRatio(fromVideoInfo
            ? videoAspectRatioOf(info!.width, info.height)
            : videoAspectRatioOf(elem.width, elem.height));
        richText.add(ExtendedWidgetSpan(
            child: VideoPlayer(
              cover: fromVideoInfo ? info!.thumbnailUrl : elem.cover,
              url: fromVideoInfo ? info!.videoUrl! : elem.link!,
              aspectRatio: aspectRatio,
            ),
            actualText: "#(视频)"));
      } else if (elem is TiebaEmojiContent) {
        //表情包
        richText.add(EmojiSpan(elem.text,
            cache: true,
            imageHeight: 18,
            imageWidth: 18,
            actualText: "#(${elem.c})",
            fallbackUrl: elem.dynamicUrl ?? elem.staticUrl));
      } else if (elem is TiebaLinkContent) {
        //type1-链接
        richText.add(prependLinkIcon(context,
            _buildLinkSpan(context, elem.text, elem.link, forumName: forumName),
            fontSize: Provider.of<APPSettingProvider>(context).fontSize));
      } else if (elem is TiebaTopicContent) {
        //type18-话题
        richText.add(_buildLinkSpan(context, elem.text, elem.link,
            forumName: forumName));
      } else if (elem is TiebaVideoLinkContent) {
        //type53-视频播放链接，官方样式为标题+播放图标
        richText.add(_buildLinkSpan(context, "▶ ${elem.text}", elem.link,
            forumName: forumName));
      } else if (elem is TiebaPhoneContent) {
        //手机号码？
        richText.add(TextSpan(
          text: (elem).text,
          style: TextStyle(fontSize: Global.setting.fontSize),
        ));
      } else if (elem is TiebaVoiceContent) {
        //type10-语音回复
        final int? during = elem.duringTime;
        richText.add(ExtendedWidgetSpan(
            child: Container(
              margin: const EdgeInsets.only(top: 2, bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color:
                    TiebananaTokens.of(context).primary.withValues(alpha: 0.12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard_voice,
                      size: 16, color: TiebananaTokens.of(context).primary),
                  if (during != null && during > 0)
                    Text(" $during″",
                        style: TextStyle(
                          fontSize: Global.setting.fontSize - 2,
                          color: TiebananaTokens.of(context).primary,
                        )),
                ],
              ),
            ),
            actualText: "#(语音)"));
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
      final text = ExtendedText.rich(
        TextSpan(children: richText),
      );
      return [selectable ? SelectionArea(child: text) : text];
    }
  }

  ///生成回复贴Widget
  static List<Widget> parseReplyContent(
      BuildContext context,
      TiebaQuota? quota,
      List<TiebaPostContent>? contents,
      String title,
      List<String> allImgs,
      List<String> allOrgImgs,
      {TiebaVideoInfo? videoInfo,
      bool selectable = false,
      int mediaLimit = 1 << 31,
      String forumName = ''}) {
    List<Widget> richText = [];

    //引用
    if (quota != null) {
      richText.add(Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 5),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            color: TiebananaTokens.of(context).quoteBackground,
            borderRadius: BorderRadius.circular(3)),
        child: Wrap(
          children: [
            ExtendedText(
              quota.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: TiebananaTokens.of(context).textTertiary,
                  fontSize: 16),
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
              color: TiebananaTokens.of(context).quoteBackground,
              borderRadius: BorderRadius.circular(3)),
          child: Wrap(children: [
            ExtendedText(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: TiebananaTokens.of(context).textTertiary,
                  fontSize: 16),
              specialTextSpanBuilder: TiebaSpanBuilder(),
            )
          ])));
    }

    //回复
    richText.add(Container(
      padding: const EdgeInsets.all(5),
      child: Column(
          children: parseContent(context, contents, allImgs, allOrgImgs,
              forumName: forumName)),
    ));

    return richText;
  }

  static List<Widget>? processIcon(TiebaUserIconData author) {
    List<Widget>? icons = author.icons.map((e) {
      return FadeIn(
          child: ExtendedImage.network(
        e,
        width: 16,
        height: 16,
        cache: true,
        // 用户挂在名字后的小图标可能失效；加载失败时留空，
        // 保持作者行高度。
        clearMemoryCacheIfFailed: true,
        loadStateChanged: (ExtendedImageState state) {
          if (state.extendedImageLoadState == LoadState.failed) {
            return const SizedBox(width: 16, height: 16);
          }
          return null;
        },
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

  static String parserContentString(List<TiebaPostContent>? contents) {
    String text = "";

    for (TiebaPostContent elem in contents ?? []) {
      if (elem is TiebaTextContent) //文字内容
      {
        text += elem.text;
      } else if (elem is TiebaAtContent) {
        //@用户
        text += elem.text;
      } else if (elem is TiebaImageContent) {
        text += "#(图片)";
      } else if (elem is TiebaVideoContent || elem is TiebaVideoLinkContent) {
        text += "#(视频)";
      } else if (elem is TiebaEmojiContent) {
        //表情包
        text += "#(${elem.c})";
      } else if (elem is TiebaVoiceContent) {
        text += "#(语音)";
      } else if (elem is TiebaTopicContent) {
        //话题文字进摘要
        text += elem.text;
      } else if (elem is TiebaPhoneContent) {
        text += elem.text;
      }
      //链接段保持旧行为：文字不进摘要。
    }
    return text;
  }

  static String contentBuilder(ContentBuilderType type,
      {TiebaAuthor? replyUser, TiebaUploadedImage? image}) {
    switch (type) {
      case ContentBuilderType.Reply:
        return "回复 #(reply, ${replyUser!.portrait}, ${replyUser.nameShow ?? replyUser.name}) :";
      case ContentBuilderType.Picture:
        return "#(pic,${image!.picId},${image.width},${image.height})";
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

enum ContentBuilderType { Emoji, Reply, Picture }
