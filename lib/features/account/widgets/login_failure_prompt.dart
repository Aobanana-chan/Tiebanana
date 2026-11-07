import 'package:flutter/material.dart';
import 'package:tiebanana/features/account/state/login_failure.dart';

class LoginFailurePrompt extends StatefulWidget {
  const LoginFailurePrompt({
    super.key,
    required this.controller,
    required this.navigatorKey,
    required this.onRelogin,
    required this.child,
  });

  final LoginFailureController controller;
  final GlobalKey<NavigatorState> navigatorKey;
  final Future<void> Function() onRelogin;
  final Widget child;

  @override
  State<LoginFailurePrompt> createState() => _LoginFailurePromptState();
}

class _LoginFailurePromptState extends State<LoginFailurePrompt> {
  bool _showing = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_schedule);
    _schedule();
  }

  void _schedule() {
    if (_showing || _scheduled || widget.controller.pending == null) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) _show();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _show() async {
    final failure = widget.controller.pending;
    final navigator = widget.navigatorKey.currentState;
    if (_showing || failure == null || navigator == null) return;
    widget.controller.acknowledge();
    _showing = true;
    try {
      final relogin = await showDialog<bool>(
        context: navigator.overlay!.context,
        builder: (context) => AlertDialog(
          title: const Text('登录失败'),
          content: Text(
            '当前账号未能完成客户端登录，部分功能暂时不可用。是否重新登录？'
            '\n\n错误码：${failure.code}\n${failure.message}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('暂不登录'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('重新登录'),
            ),
          ],
        ),
      );
      if (relogin == true && mounted) await widget.onRelogin();
    } finally {
      _showing = false;
      if (mounted) _schedule();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_schedule);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
