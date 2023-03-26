import 'package:flukit/flukit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tiebanana/common/API/Constants.dart';

///音频播放器
class TiebaAudioPlayer extends StatefulWidget {
  final String voiceMd5;
  final int? durantion;
  const TiebaAudioPlayer(
      {Key? key, required this.voiceMd5, required this.durantion})
      : super(key: key);

  @override
  State<TiebaAudioPlayer> createState() => _TiebaAudioPlayerState();
}

class _TiebaAudioPlayerState extends State<TiebaAudioPlayer>
    with SingleTickerProviderStateMixin {
  var player = AudioPlayer();
  ValueNotifier<bool> isplaying = ValueNotifier(false);
  ValueNotifier<double> progress = ValueNotifier<double>(0);
  bool canseek = false;

  late Duration duration;
  @override
  void initState() {
    super.initState();
    duration = Duration(milliseconds: widget.durantion ?? 0);
    // progressController = AnimationController(vsync: this, duration: duration);
    // progressAnimation =
    //     Tween<double>(begin: 0, end: 1).animate(progressController);
    player.setUrl("$VOVICE_MESSAGE?voice_md5=${widget.voiceMd5}");
    player.load().then((value) {
      if (value != null &&
          duration.inMilliseconds != value.inMilliseconds &&
          mounted) {
        setState(() {
          duration = value;
        });
      }
    });

    player.positionStream.listen((event) {
      progress.value = event.inMilliseconds / duration.inMilliseconds;
    });

    player.playerStateStream.listen((event) {
      switch (event.processingState) {
        case ProcessingState.completed:
          player.stop();
          progress.value = 0;
          setState(() {});
          break;
        default:
      }
    });

    player.playingStream.listen((event) {
      isplaying.value = event;
    });
  }

  void _clickButton() {
    if (isplaying.value) {
      player.pause();
    } else {
      player.play();
    }
    canseek = true;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _clickButton,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            border:
                Border.all(color: Theme.of(context).primaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ValueListenableBuilder<bool>(
            valueListenable: isplaying,
            builder: (context, value, child) {
              if (value) {
                return const Icon(Icons.pause_circle);
              } else {
                return const Icon(Icons.play_circle);
              }
            },
          ),
          Expanded(child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 30,
                child: ValueListenableBuilder<double>(
                  valueListenable: progress,
                  builder: (BuildContext context, double value, Widget? child) {
                    return GestureDetector(
                      onTapDown: (details) {
                        if (canseek) {
                          player.seek(duration *
                              (details.localPosition.dx /
                                  constraints.maxWidth));
                        } else {
                          _clickButton();
                        }
                      },
                      onHorizontalDragStart: (details) async {
                        await player.pause();
                        player.seek(duration *
                            (details.localPosition.dx / constraints.maxWidth));
                      },
                      onHorizontalDragUpdate: (details) {
                        progress.value =
                            details.localPosition.dx / constraints.maxWidth;
                      },
                      onHorizontalDragEnd: (details) async {
                        await player.seek(duration * progress.value);
                        player.play();
                      },
                      child: LinearProgressIndicator(
                        value: progress.value,
                      ),
                    );
                  },
                ),
              );
            },
          )),
          StreamBuilder<Duration>(
            initialData: duration,
            stream: player.positionStream,
            builder: (context, snapshot) {
              return Text(formatDurantion(snapshot.data!));
            },
          )
        ]),
      ),
    );
  }

  String formatDurantion(Duration duration) {
    String result = "${duration.inSeconds % 60}''";
    if (duration.inMinutes > 0) {
      result = "${duration.inMinutes}' $result";
    }
    return result;
  }

  @override
  void dispose() {
    player.dispose();

    super.dispose();
  }
}
