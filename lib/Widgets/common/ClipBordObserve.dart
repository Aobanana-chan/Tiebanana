import 'package:flutter/material.dart';
import 'package:tiebanana/common/Util/AppUtil.dart';

///监视剪切板
class ClipBordObserver extends StatefulWidget {
  final Widget child;
  const ClipBordObserver({Key? key, required this.child}) : super(key: key);

  @override
  State<ClipBordObserver> createState() => _ClipBordObserverState();
}

class _ClipBordObserverState extends State<ClipBordObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppUtil.observClipBord(mounted, context, state);
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
