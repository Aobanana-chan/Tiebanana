import 'package:extended_image/extended_image.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui show PlaceholderAlignment;

import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/AssetList.dart';

///富文本Span和构造

class EmojiSpan extends ExtendedWidgetSpan {
  EmojiSpan(
    String emoji, {
    Key? key,
    required double imageWidth,
    required double imageHeight,
    EdgeInsets? margin,
    int start = 0,
    ui.PlaceholderAlignment alignment = ui.PlaceholderAlignment.middle,
    String? actualText,
    TextBaseline? baseline,
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
              ),
            ),
          ),
          baseline: baseline,
          alignment: alignment,
          start: start,
          deleteAll: true,
          actualText: actualText,
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
  const _EmojiLoader(
      {Key? key,
      required this.emoji,
      this.cache = true,
      this.width,
      this.height,
      this.fit,
      this.semanticLabel,
      this.color,
      this.colorBlendMode,
      this.centerSlice,
      this.onTap,
      this.excludeFromSemantics = false,
      this.alignment = Alignment.center,
      this.repeat = ImageRepeat.noRepeat,
      this.matchTextDirection = false,
      this.gaplessPlayback = false,
      this.filterQuality = FilterQuality.low})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var child;
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
        "${emoji.contains("bearchildren") ? TIEBA_KUMA_EMOJI : TIEBA_EMOJI}$emoji.${emoji.contains("bearchildren") ? "gif" : "png"}",
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

class AtUserSpan extends TextSpan {
  //TODO:点击进入@的用户界面
  AtUserSpan({required String text, TextStyle? style})
      : super(text: text, style: style ?? TextStyle(color: Colors.blue));
}

abstract class TiebaSpecialText extends SpecialText {
  static const String flag = "#(";
  late List<String> args;
  TiebaSpecialText(
      {String startFlag = "#(", String endFlag = ")", TextStyle? textStyle})
      : super(startFlag, endFlag, textStyle) {
    args = argParser();
  }

  List<String> argParser() {
    return getContent().split(",");
  }
}

class TiebaRichTextSpecialText extends TiebaSpecialText {
  final int start;
  TiebaRichTextSpecialText(this.start);
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
      } else {
        return TextSpan(
            text: startFlag,
            children: [TiebaSpanBuilder().build(getContent() + endFlag)]);
      }
    } else {
      return TextSpan();
    }
  }
}

class TiebaSpanBuilder extends SpecialTextSpanBuilder {
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
      return TiebaRichTextSpecialText(start);
    }

    return null;
  }
}
