import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/common/API/Constants.dart';
import 'package:tiebanana/common/AssetList.dart';

class EmojiPanel extends StatefulWidget {
  final TextEditingController controller;
  final double height;
  const EmojiPanel({Key? key, required this.controller, required this.height})
      : super(key: key);

  @override
  State<EmojiPanel> createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<EmojiPanel> {
  late PageController controller;
  List<String> emoji = [];
  static const int _crossAxisCount = 7;
  static const int _rowCount = 3;
  static const double _mainAxisExtent = 30;
  static const double _mainAxisSpacing = 20;
  late final TextEditingController textController;
  @override
  void initState() {
    super.initState();
    controller = PageController();
    emoji.add("image_emoticon.png");
    for (var i = 2; i <= 129; i++) {
      if (AssetList.emojis.contains("image_emoticon$i.png")) {
        emoji.add("image_emoticon$i.png");
      }
    }

    textController = widget.controller;
  }

  List<String> emojiPage(int page) => emoji.sublist(
      page * _crossAxisCount * _rowCount,
      (page + 1) * _crossAxisCount * _rowCount > emoji.length
          ? emoji.length
          : (page + 1) * _crossAxisCount * _rowCount);

  void insertText(String text) {
    final TextEditingValue value = textController.value;
    final int start = value.selection.baseOffset;
    int end = value.selection.extentOffset;
    if (value.selection.isValid) {
      String newText = '';
      if (value.selection.isCollapsed) {
        if (end > 0) {
          newText += value.text.substring(0, end);
        }
        newText += text;
        if (value.text.length > end) {
          newText += value.text.substring(end, value.text.length);
        }
      } else {
        newText = value.text.replaceRange(start, end, text);
        end = start;
      }

      textController.value = value.copyWith(
          text: newText,
          selection: value.selection.copyWith(
              baseOffset: end + text.length, extentOffset: end + text.length));
    } else {
      textController.value = TextEditingValue(
          text: text,
          selection:
              TextSelection.fromPosition(TextPosition(offset: text.length)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: widget.height),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          constraints: const BoxConstraints(
              maxHeight: (_mainAxisExtent + _mainAxisSpacing) * _rowCount),
          child: PageView.builder(
            itemCount: (emoji.length / (_crossAxisCount * _rowCount)).ceil(),
            controller: controller,
            itemBuilder: (BuildContext context, int pageindex) {
              return GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    mainAxisExtent: _mainAxisExtent,
                    crossAxisCount: _crossAxisCount,
                    mainAxisSpacing: _mainAxisSpacing,
                    crossAxisSpacing: 5),
                itemCount: emojiPage(pageindex).length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      var emojiName =
                          emojiPage(pageindex)[index].replaceFirst(".png", "");
                      insertText("#(${emojiFileMapping[emojiName]})");
                    },
                    child: ExtendedImage.asset(
                      "assets/emoji/" + emojiPage(pageindex)[index],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: SmoothPageIndicator(
            controller: controller,
            count: (emoji.length / (_crossAxisCount * _rowCount)).ceil(),
            onDotClicked: (index) {
              controller.animateToPage(index,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut);
            },
            effect: WormEffect(
                spacing: 20,
                dotWidth: 7,
                dotHeight: 7,
                activeDotColor: Colors.grey,
                dotColor: Colors.grey.shade300),
          ),
        )
      ]),
    );
  }
}

class ImagePanel extends StatelessWidget {
  final Map<UploadImageModel, AssetEntity> uploaded;
  final void Function()? onAddImage;
  const ImagePanel({
    Key? key,
    required this.uploaded,
    required this.onAddImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var images = uploaded.values.toList();
    return Container(
      // color: Colors.white,
      constraints: const BoxConstraints(maxHeight: 185),
      child: ListView.builder(
        // physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: uploaded.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == uploaded.length) {
            return UnconstrainedBox(
              child: GestureDetector(
                onTap: onAddImage,
                child: ClipOval(
                  child: Container(
                    height: 64,
                    width: 64,
                    color: Colors.amber.shade100,
                    child: const Icon(
                      Icons.add,
                      size: 36,
                    ),
                  ),
                ),
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            child: FutureBuilder(
              future: images[index].file,
              initialData: null,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  return ExtendedImage.file(
                    snapshot.data,
                    fit: BoxFit.contain,
                  );
                } else {
                  return Container();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
