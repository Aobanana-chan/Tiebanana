import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// A 方向页签指示器：选中项是一颗填了容器色的药丸。
///
/// 对应概念图 `design/mockups/_mock2.css`。宽度取自 TabBar 传入的标签矩形，
/// 左右各外扩 [horizontalPadding]；高度由 [height] 指定并垂直居中。
/// 调用点的 `Tab(height: ...)` 配 [tabHeight]，页签栏与药丸同高。
///
/// 调用点把 `labelColor` 设为 `onPrimaryContainer`，保证文字对比度。
@immutable
class TiebananaPillTabIndicator extends Decoration {
  const TiebananaPillTabIndicator({
    required this.color,
    this.horizontalPadding = 14,
    this.height = defaultHeight,
  });

  /// 药丸填充色。通常传 `TiebananaTokens.of(context).primaryContainer`。
  final Color color;

  /// 药丸左右相对标签矩形的外扩量，对应概念图 `padding:7px 14px` 里的 14。
  final double horizontalPadding;

  /// 药丸高度。默认 [defaultHeight]。
  ///
  /// 与字号设置无关：它是概念图 `padding:7px 14px` 配 14px 文字的结果
  /// （行高盒约 17.9 + 上下各 7）。字号调到最大时文字行高盒约 25，也还包得住。
  final double height;

  /// 17.9（14px 字号、行高 1.2）+ 7 × 2。取整到 32。
  static const double defaultHeight = 32;

  /// 页签高度：调用点传 `Tab(height: tabHeight)`。比药丸矮 2，正好抵消 TabBar 垫在
  /// 页签下面的 `indicatorWeight`（默认 2，本来是给下划线指示器留的位置），
  /// 页签栏于是和药丸一样高（[defaultHeight]），不留额外空隙。
  ///
  /// 未设置时 `Tab` 会撑到 `kTabHeight` = 46，页签栏 48，药丸四周留白 16px。
  static const double tabHeight = defaultHeight - 2;

  /// TabBar 交进来的标签矩形 → 要画的药丸矩形。
  ///
  /// 那个矩形是「标签宽度 × **整条页签栏**」（原因见类注释），所以这里宽度按
  /// [horizontalPadding] 往外扩、高度取 [height]、再垂直居中到页签栏里。
  Rect pillRect(Rect labelRect) {
    final double pillHeight = math.min(height, labelRect.height);
    final double top = labelRect.top + (labelRect.height - pillHeight) / 2;
    return Rect.fromLTRB(
      labelRect.left - horizontalPadding,
      top,
      labelRect.right + horizontalPadding,
      top + pillHeight,
    );
  }

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _PillTabPainter(this, onChanged);

  @override
  Decoration? lerpFrom(Decoration? a, double t) {
    if (a is TiebananaPillTabIndicator) {
      return TiebananaPillTabIndicator(
        color: Color.lerp(a.color, color, t)!,
        horizontalPadding:
            lerpDouble(a.horizontalPadding, horizontalPadding, t)!,
        height: lerpDouble(a.height, height, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  Decoration? lerpTo(Decoration? b, double t) {
    if (b is TiebananaPillTabIndicator) {
      return TiebananaPillTabIndicator(
        color: Color.lerp(color, b.color, t)!,
        horizontalPadding:
            lerpDouble(horizontalPadding, b.horizontalPadding, t)!,
        height: lerpDouble(height, b.height, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TiebananaPillTabIndicator &&
        other.color == color &&
        other.horizontalPadding == horizontalPadding &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(color, horizontalPadding, height);
}

class _PillTabPainter extends BoxPainter {
  _PillTabPainter(this.decoration, VoidCallback? onChanged) : super(onChanged);

  final TiebananaPillTabIndicator decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Size? size = configuration.size;
    if (size == null) {
      return;
    }
    final Rect rect = offset & size;
    final Rect pill = decoration.pillRect(rect);
    // 半径取高度的一半 = 概念图的 999px 药丸；用 min 兜住「比高度还窄」的极端情况。
    final double radius = math.min(pill.height / 2, pill.width / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pill, Radius.circular(radius)),
      Paint()..color = decoration.color,
    );
  }
}
