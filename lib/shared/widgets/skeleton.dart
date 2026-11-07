import 'package:flutter/material.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 骨架屏基元：一块会「扫光」的占位方块。
///
/// 对应概念图 `design/mockups/states.html` 的 `.sk`：
/// 底色取 `TiebananaTokens.skeleton`，高光取 `skeletonHighlight` 横向扫过。
/// 首屏加载时用它提前撑出布局，保持内容到达前后的页面高度。
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 11,
    this.radius = TiebananaMetrics.radiusXs,
  });

  /// 为空时由父级约束决定（配合 `FractionallySizedBox` / `SizedBox`）。
  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[
                tokens.skeleton,
                tokens.skeletonHighlight,
                tokens.skeleton,
              ],
              stops: const <double>[0.35, 0.5, 0.65],
              transform: _ShimmerTransform(_controller.value),
            ),
          ),
        );
      },
    );
  }
}

/// 把渐变整体横向平移一趟，形成扫光。
class _ShimmerTransform extends GradientTransform {
  const _ShimmerTransform(this.progress);

  /// 0 → 1 扫一遍。
  final double progress;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (progress * 2 - 1), 0, 0);
}
