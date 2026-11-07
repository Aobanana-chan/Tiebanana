import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// In-repo replacement for the discontinued `pull_to_refresh_notification`
/// package, covering the only feature set this app uses: a pull-to-reload
/// header driven by drag offsets, with a [PullToRefreshContainer] that
/// renders its own indicator based on `PullToRefreshScrollNotificationInfo`.
///
/// The state machine mirrors the original package (drag -> armed -> snap ->
/// refresh -> done/canceled), only for vertical, non-reversed lists.
enum PullToRefreshIndicatorMode {
  drag, // Pointer is down.
  armed, // Dragged far enough that an up event will run the onRefresh callback.
  snap, // Animating to the indicator's final "displacement".
  refresh, // Running the refresh callback.
  done, // Animating the indicator's fade-out after refreshing.
  canceled, // Animating the indicator's fade-out after not arming.
  error, // Refresh failed.
}

typedef RefreshCallback = Future<bool> Function();

class PullToRefreshNotification extends StatefulWidget {
  const PullToRefreshNotification({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.maxDragOffset,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// The returned [Future] must complete when the refresh operation is
  /// finished. Returning `true` pulls the header back to 0 after refreshing.
  final RefreshCallback onRefresh;

  /// Unused by the app's header (it renders its own indicator), kept for
  /// API compatibility with the original package.
  final Color? color;

  /// The max drag offset (clamps the header height). Also used as the
  /// "armed" threshold (2/3 of this value).
  final double? maxDragOffset;

  @override
  PullToRefreshNotificationState createState() =>
      PullToRefreshNotificationState();
}

class PullToRefreshNotificationState extends State<PullToRefreshNotification>
    with TickerProviderStateMixin {
  static const double _armedFactor = 0.66;
  static const Duration _kPullBackDuration = Duration(milliseconds: 400);

  final StreamController<PullToRefreshScrollNotificationInfo> _onNoticed =
      StreamController<PullToRefreshScrollNotificationInfo>.broadcast();

  /// Broadcast stream of drag-offset updates, consumed by
  /// [PullToRefreshContainer].
  Stream<PullToRefreshScrollNotificationInfo> get onNoticed =>
      _onNoticed.stream;

  late AnimationController _pullBackController;
  Animation<double>? _pullBackFactor;

  PullToRefreshIndicatorMode? _mode;
  double? _dragOffset;
  bool _showing = false;

  double get dragOffset => _dragOffset ?? 0.0;

  @override
  void initState() {
    super.initState();
    _pullBackController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _pullBackController.dispose();
    _onNoticed.close();
    super.dispose();
  }

  void _notified() {
    _onNoticed.add(
        PullToRefreshScrollNotificationInfo(_mode, dragOffset));
  }

  void _setDragOffset(double value) {
    final clamped = math.max(0.0, math.min(value, widget.maxDragOffset ?? 9999));
    if (_dragOffset != clamped) {
      _dragOffset = clamped;
      _notified();
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axisDirection != AxisDirection.down) {
      return false;
    }
    // Ignore notifications from nested scrollables' slivers (e.g.
    // NestedScrollView positions), only react to the innermost vertical list.
    if (_mode == null) {
      if (notification is ScrollStartNotification &&
          notification.metrics.extentBefore == 0.0) {
        _dragOffset = 0.0;
        _mode = PullToRefreshIndicatorMode.drag;
        _notified();
      }
      return false;
    }

    if (_mode == PullToRefreshIndicatorMode.drag ||
        _mode == PullToRefreshIndicatorMode.armed) {
      if (notification is ScrollUpdateNotification) {
        if (notification.metrics.extentBefore > 0.0 &&
            notification.metrics.pixels >= 0) {
          _cancel();
        } else if (notification.dragDetails != null) {
          _setDragOffset(_dragOffset! - notification.scrollDelta!);
          if (_mode == PullToRefreshIndicatorMode.drag &&
              widget.maxDragOffset != null &&
              _dragOffset! >= widget.maxDragOffset! * _armedFactor) {
            _mode = PullToRefreshIndicatorMode.armed;
            _notified();
          }
        } else {
          // Ballistic activity (e.g. iOS bounce); release triggers refresh.
          if (_mode == PullToRefreshIndicatorMode.armed) {
            _show();
          }
        }
      } else if (notification is OverscrollNotification) {
        _setDragOffset(_dragOffset! - notification.overscroll / 2.0);
        if (_mode == PullToRefreshIndicatorMode.drag &&
            widget.maxDragOffset != null &&
            _dragOffset! >= widget.maxDragOffset! * _armedFactor) {
          _mode = PullToRefreshIndicatorMode.armed;
          _notified();
        }
      } else if (notification is ScrollEndNotification) {
        if (_mode == PullToRefreshIndicatorMode.armed) {
          _show();
        } else if (_mode == PullToRefreshIndicatorMode.drag) {
          _cancel();
        }
      }
    }
    return false;
  }

  bool _handleGlowNotification(OverscrollIndicatorNotification notification) {
    if (notification.depth != 0 || !notification.leading) {
      return false;
    }
    if (_mode == PullToRefreshIndicatorMode.drag) {
      notification.disallowIndicator();
      return true;
    }
    return false;
  }

  Future<void> _show() async {
    if (_showing) return;
    _showing = true;
    _mode = PullToRefreshIndicatorMode.snap;
    _notified();
    // Tiny delay so the header "snaps" noticeably before running onRefresh.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _mode = PullToRefreshIndicatorMode.refresh;
    _notified();
    bool success = false;
    try {
      success = await widget.onRefresh();
    } finally {
      _showing = false;
    }
    if (!mounted) return;
    if (success) {
      _mode = PullToRefreshIndicatorMode.done;
      _pullBackHeader();
    } else {
      _mode = PullToRefreshIndicatorMode.error;
      _pullBackHeader();
    }
  }

  /// Animates the drag offset back to 0.
  void _pullBackHeader() {
    final Animatable<double> tween = Tween<double>(
        begin: _dragOffset ?? 0.0, end: 0.0);
    _pullBackFactor?.removeListener(_pullBackListener);
    _pullBackController.reset();
    _pullBackFactor = _pullBackController.drive(tween);
    _pullBackFactor!.addListener(_pullBackListener);
    _pullBackController.animateTo(1.0, duration: _kPullBackDuration);
  }

  void _pullBackListener() {
    if (_dragOffset != null && _dragOffset != _pullBackFactor!.value) {
      _dragOffset = _pullBackFactor!.value;
      _notified();
      if (_dragOffset == 0.0) {
        _dragOffset = null;
        _mode = null;
        _notified();
      }
    }
  }

  Future<void> _cancel() async {
    _mode = PullToRefreshIndicatorMode.canceled;
    _pullBackHeader();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: _handleGlowNotification,
        child: widget.child,
      ),
    );
  }
}

