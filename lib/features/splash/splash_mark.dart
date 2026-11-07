import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:tiebanana/features/splash/splash_brand.dart';
import 'package:tiebanana/features/splash/splash_timeline.dart';
import 'package:tiebanana/features/splash/tiebanana_glyph.dart';

/// 绕 [pivot] 做 translate → rotate → scale。
///
/// 等价于 svg 里的
/// `translate(px py) translate(dx dy) rotate(r) scale(sx sy) translate(-px -py)`。
/// 各层支点不在图层中心（贝绕底边、香蕉绕下端尖），
/// 这里用矩阵显式给出支点。
Matrix4 pivotMatrix(
  Offset pivot, {
  Offset translate = Offset.zero,
  double rotate = 0,
  double scaleX = 1,
  double scaleY = 1,
}) {
  return Matrix4.identity()
    ..translateByDouble(pivot.dx, pivot.dy, 0, 1)
    ..translateByDouble(translate.dx, translate.dy, 0, 1)
    ..rotateZ(rotate)
    ..scaleByDouble(scaleX, scaleY, 1, 1)
    ..translateByDouble(-pivot.dx, -pivot.dy, 0, 1);
}

/// 一个图层在某一帧的变换与不透明度。
@immutable
class LayerFrame {
  const LayerFrame(this.transform, this.opacity);

  final Matrix4 transform;
  final double opacity;
}

/// 图标本体在某一帧的状态。
///
/// **与 `design/splash/splash.html` 的 `frame()` 一一对应** —— 改动画时两边一起改。
/// [t] 是设计毫秒（0–3300，见 [SplashBeats]）。
@immutable
class MarkFrame {
  const MarkFrame._({
    required this.t,
    required this.outK,
    required this.bei,
    required this.gv,
    required this.gh,
    required this.zhan,
    required this.banana,
    required this.leaf,
    required this.breathe,
    required this.squash,
    required this.glowRadius,
    required this.glowOpacity,
    required this.ringRadius,
    required this.ringStroke,
    required this.ringOpacity,
    required this.sparkProgress,
  });

  final double t;

  /// 交接进度（开屏推走）。所有图层的不透明度都乘 `1 - outK`。
  final double outK;

  final LayerFrame bei;
  final LayerFrame gv;
  final LayerFrame gh;
  final LayerFrame zhan;
  final LayerFrame banana;
  final LayerFrame leaf;

  /// 字标落定后的呼吸（绕整字重心）。
  final Matrix4 breathe;

  /// 落定瞬间的整体挤压。
  final Matrix4 squash;

  final double glowRadius;
  final double glowOpacity;
  final double ringRadius;
  final double ringStroke;
  final double ringOpacity;

  /// 星火进度 0–1（[SplashBeats.sparks] 区间内）。
  final double sparkProgress;

