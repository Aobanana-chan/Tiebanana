import 'package:flutter/material.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 关键词高亮文本。
///
/// 搜索结果里的标题 / 摘要标出命中的关键词，高亮色取自
/// `TiebananaTokens.primary`。大小写不敏感；关键词为空或没有命中时，
/// 等同于普通 [Text]。
///
/// 命中片段可能跨多个字符，这里按子串切分，适配中文搜索。
class HighlightText extends StatelessWidget {
  const HighlightText(
    this.text, {
    super.key,
    this.keyword,
    this.style,
    this.highlightStyle,
    this.maxLines,
    this.overflow,
  });

  /// 要显示的原文。
  final String text;

  /// 要高亮的关键词。空串时按普通文本显示。
  final String? keyword;

  /// 普通片段样式（未命中部分）。
  final TextStyle? style;

  /// 命中片段样式。为空时在 [style] 上叠一层强调色 + 加粗。
  final TextStyle? highlightStyle;

  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final String needle = (keyword ?? '').trim();
    if (needle.isEmpty || text.isEmpty) {
      return Text(text,
          style: style, maxLines: maxLines, overflow: overflow);
    }

    final TextStyle base = style ?? DefaultTextStyle.of(context).style;
    final TextStyle highlight = highlightStyle ??
        base.copyWith(
          color: TiebananaTokens.of(context).primary,
          fontWeight: FontWeight.w700,
        );

    final String haystack = text.toLowerCase();
    final String lowerNeedle = needle.toLowerCase();
    final List<InlineSpan> spans = <InlineSpan>[];
    int start = 0;
    bool matched = false;
    while (true) {
      final int hit = haystack.indexOf(lowerNeedle, start);
      if (hit < 0) {
        break;
      }
      matched = true;
      if (hit > start) {
        spans.add(TextSpan(text: text.substring(start, hit)));
      }
      spans.add(TextSpan(
        text: text.substring(hit, hit + needle.length),
        style: highlight,
      ));
      start = hit + needle.length;
    }
    // 一个都没命中时退回普通文本，免得白白多包一层 RichText。
    if (!matched) {
      return Text(text,
          style: style, maxLines: maxLines, overflow: overflow);
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