/// Data object passed to [PullToRefreshContainer]'s builder. The app only
/// consumes [dragOffset].
class PullToRefreshScrollNotificationInfo {
  PullToRefreshScrollNotificationInfo(this.mode, this.dragOffset);

  final PullToRefreshIndicatorMode? mode;
  final double? dragOffset;
}

typedef PullToRefreshContainerBuilder = Widget Function(
    PullToRefreshScrollNotificationInfo? info);

/// Listens to the ancestor [PullToRefreshNotificationState] stream and
/// rebuilds whenever the drag offset changes.
class PullToRefreshContainer extends StatefulWidget {
  const PullToRefreshContainer(this.builder, {super.key});

  final PullToRefreshContainerBuilder builder;

  @override
  State<PullToRefreshContainer> createState() => _PullToRefreshContainerState();
}

class _PullToRefreshContainerState extends State<PullToRefreshContainer> {
  @override
  Widget build(BuildContext context) {
    final PullToRefreshNotificationState? state =
        context.findAncestorStateOfType<PullToRefreshNotificationState>();
    return StreamBuilder<PullToRefreshScrollNotificationInfo>(
      builder: (BuildContext c, AsyncSnapshot<PullToRefreshScrollNotificationInfo> s) {
        return widget.builder(s.data);
      },
      stream: state?.onNoticed,
    );
  }
}
