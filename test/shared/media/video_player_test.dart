import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/shared/media/video_player.dart';

class _FakePlayer extends PlatformPlayer {
  _FakePlayer() : super(configuration: const PlayerConfiguration());

  int opens = 0;
  int plays = 0;
  int pauses = 0;
  final List<double> rates = [];
  final List<Duration> seeks = [];
  Object? openError;
  Completer<void>? pendingOpen;

  void playing(bool value) {
    state = state.copyWith(playing: value);
    playingController.add(value);
  }

  void position(Duration value) => positionController.add(value);

  void error(String message) => errorController.add(message);

  @override
  Future<void> open(Playable playable, {bool play = true}) async {
    opens++;
    if (pendingOpen != null) await pendingOpen!.future;
    if (openError != null) throw openError!;
    state = state.copyWith(
      playlist: Playlist([playable as Media]),
      duration: const Duration(seconds: 60),
      completed: false,
    );
    durationController.add(state.duration);
    completedController.add(false);
    playing(play);
  }

  @override
  Future<void> play() async {
    plays++;
    playing(true);
  }

  @override
  Future<void> pause() async {
    pauses++;
    playing(false);
  }

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
    state = state.copyWith(position: position);
    positionController.add(position);
  }

  @override
  Future<void> setRate(double rate) async {
    rates.add(rate);
    state = state.copyWith(rate: rate);
    rateController.add(rate);
  }
}

