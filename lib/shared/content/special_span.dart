import 'package:extended_image/extended_image.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/features/media/state/image_upload.dart';
import 'dart:ui' as ui show PlaceholderAlignment;

import 'package:tiebanana/core/config/constants.dart';
import 'package:tiebanana/core/config/asset_list.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

///富文本Span和构造

class EmojiSpan extends ExtendedWidgetSpan {
  EmojiSpan(
    String emoji, {
    Key? key,
    required double imageWidth,
    required double imageHeight,
    EdgeInsets? margin,
    super.start,
    super.alignment = ui.PlaceholderAlignment.middle,
    super.actualText = null,
    super.baseline,
    BoxFit fit = BoxFit.scaleDown,
    ImageLoadingBuilder? loadingBuilder,
    ImageFrameBuilder? frameBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    Color? color,
    BlendMode? colorBlendMode,
    Alignment imageAlignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    FilterQuality filterQuality = FilterQuality.low,
    GestureTapCallback? onTap,
    HitTestBehavior behavior = HitTestBehavior.deferToChild,
    bool cache = false,
    String? fallbackUrl,
  })  : width = imageWidth + (margin == null ? 0 : margin.horizontal),
        height = imageHeight + (margin == null ? 0 : margin.vertical),
        super(
          child: Container(
            padding: margin,
            child: GestureDetector(
              onTap: onTap,
              behavior: behavior,
              child: _EmojiLoader(
                emoji: emoji,
                key: key,
                width: imageWidth,
                height: imageHeight,
                fit: fit,
                semanticLabel: semanticLabel,
                excludeFromSemantics: excludeFromSemantics,
                color: color,
                colorBlendMode: colorBlendMode,
                alignment: imageAlignment,
                repeat: repeat,
                centerSlice: centerSlice,
                matchTextDirection: matchTextDirection,
                gaplessPlayback: gaplessPlayback,
                filterQuality: filterQuality,
                cache: cache,
                fallbackUrl: fallbackUrl,
              ),
            ),
          ),
          deleteAll: true,
        );
  final double width;
  final double height;
}

class _EmojiLoader extends StatelessWidget {
  final String emoji;
  final bool cache;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Alignment alignment;
  final ImageRepeat repeat;
  final Rect? centerSlice;
  final bool matchTextDirection;
  final bool gaplessPlayback;
  final FilterQuality filterQuality;
  final GestureTapCallback? onTap;

  ///服务端下发的表情地址（动态表情），本地资源缺失时优先使用。
  final String? fallbackUrl;
  const _EmojiLoader(
      {super.key,
      required this.emoji,
      this.cache = true,
      this.width,
      this.height,
      this.fit,
      this.semanticLabel,
      this.color,
      this.colorBlendMode,
      this.centerSlice,
      this.excludeFromSemantics = false,
      this.alignment = Alignment.center,
      this.repeat = ImageRepeat.noRepeat,
      this.matchTextDirection = false,
      this.gaplessPlayback = false,
      this.filterQuality = FilterQuality.low,
      this.fallbackUrl})
      : onTap = null;

  @override
  Widget build(BuildContext context) {
    Widget child;
    bool localAssetsExist = AssetList.emojiExists("$emoji.png");
    if (localAssetsExist) {
      child = ExtendedImage.asset(
        "assets/emoji/$emoji.png",
        key: key,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        color: color,
        colorBlendMode: colorBlendMode,
        alignment: alignment,
        repeat: repeat,
        centerSlice: centerSlice,
        matchTextDirection: matchTextDirection,
        gaplessPlayback: gaplessPlayback,
        filterQuality: filterQuality,
      );
    } else {
      child = ExtendedImage.network(
        (fallbackUrl != null && fallbackUrl!.isNotEmpty)
            ? fallbackUrl!
            : "${emoji.contains("bearchildren") ? TIEBA_KUMA_EMOJI : TIEBA_EMOJI}$emoji.${emoji.contains("bearchildren") ? "gif" : "png"}",
        key: key,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        color: color,
        colorBlendMode: colorBlendMode,
        alignment: alignment,
        repeat: repeat,
        centerSlice: centerSlice,
        matchTextDirection: matchTextDirection,
        gaplessPlayback: gaplessPlayback,
        filterQuality: filterQuality,
        cache: cache,
      );
    }

    return Container(
      child: child,
    );
  }
}

/// 是否为可跳转的用户 id。
///
/// 服务端下发的普通文字段也可能带 `uid`（缺省为 `"0"`），只有正数才是
/// 真正的用户。用它区分“@ 某人”与普通正文，避免打开空 uid 的用户页。
bool isValidUserUid(String? uid) => (int.tryParse(uid ?? '') ?? 0) > 0;

///@用户的span
class AtUserSpan extends TextSpan {
  final String uid;
  final BuildContext context;
  AtUserSpan(this.context,
      {required String text, TextStyle? style, required this.uid})
      : super(
          text: text,
          style: style ??
              (isValidUserUid(uid)
                  ? TextStyle(color: TiebananaTokens.of(context).primary)
                  : null),
        );
  @override
  GestureRecognizer? get recognizer {
    if (!isValidUserUid(uid)) return null;
    return TapGestureRecognizer()
      ..onTap = () {
        Navigator.pushNamed(context, PageRouter.user, arguments: uid);
      };
  }
}

abstract class TiebaSpecialText extends SpecialText {
  static const String flag = "#(";
  List<String> get args => getContent().split(",");
  TiebaSpecialText(
      {String startFlag = "#(", String endFlag = ")", TextStyle? textStyle})
      : super(startFlag, endFlag, textStyle);
}

class TiebaRichTextSpecialText extends TiebaSpecialText {
  final int start;
  ImageUploadProviderModel? uploadImages;
  TiebaRichTextSpecialText(this.start, {this.uploadImages});
  @override
  InlineSpan finishText() {
    //单参数,表情包
    if (args.length == 1) {
      if (emojiMapping.containsKey(getContent())) {
        return EmojiSpan(emojiMapping[getContent()]!,
            start: start,
            actualText: toString(),
            imageWidth: 18,
            imageHeight: 18);
      }
    } else if (args.length == 4 && args[0] == "pic") {
      //上传的图片
      var imageID = args[1];
      var width = int.tryParse(args[2]);
      var height = int.tryParse(args[3]);

      if (uploadImages != null && width != null && height != null) {
        for (var key in uploadImages!.pictures.keys) {
          if (key.picId == imageID) {
            return ExtendedWidgetSpan(
                start: start,
                actualText: toString(),
                child: const Icon(
                  Icons.image,
                  size: 18,
                ));
          }
        }
      }
    }
    return TextSpan(
        text: startFlag,
        children: [TiebaSpanBuilder().build(getContent() + endFlag)]);
  }
}

class TiebaSpanBuilder extends SpecialTextSpanBuilder {
  ImageUploadProviderModel? uploadImages;
  TiebaSpanBuilder({this.uploadImages});

  @override
  SpecialText? createSpecialText(String flag,
      {TextStyle? textStyle,
      SpecialTextGestureTapCallback? onTap,
      required int index}) {
    if (flag == "") {
      return null;
    }

    if (isStart(flag, TiebaSpecialText.flag)) {
      var start = index - (TiebaSpecialText.flag.length - 1);
      return TiebaRichTextSpecialText(start, uploadImages: uploadImages);
    }

    return null;
  }
}
