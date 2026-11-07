import 'package:flutter/widgets.dart';

/// KeepAliveWrapper keeps the item(s) of a scrollview alive (not disposed),
/// ported from flukit 3.0.1 `src/keep_alive.dart`.
class KeepAliveWrapper extends StatefulWidget {
  const KeepAliveWrapper({super.key, this.keepAlive = true, required this.child});

  final bool keepAlive;
  final Widget child;

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  void didUpdateWidget(covariant KeepAliveWrapper oldWidget) {
    if (oldWidget.keepAlive != widget.keepAlive) {
      updateKeepAlive();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}
