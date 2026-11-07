import 'package:flutter/material.dart';
import 'package:tiebanana/app/navigation/link_router.dart';

///监视剪切板
class ClipBordObserver extends StatefulWidget {
  final Widget child;
  const ClipBordObserver({super.key, required this.child});

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
    AppUtil.observClipBord(context, state);
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