  factory MarkFrame.of(double t) {
    final double outK =
        ease(t, SplashBeats.out.from, SplashBeats.out.to, SplashCurves.gravity);
    final double alive = 1 - outK;

    // ---- 光晕：底色浮现时推开，落定时再顶一下 ----
    final double gp = ease(t, SplashBeats.glow.from, 900, SplashCurves.out);
    final double kick = math
        .sin(math.pi * seg(t, SplashBeats.impact.from, SplashBeats.impact.to));
    final double glowRadius = mix(120, 392, gp) + 70 * kick;
    final double glowOpacity = (.17 * gp + .22 * kick) * alive;

    // ---- 贝：自左滑入，回弹落位 ----
    final double beiP =
        ease(t, SplashBeats.bei.from, SplashBeats.bei.to, SplashCurves.back);
    final double beiS =
        ease(t, SplashBeats.bei.from, SplashBeats.bei.to, SplashCurves.soft);
    final LayerFrame bei = LayerFrame(
      pivotMatrix(
        TiebananaGlyph.beiPivot,
        translate:
            TiebananaGlyph.emOffset(mix(-126, 0, beiP), mix(-20, 0, beiS)),
        rotate: deg(mix(-10, 0, beiS)),
        scaleX: mix(.9, 1, beiS),
        scaleY: mix(.9, 1, beiS),
      ),
      ease(t, SplashBeats.bei.from, SplashBeats.bei.from + 200,
              SplashCurves.out) *
          alive,
    );

    // ---- 卜（真字形）：丨 从顶端往下写、一 从左端往右写；
    //      被顶替时 丨 沉进口里（底端做支点）、一 缩回左边 ----
    final double growV = ease(
        t, SplashBeats.ghostV.from, SplashBeats.ghostV.to, SplashCurves.out);
    final double growH = ease(
        t, SplashBeats.ghostH.from, SplashBeats.ghostH.to, SplashCurves.out);
    final double sinkV = ease(t, SplashBeats.evictV.from, SplashBeats.evictV.to,
        SplashCurves.gravity);
    final double sinkH = ease(t, SplashBeats.evictH.from, SplashBeats.evictH.to,
        SplashCurves.gravity);

    // 支点在「写」与「退」之间会换一次；换的时候 scale 已回到 1，切换时画面连续。
    final LayerFrame gv = LayerFrame(
      sinkV > 0
          ? pivotMatrix(TiebananaGlyph.gvBottomPivot, scaleY: 1 - sinkV)
          : pivotMatrix(TiebananaGlyph.gvTopPivot, scaleY: growV),
      (1 - sinkV) * alive,
    );
    final LayerFrame gh = LayerFrame(
      pivotMatrix(TiebananaGlyph.ghPivot, scaleX: growH * (1 - sinkH)),
      (1 - sinkH) * alive,
    );

    // ---- 占的口：自下抬起 ----
    final double kouP =
        ease(t, SplashBeats.kou.from, SplashBeats.kou.to, SplashCurves.back);
    final double kouS =
        ease(t, SplashBeats.kou.from, SplashBeats.kou.to, SplashCurves.soft);
    final LayerFrame zhan = LayerFrame(
      pivotMatrix(
        TiebananaGlyph.kouPivot,
        translate: TiebananaGlyph.emOffset(0, mix(148, 0, kouP)),
        rotate: deg(mix(8, 0, kouS)),
        scaleX: mix(.92, 1, kouS),
        scaleY: mix(.92, 1, kouS),
      ),
      ease(t, SplashBeats.kou.from, SplashBeats.kou.from + 200,
              SplashCurves.out) *
          alive,
    );

    // ---- 香蕉：从右上荡入。水平走 expo、垂直走重力，旋转来回摆几下 ----
    final double bananaP =
        seg(t, SplashBeats.banana.from, SplashBeats.banana.to);
    final double bananaWob = t > SplashBeats.banana.to
        ? 1.9 *
            math.pow(.42, (t - SplashBeats.banana.to) / 420) *
            math.sin((t - SplashBeats.banana.to) / 125)
        : 0;
    final LayerFrame banana = LayerFrame(
      pivotMatrix(
        TiebananaGlyph.bananaPivot,
        translate: TiebananaGlyph.emOffset(
          mix(228, 0, curveAt(SplashCurves.expo, bananaP)),
          mix(-322, 0, curveAt(SplashCurves.gravity, bananaP)),
        ),
        rotate: deg(kf(
              bananaP,
              const <Stop>[
                Stop(0, 62),
                Stop(.58, -16),
                Stop(.8, 6.5),
                Stop(1, 0),
              ],
            ) +
            bananaWob),
        scaleX: mix(.84, 1, curveAt(SplashCurves.back, seg(bananaP, 0, .55))),
        scaleY: mix(.84, 1, curveAt(SplashCurves.back, seg(bananaP, 0, .55))),
      ),
      ease(bananaP, 0, .1, SplashCurves.out) * alive,
    );

    // ---- 叶子：从右侧飘入，带扑翼 ----
    final double leafRaw = seg(t, SplashBeats.leaf.from, SplashBeats.leaf.to);
    final double leafP = curveAt(SplashCurves.back, leafRaw);
    final double flutter =
        math.sin(leafRaw * math.pi * 3.2) * 17 * (1 - leafRaw);
    final double leafWob = t > SplashBeats.leaf.to
        ? 2.3 *
            math.pow(.4, (t - SplashBeats.leaf.to) / 480) *
            math.sin((t - SplashBeats.leaf.to) / 140)
        : 0;
    final LayerFrame leaf = LayerFrame(
      pivotMatrix(
        TiebananaGlyph.leafPivot,
        translate:
            TiebananaGlyph.emOffset(mix(168, 0, leafP), mix(-74, 0, leafP)),
        rotate: deg(kf(
              leafRaw,
              const <Stop>[
                Stop(0, 30),
                Stop(.6, -12),
                Stop(.85, 4.5),
                Stop(1, 0),
              ],
            ) +
            flutter +
            leafWob),
        scaleX: mix(.55, 1, curveAt(SplashCurves.out, leafRaw)),
        scaleY: mix(.55, 1, curveAt(SplashCurves.out, leafRaw)),
      ),
      ease(t, SplashBeats.leaf.from, SplashBeats.leaf.from + 140,
              SplashCurves.out) *
          alive,
    );

    // ---- 落定：整字挤压回弹 + 冲击环 ----
    final double impactK =
        seg(t, SplashBeats.impact.from, SplashBeats.impact.to);
    final double impactS =
        t < SplashBeats.impact.to ? math.sin(math.pi * impactK) : 0;
    final Matrix4 squash = pivotMatrix(
      TiebananaGlyph.markPivot,
      scaleX: 1 + .055 * impactS,
      scaleY: 1 - .062 * impactS,
    );

    final double ringK =
        seg(t, SplashBeats.impact.from, SplashBeats.impact.from + 300);
    final double ringGate =
        seg(t, SplashBeats.impact.from, SplashBeats.impact.from + 40);

    // ---- 呼吸：整体轻微起落，让画面「活着」 ----
    final double holdK = seg(t, SplashBeats.hold.from, SplashBeats.hold.to);
    final Matrix4 breathe = (holdK > 0 && holdK < 1)
        ? pivotMatrix(
            TiebananaGlyph.markPivot,
            scaleX: 1 + math.sin(holdK * math.pi) * .013,
            scaleY: 1 - math.sin(holdK * math.pi) * .013 * .6,
          )
        : Matrix4.identity();

    return MarkFrame._(
      t: t,
      outK: outK,
      bei: bei,
      gv: gv,
      gh: gh,
      zhan: zhan,
      banana: banana,
      leaf: leaf,
      breathe: breathe,
      squash: squash,
      glowRadius: glowRadius,
      glowOpacity: glowOpacity,
      ringRadius: mix(14, 468, curveAt(SplashCurves.out, ringK)),
      ringStroke: mix(17, .5, ringK),
      ringOpacity: (1 - ringK) * ringGate * .7 * alive,
      sparkProgress:
          seg(t, SplashBeats.sparks.from, SplashBeats.sparks.from + 540),
    );
  }

