import 'package:flutter/material.dart';

/// 单条滑动操作（必填图标、文字与前景/背景色，颜色由调用方取主题令牌）。
class SwipeAction {
  const SwipeAction({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
}

/// 左滑露出右侧操作按钮的行容器。
///
/// 手势固定为「向左拖动、右侧露出」，与首页「最近浏览」和浏览历史页一致。
/// 拖动时直接修改动画控制器的值，松手后按速度或过半吸附。
class SwipeActionRow extends StatefulWidget {
  const SwipeActionRow({
    super.key,
    required this.child,
    required this.actions,
    this.actionWidth = 66,
    this.margin,
    this.borderRadius = 18,
  });

  /// 行内容（点击、跳转等行为由它自己处理）。
  final Widget child;

  /// 从右往左排列的操作按钮，最后一个最靠右。
  final List<SwipeAction> actions;

  final double actionWidth;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  @override
  State<SwipeActionRow> createState() => _SwipeActionRowState();
}

class _SwipeActionRowState extends State<SwipeActionRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final CurvedAnimation _openness = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  double get _totalWidth => widget.actionWidth * widget.actions.length;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_totalWidth == 0) {
      return;
    }
    _controller.value =
        (_controller.value - details.delta.dx / _totalWidth).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    if (velocity < -200) {
      _controller.forward();
      return;
    }
    if (velocity > 200) {
      _controller.reverse();
      return;
    }
    if (_controller.value >= 0.5) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _handleAction(SwipeAction action) {
    _controller.reverse();
    action.onTap();
  }

  Widget _actionButton(SwipeAction action) {
    return SizedBox(
      width: widget.actionWidth,
      child: Material(
        color: action.background,
        child: InkWell(
          onTap: () => _handleAction(action),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(action.icon, size: 16, color: action.foreground),
              const SizedBox(height: 3),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  color: action.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final SwipeAction action in widget.actions)
                      _actionButton(action),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _openness,
              builder: (BuildContext context, Widget? child) =>
                  Transform.translate(
                offset: Offset(-_totalWidth * _openness.value, 0),
                child: child,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
