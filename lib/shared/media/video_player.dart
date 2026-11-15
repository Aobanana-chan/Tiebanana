import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:tiebanana/app/navigation/app_route_observer.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/shared/media/player_system_utils.dart';
import 'package:tiebanana/shared/media/video_fullscreen_route.dart';
import 'package:tiebanana/shared/media/video_source_url.dart';
import 'package:tiebanana/shared/theme/tiebanana_palette.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 控件固定叠在暗色遮罩上，与应用当前的亮暗模式无关。
Color accentOnBlack() =>
    TiebananaPalette.dark(seedOf(Global.setting.theme)).primary;

/// 视频元数据到达前的兜底比例。
const double kVideoFallbackAspectRatio = 16 / 9;

/// 卡片画面的圆角。进出全屏时飞行中的画面沿用这个圆角，落位后消失。
const double kVideoCornerRadius = 16;

/// 起播前（还没拿到时长）用封面盖住黑屏，开始播放后交给画面本身。
bool _showVideoCover(bool playing, Duration duration) =>
    !playing && duration == Duration.zero;

/// 诊断信息不展示视频地址中的签名参数。
String redactVideoDiagnostic(String message) => message.replaceAllMapped(
      RegExp(r'https?://[^\s]+'),
      (match) => match[0]!.split('?').first,
    );

/// 由像素尺寸得到画面比例；尺寸未知或非法时返回 null。
double? videoAspectRatioOf(int? width, int? height) {
  if (width == null || height == null || width <= 0 || height <= 0) {
    return null;
  }
  return width / height;
}

/// 把任意来源的比例限制在可排版范围内。
double normalizeVideoAspectRatio(double? ratio) {
  if (ratio == null || !ratio.isFinite || ratio <= 0) {
    return kVideoFallbackAspectRatio;
  }
  return ratio.clamp(9 / 21, 21 / 9);
}

/// 最近播放位置。列表回收播放器后重新创建时，用这里的位置续播。
final Map<String, Duration> _resumePositions = <String, Duration>{};
const int _resumePositionsLimit = 24;

void _rememberPosition(String url, Duration position) {
  if (position <= Duration.zero) return;
  _resumePositions[url] = position;
  while (_resumePositions.length > _resumePositionsLimit) {
    _resumePositions.remove(_resumePositions.keys.first);
  }
}

/// 视频中央的播放 / 暂停 / 重播按钮。
///
/// 叠在封面或画面上，因此始终使用暗色遮罩派生的配色：
/// 播放态是主题色渐变实心圆，暂停态是半透明玻璃圆，外圈带细描边和投影。
class VideoPlayButton extends StatelessWidget {
  const VideoPlayButton({
    super.key,
    this.onPressed,
    this.icon = Icons.play_arrow_rounded,
    this.label = '播放',
    this.size = 56,
    this.filled = true,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final double size;

  /// 是否使用主题色实心填充；暂停态使用半透明玻璃。
  final bool filled;

  @override
  Widget build(BuildContext context) {
    // 独立组件测试可能用裸 ThemeData，故对令牌缺失做兜底。
    final TiebananaTokens? tokens =
        Theme.of(context).extension<TiebananaTokens>();
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color accent = tokens?.accentFill ?? scheme.primary;
    final Color foreground =
        filled ? (tokens?.accentOn ?? scheme.onPrimary) : Colors.white;
    final double inner = size * .78;
    final Widget circle = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .11),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: .32),
        border: Border.all(color: Colors.white.withValues(alpha: .24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .38),
            blurRadius: size * .34,
            offset: Offset(0, size * .08),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: filled
                ? [Color.lerp(accent, Colors.white, .16)!, accent]
                : [
                    Colors.white.withValues(alpha: .22),
                    Colors.white.withValues(alpha: .06),
                  ],
          ),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: .42),
                    blurRadius: size * .18,
                  ),
                ]
              : null,
        ),
        child: Transform.translate(
          // 播放三角形视觉重心偏左，向右挪一点才像居中。
          offset: Offset(icon == Icons.play_arrow_rounded ? size * .025 : 0, 0),
          child: Icon(icon, size: inner * .62, color: foreground),
        ),
      ),
    );

    final Widget semantic = Semantics(
      button: onPressed != null,
      label: label,
      child: circle,
    );
    if (onPressed == null) return semantic;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: semantic,
      ),
    );
  }
}

