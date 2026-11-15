import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/app/bootstrap.dart';
import 'package:tiebanana/features/splash/splash_page.dart';
import 'package:tiebanana/features/splash/splash_timeline.dart';
import 'package:tiebanana/features/splash/splash_tips.dart';

void main() {
  test('Tips 列表非空、无重复、无空白条目', () {
    expect(SplashTips.all, isNotEmpty);
    expect(SplashTips.all.toSet().length, SplashTips.all.length);
    for (final String tip in SplashTips.all) {
      expect(tip.trim(), isNotEmpty);
    }
  });

  test('pick 只从列表里抽', () {
    for (int seed = 0; seed < 20; seed++) {
      expect(SplashTips.all, contains(SplashTips.pick(math.Random(seed))));
    }
  });

  testWidgets('Tips 进入开屏即显示、交接时淡出，并展示传入的文案', (tester) async {
    Future<double> opacityAt(double t) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: SplashTipsLine(
            t: t,
            text: SplashTips.all.first,
            fontSize: 12,
          ),
        ),
      ));
      final Opacity opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(SplashTipsLine),
          matching: find.byType(Opacity),
        ),
      );
      return opacity.opacity;
    }

    expect(await opacityAt(0), 1);
    expect(await opacityAt(1000), 1);
    expect(await opacityAt(SplashBeats.hold.from), 1);
    expect(await opacityAt(SplashBeats.out.to), 0);
    expect(find.textContaining('Tips'), findsOneWidget);
    expect(find.textContaining(SplashTips.all.first), findsOneWidget);
  });

  testWidgets('启动时把抽到的 Tips 传给开屏页', (tester) async {
    final BootState boot = BootState()..markReady();
    await tester.pumpWidget(BootstrapApp(boot: boot, app: const SizedBox()));
    final SplashPage page = tester.widget<SplashPage>(find.byType(SplashPage));
    expect(SplashTips.all, contains(page.tip));
  });
}