  /// 星火的数量与相位（与概念图一致：7 颗，错开 26ms）。
  static const int sparkCount = 7;
  static const double sparkStaggerMs = 26;
  static const double sparkSpanMs = 540;
  static const double sparkGateMs = 50;

  /// 星火炸开的原点（画布空间，取香蕉落点）。
  static const Offset sparkOrigin = Offset(667, 494);
  static const double sparkMaxDistance = 262;
  static const double sparkMaxSize = 26;
}

/// 光晕的中心（画布空间）。
const Offset _glowCenter = Offset(511, 470);

// ============================================================
// 绘制
// ============================================================

/// 把画布空间的矩阵换算成某个 widget 局部坐标系的矩阵。
///
/// 图片层是 widget：`Positioned` 之后它的局部原点是自己的左上角，
/// 而 [canvasMatrix] 是在 1024 画布空间里写的，所以要先挪回画布原点再套矩阵。
Matrix4 _localize(Matrix4 canvasMatrix, Rect box) {
  if (canvasMatrix.isIdentity()) return canvasMatrix;
  return Matrix4.identity()
    ..translateByDouble(-box.left, -box.top, 0, 1)
    ..multiply(canvasMatrix)
    ..translateByDouble(box.left, box.top, 0, 1);
}

/// 光晕。画在字形后面。
class GlowPainter extends CustomPainter {
  const GlowPainter(this.frame);

  final MarkFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = frame.glowRadius;
    final double a = frame.glowOpacity;
    if (r <= 1 || a <= .002) return;
    final Rect rect = Rect.fromCircle(center: _glowCenter, radius: r);
    canvas.drawCircle(
      _glowCenter,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            SplashBrand.ink.withValues(alpha: .5 * a),
            SplashBrand.ink.withValues(alpha: .14 * a),
            SplashBrand.ink.withValues(alpha: 0),
          ],
          stops: const <double>[0, .55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(GlowPainter old) => old.frame.t != frame.t;
}

/// 「贴」的四个字形图层：卜 丨 / 卜 一 / 贝 / 占 口。
///
/// 「口」直接使用图标轮廓；卜是原字形减去口，再分成两笔。
/// 接口沿真实斜边相接。
class GlyphPainter extends CustomPainter {
  const GlyphPainter(this.frame);

  final MarkFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..isAntiAlias = true;

    // 卜 丨（画在「口」之前，与 svg 的层序一致）
    _layer(
        canvas, paint, frame.gv, TiebananaGlyph.buVRect, TiebananaGlyph.buPath);
    // 卜 一
    _layer(
        canvas, paint, frame.gh, TiebananaGlyph.buHRect, TiebananaGlyph.buPath);
    // 贝
    _layer(canvas, paint, frame.bei, null, TiebananaGlyph.beiPath);
    // 口的独立闭合轮廓，入场和落定时保持笔画干净。
    _layer(canvas, paint, frame.zhan, null, TiebananaGlyph.kouPath);
  }