/// 帖子内的视频卡片：按可用宽度布局。
class VideoPlayer extends StatefulWidget {
  const VideoPlayer(
      {super.key,
      this.cover,
      required this.url,
      this.autoplay = false,
      this.aspectRatio});

  final String? cover;
  final String url;

  /// 播放器元数据到达前的画面比例。传 null 时先用 16:9，
  /// 起播后再按实际宽高自动修正。
  final double? aspectRatio;

  /// 挂载后立即起播。列表预览卡片用：用户点封面这一步本身就是「播放」，
  /// 不应再让他点一次中央按钮。
  final bool autoplay;

  @override
  State<VideoPlayer> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoPlayer>
    with WidgetsBindingObserver, RouteAware {
  static final Set<_VideoScreenState> _activePlayers = {};
  static Future<void> _wakelockUpdate = Future<void>.value();

  final Player player = Player(
    configuration: const PlayerConfiguration(logLevel: MPVLogLevel.debug),
  );
  late final VideoController videoController = VideoController(player);
  StreamSubscription<bool>? _playingSubs;
  StreamSubscription<Duration>? _durationSubs;
  StreamSubscription<bool>? _completedSubs;
  StreamSubscription<int?>? _widthSubs;
  StreamSubscription<int?>? _heightSubs;
  ScrollPosition? _scrollPosition;
  ScrollNotificationObserverState? _scrollObserver;
  bool _visibilityCheckScheduled = false;
  bool _routeSubscribed = false;
  bool _playing = false;
  Duration _duration = Duration.zero;
  bool _isFullScreen = false;

  /// 卡片与全屏页共用同一个 Hero 标识；每个播放器独立，避免列表里重名。
  final Object _heroTag = Object();
  late double _aspectRatio = normalizeVideoAspectRatio(widget.aspectRatio);
  int? _videoWidth;
  int? _videoHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playingSubs = player.stream.playing.listen((playing) {
      if (!mounted) return;
      _updateWakelock(playing);
      setState(() => _playing = playing);
    });
    _durationSubs = player.stream.duration.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });
    _completedSubs = player.stream.completed.listen((completed) {
      // 完整看完的视频下次从头播放。
      if (completed) _resumePositions.remove(widget.url);
    });
    _widthSubs = player.stream.width.listen((width) {
      _videoWidth = width;
      _syncAspectRatio();
    });
    _heightSubs = player.stream.height.listen((height) {
      _videoHeight = height;
      _syncAspectRatio();
    });
  }

  @override
  void didUpdateWidget(covariant VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aspectRatio != widget.aspectRatio) _syncAspectRatio();
  }

  void _syncAspectRatio() {
    final next = normalizeVideoAspectRatio(
        videoAspectRatioOf(_videoWidth, _videoHeight) ?? widget.aspectRatio);
    if (next == _aspectRatio) return;
    if (mounted) {
      setState(() => _aspectRatio = next);
    } else {
      _aspectRatio = next;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observer = ScrollNotificationObserver.maybeOf(context);
    if (observer != _scrollObserver) {
      _scrollObserver?.removeListener(_handleScrollNotification);
      _scrollObserver = observer;
      _scrollObserver?.addListener(_handleScrollNotification);
    }
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _scrollPosition) {
      _scrollPosition?.removeListener(_scheduleVisibilityCheck);
      _scrollPosition = position;
      _scrollPosition?.addListener(_scheduleVisibilityCheck);
    }
    if (!_routeSubscribed) {
      final ModalRoute<void>? route = ModalRoute.of(context);
      if (route != null) {
        appRouteObserver.subscribe(this, route);
        _routeSubscribed = true;
      }
    }
    _scheduleVisibilityCheck();
  }

  void _handleScrollNotification(ScrollNotification notification) {
    _scheduleVisibilityCheck();
  }

  void _scheduleVisibilityCheck() {
    if (_visibilityCheckScheduled) return;
    _visibilityCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityCheckScheduled = false;
      if (mounted) _checkVisibility();
    });
  }

  /// 滚出可视区域或页面被上层路由盖住时暂停播放。
  void _checkVisibility() {
    if (!mounted || _isFullScreen) return;
    final ModalRoute<void>? route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      _pauseForLeavingView();
      return;
    }
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return;
    }
    final Size size = renderObject.size;
    if (size.isEmpty) return;
    final Rect rect = renderObject.localToGlobal(Offset.zero) & size;
    final Rect screen = Offset.zero & MediaQuery.sizeOf(context);
    final Rect visible = rect.intersect(screen);
    final double visibleArea = visible.width <= 0 || visible.height <= 0
        ? 0
        : visible.width * visible.height;
    if (visibleArea / (size.width * size.height) < .05) {
      _pauseForLeavingView();
    }
  }

  void _pauseForLeavingView() {
    _rememberPosition(widget.url, player.state.position);
    if (_playing) unawaited(player.pause());
  }

  @override
  void didPushNext() {
    // 全屏页是本播放器自己的子路由，这里保持播放。
    if (_isFullScreen) return;
    _pauseForLeavingView();
  }

  void _updateWakelock(bool playing) {
    if (playing) {
      _activePlayers.add(this);
    } else {
      _activePlayers.remove(this);
    }
    _wakelockUpdate = _wakelockUpdate.then((_) async {
      await WakelockPlus.toggle(enable: _activePlayers.isNotEmpty);
    }).catchError((Object error, StackTrace stack) {
      debugPrint('Unable to update video wakelock: $error');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _rememberPosition(widget.url, player.state.position);
      _updateWakelock(false);
      unawaited(player.pause());
    }
  }

  Future<void> _open() async {
    // 列表回收后重新创建的播放器从上次位置继续；正常首次播放时为零。
    final Duration resume = player.state.position > Duration.zero
        ? player.state.position
        : (_resumePositions[widget.url] ?? Duration.zero);
    await player.open(Media(videoSourceUrl(widget.url)), play: false);
    if (!mounted) return;
    if (resume > Duration.zero) {
      final Duration duration = player.state.duration;
      if (duration <= Duration.zero || resume < duration) {
        await player.seek(resume);
      }
    }
    await player.play();
  }

  Future<void> _enterFullScreen() async {
    if (_isFullScreen) return;
    setState(() => _isFullScreen = true);
    await Navigator.of(context).push<void>(VideoFullScreenRoute(
      builder: (_) => _FullScreenVideoPage(
        player: player,
        videoController: videoController,
        onPlay: _open,
        aspectRatio: _aspectRatio,
        heroTag: _heroTag,
        cover: widget.cover,
      ),
    ));
    if (mounted) setState(() => _isFullScreen = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_routeSubscribed) {
      appRouteObserver.unsubscribe(this);
      _routeSubscribed = false;
    }
    _scrollObserver?.removeListener(_handleScrollNotification);
    _scrollObserver = null;
    _scrollPosition?.removeListener(_scheduleVisibilityCheck);
    _scrollPosition = null;
    if (!player.state.completed) {
      _rememberPosition(widget.url, player.state.position);
    }
    _playingSubs?.cancel();
    _durationSubs?.cancel();
    _completedSubs?.cancel();
    _widthSubs?.cancel();
    _heightSubs?.cancel();
    unawaited(player.dispose());
    _updateWakelock(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(kVideoCornerRadius),
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 全屏页与本卡片共用同一个控制器，Hero 只搬运画面这一层：
              // 进出全屏时画面从卡片位置拉到整屏，而不是整页翻过去。
              Hero(
                tag: _heroTag,
                flightShuttleBuilder: _videoHeroShuttle,
                child: _VideoSurface(
                  controller: videoController,
                  cover: widget.cover,
                  showCover: _showVideoCover(_playing, _duration),
                ),
              ),
              VideoPlayerPanel(
                player: player,
                onPlay: _open,
                isFullScreen: false,
                // 由控制层统一处理自动起播与加载错误。
                autoplay:
                    widget.autoplay && player.state.playlist.medias.isEmpty,
                onFullScreen: _enterFullScreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 卡片和全屏页共用的画面层。
///
/// 两处共用同一个 [VideoController]，因此 Hero 不需要复制播放器：
/// 进出的动画就是这一层画面在放大 / 缩回。
class _VideoSurface extends StatelessWidget {
  const _VideoSurface({
    required this.controller,
    this.cover,
    this.showCover = false,
  });

  final VideoController controller;
  final String? cover;

  /// 起播前用封面盖住黑屏。
  final bool showCover;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 唤醒锁由卡片统一管理（见 _VideoScreenState._updateWakelock）；
        // 飞行中画面层会短暂存在两份，不再各自申请。
        Video(
          controller: controller,
          controls: NoVideoControls,
          wakelock: false,
        ),
        if (showCover && cover != null)
          IgnorePointer(
            child: Image.network(
              cover!,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) =>
                  const ColoredBox(color: Colors.black),
            ),
          ),
      ],
    );
  }
}

