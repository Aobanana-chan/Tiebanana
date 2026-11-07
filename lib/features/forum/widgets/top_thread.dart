import 'package:flutter/material.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

///置顶帖部件。
///
///对应概念图 `design/mockups/forum.html`（方向 A）的置顶行：
///实心「置顶」小标签 + 两行标题，卡片与普通帖一致。
class TopThread extends StatelessWidget {
  final String tid;
  final String title;
  const TopThread({super.key, required this.tid, required this.title});

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(TiebananaMetrics.pageGutter, 0,
          TiebananaMetrics.pageGutter, TiebananaMetrics.gapSm),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: MaterialButton(
        onPressed: () {
          Navigator.pushNamed(context, PageRouter.threadPage,
              arguments: ThreadPageRouterData(kz: tid, pid: null));
        },
        color: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minWidth: 0,
        padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
        shape: RoundedRectangleBorder(borderRadius: TiebananaMetrics.brLg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            //「置顶」标签
            Container(
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              margin: const EdgeInsets.only(top: 1),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tokens.accentFill,
                borderRadius: TiebananaMetrics.brXs,
              ),
              child: Text(
                "置顶",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: tokens.accentOn,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: tokens.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
