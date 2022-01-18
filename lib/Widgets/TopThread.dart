import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';

//置顶帖部件
class TopThread extends StatelessWidget {
  final ThreadRecommendSummary info;
  const TopThread({Key? key, required this.info}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(0),
      padding: EdgeInsets.all(0),
      decoration: BoxDecoration(color: Colors.white),
      child: MaterialButton(
        onPressed: () {
          //TODO:进入主题帖
        },
        padding: EdgeInsets.all(5),
        child: Row(
          children: [
            ClipOval(
              child: Container(
                color: Colors.blue,
                child: Icon(
                  Icons.arrow_drop_up_rounded,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
                child: Container(
              padding: EdgeInsets.only(left: 5),
              child: Text(
                info.title!,
                style: TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            )),
          ],
        ),
      ),
    );
  }
}
