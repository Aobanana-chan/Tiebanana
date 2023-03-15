import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/common/API/Constants.dart';

///音频播放器
class TiebaAudioPlayer extends StatefulWidget {
  final String voiceMd5;
  final String durantion;
  const TiebaAudioPlayer(
      {Key? key, required this.voiceMd5, required this.durantion})
      : super(key: key);

  @override
  State<TiebaAudioPlayer> createState() => _TiebaAudioPlayerState();
}

class _TiebaAudioPlayerState extends State<TiebaAudioPlayer>
    with SingleTickerProviderStateMixin {
  var player = AudioPlayer();
  bool isplaying = false;
  // late Animation<double> progressAnimation;
  // late AnimationController progressController;
  ValueNotifier<double> progress = ValueNotifier<double>(0);

  late final Duration duration;
  @override
  void initState() {
    super.initState();
    duration = Duration(milliseconds: int.parse(widget.durantion));
    // progressController = AnimationController(vsync: this, duration: duration);
    // progressAnimation =
    //     Tween<double>(begin: 0, end: 1).animate(progressController);
    var uri = Uri.parse(VOVICE_MESSAGE);
    uri.queryParameters["voice_md5"] = widget.voiceMd5;
    player.setUrl(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(64)),
      child: Row(children: [
        player.playing
            ? const Icon(Icons.stop_circle_outlined)
            : const Icon(Icons.play_circle_outline_outlined),
        Visibility(
          child: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (BuildContext context, double value, Widget? child) {
              return Container();
            },
          ),
        )
      ]),
    );
  }
}
