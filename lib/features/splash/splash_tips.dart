import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:tiebanana/features/splash/splash_brand.dart';
import 'package:tiebanana/features/splash/splash_timeline.dart';

/// 开屏底部的小提示（Tips）。
///
/// **新增提示**只需要往 [all] 里加一行，顺序不影响展示（每次启动随机抽）。
class SplashTips {
  const SplashTips._();

  /// Tips 文案。保持短句，不要以句号结尾。
  static const List<String> all = <String>[
    '长按主页的吧标签，可以移动排序',
    '贴浏览后会保存一天的缓存，期间贴被删除也可以访问',
  ];

  /// 随机抽一条。开屏一次只抽一次，避免逐帧重建时文案乱跳。
  ///
  /// 测试可以传入固定种子的 [math.Random] 让结果可复现。
  static String pick([math.Random? random]) =>
      all[(random ?? math.Random()).nextInt(all.length)];
}

/// 开屏底部的 Tips 行。
///
/// 进入开屏就显示，给用户留足阅读时间；交接时随整屏一起淡出。
class SplashTipsLine extends StatelessWidget {
  const SplashTipsLine({
    super.key,
    required this.t,
    required this.text,
    required this.fontSize,
  });

  /// 设计毫秒（0–3300）。
  final double t;

  /// 本次开屏抽到的文案，见 [SplashTips.all]。
  final String text;

  /// 正文字号；`Tips` 前缀用同一字号加粗。
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    // 不做入场淡入：开屏第一帧就要能读到，后面交接时再跟整屏一起淡出。
    final double alive = 1 -
        ease(t, SplashBeats.out.from, SplashBeats.out.to, SplashCurves.gravity);

    return Opacity(
      opacity: alive.clamp(0, 1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SplashBrand.ink.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(fontSize * 1.6),
          border: Border.all(
            color: SplashBrand.ink.withValues(alpha: .14),
            width: .8,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: fontSize * 1.2,
            vertical: fontSize * .55,
          ),
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: 'Tips',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: SplashBrand.ink.withValues(alpha: .92),
                  ),
                ),
                TextSpan(text: '  $text'),
              ],
            ),
            textAlign: TextAlign.center,
            // 开屏版式固定，只允许有限的系统字号放大，免得长句把页面撑走形。
            textScaler:
                MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
            style: TextStyle(
              fontSize: fontSize,
              height: 1.5,
              letterSpacing: .2,
              color: SplashBrand.ink.withValues(alpha: .78),
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
