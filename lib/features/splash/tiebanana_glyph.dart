import 'dart:ui';

import 'package:flutter/widgets.dart' show Matrix4;

/// 「贴」的字形几何。
///
/// 所有数值对应 `docs/icon/tiebanana.svg`（由 `docs/icon/build_svg.py`
/// 生成，勿手改）。图标若重新生成，这里要同步。
///
/// svg 里字形、香蕉、叶子都装在
/// `<g transform="translate(45.08,-52.01) scale(0.95)">` 这个组里，坐标是「em 空间」。
/// 本文件把 em 空间的值换算到 **1024 画布空间** 之后再对外暴露，
/// 于是字形（painter）、香蕉叶子（widget）、特效三边共用同一套坐标，
/// 绘制时无需重复变换。
class TiebananaGlyph {
  const TiebananaGlyph._();

  // ---------------- em 空间 → 1024 画布空间 ----------------

  static const double _ox = 45.08;
  static const double _oy = -52.01;

  /// svg 里那个组变换的缩放系数。
  /// 图标内部一切长度（位移量）从 em 换算到画布都要乘它。
  static const double emScale = 0.95;

  static Offset _at(double x, double y) =>
      Offset(_ox + emScale * x, _oy + emScale * y);

  static Rect _box(double x, double y, double w, double h) => Rect.fromLTRB(
        _ox + emScale * x,
        _oy + emScale * y,
        _ox + emScale * (x + w),
        _oy + emScale * (y + h),
      );

  /// 把 em 空间的位移量换算成画布空间的位移量。
  static Offset emOffset(double dx, double dy) =>
      Offset(emScale * dx, emScale * dy);

  // ---------------- 字形路径 ----------------

  /// 动画书写阶段保留原字体的「占」，落定的「口」使用修正后的图标轮廓。
  /// 三段 subpath，顺序与 svg 一致：
  ///   0 → 原字形「占」的外轮廓（含 丨 一）
  ///   1 → 「贝」
  ///   2 → 「口」的字腔（洞）
  static const String _d = 'M679.0 478.0 686.0 571.0 836.0 555.0 887.0 608.0 '
      '843.0 1013.0 797.0 1054.0 506.0 1055.0 458.0 1014.0 414.0 647.0 '
      '457.0 594.0 593.0 580.0 566.0 233.0 659.0 225.0 671.0 383.0 856.0 355.0 '
      '871.0 449.0Z'
      'M212.0 821.0 219.0 808.0 384.0 895.0 342.0 978.0 189.0 899.0 144.0 1054.0 '
      '54.0 1028.0 142.0 725.0 68.0 732.0 33.0 335.0 78.0 284.0 377.0 269.0 '
      '427.0 320.0 392.0 720.0 298.0 713.0 328.0 365.0 132.0 377.0 157.0 672.0 '
      '219.0 459.0 311.0 485.0Z'
      'M514.0 683.0 547.0 962.0 754.0 960.0 787.0 655.0Z';

  static final Matrix4 _markMatrix = Matrix4.identity()
    ..translateByDouble(_ox, _oy, 0, 1)
    ..scaleByDouble(emScale, emScale, 1, 1);

  static final List<Path> _subpaths = _parseSubpaths(_d);

  /// 「贝」：第二段 subpath。
  static final Path beiPath = _subpaths[1].transform(_markMatrix.storage);

  /// 「占」：外轮廓 + 字腔。fillType 用默认的 nonZero，
  /// 字腔靠相反的绕向被挖成洞 —— 与 svg 的行为一致。
  static final Path zhanPath = () {
    final Path p = Path()
      ..addPath(_subpaths[0], Offset.zero)
      ..addPath(_subpaths[2], Offset.zero);
    return p.transform(_markMatrix.storage);
  }();

  /// 与应用图标一致的干净「口」；上沿是一条连续斜线，没有卜的残笔。
  static final Path kouPath = (Path()
        ..addPath(
          _parseSubpaths('M836 555 887 608 843 1013 797 1054 '
                  '506 1055 458 1014 414 647 457 594Z')
              .single,
          Offset.zero,
        )
        ..addPath(_subpaths[2], Offset.zero))
      .transform(_markMatrix.storage);

  /// 沿「口」真实上沿拆出卜，切口与图标轮廓吻合。
  static final Path buPath =
      Path.combine(PathOperation.difference, zhanPath, kouPath);

  /// 把 svg 里那种「`M x y x y … Z`」的折线路径解析成若干 subpath。
  ///
  /// 图标路径只用了 `M` / `L` / `Z`（移动之后的坐标对是隐式 lineto），
  /// 这里用简单折线解析即可。
  static List<Path> _parseSubpaths(String d) {
    final List<Path> out = <Path>[];
    Path? current;
    bool started = false;
    double? pendingX;
    for (final String tk in d
        .replaceAll('M', ' M ')
        .replaceAll('Z', ' Z ')
        .split(RegExp(r'\s+'))) {
      if (tk.isEmpty) continue;
      if (tk == 'M') {
        current = Path();
        out.add(current);
        started = false;
        pendingX = null;
        continue;
      }
      if (tk == 'Z') {
        current?.close();
        started = false;
        pendingX = null;
        continue;
      }
      final double v = double.parse(tk);
      if (pendingX == null) {
        pendingX = v;
        continue;
      }
      assert(current != null, '路径必须以 M 开头');
      if (started) {
        current!.lineTo(pendingX, v);
      } else {
        current!.moveTo(pendingX, v);
        started = true;
      }
      pendingX = null;
    }
    return out;
  }

  // ---------------- 卜的两笔裁剪区（只裁 buPath） ----------------

  static final Rect buVRect = _box(500, 201, 171, 400);
  static final Rect buHRect = _box(671, 201, 239, 400);

  // ---------------- 支点（画布空间，取自 svg 的坐标） ----------------

  /// 贝的底部中心。
  static final Offset beiPivot = _at(230, 1054);

  /// 口的中心。
  static final Offset kouPivot = _at(650, 810);

  /// 丨的顶端 —— 「写」这一笔时绕它往下长。
  static final Offset gvTopPivot = _at(612, 225);

  /// 丨的底端 —— 被顶替时绕它往下缩（像沉进口里）。
  static final Offset gvBottomPivot = _at(612, 578.05);

  /// 一的左端 —— 写与退都用它做支点。
  static final Offset ghPivot = _at(620, 399);

  /// 整字重心，落定挤压与呼吸都绕它。
  static final Offset markPivot = _at(490, 600);

  /// 香蕉下端的尖 —— 荡入时的摆动支点。
  static final Offset bananaPivot = _at(655, 575);

  /// 叶子左端 —— 飘入时的支点。
  static final Offset leafPivot = _at(646, 368);

  // ---------------- 香蕉 / 叶子在画布上的落位 ----------------

  static final Rect bananaRect = _box(427, 133, 242, 445);
  static final Rect leafRect = _box(646, 293, 304, 150);

  /// 素材路径（`assets/` 下，见 pubspec.yaml）。
  static const String bananaAsset = 'assets/splash/banana.png';
  static const String leafAsset = 'assets/splash/leaf.png';
}
