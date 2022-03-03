import 'dart:math';
import 'package:extended_text/extended_text.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:like_button/like_button.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/Widgets/EmojiPanel.dart';
import 'package:tiebanana/Widgets/SpecialSpan.dart';
import 'package:tiebanana/common/API/TiebaParser.dart';
import 'package:tiebanana/common/Global.dart';

///帖子-底端回复栏
class ThreadReplyBar extends StatefulWidget {
  final String fid;
  final String tid;
  final String kw;
  final String replyText;
  ThreadReplyBar(
      {Key? key,
      required this.fid,
      required this.tid,
      required this.kw,
      required this.replyText})
      : super(key: key);

  @override
  _ThreadReplyBarState createState() => _ThreadReplyBarState();
}

class _ThreadReplyBarState extends State<ThreadReplyBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0F1F2)))),
      child: Row(
        children: [
          Expanded(
              child: GestureDetector(
            onTap: () {
              //TODO:打开回复框
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
              padding: EdgeInsets.only(left: 10),
              margin: EdgeInsets.only(right: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "我来聊几句",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )),
          LikeButton(
            likeBuilder: (isLiked) {
              if (!isLiked) {
                return Icon(Icons.star_border);
              } else {
                return Icon(
                  Icons.star,
                  color: Colors.yellow,
                );
              }
            },
          ),
          //TODO:帖子分享
          LikeButton(
            likeBuilder: (isLiked) {
              return Icon(Icons.share);
            },
          )
        ],
      ),
    );
  }
}

class InnerFloorReplyBar extends StatelessWidget {
  final Author author;
  final Forum forum;
  final String threadID;
  final PostList postMain;
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
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
          color: Colors.white,
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
                  kw: forum.name!,
                  fid: forum.id!,
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
              padding: EdgeInsets.only(left: 10),
              margin: EdgeInsets.only(right: 10),
              child: Align(
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
  final Author? replyUser;
  ReplyBottomSheet(
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
  bool showEmojiInput = false;
  bool emojiInputActive = false;
  double _keyboardHeight = 267;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    if (keyboardHeight > 0) {
      emojiInputActive = false;
    }
    return Container(
      constraints: BoxConstraints(
          maxHeight:
              400 + (emojiInputActive ? _keyboardHeight : keyboardHeight)),
      padding: EdgeInsets.only(
        left: 20,
        top: 20,
        right: 20,
      ),
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20.0),
            topRight: const Radius.circular(20.0),
          ),
          color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //回复评论
          Container(
            margin: EdgeInsets.only(bottom: 5),
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
            constraints: BoxConstraints(minHeight: 80, maxHeight: 120),
            child: Row(
              children: [
                Expanded(
                    child: ExtendedTextField(
                        specialTextSpanBuilder: TiebaSpanBuilder(),
                        controller: controller,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        focusNode: focusNode,
                        autofocus: true,
                        onTap: () {
                          showEmojiInput = false;
                        },
                        decoration: InputDecoration(
                          hintText: "我来聊几句",
                          isCollapsed: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none),
                        ))),
                Container(
                  margin: EdgeInsets.only(left: 10),
                  alignment: Alignment.bottomCenter,
                  child: GradientButton(
                    onPressed: () async {
                      assert(!(widget.isReplyThread == false &&
                          widget.floorId == null));
                      late WAPTiebaBase msg;
                      if (widget.isReplyThread == true) {
                        msg = await Global.tiebaAPI.replyThread(
                            controller.text, widget.kw, widget.fid, widget.tid);
                      } else if (widget.isReplyThread == false) {
                        if (widget.replyUser == null) {
                          msg = await Global.tiebaAPI.replyFloor(
                              "${controller.text}",
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
                              replyUID: widget.replyUser!.id!);
                        }
                      }

                      String message;
                      if (msg.errcode == "0") {
                        message = "发送成功";
                        Fluttertoast.showToast(msg: message);
                        Navigator.pop(context);
                      } else {
                        message = "${msg.msg}";
                        Fluttertoast.showToast(msg: message);
                      }
                    },
                    child: Text(
                      "发表",
                    ),
                    borderRadius: BorderRadius.circular(64),
                  ),
                )
              ],
            ),
          ),

          //媒体输入按钮
          Container(
            child: Row(
              children: [
                IconButton(
                    onPressed: () {
                      //TODO:选择图片上传
                    },
                    icon: Icon(Icons.photo)),
                IconButton(
                  onPressed: () {
                    showEmojiInput = !showEmojiInput;
                    if (emojiInputActive) {
                      setState(() {
                        if (showEmojiInput) {
                          FocusScope.of(context).requestFocus(focusNode);
                        }
                        emojiInputActive = showEmojiInput;
                      });
                    } else {
                      SystemChannels.textInput
                          .invokeListMethod("TextInput.hide")
                          .whenComplete(() =>
                              Future.delayed(Duration(milliseconds: 200))
                                  .whenComplete(() => setState(() {
                                        if (showEmojiInput) {
                                          FocusScope.of(context)
                                              .requestFocus(focusNode);
                                        }
                                        emojiInputActive = showEmojiInput;
                                      })));
                    }
                  },
                  icon: Icon(Icons.emoji_emotions_outlined),
                ),
                IconButton(
                    onPressed: () async {
                      bool? action = await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: Text('确认'),
                              content: Text('是否清空输入?'),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('取消'),
                                  onPressed: () {
                                    Navigator.pop(context, false);
                                  },
                                ),
                                TextButton(
                                  child: Text('确认'),
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
                    icon: Icon(Icons.clear_outlined))
              ],
            ),
          ),
          Container(
            constraints: BoxConstraints(
                maxHeight: emojiInputActive ? _keyboardHeight : 0),
            child: EmojiPanel(
              controller: controller,
              height: emojiInputActive ? _keyboardHeight : 0,
            ),
          ),
        ],
      ),
    );
  }
}
