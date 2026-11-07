import 'package:extended_text/extended_text.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:like_button/like_button.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Json_Model/provider.dart';
import 'package:tiebanana/Widgets/EmojiPanel.dart';
import 'package:tiebanana/Widgets/SpecialSpan.dart';
import 'package:tiebanana/common/API/TiebaParser.dart';
import 'package:tiebanana/common/Global.dart';
import 'package:tiebanana/routes/ThreadPage.dart';
import 'package:tiebanana/routes/routes.dart';

import '../Json_Model/WidgetModel/PostContentModel.dart';
import '../Json_Model/WidgetModel/ThreadCommentModel.dart';
import '../Json_Model/WidgetModel/ThreadPageModel.dart';

///帖子-底端回复栏
class ThreadReplyBar extends StatefulWidget {
  final String fid;
  final String tid;
  final String kw;
  final String replyText;
  final bool isThreadStored;
  const ThreadReplyBar(
      {Key? key,
      required this.fid,
      required this.tid,
      required this.kw,
      required this.replyText,
      required this.isThreadStored})
      : super(key: key);

  @override
  _ThreadReplyBarState createState() => _ThreadReplyBarState();
}

class _ThreadReplyBarState extends State<ThreadReplyBar> {
  String get pid {
    var p = "";
    p = context.findAncestorStateOfType<ThreadPageMainState>()!.pid;
    return p;
  }

  ///贴是否收藏
  bool isStored = false;
  @override
  void initState() {
    super.initState();
    isStored = widget.isThreadStored;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Theme.of(context).colorScheme.background,
          border: const Border(top: BorderSide(color: Color(0xFFF0F1F2)))),
      child: Row(
        children: [
          Expanded(
              child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => ReplyBottomSheet(
                  replyText: widget.replyText,
                  kw: widget.kw,
                  fid: widget.fid,
                  tid: widget.tid,
                  isReplyThread: true,
                ),
              );
            },
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Colors.grey.shade200,
              ),
              padding: const EdgeInsets.only(left: 10),
              margin: const EdgeInsets.only(right: 10),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "我来聊几句",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )),
          LikeButton(
            isLiked: isStored,
            likeBuilder: (isLiked) {
              if (!isLiked) {
                return const Icon(Icons.star_border);
              } else {
                return const Icon(
                  Icons.star,
                  color: Colors.yellow,
                );
              }
            },
            onTap: (isLiked) async {
              if (isLiked) {
                //TODO:取消收藏
                var res = await Global.tiebaAPI.threadRemoveStore(widget.tid);
                if (res.error?.errno == "0") {
                  Fluttertoast.showToast(msg: "取消收藏");
                } else {
                  Fluttertoast.showToast(msg: "取消失败");
                  return isLiked;
                }
              } else {
                var res = await Global.tiebaAPI.threadAddStore(widget.tid, pid);
                if (res.error?.errno == "0") {
                  Fluttertoast.showToast(msg: "收藏成功");
                } else {
                  Fluttertoast.showToast(msg: "收藏失败");
                  return isLiked;
                }
              }

              isStored = !isLiked;
              if (mounted) {
                context
                    .findAncestorStateOfType<ThreadPageMainState>()
                    ?.isStored = isStored;
              }

              return !isLiked;
            },
          ),
          //TODO:帖子分享
          LikeButton(
            likeBuilder: (isLiked) {
              return const Icon(Icons.share);
            },
          )
        ],
      ),
    );
  }
}

