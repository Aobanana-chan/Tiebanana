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
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) {
      return;
    }
    // 每个命名路由外层都包了一份本组件。一次恢复事件会发给所有页面，
    // 只让最上层页面检查剪贴板，否则会连续弹出多个跳转窗口。
    final ModalRoute<Object?>? route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) {
      return;
    }
    AppUtil.observClipBord(context, state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
