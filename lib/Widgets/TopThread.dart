import 'package:flutter/material.dart';
import 'package:tiebanana/routes/routes.dart';

//置顶帖部件
class TopThread extends StatelessWidget {
  // final ThreadRecommendSummary info;
  final String tid;
  final String title;
  const TopThread({Key? key, required this.tid, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Theme.of(context).scaffoldBackgroundColor),
      child: MaterialButton(
        onPressed: () {
          Navigator.pushNamed(context, PageRouter.threadPage,
              arguments: ThreadPageRouterData(kz: tid, pid: null));
        },
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipOval(
              child: Container(
                color: Theme.of(context).primaryColor,
                child: Icon(
                  Icons.arrow_drop_up_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            Expanded(
                child: Container(
              padding: const EdgeInsets.only(left: 5),
              child: Text(
                title,
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
