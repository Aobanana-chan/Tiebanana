import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';

///ExtendedNestedScrollView注入，实现进入ExtendedNestedScrollView的state回调
class ExtendedNestedScrollViewInject extends StatefulWidget {
  final void Function(ExtendedNestedScrollViewState)? initCallback;
  final Widget child;
  const ExtendedNestedScrollViewInject(
      {Key? key, this.initCallback, required this.child})
      : super(key: key);

  @override
  State<ExtendedNestedScrollViewInject> createState() =>
      _ExtendedNestedScrollViewInjectState();
}

class _ExtendedNestedScrollViewInjectState
    extends State<ExtendedNestedScrollViewInject> {
  GlobalKey<ExtendedNestedScrollViewState> key = GlobalKey();
  @override
  void initState() {
    // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //   widget.initCallback?.call(key.currentState!);
    // });
    var state =
        context.findAncestorStateOfType<ExtendedNestedScrollViewState>();
    widget.initCallback?.call(state!);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
