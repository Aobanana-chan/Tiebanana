"""Locate 占's 丨 and 一 strokes from a rendered bitmap (font-agnostic).

Prints JSON with boxes in the em space used by tiebanana.svg:
y-down, baseline at y = 1000, glyph rendered at 1000px so 1px == 1 unit.
"""
import json
import sys
from collections import deque

import numpy as np
from PIL import Image, ImageDraw, ImageFont

font_path = sys.argv[1]
ch = sys.argv[2] if len(sys.argv) > 2 else "占"
size = 1000

font = ImageFont.truetype(font_path, size)
img = Image.new("L", (size * 2, size * 2), 0)
d = ImageDraw.Draw(img)
# anchor "ls" = left baseline
d.text((size // 2, size), ch, font=font, fill=255, anchor="ls")
a = np.asarray(img)
ys, xs = np.nonzero(a > 128)
ox, oy = xs.min(), ys.min()
crop = a[oy:ys.max() + 1, ox:xs.max() + 1]
mask = crop > 128

# outside = background connected to the border
h, w = mask.shape
outside = np.zeros_like(mask)
dq = deque()
for x in range(w):
    for y in (0, h - 1):
        if not mask[y, x] and not outside[y, x]:
            outside[y, x] = True
            dq.append((y, x))
for y in range(h):
    for x in (0, w - 1):
        if not mask[y, x] and not outside[y, x]:
            outside[y, x] = True
            dq.append((y, x))
while dq:
    y, x = dq.popleft()
    for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
        if 0 <= ny < h and 0 <= nx < w and not mask[ny, nx] and not outside[ny, nx]:
            outside[ny, nx] = True
            dq.append((ny, nx))

holes = (~mask) & (~outside)
# group holes and report them all; the biggest one is 口's counter
lab = np.zeros_like(holes, dtype=np.int32)
found = []
cur = 0
for y0, x0 in zip(*np.nonzero(holes)):
    if lab[y0, x0]:
        continue
    cur += 1
    q = deque([(y0, x0)])
    lab[y0, x0] = cur
    pts = []
    while q:
        y, x = q.popleft()
        pts.append((y, x))
        for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= ny < h and 0 <= nx < w and holes[ny, nx] and not lab[ny, nx]:
                lab[ny, nx] = cur
                q.append((ny, nx))
    found.append(pts)

found.sort(key=len, reverse=True)
all_holes = []
for pts in found:
    hy = [p[0] for p in pts]
    hx = [p[1] for p in pts]
    all_holes.append([min(hx), min(hy), max(hx), max(hy), len(pts)])

best = found[0]
hy = [p[0] for p in best]
hx = [p[1] for p in best]
hx0, hx1, hy0, hy1 = min(hx), max(hx), min(hy), max(hy)
mid = (hy0 + hy1) // 2
row = mask[mid]
# wall thickness of 口 at that row
runs = []
x = 0
while x < w:
    if row[x]:
        s = x
        while x < w and row[x]:
            x += 1
        runs.append((s, x - 1))
    else:
        x += 1
wall = runs[0][1] - runs[0][0] + 1 if runs else 0

# 口's outer top edge: walk up from the counter at a column with no 卜 above it
col = min(hx1 - wall // 2, w - 1)
top = hy0
while top > 0 and mask[top - 1, col]:
    top -= 1
mouth_top = top if mask[top, col] else hy0 - wall

# rows above the mouth, restricted to 占's own column = the 卜 strokes
x_lo = max(0, hx0 - wall - 10)
above = mask[:mouth_top, x_lo:]
rows = []
for y in range(above.shape[0]):
    r = np.nonzero(above[y])[0]
    if len(r):
        rows.append((y, r.min() + x_lo, r.max() + x_lo, len(r)))
vert_rows = [r for r in rows if (r[2] - r[1] + 1) <= 1.8 * wall]
if vert_rows:
    vx0 = min(r[1] for r in vert_rows)
    vx1 = max(r[2] for r in vert_rows)
else:
    vx0 = vx1 = 0
# 一 rows: ink reaching clearly past the 丨 column on either side
horz_rows = [r for r in rows
             if r[1] < vx0 - wall * 0.6 or r[2] > vx1 + wall * 0.6]
# keep only the contiguous band closest to the top of the 丨
if horz_rows:
    ys_ = sorted(r[0] for r in horz_rows)
    band, cur_band = [], [ys_[0]]
    for y in ys_[1:]:
        if y - cur_band[-1] <= 3:
            cur_band.append(y)
        else:
            band.append(cur_band)
            cur_band = [y]
    band.append(cur_band)
    best_band = max(band, key=len)
    horz_rows = [r for r in horz_rows if r[0] in set(best_band)]
    # drop the rows that belong to the 丨 body (they only clip the 一 near its ends)
    horz_rows = [r for r in horz_rows if r[2] > vx1 + wall * 1.2]


def box(rs):
    if not rs:
        return None
    y0 = min(r[0] for r in rs)
    y1 = max(r[0] for r in rs)
    x0 = min(r[1] for r in rs)
    x1 = max(r[2] for r in rs)
    return [x0, y0, x1, y1]


def to_font(b, size=size, ox=ox, oy=oy, pen_x=size // 2):
    """bitmap coords -> em space of the glyph outline (y-down, baseline at y = size)"""
    if b is None:
        return None
    return [int(b[0] + ox - pen_x), int(b[1] + oy), int(b[2] + ox - pen_x), int(b[3] + oy)]


out = {
    "font": font_path,
    "char": ch,
    "wall": int(wall),
    "mouthCounterBox": to_font([hx0, hy0, hx1, hy1]),
    "mouthTopY": int(mouth_top + oy),
    "vertical": to_font(box(vert_rows)),
    "horizontal": to_font(box(horz_rows)),
    "ink": to_font([0, 0, w - 1, h - 1]),
    "holes": [to_font(b[:4]) for b in all_holes],
    "holeAreas": [int(b[4]) for b in all_holes],
}
print(json.dumps(out, ensure_ascii=False))