class InnerFloorReplyBar extends StatelessWidget {
  final AuthorWidgetModel author;
  final ForumData forum;
  final String threadID;
  final PostListWidgetModel postMain;
  const InnerFloorReplyBar(
      {Key? key,
      required this.author,
      required this.forum,
      required this.threadID,
      required this.postMain})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: const BoxDecoration(
          // color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0F1F2)))),
      child: Row(
        children: [
          Expanded(
              child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => ReplyBottomSheet(
                  replyText:
                      "${author.nameShow ?? author.name}： ${TiebaParser.parserContentString(postMain.content)}",
                  kw: forum.forumName,
                  fid: forum.fid,
                  tid: threadID,
                  floorId: postMain.id,
                  isReplyThread: false,
                ),
              );
            },
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Colors.grey.shade200,
              ),
              padding: const EdgeInsets.only(left: 10),
              margin: const EdgeInsets.only(right: 10),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "我来聊几句",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class ReplyBottomSheet extends StatefulWidget {
  final String replyText;
  final String kw;
  final String fid;
  final String tid;
  final bool isReplyThread;
  final String? floorId;
  final AuthorWidgetModel? replyUser;
  const ReplyBottomSheet(
      {Key? key,
      required this.replyText,
      required this.kw,
      required this.fid,
      required this.tid,
      required this.isReplyThread,
      this.floorId,
      this.replyUser})
      : super(key: key);

  @override
  State<ReplyBottomSheet> createState() => _ReplyBottomSheetState();
}

class _ReplyBottomSheetState extends State<ReplyBottomSheet> {
  TextEditingController controller =
      TextEditingController.fromValue(TextEditingValue.empty);
  final FocusNode focusNode = FocusNode();
  bool get showCustomKeyBoard => emojiInputActive || imageInputActive;
  bool emojiInputActive = false;
  bool imageInputActive = false;
  final double _keyboardHeight = 267;
  late ImageUploadProviderModel imagesUpload;
  @override
  void initState() {
    super.initState();
    imagesUpload = ImageUploadProviderModel(widget.kw);
  }

  void insertText(String text) {
    final TextEditingValue value = controller.value;
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

      controller.value = value.copyWith(
          text: newText,
          selection: value.selection.copyWith(
              baseOffset: end + text.length, extentOffset: end + text.length));
    } else {
      controller.value = TextEditingValue(
          text: text,
          selection:
              TextSelection.fromPosition(TextPosition(offset: text.length)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    if (keyboardHeight > 0) {
      emojiInputActive = false;
      imageInputActive = false;
    }
    return Container(
      constraints: BoxConstraints(
          maxHeight:
              400 + (emojiInputActive ? _keyboardHeight : keyboardHeight)),
      padding: const EdgeInsets.only(
        left: 20,
        top: 20,
        right: 20,
      ),
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Theme.of(context).colorScheme.background),
      child: ChangeNotifierProvider.value(
        value: imagesUpload,
        builder: (context, child) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //回复评论
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Expanded(
                      child: ExtendedText(
                    "回复： ${widget.replyText}",
                    overflow: TextOverflow.ellipsis,
                    specialTextSpanBuilder: TiebaSpanBuilder(),
                  ))
                ],
              ),
            ),
            //回复输入
            Container(
              constraints: const BoxConstraints(minHeight: 80, maxHeight: 120),
              child: Row(
                children: [
                  Consumer<ImageUploadProviderModel>(
                      builder: ((context, value, child) => Expanded(
                          child: ExtendedTextField(
                              specialTextSpanBuilder:
                                  TiebaSpanBuilder(uploadImages: value),
                              controller: controller,
                              expands: true,
                              maxLines: null,
                              minLines: null,
                              focusNode: focusNode,
                              autofocus: true,
                              onTap: () {
                                // showCustomKeyBoard = false;
                              },
                              decoration: InputDecoration(
                                hintText: "我来聊几句",
                                isCollapsed: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                filled: true,
                                // fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none),
                              ))))),
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    alignment: Alignment.bottomCenter,
                    child: GradientButton(
                      onPressed: () async {
                        assert(!(widget.isReplyThread == false &&
                            widget.floorId == null));
                        late WAPTiebaBase msg;
                        if (widget.isReplyThread == true) {
                          msg = await Global.tiebaAPI.replyThread(
                              controller.text,
                              widget.kw,
                              widget.fid,
                              widget.tid);
                        } else if (widget.isReplyThread == false) {
                          if (widget.replyUser == null) {
                            msg = await Global.tiebaAPI.replyFloor(
                                controller.text,
                                widget.kw,
                                widget.fid,
                                widget.tid,
                                widget.floorId!);
                          } else {
                            msg = await Global.tiebaAPI.replyFloor(
                                "${TiebaParser.contentBuilder(ContentBuilderType.Reply, replyUser: widget.replyUser)}${controller.text}",
                                widget.kw,
                                widget.fid,
                                widget.tid,
                                widget.floorId!,
                                replyUID: widget.replyUser!.id);
                          }
                        }

                        String message;
                        if (msg.errcode == "0") {
                          message = "发送成功";
                          Fluttertoast.showToast(msg: message);
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        } else {
                          message = "${msg.msg}";
                          Fluttertoast.showToast(msg: message);
                        }
                      },
                      borderRadius: BorderRadius.circular(64),
                      child: const Text(
                        "发表",
                      ),
                    ),
                  )
                ],
              ),
            ),

            //媒体输入按钮

            Row(
              children: [
                IconButton(
                    onPressed: () {
                      // ignore: prefer_function_declarations_over_variables
                      final Function change = () {
                        setState(() {
                          if (imageInputActive) {
                            FocusScope.of(context).requestFocus(focusNode);
                          }
                          imageInputActive = !imageInputActive;
                          emojiInputActive = false;
                        });
                      };
                      if (showCustomKeyBoard) {
                        change();
                      } else {
                        SystemChannels.textInput
                            .invokeMethod<void>('TextInput.hide')
                            .whenComplete(() {
                          Future<void>.delayed(
                                  const Duration(milliseconds: 200))
                              .whenComplete(() {
                            change();
                          });
                        });
                      }
                      // var data = await Navigator.pushNamed(
                      //     context, PageRouter.imagePicker);

                      // if (data != null) {
                      //   var pic = (data as List)[0] as Set<AssetEntity>;
                      //   var saveOrigin = data[1] as bool;
                      //   for (var p in pic) {
                      //     var picture =
                      //         await imagesUpload.uploadPicture(p, saveOrigin);
                      //     //上传完成后加入编辑框
                      //     if (picture != null) {
                      //       insertText(TiebaParser.contentBuilder(
                      //           ContentBuilderType.Picture,
                      //           image: picture[1] as UploadImageModel));
                      //     }
                      //   }
                      // }
                    },
                    icon: const Icon(Icons.photo)),
                IconButton(
                  onPressed: () {
                    // ignore: prefer_function_declarations_over_variables
                    final Function change = () {
                      setState(() {
                        if (emojiInputActive) {
                          FocusScope.of(context).requestFocus(focusNode);
                        }
                        emojiInputActive = !emojiInputActive;
                        imageInputActive = false;
                      });
                    };
                    if (showCustomKeyBoard) {
                      change();
                    } else {
                      SystemChannels.textInput
                          .invokeMethod<void>('TextInput.hide')
                          .whenComplete(() {
                        Future<void>.delayed(const Duration(milliseconds: 200))
                            .whenComplete(() {
                          change();
                        });
                      });
                    }
                    // if (emojiInputActive) {
                    //   setState(() {
                    //     if (showCustomKeyBoard != 0) {
                    //       FocusScope.of(context).requestFocus(focusNode);
                    //     }
                    //     emojiInputActive = showCustomKeyBoard == 2;
                    //   });
                    // } else {
                    //   SystemChannels.textInput
                    //       .invokeListMethod("TextInput.hide")
                    //       .whenComplete(() =>
                    //           Future.delayed(Duration(milliseconds: 200))
                    //               .whenComplete(() => setState(() {
                    //                     if (showCustomKeyBoard != 0) {
                    //                       FocusScope.of(context)
                    //                           .requestFocus(focusNode);
                    //                     }
                    //                     emojiInputActive =
                    //                         showCustomKeyBoard == 2;
                    //                   })));
                    // }
                  },
                  icon: const Icon(Icons.emoji_emotions_outlined),
                ),
                IconButton(
                    onPressed: () async {
                      bool? action = await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: const Text('确认'),
                              content: const Text('是否清空输入?'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('取消'),
                                  onPressed: () {
                                    Navigator.pop(context, false);
                                  },
                                ),
                                TextButton(
                                  child: const Text('确认'),
                                  onPressed: () {
                                    Navigator.pop(context, true);
                                  },
                                ),
                              ],
                            );
                          });
                      if (action == true) {
                        controller.text = "";
                      }
                    },
                    icon: const Icon(Icons.clear_outlined))
              ],
            ),
            Consumer<ImageUploadProviderModel>(
                builder: ((context, value, child) {
                  if (emojiInputActive) {
                    return child!;
                  } else {
                    return Container(
                      constraints: BoxConstraints(
                          maxHeight: imageInputActive ? _keyboardHeight : 0),
                      child: ImagePanel(
                        uploaded: value.pictures,
                        onAddImage: () async {
                          imageInputActive = false;
                          var data = await Navigator.pushNamed(
                              context, PageRouter.imagePicker);

                          if (data != null) {
                            var pic = (data as List)[0] as Set<AssetEntity>;
                            var saveOrigin = data[1] as bool;
                            for (var p in pic) {
                              var picture = await imagesUpload.uploadPicture(
                                  p, saveOrigin);
                              //上传完成后加入编辑框
                              if (picture != null) {
                                insertText(TiebaParser.contentBuilder(
                                    ContentBuilderType.Picture,
                                    image: picture[1] as UploadImageModel));
                              }
                            }
                          }
                        },
                      ),
                    );
                  }
                }),
                child: Container(
                  constraints: BoxConstraints(
                      maxHeight: emojiInputActive ? _keyboardHeight : 0),
                  child: EmojiPanel(
                    controller: controller,
                    height: emojiInputActive ? _keyboardHeight : 0,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
