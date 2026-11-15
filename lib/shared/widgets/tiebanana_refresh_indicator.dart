import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';

/// 下拉刷新控制器：让列表外部的代码（例如「返回键先回顶并刷新」）驱动
/// 当前挂载的 [TiebananaRefreshIndicator]。
///
/// 同一个控制器可以给互斥分支里的多个 indicator 复用（列表 / 空态 / 错误页），
/// 同一时间只会挂载一个。注销时按挂载者身份判断，晚一步执行的 dispose
/// 不会误清掉新挂载的实例。
class TiebananaRefreshController {
  TiebananaRefreshIndicatorState? _state;

  /// 当前是否有 indicator 挂载。没有时 [show] 等同于空操作。
  bool get isAttached => _state != null;

  void attach(TiebananaRefreshIndicatorState state) {
    _state = state;
  }

  void detach(TiebananaRefreshIndicatorState state) {
    if (identical(_state, state)) {
      _state = null;
    }
  }

  /// 按下拉刷新同样的动画把指示器拉出来，并执行一次刷新。
  ///
  /// 正在刷新时返回同一个 Future；没有挂载 indicator 时直接返回。
  Future<void> show() {
    final TiebananaRefreshIndicatorState? state = _state;
    if (state == null) {
      return Future<void>.value();
    }
    return state.show();
  }
}

/// 下拉刷新指示器，替代 Material [RefreshIndicator]。
///
/// 与 Material 版本的差异都是本应用需要的：
/// 1. 位移与手指 1:1（圆弧进度另有映射，不影响位置）。过了触发距离也继续跟手，
///    往回拉时立即缩回，回到起点后完全消失；Material 版本在 armed 之后会把
///    指示器钉在展开位置，往上拉也不缩回。
/// 2. 支持 [TiebananaRefreshController.show] 从代码触发，用于返回键
///    「回顶 + 刷新」时同步显示转圈。
///
/// 只处理纵向、非反向的列表（与 Material 版本一致）。
class TiebananaRefreshIndicator extends StatefulWidget {
  const TiebananaRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.controller,
    this.edgeOffset = 0.0,
    this.displacement = 40.0,
    this.triggerDistance = 80.0,
    this.notificationPredicate = defaultScrollNotificationPredicate,
  }) : assert(triggerDistance > 0.0);

  /// 滚动内容。需要自己带 `AlwaysScrollableScrollPhysics` 才能空列表下拉。
  final Widget child;

  /// 刷新回调。Future 完成前指示器保持转圈。
  final Future<void> Function() onRefresh;

  /// 可选的代码控制器，用于从外部触发刷新。
  final TiebananaRefreshController? controller;

  /// 指示器距列表可视区顶部的距离（例如列表上方还有搜索栏时）。
  final double edgeOffset;

  /// 指示器完全展开后与顶部的距离。
  final double displacement;

  /// 触发刷新所需的下拉距离。
  final double triggerDistance;

  final ScrollNotificationPredicate notificationPredicate;

  @override
  State<TiebananaRefreshIndicator> createState() =>
      TiebananaRefreshIndicatorState();
}

enum _RefreshMode {
  idle,
  drag,
  armed,
  snap,
  refresh,
  done,
  canceled,
}