/// 进出全屏时的飞行体。
///
/// 沿用出发侧的同一份画面（推进时是卡片上的封面 / 视频，退出时是全屏画面），
/// 圆角只属于卡片，随放大一起消失，退出时再长回来。
Widget _videoHeroShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) => ClipRRect(
      borderRadius:
          BorderRadius.circular(kVideoCornerRadius * (1 - animation.value)),
      child: child,
    ),
    child: (fromHeroContext.widget as Hero).child,
  );
}

/// 内嵌和全屏共用的自适应控制层。所有控件都是覆盖层，不挤占画面高度。
class VideoPlayerPanel extends StatefulWidget {
  const VideoPlayerPanel({
    super.key,
    required this.player,
    required this.onPlay,
    this.pageContent,
    required this.isFullScreen,
    this.autoplay = false,
    this.onFullScreen,
  });

  final Player player;
  final BuildContext? pageContent;
  final Future<void> Function() onPlay;
  final bool isFullScreen;

  /// 首帧后直接打开媒体，用于列表预览卡片的「点一下即播」。
  final bool autoplay;
  final VoidCallback? onFullScreen;

  @override
  State<VideoPlayerPanel> createState() => _VideoPlayerPanelState();
}

class _VideoPlayerPanelState extends State<VideoPlayerPanel> {
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _hideTimer;
  bool _controlsVisible = false;
  bool _opening = false;
  bool _started = false;
  bool _playing = false;
  bool _completed = false;
  bool _buffering = false;
  bool _menuOpen = false;
  String _error = '';
  final List<String> _diagnosticLogs = [];
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Duration _buffer = Duration.zero;
  double _speed = 1;
  double? _seekValue;
  double? _dragStartX;
  Duration _dragStartPosition = Duration.zero;
  Duration? _dragPosition;
  double? _systemValue;
  bool _brightnessGesture = false;
  bool _verticalDragging = false;
  int _gestureGeneration = 0;

