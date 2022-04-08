import 'package:flutter/material.dart';
import 'package:tiebanana/Json_Model/json.dart';
import 'package:tiebanana/routes/routes.dart';

//置顶帖部件
class TopThread extends StatelessWidget {
  final ThreadRecommendSummary info;
  const TopThread({Key? key, required this.info}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.all(0),
      decoration: const BoxDecoration(color: Colors.white),
      child: MaterialButton(
        onPressed: () {
          Navigator.pushNamed(context, PageRouter.threadPage,
              arguments: info.tid!);
        },
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipOval(
              child: Container(
                color: Colors.blue,
                child: const Icon(
                  Icons.arrow_drop_up_rounded,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
                child: Container(
              padding: const EdgeInsets.only(left: 5),
              child: Text(
                info.title!,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            )),
          ],
        ),
      ),
    );
  }
}