  void _layer(
    Canvas canvas,
    Paint paint,
    LayerFrame layer,
    Object? clip,
    Path path,
  ) {
    if (layer.opacity <= .001) return;
    canvas.save();
    // 裁剪区要跟着图层一起动（svg 里 mask 挂在被变换的子元素上），
    // 所以先把裁剪路径套上同一个矩阵，再设变换。
    if (clip is Rect) {
      final Path clipPath = Path()..addRect(clip);
      canvas.clipPath(
        layer.transform.isIdentity()
            ? clipPath
            : clipPath.transform(layer.transform.storage),
        // 两笔共用的分界线不做抗锯齿，保持边缘干净。
        // 字形自身仍保留抗锯齿。
        doAntiAlias: false,
      );
    }
    canvas.transform(layer.transform.storage);
    paint.color = SplashBrand.ink.withValues(alpha: layer.opacity.clamp(0, 1));
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(GlyphPainter old) => old.frame.t != frame.t;
}

/// 冲击环与星火。画在字形与图片前面，显示在最上层。
class FxFrontPainter extends CustomPainter {
  const FxFrontPainter(this.frame);

  final MarkFrame frame;

  static final Path _star = Path()
    ..moveTo(0, -1)
    ..cubicTo(.12, -.34, .34, -.12, 1, 0)
    ..cubicTo(.34, .12, .12, .34, 0, 1)
    ..cubicTo(-.12, .34, -.34, .12, -1, 0)
    ..cubicTo(-.34, -.12, -.12, -.34, 0, -1)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final double alive = 1 - frame.outK;

    // 冲击环
    if (frame.ringOpacity > .002) {
      canvas.drawCircle(
        TiebananaGlyph.markPivot,
        frame.ringRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = frame.ringStroke
          ..isAntiAlias = true
          ..color =
              SplashBrand.ink.withValues(alpha: frame.ringOpacity.clamp(0, 1)),
      );
    }

    // 星火：逐颗延迟，炸开并淡出
    final Paint spark = Paint()..isAntiAlias = true;
    for (int i = 0; i < MarkFrame.sparkCount; i++) {
      final double start =
          SplashBeats.sparks.from + i * MarkFrame.sparkStaggerMs;
      final double k = seg(frame.t, start, start + MarkFrame.sparkSpanMs);
      final double gate = seg(frame.t, start, start + MarkFrame.sparkGateMs);
      final double opacity = (1 - k) * gate * .95 * alive;
      if (opacity <= .002) continue;
      final double ang = (i / MarkFrame.sparkCount) * math.pi * 2 + .42;
      final double d =
          mix(30, MarkFrame.sparkMaxDistance, curveAt(SplashCurves.out, k));
      final double s =
          mix(MarkFrame.sparkMaxSize, 0, curveAt(SplashCurves.out, k));
      canvas.save();
      canvas.translate(MarkFrame.sparkOrigin.dx + math.cos(ang) * d,
          MarkFrame.sparkOrigin.dy + math.sin(ang) * d);
      canvas.rotate(ang + .24);
      canvas.scale(s, s);
      spark.color = SplashBrand.ink.withValues(alpha: opacity.clamp(0, 1));
      canvas.drawPath(_star, spark);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(FxFrontPainter old) => old.frame.t != frame.t;
}

/// 图标本体：光晕 → 字形 → 香蕉 → 叶子 → 冲击环/星火。
///
/// 整块按 1024 画布空间布局，再等比缩放到 [size]，
/// 所以这里所有坐标都能直接对着 `tiebanana.svg` 读。
class SplashMark extends StatelessWidget {
  const SplashMark({super.key, required this.t, required this.size});

  /// 设计毫秒（0–3300）。
  final double t;
  final double size;

  @override
  Widget build(BuildContext context) {
    final MarkFrame frame = MarkFrame.of(t);
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 1024,
          height: 1024,
          child: Stack(
            children: <Widget>[
              Positioned.fill(child: CustomPaint(painter: GlowPainter(frame))),
              // 呼吸与挤压要同时作用于字形和香蕉叶子（svg 里它们同属一个组）
              Positioned.fill(
                child: Transform(
                  transform: frame.breathe,
                  child: Transform(
                    transform: frame.squash,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: CustomPaint(painter: GlyphPainter(frame)),
                        ),
                        _image(TiebananaGlyph.leafRect,
                            TiebananaGlyph.leafAsset, frame.leaf),
                        _image(TiebananaGlyph.bananaRect,
                            TiebananaGlyph.bananaAsset, frame.banana),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                  child: CustomPaint(painter: FxFrontPainter(frame))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _image(Rect box, String asset, LayerFrame layer) {
    // 不透明为 0 时也保留在树里：`Opacity(0)` 会整段跳过绘制（零成本），
    // 但图片会提前解码 —— 香蕉落下来（约 1.0s）时直接显示。
    return Positioned(
      left: box.left,
      top: box.top,
      width: box.width,
      height: box.height,
      child: Transform(
        transform: _localize(layer.transform, box),
        child: Opacity(
          opacity: layer.opacity.clamp(0, 1),
          child: Image.asset(
            asset,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