void main() {
  late _FakePlayer native;
  late Player player;

  setUp(() {
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    native = _FakePlayer();
    player = Player(platformPlayer: native);
  });

  Future<void> mount(WidgetTester tester,
      {bool fullScreen = false,
      bool autoplay = false,
      double width = 600,
      double height = 350,
      double textScale = 1}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            padding: const EdgeInsets.only(top: 32),
            textScaler: TextScaler.linear(textScale),
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: VideoPlayerPanel(
              player: player,
              onPlay: () => player.open(Media('https://example.com/video.mp4')),
              isFullScreen: fullScreen,
              autoplay: autoplay,
            ),
          ),
        ),
      ),
    ));
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await player.dispose();
  }

  test('画面比例工具：横竖屏与异常尺寸', () {
    expect(videoAspectRatioOf(1920, 1080), closeTo(16 / 9, .001));
    expect(videoAspectRatioOf(1080, 1920), closeTo(9 / 16, .001));
    expect(videoAspectRatioOf(0, 1080), isNull);
    expect(videoAspectRatioOf(null, 1080), isNull);
    expect(normalizeVideoAspectRatio(null), 16 / 9);
    expect(normalizeVideoAspectRatio(0), 16 / 9);
    expect(normalizeVideoAspectRatio(double.infinity), 16 / 9);
    expect(normalizeVideoAspectRatio(.01), 9 / 21);
    expect(normalizeVideoAspectRatio(99), 21 / 9);
  });

  testWidgets('首次点击才打开媒体，重复点击不会重复加载', (tester) async {
    await mount(tester);
    expect(native.opens, 0);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    native.pendingOpen = Completer<void>();
    await tester.tap(find.byKey(const ValueKey('video-center-play')));
    await tester.pump();
    expect(native.opens, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tapAt(const Offset(300, 175));
    await tester.pump();
    await tester.tapAt(const Offset(300, 175));
    await tester.pump();
    expect(native.opens, 1);

    native.pendingOpen!.complete();
    await tester.pumpAndSettle();
    expect(native.state.playing, isTrue);
    await unmount(tester);
  });

  testWidgets('自动起播只打开一次媒体', (tester) async {
    await mount(tester, autoplay: true);
    await tester.pump();
    expect(native.opens, 1);

    await tester.tapAt(const Offset(300, 175));
    await tester.pump();
    expect(native.opens, 1);
    expect(native.state.playing, isTrue);
    await unmount(tester);
  });

  testWidgets('进度事件不会把暂停误判为播放，继续不重新打开', (tester) async {
    await native.open(Media('https://example.com/video.mp4'), play: false);
    await mount(tester);
    native.position(const Duration(seconds: 5));
    await tester.pump();
    expect(find.byIcon(Icons.pause_rounded), findsNothing);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('video-center-play')));
    await tester.pumpAndSettle();
    expect(native.plays, 1);
    expect(native.opens, 1);

    await tester.tap(find.byKey(const ValueKey('video-center-play')));
    await tester.pumpAndSettle();
    expect(native.pauses, 1);
    expect(find.byIcon(Icons.pause_rounded), findsNothing);
    await unmount(tester);
  });

  for (final fullScreen in [false, true]) {
    testWidgets('打开失败后可重新加载（全屏=$fullScreen）', (tester) async {
      native.openError = StateError('load failed');
      await mount(tester, fullScreen: fullScreen);
      await tester.tap(find.byKey(const ValueKey('video-center-play')));
      await tester.pumpAndSettle();
      expect(find.text('点击重试'), findsOneWidget);

      native.openError = null;
      await tester.tap(find.text('点击重试'));
      await tester.pumpAndSettle();
      expect(native.opens, 2);
      expect(find.text('点击重试'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await unmount(tester);
    });
  }

  testWidgets('错误流触发失败提示，重试清除错误', (tester) async {
    await native.open(Media('https://example.com/video.mp4'));
    await mount(tester);
    native.playing(false);
    native.error('network error');
    await tester.pumpAndSettle();
    expect(find.text('点击重试'), findsOneWidget);
    await tester.tap(find.text('点击重试'));
    await tester.pumpAndSettle();
    expect(native.opens, 2);
    expect(find.text('点击重试'), findsNothing);
    await unmount(tester);
  });

  testWidgets('播放结束后从头重播，不重复打开媒体', (tester) async {
    await native.open(Media('https://example.com/video.mp4'), play: false);
    native.state = native.state.copyWith(completed: true);
    await mount(tester);
    await tester.tap(find.byKey(const ValueKey('video-center-play')));
    await tester.pumpAndSettle();
    expect(native.seeks, [Duration.zero]);
    expect(native.plays, 1);
    expect(native.opens, 1);
    await unmount(tester);
  });

  testWidgets('切换控制层后保留暂停、进度和倍速状态', (tester) async {
    await native.open(Media('https://example.com/video.mp4'), play: false);
    native.state = native.state.copyWith(
      position: const Duration(seconds: 12),
      rate: 1.5,
    );
    await mount(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await mount(tester, fullScreen: true);
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    expect(find.text('00:12 / 01:00'), findsOneWidget);
    expect(find.text('1.5 X'), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsNothing);
    expect(native.opens, 1);
    await unmount(tester);
  });

  testWidgets('加载期间退出后异步完成不会更新已销毁的控制层', (tester) async {
    native.pendingOpen = Completer<void>();
    await mount(tester);
    await tester.tap(find.byKey(const ValueKey('video-center-play')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    native.pendingOpen!.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
    await player.dispose();
  });

  testWidgets('窄视频卡片和放大字号不溢出，播放按钮位于画面中央', (tester) async {
    await mount(tester, width: 280, height: 118, textScale: 1.6);
    expect(tester.getCenter(find.byKey(const ValueKey('video-center-play'))),
        const Offset(140, 59));
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    expect(find.byType(Slider), findsOneWidget);
    expect(tester.takeException(), isNull);
    native.error('network');
    await tester.pump();
    await tester.pump();
    expect(find.text('点击重试'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('内嵌播放器不阻止帖子垂直滚动', (tester) async {
    final controller = ScrollController();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: ListView(controller: controller, children: [
        SizedBox(
            height: 200,
            child: VideoPlayerPanel(
              player: player,
              onPlay: () async {},
              isFullScreen: false,
            )),
        const SizedBox(height: 1200),
      ]),
    )));
    await tester.drag(find.byType(VideoPlayerPanel), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    await unmount(tester);
    controller.dispose();
  });

  testWidgets('窄卡片倍速菜单不挤占画面，拖动进度可以回到零', (tester) async {
    await native.open(Media('https://example.com/video.mp4'), play: false);
    native.state = native.state.copyWith(position: const Duration(seconds: 30));
    await mount(tester, width: 280, height: 158);
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.tap(find.text('1.0 X'));
    await tester.pumpAndSettle();
    expect(find.text('1.5 X'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('1.5 X'));
    await tester.pumpAndSettle();
    expect(native.rates, [1.5]);
    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(0);
    slider.onChangeEnd!(0);
    await tester.pump();
    expect(native.seeks.last, Duration.zero);
    await unmount(tester);
  });
}
