import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/thread/state/reply_events.dart';
import 'package:tiebanana/features/settings/state/app_settings.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/features/thread/widgets/thread_floor_card.dart';
import 'package:tiebanana/features/thread/widgets/thread_common.dart';

class _Api extends DemoTiebaApi {
  _Api() : super(latency: Duration.zero);
  final List<int> pages = [];

  @override
  Future<InnerFloor> getInnerFloor(String kz, String pid,
      {String spid = '', int pn = 1, int rn = 20}) async {
    pages.add(pn);
    final floor = await super.getInnerFloor(kz, pid, pn: pn);
    floor.subposts.first.content = [
      TiebaTextContent(text: '刷新后的回复 ${pages.length}')
    ];
    return floor;
  }
}

void main() {
  testWidgets('楼中楼成功事件重读当前页并替换旧回复，销毁后停止监听', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Global.profile = await SharedPreferences.getInstance();
    Global.setting = APPSetting.fromJson(defaultAPPSetting);
    final api = _Api();
    Global.tiebaAPI = api;
    final page = await api.getThreadPage('123');
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => APPSettingProvider(),
      child: MaterialApp(
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        home: Scaffold(
          body: InnerFloorBottomSheet(
              floorNum: '3', kz: '123', pid: '3', pn: 2, forum: page),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(api.pages, [2]);
    final votes =
        tester.widgetList<ThreadVoteBar>(find.byType(ThreadVoteBar)).toList();
    final cards =
        tester.widgetList<InnerFloorCard>(find.byType(InnerFloorCard)).toList();
    expect(votes.length, greaterThan(1));
    expect(votes.first.objType, 1, reason: '楼中楼面板的父楼层不是楼中楼');
    for (var i = 0; i < votes.length; i++) {
      expect(votes[i].objType, i == 0 ? 1 : 2);
      expect(votes[i].postId, cards[i].postMain.id);
      expect(votes[i].threadId, '123');
      expect(votes[i].forumId, page.fid);
    }
    // 按压反馈必须覆盖卡片内边距，而不只是中间的内容区域。
    final firstCard = find.byType(InnerFloorCard).first;
    final cardBounds = tester.getRect(firstCard);
    final inkWell = find
        .descendant(
          of: firstCard,
          matching: find.byType(InkWell),
        )
        .first;
    final material = tester.widget<Material>(find
        .descendant(
          of: firstCard,
          matching: find.byType(Material),
        )
        .first);
    expect(
      tester.getRect(inkWell),
      Rect.fromLTRB(cardBounds.left + 12, cardBounds.top, cardBounds.right - 12,
          cardBounds.bottom),
    );
    expect(material.clipBehavior, Clip.antiAlias);
    expect(material.borderRadius, TiebananaMetrics.brLg);
    expect(tester.widget<InkWell>(inkWell).borderRadius, material.borderRadius);
    String firstReply() => (tester
            .widgetList<InnerFloorCard>(find.byType(InnerFloorCard))
            .elementAt(1)
            .postMain
            .content
            .first as TiebaTextContent)
        .text;
    expect(firstReply(), '刷新后的回复 1');
    replyEvents.sent('other', pid: '3');
    replyEvents.sent('123', pid: 'other');
    expect(api.pages, [2]);
    replyEvents.sent('123', pid: '3');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(api.pages, [2, 2]);
    expect(firstReply(), '刷新后的回复 2');
    await tester.pumpWidget(const SizedBox());
    replyEvents.sent('123', pid: '3');
    expect(api.pages, [2, 2]);
    expect(tester.takeException(), isNull);
  });
}