  Player get player => widget.player;
  bool get _loading => _opening || (_started && _buffering);
  bool get _showCenter =>
      !_started || !_playing || _controlsVisible || _loading;

  @override
  void initState() {
    super.initState();
    final state = player.state;
    _duration = state.duration;
    _position = state.position;
    _buffer = state.buffer;
    _speed = state.rate;
    _playing = state.playing;
    _completed = state.completed;
    _buffering = state.buffering;
    _started = state.playlist.medias.isNotEmpty;
    _subscriptions.addAll([
      player.stream.log.listen((log) {
        // 保留网络上下文，排除渲染器的大量格式枚举；只驻留内存。
        if (log.prefix.startsWith('libmpv_render') &&
            log.level != 'error' &&
            log.level != 'warn') {
          return;
        }
        _diagnosticLogs.add(
            redactVideoDiagnostic('[${log.prefix}/${log.level}] ${log.text}'));
        if (_diagnosticLogs.length > 120) _diagnosticLogs.removeAt(0);
      }),
      player.stream.position.listen((value) {
        if (mounted) setState(() => _position = value);
      }),
      player.stream.duration.listen((value) {
        if (mounted) setState(() => _duration = value);
      }),
      player.stream.buffer.listen((value) {
        if (mounted) setState(() => _buffer = value);
      }),
      player.stream.buffering.listen((value) {
        if (mounted) setState(() => _buffering = value);
      }),
      player.stream.rate.listen((value) {
        if (mounted) setState(() => _speed = value);
      }),
      player.stream.playing.listen((value) {
        if (!mounted) return;
        setState(() {
          _playing = value;
          if (value) {
            _error = '';
            _started = true;
            _completed = false;
          }
        });
        _scheduleHide();
      }),
      player.stream.completed.listen((value) {
        if (!mounted) return;
        setState(() {
          _completed = value;
          if (value) _playing = false;
        });
      }),
      player.stream.error.listen((value) {
        if (mounted && value.isNotEmpty) setState(() => _error = value);
      }),
    ]);
    if (widget.autoplay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_open());
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!_playing || !_controlsVisible || _menuOpen || _seekValue != null) {
      return;
    }
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    _scheduleHide();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _open() async {
    if (_opening) return;
    setState(() {
      _error = '';
      _opening = true;
      _started = true;
      _completed = false;
      _buffering = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _buffer = Duration.zero;
    });
    await _run(widget.onPlay);
    if (mounted) setState(() => _opening = false);
  }

