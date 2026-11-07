"""Generate docs/icon/tiebanana.svg.

Inputs
  - a CJK font (default: ZCOOL KuaiLe) for the 贴 outline
  - banana.png / leaf.png, the cut-out banana artwork
  - stroke boxes detected from a rendered bitmap, so the banana can stand exactly where
    「占」's 丨 was and the leaf where its 一 was

The output keeps {{PLACEHOLDER}} colour names for docs/icon/build_icons.js and
{{BANANA_IMG}} / {{LEAF_IMG}} for the artwork, which build_icons.js inlines as data URIs.
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

from fontTools.misc.transform import Transform
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

HERE = Path(__file__).resolve().parent
BOX_SCRIPT = HERE / "_stroke_boxes.py"

DEFAULT_FONT = Path(__file__).resolve().parent / "fonts" / "ZCOOLKuaiLe-Regular.ttf"


def glyph_path(font, ch, baseline=1000.0):
    gs = font.getGlyphSet()
    gname = font.getBestCmap()[ord(ch)]
    pen = SVGPathPen(gs, ntos=lambda v: f"{v:.1f}")
    gs[gname].draw(TransformPen(pen, Transform(1, 0, 0, -1, 0, baseline)))
    return pen.getCommands()


def stroke_boxes(font_path):
    out = subprocess.run([sys.executable, str(BOX_SCRIPT), str(font_path), "贴"],
                         capture_output=True, text=True, check=True).stdout
    return json.loads(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--font", default=str(DEFAULT_FONT))
    ap.add_argument("--out", default=str(HERE / "tiebanana.svg"))
    ap.add_argument("--banana", default=str(HERE / "banana.png"))
    ap.add_argument("--leaf", default=str(HERE / "leaf.png"))
    # banana placement, in em units (baseline at y=1000)
    ap.add_argument("--banana-height", type=float, default=0.95,
                    help="banana height as a multiple of 口's outer width")
    ap.add_argument("--banana-tip-overlap", type=float, default=12.0,
                    help="how far the banana's tip dips below 口's top edge")
    # leaf placement
    ap.add_argument("--leaf-height", type=float, default=0.32,
                    help="leaf height as a multiple of 口's outer width")
    ap.add_argument("--leaf-center-drop", type=float, default=0.58,
                    help="leaf centre, as a fraction of 卜 height below 口's top")
    ap.add_argument("--leaf-right", type=float, default=950.0)
    # canvas
    ap.add_argument("--scale", type=float, default=0.95)
    args = ap.parse_args()

    font = TTFont(args.font)
    path = glyph_path(font, "贴")
    if Path(args.font).stem == "ZCOOLKuaiLe-Regular":
        # The font joins 卜 to 口 in the first contour. A horizontal mask leaves
        # a stump above 口's sloping top edge; remove 卜 from the contour itself.
        # Keep the original mouth corners, 贝 and the counter unchanged.
        _, rest = path.split("Z", 1)
        path = ("M836.0 555.0 887.0 608.0 843.0 1013.0 797.0 1054.0 "
                "506.0 1055.0 458.0 1014.0 414.0 647.0 457.0 594.0Z" + rest)
    info = stroke_boxes(args.font)

    ink = info["ink"]
    mouth_top = info["mouthTopY"]
    counter = info["mouthCounterBox"]
    wall = info["wall"]
    # 占's column starts at 口's outer left edge; everything above 口 in that column is 卜
    zhan_left = counter[0] - wall
    v_top = info["vertical"][1] if info["vertical"] else ink[1]
    body_h = mouth_top - v_top          # height of 占's 卜 (丨) stroke
    mouth_cx = (counter[0] + counter[2]) / 2.0

    bw, bh = 479.0, 880.0         # banana.png aspect
    mouth_w = counter[2] - counter[0] + 2 * wall
    banana_h = args.banana_height * mouth_w
    banana_w = banana_h * bw / bh
    chord_ratio = 0.92            # where the banana's stem-tip chord sits in banana.png
    banana_x = mouth_cx - chord_ratio * banana_w
    # keep the belly clear of 贝's right edge
    banana_x = max(banana_x, zhan_left - 24.0)
    banana_y = mouth_top + args.banana_tip_overlap - banana_h

    lw, lh = 369.0, 182.0         # leaf.png aspect
    leaf_h = args.leaf_height * mouth_w
    leaf_w = leaf_h * lw / lh
    leaf_x = args.leaf_right - leaf_w
    leaf_y = (mouth_top - args.leaf_center_drop * body_h) - leaf_h / 2.0

    # mask: 占's whole 卜 (丨 + 一) is dropped; the banana and leaf take its place
    cut_v = [zhan_left - 16, ink[1] - 24, ink[2] + 24, mouth_top - 2]
    cut_h = None

    # content box -> canvas
    content = [min(ink[0], banana_x), min(ink[1], banana_y, leaf_y),
               max(ink[2], banana_x + banana_w, leaf_x + leaf_w),
               max(ink[3], banana_y + banana_h, leaf_y + leaf_h)]
    cw, chh = content[2] - content[0], content[3] - content[1]
    s = args.scale
    tx = 512 - (content[0] + cw / 2) * s
    ty = 512 - (content[1] + chh / 2) * s

    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <!--
    Tiebanana 应用图标模板，由 docs/icon/build_svg.py 生成。

    概念：贴 = 贝 + 占；香蕉顶替「占」的竖笔（丨），香蕉叶顶替「占」顶部的短横（一）。
    字形：{Path(args.font).stem} 的「贴」轮廓，已转为路径，渲染不依赖系统字体。
    香蕉与叶子：透明 PNG（banana.png / leaf.png），由 build_icons.js 内联。

    {{{{...}}}} 是调色板占位符，见 build_icons.js。
  -->
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{{{{BG_A}}}}"/>
      <stop offset="1" stop-color="{{{{BG_B}}}}"/>
    </linearGradient>

    <!-- 抠掉「占」的整段「卜」（丨 + 一），交给香蕉和叶子 -->
    <mask id="glyphCut">
      <rect x="-600" y="-600" width="3000" height="3000" fill="#ffffff"/>
      <rect x="{cut_v[0]:.0f}" y="{cut_v[1]:.0f}" width="{cut_v[2]-cut_v[0]:.0f}" height="{cut_v[3]-cut_v[1]:.0f}" fill="#000000"/>
    </mask>
  </defs>

  <rect x="0" y="0" width="1024" height="1024" fill="url(#bg)"/>

  <g transform="translate({tx:.2f},{ty:.2f}) scale({s})">
    <g mask="url(#glyphCut)" fill="{{{{INK}}}}">
      <path d="{path}"/>
    </g>
    <image x="{leaf_x:.0f}" y="{leaf_y:.0f}" width="{leaf_w:.0f}" height="{leaf_h:.0f}" href="{{{{LEAF_IMG}}}}"/>
    <image x="{banana_x:.0f}" y="{banana_y:.0f}" width="{banana_w:.0f}" height="{banana_h:.0f}" href="{{{{BANANA_IMG}}}}"/>
  </g>
</svg>
'''
    Path(args.out).write_text(svg, encoding="utf-8")
    print(f"wrote {args.out}")
    print(f"  glyph ink   {[round(x) for x in ink]}")
    print(f"  口 top      {round(mouth_top)}  counter {[round(x) for x in counter]} wall {wall}")
    print(f"  卜 height   {round(body_h)} (from {round(v_top)} to {round(mouth_top)})  口 width {round(mouth_w)}")
    print(f"  cut         {[round(x) for x in cut_v]}")
    print(f"  banana      x={banana_x:.0f} y={banana_y:.0f} w={banana_w:.0f} h={banana_h:.0f}")
    print(f"  leaf        x={leaf_x:.0f} y={leaf_y:.0f} w={leaf_w:.0f} h={leaf_h:.0f}")
    print(f"  transform   translate({tx:.2f},{ty:.2f}) scale({s})  content {cw:.0f}x{chh:.0f}")


main()