class TiebananaRefreshIndicatorState extends State<TiebananaRefreshIndicator>
    with SingleTickerProviderStateMixin {
  /// 超过触发距离后允许继续下拉的倍数，只用于避免数值无限增长。
  static const double _maxPullFactor = 3.0;

  /// 下拉进度 → 圆弧进度的映射。拉满时画到 3/4 圈，与 Material 一致。
  static const double _dragArcFactor = 0.75;

  late final AnimationController _controller;
  Animation<double>? _offsetAnimation;
  final ValueNotifier<double> _offset = ValueNotifier<double>(0.0);

  _RefreshMode _mode = _RefreshMode.idle;
  Completer<void>? _pendingRefresh;

  /// 当前是否正在执行刷新回调（含收尾动画）。
  bool get isRefreshing {
    final Completer<void>? pending = _pendingRefresh;
    return pending != null && !pending.isCompleted;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    widget.controller?.attach(this);
  }

  @override
  void didUpdateWidget(TiebananaRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach(this);
      widget.controller?.attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(this);
    final Completer<void>? pending = _pendingRefresh;
    if (pending != null && !pending.isCompleted) {
      pending.complete();
    }
    _pendingRefresh = null;
    _controller.dispose();
    _offset.dispose();
    super.dispose();
  }

  /// 以动画拉出指示器并刷新。正在刷新时复用同一个 Future。
  Future<void> show() {
    final Completer<void>? pending = _pendingRefresh;
    if (pending != null) {
      return pending.future;
    }
    return _runRefresh();
  }

  Future<void> _runRefresh() async {
    if (_pendingRefresh != null) {
      await _pendingRefresh!.future;
      return;
    }
    final Completer<void> completer = Completer<void>();
    _pendingRefresh = completer;
    _setMode(_RefreshMode.snap);
    await _animateOffsetTo(widget.triggerDistance,
        duration: TiebananaMetrics.durationBase);
    if (mounted) {
      _setMode(_RefreshMode.refresh);
      try {
        await widget.onRefresh();
      } catch (_) {
        // 刷新失败也收起指示器；错误提示由 onRefresh 自己负责。
      }
    }
    if (mounted) {
      _setMode(_RefreshMode.done);
      await _animateOffsetTo(0.0, duration: TiebananaMetrics.durationBase);
      if (mounted) {
        _setMode(_RefreshMode.idle);
      }
    }
    _pendingRefresh = null;
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  void _setMode(_RefreshMode mode) {
    if (_mode == mode) {
      return;
    }
    if (!mounted) {
      _mode = mode;
      return;
    }
    setState(() {
      _mode = mode;
    });
  }

  /// 把下拉位移动画到 [target]。被打断时安静返回，由新的动画接管。
  Future<void> _animateOffsetTo(double target,
      {required Duration duration}) async {
    _offsetAnimation?.removeListener(_onAnimatedOffset);
    _offsetAnimation = _controller.drive(
      Tween<double>(begin: _offset.value, end: target)
          .chain(CurveTween(curve: TiebananaMetrics.curveStandard)),
    );
    _offsetAnimation!.addListener(_onAnimatedOffset);
    _controller.duration = duration;
    try {
      await _controller.forward(from: 0.0).orCancel;
    } on TickerCanceled {
      // 页面销毁或新的动画开始：交给调用方继续处理。
    }
  }

  void _onAnimatedOffset() {
    final double value = _offsetAnimation!.value;
    if (_offset.value != value) {
      _offset.value = value;
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification)) {
      return false;
    }
    if (notification.metrics.axisDirection != AxisDirection.down) {
      return false;
    }

    if (_mode == _RefreshMode.idle) {
      if (notification.metrics.extentBefore > 0.0) {
        return false;
      }
      // 从顶部开始拖，或者一次拖动中途滚到了顶部，都可以接着下拉刷新。
      final bool dragStart = notification is ScrollStartNotification &&
          notification.dragDetails != null;
      final bool dragReachedTop = notification is ScrollUpdateNotification &&
          notification.dragDetails != null;
      if (dragStart || dragReachedTop) {
        _offset.value = 0.0;
        _setMode(_RefreshMode.drag);
      }
      return false;
    }

    if (_mode != _RefreshMode.drag && _mode != _RefreshMode.armed) {
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails != null) {
        // 包含「已经在顶部继续下拉」和「往回拉、列表重新往上滚」两个方向。
        _applyDragOffset(_offset.value - notification.scrollDelta!);
      } else if (_mode == _RefreshMode.armed) {
        // iOS 回弹：手指松开后的 update 不再带 dragDetails。
        _runRefresh();
      }
    } else if (notification is OverscrollNotification) {
      _applyDragOffset(_offset.value - notification.overscroll);
    } else if (notification is ScrollEndNotification) {
      if (_mode == _RefreshMode.armed) {
        _runRefresh();
      } else {
        _cancel();
      }
    }
    return false;
  }

  void _applyDragOffset(double value) {
    final double max = widget.triggerDistance * _maxPullFactor;
    final double next = value.clamp(0.0, max).toDouble();
    if (_offset.value != next) {
      _offset.value = next;
    }
    final _RefreshMode nextMode = next >= widget.triggerDistance
        ? _RefreshMode.armed
        : _RefreshMode.drag;
    if (_mode != nextMode) {
      _setMode(nextMode);
    }
  }

  void _cancel() {
    if (_mode == _RefreshMode.idle) {
      return;
    }
    _setMode(_RefreshMode.canceled);
    _animateOffsetTo(0.0, duration: TiebananaMetrics.durationFast)
        .whenComplete(() {
      if (mounted && _mode == _RefreshMode.canceled) {
        _setMode(_RefreshMode.idle);
      }
    });
  }

  bool _handleGlowNotification(OverscrollIndicatorNotification notification) {
    if (notification.depth != 0 || !notification.leading) {
      return false;
    }
    if (_mode == _RefreshMode.drag ||
        _mode == _RefreshMode.armed ||
        _mode == _RefreshMode.snap) {
      // 有下拉指示器时不要再叠一层边缘发光。
      notification.disallowIndicator();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: _handleGlowNotification,
        child: widget.child,
      ),
    );
    return ValueListenableBuilder<double>(
      valueListenable: _offset,
      // 同一个 child 实例透传：下拉过程中只重建指示器，不重建列表。
      child: content,
      builder: (BuildContext context, double offset, Widget? child) {
        final bool visible = offset > 0.0 || _mode != _RefreshMode.idle;
        return Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            child!,
            if (visible)
              Positioned(
                top: widget.edgeOffset,
                left: 0.0,
                right: 0.0,
                child: IgnorePointer(
                  child: _buildIndicator(offset),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildIndicator(double offset) {
    final double reveal =
        (offset / widget.triggerDistance).clamp(0.0, 1.0).toDouble();
    final bool spinning = _mode == _RefreshMode.refresh ||
        _mode == _RefreshMode.done;
    return SizeTransition(
      sizeFactor: AlwaysStoppedAnimation<double>(reveal),
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(top: widget.displacement),
        child: Align(
          alignment: Alignment.topCenter,
          child: RefreshProgressIndicator(
            value: spinning ? null : reveal * _dragArcFactor,
          ),
        ),
      ),
    );
  }
}