  Future<void> _playOrPause() async {
    if (_opening) return;
    if (!_started || _error.isNotEmpty) return _open();
    await _run(() async {
      if (_playing && !_completed) {
        await player.pause();
      } else {
        if (_completed) await player.seek(Duration.zero);
        await player.play();
      }
    });
  }

  Future<void> _seek(double milliseconds) async {
    final position = Duration(milliseconds: milliseconds.round());
    setState(() {
      _position = position;
      _seekValue = null;
    });
    await _run(() => player.seek(position));
    _scheduleHide();
  }

  void _horizontalStart(DragStartDetails details) {
    if (!_started || _duration == Duration.zero || _error.isNotEmpty) return;
    _hideTimer?.cancel();
    _dragStartX = details.localPosition.dx;
    _dragStartPosition = _position;
  }

  void _horizontalUpdate(DragUpdateDetails details) {
    if (_dragStartX == null) return;
    final width = context.size?.width ?? 1;
    final delta = (details.localPosition.dx - _dragStartX!) / width;
    setState(() {
      _dragPosition = Duration(
        milliseconds: (_dragStartPosition.inMilliseconds +
                delta * _duration.inMilliseconds)
            .clamp(0, _duration.inMilliseconds)
            .round(),
      );
    });
  }

  void _horizontalEnd(DragEndDetails details) {
    final position = _dragPosition;
    setState(() {
      _dragPosition = null;
      _dragStartX = null;
    });
    if (position != null) unawaited(_seek(position.inMilliseconds.toDouble()));
  }

  Future<void> _verticalStart(DragStartDetails details) async {
    final generation = ++_gestureGeneration;
    _verticalDragging = true;
    _brightnessGesture =
        details.localPosition.dx < (context.size?.width ?? 0) / 2;
    await _run(() async {
      var value = _brightnessGesture
          ? await PlayerSystemUtils.getBrightness()
          : await PlayerSystemUtils.getSystemVolume();
      if (!mounted || !_verticalDragging || generation != _gestureGeneration) {
        return;
      }
      if (value < 0) value = 0.5;
      setState(() => _systemValue = value.clamp(0, 1));
    });
  }

  void _verticalUpdate(DragUpdateDetails details) {
    if (_systemValue == null) return;
    final height = math.max(context.size?.height ?? 1, 1);
    final value = (_systemValue! - details.delta.dy / height).clamp(0.0, 1.0);
    setState(() => _systemValue = value);
    unawaited(_run(() => _brightnessGesture
        ? PlayerSystemUtils.setBrightness(value)
        : PlayerSystemUtils.setSystemVolume(value)));
  }

  void _verticalEnd() {
    _verticalDragging = false;
    _gestureGeneration++;
    setState(() => _systemValue = null);
  }

  String _time(Duration value) {
    final seconds = math.max(value.inSeconds, 0);
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }

