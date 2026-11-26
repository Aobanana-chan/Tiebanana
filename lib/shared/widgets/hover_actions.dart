import 'package:flutter/material.dart';
import 'package:tiebanana/core/platform/platform_capabilities.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';

/// 桌面悬停显隐操作容器：鼠标悬停时淡入 [actionsBuilder]，保持行静止不位移；
/// 非桌面端或未启用悬停隐藏时常显操作区，避免触摸端找不到操作。
class HoverActions extends StatefulWidget {
  const HoverActions({
    super.key,
    required this.child,
    required this.actionsBuilder,
    this.alwaysShow = false,
  });

  final Widget child;
  final Widget Function(BuildContext context, bool hovered) actionsBuilder;
  final bool alwaysShow;

  @override
  State<HoverActions> createState() => _HoverActionsState();
}

class _HoverActionsState extends State<HoverActions> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool visible = widget.alwaysShow || !isDesktop || _hovered;
    return MouseRegion(
      onEnter: (_) {
        if (!_hovered) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: Stack(
        children: <Widget>[
          widget.child,
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              ignoring: !visible,
              child: AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: TiebananaMetrics.durationFast,
                child: widget.actionsBuilder(context, _hovered),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
