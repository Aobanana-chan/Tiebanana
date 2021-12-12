import 'package:flutter/material.dart';

///消息页
class MessagePan extends StatefulWidget {
  MessagePan({Key? key}) : super(key: key);

  @override
  _MessagePanState createState() => _MessagePanState();
}

class _MessagePanState extends State<MessagePan> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: PageView(
        physics: BouncingScrollPhysics(),
      ),
    );
  }
}