  Widget _centerButton() {
    if (_loading) {
      return const SizedBox.square(
        dimension: 32,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
    }
    final bool showPlay = _completed || !_playing;
    return VideoPlayButton(
      key: const ValueKey('video-center-play'),
      onPressed: _playOrPause,
      icon: _completed
          ? Icons.replay_rounded
          : (_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
      label: _completed ? '重新播放' : (_playing ? '暂停' : '播放'),
      filled: showPlay,
      size: widget.isFullScreen ? 64 : 56,
    );
  }

  Widget _speedMenu() {
    return PopupMenuButton<double>(
      tooltip: '播放速度',
      initialValue: _speed,
      color: const Color(0xFF242832),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onOpened: () {
        _menuOpen = true;
        _hideTimer?.cancel();
      },
      onCanceled: () {
        _menuOpen = false;
        _scheduleHide();
      },
      onSelected: (value) {
        _menuOpen = false;
        unawaited(_run(() => player.setRate(value)));
        _scheduleHide();
      },
      itemBuilder: (_) => [
        for (final rate in [0.5, 1.0, 1.25, 1.5, 2.0])
          PopupMenuItem(
            value: rate,
            child: Text(
              '${rate.toStringAsFixed(rate == 1.25 ? 2 : 1)} X',
              style: TextStyle(
                color: rate == _speed ? accentOnBlack() : Colors.white,
                fontSize: 14,
              ),
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text('${_speed.toStringAsFixed(_speed == 1.25 ? 2 : 1)} X'),
      ),
    );
  }

  Widget _bottomBar() {
    final maximum = math.max(_duration.inMilliseconds.toDouble(), 1.0);
    final value = (_seekValue ??
            _dragPosition?.inMilliseconds.toDouble() ??
            _position.inMilliseconds.toDouble())
        .clamp(0.0, maximum);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xCC000000)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 4, 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 16,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  activeTrackColor: accentOnBlack(),
                  inactiveTrackColor: Colors.white24,
                  secondaryActiveTrackColor: Colors.white54,
                  thumbColor: Colors.white,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  value: value,
                  secondaryTrackValue: math
                      .max(value, _buffer.inMilliseconds.toDouble())
                      .clamp(0.0, maximum),
                  max: maximum,
                  onChanged: _duration == Duration.zero
                      ? null
                      : (value) {
                          _hideTimer?.cancel();
                          setState(() => _seekValue = value);
                        },
                  onChangeEnd: _duration == Duration.zero ? null : _seek,
                ),
              ),
            ),
            Row(
              children: [
                const SizedBox(width: 6),
                Flexible(
                  fit: FlexFit.tight,
                  child: Text(
                    '${_time(Duration(milliseconds: value.round()))} / ${_time(_duration)}',
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
                _speedMenu(),
                IconButton(
                  tooltip: widget.isFullScreen ? '退出全屏' : '全屏',
                  onPressed: widget.onFullScreen,
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints.tightFor(width: 36, height: 32),
                  padding: const EdgeInsets.all(4),
                  color: Colors.white,
                  icon: Icon(widget.isFullScreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedback() {
    final seeking = _dragPosition != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xD9000000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          seeking
              ? '${_time(_dragPosition!)} / ${_time(_duration)}'
              : '${_brightnessGesture ? '亮度' : '音量'}  ${((_systemValue ?? 0) * 100).round()}%',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  Widget _errorPanel() {
    // 可滚动而非固定高度，支持窄卡片和放大字号。
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('视频暂时无法播放',
                style: TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _open,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white12,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('点击重试'),
            ),
            TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) {
                  final details = [
                    redactVideoDiagnostic(_error),
                    if (_diagnosticLogs.isNotEmpty) ...[
                      '',
                      '底层播放日志：',
                      ..._diagnosticLogs,
                    ],
                  ].join('\n');
                  return AlertDialog(
                    title: const Text('视频播放错误详情'),
                    content: SingleChildScrollView(
                      child: SelectableText(details),
                    ),
                    actions: [
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: details));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已复制全部错误详情')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('复制全部'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('关闭'),
                      ),
                    ],
                  );
                },
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('错误详情'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(color: Colors.white, fontSize: 12),
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          onHorizontalDragStart: _horizontalStart,
          onHorizontalDragUpdate: _horizontalUpdate,
          onHorizontalDragEnd: _horizontalEnd,
          onHorizontalDragCancel: () => setState(() {
            _dragStartX = null;
            _dragPosition = null;
          }),
          // 内嵌视频不拦截帖子上下滚动。
          onVerticalDragStart: widget.isFullScreen ? _verticalStart : null,
          onVerticalDragUpdate: widget.isFullScreen ? _verticalUpdate : null,
          onVerticalDragEnd: widget.isFullScreen ? (_) => _verticalEnd() : null,
          onVerticalDragCancel: widget.isFullScreen ? _verticalEnd : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_error.isNotEmpty) ...[
                const ColoredBox(color: Color(0xB3000000)),
                _errorPanel(),
              ] else ...[
                if (!_started || !_playing)
                  const IgnorePointer(
                    child: ColoredBox(color: Color(0x26000000)),
                  ),
                if (_showCenter) Center(child: _centerButton()),
                if (_controlsVisible)
                  Positioned(left: 0, right: 0, bottom: 0, child: _bottomBar())
                else if (_started && _duration > Duration.zero)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      value:
                          (_position.inMilliseconds / _duration.inMilliseconds)
                              .clamp(0, 1),
                      minHeight: 2,
                      color: accentOnBlack(),
                      backgroundColor: Colors.white24,
                    ),
                  ),
                if (_dragPosition != null || _systemValue != null)
                  Center(child: IgnorePointer(child: _feedback())),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenVideoPage extends StatefulWidget {
  const _FullScreenVideoPage({
    required this.player,
    required this.videoController,
    required this.onPlay,
    required this.aspectRatio,
    required this.heroTag,
    this.cover,
  });

  final Player player;
  final VideoController videoController;
  final Future<void> Function() onPlay;
  final double aspectRatio;

  /// 与卡片上的 Hero 对应，画面从这里启动 / 回到这里。
  final Object heroTag;
  final String? cover;

  @override
  State<_FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<_FullScreenVideoPage> {
  StreamSubscription<int?>? _widthSubs;
  StreamSubscription<int?>? _heightSubs;
  StreamSubscription<bool>? _playingSubs;
  StreamSubscription<Duration>? _durationSubs;
  int? _width;
  int? _height;
  bool _playing = false;
  Duration _duration = Duration.zero;
  bool _immersive = false;
  ModalRoute<void>? _route;
  late double _aspectRatio = _currentAspectRatio();
  late bool _landscape = _aspectRatio > 1;

  /// 起播前用封面盖住黑屏，和卡片上的表现保持一致。
  bool get _showCover => _showVideoCover(_playing, _duration);

  double _currentAspectRatio() => normalizeVideoAspectRatio(videoAspectRatioOf(
          _width ?? widget.player.state.width,
          _height ?? widget.player.state.height) ??
      widget.aspectRatio);

  @override
  void initState() {
    super.initState();
    final state = widget.player.state;
    _playing = state.playing;
    _duration = state.duration;
    _widthSubs = widget.player.stream.width.listen((width) {
      _width = width;
      _syncAspectRatio();
    });
    _heightSubs = widget.player.stream.height.listen((height) {
      _height = height;
      _syncAspectRatio();
    });
    _playingSubs = widget.player.stream.playing.listen((playing) {
      if (mounted) setState(() => _playing = playing);
    });
    _durationSubs = widget.player.stream.duration.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<void>? route = ModalRoute.of<void>(context);
    if (route != _route) {
      _route?.animation?.removeStatusListener(_handleRouteStatus);
      _route = route;
      _route?.animation?.addStatusListener(_handleRouteStatus);
    }
    // 路由已处于完成状态（如重建）时不必再等动画结束。
    if (_route?.animation?.status == AnimationStatus.completed) {
      _enterImmersive();
    }
  }

  void _handleRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _enterImmersive();
  }

  /// 等放大动画落位后再进入沉浸式并转屏。
  ///
  /// 转屏会改变可用尺寸，提前做会让画面在飞行途中跳一下。
  void _enterImmersive() {
    if (_immersive || !mounted) return;
    _immersive = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _applyOrientation();
  }

  /// 横屏视频才转横屏，竖屏 / 方形视频保持竖屏。
  void _syncAspectRatio() {
    final double ratio = _currentAspectRatio();
    final bool landscape = ratio > 1;
    if (ratio == _aspectRatio && landscape == _landscape) return;
    _aspectRatio = ratio;
    _landscape = landscape;
    _applyOrientation();
    if (mounted) setState(() {});
  }

  void _applyOrientation() {
    if (!_immersive) return;
    SystemChrome.setPreferredOrientations(_landscape
        ? const [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]
        : const [DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _widthSubs?.cancel();
    _heightSubs?.cancel();
    _playingSubs?.cancel();
    _durationSubs?.cancel();
    _route?.animation?.removeStatusListener(_handleRouteStatus);
    if (_immersive) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 画面按实际比例居中：这里同时是 Hero 放大动画的终点。
          Center(
            child: AspectRatio(
              aspectRatio: _aspectRatio,
              child: Hero(
                tag: widget.heroTag,
                flightShuttleBuilder: _videoHeroShuttle,
                child: _VideoSurface(
                  controller: widget.videoController,
                  cover: widget.cover,
                  showCover: _showCover,
                ),
              ),
            ),
          ),
          SafeArea(
            child: VideoPlayerPanel(
              player: widget.player,
              onPlay: widget.onPlay,
              isFullScreen: true,
              onFullScreen: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: SafeArea(
              child: IconButton.filledTonal(
                tooltip: '返回',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
