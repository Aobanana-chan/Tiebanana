import 'package:extended_text/extended_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 保留文字的换行和点击行为，图标使用与链接一致的颜色。
TextSpan prependLinkIcon(BuildContext context, TextSpan link,
    {required double fontSize}) {
  final size = MediaQuery.textScalerOf(context).scale(fontSize);
  return TextSpan(style: link.style, children: [
    ExtendedWidgetSpan(
      actualText: '',
      alignment: PlaceholderAlignment.middle,
      child: GestureDetector(
        onTap: (link.recognizer as TapGestureRecognizer?)?.onTap,
        excludeFromSemantics: true,
        child: Padding(
          padding: EdgeInsets.only(right: size * 0.18),
          child: Icon(Icons.link_rounded,
              size: size * 0.9, color: link.style?.color),
        ),
      ),
    ),
    link,
  ]);
}
