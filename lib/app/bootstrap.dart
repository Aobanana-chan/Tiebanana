import 'package:flutter/material.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:tiebanana/features/diagnostics/pages/diagnostics_page.dart';
import 'package:tiebanana/features/splash/splash_page.dart';
import 'package:tiebanana/features/splash/splash_timeline.dart';
import 'package:tiebanana/features/splash/tiebanana_glyph.dart';

/// `Global.init()` 是否已经完成。
///
/// 开屏与初始化**并行**：先挂开屏，初始化在同一个 zone 里运行，
/// 完成后把这里置 true，开屏进入交接。启动期全程由开屏动画覆盖。
class BootState extends ValueNotifier<bool> {
  BootState() : super(false);

  Object? error;
  bool _initializing = false;
  bool _canSkipSplash = false;

  /// 本次启动是否允许跳过；首次完整播放后，下次启动才开启。
  bool get canSkipSplash => _canSkipSplash;

  void setSplashSkippable(bool value) {
    if (_canSkipSplash == value) return;
    _canSkipSplash = value;
    notifyListeners();
  }

  /// 每次只执行一次初始化，失败后等待用户手动重试。
  Future<void> initialize(Future<void> Function() initialize) async {
    if (_initializing || value) return;
    _initializing = true;
    error = null;
    notifyListeners();
    try {
      await initialize();
      markReady();
    } catch (e, stackTrace) {
      AppLog.shared.error('startup.failed', e, stackTrace);
      error = e;
      debugPrint('应用初始化失败：$e');
      debugPrintStack(stackTrace: stackTrace);
      notifyListeners();
    } finally {
      _initializing = false;
    }
  }

  void markReady() => value = true;
}

/// 启动壳：底下是真正的 App，上面盖一层开屏。
///
/// 两层**同时在树里**：首屏在开屏覆盖期间完成构建并开始拉数据，
/// 交接时淡出开屏即可显示内容。
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({
    super.key,
    required this.boot,
    required this.app,
    this.onRetry,
    this.onSplashCompleted,
  });

  final BootState boot;

  /// 真正的 App，由外部传入以解除与 `main.dart` 的循环依赖。
  final Widget app;
  final VoidCallback? onRetry;
  final VoidCallback? onSplashCompleted;

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp>
    with TickerProviderStateMixin {
  /// 前四拍：0 → 落定 / 字标合上。
  late final AnimationController _intro;

  /// 交接：开屏推走 + 首屏浮起。
  late final AnimationController _handoff;

  bool _leaving = false;
  bool _splashGone = false;
  bool _precached = false;

  /// 当前的设计毫秒（0–3300）。
  double get _t =>
      _intro.value * (SplashTiming.introTo - SplashTiming.introFrom) +
      _handoff.value * (SplashTiming.handoffTo - SplashTiming.handoffFrom);

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: SplashTiming.introDuration,
    );
    _handoff = AnimationController(
      vsync: this,
      duration: SplashTiming.handoffDuration,
    );
    _intro.addListener(_repaint);
    _handoff.addListener(_repaint);
    widget.boot.addListener(_onBootChanged);
    _intro.forward().whenComplete(_maybeLeave);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    // 香蕉要到 1.0s 左右才出现，但那时再解码会闪一下。这里提前解好。
    // （放在 didChangeDependencies，因为 precacheImage 需要读取 MediaQuery。）
    for (final String asset in <String>[
      TiebananaGlyph.bananaAsset,
      TiebananaGlyph.leafAsset,
    ]) {
      precacheImage(AssetImage(asset), context);
    }
  }

  @override
  void dispose() {
    widget.boot.removeListener(_onBootChanged);
    _intro.dispose();
    _handoff.dispose();
    super.dispose();
  }

  void _repaint() => setState(() {});

  void _onBootChanged() {
    if (!mounted) return;
    setState(() {});
    _maybeLeave();
  }

  void _skipIntro() {
    final double target = SplashTiming.skipTo / SplashTiming.introTo;
    // 跳过前段时从当前进度继续；交接和错误页上的点击不改变时间轴。
    if (!widget.boot.canSkipSplash ||
        widget.boot.error != null ||
        _leaving ||
        _intro.value >= target) {
      return;
    }
    // forward(from:) 保留剩余段落的原速，落定波纹和字标收尾仍完整播放。
    _intro.forward(from: target).whenComplete(_maybeLeave);
  }

  /// 四拍走完 **且** 初始化完成，才允许进入交接。
  ///
  /// 初始化更慢时，开屏就停在落定那一帧、靠底部的加载点说明「还在初始化」；
  /// 首次启动完整播放；后续启动可点击跳到落定波纹，再播完收尾。
  void _maybeLeave() {
    if (!mounted || _leaving || !widget.boot.value || !_intro.isCompleted) {
      return;
    }
    _leaving = true;
    _handoff.forward().whenComplete(() {
      if (mounted) {
        setState(() => _splashGone = true);
        widget.onSplashCompleted?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double t = _t;
    // 首屏自下方浮起（概念图里的 translateY 28 → 0）。
    // 不做整屏淡入 —— 开屏本来就在淡出，再叠一层全屏 Opacity 只会多吃一次离屏缓冲。
    final double rise = ease(
        t, SplashBeats.out.from - 200, SplashBeats.out.to, SplashCurves.out);

    return Stack(
      // 这里是 runApp 的根，上面没有 MaterialApp/WidgetsApp，
      // 这里使用显式 Alignment.topLeft，避免依赖 Directionality。
      alignment: Alignment.topLeft,
      fit: StackFit.expand,
      children: <Widget>[
        if (widget.boot.value)
          // 保持同一 widget 结构，交接时复用已建好的首屏。
          Transform.translate(
            offset: Offset(0, 28 * (1 - rise)),
            child: widget.app,
          ),
        if (!_splashGone)
          // 开屏要自己的 MaterialApp：它需要 MediaQuery / Directionality，
          // 而这两样来自 `App`，兄弟节点继承不到。
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: widget.boot.error == null
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _skipIntro,
                    child: SplashPage(t: t),
                  )
                : Scaffold(
                    body: SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text('启动失败，请重试'),
                              const SizedBox(height: 12),
                              SelectableText('${widget.boot.error}'),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: widget.onRetry,
                                child: const Text('重试'),
                              ),
                              Builder(
                                  builder: (context) => TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const DiagnosticsPage()),
                                        ),
                                        child: const Text('导出诊断日志'),
                                      )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}
