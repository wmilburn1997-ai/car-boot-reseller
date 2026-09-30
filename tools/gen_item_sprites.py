#!/usr/bin/env python3
"""Procedural 32x32 pixel-art item sprites for Car Boot Reseller.

One sprite per item *family* (the dicts in scripts/data/cat_*.gd FAMILIES).
Each family is mapped by keywords in its name to one of ~100 hand-designed
base shapes; colours vary deterministically per family (hash of the name)
within palettes that suit the object.

Writes:
  art/items/<slug>.png          32x32 RGBA, transparent bg, 1px dark outline
  scripts/data/item_art.gd      const ITEM_ART = {"Family Name": "res://art/items/slug.png", ...}

Options:
  --sheet PATH   also write a x3 contact sheet with names (default /tmp/item_contact_sheet.png)
  --scale N      write sprites upscaled xN with nearest neighbour (default 1 = native 32x32)

Run from anywhere:  python3 tools/gen_item_sprites.py
Requires Pillow. Deterministic.
"""
import colorsys
import glob
import hashlib
import math
import os
import random
import re
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTDIR = os.path.join(ROOT, "art", "items")
GD_OUT = os.path.join(ROOT, "scripts", "data", "item_art.gd")
S = 32


def hx(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


OUT = hx("141018")          # outline, same as tools/gen_art.py


# ------------------------------------------------------------------ colour ramps
def _shift(h, target, amt):
    d = (target - h + 0.5) % 1.0 - 0.5
    if abs(d) < amt:
        return target % 1.0
    return (h + math.copysign(amt, d)) % 1.0


class Ramp:
    """e(xtra light) l(ight) m(id) d(ark) x (deepest). Hue-shifted: lights lean warm, darks lean cool."""

    def __init__(self, base):
        r, g, b = [int(base[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        k = min(1.0, s * 1.5)

        def mk(dl, target, amt, ds):
            hh = _shift(h, target, amt * k)
            ll = min(0.96, max(0.05, l + dl))
            ss = min(1.0, max(0.0, s + ds))
            return tuple(int(round(v * 255)) for v in colorsys.hls_to_rgb(hh, ll, ss)) + (255,)

        self.base = base
        self.e = mk(+0.24, 0.14, 0.05, -0.05)
        self.l = mk(+0.12, 0.14, 0.025, 0.0)
        self.m = mk(0.0, h, 0.0, 0.0)
        self.d = mk(-0.13, 0.70, 0.03, 0.04)
        self.x = mk(-0.23, 0.72, 0.05, 0.04)


PAL = dict(
    red="c8413a", crimson="a3303c", orange="e07b39", amber="e89a3a", yellow="e8c547", mustard="c9a13b",
    lime="8cc152", green="4f9a4a", forest="2f6b3f", mint="7fcfa0", teal="2fb3a6", sky="5fa8e0",
    blue="3f6fc4", navy="2b3f7a", purple="7a4fb0", violet="9b6bd0", pink="e0709a", magenta="c2408f",
    cream="efe3c4", white="e3e6ee", grey="8d91a0", slate="5a6070", black="3c3e4c", charcoal="30323e",
    brown="8a5a3a", tan="c08a55", oak="b8844f", teak="a3632f", walnut="6e4428", mahogany="7a3a2a",
    pine="d4a86c", gold="e0b04a", brass="c9a040", silver="b4b9c6", steel="8a93a6", chrome="c9cdd8",
    copper="c47a45", bronze="a8753a", denim="3f6a9e", khaki="a39b62", olive="6b7040", leather="7a4a2e",
    tweed="8a7355", terracotta="c0643a", stone="9d998c", glass="a9d3e3", paper="ece0bf", kraft="b88a55",
    skin="e2b08a", vinyl="3a3a46", jet="2a2a36", pearl="ece6da", ruby="d0304a", sapphire="3a64d8",
    emerald="2fa865", amethyst="9b4fd0", diamond="cfeaff", wine="7a2440", rust="a0462a",
    lcd="9fb86a", screen="2a3a4a", cork="c49a6a", galv="a2abb2", ivory="eee6cc", plum="6a3a6a",
)
_rc = {}


def C(name):
    """Ramp for a palette name or a hex string."""
    key = PAL.get(name, name)
    if key not in _rc:
        _rc[key] = Ramp(key)
    return _rc[key]


def pick(rng, seq):
    return seq[rng.randrange(len(seq))]


def picks(rng, seq, n):
    seq = list(seq)
    rng.shuffle(seq)
    return seq[:n]


# ------------------------------------------------------------------ masks
def R(x0, y0, x1, y1):
    x0, y0, x1, y1 = (int(math.floor(v)) for v in (x0, y0, x1, y1))
    return {(x, y) for x in range(min(x0, x1), max(x0, x1) + 1) for y in range(min(y0, y1), max(y0, y1) + 1)}


def RR(x0, y0, x1, y1, r=1):
    """Rect with chamfered (pixel-rounded) corners."""
    x0, y0, x1, y1 = (int(math.floor(v)) for v in (x0, y0, x1, y1))
    out = set()
    for (x, y) in R(x0, y0, x1, y1):
        cx = min(x - x0, x1 - x)
        cy = min(y - y0, y1 - y)
        if cx + cy >= r:
            out.add((x, y))
    return out


def E(cx, cy, rx, ry=None, k=1.0):
    ry = rx if ry is None else ry
    out = set()
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= k + 0.04:
                out.add((x, y))
    return out


def ring(cx, cy, ro, ri, ryo=None, ryi=None):
    return E(cx, cy, ro, ryo) - E(cx, cy, ri, ryi)


def _segdist(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    L2 = dx * dx + dy * dy
    t = 0.0 if L2 == 0 else max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / L2))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def P(*pts):
    """Polygon; vertices are pixel centres, edges inclusive."""
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    out = set()
    n = len(pts)
    for y in range(int(min(ys)) - 1, int(max(ys)) + 2):
        for x in range(int(min(xs)) - 1, int(max(xs)) + 2):
            inside = False
            for i in range(n):
                (xa, ya), (xb, yb) = pts[i], pts[(i + 1) % n]
                if (ya > y) != (yb > y):
                    xi = xa + (y - ya) * (xb - xa) / (yb - ya)
                    if x < xi:
                        inside = not inside
            if not inside:
                for i in range(n):
                    (xa, ya), (xb, yb) = pts[i], pts[(i + 1) % n]
                    if _segdist(x, y, xa, ya, xb, yb) <= 0.5:
                        inside = True
                        break
            if inside:
                out.add((x, y))
    return out


def L(x0, y0, x1, y1, w=1.0):
    """Line; w<=1 is a crisp Bresenham line, otherwise a thick capsule."""
    if w <= 1.0:
        out = set()
        x0, y0, x1, y1 = int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1))
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx + dy
        while True:
            out.add((x0, y0))
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy
        return out
    out = set()
    r = w / 2.0
    for y in range(int(min(y0, y1) - r) - 1, int(max(y0, y1) + r) + 2):
        for x in range(int(min(x0, x1) - r) - 1, int(max(x0, x1) + r) + 2):
            if _segdist(x, y, x0, y0, x1, y1) <= r:
                out.add((x, y))
    return out


def PL(pts, w=1.0):
    out = set()
    for a, b in zip(pts, pts[1:]):
        out |= L(a[0], a[1], b[0], b[1], w)
    return out


def shift(m, dx, dy):
    return {(x + dx, y + dy) for (x, y) in m}


def mirror(m, axis=15.5):
    return m | {(int(round(2 * axis - x)), y) for (x, y) in m}


# ------------------------------------------------------------------ painters
def flat(c):
    return lambda x, y, m: c


def bev(r, hi=None, lo=None, mid=None):
    hi = hi or r.l
    lo = lo or r.d
    mid = mid or r.m

    def f(x, y, m):
        t = (x, y - 1) not in m or (x - 1, y) not in m
        b = (x, y + 1) not in m or (x + 1, y) not in m
        if t and not b:
            return hi
        if b and not t:
            return lo
        return mid
    return f


def sph(r, cx, cy, rad, spec=True):
    lx, ly = cx - rad * 0.38, cy - rad * 0.42

    def f(x, y, m):
        d = math.hypot(x - lx, y - ly) / (rad * 1.4)
        if spec and d < 0.10:
            return r.e
        if d < 0.40:
            return r.l
        if d < 0.80:
            return r.m
        return r.d
    return f


def cylx(r, x0, x1, spec=False):
    def f(x, y, m):
        t = (x - x0) / max(1.0, (x1 - x0))
        if spec and 0.2 <= t < 0.3:
            return r.e
        if t < 0.12:
            return r.m
        if t < 0.38:
            return r.l
        if t < 0.74:
            return r.m
        return r.d
    return f


def cyly(r, y0, y1, spec=False):
    def f(x, y, m):
        t = (y - y0) / max(1.0, (y1 - y0))
        if spec and 0.2 <= t < 0.3:
            return r.e
        if t < 0.12:
            return r.m
        if t < 0.38:
            return r.l
        if t < 0.74:
            return r.m
        return r.d
    return f


def vgrad(cols, y0, y1):
    def f(x, y, m):
        t = (y - y0) / max(1.0, (y1 - y0 + 1))
        return cols[min(len(cols) - 1, int(t * len(cols)))]
    return f


# ------------------------------------------------------------------ sprite canvas
class Spr:
    def __init__(self):
        self.px = {}
        self.ox = 0
        self.oy = 0

    def put(self, x, y, c):
        x += self.ox
        y += self.oy
        if c is not None and 0 <= x < S and 0 <= y < S:
            self.px[(x, y)] = c

    def draw(self, mask, paint, ol=True):
        """Paint a part: its own 1px outline ring (4-neighbour) first, then the fill.
        Parts are drawn back-to-front so front parts get separated from back parts."""
        mask = set(mask)
        if ol:
            for (x, y) in mask:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    q = (x + dx, y + dy)
                    if q not in mask:
                        self.put(q[0], q[1], OUT)
        for (x, y) in mask:
            c = paint(x, y, mask) if callable(paint) else paint
            self.put(x, y, c)

    def fill(self, mask, c):
        for (x, y) in mask:
            self.put(x, y, c(x, y) if callable(c) else c)

    def rect(self, x0, y0, x1, y1, c):
        self.fill(R(x0, y0, x1, y1), c)

    def line(self, x0, y0, x1, y1, c):
        self.fill(L(x0, y0, x1, y1), c)

    def pts(self, lst, c):
        for (x, y) in lst:
            self.put(x, y, c)

    def get(self, x, y):
        return self.px.get((x + self.ox, y + self.oy))

    def image(self):
        # final silhouette outline (catches parts drawn with ol=False)
        solid = set(self.px)
        for (x, y) in list(solid):
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q = (x + dx, y + dy)
                if q not in solid and 0 <= q[0] < S and 0 <= q[1] < S:
                    self.px[q] = OUT
        im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        pix = im.load()
        for (x, y), c in self.px.items():
            pix[x, y] = c
        return im


# ------------------------------------------------------------------ shared motifs
def star5(cx, cy, r):
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.45
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return P(*pts)


def text_lines(s, x0, x1, y0, y1, c, step=2, rng=None):
    """Little 'text' rows of dashes."""
    for y in range(y0, y1 + 1, step):
        xe = x1 if rng is None else x1 - rng.randrange(0, max(1, (x1 - x0) // 2))
        s.rect(x0, y, xe, y, c)


def glass_glint(s, x, y, c, n=2):
    for i in range(n):
        s.put(x + i, y + i, c)


BRIGHTS = ["red", "orange", "yellow", "green", "teal", "sky", "blue", "purple", "pink", "magenta", "lime", "crimson",
           "navy", "forest", "amber", "violet"]
COVERS = ["red", "crimson", "blue", "navy", "green", "forest", "mustard", "teal", "purple", "brown", "black", "orange",
          "plum", "sky", "wine"]
WOODS = ["oak", "teak", "walnut", "mahogany", "pine", "brown"]
PLASTICS = ["black", "charcoal", "grey", "slate", "cream", "white", "silver"]


def contrast(rng, bgname, pool=BRIGHTS):
    pool = [p for p in pool if p != bgname]
    return pick(rng, pool)


# ======================================================================= SHAPES
# Every shape: fn(s, rng, name, **opts). Coordinates 0..31, keep art inside 1..30.

# ---------------------------------------------------------------- music media
def vinyl_disc(s, cx, cy, rad, lab, hole=1.0, grooves=True, pic=None):
    rv = C("vinyl")
    lr = rad * 0.34 if pic is None else 0

    def f(x, y, m):
        d = math.hypot(x - cx, y - cy)
        if d <= hole:
            return OUT
        if d <= lr:
            return lab.l if (x - cx) + (y - cy) < -0.5 else lab.m
        a = math.degrees(math.atan2(y - cy, x - cx))
        if pic is not None:
            return pic(x, y, d, a)
        sheen = (-70 <= a <= -35) or (110 <= a <= 145)
        if d > rad - 0.8:
            return rv.l if sheen else rv.m
        if sheen and d > lr + 1.2:
            return rv.e if int(d) % 3 == 0 else rv.l
        if grooves and int(d) % 2 == 0:
            return rv.d
        return rv.m
    s.draw(E(cx, cy, rad), f)


def sleeve_art(s, rng, name, x0, y0, x1, y1):
    n = name.lower()
    bgn = pick(rng, COVERS + ["cream", "white", "yellow", "pink", "teal"])
    motif = pick(rng, ["circle", "stripes", "band", "frame", "face", "diamond"])
    fg = None
    if "jazz" in n:
        bgn, motif = pick(rng, ["navy", "black", "blue"]), pick(rng, ["band", "circle", "face"])
    elif "punk" in n:
        bgn, motif, fg = pick(rng, ["pink", "yellow", "lime"]), pick(rng, ["stripes", "diamond"]), "black"
    elif "reggae" in n:
        bgn, motif = "black", "rasta"
    elif "metal" in n:
        bgn, motif, fg = "black", "bolt", pick(rng, ["red", "silver"])
    elif "christmas" in n:
        bgn, motif, fg = pick(rng, ["red", "crimson"]), "tree", "green"
    elif "classical" in n:
        bgn, motif, fg = pick(rng, ["cream", "navy", "wine"]), "frame", "gold"
    elif "prog" in n:
        bgn, motif = pick(rng, ["purple", "teal", "navy"]), "circle"
    elif "soundtrack" in n:
        bgn, motif = pick(rng, ["black", "navy", "crimson"]), "face"
    elif "easy listening" in n:
        bgn, motif = pick(rng, ["sky", "pink", "cream", "mint"]), "face"
    elif "folk" in n:
        bgn, motif = pick(rng, ["forest", "olive", "brown", "cream"]), "circle"
    elif "comedy" in n or "spoken" in n:
        bgn, motif = pick(rng, ["yellow", "orange"]), "face"
    elif "japanese" in n:
        bgn, motif, fg = "white", "sun", "red"
    elif "surf" in n or "exotica" in n:
        bgn, motif = pick(rng, ["teal", "sky"]), "waves"
    elif "rock" in n:
        motif = pick(rng, ["circle", "diamond", "face", "stripes"])
    bg = C(bgn)
    fg = C(fg or contrast(rng, bgn))
    s.draw(R(x0, y0, x1, y1), bev(bg))
    ix0, iy0, ix1, iy1 = x0 + 1, y0 + 1, x1 - 1, y1 - 1
    cx, cy = (x0 + x1) / 2.0, (y0 + y1) / 2.0
    w = x1 - x0
    if motif == "circle":
        s.draw(E(cx, cy + 1, w * 0.3), sph(fg, cx, cy + 1, w * 0.3), ol=False)
    elif motif == "sun":
        s.fill(E(cx, cy, w * 0.26), fg.m)
    elif motif == "stripes":
        for (x, y) in R(ix0, iy0, ix1, iy1):
            if (x + y) % 6 < 2:
                s.put(x, y, fg.m)
    elif motif == "band":
        s.rect(ix0, int(cy) - 2, ix1, int(cy) + 2, fg.m)
        s.rect(ix0, int(cy) - 2, ix1, int(cy) - 2, fg.l)
        s.rect(ix0 + 2, int(cy) + 5, ix0 + 7, int(cy) + 5, bg.e)
    elif motif == "frame":
        for (x, y) in R(ix0 + 1, iy0 + 1, ix1 - 1, iy1 - 1) - R(ix0 + 2, iy0 + 2, ix1 - 2, iy1 - 2):
            s.put(x, y, fg.m)
        s.fill(E(cx, cy, 3), fg.l)
    elif motif == "face":
        skin = C(pick(rng, ["skin", "tan", "brown"]))
        s.fill(E(cx, cy - 1, 3.5, 4), skin.m)
        s.fill(E(cx - 1, cy - 2, 1.5, 2), skin.l)
        s.fill(P((cx - 7, iy1), (cx - 4, cy + 4), (cx + 4, cy + 4), (cx + 7, iy1)), fg.m)
        s.fill(E(cx, cy - 4, 4, 2.5) - E(cx, cy - 1, 3.5, 4), C(pick(rng, ["black", "brown", "yellow", "orange"])).m)
    elif motif == "diamond":
        s.fill(P((cx, iy0 + 2), (ix1 - 2, cy), (cx, iy1 - 2), (ix0 + 2, cy)), fg.m)
        s.fill(P((cx, iy0 + 2), (ix1 - 2, cy), (cx, cy)), fg.l)
    elif motif == "rasta":
        h = (iy1 - iy0 + 1) // 3
        for i, cn in enumerate(["red", "yellow", "green"]):
            s.rect(ix0, iy0 + i * h, ix1, iy0 + (i + 1) * h - 1 if i < 2 else iy1, C(cn).m)
    elif motif == "bolt":
        s.fill(P((cx + 2, iy0 + 2), (cx - 4, cy + 1), (cx, cy + 1), (cx - 2, iy1 - 2), (cx + 4, cy - 1), (cx, cy - 1)), fg.m)
    elif motif == "tree":
        s.fill(P((cx, iy0 + 3), (cx + 6, iy1 - 4), (cx - 6, iy1 - 4)), fg.m)
        s.fill(P((cx, iy0 + 3), (cx + 6, iy1 - 4), (cx, iy1 - 4)), fg.d)
        s.rect(int(cx), iy1 - 3, int(cx) + 1, iy1 - 2, C("brown").m)
        s.put(int(cx), iy0 + 2, C("yellow").e)
    elif motif == "waves":
        for (x, y) in R(ix0, iy0 + 6, ix1, iy1):
            if (y + int(2 * math.sin(x * 0.9))) % 4 == 0:
                s.put(x, y, C("white").m)
        s.fill(E(cx + 3, iy0 + 4, 2.5), C("yellow").l)
    # title strip
    if motif not in ("rasta", "stripes", "sun"):
        s.rect(ix0 + 1, iy0 + 1, ix0 + 1 + rng.randrange(4, 8), iy0 + 1, bg.e if bgn not in ("white", "cream", "yellow") else C("black").m)
    if motif == "sun":  # obi strip
        s.rect(ix0, iy0, ix0 + 1, iy1, C(pick(rng, ["red", "gold", "blue"])).m)
        s.rect(ix0, iy0 + 3, ix0 + 1, iy0 + 8, C("black").m)


def sh_lp(s, rng, name, style=None):
    lab = C(pick(rng, BRIGHTS))
    vinyl_disc(s, 21.5, 15.5, 9, lab)
    if style in ("kraft", "whitelabel"):
        paper = C("kraft" if style == "kraft" else "white")
        s.draw(R(1, 6, 20, 25), bev(paper))
        s.fill(E(10.5, 15.5, 4.6) , OUT)
        s.fill(E(10.5, 15.5, 3.6), C("vinyl").m)
        s.fill(E(10.5, 15.5, 2.2), (C("white") if style == "whitelabel" else lab).m)
        s.put(10, 15, OUT)
        if style == "kraft":
            s.rect(3, 8, 7, 8, paper.d)
            s.rect(14, 23, 18, 23, paper.d)
        else:
            s.rect(3, 8, 8, 8, C("black").m)
            s.rect(3, 10, 6, 10, C("black").l)
    else:
        sleeve_art(s, rng, name, 1, 6, 20, 25)


def sh_single7(s, rng, name, lot=False):
    sl = C(pick(rng, ["white", "paper", "kraft", "red", "blue", "green", "orange", "black"]))
    # paper company sleeve behind
    s.draw(R(2, 2, 21, 21), bev(sl))
    s.fill(E(11.5, 11.5, 3.5), sl.d)
    if lot:
        s.rect(4, 4, 9, 4, sl.e)
    lab = C(pick(rng, BRIGHTS + ["cream", "white"]))
    cx, cy, rad = 18.5, 18.5, 11
    vinyl_disc(s, cx, cy, rad, lab, hole=0, grooves=True)
    # 7" singles: big label with a large centre hole
    s.fill(E(cx, cy, 4.8), lab.m)
    s.fill({(x, y) for (x, y) in E(cx, cy, 4.8) if (x - cx) + (y - cy) < -2.5}, lab.l)
    s.fill(E(cx, cy, 1.9), OUT)
    s.rect(15, 16, 16, 16, lab.d)
    s.rect(21, 21, 22, 21, lab.d)


def sh_picdisc(s, rng, name):
    a, b, c = [C(n) for n in picks(rng, BRIGHTS, 3)]
    cx = cy = 15.5
    kind = rng.randrange(3)

    def pic(x, y, d, ang):
        if d > 12.2:
            return C("glass").l
        if kind == 0:  # sunburst
            return a.m if int((ang + 180) / 22.5) % 2 else b.m
        if kind == 1:  # target
            return [a.m, b.m, c.m][int(d / 3) % 3]
        # sunset
        if y < cy + 1:
            return a.l if y < cy - 5 else a.m
        return b.d if (y - cy) % 3 else b.m
    vinyl_disc(s, cx, cy, 13.4, a, hole=1.0, pic=pic)
    if kind == 2:
        s.fill(E(cx, cy - 1, 4, 4) - R(0, int(cy) + 1, 31, 31), C("yellow").l)
    s.fill(E(cx, cy, 1.5), OUT)
    s.pts([(8, 7), (7, 8), (9, 6)], C("white").e)


def sh_crate(s, rng, name, kind="records"):
    """Box/crate/lot: contents sticking out of the top of a crate or carton."""
    if kind in ("records", "books"):
        box = C(pick(rng, ["pine", "oak", "teak"]))
    elif kind == "packs":
        box = C(pick(rng, ["navy", "crimson", "purple", "black", "blue"]))
    elif kind == "cards":
        box = C("white")
    elif kind == "binbag":
        box = C("black")
    else:
        box = C("kraft")
    rng2 = random.Random(rng.random())
    # contents
    x = 4
    while x < 27:
        w = {"records": rng2.choice([3, 3, 4]), "books": rng2.choice([3, 4, 4, 5]), "packs": 5,
             "cards": 2, "rockets": 4, "gadgets": 6, "darkroom": 5}.get(kind, 4)
        w = min(w, 28 - x)
        if w < 2:
            break
        top = rng2.randrange(4, 10)
        if kind == "records":
            top = rng2.randrange(4, 8)
            c = C(rng2.choice(COVERS + ["cream", "white", "yellow", "pink"]))
            s.draw(R(x, top, x + w - 1, 17), bev(c))
            if w >= 3 and rng2.random() < 0.6:
                s.rect(x + 1, top + 2, x + w - 2, top + 2, c.e)
        elif kind == "books":
            c = C(rng2.choice(COVERS))
            s.draw(R(x, top, x + w - 1, 17), bev(c))
            s.rect(x, top + 2, x + w - 1, top + 2, C("gold").m)
        elif kind == "cards":
            top = 8 + (x % 3)
            c = C(rng2.choice(["white", "cream", "yellow", "sky", "pink"]))
            s.draw(R(x, top, x + 1, 17), flat(c.m if x % 4 else c.l))
        elif kind == "packs":
            c = C(rng2.choice(BRIGHTS))
            top = rng2.randrange(3, 7)
            s.draw(R(x, top, x + w - 1, 17), cylx(c, x, x + w - 1, spec=True))
            for xx in range(x, x + w, 2):
                s.put(xx, top, c.x)
            s.fill(E(x + w / 2.0 - 0.5, top + 5, 1.5), C("yellow").l)
        elif kind == "rockets":
            c = C(rng2.choice(["red", "blue", "green", "purple", "yellow", "orange"]))
            top = rng2.randrange(3, 9)
            s.draw(R(x + 1, top + 3, x + 2, 17), cylx(c, x + 1, x + 2))
            s.draw(P((x + 1.5, top), (x + 3, top + 3), (x, top + 3)), flat(C("gold").l if x % 2 else C("silver").l))
            s.put(x + 1, top + 5, c.e)
            w = 5
        elif kind in ("gadgets", "darkroom", "cables"):
            c = C(rng2.choice(["black", "grey", "silver", "cream", "blue", "red", "charcoal"]))
            if kind == "darkroom":
                c = C(rng2.choice(["amber", "brown", "black", "white"]))
                s.draw(RR(x, top + 2, x + 3, 17, 1), cylx(c, x, x + 3))
                s.draw(R(x + 1, top, x + 2, top + 1), flat(C("black").m))
                w = 5
            else:
                shape = rng2.randrange(3)
                if shape == 0:
                    s.draw(RR(x, top, x + 4, 17, 1), bev(c))
                    s.put(x + 2, top + 2, C(rng2.choice(["red", "lime"])).l)
                elif shape == 1:
                    s.draw(E(x + 2, top + 4, 2.5), sph(c, x + 2, top + 4, 2.5))
                    s.draw(L(x + 2, top + 7, x + 2, 17), flat(C("black").m))
                else:
                    s.draw(R(x, top + 2, x + 5, 17), bev(c))
                    s.rect(x + 1, top + 3, x + 4, top + 5, C("screen").m)
                    s.put(x + 1, top + 3, C("glass").l)
        x += w
    # box front
    if kind in ("records", "books"):
        s.draw(R(2, 15, 29, 29), bev(box))
        for y in (19, 24):
            s.rect(3, y, 28, y, box.d)
        s.rect(3, 15 + 1, 28, 15 + 1, box.l)
        s.draw(RR(12, 17, 19, 19, 1), flat(box.x))  # hand hole
    elif kind == "packs":
        s.draw(R(2, 15, 29, 29), bev(box))
        s.draw(R(4, 18, 27, 23), flat(C("gold").m), ol=False)
        s.rect(5, 19, 26, 22, C(contrast(rng, box.base)).m)
        s.fill(star5(15.5, 20.5, 3), C("yellow").l)
        s.rect(4, 25, 12, 26, box.l)
    elif kind == "cards":
        s.draw(R(2, 15, 29, 28), bev(box))
        s.rect(3, 18, 28, 18, box.d)
        s.rect(5, 21, 12, 21, C("black").m)
        s.rect(5, 23, 10, 23, C("grey").m)
    else:
        s.draw(R(2, 15, 29, 29), bev(box))
        s.draw(P((2, 15), (-1, 11), (6, 11), (8, 15)), flat(box.d), ol=True)
        s.draw(P((29, 15), (31, 11), (25, 11), (23, 15)), flat(box.d), ol=True)
        s.rect(14, 16, 17, 29, C("tan").l if kind != "rockets" else C("red").m)
        if kind == "rockets":
            s.rect(3, 21, 28, 23, C("yellow").m)
            s.fill(star5(8, 22, 2.2), C("red").l)
            s.fill(star5(24, 22, 2.2), C("blue").l)
            s.rect(14, 16, 17, 29, box.m)
            s.rect(14, 16, 17, 16, box.l)
        else:
            s.pts([(4, 26), (5, 26), (6, 26)], box.d)


def sh_cassette(s, rng, name, kind="audio"):
    body = C(pick(rng, ["black", "charcoal", "grey", "cream", "white", "red", "blue", "smoke"] if kind == "audio" else ["black", "grey", "charcoal"])) if True else None
    if body.base == PAL.get("smoke", "smoke"):
        body = C("slate")
    s.draw(RR(2, 7, 29, 25, 1), bev(body))
    lab = C(pick(rng, ["white", "cream", "paper", "yellow"]))
    stripe = C(pick(rng, BRIGHTS))
    s.draw(R(4, 9, 27, 18), flat(lab.m), ol=False)
    s.rect(4, 9, 27, 10, stripe.m)
    if kind == "game":
        s.rect(4, 9, 27, 11, stripe.m)
        s.rect(5, 10, 12, 10, stripe.e)
    s.rect(4, 17, 27, 18, lab.d)
    # window with reels
    s.draw(RR(9, 12, 22, 16, 1), flat(C("screen").d))
    for cx in (12, 19):
        s.fill(E(cx, 14, 1.6), C("white").l)
        s.put(cx, 14, OUT)
    s.rect(14, 13, 17, 15, C("brown").d)
    # tape head area
    s.draw(P((8, 25), (10, 21), (21, 21), (23, 25)), flat(body.d), ol=False)
    s.rect(9, 22, 22, 22, OUT) if False else None
    for x in (11, 15, 16, 20):
        s.put(x, 23, OUT)
    s.put(3, 8, body.e)


def sh_reel(s, rng, name):
    fl = C(pick(rng, ["silver", "chrome", "grey", "red", "blue"]))
    tape = C(pick(rng, ["brown", "rust", "walnut"]))
    cx = cy = 15.5
    s.draw(E(cx, cy, 13.4), sph(fl, cx, cy, 13.4))
    for k in range(3):
        a0 = math.radians(-90 + k * 120)
        win = {(x, y) for (x, y) in ring(cx, cy, 11.2, 5.2)
               if abs(((math.atan2(y - cy, x - cx) - a0 + math.pi) % (2 * math.pi)) - math.pi) < 0.62}

        def tf(x, y, m):
            d = math.hypot(x - cx, y - cy)
            if d > 10.3:
                return OUT
            return tape.l if int(d) % 2 else tape.m
        s.draw(win, tf)
    s.draw(E(cx, cy, 3.6), sph(fl, cx, cy, 3.6))
    s.fill(E(cx, cy, 1.4), OUT)


def sh_cd(s, rng, name):
    cx = cy = 15.5
    hues = [C(n).l for n in ["sky", "violet", "pink", "yellow", "mint", "sky"]]
    sil = C("chrome")

    def f(x, y, m):
        d = math.hypot(x - cx, y - cy)
        if d < 1.6:
            return OUT
        if d < 4.2:
            return C("glass").l if d < 3.4 else sil.d
        a = (math.degrees(math.atan2(y - cy, x - cx)) + 360) % 360
        if 200 < a < 250 or 20 < a < 70:
            return hues[int(d) % len(hues)]
        if d > 12.5:
            return sil.d
        return sil.l if (a < 200) else sil.m
    s.draw(E(cx, cy, 13.4), f)


def sh_case(s, rng, name, lot=False, kind="dvd"):
    """DVD / game disc case with cover art."""
    shell = C("black" if kind == "dvd" else pick(rng, ["black", "blue", "charcoal"]))
    if lot:
        s.draw(R(10, 1, 28, 27), bev(C("blue" if kind == "dvd" else "charcoal")))
    x0 = 4 if lot else 7
    s.draw(R(x0, 3, x0 + 18, 30), bev(shell))
    art = C(pick(rng, COVERS + ["orange", "sky", "yellow"]))
    s.rect(x0 + 2, 5, x0 + 17, 28, art.m)
    s.rect(x0 + 2, 5, x0 + 17, 8, art.d)
    s.rect(x0 + 3, 6, x0 + 11, 6, C("white").l)
    fg = C(contrast(rng, art.base))
    kind2 = rng.randrange(3)
    if kind2 == 0:
        s.fill(E(x0 + 10, 18, 5), fg.m)
        s.fill(E(x0 + 9, 17, 2.5), fg.l)
    elif kind2 == 1:
        s.fill(P((x0 + 4, 27), (x0 + 10, 12), (x0 + 16, 27)), fg.m)
        s.fill(P((x0 + 10, 12), (x0 + 16, 27), (x0 + 10, 27)), fg.d)
    else:
        s.fill(E(x0 + 10, 16, 2.5, 3), C("skin").m)
        s.fill(P((x0 + 4, 27), (x0 + 7, 20), (x0 + 13, 20), (x0 + 16, 27)), fg.m)
    s.rect(x0 + 2, 25, x0 + 17, 26, OUT)
    s.rect(x0 + 3, 25, x0 + 8, 25, C("white").m)
    s.rect(x0 + 1, 4, x0 + 1, 29, shell.l)  # spine gloss


def sh_vhs(s, rng, name):
    body = C("black")
    s.draw(R(2, 8, 29, 25), bev(body))
    lab = C(pick(rng, ["white", "cream", "yellow"]))
    s.draw(R(4, 10, 27, 15), flat(lab.m), ol=False)
    s.rect(4, 10, 27, 10, C(pick(rng, BRIGHTS)).m)
    text_lines(s, 6, 22, 12, 14, C("black").l, 2, rng)
    s.draw(R(7, 18, 24, 22), flat(C("screen").d))
    for cx in (10, 21):
        s.fill(E(cx, 20, 1.8), C("brown").m)
        s.put(cx, 20, C("white").l)
    s.rect(13, 18, 18, 22, C("screen").m)
    s.put(3, 9, body.e)
    s.rect(4, 17, 27, 17, body.d)


# ---------------------------------------------------------------- books & paper
def book_front(s, rng, x0, y0, x1, y1, cov, emblem, detail=None):
    # page block + back cover then front cover
    s.draw(R(x0 + 3, y0 + 3, x1 + 3, y1 + 3), flat(cov.d))
    pages = C("paper")

    def pg(x, y, m):
        return pages.d if (x + y) % 2 == 0 and (x > x1 + 1 or y > y1 + 1) else pages.m
    s.draw(R(x0 + 2, y0 + 1, x1 + 2, y1 + 2), pg)
    s.draw(R(x0, y0, x1, y1), bev(cov))
    s.rect(x0 + 1, y0 + 1, x0 + 2, y1 - 1, cov.d)
    s.rect(x0 + 3, y0 + 1, x0 + 3, y1 - 1, cov.l)
    cx = (x0 + 4 + x1) / 2.0
    gold = C("gold")
    if emblem == "plate":
        s.draw(R(int(cx) - 5, y0 + 4, int(cx) + 5, y0 + 8), flat(C("paper").l))
        s.rect(int(cx) - 3, y0 + 6, int(cx) + 3, y0 + 6, cov.d)
    elif emblem == "gilt":
        for (x, y) in R(x0 + 5, y0 + 2, x1 - 2, y1 - 2) - R(x0 + 6, y0 + 3, x1 - 3, y1 - 3):
            s.put(x, y, gold.m)
        s.fill(P((cx, y0 + 8), (cx + 3, (y0 + y1) / 2), (cx, y1 - 8), (cx - 3, (y0 + y1) / 2)), gold.l)
    elif emblem == "cross":
        s.rect(int(cx) - 1, y0 + 5, int(cx), y1 - 6, gold.m)
        s.rect(int(cx) - 4, y0 + 9, int(cx) + 3, y0 + 10, gold.m)
        s.rect(int(cx) - 1, y0 + 5, int(cx) - 1, y1 - 6, gold.l)
        for (x, y) in R(x0 + 5, y0 + 2, x1 - 2, y1 - 2) - R(x0 + 6, y0 + 3, x1 - 3, y1 - 3):
            s.put(x, y, gold.d)
    elif emblem == "album":
        s.draw(R(int(cx) - 5, y0 + 6, int(cx) + 5, y0 + 14), flat(C("paper").m))
        s.rect(int(cx) - 4, y0 + 7, int(cx) + 4, y0 + 13, C("sky").m)
        s.rect(int(cx) - 4, y0 + 11, int(cx) + 4, y0 + 13, C("green").d)
        s.fill(E(int(cx) + 2, y0 + 9, 1.3), C("yellow").l)
        s.rect(int(cx) - 5, y1 - 5, int(cx) + 5, y1 - 5, gold.m)
    elif emblem == "annual":
        fg = C(detail or "yellow")
        s.rect(x0 + 4, y0 + 2, x1 - 1, y0 + 6, fg.m)
        s.rect(x0 + 5, y0 + 3, x1 - 3, y0 + 3, fg.e)
        s.rect(x0 + 5, y0 + 5, x1 - 5, y0 + 5, cov.d)
        s.fill(E(cx, y0 + 13, 3, 3.2), C("skin").m)
        s.fill(E(cx - 1, y0 + 12, 1.2), C("skin").l)
        s.fill(P((cx - 5, y1 - 2), (cx - 3, y0 + 17), (cx + 3, y0 + 17), (cx + 5, y1 - 2)), C(detail or "red").m)
        s.put(int(cx) - 1, y0 + 13, OUT)
        s.put(int(cx) + 1, y0 + 13, OUT)
    elif emblem == "dragon":
        s.fill(P((cx - 6, y1 - 4), (cx, y0 + 5), (cx + 6, y1 - 4)), C("red").m)
        s.fill(P((cx, y0 + 5), (cx + 6, y1 - 4), (cx, y1 - 4)), C("red").d)
        s.rect(x0 + 5, y0 + 2, x1 - 2, y0 + 3, gold.l)
        s.put(int(cx), y0 + 11, C("yellow").e)
    elif emblem == "title":
        s.rect(x0 + 6, y0 + 4, x1 - 3, y0 + 4, gold.l)
        s.rect(x0 + 7, y0 + 6, x1 - 5, y0 + 6, gold.m)
        fg = C(detail or contrast(rng, cov.base))
        s.fill(E(cx, (y0 + y1) / 2.0 + 3, 3.5), fg.m)
        s.fill(E(cx - 1, (y0 + y1) / 2.0 + 2, 1.5), fg.l)


def sh_book(s, rng, name, emblem=None, cover=None):
    cov = C(cover or pick(rng, COVERS))
    book_front(s, rng, 4, 2, 23, 27, cov, emblem or pick(rng, ["plate", "gilt", "title"]))


def sh_book_stack(s, rng, name, pal=None):
    pal = pal or COVERS
    y = 28
    cols = picks(rng, pal, 4)
    specs = []
    for i, cn in enumerate(cols):
        h = rng.choice([5, 5, 6])
        w = rng.randrange(20, 27)
        x0 = rng.randrange(2, 31 - w - 1)
        specs.append((x0, y - h + 1, x0 + w, y, C(cn)))
        y -= h + 1
        if y < 8:
            break
    for (x0, y0, x1, y1, c) in specs:
        # spine faces viewer on the left, page ends on the right
        pages = C("paper")
        s.draw(R(x0, y0, x1, y1), bev(c))
        s.rect(x1 - 3, y0 + 1, x1 - 1, y1 - 1, pages.m)
        for yy in range(y0 + 2, y1, 2):
            s.rect(x1 - 3, yy, x1 - 1, yy, pages.d)
        s.rect(x0 + 2, y0 + 2, x0 + 2, y1 - 2, C("gold").m)
        s.rect(x0 + 5, (y0 + y1) // 2, x1 - 7, (y0 + y1) // 2, c.l)


def sh_books_row(s, rng, name, uniform=None):
    x = 2
    base_c = C(uniform) if uniform else None
    i = 0
    gold = C("gold")
    while x < 28:
        w = rng.choice([4, 4, 5]) if not uniform else 4
        w = min(w, 30 - x)
        if w < 3:
            break
        h = rng.randrange(18, 25) if not uniform else 22 - (i % 2)
        c = base_c or C(pick(rng, COVERS))
        top = 29 - h
        s.draw(R(x, top, x + w - 1, 29), cylx(c, x, x + w - 1))
        s.rect(x, top + 2, x + w - 1, top + 2, gold.m)
        s.rect(x, 26, x + w - 1, 26, gold.m)
        if uniform:
            s.rect(x, top + 4, x + w - 1, top + 4, gold.d)
            s.rect(x, top + 8, x + w - 1, top + 8, gold.d)
            s.rect(x + 1, top + 6, x + w - 2, top + 6, gold.l)
        else:
            s.rect(x + 1, top + 5, x + w - 2, top + 5, c.e)
        x += w + 1
        i += 1


def sh_open_book(s, rng, name, content="text"):
    cov = C(pick(rng, COVERS))
    s.draw(P((1, 10), (15, 12), (16, 12), (30, 10), (30, 27), (16, 29), (15, 29), (1, 27)), flat(cov.m))
    pg = C("paper")
    left = P((2, 8), (8, 7), (15, 10), (15, 26), (8, 23), (2, 24))
    right = P((16, 10), (23, 7), (29, 8), (29, 24), (23, 23), (16, 26))
    s.draw(left, lambda x, y, m: pg.l if x < 12 else pg.m)
    s.draw(right, lambda x, y, m: pg.m if x > 19 else pg.d)
    ink = C("slate").m
    if content in ("text", "poetry"):
        for y in range(11, 22, 2):
            s.rect(4, y, 13 - (y % 4), y, ink)
            s.rect(18, y + 1, 27 - (y % 3), y + 1, ink)
    elif content == "picture":
        s.rect(4, 11, 13, 19, C("sky").l)
        s.rect(4, 17, 13, 19, C("green").m)
        s.fill(E(10, 13, 1.5), C("yellow").l)
        s.rect(18, 11, 27, 19, C(pick(rng, BRIGHTS)).l)
        s.fill(E(22.5, 15, 3), C(pick(rng, BRIGHTS)).m)
        for y in (21,):
            s.rect(5, y, 12, y, ink)
            s.rect(19, y, 26, y, ink)
    elif content == "nature":
        # butterfly plate + text
        bc = C(pick(rng, ["orange", "sky", "yellow", "pink"]))
        s.fill(E(7, 14, 2.5, 3), bc.m)
        s.fill(E(11, 14, 2.5, 3), bc.m)
        s.fill(E(7, 18, 2, 2), bc.d)
        s.fill(E(11, 18, 2, 2), bc.d)
        s.rect(9, 12, 9, 20, C("black").m)
        for y in range(11, 22, 2):
            s.rect(18, y + 1, 27 - (y % 3), y + 1, ink)
    elif content == "popup":
        # castle popping up from the gutter
        st = C(pick(rng, ["pink", "stone", "cream", "sky"]))
        roof = C(pick(rng, ["red", "blue", "purple", "teal"]))
        s.draw(R(10, 11, 21, 21), bev(st))
        for x in range(10, 22, 2):
            s.put(x, 10, st.m)
        for x0 in (7, 20):
            s.draw(R(x0, 8, x0 + 4, 21), cylx(st, x0, x0 + 4))
            s.draw(P((x0 - 1, 8), (x0 + 2, 2), (x0 + 5, 8)), lambda x, y, m: roof.l if x < x0 + 2 else roof.d)
        s.draw(P((13, 21), (13, 16), (15.5, 14), (18, 16), (18, 21)), flat(C("walnut").d))
        s.pts([(9, 12), (22, 12)], C("black").m)
        s.draw(E(3.5, 22, 2), sph(C("green"), 3.5, 22, 2))
        s.draw(E(27.5, 22, 2), sph(C("green"), 27.5, 22, 2))
    s.rect(15, 11, 15, 27, pg.x)


def sh_comic(s, rng, name, lot=False, style="comic"):
    if lot:
        back = C(pick(rng, BRIGHTS))
        s.draw(R(10, 1, 28, 25), bev(back))
        s.rect(11, 2, 27, 5, C("white").m)
        s.draw(R(7, 3, 25, 27), bev(C(pick(rng, BRIGHTS))))
    x0, y0, x1, y1 = (4, 6, 22, 30) if lot else (6, 2, 25, 29)
    bg = C(pick(rng, ["sky", "yellow", "orange", "lime", "pink", "red", "teal", "white"]))
    s.draw(R(x0, y0, x1, y1), bev(bg))
    tb = C(pick(rng, ["red", "blue", "black", "yellow"]))
    if tb.base == bg.base:
        tb = C("navy")
    cx = (x0 + x1) / 2.0
    if style == "comic":
        s.rect(x0 + 1, y0 + 1, x1 - 1, y0 + 5, tb.m)
        for xx in range(x0 + 2, x1 - 3, 3):
            s.rect(xx, y0 + 2, xx + 1, y0 + 4, C("white").e)
        # burst
        pts = []
        for i in range(16):
            a = i * math.pi / 8
            r = 7 if i % 2 == 0 else 4
            pts.append((cx + r * math.cos(a), y0 + 15 + r * math.sin(a)))
        s.fill(P(*pts), C("yellow").l if bg.base != PAL["yellow"] else C("red").m)
        s.fill(E(cx, y0 + 15, 2.6), C("red").m if bg.base != PAL["red"] else C("blue").m)
        s.rect(x0 + 2, y1 - 3, x0 + 6, y1 - 2, C("white").l)
    else:  # magazine
        s.rect(x0 + 1, y0 + 1, x1 - 1, y0 + 5, tb.m)
        s.rect(x0 + 2, y0 + 2, x1 - 5, y0 + 4, C("white").e)
        s.rect(x0 + 2, y0 + 3, x1 - 5, y0 + 3, tb.m)
        photo = C(pick(rng, ["sky", "teal", "orange", "pink", "green"]))
        s.rect(x0 + 2, y0 + 7, x1 - 2, y1 - 2, photo.m)
        if style == "football":
            s.rect(x0 + 2, y0 + 14, x1 - 2, y1 - 2, C("green").m)
            s.rect(x0 + 2, y0 + 14, x1 - 2, y0 + 14, C("green").l)
            s.fill(E(cx + 3, y0 + 18, 2.4), C("white").m)
            s.put(int(cx) + 3, y0 + 18, OUT)
        s.fill(E(cx - 2, y0 + 12, 2.5, 3), C("skin").m)
        s.fill(P((cx - 8, y1 - 2), (cx - 5, y0 + 16), (cx + 1, y0 + 16), (cx + 3, y1 - 2)), C(pick(rng, BRIGHTS)).d)
        s.rect(x1 - 6, y0 + 8, x1 - 3, y0 + 8, C("white").e)
        s.rect(x1 - 6, y0 + 10, x1 - 3, y0 + 10, C("yellow").l)


def sh_scroll(s, rng, name, content="map"):
    paper = C("paper" if content == "map" else "white")
    if content == "map":
        paper = C(pick(rng, ["paper", "cream", "pine"]))
    s.draw(R(5, 6, 26, 25), lambda x, y, m: paper.l if y < 9 else (paper.d if y > 22 else paper.m))
    if content == "map":
        sea = C("sky")
        s.rect(6, 7, 25, 24, sea.l)
        land = C("green")
        s.fill(P((8, 9), (15, 8), (17, 13), (14, 17), (18, 22), (10, 23), (7, 16)), paper.m)
        s.fill(P((19, 10), (24, 9), (24, 15), (21, 16)), paper.m)
        s.pts([(9, 10), (12, 12), (10, 18), (13, 20), (20, 11)], paper.d)
        s.pts([(11, 15), (12, 16), (13, 17), (14, 18), (16, 20)], C("red").m)
        s.pts([(15, 19), (17, 19), (16, 18), (16, 20)], C("red").l)
        s.fill(star5(22, 21, 2), C("gold").m)
    elif content == "poster":
        bg = C(pick(rng, ["pink", "sky", "yellow", "mint", "orange"]))
        s.rect(6, 7, 25, 24, bg.m)
        fg = C(contrast(rng, bg.base))
        s.fill(E(15.5, 16, 6), fg.m)
        s.fill(E(13.5, 14.5, 2), C("white").e)
        s.fill(E(17.5, 14.5, 2), C("white").e)
        s.put(14, 15, OUT)
        s.put(18, 15, OUT)
        s.fill(P((11, 10), (12, 5), (14, 10)), fg.m)
        s.fill(P((17, 10), (19, 5), (20, 10)), fg.m)
        s.rect(7, 22, 16, 23, C("white").l)
    else:  # playmat
        bg = C(pick(rng, ["navy", "purple", "black", "teal", "forest"]))
        s.rect(6, 7, 25, 24, bg.m)
        for x0 in (8, 13, 18):
            s.draw(R(x0, 17, x0 + 3, 22), flat(bg.l), ol=False)
        s.fill(E(15.5, 12, 3.5), C(pick(rng, ["gold", "sky", "red"])).l)
    for x in (2, 26):
        s.draw(R(x, 4, x + 3, 27), cylx(paper, x, x + 3))
        s.fill(R(x + 1, 3, x + 2, 3), paper.d)
        s.put(x + 1, 3, OUT)
        s.put(x + 2, 3, OUT)
        s.put(x + 1, 28, OUT)
        s.put(x + 2, 28, OUT)


def sh_sheet(s, rng, name):
    paper = C(pick(rng, ["white", "paper", "cream"]))
    s.draw(R(9, 1, 28, 26), bev(paper))
    s.draw(R(3, 5, 22, 30), bev(paper))
    ink = C("black").m
    for sy in (8, 17):
        for k in range(5):
            s.rect(5, sy + k * 1 + (k * 1), 20, sy + k * 2, C("slate").l)
    for (x, y) in [(7, 11), (10, 9), (13, 13), (16, 10), (8, 20), (12, 22), (15, 19), (18, 23)]:
        s.rect(x, y, x + 1, y + 1, ink)
        s.rect(x + 1, y - 4, x + 1, y, ink)
    s.rect(4, 5, 4, 29, paper.e)


def sh_binder(s, rng, name, kind="cards"):
    cov = C(pick(rng, ["red", "blue", "black", "navy", "green", "purple", "crimson"]))
    if kind in ("stamps", "vintage"):
        cov = C(pick(rng, ["wine", "forest", "navy", "brown", "leather"]))
    s.draw(R(1, 1, 30, 30), bev(cov))
    page = C("white" if kind != "vintage" else "paper")
    s.draw(R(5, 3, 28, 28), flat(page.d))
    # rings
    for y in (6, 15, 24):
        s.rect(2, y, 6, y + 1, C("chrome").l)
        s.put(2, y + 1, C("chrome").d)
    if kind == "stamps":
        for j in range(4):
            for i in range(4):
                x0, y0 = 7 + i * 5, 5 + j * 6
                sc = C(pick(rng, ["red", "blue", "green", "purple", "orange", "wine", "teal"]))
                s.rect(x0, y0, x0 + 3, y0 + 4, C("white").e)
                s.rect(x0 + 1, y0 + 1, x0 + 2, y0 + 3, sc.m)
        return
    rows, cols, cw, ch = 3, 3, 6, 7
    for j in range(rows):
        for i in range(cols):
            x0, y0 = 7 + i * 7, 4 + j * 8
            if kind == "stickers" and rng.random() < 0.3:
                s.rect(x0, y0, x0 + cw - 1, y0 + ch - 1, page.m)
                continue
            border = C(pick(rng, ["yellow", "silver", "yellow", "sky", "red", "white"] if kind != "vintage" else ["cream", "paper", "white"]))
            art = C(pick(rng, BRIGHTS))
            s.rect(x0, y0, x0 + cw - 1, y0 + ch - 1, border.m)
            s.rect(x0 + 1, y0 + 1, x0 + cw - 2, y0 + 3, art.m)
            s.put(x0 + 2, y0 + 2, art.e)
            s.rect(x0 + 1, y0 + 5, x0 + cw - 2, y0 + 5, border.d)
            s.rect(x0, y0, x0, y0 + ch - 1, border.l)


def card_face(s, rng, x0, y0, x1, y1, border, art, motif, holo=False):
    s.draw(RR(x0, y0, x1, y1, 1), bev(border))
    ax0, ay0, ax1, ay1 = x0 + 2, y0 + 3, x1 - 2, y0 + (y1 - y0) // 2 + 1
    s.rect(x0 + 2, y0 + 1, x1 - 4, y0 + 1, border.d)
    s.put(x1 - 2, y0 + 1, C("red").m)
    s.draw(R(ax0, ay0, ax1, ay1), flat(art.l), ol=False)
    s.fill({(x, y) for x in (ax0 - 1, ax1 + 1) for y in range(ay0, ay1 + 1)} | {(x, y) for y in (ay0 - 1, ay1 + 1) for x in range(ax0 - 1, ax1 + 2)}, border.x)
    if holo:
        hol = [C(n).l for n in ("pink", "yellow", "mint", "sky", "violet")]
        for (x, y) in R(ax0, ay0, ax1, ay1):
            if (x + y) % 3 == 0:
                s.put(x, y, hol[((x + y) // 3) % len(hol)])
    cx, cy = (ax0 + ax1) / 2.0, (ay0 + ay1) / 2.0 + 0.5
    if motif == "star":
        s.fill(star5(cx, cy, 4.5), C("yellow").l)
        s.fill(star5(cx, cy, 2.2), C("yellow").e)
    elif motif == "flame":
        s.fill(P((cx, cy - 5), (cx + 4, cy + 1), (cx + 2, cy + 4), (cx - 2, cy + 4), (cx - 4, cy + 1)), C("orange").m)
        s.fill(P((cx, cy - 2), (cx + 2, cy + 2), (cx - 2, cy + 2)), C("yellow").l)
    elif motif == "leaf":
        s.fill(E(cx, cy, 2.8, 4.5), C("green").m)
        s.fill(E(cx - 1, cy - 1, 1.2, 2.5), C("green").l)
        s.rect(int(cx), int(cy) - 3, int(cx), int(cy) + 4, C("green").d)
    elif motif == "drop":
        s.fill(E(cx, cy + 1, 3.3), C("blue").m)
        s.fill(P((cx, cy - 5), (cx + 2.5, cy), (cx - 2.5, cy)), C("blue").m)
        s.put(int(cx) - 1, int(cy), C("sky").e)
    elif motif == "bolt":
        s.fill(P((cx + 1, cy - 5), (cx - 3, cy + 1), (cx, cy + 1), (cx - 1, cy + 5), (cx + 3, cy - 1), (cx, cy - 1)), C("yellow").m)
    elif motif == "player":
        kit = C(pick(rng, ["red", "blue", "white", "green", "navy"]))
        s.fill(E(cx, cy - 2, 2, 2.2), C(pick(rng, ["skin", "tan", "brown"])).m)
        s.fill(P((cx - 4, ay1), (cx - 3, cy + 1), (cx + 3, cy + 1), (cx + 4, ay1)), kit.m)
        s.rect(int(cx) - 1, int(cy) - 5, int(cx) + 1, int(cy) - 4, C("brown").d)
    elif motif == "portrait":
        s.fill(E(cx, cy - 1, 2.2, 2.6), C("skin").m)
        s.fill(P((cx - 4, ay1), (cx - 2, cy + 2), (cx + 2, cy + 2), (cx + 4, ay1)), C(pick(rng, ["navy", "wine", "forest", "black"])).m)
    # text box
    for y in range(ay1 + 3, y1 - 1, 2):
        s.rect(x0 + 2, y, x1 - 3 - (y % 3), y, border.d)


def sh_card(s, rng, name, holo=False, sports=False, vintage=False):
    if sports:
        border = C(pick(rng, ["white", "silver", "red", "blue"]))
        motif = "player"
    elif vintage:
        border = C("paper")
        motif = "portrait"
    else:
        border = C(pick(rng, ["yellow", "yellow", "silver", "gold", "black"] if not holo else ["yellow", "silver", "gold"]))
        motif = pick(rng, ["star", "flame", "leaf", "drop", "bolt"])
    art = C(pick(rng, ["sky", "mint", "pink", "cream", "orange", "violet", "teal"]))
    card_face(s, rng, 6, 2, 25, 29, border, art, motif, holo=holo)
    if holo:
        s.pts([(27, 4), (28, 5), (29, 4), (28, 3), (28, 4)], C("white").e)


def sh_cardfan(s, rng, name, vintage=True):
    bor = ["paper", "cream", "white"] if vintage else ["yellow", "silver", "white"]
    motifs = ["portrait", "player", "portrait"] if vintage else ["star", "leaf", "flame"]
    for i, (x0, y0) in enumerate([(2, 5), (12, 2), (7, 8)]):
        card_face(s, rng, x0, y0, x0 + 15, y0 + 21, C(pick(rng, bor)), C(pick(rng, ["sky", "mint", "pink", "cream", "orange"])),
                  motifs[i])


def sh_slab(s, rng, name):
    case = C("glass")
    s.draw(RR(6, 1, 25, 30, 1), lambda x, y, m: case.l if x in (7,) else (case.d if x == 24 or y == 29 else case.m))
    s.draw(R(8, 3, 23, 7), flat(C("white").l))
    s.rect(9, 4, 16, 4, C("red").m)
    s.rect(9, 6, 14, 6, C("slate").m)
    s.draw(R(19, 4, 22, 6), flat(C("red").m), ol=False)
    s.put(20, 5, C("white").e)
    s.put(21, 5, C("white").e)
    border = C(pick(rng, ["yellow", "silver", "gold"]))
    card_face(s, rng, 9, 10, 22, 28, border, C(pick(rng, ["sky", "pink", "mint", "orange"])), pick(rng, ["star", "flame", "bolt"]),
              holo=rng.random() < 0.5)
    s.put(7, 9, C("white").e)
    s.put(7, 10, C("white").e)


def sh_booster(s, rng, name, japanese=False):
    foil = C(pick(rng, BRIGHTS + ["silver", "gold"]))
    x0, x1 = 7, 24

    def f(x, y, m):
        t = (x - x0) / (x1 - x0)
        if y <= 4 or y >= 27:
            return foil.d if (x % 2 == 0) else foil.l
        if 0.18 < t < 0.3:
            return foil.e
        if t < 0.4:
            return foil.l
        if t > 0.82:
            return foil.d
        return foil.m
    s.draw(R(x0, 2, x1, 29), f)
    for x in range(x0, x1 + 1, 2):
        s.put(x, 1, OUT)
        s.put(x + 1, 30, OUT)
    fg = C(contrast(rng, foil.base))
    s.draw(E(15.5, 16, 5.2), sph(fg, 15.5, 16, 5.2))
    s.fill(star5(15.5, 16, 2.5), C("yellow").e)
    s.draw(R(9, 6, 22, 9), flat(C("yellow").l if foil.base != PAL["yellow"] else C("red").m))
    s.rect(10, 7, 20, 7, C("red").m if foil.base != PAL["red"] else C("blue").m)
    if japanese:
        s.rect(18, 23, 22, 25, C("white").e)
        s.rect(19, 24, 21, 24, C("red").m)
    else:
        s.rect(9, 24, 14, 24, C("white").l)


def sh_deckbox(s, rng, name, starter=False):
    c = C(pick(rng, BRIGHTS + ["black", "white"]))
    s.draw(P((8, 8), (22, 8), (26, 5), (12, 5)), flat(c.l))
    s.draw(P((22, 8), (26, 5), (26, 26), (22, 29)), flat(c.d))
    s.draw(R(8, 8, 22, 29), bev(c))
    s.rect(9, 12, 21, 12, c.x)
    s.fill(E(15, 20, 4.3), C(contrast(rng, c.base)).m)
    s.fill(star5(15, 20, 2.6), C("white").e)
    if starter:
        s.draw(R(9, 26, 16, 28), flat(C("yellow").l), ol=False)
    for y in range(9, 28, 5):
        s.put(21, y, c.e)


def sh_tin(s, rng, name, motif=None):
    c = C(pick(rng, ["red", "blue", "green", "navy", "crimson", "teal", "gold", "silver", "purple", "yellow"]))
    if motif in ("bolts", "gears", "slides"):
        c = C(pick(rng, ["galv", "silver", "red", "blue", "green"]))
    # cylinder tin, front 3/4 view
    body = E(15.5, 25, 13, 4) | R(3, 11, 28, 25)
    s.draw(body, cylx(c, 3, 28))
    lid = E(15.5, 11, 13.5, 4.2) | R(2, 8, 29, 11)
    s.draw(R(2, 8, 29, 12) | E(15.5, 12, 13.5, 3), cylx(c, 2, 29, spec=True))
    s.draw(E(15.5, 8, 13.5, 4.2), lambda x, y, m: c.e if (x + y) % 7 == 0 and y < 8 else (c.l if y < 8 else c.m))
    s.fill(E(15.5, 8, 10.5, 2.6) - E(15.5, 8, 9.5, 1.8), c.d)
    fg = C("gold") if c.base not in (PAL["gold"], PAL["yellow"]) else C("red")
    if motif == "badges":
        for (bx, by, cn) in [(9, 7, "red"), (15, 9, "blue"), (21, 7, "yellow"), (12, 5, "green")]:
            s.draw(E(bx, by, 1.8, 1.3), flat(C(cn).l))
    elif motif == "bolts":
        for (bx, by) in [(9, 7), (14, 9), (20, 7), (23, 8), (17, 6)]:
            s.draw(R(bx - 1, by - 1, bx + 1, by), flat(C("steel").l))
    elif motif == "gears":
        for (bx, by) in [(10, 8), (18, 7), (22, 9)]:
            s.draw(E(bx, by, 2, 1.4), flat(C("brass").l))
            s.put(bx, by, OUT)
    elif motif == "brooches":
        for (bx, by, cn) in [(10, 8, "ruby"), (16, 7, "emerald"), (21, 8, "sapphire")]:
            s.draw(E(bx, by, 1.8, 1.3), flat(C("gold").l))
            s.put(bx, by, C(cn).l)
    elif motif == "slides":
        for bx in (8, 13, 18):
            s.draw(R(bx, 4, bx + 4, 8), flat(C("white").l))
            s.rect(bx + 1, 5, bx + 3, 7, C(pick(rng, ["sky", "orange", "green"])).m)
    # front label
    if motif == "cards":
        s.draw(R(9, 15, 22, 24), flat(fg.m))
        s.fill(star5(15.5, 19.5, 3.3), C("white").e)
    else:
        s.fill(E(15.5, 19, 5, 3.6), fg.m)
        s.fill(E(15.5, 19, 4, 2.6), fg.l)
        s.rect(12, 19, 19, 19, c.d)


def sh_advent(s, rng, name):
    c = C(pick(rng, ["red", "green", "navy", "crimson", "forest"]))
    s.draw(R(2, 3, 29, 28), bev(c))
    s.fill(P((15.5, 5), (22, 16), (9, 16)), C("forest").l)
    s.put(15, 4, C("yellow").e)
    s.put(16, 4, C("yellow").e)
    for j, y in enumerate((18, 23)):
        for i in range(5):
            x = 4 + i * 5
            s.draw(R(x, y, x + 3, y + 3), flat(C("paper").l))
            s.put(x + 1, y + 1, C("red").m if (i + j) % 2 else C("green").m)
    for x in (5, 26):
        s.draw(R(x, 7, x + 2, 12), flat(C("paper").l))


# ---------------------------------------------------------------- cameras
def lens_front(s, cx, cy, r, barrel, glass=None):
    glass = glass or C("sapphire")
    s.draw(E(cx, cy, r), sph(barrel, cx, cy, r, spec=False))
    s.fill(E(cx, cy, r - 1.3) - E(cx, cy, r - 2.1), barrel.x)
    s.fill(E(cx, cy, r - 2.1), glass.d)
    s.fill(E(cx, cy, r - 3.1), glass.m)
    s.fill(E(cx - r * 0.25, cy - r * 0.25, max(1.0, r * 0.25)), glass.l)
    s.put(int(cx - r * 0.35), int(cy - r * 0.35), C("white").e)


def sh_slr(s, rng, name, dslr=False):
    chrome = C("chrome")
    leather = C("black")
    if dslr:
        s.draw(RR(2, 10, 29, 25, 2), bev(C("charcoal")))
        s.draw(RR(2, 12, 8, 26, 2), bev(C("black")))  # grip
        s.draw(P((11, 10), (13, 5), (19, 5), (21, 10)), flat(C("charcoal").m))
        s.rect(13, 6, 19, 6, C("charcoal").l)
        s.draw(R(23, 8, 26, 9), flat(C("black").l))
        s.put(26, 12, C("red").m)
        lens_front(s, 16, 18, 7.5, C("black"))
        s.rect(4, 14, 6, 14, C("black").l)
        return
    s.draw(R(2, 10, 29, 25), lambda x, y, m: chrome.l if y == 10 else (chrome.m if y < 15 else (leather.d if (x + y) % 2 else leather.m) if y < 25 else chrome.d))
    s.rect(3, 15, 28, 15, chrome.d)
    s.rect(3, 24, 28, 24, chrome.m)
    s.draw(P((10, 10), (13, 4), (19, 4), (22, 10)), lambda x, y, m: chrome.l if x < 16 else chrome.m)
    s.rect(14, 6, 18, 7, chrome.d)
    s.draw(R(23, 7, 26, 9), flat(chrome.m))
    s.draw(R(4, 7, 7, 9), flat(chrome.d))
    lens_front(s, 16, 18, 7, C("black"))
    s.put(5, 12, C("red").m)


def sh_compact(s, rng, name, kind="point"):
    if kind == "instant":
        body = C(pick(rng, ["white", "cream", "black"]))
        s.draw(RR(3, 4, 28, 29, 2), bev(body))
        s.rect(4, 24, 27, 25, OUT)
        s.rect(4, 13, 27, 13, C("red").m)
        s.rect(4, 14, 27, 14, C("orange").m)
        s.rect(4, 15, 27, 15, C("yellow").m)
        s.rect(4, 16, 27, 16, C("green").m)
        s.rect(4, 17, 27, 17, C("blue").m)
        lens_front(s, 15.5, 11, 5.5, C("black"))
        s.draw(R(20, 5, 26, 8), flat(C("glass").l))
        s.draw(R(5, 5, 9, 7), flat(C("black").l))
        return
    if kind == "box":
        body = C(pick(rng, ["black", "brown", "leather"]))
        s.draw(RR(5, 5, 26, 28, 1), lambda x, y, m: body.d if (x * 3 + y) % 4 == 0 else body.m)
        s.draw(L(9, 5, 22, 5), flat(C("leather").d))
        s.draw(PL([(12, 5), (12, 2), (19, 2), (19, 5)]), flat(C("leather").m))
        lens_front(s, 15.5, 18, 4.5, C("chrome"))
        s.draw(R(7, 8, 10, 10), flat(C("glass").m))
        s.draw(R(21, 8, 24, 10), flat(C("glass").m))
        s.rect(8, 25, 23, 25, C("chrome").d)
        return
    silver = kind in ("digital",) and rng.random() < 0.6
    body = C("silver" if silver else pick(rng, ["black", "charcoal", "silver", "red", "blue"]))
    if kind == "rangefinder":
        chrome = C("chrome")
        s.draw(RR(2, 9, 29, 24, 2), lambda x, y, m: chrome.l if y < 11 else (chrome.m if y < 15 else (C("black").m if y < 23 else chrome.d)))
        s.rect(3, 15, 28, 15, chrome.d)
        s.draw(R(4, 11, 8, 13), flat(C("glass").l))
        s.draw(R(11, 11, 13, 13), flat(C("glass").d))
        s.draw(R(20, 11, 24, 13), flat(C("glass").m))
        s.draw(R(22, 6, 25, 8), flat(chrome.m))
        s.draw(R(5, 7, 8, 8), flat(chrome.d))
        lens_front(s, 15.5, 18, 5.5, C("chrome"))
        return
    s.draw(RR(2, 9, 29, 24, 3), bev(body))
    s.draw(R(4, 11, 9, 13), flat(C("white").e if kind != "digital" else C("glass").l))
    s.draw(R(21, 11, 25, 13), flat(C("glass").d))
    s.draw(R(23, 6, 26, 8), flat(C("chrome").m))
    lens_front(s, 13, 18, 5.2, C("chrome") if body.base != PAL["silver"] else C("black"))
    s.rect(3, 23, 28, 23, body.d)
    s.rect(24, 17, 27, 17, body.d)
    if kind == "digital":
        s.put(26, 20, C("lime").m)


def sh_lens(s, rng, name, tele=False):
    c = C("white" if tele and rng.random() < 0.5 else "black")
    x0 = 2 if tele else 5
    s.draw(R(x0, 11, 7 if tele else 9, 20), cyly(C("chrome"), 11, 20))   # mount
    s.draw(R(x0 + 3, 9, 24, 22), cyly(c, 9, 22))
    for x in range(x0 + 6, 22, 1 if tele else 1):
        if (tele and 9 <= x <= 15) or (not tele and 12 <= x <= 18):
            s.rect(x, 10, x, 21, C("black").x if x % 2 else C("black").l)
    s.rect(x0 + 4, 16, x0 + 4, 16, C("red").m)
    s.draw(R(24, 6, 27, 25), cyly(c, 6, 25))
    glass = C("violet")
    s.draw(E(28, 15.5, 2, 8.5), lambda x, y, m: glass.l if y < 12 else (glass.m if y < 20 else glass.d))
    s.put(28, 10, C("white").e)
    if tele:
        s.rect(18, 22, 20, 24, C("black").m)
        s.rect(17, 25, 21, 25, C("black").d)
    s.rect(x0 + 4, 9, 23, 9, c.e)


def sh_tlr(s, rng, name):
    body = C("black")
    s.draw(R(8, 5, 23, 30), lambda x, y, m: body.d if (x * 3 + y) % 4 == 0 else body.m)
    s.draw(P((8, 5), (10, 1), (21, 1), (23, 5)), flat(C("chrome").m))
    s.rect(10, 2, 21, 2, C("chrome").l)
    s.draw(R(9, 16, 22, 17), flat(C("chrome").l))
    lens_front(s, 15.5, 11, 4.6, C("chrome"))
    lens_front(s, 15.5, 23.5, 5, C("chrome"))
    s.draw(E(24, 20, 1.5), flat(C("chrome").m))


def sh_bellows(s, rng, name):
    body = C("black")
    chrome = C("chrome")
    s.draw(R(2, 26, 27, 28), flat(chrome.d))
    s.draw(R(2, 5, 8, 27), lambda x, y, m: body.d if (x * 3 + y) % 4 == 0 else body.m)
    s.rect(3, 6, 7, 6, body.l)
    bel = P((9, 8), (21, 12), (21, 22), (9, 25))
    s.draw(bel, lambda x, y, m: body.x if (x % 3 == 0) else (body.m if x % 3 == 1 else body.l))
    s.draw(R(21, 10, 24, 24), cylx(chrome, 21, 24))
    s.draw(R(25, 13, 28, 21), cylx(C("black"), 25, 28))
    s.draw(E(29, 17, 1, 3.5), flat(C("violet").l))
    s.draw(L(22, 25, 22, 27), flat(chrome.m))


def sh_cine(s, rng, name, camcorder=False):
    if camcorder:
        body = C(pick(rng, ["charcoal", "black", "silver"]))
        s.draw(RR(8, 11, 28, 25, 2), bev(body))
        s.draw(R(2, 13, 9, 22), cyly(C("black"), 13, 22))
        s.draw(E(2, 17.5, 1, 4), flat(C("violet").m))
        s.draw(PL([(10, 11), (12, 6), (26, 6), (27, 11)], 2), flat(C("black").m))
        s.draw(R(24, 8, 30, 12), cyly(C("black"), 8, 12))
        s.draw(R(13, 16, 22, 19), flat(body.d), ol=False)
        s.put(25, 14, C("red").m)
        s.rect(12, 22, 26, 22, body.d)
        return
    body = C(pick(rng, ["chrome", "silver", "brown", "black"]))
    s.draw(E(12, 6, 5), sph(C("black"), 12, 6, 5))
    s.draw(E(22, 6, 5), sph(C("black"), 22, 6, 5))
    for cx in (12, 22):
        s.fill(E(cx, 6, 1.2), C("chrome").l)
    s.draw(RR(8, 10, 27, 23, 2), bev(body))
    s.draw(R(2, 13, 8, 20), cyly(C("black"), 13, 20))
    s.draw(E(2, 16.5, 1, 3.2), flat(C("violet").l))
    s.draw(P((17, 23), (22, 23), (20, 30), (16, 30)), flat(C("black").m))
    s.draw(E(24, 17, 2), sph(C("chrome"), 24, 17, 2))
    s.rect(10, 12, 20, 12, body.e)


def sh_tripod(s, rng, name):
    leg = C(pick(rng, ["black", "silver", "chrome"]))
    for (x1, y1) in [(4, 30), (27, 30), (16, 30)]:
        s.draw(L(16, 11, x1, y1, 2.2), flat(leg.m))
    for (x1, y1) in [(4, 30), (27, 30), (16, 30)]:
        mx, my = 16 + (x1 - 16) * 0.55, 11 + (y1 - 11) * 0.55
        s.draw(R(int(mx) - 1, int(my), int(mx) + 1, int(my) + 1), flat(C("black").l))
    s.draw(R(12, 7, 20, 11), bev(C("black")))
    s.draw(R(11, 4, 21, 6), bev(C("charcoal")))
    s.draw(L(21, 7, 29, 12, 2), flat(C("black").l))


def sh_binoculars(s, rng, name):
    c = C(pick(rng, ["black", "forest", "olive", "charcoal"]))
    for x0 in (3, 18):
        s.draw(RR(x0, 4, x0 + 3 + 3, 9, 1), cylx(C("black"), x0, x0 + 6))
        s.draw(RR(x0 - 1, 9, x0 + 11, 28, 2), cylx(c, x0 - 1, x0 + 11))
        s.rect(x0, 13, x0 + 10, 14, c.x)
        s.draw(E(x0 + 5, 27, 5, 1.8), flat(C("violet").m))
        s.put(x0 + 3, 27, C("white").e)
    s.draw(R(14, 10, 17, 16), cylx(C("chrome"), 14, 17))
    s.draw(E(15.5, 8, 2.2), sph(C("chrome"), 15.5, 8, 2.2))


def sh_projector(s, rng, name, cine=False):
    body = C(pick(rng, ["grey", "cream", "slate", "brown", "silver"]))
    if cine:
        s.draw(L(9, 12, 7, 6, 2), flat(C("chrome").d))
        s.draw(L(19, 12, 21, 6, 2), flat(C("chrome").d))
        for (cx, r) in ((7, 5.5), (22, 5.5)):
            s.draw(E(cx, 6, r), sph(C("black"), cx, 6, r))
            s.fill(E(cx, 6, 1.3), C("chrome").l)
            s.fill(E(cx, 6, r - 1.2) - E(cx, 6, r - 2.2), C("brown").m)
    else:
        s.draw(E(14, 12, 10, 3.5), flat(C("black").m))
        for i in range(-8, 9, 2):
            s.put(14 + i, 11 + (1 if abs(i) > 5 else 0), C("black").l)
        s.fill(E(14, 11, 3, 1.2), C("black").x)
    s.draw(RR(2, 13, 25, 26, 1), bev(body))
    for y in range(16, 24, 2):
        s.rect(4, y, 10, y, body.d)
    s.draw(R(24, 16, 29, 23), cyly(C("black"), 16, 23))
    s.draw(E(29.5, 19.5, 0.8, 3), flat(C("glass").e))
    s.draw(R(4, 27, 6, 28), flat(C("black").m))
    s.draw(R(20, 27, 22, 28), flat(C("black").m))
    s.put(14, 20, C("red").m)


def sh_flashgun(s, rng, name):
    body = C(pick(rng, ["black", "charcoal", "silver"]))
    s.draw(RR(5, 2, 26, 12, 1), bev(body))
    s.draw(R(7, 4, 24, 10), lambda x, y, m: C("paper").e if (y % 2 == 0) else C("yellow").l)
    s.draw(R(12, 13, 19, 15), flat(body.d))
    s.draw(RR(9, 15, 22, 27, 1), bev(body))
    s.draw(R(12, 17, 19, 20), flat(C("screen").m))
    s.put(13, 18, C("red").l)
    s.draw(R(8, 27, 23, 29), cyly(C("chrome"), 27, 29))


def sh_meter(s, rng, name):
    body = C(pick(rng, ["black", "charcoal", "grey", "silver"]))
    s.draw(RR(8, 6, 23, 29, 2), bev(body))
    s.draw(E(15.5, 5, 4.5, 3.5), sph(C("white"), 15.5, 5, 4.5))
    s.draw(R(10, 11, 21, 18), flat(C("paper").l))
    s.rect(11, 12, 20, 12, C("red").m)
    s.fill(L(15, 18, 19, 13), OUT)
    s.draw(E(15.5, 24, 3.4), sph(C("chrome"), 15.5, 24, 3.4))
    for a in range(0, 360, 60):
        s.put(int(15.5 + 3 * math.cos(math.radians(a))), int(24 + 3 * math.sin(math.radians(a))), C("chrome").d)


def sh_pillar(s, rng, name, enlarger=False):
    if enlarger:
        base = C("white")
        s.draw(R(2, 26, 29, 29), bev(base))
        s.draw(R(22, 4, 24, 26), cylx(C("chrome"), 22, 24))
        head = C("black")
        s.draw(R(6, 3, 21, 9), bev(C("grey")))
        s.draw(P((8, 10), (19, 10), (17, 17), (10, 17)), lambda x, y, m: head.m if y % 2 else head.l)
        s.draw(R(11, 18, 16, 21), cylx(C("black"), 11, 16))
        s.draw(R(20, 5, 21, 8), flat(C("black").m))
        s.draw(R(5, 23, 17, 25), flat(C("paper").l), ol=False)
        return
    body = C(pick(rng, ["green", "grey", "blue", "slate", "forest"]))
    s.draw(R(3, 26, 28, 29), bev(C("steel")))
    s.draw(R(6, 4, 8, 26), cylx(C("chrome"), 6, 8))
    s.draw(R(10, 19, 27, 21), bev(C("steel")))
    s.draw(RR(4, 3, 25, 12, 2), bev(body))
    s.draw(E(12, 3, 4.5, 2.5), flat(body.l))
    s.draw(R(18, 12, 21, 15), cylx(C("chrome"), 18, 21))
    s.draw(L(19.5, 16, 19.5, 18, 1), flat(C("steel").e))
    for (dx, dy) in [(5, 3), (4, 6)]:
        s.draw(L(25, 9, 25 + dx, 9 + dy), flat(C("black").l))
    s.put(29, 11, C("red").m)
    s.put(29, 16, C("red").m)


# ---------------------------------------------------------------- electronics
def grille(s, x0, y0, x1, y1, dark, light=None, step=2):
    for (x, y) in R(x0, y0, x1, y1):
        if (x - x0) % step == 0 and (y - y0) % step == 0:
            s.put(x, y, dark)
        elif light is not None:
            s.put(x, y, light)


def knob(s, cx, cy, c=None, r=1.6):
    c = c or C("chrome")
    s.draw(E(cx, cy, r), sph(c, cx, cy, r, spec=False))


def sh_radio(s, rng, name):
    body = C(pick(rng, ["red", "cream", "sky", "tan", "leather", "mint", "black", "blue"]))
    s.draw(PL([(8, 8), (9, 3), (22, 3), (23, 8)], 1.6), flat(C("chrome").m))
    s.draw(RR(3, 8, 28, 27, 2), bev(body))
    s.draw(R(5, 11, 17, 25), flat(C("chrome").l))
    grille(s, 6, 12, 16, 24, C("chrome").x, C("chrome").m)
    s.draw(R(19, 11, 26, 16), flat(C("paper").l))
    for x in range(20, 26, 2):
        s.put(x, 12, C("slate").m)
    s.rect(23, 12, 23, 15, C("red").m)
    knob(s, 22.5, 21.5, C("chrome"), 2.2)
    s.put(4, 9, body.e)


def sh_valve_radio(s, rng, name):
    wood = C(pick(rng, ["walnut", "teak", "brown", "mahogany", "cream"]))
    if wood.base == PAL["cream"]:
        wood = C("ivory")
    mask = R(3, 12, 28, 28) | E(15.5, 12, 12.5, 10) & R(0, 0, 31, 12)
    s.draw(mask, bev(wood))
    cloth = C(pick(rng, ["paper", "tan", "kraft", "gold"]))
    s.draw(E(15.5, 14, 9, 8) & R(0, 0, 31, 18), lambda x, y, m: cloth.m if (x + y) % 2 else cloth.d)
    for x in (10, 13, 18, 21):
        s.rect(x, 7, x, 18, wood.d)
    s.rect(15, 6, 16, 18, wood.d)
    s.draw(R(7, 21, 24, 24), flat(C("paper").l))
    for x in range(8, 24, 2):
        s.put(x, 22, C("walnut").m)
    s.rect(14, 21, 14, 24, C("red").m)
    knob(s, 6.5, 26, C("walnut"), 1.6)
    knob(s, 24.5, 26, C("walnut"), 1.6)
    s.rect(4, 13, 4, 26, wood.l)


def sh_tv(s, rng, name):
    body = C(pick(rng, ["teak", "walnut", "grey", "black", "cream", "silver"]))
    s.draw(L(15, 7, 9, 1), flat(C("chrome").m))
    s.draw(L(17, 7, 23, 1), flat(C("chrome").m))
    s.draw(E(16, 7, 2.5, 1.5), flat(C("black").m))
    s.draw(R(6, 27, 8, 29), flat(C("black").m))
    s.draw(R(23, 27, 25, 29), flat(C("black").m))
    s.draw(RR(2, 8, 29, 27, 2), bev(body))
    scr = C("screen")
    s.draw(RR(4, 10, 22, 25, 3), lambda x, y, m: scr.l if (x - y) in (-6, -7) or (x - y) in (-3,) else scr.m)
    s.pts([(6, 12), (7, 12), (6, 13)], C("glass").e)
    knob(s, 25.5, 13, C("chrome"), 1.8)
    knob(s, 25.5, 18, C("chrome"), 1.8)
    for y in (22, 24):
        s.rect(24, y, 27, y, body.d)


def sh_console(s, rng, name):
    body = C(pick(rng, ["black", "grey", "charcoal", "silver", "white"]))
    s.draw(P((3, 9), (26, 9), (29, 13), (29, 20), (2, 20), (2, 13)), lambda x, y, m: body.l if y < 13 else body.m)
    s.rect(3, 19, 28, 19, body.d)
    s.draw(R(8, 10, 19, 12), flat(body.x))
    s.draw(R(22, 15, 24, 16), flat(C("black").m))
    s.put(5, 16, C("red").l)
    s.rect(3, 13, 28, 13, body.d)
    s.draw(R(8, 15, 18, 16), flat(body.d), ol=False)
    pad = C(pick(rng, ["black", "grey", "charcoal"]))
    gamepad(s, 9, 18, pad, small=True)


def gamepad(s, x0, y0, pad, small=False):
    # body width 20, height 11
    m = RR(x0 + 1, y0, x0 + 19, y0 + 7, 2) | E(x0 + 4, y0 + 8, 3.5, 3) | E(x0 + 16, y0 + 8, 3.5, 3)
    s.draw(m, bev(pad))
    s.rect(x0 + 3, y0 + 4, x0 + 7, y0 + 4, OUT)
    s.rect(x0 + 5, y0 + 2, x0 + 5, y0 + 6, OUT)
    for (dx, dy, cn) in [(15, 2, "yellow"), (17, 4, "red"), (13, 4, "blue"), (15, 6, "green")]:
        s.put(x0 + dx, y0 + dy, C(cn).l)
    s.rect(x0 + 9, y0 + 3, x0 + 11, y0 + 3, pad.x)


def sh_gamepad(s, rng, name):
    pad = C(pick(rng, ["grey", "black", "charcoal", "white", "purple"]))
    m = RR(3, 9, 28, 19, 3) | E(7, 20, 5, 5.5) | E(24, 20, 5, 5.5)
    s.draw(PL([(16, 9), (16, 5), (19, 2), (24, 2)], 1.2), flat(C("black").m))
    s.draw(m, bev(pad))
    s.draw(R(6, 13, 12, 15) | R(8, 11, 10, 17), flat(C("black").m))
    s.put(8, 12, C("black").l)
    for (x, y, cn) in [(23, 11, "yellow"), (26, 14, "red"), (20, 14, "blue"), (23, 17, "green")]:
        s.draw(E(x, y, 1.1), flat(C(cn).l))
    s.rect(14, 14, 15, 14, pad.x)
    s.rect(17, 14, 18, 14, pad.x)


def sh_arcade(s, rng, name):
    body = C(pick(rng, ["black", "red", "blue", "charcoal"]))
    s.draw(P((2, 17), (29, 17), (30, 28), (1, 28)), bev(body))
    s.draw(P((3, 15), (28, 15), (29, 18), (2, 18)), flat(body.l))
    s.draw(L(9, 8, 9, 16, 1.5), flat(C("chrome").l))
    s.draw(E(9, 7, 3.5), sph(C(pick(rng, ["red", "yellow", "blue"])), 9, 7, 3.5))
    cols = picks(rng, ["red", "blue", "yellow", "green", "white", "purple"], 4)
    for i, (x, y) in enumerate([(17, 15), (21, 14), (25, 15), (19, 18)]):
        s.draw(E(x, y + 0.5, 1.6, 1.1), flat(C(cols[i % len(cols)]).l))
    s.rect(4, 22, 27, 22, body.d)
    s.fill(star5(24, 25, 2), C("yellow").m)


def sh_handheld(s, rng, name, kind="gb"):
    if kind == "ds":
        c = C(pick(rng, ["silver", "black", "white", "pink", "blue", "red"]))
        s.draw(RR(4, 2, 27, 14, 2), bev(c))
        s.draw(R(9, 4, 22, 12), flat(C("screen").d))
        s.rect(10, 5, 21, 11, C("sky").m)
        s.rect(10, 9, 21, 11, C("green").m)
        s.draw(RR(4, 16, 27, 29, 2), bev(c))
        s.rect(5, 15, 26, 15, c.x)
        s.draw(R(10, 18, 21, 27), flat(C("screen").d))
        s.rect(11, 19, 20, 26, C("screen").l)
        s.fill(R(5, 21, 8, 22) | R(6, 20, 7, 23), OUT)
        for (x, y) in [(24, 20), (25, 22), (23, 22), (24, 24)]:
            s.put(x, y, C("grey").x)
        return
    if kind == "gw":
        c = C(pick(rng, ["silver", "gold", "red", "chrome"]))
        s.draw(RR(2, 7, 29, 25, 2), bev(c))
        s.draw(R(8, 9, 23, 22), flat(C("black").m))
        s.draw(R(9, 10, 22, 21), flat(C("lcd").l), ol=False)
        s.fill(E(13, 17, 1.5, 2), C("black").l)
        s.fill(R(18, 12, 20, 13), C("black").l)
        s.fill(R(3, 15, 6, 16) | R(4, 14, 5, 17), OUT)
        s.draw(E(26, 16.5, 1.6), flat(C("red").m))
        s.rect(4, 10, 6, 10, C("red").m)
        return
    c = C(pick(rng, ["grey", "grey", "purple", "teal", "yellow", "red", "white", "black"]))
    s.draw(RR(6, 2, 25, 29, 2) | R(8, 26, 25, 29), bev(c))
    s.draw(RR(8, 4, 23, 15, 1), flat(C("slate").m))
    s.draw(R(11, 6, 20, 13), flat(C("lcd").m), ol=False)
    s.rect(11, 6, 20, 6, C("lcd").d)
    s.put(9, 7, C("red").l)
    s.fill(R(8, 20, 12, 21) | R(9, 19, 11, 22) - {(8, 20), (12, 21)} | R(9, 18, 11, 23) - R(8, 18, 8, 23) - R(12, 18, 12, 23), OUT)
    s.fill(R(8, 20, 12, 21), OUT)
    s.draw(E(22, 19, 1.4), flat(C("wine").m))
    s.draw(E(19, 21, 1.4), flat(C("wine").m))
    for i in range(3):
        s.rect(19 + i * 2, 25, 19 + i * 2, 27, c.d)
    s.rect(13, 24, 14, 24, c.x)
    s.rect(16, 24, 17, 24, c.x)


def sh_cartridge(s, rng, name, lot=False):
    shell = C(pick(rng, ["grey", "black", "charcoal", "grey"]))
    if lot:
        s.draw(RR(12, 1, 29, 22, 1), bev(C(pick(rng, ["grey", "black", "red"]))))
        s.rect(14, 3, 27, 10, C(pick(rng, BRIGHTS)).m)
        s.ox, s.oy = -3, 5
    s.draw(RR(6, 3, 25, 28, 1) - R(6, 25, 7, 28) - R(24, 25, 25, 28), bev(shell))
    for x in range(8, 24, 2):
        s.put(x, 4, shell.d)
    lab = C(pick(rng, BRIGHTS))
    s.draw(R(8, 7, 23, 21), flat(lab.m))
    s.rect(9, 8, 22, 10, lab.x)
    s.rect(10, 9, 18, 9, C("white").l)
    fg = C(contrast(rng, lab.base))
    s.fill(P((10, 20), (15, 12), (20, 20)), fg.m)
    s.fill(E(19, 14, 1.6), C("yellow").l)
    s.rect(8, 21, 23, 21, lab.d)
    s.draw(P((13, 24), (18, 24), (15.5, 26)), flat(shell.d), ol=False)
    s.ox = s.oy = 0


def sh_gamebox(s, rng, name, big=False):
    c = C(pick(rng, COVERS + ["orange", "sky", "yellow"]))
    x0, x1, y0, y1 = (3, 25, 1, 30) if big else (5, 24, 3, 29)
    s.draw(P((x1, y0), (x1 + 4, y0 + 2), (x1 + 4, y1 - 1), (x1, y1)), flat(c.d))
    s.draw(R(x0, y0, x1, y1), bev(c))
    s.rect(x0 + 1, y0 + 1, x1 - 1, y0 + 5, c.x)
    s.rect(x0 + 2, y0 + 2, x1 - 5, y0 + 4, C("white").l)
    s.rect(x0 + 3, y0 + 3, x1 - 7, y0 + 3, c.x)
    cx = (x0 + x1) / 2.0
    kind = rng.randrange(3)
    fg = C(contrast(rng, c.base))
    if kind == 0:
        s.fill(P((x0 + 2, y1 - 3), (cx - 3, y0 + 10), (cx + 1, y0 + 16), (cx + 4, y0 + 12), (x1 - 2, y1 - 3)), fg.m)
        s.fill(E(x1 - 5, y0 + 10, 2.2), C("yellow").l)
    elif kind == 1:
        s.fill(E(cx, y0 + 16, 5.5), fg.m)
        s.fill(E(cx - 2, y0 + 14, 2), fg.l)
    else:
        s.fill(P((cx - 5, y1 - 3), (cx, y0 + 8), (cx + 5, y1 - 3)), fg.m)
        s.fill(P((cx, y0 + 8), (cx + 5, y1 - 3), (cx, y1 - 3)), fg.d)
    s.rect(x0 + 2, y1 - 2, x0 + 5, y1 - 2, C("white").m)


def sh_boardgame(s, rng, name, stack=False):
    if stack:
        c2 = C(pick(rng, COVERS))
        s.draw(P((4, 3), (27, 3), (30, 7), (30, 11), (1, 11), (1, 7)), lambda x, y, m: c2.l if y < 7 else c2.d)
        s.rect(3, 8, 28, 8, C("white").m)
    y0 = 12 if stack else 7
    c = C(pick(rng, COVERS + ["yellow", "orange", "sky"]))
    s.draw(P((4, y0), (27, y0), (30, y0 + 4), (30, 28), (1, 28), (1, y0 + 4)), flat(c.d))
    top = P((4, y0), (27, y0), (29, y0 + 4), (2, y0 + 4)) if False else None
    s.draw(R(2, y0 + 1, 29, 24), bev(c))
    s.rect(3, 25, 28, 27, c.d)
    s.rect(3, 25, 28, 25, c.x)
    s.rect(4, y0 + 3, 20, y0 + 5, C("white").e)
    s.rect(5, y0 + 4, 18, y0 + 4, c.m)
    # board motif: dice + pawn
    s.draw(R(6, y0 + 8, 11, y0 + 13), bev(C("white")))
    s.put(7, y0 + 9, OUT)
    s.put(10, y0 + 12, OUT)
    s.put(8, y0 + 10, OUT) if False else None
    pc = C(contrast(rng, c.base))
    s.draw(E(22, y0 + 8, 1.8), sph(pc, 22, y0 + 8, 1.8))
    s.draw(P((20, y0 + 13), (22, y0 + 9), (24, y0 + 13)), flat(pc.m))
    s.draw(R(14, y0 + 9, 17, y0 + 13), flat(C("yellow").l))


def sh_computer(s, rng, name):
    body = C(pick(rng, ["black", "cream", "charcoal", "grey", "brown"]))
    s.draw(P((4, 10), (27, 10), (30, 22), (1, 22)), lambda x, y, m: body.l if y < 12 else body.m)
    s.draw(R(1, 22, 30, 25), flat(body.d))
    s.rect(2, 22, 29, 22, body.x)
    keyc = C("black") if body.base != PAL["black"] else C("grey")
    for j, y in enumerate((13, 15, 17, 19)):
        inset = 5 - j
        for x in range(inset + 1, 31 - inset - 2, 2):
            s.put(x, y, keyc.m)
            if j < 3:
                s.put(x, y + 1, keyc.x)
    s.rect(10, 20, 21, 20, keyc.l)
    for i, cn in enumerate(["red", "orange", "yellow", "green", "sky"]):
        s.rect(20 + i, 11, 20 + i, 11, C(cn).m)
    s.put(4, 23, C("red").l)


def sh_speaker(s, rng, name, kind="cab"):
    if kind == "bt":
        c = C(pick(rng, ["black", "blue", "red", "teal", "grey", "orange"]))
        s.draw(RR(2, 10, 29, 24, 4), cyly(c, 10, 24, spec=True))
        grille(s, 6, 13, 25, 21, c.x)
        s.draw(RR(0, 12, 3, 22, 1), flat(C("black").m))
        s.draw(RR(28, 12, 31, 22, 1), flat(C("black").m))
        s.rect(13, 10, 18, 10, c.e)
        return
    if kind == "pair":
        wood = C(pick(rng, ["black", "teak", "walnut", "oak"]))
        for x0 in (1, 17):
            s.draw(R(x0, 6, x0 + 13, 28), bev(wood))
            s.draw(E(x0 + 6.5, 11, 2), sph(C("black"), x0 + 6.5, 11, 2))
            s.draw(E(x0 + 6.5, 20.5, 4.5), lambda x, y, m, c=x0: C("black").m if math.hypot(x - c - 6.5, y - 20.5) > 2 else C("black").l)
            s.put(x0 + 6, 20, C("chrome").l)
        return
    if kind in ("amp", "smallamp"):
        tol = C(pick(rng, ["black", "cream", "black", "tan"]))
        top = 8 if kind == "amp" else 11
        s.draw(R(12, top - 4, 19, top - 3), flat(C("black").m))
        s.draw(RR(2, top - 2, 29, 28, 1), bev(tol))
        panel = C(pick(rng, ["gold", "chrome", "black"]))
        s.draw(R(4, top, 27, top + 3), flat(panel.m))
        for x in range(7, 26, 3):
            s.put(x, top + 1, OUT)
            s.put(x, top + 2, panel.x)
        s.put(5, top + 1, C("red").l)
        cloth = C(pick(rng, ["paper", "grey", "tan", "wine", "black"]))
        s.draw(R(4, top + 5, 27, 26), lambda x, y, m: cloth.d if (x + y) % 3 == 0 or (x - y) % 3 == 0 else cloth.m)
        s.rect(4, top + 5, 27, top + 5, tol.d)
        return
    wood = C(pick(rng, ["black", "teak", "walnut", "oak", "charcoal"]))
    s.draw(R(6, 2, 25, 29), bev(wood))
    s.draw(E(15.5, 8, 2.8), sph(C("black"), 15.5, 8, 2.8))
    s.draw(E(15.5, 19.5, 7), lambda x, y, m: C("black").l if math.hypot(x - 15.5, y - 19.5) < 2.5 else (C("black").m if math.hypot(x - 15.5, y - 19.5) < 5.5 else C("black").d))
    s.fill(E(15.5, 19.5, 1.2), C("chrome").l)


def sh_component(s, rng, name, face="amp"):
    body = C(pick(rng, ["silver", "black", "chrome", "charcoal"]))
    if face in ("vcr", "settop"):
        body = C(pick(rng, ["black", "charcoal", "silver"]))
    if face == "minihifi":
        spk = C("black")
        s.draw(R(1, 8, 8, 27), bev(spk))
        s.draw(R(23, 8, 30, 27), bev(spk))
        for x in (4.5, 26.5):
            s.draw(E(x, 20, 2.5), flat(spk.l))
            s.draw(E(x, 12, 1.4), flat(spk.l))
        s.draw(R(9, 6, 22, 27), bev(C("charcoal")))
        s.draw(R(11, 8, 20, 11), flat(C("sky").m))
        s.rect(12, 9, 16, 9, C("sky").e)
        s.draw(R(11, 14, 20, 17), flat(C("black").x))
        s.draw(R(11, 20, 20, 23), flat(C("black").x))
        s.put(13, 25, C("blue").e)
        return
    y0, y1 = (9, 23) if face != "settop" else (12, 21)
    s.draw(R(1, y0, 30, y1), bev(body))
    s.rect(2, y1 - 1, 29, y1 - 1, body.d)
    s.draw(R(3, y1 + 1, 5, y1 + 2), flat(C("black").m))
    s.draw(R(26, y1 + 1, 28, y1 + 2), flat(C("black").m))
    if face == "amp":
        for x0 in (4, 12):
            s.draw(R(x0, 11, x0 + 6, 15), flat(C("amber").l))
            s.fill(L(x0 + 1, 15, x0 + 4, 12), OUT)
        knob(s, 23, 13.5, C("chrome"), 2.6)
        for x in (5, 9, 13, 17):
            knob(s, x, 19.5, C("chrome"), 1.3)
        s.put(27, 19, C("red").l)
    elif face == "cassette":
        s.draw(R(4, 11, 15, 20), flat(C("screen").m))
        s.rect(5, 12, 14, 19, C("screen").l)
        s.fill(E(7.5, 15.5, 1.5), C("black").x)
        s.fill(E(11.5, 15.5, 1.5), C("black").x)
        s.rect(7, 18, 12, 18, C("brown").m)
        for x in range(18, 29, 2):
            s.draw(R(x, 18, x, 20), flat(body.l), ol=False)
            s.put(x, 17, OUT) if False else None
        s.draw(R(18, 11, 27, 14), flat(C("black").m))
        s.rect(19, 12, 24, 12, C("amber").l)
    elif face == "vcr":
        s.draw(R(4, 12, 17, 15), flat(C("black").x))
        s.rect(5, 13, 16, 13, body.d)
        s.draw(R(20, 12, 27, 15), flat(C("black").x))
        s.rect(21, 13, 22, 14, C("lime").l)
        s.rect(24, 13, 26, 14, C("lime").l)
        for x in range(5, 17, 3):
            s.draw(R(x, 18, x + 1, 19), flat(body.l), ol=False)
        s.put(27, 19, C("red").l)
    elif face == "settop":
        s.draw(R(20, 14, 27, 18), flat(C("black").x))
        s.rect(21, 15, 22, 17, C("red").l)
        s.rect(24, 15, 26, 17, C("red").l)
        s.put(4, 16, C("lime").l)
        s.rect(7, 16, 12, 16, body.l)


def sh_reeldeck(s, rng, name):
    body = C(pick(rng, ["silver", "black", "charcoal", "teak"]))
    s.draw(R(2, 2, 29, 29), bev(body))
    for cx in (8.5, 22.5):
        s.draw(E(cx, 9.5, 5.5), sph(C("chrome"), cx, 9.5, 5.5, spec=False))
        s.fill(E(cx, 9.5, 4.2) - E(cx, 9.5, 2), C("brown").m)
        s.fill(E(cx, 9.5, 1.2), OUT)
    s.draw(R(12, 17, 19, 20), flat(C("chrome").l))
    s.rect(13, 18, 18, 18, C("black").m)
    for x in range(5, 27, 4):
        s.draw(R(x, 24, x + 2, 26), flat(C("black").m))
    s.draw(R(4, 17, 9, 20), flat(C("amber").l))
    s.draw(R(22, 17, 27, 20), flat(C("amber").l))


def sh_turntable(s, rng, name):
    wood = C(pick(rng, ["teak", "walnut", "silver", "black", "oak"]))
    s.draw(RR(1, 5, 30, 28, 1), bev(wood))
    s.draw(E(13, 16.5, 9.6), flat(C("chrome").d))
    vinyl_disc(s, 13, 16.5, 8.6, C(pick(rng, BRIGHTS)))
    s.draw(E(25, 9, 2.2), sph(C("chrome"), 25, 9, 2.2))
    s.draw(PL([(25, 9), (25, 20), (20, 23)], 1), flat(C("chrome").l))
    s.draw(R(18, 22, 20, 24), flat(C("black").m))
    s.draw(R(24, 24, 28, 25), flat(C("black").m))
    s.put(4, 26, C("red").l)


def sh_boombox(s, rng, name):
    body = C(pick(rng, ["silver", "black", "charcoal", "red"]))
    s.draw(PL([(7, 11), (7, 5), (24, 5), (24, 11)], 2), flat(C("black").m))
    s.draw(RR(1, 10, 30, 27, 2), bev(body))
    for cx in (7, 24):
        s.draw(E(cx, 20, 5.2), flat(C("chrome").l))
        s.fill(E(cx, 20, 4.2), C("black").m)
        grille(s, cx - 3, 17, cx + 3, 23, C("black").x)
        s.fill(E(cx, 20, 1.4), C("black").l)
    s.draw(R(12, 18, 19, 25), flat(C("screen").m))
    s.rect(13, 19, 18, 24, C("screen").l)
    s.put(14, 21, OUT)
    s.put(17, 21, OUT)
    s.draw(R(4, 12, 27, 14), flat(C("black").x), ol=False)
    s.rect(6, 13, 16, 13, C("amber").l)
    for x in range(18, 27, 2):
        s.put(x, 12, body.l)


def sh_phone(s, rng, name):
    c = C(pick(rng, ["charcoal", "black", "grey", "blue", "silver"]))
    s.draw(R(20, 1, 21, 4), flat(C("black").m))
    s.draw(RR(9, 3, 22, 30, 3), bev(c))
    s.draw(R(11, 6, 20, 13), flat(C("slate").d))
    s.rect(12, 7, 19, 12, C("lcd").m)
    s.rect(13, 9, 15, 9, C("lcd").x)
    s.rect(15, 10, 17, 10, C("lcd").x)
    s.draw(E(15.5, 16, 2.3, 1.3), flat(c.l))
    for j in range(4):
        for i in range(3):
            s.draw(R(11 + i * 4, 19 + j * 3, 12 + i * 4, 19 + j * 3), flat(C("grey").l), ol=False)


def sh_tablet(s, rng, name):
    c = C(pick(rng, ["black", "white", "silver", "charcoal"]))
    s.draw(RR(2, 6, 29, 26, 2), bev(c))
    scr = C("screen")
    s.draw(R(5, 8, 26, 24), lambda x, y, m: scr.l if (x - y) in (-2, -3, 6) else scr.m)
    for (x, y, cn) in [(8, 11, "red"), (12, 11, "green"), (16, 11, "sky"), (8, 15, "yellow"), (12, 15, "pink")]:
        s.rect(x, y, x + 1, y + 1, C(cn).l)
    s.put(28, 16, c.x)


def sh_remote(s, rng, name, lot=True):
    if lot:
        c2 = C(pick(rng, ["grey", "silver", "charcoal"]))
        s.draw(RR(16, 3, 24, 28, 2), bev(c2))
        for y in range(7, 25, 3):
            s.rect(18, y, 22, y, c2.x)
    c = C("black")
    s.draw(RR(7, 2, 15, 30, 2), bev(c))
    s.put(11, 4, C("red").l)
    s.draw(R(9, 6, 10, 7), flat(C("red").m), ol=False)
    for j in range(5):
        for i in range(2):
            s.put(9 + i * 3, 10 + j * 3, C("grey").l)
            s.put(10 + i * 3, 10 + j * 3, C("grey").m)
    s.draw(R(9, 26, 13, 27), flat(C("blue").m), ol=False)


def sh_calculator(s, rng, name):
    c = C(pick(rng, ["black", "charcoal", "brown", "silver", "cream"]))
    s.draw(RR(7, 2, 24, 29, 1), bev(c))
    s.draw(R(9, 4, 22, 9), flat(C("black").x))
    for x in (11, 14, 17, 20):
        s.rect(x, 6, x + 1, 7, C("red").l)
    for j in range(5):
        for i in range(4):
            cn = "orange" if i == 3 else ("grey" if j > 0 else "red")
            s.draw(R(9 + i * 4, 12 + j * 3, 10 + i * 4, 12 + j * 3), flat(C(cn).l))


def sh_headphones(s, rng, name):
    c = C(pick(rng, ["black", "silver", "red", "blue", "white", "charcoal"]))
    band = ring(15.5, 17, 13, 10.5) & R(0, 0, 31, 17)
    s.draw(band, flat(C("black").m))
    s.fill(ring(15.5, 17, 12.2, 11.4) & R(0, 3, 31, 12), C("black").l)
    for x0 in (1, 23):
        s.draw(RR(x0, 14, x0 + 7, 28, 2), bev(c))
        s.draw(R(x0 + (5 if x0 == 1 else 0), 16, x0 + (7 if x0 == 1 else 2), 26), flat(C("black").l))
        s.put(x0 + 3, 21, c.e)


def sh_coil(s, rng, name, lights=False):
    c = C(pick(rng, ["black", "grey", "white", "charcoal"]) if not lights else "green")
    for i, (ro, yo) in enumerate([(12, 17), (10, 16), (8, 15.5)]):
        s.draw(ring(15.5, yo, ro, ro - 2, ro * 0.62, ro * 0.62 - 2), lambda x, y, m: c.l if y < yo else c.m)
    s.draw(L(4, 20, 2, 29, 2), flat(c.m))
    s.draw(R(0, 27, 4, 30), flat(C("black").m if not lights else C("green").d))
    s.put(1, 30, C("chrome").l)
    s.put(3, 30, C("chrome").l)
    if lights:
        cols = ["red", "yellow", "sky", "pink", "lime", "orange"]
        k = 0
        for (ro, yo) in [(12, 17), (10, 16), (8, 15.5)]:
            for a in range(0, 360, 45):
                x = 15.5 + (ro - 1) * math.cos(math.radians(a + ro * 7))
                y = yo + (ro * 0.62 - 1) * math.sin(math.radians(a + ro * 7))
                s.draw(E(round(x), round(y), 1.2), sph(C(cols[k % len(cols)]), round(x), round(y), 1.2))
                k += 1


def sh_walkman(s, rng, name):
    c = C(pick(rng, ["silver", "blue", "yellow", "red", "black", "chrome"]))
    for i, cn in enumerate(["grey", "grey", "orange", "grey"]):
        s.draw(R(8 + i * 4, 2, 10 + i * 4, 4), flat(C(cn).l))
    s.draw(RR(5, 4, 26, 29, 2), bev(c))
    s.draw(R(8, 8, 23, 19), flat(C("screen").d))
    s.rect(9, 9, 22, 18, C("glass").d)
    s.rect(9, 11, 22, 16, C("cream").m)
    for cx in (12, 19):
        s.fill(E(cx, 13.5, 1.6), C("black").m)
        s.put(cx, 13, C("white").l)
    s.rect(9, 11, 22, 11, C("red").m)
    s.rect(8, 23, 22, 23, c.d)
    s.draw(R(20, 25, 23, 26), flat(C("black").m), ol=False)
    s.pts([(10, 9), (11, 9)], C("white").e)


def sh_discman(s, rng, name):
    c = C(pick(rng, ["silver", "chrome", "grey", "black", "blue"]))
    s.draw(RR(2, 3, 29, 29, 6), bev(c))
    s.draw(E(15.5, 15, 10.5), sph(c, 15.5, 15, 10.5, spec=False))
    s.fill(ring(15.5, 15, 10.5, 9.8), c.d)
    s.draw(E(15.5, 15, 2.5), flat(c.l))
    s.fill(R(9, 8, 14, 8), c.e)
    s.draw(R(6, 26, 25, 27), flat(C("black").m), ol=False)
    for x in range(8, 24, 4):
        s.put(x, 26, C("grey").l)
    s.draw(R(20, 4, 24, 5), flat(C("screen").m), ol=False)


# ---------------------------------------------------------------- instruments
def sh_guitar(s, rng, name, kind="acoustic"):
    if kind in ("acoustic", "uke"):
        body = C(pick(rng, ["pine", "tan", "oak", "teak", "walnut", "amber"]))
        neck = C("walnut")
        sc = 0.72 if kind == "uke" else 1.0
        ly, uy = 21.5, 13.5
        s.draw(R(14, 2, 17, 5), flat(neck.d))
        s.draw(R(15, 5, 16, 13), cylx(C("walnut"), 15, 16))
        for y in range(7, 13, 2):
            s.put(15, y, C("chrome").l)
        bm = E(15.5, ly + (1 - sc) * 6, 8.5 * sc + 0.5, 7.5 * sc) | E(15.5, uy + (1 - sc) * 7, 6.5 * sc + 0.3, 5.5 * sc)
        s.draw(bm, lambda x, y, m: body.l if x < 12 else (body.d if x > 20 or y > 26 else body.m))
        hy = 16.5 + (1 - sc) * 7
        s.fill(E(15.5, hy, 2.3 * max(sc, 0.8)), body.x)
        s.fill(E(15.5, hy, 1.4 * max(sc, 0.8)), OUT)
        s.rect(13, int(ly + 2 + (1 - sc) * 5), 18, int(ly + 2 + (1 - sc) * 5), C("walnut").d)
        s.rect(15, int(hy) - 6, 16, int(hy) - 3, neck.m) if False else None
        s.pts([(13, 3), (13, 5), (18, 3), (18, 5)], C("chrome").l)
        return
    if kind == "banjo":
        neck = C("walnut")
        s.draw(R(14, 1, 17, 4), flat(neck.d))
        s.draw(R(15, 4, 16, 13), cylx(neck, 15, 16))
        s.draw(E(15.5, 20.5, 9), flat(C("chrome").m))
        s.draw(E(15.5, 20.5, 7.5), sph(C("paper"), 15.5, 20.5, 7.5, spec=False))
        for a in range(0, 360, 30):
            s.put(int(round(15.5 + 8.3 * math.cos(math.radians(a)))), int(round(20.5 + 8.3 * math.sin(math.radians(a)))), C("chrome").x)
        s.rect(14, 23, 17, 23, C("walnut").m)
        s.pts([(15, 14), (15, 16), (15, 18), (15, 20), (16, 22)], C("slate").l)
        s.draw(L(19, 5, 22, 8), flat(C("chrome").l))
        return
    # electric / bass
    body = C(pick(rng, ["red", "sky", "black", "white", "sunburst", "mint", "yellow", "blue"]) if kind == "electric" else pick(rng, ["black", "sunburst", "white", "red", "walnut"]))
    if body.base == PAL.get("sunburst", "sunburst"):
        body = C("amber")
    neck = C("pine")
    top = 1 if kind == "bass" else 2
    s.draw(R(14, top, 17, top + 4), flat(C("black").m))
    s.draw(R(15, top + 4, 16, 15), cylx(neck, 15, 16))
    for y in range(top + 6, 15, 2):
        s.put(15, y, C("chrome").l)
    bm = E(15.5, 22, 8.5, 6.5) | E(11, 15.5, 3, 4) | E(20.5, 16, 2.5, 3.5)
    bm -= E(15.5, 13, 2.6, 3)
    s.draw(bm, lambda x, y, m: body.l if x < 11 else (body.d if x > 20 or y > 26 else body.m))
    pg = C("white" if body.base != PAL["white"] else "black")
    s.fill(P((11, 18), (16, 16), (19, 26), (14, 27), (11, 24)), pg.m)
    s.draw(R(14, 18, 17, 19), flat(C("black").m), ol=False)
    s.draw(R(14, 21, 17, 22), flat(C("black").m), ol=False)
    s.rect(14, 24, 17, 24, C("chrome").l)
    s.put(20, 24, C("chrome").l)
    s.put(21, 26, C("chrome").l)
    s.pts([(13, top + 1), (13, top + 3), (18, top + 1), (18, top + 3)], C("chrome").l)


def sh_violin(s, rng, name, cello=False):
    body = C(pick(rng, ["amber", "teak", "mahogany", "tan"]))
    neck = C("black")
    if cello:
        s.draw(L(15.5, 27, 15.5, 30), flat(C("chrome").m))
    s.draw(E(15.5, 1.8, 1.6), flat(C("walnut").d))
    s.draw(R(15, 2, 16, 8), flat(C("walnut").d))
    bm = E(15.5, 22, 7.5 if cello else 6.5, 5.5 if cello else 5) | E(15.5, 12.5, 6.5 if cello else 5.5, 4.5 if cello else 4)
    bm |= R(12, 12, 19, 22)
    bm -= E(8, 17.5, 1.5, 2) | E(23, 17.5, 1.5, 2)
    s.draw(bm, lambda x, y, m: body.l if x < 12 else (body.d if x > 19 else body.m))
    s.fill(R(15, 7, 16, 19), neck.m)
    s.fill(R(15, 7, 15, 19), neck.l)
    s.pts([(11, 15), (11, 16), (12, 17), (12, 18), (20, 15), (20, 16), (19, 17), (19, 18)], body.x)
    s.rect(13, 21, 18, 21, C("pine").l)
    s.draw(P((14, 23), (17, 23), (16, 27), (15, 27)), flat(C("black").m))
    s.pts([(14, 4), (17, 4), (14, 6), (17, 6)], C("walnut").m)


def sh_trumpet(s, rng, name):
    br = C(pick(rng, ["brass", "gold", "silver"]))
    s.draw(ring(14, 17.5, 7.5, 5.5, 4.5, 2.5) & R(0, 15, 31, 31), flat(br.d))
    s.draw(L(3, 13, 22, 13, 2), cyly(br, 12, 14))
    s.draw(P((20, 12), (29, 5), (29, 22), (20, 15)), lambda x, y, m: br.l if y < 11 else (br.m if y < 17 else br.d))
    s.draw(E(29.5, 13.5, 1.2, 8.5), flat(br.x))
    s.draw(R(1, 12, 3, 14), flat(C("silver").l))
    for x in (9, 12, 15):
        s.draw(R(x, 8, x + 1, 17), cylx(br, x, x + 1))
        s.draw(R(x - 1, 6, x + 2, 7), flat(C("pearl").l))
    s.rect(4, 12, 19, 12, br.e)


def sh_sax(s, rng, name):
    br = C(pick(rng, ["brass", "gold", "bronze"]))
    s.draw(PL([(6, 3), (10, 2), (13, 6)], 2), flat(C("black").m))
    body = PL([(13, 6), (14, 12), (15, 20), (17, 25)], 3.5) | PL([(15, 20), (17, 26), (21, 27), (24, 23)], 4.5)
    s.draw(body, lambda x, y, m: br.l if x < 14 else (br.d if y > 26 or x > 22 else br.m))
    s.draw(P((22, 12), (29, 12), (27, 23), (22, 24)), lambda x, y, m: br.m if x < 25 else br.d)
    s.draw(E(25.5, 12.5, 3.8, 1.6), flat(br.x))
    for (x, y) in [(14, 10), (15, 13), (15, 16), (16, 19), (18, 23)]:
        s.draw(E(x, y, 1), flat(C("pearl").l), ol=False)
    s.put(13, 8, br.e)


def sh_woodwind(s, rng, name, kind="clarinet"):
    if kind == "recorders":
        for i, (dx, cn) in enumerate([(-7, "cream"), (0, "brown"), (7, "ivory")]):
            c = C(pick(rng, ["cream", "ivory", "brown", "pine", "sky", "pink"]))
            x = 15 + dx
            s.draw(R(x - 1, 4, x + 1, 28), cylx(c, x - 1, x + 1))
            s.draw(R(x - 2, 26, x + 2, 29), cylx(c, x - 2, x + 2))
            s.draw(P((x - 1, 1), (x + 1, 1), (x + 1, 4), (x - 1, 4)), flat(c.d))
            for y in range(10, 24, 3):
                s.put(x, y, OUT)
        return
    if kind == "flute":
        c = C("chrome")
        s.draw(L(2, 26, 29, 5, 2.6), lambda x, y, m: c.l if (x + y) < 30 else c.m)
        for t in range(3, 11):
            x, y = 2 + t * 2.5, 26 - t * 1.95
            s.draw(E(round(x), round(y), 0.9), flat(C("chrome").d))
        s.draw(E(26, 7.5, 1.5), flat(C("chrome").x))
        return
    c = C("black")
    s.draw(L(6, 25, 25, 4, 3), lambda x, y, m: c.l if (x + y) < 30 else c.m)
    s.draw(E(5.5, 26.5, 3.4), sph(C("black"), 5.5, 26.5, 3.4, spec=False))
    s.fill(E(4.5, 27.5, 1.6), C("black").x)
    s.draw(L(25, 4, 28, 1, 2), flat(C("black").l))
    for t in (0.25, 0.45, 0.55, 0.7):
        x, y = 6 + 19 * t, 25 - 21 * t
        s.draw(L(round(x) - 1, round(y) - 1, round(x) + 1, round(y) + 1), flat(C("chrome").l), ol=False)
    s.draw(R(20, 8, 21, 9), flat(C("chrome").l), ol=False)
    s.rect(10, 20, 11, 21, C("chrome").l)


def sh_harmonica(s, rng, name):
    c = C("chrome")
    s.draw(RR(2, 9, 29, 13, 1), cyly(c, 9, 13, spec=True))
    s.draw(R(2, 14, 29, 17), flat(C(pick(rng, ["black", "red", "pine", "blue"])).m))
    for x in range(4, 28, 2):
        s.put(x, 15, OUT)
        s.put(x, 16, OUT)
    s.draw(RR(2, 18, 29, 22, 1), cyly(c, 18, 22))
    s.rect(5, 11, 12, 11, c.d)
    for x in (4, 27):
        s.put(x, 20, c.x)
    s.draw(RR(11, 24, 29, 27, 1), cyly(C("red"), 24, 27))
    s.rect(13, 25, 20, 25, C("white").l)


def sh_keyboard(s, rng, name, synth=False):
    body = C(pick(rng, ["black", "charcoal", "grey", "silver"]) if not synth else pick(rng, ["black", "silver", "cream", "charcoal"]))
    s.draw(R(1, 9, 30, 25), bev(body))
    if synth:
        s.draw(R(0, 8, 2, 26), bev(C("teak")))
        s.draw(R(29, 8, 31, 26), bev(C("teak")))
        for j in range(2):
            for i in range(6):
                knob(s, 5 + i * 4, 12 + j * 3, C(pick(rng, ["black", "black", "chrome"])), 1.1)
        s.put(26, 12, C("red").l)
    else:
        grille(s, 3, 11, 8, 15, body.x)
        grille(s, 23, 11, 28, 15, body.x)
        s.draw(R(11, 11, 20, 13), flat(C("lcd").m))
        for x in range(11, 21, 2):
            s.put(x, 15, C(pick(rng, ["red", "yellow", "sky", "lime"])).l)
    white = C("white")
    s.draw(R(3, 18, 28, 25), flat(white.m))
    for x in range(3, 29, 3):
        s.rect(x + 2, 18, x + 2, 25, white.d)
    for x in range(4, 28, 3):
        if (x // 3) % 7 not in (2, 6):
            s.rect(x + 0, 18, x + 1, 21, C("black").x)
    s.rect(3, 25, 28, 25, white.d)


def sh_drum(s, rng, name, kit=False):
    shell = C(pick(rng, ["red", "blue", "black", "silver", "wine", "teal", "white", "gold"]))
    if kit:
        # bass drum front view + tom
        s.draw(E(22, 9, 5.5, 4), flat(shell.m))
        s.draw(E(22, 7, 5.5, 2.2), flat(C("white").m))
        s.draw(E(15.5, 19, 11), flat(shell.m))
        s.draw(E(15.5, 19, 9.2), sph(C("white"), 15.5, 19, 9.2, spec=False))
        s.fill(E(15.5, 19, 4.5), C(pick(rng, ["black", "red", "navy"])).m)
        s.fill(E(14.5, 18, 1.8), C("white").e)
        for a in range(0, 360, 45):
            s.put(int(round(15.5 + 10.2 * math.cos(math.radians(a)))), int(round(19 + 10.2 * math.sin(math.radians(a)))), C("chrome").l)
        s.draw(L(3, 30, 7, 26, 1.5), flat(C("chrome").m))
        s.draw(L(28, 30, 24, 26, 1.5), flat(C("chrome").m))
        return
    s.draw(E(15.5, 24, 13, 4) | R(3, 13, 28, 24), cylx(shell, 3, 28, spec=True))
    for x in (5, 10, 15, 21, 26):
        s.rect(x, 15, x, 22, C("chrome").l)
        s.put(x, 15, C("chrome").e)
    s.draw(E(15.5, 13, 13, 4), flat(C("chrome").m))
    s.draw(E(15.5, 13, 11.8, 3.2), lambda x, y, m: C("white").e if x < 12 and y < 13 else C("white").m)
    s.fill(ring(15.5, 24, 13, 12, 4, 3) & R(0, 24, 31, 31), C("chrome").m)
    wood = C("pine")
    s.draw(L(4, 2, 18, 12, 1.6), cylx(wood, 4, 18))
    s.draw(L(27, 2, 13, 12, 1.6), cylx(wood, 13, 27))


def sh_tambourine(s, rng, name):
    rim = C(pick(rng, ["red", "pine", "black", "blue"]))
    s.draw(E(15.5, 15.5, 13), flat(rim.m))
    s.draw(E(15.5, 15.5, 10.5), sph(C("paper"), 15.5, 15.5, 10.5, spec=False))
    for a in range(0, 360, 60):
        x, y = 15.5 + 11.8 * math.cos(math.radians(a)), 15.5 + 11.8 * math.sin(math.radians(a))
        s.draw(E(round(x), round(y), 1.6, 1.6), sph(C("brass"), round(x), round(y), 1.6))
    s.draw(E(24, 25, 3.5), sph(C("red"), 24, 25, 3.5))
    s.draw(L(26, 27, 29, 30, 1.5), flat(C("pine").m))


def sh_accordion(s, rng, name):
    c = C(pick(rng, ["red", "black", "white", "blue", "green", "wine", "pearl"]))
    s.draw(P((9, 6), (22, 6), (22, 27), (9, 27)), lambda x, y, m: C("black").l if x % 2 else C("black").x)
    for y in (6, 27):
        s.rect(9, y, 22, y, C("chrome").m)
    s.draw(RR(1, 4, 9, 29, 1), bev(c))
    for (x, y) in [(3, 8), (6, 9), (3, 12), (6, 13), (3, 16), (6, 17), (3, 20), (6, 21), (3, 24), (6, 25)]:
        s.put(x, y, C("pearl").e)
    s.draw(RR(22, 4, 30, 29, 1), bev(c))
    s.draw(R(25, 6, 29, 27), flat(C("white").e))
    for y in range(7, 27, 2):
        s.rect(25, y, 29, y, C("white").d)
    for y in range(8, 26, 4):
        s.rect(25, y, 26, y + 1, C("black").x)
    s.rect(2, 5, 8, 5, c.e)


def sh_pedal(s, rng, name):
    c = C(pick(rng, ["orange", "yellow", "green", "blue", "red", "purple", "silver", "pink"]))
    s.draw(RR(6, 4, 25, 29, 2), bev(c))
    for x in (10, 15.5, 21):
        knob(s, x, 9, C("black"), 1.8)
        s.put(int(x), 8, C("white").e)
    s.draw(E(15.5, 14, 0.8), flat(C("red").e))
    s.draw(R(8, 17, 23, 20), flat(c.d), ol=False)
    s.rect(9, 18, 18, 18, C("white").l)
    s.draw(E(15.5, 24.5, 3), sph(C("chrome"), 15.5, 24.5, 3))
    s.draw(R(3, 10, 5, 12), flat(C("chrome").m))
    s.draw(R(26, 10, 28, 12), flat(C("chrome").m))


def sh_bell(s, rng, name):
    br = C(pick(rng, ["brass", "gold", "bronze"]))
    s.draw(RR(13, 1, 18, 9, 1), cylx(C(pick(rng, ["leather", "wine", "walnut"])), 13, 18))
    m = P((11, 10), (20, 10), (22, 16), (26, 25), (5, 25), (9, 16)) | E(15.5, 11, 5, 2.5)
    s.draw(m, cylx(br, 5, 26, spec=True))
    s.draw(E(15.5, 25.5, 11, 2.3), lambda x, y, m: br.d if y < 26 else br.x)
    s.draw(E(15.5, 28.5, 1.8), sph(br, 15.5, 28.5, 1.8))


# ---------------------------------------------------------------- clothing
def shirt_mask(long=False, hood=False):
    if long:
        m = P((10, 3), (21, 3), (28, 7), (30, 27), (26, 28), (24, 14), (24, 29), (7, 29), (7, 14), (5, 28), (1, 27), (3, 7))
    else:
        m = P((10, 3), (21, 3), (29, 9), (26, 14), (23, 12), (23, 29), (8, 29), (8, 12), (5, 14), (2, 9))
    return m


def garment(s, c, mask, stripes=None):
    def f(x, y, m):
        if stripes:
            col = stripes(x, y)
            if col is not None:
                return col
        t = (x, y - 1) not in m or (x - 1, y) not in m
        b = (x + 1, y) not in m or (x, y + 1) not in m
        return c.l if t and not b else (c.d if b and not t else c.m)
    s.draw(mask, f)


def sh_tshirt(s, rng, name, kind="plain"):
    c = C(pick(rng, BRIGHTS + ["white", "black", "grey"]))
    stripes = None
    long = False
    if kind == "football":
        c = C(pick(rng, ["red", "blue", "white", "sky", "yellow", "green", "navy"]))
        c2 = C(contrast(rng, c.base, ["white", "red", "blue", "black", "yellow", "navy"]))
        if rng.random() < 0.5:
            stripes = lambda x, y: c2.m if x % 4 in (0, 1) and y > 5 else None
    elif kind == "rugby":
        long = True
        c = C(pick(rng, ["navy", "green", "red", "forest", "wine"]))
        c2 = C(pick(rng, ["white", "yellow", "gold", "sky"]))
        stripes = lambda x, y: c2.m if y % 6 in (0, 1) and y > 6 else None
    elif kind == "band":
        c = C(pick(rng, ["black", "black", "charcoal", "white"]))
    elif kind == "jumper":
        long = True
        c = C(pick(rng, ["red", "green", "navy", "crimson", "forest"]))
        stripes = lambda x, y: (C("white").l if (y in (9, 23) or (y in (10, 22) and x % 2)) else None)
    elif kind == "hoodie":
        long = True
        c = C(pick(rng, ["grey", "black", "navy", "red", "forest", "purple", "slate"]))
    m = shirt_mask(long)
    if kind == "hoodie":
        s.draw(E(15.5, 5, 7.5, 4.5), flat(c.d))
    garment(s, c, m, stripes)
    # neckline / collar
    if kind in ("football", "rugby"):
        col = C("white") if kind == "rugby" else c2
        s.draw(P((11, 3), (20, 3), (15.5, 8)), flat(C("black").x))
        s.draw(P((10, 2), (14, 2), (15.5, 7), (12, 5)), flat(col.l))
        s.draw(P((21, 2), (17, 2), (15.5, 7), (19, 5)), flat(col.m))
        if kind == "football":
            s.draw(E(19.5, 11, 1.6), flat(C("gold").l))
            s.rect(8, 12, 8, 13, OUT) if False else None
    elif kind == "hoodie":
        s.fill(E(15.5, 4.5, 4, 2.5), c.x)
        s.rect(13, 7, 13, 13, C("white").l)
        s.rect(18, 7, 18, 12, C("white").l)
        s.draw(P((10, 19), (21, 19), (23, 25), (8, 25)), flat(c.d), ol=False)
        s.rect(10, 19, 21, 19, OUT)
        s.rect(24, 28, 24, 28, OUT) if False else None
        s.rect(7, 28, 24, 29, c.d)
    else:
        s.fill(E(15.5, 3, 3.5, 2.2), OUT)
        s.fill(E(15.5, 2.3, 2.6, 1.6) & R(0, 3, 31, 31), c.x)
        if kind == "band":
            fg = C(pick(rng, ["white", "yellow", "red", "sky"]))
            s.fill(E(15.5, 16, 4.5), fg.m)
            s.fill(E(14, 15, 1.2), C("black").m)
            s.fill(E(17, 15, 1.2), C("black").m)
            s.rect(14, 18, 17, 18, C("black").m)
            s.rect(11, 10, 20, 10, fg.l)
        elif kind == "jumper":
            s.fill(P((15.5, 12), (19, 19), (12, 19)), C("green").m if c.base != PAL["green"] else C("red").m)
            s.put(15, 11, C("yellow").e)
            s.put(16, 11, C("yellow").e)
            s.rect(7, 28, 24, 29, c.d)
            s.rect(1, 26, 5, 27, c.d)
            s.rect(26, 26, 30, 27, c.d)
        elif kind == "plain":
            fg = C(contrast(rng, c.base))
            s.fill(star5(15.5, 15, 3.5) if rng.random() < 0.5 else E(15.5, 15, 3), fg.m)
    if kind == "stack":
        pass


def sh_tshirt_stack(s, rng, name):
    y = 29
    for i in range(4):
        c = C(pick(rng, BRIGHTS + ["white", "black", "grey"]))
        s.draw(RR(3 + (i % 2), y - 5, 28 - (i % 2), y, 1), bev(c))
        s.rect(6, y - 2, 25, y - 2, c.d)
        y -= 6
    s.fill(E(15.5, y + 6, 3, 1.5), OUT)


def sh_jacket(s, rng, name, kind="denim", coat=False):
    pal = {"denim": ["denim", "navy", "sky"], "leather": ["black", "leather", "brown", "charcoal"],
           "wax": ["olive", "forest", "khaki"], "track": BRIGHTS, "ski": ["red", "yellow", "teal", "orange", "pink", "blue"],
           "work": ["navy", "brown", "tan", "khaki", "orange"], "tweed": ["tweed", "brown", "olive"],
           "coat": ["navy", "charcoal", "tan", "wine", "camel" if False else "brown", "forest", "black"],
           "parka": ["olive", "khaki", "forest"]}[kind]
    c = C(pick(rng, pal))
    bottom = 30 if coat else 28
    m = P((10, 3), (21, 3), (28, 7), (30, 26), (26, 27), (24, 14), (24, bottom), (7, bottom), (7, 14), (5, 27), (1, 26), (3, 7))
    stripes = None
    if kind == "track":
        c2 = C(contrast(rng, c.base, ["white", "white", "navy", "black", "yellow"]))
        stripes = lambda x, y: c2.m if (y > 6 and ((x in (27, 28) and y < 26 and x - y * 0.12 > 23.5) or (x in (3, 4) and y < 26 and x + y * 0.12 < 7.5))) else None
    elif kind == "tweed":
        stripes = lambda x, y: c.d if (x % 4 == 0 or y % 4 == 0) else None
    elif kind == "ski":
        c2 = C(contrast(rng, c.base, ["white", "navy", "black", "sky"]))
        stripes = lambda x, y: c2.m if 13 <= y <= 17 else None
    if kind == "parka":
        s.draw(E(15.5, 4, 8, 4), flat(C("cream").d))
        s.fill({(x, y) for (x, y) in E(15.5, 4, 8, 4) if (x + y) % 2}, C("cream").m)
    garment(s, c, m, stripes)
    # opening / zip
    s.rect(15, 5, 16, bottom, c.x)
    zip_c = C("chrome").l if kind in ("leather", "track", "ski", "parka", "denim") else None
    if kind in ("leather", "track", "ski", "parka"):
        s.rect(15, 5, 15, bottom, zip_c)
    # collar / lapels
    if kind in ("tweed", "coat"):
        s.draw(P((11, 3), (15, 3), (15, 14), (11, 8)), flat(c.d))
        s.draw(P((20, 3), (16, 3), (16, 14), (20, 8)), flat(c.d))
        s.fill(P((13, 3), (15, 3), (15, 11)), C("white").l if kind == "tweed" else C("cream").m)
        for y in (16, 20, 24):
            s.put(17, y, C("black").m if kind == "coat" else C("walnut").m)
    elif kind in ("leather", "denim", "work", "wax"):
        colc = C("walnut") if kind == "wax" else c
        s.draw(P((10, 2), (14, 2), (15, 8), (11, 7)), flat(colc.l))
        s.draw(P((21, 2), (17, 2), (16, 8), (20, 7)), flat(colc.m))
    elif kind in ("track", "ski"):
        s.draw(R(12, 1, 19, 4), flat(c.l))
        s.rect(15, 1, 15, 4, zip_c)
    if kind == "denim":
        for y in (10, 18):
            s.rect(9, y, 13, y, C("gold").m)
            s.rect(18, y, 22, y, C("gold").m)
        s.draw(R(9, 11, 13, 13), flat(c.d), ol=False)
        s.draw(R(18, 11, 22, 13), flat(c.d), ol=False)
    elif kind in ("wax", "work", "coat", "parka"):
        for x0 in (8, 18):
            s.draw(R(x0, 19, x0 + 5, 23), flat(c.d), ol=False)
            s.rect(x0, 19, x0 + 5, 19, OUT)
    elif kind == "leather":
        s.pts([(9, 9), (10, 10), (11, 11)], c.e)
        s.rect(19, 18, 22, 18, zip_c)
    elif kind == "ski":
        s.rect(7, bottom, 24, bottom, C("black").m)
    if kind in ("leather", "denim", "track", "work", "wax"):
        s.rect(7, bottom - 1, 24, bottom - 1, c.d)


def sh_dress(s, rng, name):
    c = C(pick(rng, ["red", "pink", "sky", "yellow", "navy", "teal", "violet", "mint", "wine", "green"]))
    s.draw(PL([(10, 1), (11, 6)], 1) | PL([(21, 1), (20, 6)], 1), flat(c.d))
    m = P((10, 6), (21, 6), (20, 14), (21, 16), (28, 29), (3, 29), (10, 16), (11, 14))
    pattern = pick(rng, ["dots", "none", "stripes"])
    fg = C("white")

    def st(x, y):
        if pattern == "dots" and y > 16 and (x * 3 + y * 2) % 7 == 0:
            return fg.l
        if pattern == "stripes" and y > 17 and y % 4 == 0:
            return fg.m
        return None
    garment(s, c, m, st)
    s.draw(R(10, 14, 21, 15), flat(C(contrast(rng, c.base, ["white", "black", "gold", "navy"])).m))
    s.fill(E(15.5, 6, 3, 2) & R(0, 6, 31, 9), c.x)


def sh_suitcase(s, rng, name):
    c = C(pick(rng, ["tan", "leather", "brown", "wine", "forest", "navy", "cream"]))
    s.draw(PL([(12, 8), (12, 4), (19, 4), (19, 8)], 2), flat(C("black").m))
    s.draw(RR(2, 8, 29, 28, 1), bev(c))
    for x in (8, 23):
        s.rect(x, 9, x + 1, 27, c.x)
        s.rect(x, 9, x, 27, c.d)
    for (x, y) in [(3, 9), (27, 9), (3, 26), (27, 26)]:
        s.draw(R(x, y, x + 1, y + 1), flat(C("brass").l), ol=False)
    s.draw(R(14, 9, 17, 11), flat(C("brass").m), ol=False)
    st = C(pick(rng, ["red", "yellow", "sky", "white"]))
    s.draw(E(18, 19, 3, 2.2), flat(st.l))
    s.fill(E(12, 22, 2.2, 1.6), C("white").m)


def sh_binbag(s, rng, name):
    c = C(pick(rng, ["black", "charcoal", "black", "navy"]))
    m = E(15.5, 20, 13, 9.5) | P((12, 11), (19, 11), (16.5, 6), (14.5, 6))
    s.draw(m, lambda x, y, m: c.e if (x - 2 * y) % 13 == 0 and y < 22 and x < 16 else (c.l if (x < 10 and y < 20) else (c.d if y > 25 or x > 24 else c.m)))
    s.draw(P((12, 3), (15, 5), (16, 5), (19, 3), (19, 6), (12, 6)), flat(c.l))
    sl = C(pick(rng, BRIGHTS))
    s.draw(P((22, 13), (29, 10), (30, 14), (24, 17)), bev(sl))
    s.draw(L(7, 22, 11, 27), flat(c.x), ol=False)
    s.draw(L(19, 24, 23, 21), flat(c.x), ol=False)


def sh_jeans(s, rng, name):
    c = C(pick(rng, ["denim", "navy", "sky", "black"]))
    m = P((7, 2), (24, 2), (27, 29), (18, 29), (15.5, 11), (13, 29), (4, 29))
    garment(s, c, m)
    s.rect(7, 2, 24, 4, c.d)
    s.rect(7, 2, 24, 2, c.l)
    s.draw(R(15, 3, 16, 3), flat(C("brass").l))
    s.rect(16, 5, 16, 11, c.x)
    for x in (9, 22):
        s.pts([(x, 5), (x + 1, 6), (x + 2, 7)] if x == 9 else [(x, 5), (x - 1, 6), (x - 2, 7)], C("gold").m)
    s.rect(4, 27, 13, 27, c.d)
    s.rect(18, 27, 27, 27, c.d)


def sh_trainers(s, rng, name):
    up = C(pick(rng, ["white", "red", "blue", "black", "grey", "navy", "green", "yellow"]))
    acc = C(contrast(rng, up.base, ["red", "blue", "navy", "green", "white", "gold", "black"]))
    m = P((3, 12), (12, 11), (16, 14), (25, 17), (29, 20), (29, 23), (3, 23))
    s.draw(m, bev(up))
    s.draw(R(2, 23, 30, 26), lambda x, y, m: C("white").l if y < 25 else C("white").d)
    s.rect(3, 24, 29, 24, C("grey").l)
    s.draw(P((7, 20), (22, 16), (25, 19), (9, 22)), flat(acc.m), ol=False)
    for (x, y) in [(13, 13), (15, 14), (17, 15), (19, 16)]:
        s.put(x, y, C("white").e if up.base != PAL["white"] else C("black").m)
    s.draw(R(3, 11, 7, 13), flat(acc.d))
    s.rect(3, 14, 3, 22, up.l)


def sh_boots(s, rng, name):
    c = C(pick(rng, ["forest", "black", "green", "navy", "red", "yellow"]))
    for dx, shade in ((6, 1), (0, 0)):
        m = P((5 + dx, 3), (15 + dx, 3), (15 + dx, 17), (24 + dx, 20), (25 + dx, 26), (4 + dx, 26))
        cc = c if shade == 0 else C(c.base)
        if shade:
            s.draw(m, flat(c.d))
        else:
            s.draw(m, cylx(c, 4, 15))
            s.rect(5, 3, 15, 5, c.l)
            s.rect(5, 5, 15, 5, c.d)
    s.draw(R(3, 26, 31, 28) - R(29, 26, 31, 26), flat(C("black").m))
    s.rect(4, 27, 30, 27, C("black").l)


def sh_hat(s, rng, name, witch=False):
    if witch:
        c = C(pick(rng, ["black", "purple", "plum"]))
        s.draw(P((13, 3), (19, 2), (24, 6), (21, 8), (22, 20), (9, 20)), lambda x, y, m: c.l if x < 13 else c.m)
        s.draw(E(15.5, 22, 14, 4), bev(c))
        s.draw(R(9, 17, 22, 19), flat(C(pick(rng, ["orange", "lime", "purple"])).m))
        s.draw(R(14, 17, 17, 19), flat(C("gold").l))
        s.rect(15, 18, 16, 18, OUT)
        return
    c = C(pick(rng, ["cream", "paper", "pine", "ivory"]))
    band = C(pick(rng, ["black", "navy", "wine", "brown"]))
    s.draw(E(15.5, 21, 14.5, 5.5), lambda x, y, m: c.d if y > 22 else c.m)
    s.draw(E(15.5, 12, 8.5, 7) & R(0, 0, 31, 19) | R(7, 12, 24, 19), lambda x, y, m: (c.e if x < 11 and y < 12 else c.l if x < 14 else c.m))
    s.fill(E(15.5, 6.5, 3, 1.2), c.d)
    s.rect(7, 16, 24, 18, band.m)
    s.rect(7, 16, 24, 16, band.l)
    for (x, y) in R(3, 19, 28, 25):
        if (x + y) % 4 == 0 and (x, y) in E(15.5, 21, 14.5, 5.5) - R(7, 12, 24, 19):
            s.put(x, y, c.d)


def sh_bag(s, rng, name, camera=False):
    c = C(pick(rng, ["leather", "tan", "brown", "wine", "black", "walnut"]) if not camera else pick(rng, ["black", "charcoal", "slate", "navy"]))
    s.draw(ring(15.5, 10, 8, 6, 7, 5) & R(0, 0, 31, 10), flat(C("walnut").d if not camera else C("black").m))
    s.draw(RR(3, 10, 28, 28, 2), bev(c))
    s.draw(P((3, 10), (28, 10), (28, 19), (26, 21), (5, 21), (3, 19)), lambda x, y, m: c.l if y < 12 else c.m)
    if camera:
        s.rect(4, 13, 27, 13, C("black").x)
        s.draw(R(12, 16, 19, 19), flat(C("red").m))
        s.rect(13, 17, 18, 17, C("white").l)
        s.draw(R(6, 23, 25, 26), flat(c.d), ol=False)
        return
    for x in (9, 21):
        s.draw(R(x, 13, x + 1, 25), flat(c.x))
        s.draw(R(x - 1, 20, x + 2, 22), flat(C("brass").l))
        s.put(x, 21, OUT)
    s.rect(4, 26, 27, 26, c.d)


def sh_scarf(s, rng, name):
    c = C(pick(rng, ["red", "navy", "teal", "pink", "gold", "purple", "green", "wine", "sky"]))
    c2 = C(contrast(rng, c.base, ["white", "gold", "cream", "navy", "pink"]))
    pat = rng.randrange(3)

    def f(x, y, m):
        if pat == 0 and (x + y) % 5 == 0:
            return c2.m
        if pat == 1 and (x * 2 + y * 3) % 9 == 0:
            return c2.l
        if pat == 2 and y % 5 == 0:
            return c2.m
        t = (x - 1, y) not in m or (x, y - 1) not in m
        b = (x + 1, y) not in m or (x, y + 1) not in m
        return c.l if t and not b else (c.d if b and not t else c.m)
    loop = ring(15.5, 9, 10, 6.5, 7, 3.8)
    s.draw(loop, f)
    s.draw(P((17, 14), (22, 13), (25, 27), (19, 28)), f)
    s.draw(P((8, 12), (14, 13), (13, 28), (7, 27)), f)
    for x in range(7, 14, 2):
        s.draw(R(x, 29, x, 30), flat(c.d), ol=False)
    for x in range(19, 26, 2):
        s.draw(R(x, 29, x, 30), flat(c.d), ol=False)


# ---------------------------------------------------------------- jewellery
def gem(s, cx, cy, r, g):
    s.draw(E(cx, cy, r), lambda x, y, m: g.e if (x < cx and y < cy) else (g.l if x < cx or y < cy else g.m))
    s.put(int(cx), int(cy), g.d)


def sh_ring(s, rng, name, kind="plain"):
    metal = C("gold" if kind != "silver" else "silver")
    if "silver" in name.lower():
        metal = C("silver")
    band = ring(15.5, 19.5, 10, 7.5, 9, 6.5)
    if kind == "plain":
        band = ring(15.5, 17, 11, 8, 11, 8)
    s.draw(band, lambda x, y, m: metal.e if (x < 12 and y < 16) else (metal.l if y < 18 and x < 15 else (metal.d if y > 22 else metal.m)))
    if kind == "plain":
        s.fill(ring(15.5, 17, 8.9, 8, 8.9, 8) & R(0, 0, 31, 17), metal.x)
        return
    if kind == "solitaire":
        s.draw(R(13, 9, 18, 12), flat(metal.d))
        s.draw(P((10, 5), (21, 5), (15.5, 11)), lambda x, y, m: C("diamond").e if x < 14 else (C("diamond").l if x < 17 else C("sky").l))
        s.draw(P((12, 2), (19, 2), (21, 5), (10, 5)), lambda x, y, m: C("diamond").e if x < 16 else C("diamond").l)
        s.pts([(24, 3), (25, 2), (25, 4), (26, 3)], C("white").e)
        return
    if kind == "signet":
        s.draw(E(15.5, 8, 7, 5), sph(metal, 15.5, 8, 7))
        s.fill(E(15.5, 8, 4, 2.6), metal.d)
        s.pts([(14, 7), (15, 8), (16, 8), (17, 7), (15, 9), (16, 9)], metal.l)
        return
    g = C(pick(rng, ["ruby", "sapphire", "emerald", "amethyst"]))
    s.draw(E(15.5, 9, 4), flat(metal.m))
    gem(s, 15.5, 9, 3, g)


def chain(s, pts, metal, step=1.0, bead=0):
    for i, (x, y) in enumerate(pts):
        if bead:
            s.draw(E(x, y, bead), sph(metal, x, y, bead))
        else:
            s.put(int(round(x)), int(round(y)), metal.l if i % 2 else metal.d)


def sh_necklace(s, rng, name, kind="chain"):
    metal = C("gold" if kind in ("chain", "coin") else "silver")
    if kind == "pearl":
        metal = C("pearl")
    if "silver" in name.lower():
        metal = C("silver")
    if kind == "lot":
        metal = C("silver")
    cx, cy, rx, ry = 15.5, 6, 12, 17
    pts = []
    n = 24 if kind != "pearl" else 13
    for i in range(n + 1):
        a = math.pi * i / n
        pts.append((cx + rx * math.cos(a), cy + ry * math.sin(a) * 0.9))
    if kind == "pearl":
        for (x, y) in pts:
            s.draw(E(round(x), round(y), 1.6), sph(metal, round(x), round(y), 1.6))
        s.draw(E(15.5, 23.5, 2.3), sph(metal, 15.5, 23.5, 2.3))
        return
    thick = 1.8 if kind == "chain" else 1.2
    s.draw(PL([(round(x), round(y)) for (x, y) in pts], thick), lambda x, y, m: metal.l if (x + y) % 2 else metal.d)
    if kind == "coin":
        s.draw(E(15.5, 24, 5.5), sph(C("gold"), 15.5, 24, 5.5))
        s.fill(ring(15.5, 24, 4.2, 3.4), C("gold").d)
        s.fill(E(15, 23.5, 1.6, 2), C("gold").d)
    elif kind == "locket":
        s.draw(E(15.5, 24, 4.5, 5.5), sph(metal, 15.5, 24, 5))
        s.fill(ring(15.5, 24, 3.3, 2.6, 4.3, 3.6), metal.d)
        s.put(15, 18, OUT)
    elif kind == "lot":
        s.draw(ring(21, 23, 6, 4), sph(C("silver"), 21, 23, 6))
        s.draw(E(12, 25, 2.5), flat(C("sapphire").l))
    else:
        s.draw(E(15.5, 22, 2.2, 2.6), sph(metal, 15.5, 22, 2.2))


def sh_bracelet(s, rng, name):
    metal = C("silver")
    pts = [(15.5 + 11 * math.cos(a), 13 + 8 * math.sin(a)) for a in [i * math.pi / 14 for i in range(29)]]
    s.draw(PL([(round(x), round(y)) for (x, y) in pts], 1.6), lambda x, y, m: metal.l if (x + y) % 2 else metal.d)
    for (a, kind) in [(0.3, "heart"), (0.9, "star"), (1.5, "disc"), (2.1, "heart"), (2.7, "bell")]:
        x, y = 15.5 + 11 * math.cos(a), 13 + 8 * math.sin(a) + 3
        x, y = round(x), round(y)
        s.draw(L(x, y - 3, x, y - 2), flat(metal.d), ol=False)
        if kind == "heart":
            s.draw(E(x - 1, y, 1.2) | E(x + 1, y, 1.2) | P((x - 2, y + 1), (x + 2, y + 1), (x, y + 3)), flat(C("pink").l))
        elif kind == "star":
            s.draw(star5(x, y + 1, 2.8), flat(C("gold").l))
        elif kind == "disc":
            s.draw(E(x, y + 1, 2), sph(metal, x, y + 1, 2))
        else:
            s.draw(P((x - 1, y), (x + 1, y), (x + 2, y + 3), (x - 2, y + 3)), flat(C("gold").m))


def sh_watch(s, rng, name, kind="classic"):
    if kind == "digital":
        strap = C(pick(rng, ["black", "charcoal", "silver"]))
        s.draw(R(11, 0, 20, 8) | R(11, 23, 20, 31), lambda x, y, m: strap.d if y % 3 == 0 else strap.m)
        case = C(pick(rng, ["silver", "gold", "black"]))
        s.draw(RR(6, 7, 25, 24, 2), bev(case))
        s.draw(R(9, 11, 22, 19), flat(C("lcd").d))
        s.rect(10, 12, 21, 18, C("lcd").l)
        for x in (11, 14, 17, 20):
            s.rect(x, 14, x + 1, 17, C("black").m)
            s.put(x, 15, C("lcd").l)
        s.rect(12, 21, 19, 21, case.d)
        s.pts([(4, 11), (4, 20), (27, 11), (27, 20)], case.d)
        return
    if kind == "pocket":
        case = C(pick(rng, ["gold", "silver", "brass"]))
        s.draw(PL([(15, 6), (10, 4), (5, 7), (3, 13), (4, 21)], 1.2), lambda x, y, m: case.l if (x + y) % 2 else case.d)
        s.draw(ring(15.5, 3.5, 2.8, 1.4), flat(case.m))
        s.draw(R(14, 5, 17, 7), flat(case.m))
        s.draw(E(15.5, 18.5, 11.2), sph(case, 15.5, 18.5, 11.2))
        s.draw(E(15.5, 18.5, 8.8), flat(C("ivory").l))
        for a in range(0, 360, 30):
            s.put(int(round(15.5 + 7.5 * math.cos(math.radians(a)))), int(round(18.5 + 7.5 * math.sin(math.radians(a)))), C("black").m)
        s.fill(L(15.5, 18.5, 15.5, 12.5), OUT)
        s.fill(L(15.5, 18.5, 20, 20.5), OUT)
        return
    strap = C(pick(rng, ["leather", "brown", "black", "tan", "silver"]) if kind != "steel" else "silver")
    if kind == "fashion":
        strap = C(pick(rng, ["pink", "white", "red", "sky", "black", "gold"]))
    s.draw(R(11, 0, 20, 9) | R(11, 22, 20, 31), lambda x, y, m: strap.d if (y % 3 == 0 and strap.base in (PAL["silver"], PAL["gold"])) else (strap.l if x == 11 else strap.m))
    s.pts([(15, 26), (16, 26), (15, 29), (16, 29)], strap.x)
    case = C(pick(rng, ["gold", "silver", "chrome"]) if kind != "steel" else "chrome")
    s.draw(R(26, 14, 27, 17), flat(case.m))
    s.draw(E(15.5, 15.5, 9), sph(case, 15.5, 15.5, 9))
    dial = C(pick(rng, ["ivory", "white", "navy", "black", "sky"]))
    s.draw(E(15.5, 15.5, 6.8), flat(dial.m), ol=True)
    tick = C("black").m if dial.base in (PAL["ivory"], PAL["white"], PAL["sky"]) else C("white").l
    for a in range(0, 360, 90):
        s.put(int(round(15.5 + 5.5 * math.cos(math.radians(a)))), int(round(15.5 + 5.5 * math.sin(math.radians(a)))), tick)
    s.fill(L(15.5, 15.5, 15.5, 10.5), tick)
    s.fill(L(15.5, 15.5, 19, 17), tick)
    s.put(12, 12, dial.e)


def sh_brooch(s, rng, name, kind="gem"):
    metal = C("gold" if kind != "silver" else "silver")
    if kind == "jet":
        s.draw(E(15.5, 15.5, 11, 13), sph(metal, 15.5, 15.5, 12))
        for a in range(0, 360, 30):
            s.put(int(round(15.5 + 10 * math.cos(math.radians(a)))), int(round(15.5 + 12 * math.sin(math.radians(a)))), metal.x)
        s.draw(E(15.5, 15.5, 7.5, 9.5), sph(C("jet"), 15.5, 15.5, 8.5))
        s.fill(E(15.5, 15.5, 3, 4) - E(15.5, 15.5, 2, 3), metal.d)
        return
    if kind == "festive":
        s.draw(E(11, 13, 6, 3.5), flat(C("green").m))
        s.draw(E(21, 13, 6, 3.5), flat(C("green").m))
        s.rect(6, 13, 26, 13, C("green").d)
        for (x, y) in ((13, 19), (18, 19), (15.5, 16)):
            s.draw(E(x, y, 3), sph(C("red"), x, y, 3))
        return
    g = C(pick(rng, ["ruby", "sapphire", "emerald", "amethyst", "diamond"]))
    for a in range(0, 360, 45):
        x, y = 15.5 + 9 * math.cos(math.radians(a)), 15.5 + 9 * math.sin(math.radians(a))
        s.draw(E(round(x), round(y), 3), sph(metal, round(x), round(y), 3))
        s.put(round(x), round(y), C("diamond").e)
    s.draw(E(15.5, 15.5, 7), sph(metal, 15.5, 15.5, 7))
    gem(s, 15.5, 15.5, 4.8, g)


def sh_earrings(s, rng, name):
    metal = C("gold" if "silver" not in name.lower() else "silver")
    for cx in (9, 22):
        s.draw(ring(cx, 19, 7.5, 5.5), lambda x, y, m, c=cx: metal.e if (x < c - 3 and y < 17) else (metal.l if y < 19 else metal.d))
        s.draw(PL([(cx, 11), (cx + 1, 8), (cx + 3, 7)], 1), flat(metal.d))


def sh_cufflinks(s, rng, name):
    metal = C(pick(rng, ["silver", "gold", "chrome"]))
    g = C(pick(rng, ["jet", "sapphire", "ruby", "emerald", "pearl"]))
    for (cx, cy) in ((10, 11), (21, 20)):
        s.draw(R(cx - 1, cy + 4, cx + 1, cy + 7), flat(metal.d))
        s.draw(RR(cx - 3, cy + 7, cx + 4, cy + 8, 1), flat(metal.m))
        s.draw(RR(cx - 6, cy - 5, cx + 6, cy + 4, 2), sph(metal, cx, cy, 6))
        s.draw(RR(cx - 4, cy - 3, cx + 4, cy + 2, 1), lambda x, y, m: g.l if x + y < 2 * cx - 2 else g.m)


def sh_tiara(s, rng, name):
    metal = C("silver")
    peaks = [(4, 15), (9, 9), (15.5, 3), (22, 9), (27, 15)]
    m = PL([(2, 24), (8, 21), (15.5, 20), (23, 21), (29, 24)], 2.5)
    for (px, py) in peaks:
        m |= P((px - 3, 22), (px, py), (px + 3, 22))
    s.draw(m, lambda x, y, m: metal.l if (x + y) % 3 else metal.d)
    for (px, py) in peaks:
        s.draw(E(px, py + 3, 1.3), flat(C("diamond").e))
    s.draw(E(15.5, 13, 2), flat(C(pick(rng, ["sapphire", "ruby", "diamond", "amethyst"])).l))
    for x in range(5, 27, 3):
        s.put(x, 21 + (1 if abs(x - 15.5) > 8 else 0), C("white").e)


def sh_coin(s, rng, name, lot=False):
    metal = C("silver" if "silver" in name.lower() else pick(rng, ["gold", "silver", "copper", "bronze", "gold"]))

    def coin(cx, cy, r, mt):
        s.draw(E(cx, cy, r), sph(mt, cx, cy, r, spec=False))
        for (x, y) in ring(cx, cy, r + 0.2, r - 0.9):
            a = math.atan2(y - cy, x - cx)
            s.put(x, y, mt.d if int(a * 6) % 2 else mt.m)
        inner = E(cx, cy, r - 2.6)
        s.fill(ring(cx, cy, r - 1.8, r - 2.6), mt.d)
        hr = r * 0.30
        bust = (E(cx - 0.5, cy - hr * 0.5, hr, hr * 1.15) | E(cx, cy + hr * 1.9, hr * 1.9, hr * 1.1)
                | R(int(cx - hr * 0.5), int(cy + hr * 0.3), int(cx + hr * 0.4), int(cy + hr * 1.2)) | {(int(round(cx + hr + 0.3)), int(round(cy - hr * 0.3)))})
        bust &= inner
        s.fill(bust, mt.d)
        s.fill({(x, y) for (x, y) in bust if (x - 1, y) not in bust or (x, y - 1) not in bust}, mt.e)
    if lot:
        others = [C(n) for n in picks(rng, ["gold", "silver", "copper", "bronze"], 2)]
        mt = others[0]
        for i in range(5):
            y = 24 - i * 3
            s.draw(R(15, y - 1, 29, y + 1) | E(22, y + 1, 7, 2.2), lambda x, yy, m: mt.d if (x % 2 == 0) else (mt.l if x < 19 else mt.m))
            s.draw(E(22, y - 1, 7, 2.2), flat(mt.l if i == 4 else mt.m), ol=(i == 4))
        s.fill(E(21, 11, 3, 0.8), mt.e)
        coin(10.5, 19.5, 9, metal)
        return
    coin(15.5, 15.5, 13.2, metal)


def sh_note(s, rng, name):
    c = C(pick(rng, ["mint", "sky", "pink", "amber", "violet", "lime"]))
    s.draw(R(3, 9, 30, 25), flat(c.d))
    s.draw(R(1, 6, 28, 22), bev(c))
    s.fill(ring(20, 14, 5.5, 4.5, 6.5, 5.5), c.x)
    s.fill(E(20, 14, 4.5, 5.5), c.l)
    s.fill(E(20.5, 13, 2, 2.5), c.d)
    s.fill(P((17, 19), (19, 16), (22, 16), (24, 19)), c.d)
    s.rect(3, 8, 7, 9, c.x)
    s.rect(3, 19, 12, 19, c.x)
    s.rect(3, 12, 11, 12, c.d)
    s.rect(3, 14, 9, 14, c.d)
    s.pts([(26, 8), (26, 20)], c.x)


def sh_medal(s, rng, name, group=False):
    positions = [(7, "bronze"), (15.5, "silver"), (24, "gold")] if group else [(15.5, pick(rng, ["bronze", "silver", "gold"]))]
    for cx, metal in positions:
        cols = picks(rng, ["red", "navy", "yellow", "green", "white", "purple", "sky", "crimson"], 3)
        w = 3 if group else 5
        x0, x1 = int(cx - w), int(cx + w)
        ribbon = R(x0, 2, x1, 14 if group else 12)

        def rf(x, y, m, x0=x0, cols=cols, w=w):
            k = (x - x0) * 3 // (2 * w + 1)
            return C(cols[min(2, k)]).m if y > 2 else C(cols[min(2, k)]).l
        s.draw(ribbon, rf)
        s.draw(R(x0 - 1, 1, x1 + 1, 2), flat(C("brass").m))
        mt = C(metal)
        r = 3.8 if group else 7
        cy = 20 if group else 20.5
        s.draw(R(int(cx) - 1, 14 if group else 12, int(cx) + 1, int(cy - r)), flat(mt.d))
        if group and metal == "silver" or (not group and rng.random() < 0.4):
            s.draw(star5(cx, cy, r + 1.6), flat(mt.m))
            s.fill(star5(cx, cy, r * 0.6), mt.l)
        else:
            s.draw(E(cx, cy, r), sph(mt, cx, cy, r))
            s.fill(ring(cx, cy, r - 1, r - 1.8), mt.d)


def sh_drawers(s, rng, name, kind="toolchest"):
    if kind == "toolchest":
        c = C(pick(rng, ["red", "walnut", "oak", "black", "blue"]))
        s.draw(P((3, 7), (28, 7), (29, 10), (2, 10)), flat(c.l))
        s.draw(R(2, 10, 29, 29), bev(c))
        for i, y in enumerate(range(12, 28, 4)):
            s.draw(R(4, y, 27, y + 2), flat(c.m if c.base in (PAL["red"], PAL["blue"], PAL["black"]) else c.d))
            s.draw(R(13, y + 1, 18, y + 1), flat(C("chrome").l), ol=False)
        s.draw(R(11, 4, 20, 6), flat(C("chrome").m))
        return
    # jewellery armoire
    c = C(pick(rng, ["walnut", "mahogany", "white", "black", "oak"]))
    s.draw(E(15.5, 6, 9, 4) & R(0, 0, 31, 7) | R(6.5, 6, 24.5, 8), bev(c))
    s.draw(R(6, 4, 25, 7) & E(15.5, 6, 8, 3), flat(C("glass").l), ol=False)
    s.draw(R(6, 8, 25, 28), bev(c))
    for y in range(10, 27, 4):
        s.draw(R(8, y, 23, y + 2), flat(c.d))
        s.put(15, y + 1, C("brass").l)
        s.put(16, y + 1, C("brass").l)
    s.draw(R(7, 28, 9, 30), flat(c.d))
    s.draw(R(22, 28, 24, 30), flat(c.d))


# ---------------------------------------------------------------- tools
WOOD_HANDLE = "pine"


def sh_hammer(s, rng, name):
    wood = C(pick(rng, ["pine", "oak", "tan"]))
    s.draw(L(6, 27, 19, 14, 3.2), lambda x, y, m: wood.l if (x - y) < -13 else wood.m)
    s.draw(L(4, 29, 9, 24, 3.6), flat(C(pick(rng, ["black", "red", "blue"])).m))
    steel = C("steel")
    head = L(15, 7, 26, 18, 5)
    s.draw(head, lambda x, y, m: steel.l if (x - y) > 9 else (steel.d if (x - y) < 7 else steel.m))
    s.draw(P((12, 3), (17, 8), (13, 10), (10, 5)), flat(steel.m))
    s.fill(L(13, 5, 15, 7), OUT)


def sh_drill(s, rng, name):
    c = C(pick(rng, ["yellow", "teal", "red", "orange", "blue", "green", "lime"]))
    blk = C("black")
    s.draw(P((10, 15), (17, 15), (15, 24), (9, 24)), bev(blk))
    s.draw(RR(4, 25, 18, 29, 1), bev(c))
    s.draw(RR(3, 6, 23, 16, 2), bev(c))
    s.draw(R(5, 8, 9, 14), flat(blk.m), ol=False)
    s.draw(R(23, 8, 27, 14), cyly(blk, 8, 14))
    s.draw(R(28, 9, 29, 13), cyly(C("chrome"), 9, 13))
    s.draw(L(30, 11, 31, 11), flat(C("steel").l), ol=False)
    s.draw(R(16, 16, 17, 18), flat(C("red").m))
    s.rect(12, 26, 16, 26, blk.m)


def sh_saw(s, rng, name):
    steel = C("steel")
    blade = P((10, 7), (29, 16), (29, 20), (10, 22))
    s.draw(blade, lambda x, y, m: steel.l if y < 11 + (x - 10) * 0.4 else steel.m)
    for x in range(11, 30, 2):
        s.put(x, 23 - int((x - 10) * 0.12), OUT)
    s.rect(14, 12, 24, 12, steel.e) if False else None
    wood = C(pick(rng, ["walnut", "teak", "oak", "mahogany"]))
    s.draw(RR(2, 5, 12, 24, 3), bev(wood))
    s.draw(RR(5, 9, 9, 18, 1), flat(OUT), ol=False)
    s.draw(E(11, 11, 0.8), flat(C("brass").l), ol=False)
    s.draw(E(11, 18, 0.8), flat(C("brass").l), ol=False)
    s.put(20, 15, steel.d)


def sh_circsaw(s, rng, name):
    c = C(pick(rng, ["yellow", "teal", "red", "blue", "orange", "green"]))
    s.draw(E(12, 18, 10), lambda x, y, m: C("steel").l if (x + y) % 4 == 0 else C("steel").m)
    for a in range(0, 360, 20):
        s.put(int(round(12 + 10.6 * math.cos(math.radians(a)))), int(round(18 + 10.6 * math.sin(math.radians(a)))), OUT)
    s.draw(E(12, 18, 10.5) & R(0, 0, 31, 18), cylx(c, 1, 22))
    s.draw(E(12, 18, 2.2), sph(C("chrome"), 12, 18, 2.2))
    s.draw(RR(16, 9, 29, 20, 2), bev(C("black")))
    s.draw(PL([(18, 9), (21, 3), (28, 3), (29, 9)], 2.2), flat(c.m))
    s.draw(R(3, 26, 29, 28), flat(C("steel").d))
    for y in range(12, 19, 2):
        s.rect(22, y, 27, y, C("black").l)


def sh_grinder(s, rng, name):
    c = C(pick(rng, ["teal", "yellow", "red", "blue", "orange", "green"]))
    s.draw(L(21, 8, 27, 2, 2.6), flat(C("black").m))
    s.draw(RR(2, 10, 19, 19, 3), cyly(c, 10, 19, spec=True))
    for x in range(5, 12, 2):
        s.rect(x, 12, x, 17, C("black").m)
    s.draw(RR(2, 10, 5, 19, 1), flat(C("black").m))
    s.draw(RR(18, 8, 26, 18, 1), bev(C("charcoal")))
    guard = (E(22, 21, 8.5, 4.5) & R(0, 0, 31, 21)) - E(22, 21, 7, 3)
    s.draw(E(22, 22, 8, 1.3), flat(C("steel").l))
    s.draw(guard, flat(C("steel").d))
    s.draw(R(21, 18, 23, 21), flat(C("steel").m))


def sh_benchgrinder(s, rng, name):
    c = C(pick(rng, ["grey", "green", "blue", "red", "slate"]))
    s.draw(R(4, 26, 27, 29), bev(C("steel")))
    s.draw(P((12, 25), (19, 25), (21, 27), (10, 27)), flat(c.d))
    s.draw(RR(9, 11, 22, 25, 3), cylx(c, 9, 22, spec=True))
    for (x0, x1) in ((1, 9), (22, 30)):
        s.draw(E((x0 + x1) / 2.0, 16, 4.5, 8.5), lambda x, y, m: C("stone").l if y < 13 else (C("stone").m if y < 20 else C("stone").d))
        s.draw(ring((x0 + x1) / 2.0, 16, 5.5, 4.4, 9.5, 8.5) & R(0, 0, 31, 13), flat(c.m))
    s.put(15, 22, C("red").m)


def sh_router(s, rng, name):
    c = C(pick(rng, ["blue", "teal", "green", "yellow", "red"]))
    s.draw(E(15.5, 27, 13, 3), flat(C("steel").d))
    s.draw(R(8, 18, 23, 25), cylx(C("steel"), 8, 23))
    for cx in (4, 27):
        s.draw(E(cx, 17, 3, 3.5), sph(C("black"), cx, 17, 3.5))
    s.draw(R(6, 16, 25, 18), flat(C("black").m))
    s.draw(RR(9, 3, 22, 17, 2), cylx(c, 9, 22, spec=True))
    s.draw(E(15.5, 3, 6.5, 2), flat(c.l))
    for y in range(6, 15, 2):
        s.rect(12, y, 19, y, c.d)


def sh_jack(s, rng, name):
    c = C(pick(rng, ["red", "red", "blue", "black", "orange"]))
    s.draw(L(19, 17, 29, 4, 2.2), flat(C("steel").m))
    s.draw(R(27, 2, 30, 4), flat(C("black").m))
    s.draw(P((2, 20), (22, 18), (24, 24), (2, 25)), bev(c))
    s.draw(L(6, 19, 11, 9, 3.5), flat(c.d))
    s.draw(R(8, 7, 14, 9), flat(C("steel").m))
    for x in (5, 20):
        s.draw(E(x, 26, 2.8), sph(C("black"), x, 26, 2.8))
        s.put(x, 26, C("chrome").l)
    s.draw(R(17, 14, 22, 18), cylx(C("chrome"), 17, 22))


def sh_toolbox(s, rng, name, tackle=False):
    c = C(pick(rng, ["red", "red", "blue", "grey", "green"]) if not tackle else pick(rng, ["green", "forest", "olive", "grey"]))
    s.draw(PL([(9, 11), (9, 5), (22, 5), (22, 11)], 2.2), flat(C("black").m))
    if tackle:
        s.draw(R(2, 8, 13, 12), flat(c.l))
        s.draw(R(18, 8, 29, 12), flat(c.l))
        for x in range(4, 12, 3):
            s.put(x, 10, C(pick(rng, ["red", "yellow", "orange"])).l)
    s.draw(R(2, 11, 29, 16), bev(c))
    s.draw(R(2, 17, 29, 29), bev(c))
    s.rect(3, 17, 28, 17, c.d)
    s.draw(R(6, 15, 8, 19), flat(C("chrome").l))
    s.draw(R(23, 15, 25, 19), flat(C("chrome").l))
    s.rect(3, 28, 28, 28, c.d)


def sh_sockets(s, rng, name):
    case = C(pick(rng, ["blue", "black", "red", "grey"]))
    s.draw(RR(1, 5, 30, 27, 1), bev(case))
    s.draw(R(3, 7, 28, 25), flat(case.x))
    chrome = C("chrome")
    for i, r in enumerate([1.6, 1.9, 2.2, 2.5, 2.8]):
        x = 5 + i * 5 + (i * 0.4)
        s.draw(E(x, 11, r), sph(chrome, x, 11, r, spec=False))
        s.fill(E(x, 11, r * 0.45), OUT)
    s.draw(L(5, 20, 20, 20, 2.4), cyly(chrome, 19, 21))
    s.draw(E(22, 20, 3), sph(chrome, 22, 20, 3))
    s.draw(R(25, 15, 27, 23), flat(chrome.d))


def sh_toolroll(s, rng, name, kind="spanners"):
    canvas = C(pick(rng, ["khaki", "olive", "tan", "leather", "brown"]))
    s.draw(R(1, 6, 30, 28), lambda x, y, m: canvas.d if y > 18 and (x % 5 == 4) else (canvas.l if y < 8 else canvas.m))
    s.draw(R(1, 18, 30, 28), flat(canvas.d), ol=False)
    for x in range(5, 30, 5):
        s.rect(x, 18, x, 28, canvas.x)
    s.rect(1, 18, 30, 18, canvas.x)
    for i in range(5):
        x = 3 + i * 5
        if kind == "spanners":
            steel = C("chrome")
            top = 4 + i
            s.draw(R(x, top + 2, x + 1, 24), cylx(steel, x, x + 1))
            s.draw(E(x + 0.5, top + 1.5, 2.2), flat(steel.m))
            s.fill(R(x, top - 1, x + 1, top + 1), OUT)
        else:
            steel = C("steel")
            wood = C(pick(rng, ["pine", "oak", "tan"]))
            top = 3 + i
            s.draw(R(x, top, x + 1, top + 4), flat(steel.l))
            s.draw(R(x - 1 if i > 0 else x, top + 5, x + 1, top + 5), flat(steel.m))
            s.draw(RR(x - 1, top + 6, x + 2, 25, 1), cylx(wood, x - 1, x + 2))
    for x in range(1, 31):
        pass
    s.draw(R(29, 10, 31, 12), flat(C("leather").d))


def sh_plane(s, rng, name, wooden=False):
    if wooden:
        wood = C(pick(rng, ["pine", "oak", "teak"]))
        s.draw(P((12, 3), (17, 3), (16, 16), (12, 16)), lambda x, y, m: wood.d if x > 13 else wood.m)
        s.draw(P((2, 12), (4, 10), (27, 10), (29, 12), (29, 23), (2, 23)), bev(wood))
        s.draw(P((12, 10), (17, 10), (16, 17), (12, 17)), flat(wood.x))
        s.draw(P((16, 7), (18, 7), (17, 23), (16, 23)), flat(C("steel").l))
        prof = [24, 25, 25, 24, 24, 25, 26, 26, 25, 24]
        for x in range(2, 30):
            s.rect(x, 24, x, prof[(x - 2) % len(prof)], wood.d)
        for x in range(2, 30):
            s.put(x, prof[(x - 2) % len(prof)] + 1, OUT)
        s.rect(4, 13, 10, 13, wood.l)
        s.rect(20, 13, 27, 13, wood.l)
        s.pts([(6, 18), (25, 18)], wood.x)
        return
    body = C(pick(rng, ["navy", "black", "blue", "wine", "green"]))
    wood = C(pick(rng, ["mahogany", "teak", "walnut"]))
    steel = C("steel")
    s.draw(E(7, 13.5, 2.6, 3.5), sph(wood, 7, 13.5, 3))
    s.draw(P((19, 18), (20, 9), (22, 6), (27, 6), (27, 9), (25, 18)), bev(wood))
    s.fill(P((22, 9), (24, 9), (23, 14), (22, 14)), OUT)
    s.draw(P((10, 19), (13, 7), (16, 7), (15, 19)), lambda x, y, m: C("chrome").l if x < 14 else C("chrome").m)
    s.draw(E(15, 6, 1.6), flat(C("brass").l))
    s.draw(P((3, 23), (6, 18), (26, 18), (29, 23)), bev(body))
    s.draw(R(2, 23, 29, 26), bev(steel))
    s.fill(R(3, 20, 28, 20) & P((3, 23), (6, 18), (26, 18), (29, 23)), body.l)


def sh_level(s, rng, name):
    wood = C("pine")
    s.draw(R(4, 3, 8, 29) | R(4, 25, 16, 29), bev(wood))
    s.draw(R(8, 2, 26, 4), flat(C("chrome").m))
    s.rect(9, 2, 26, 2, C("chrome").l)
    for x in range(10, 26, 2):
        s.put(x, 4, C("chrome").x)
    c = C(pick(rng, ["yellow", "red", "blue", "silver", "orange"]))
    s.draw(R(1, 13, 30, 19), bev(c))
    s.draw(R(12, 14, 19, 18), flat(C("black").m))
    s.draw(R(13, 15, 18, 17), flat(C("lime").l), ol=False)
    s.draw(E(15.5, 16, 1.2, 0.8), flat(C("white").e), ol=False)
    s.rect(2, 19, 29, 19, c.d)
    for x in (4, 26):
        s.fill(E(x, 16, 1.2), C("black").m)


def sh_micrometer(s, rng, name):
    frame = C(pick(rng, ["chrome", "steel", "blue"]))
    s.draw(ring(12, 16, 9, 6, 11, 7) & R(0, 0, 13, 31), cylx(frame, 3, 12))
    s.draw(R(12, 5, 14, 8), flat(frame.m))
    s.draw(R(12, 24, 14, 27), flat(frame.m))
    s.draw(E(6, 16, 1.5), flat(C("brass").l))
    s.draw(R(14, 5, 18, 8), cyly(C("chrome"), 5, 8))
    s.draw(R(18, 4, 25, 9), cyly(C("chrome"), 4, 9, spec=True))
    for x in range(19, 25, 2):
        s.put(x, 8, C("black").m)
    s.draw(R(25, 5, 29, 8), cyly(C("steel"), 5, 8))
    s.draw(R(14, 25, 18, 26), flat(C("steel").l))


def sh_vice(s, rng, name):
    c = C(pick(rng, ["blue", "grey", "green", "red", "slate"]))
    s.draw(R(3, 25, 28, 29), bev(c))
    s.draw(R(4, 12, 13, 25), bev(c))
    s.draw(R(18, 12, 26, 25), bev(c))
    s.draw(R(2, 8, 14, 12), flat(C("steel").m))
    s.draw(R(17, 8, 27, 12), flat(C("steel").m))
    for x in range(3, 14, 2):
        s.put(x, 9, C("steel").x)
    for x in range(18, 27, 2):
        s.put(x, 9, C("steel").x)
    s.draw(R(13, 17, 29, 18), cyly(C("chrome"), 17, 18))
    s.draw(L(29, 11, 29, 24, 1.5), flat(C("chrome").l))
    s.draw(E(29, 10, 1.5), flat(C("chrome").m))
    s.draw(E(29, 25, 1.5), flat(C("chrome").m))


def sh_anvil(s, rng, name):
    c = C(pick(rng, ["charcoal", "slate", "black"]))
    m = P((1, 9), (9, 8), (29, 8), (29, 14), (22, 15), (20, 20), (26, 24), (26, 28), (5, 28), (5, 24), (11, 20), (9, 15), (7, 13), (3, 11))
    s.draw(m, lambda x, y, m: c.e if y == 8 and x > 8 else (c.l if y < 11 else (c.d if y > 25 else c.m)))
    s.rect(9, 9, 28, 9, c.l)
    s.put(26, 10, OUT)
    s.put(25, 10, OUT)


def sh_axe(s, rng, name):
    wood = C(pick(rng, ["pine", "oak", "tan"]))
    s.draw(L(5, 29, 20, 5, 2.8), lambda x, y, m: wood.l if (x * 1.6 + y) < 36 else wood.m)
    head = C(pick(rng, ["steel", "red", "black"]))
    s.draw(P((14, 5), (22, 4), (29, 1), (30, 14), (24, 11), (16, 12)), lambda x, y, m: C("chrome").e if x > 27 else (head.l if y < 7 else head.m))
    s.rect(28, 3, 28, 11, C("chrome").l)


def sh_brace(s, rng, name):
    steel = C("chrome")
    s.draw(PL([(9, 5), (9, 10), (21, 10), (21, 21), (9, 21), (9, 27)], 1.8), flat(steel.m))
    s.draw(E(9, 4, 4, 2.5), sph(C(pick(rng, ["walnut", "mahogany", "oak"])), 9, 4, 4))
    s.draw(R(20, 12, 23, 19), cylx(C(pick(rng, ["walnut", "oak", "mahogany"])), 20, 23))
    s.draw(R(7, 25, 11, 29), cylx(steel, 7, 11))
    for x in (26, 28):
        s.draw(L(x, 13, x, 29, 1), flat(C("steel").l))
        s.draw(E(x, 12, 0.8), flat(C("steel").m))


def sh_steamer(s, rng, name):
    c = C(pick(rng, ["orange", "yellow", "green", "blue", "red"]))
    s.draw(RR(2, 14, 14, 29, 2), cylx(c, 2, 14, spec=True))
    s.draw(R(6, 11, 9, 14), flat(C("black").m))
    s.draw(PL([(12, 16), (18, 12), (22, 16), (22, 20)], 1.6), flat(C("black").l))
    s.draw(R(16, 20, 29, 27), bev(C("grey")))
    s.draw(R(20, 17, 25, 20), flat(C("black").m))
    for x in range(17, 29, 3):
        s.put(x, 27, OUT)


def sh_gardentools(s, rng, name):
    wood = C(pick(rng, ["pine", "oak", "tan"]))
    steel = C(pick(rng, ["steel", "chrome", "galv"]))
    # fork: top-left to bottom-right
    s.draw(L(6, 4, 19, 17, 2.2), flat(wood.m))
    s.draw(R(3, 1, 8, 3) - {(3, 1), (8, 1)}, flat(C("black").m))
    s.draw(L(17, 22, 22, 17, 2), flat(steel.m))
    for k in range(4):
        x0, y0 = 17 + k * 1.6, 22 - k * 1.6
        s.draw(L(x0, y0, x0 + 6, y0 + 6), flat(steel.l))
    # spade: top-right to bottom-left
    s.draw(L(26, 4, 12, 18, 2.2), flat(wood.l))
    s.draw(R(24, 1, 29, 3) - {(24, 1), (29, 1)}, flat(C("black").m))
    s.draw(P((10, 17), (15, 22), (8, 29), (3, 24)), lambda x, y, m: steel.l if x + y < 28 else steel.m)
    s.fill(L(10, 18, 14, 22), steel.d)


def sh_wheelbarrow(s, rng, name):
    c = C(pick(rng, ["green", "galv", "red", "orange", "forest"]))
    s.draw(L(18, 19, 30, 13, 2), flat(C("walnut").m))
    s.draw(L(22, 21, 24, 29, 1.6), flat(C("black").m))
    s.draw(E(6, 24, 5), sph(C("black"), 6, 24, 5, spec=False))
    s.fill(E(6, 24, 2), C("chrome").l)
    s.draw(P((2, 11), (26, 11), (22, 21), (8, 21)), lambda x, y, m: c.l if y < 13 else (c.m if y < 18 else c.d))
    s.rect(3, 11, 25, 12, c.e)


def sh_stove(s, rng, name):
    c = C(pick(rng, ["blue", "red", "sky", "navy"]))
    s.draw(E(15.5, 27, 8, 2.5) | R(7, 16, 24, 27), cylx(c, 7, 24, spec=True))
    s.draw(E(15.5, 16, 8, 2.5), flat(c.l))
    s.draw(R(13, 10, 18, 15), cylx(C("chrome"), 13, 18))
    for (x0, x1) in ((6, 13), (18, 25)):
        s.draw(L(x0, 8, x1, 8, 1.5), flat(C("steel").m))
    s.draw(P((12, 9), (15.5, 1), (19, 9)), lambda x, y, m: C("sky").e if y > 5 else C("blue").l)
    s.fill(P((14, 9), (15.5, 5), (17, 9)), C("white").e)
    s.fill(R(9, 20, 22, 23), C("white").l)
    s.rect(10, 21, 19, 21, c.m)


def sh_rod(s, rng, name):
    rod = C(pick(rng, ["black", "navy", "forest", "wine"]))
    s.draw(L(3, 29, 9, 22, 3), flat(C("cork").m))
    s.draw(L(9, 22, 28, 3, 1.5), flat(rod.m))
    s.draw(E(12, 23, 3), sph(C("chrome"), 12, 23, 3))
    for t in (0.3, 0.55, 0.8):
        s.put(int(9 + 19 * t) + 1, int(22 - 19 * t) + 1, C("chrome").l)
    s.fill(L(28, 3, 29, 14), C("white").l)
    s.draw(E(29, 16, 1.3, 2), lambda x, y, m: C("red").m if y < 16 else C("white").l)


def sh_fishreel(s, rng, name):
    c = C(pick(rng, ["black", "gold", "silver", "brass", "forest"]))
    s.draw(R(4, 26, 26, 28), flat(C("chrome").d))
    s.draw(R(13, 22, 17, 26), flat(C("chrome").m))
    s.draw(E(15.5, 14, 11), sph(c, 15.5, 14, 11))
    s.fill(ring(15.5, 14, 9.5, 8.5), c.d)
    s.draw(E(15.5, 14, 3), sph(C("chrome"), 15.5, 14, 3))
    s.draw(L(15.5, 14, 23, 7, 1.6), flat(C("chrome").l))
    s.draw(E(23, 7, 2), sph(C("ivory"), 23, 7, 2))
    s.fill(ring(15.5, 14, 7, 6) & R(0, 16, 31, 31), c.l)


def sh_bbq(s, rng, name):
    c = C(pick(rng, ["black", "red", "charcoal", "navy", "green"]))
    for (x0, x1) in ((9, 5), (22, 26), (15.5, 15.5)):
        s.draw(L(x0, 20, x1, 29, 1.4), flat(C("chrome").m))
    s.draw(E(15.5, 14, 12, 8) & R(0, 14, 31, 31), sph(c, 15.5, 16, 12, spec=False))
    s.draw(E(15.5, 14, 12, 7) & R(0, 0, 31, 13), sph(c, 13, 12, 12))
    s.rect(4, 14, 27, 14, C("chrome").l)
    s.draw(R(13, 4, 18, 6), flat(C("black").m))
    s.draw(E(5, 29, 2), sph(C("black"), 5, 29, 2))
    for x in (9, 13, 18, 22):
        s.put(x, 10, c.x)


def sh_pool(s, rng, name):
    c = C(pick(rng, ["blue", "pink", "yellow", "teal", "orange"]))
    s.draw(E(15.5, 18, 14.5, 10), lambda x, y, m: c.l if y < 14 else (c.m if y < 23 else c.d))
    s.fill(E(15.5, 18, 14, 9) - E(15.5, 18, 11, 6.5), c.m)
    s.fill(ring(15.5, 18, 14, 13.2, 9, 8.2) & R(0, 0, 31, 16), c.e)
    s.draw(E(15.5, 17.5, 10.5, 6), lambda x, y, m: C("sky").e if (x + 2 * y) % 9 == 0 else C("sky").l)
    for a in range(0, 360, 60):
        s.put(int(round(15.5 + 12.5 * math.cos(math.radians(a)))), int(round(18 + 8 * math.sin(math.radians(a)))), C("white").e)
    s.draw(E(20, 16, 2.4), sph(C("red"), 20, 16, 2.4))


def sh_lawnmower(s, rng, name):
    c = C(pick(rng, ["green", "red", "orange", "yellow", "blue"]))
    s.draw(PL([(15, 16), (20, 4), (27, 3)], 1.6), flat(C("black").m))
    s.draw(L(26, 1, 29, 5, 2), flat(C("black").l))
    s.draw(RR(15, 13, 29, 23, 2), lambda x, y, m: C("black").l if (x + y) % 3 == 0 else C("black").m)
    s.draw(P((2, 21), (4, 15), (17, 15), (19, 21), (19, 25), (2, 25)), bev(c))
    s.draw(R(6, 12, 13, 15), flat(C("charcoal").m))
    s.draw(E(9.5, 12, 3.5, 1.2), flat(C("charcoal").l))
    for x in (5, 17):
        s.draw(E(x, 26, 3), sph(C("black"), x, 26, 3, spec=False))
        s.put(x, 26, C("chrome").l)


def sh_deckchair(s, rng, name):
    wood = C(pick(rng, ["pine", "oak", "tan"]))
    c1, c2 = [C(n) for n in picks(rng, ["red", "blue", "yellow", "green", "white", "orange", "navy"], 2)]
    s.draw(L(6, 29, 18, 3, 2), flat(wood.m))
    s.draw(L(4, 20, 24, 29, 2), flat(wood.d))
    s.draw(L(14, 29, 26, 17, 2), flat(wood.m))
    sling = P((9, 7), (18, 5), (24, 21), (14, 24))
    s.draw(sling, lambda x, y, m: c1.m if ((x - (y - 5) * 0.4) // 3) % 2 else c2.l)
    s.draw(L(19, 17, 29, 24, 2), flat(wood.l))


def sh_bench(s, rng, name):
    iron = C("jet")
    wood = C(pick(rng, ["teak", "oak", "pine", "green", "walnut"]))
    for x0 in (3, 25):
        s.draw(PL([(x0 + 2, 5), (x0 + 1, 17), (x0 + 3, 21), (x0, 29)], 2) | PL([(x0 + 1, 21), (x0 + 4, 29)], 2), flat(iron.m))
        s.draw(E(x0 + 2, 18, 2.5), flat(iron.l))
        s.fill(E(x0 + 2, 18, 1), OUT)
    for y in (6, 9, 12):
        s.draw(R(4, y, 28, y + 1), cyly(wood, y, y + 1))
    for y in (18, 20):
        s.draw(R(2, y, 29, y + 1), cyly(wood, y, y + 1))


def sh_chair(s, rng, name, patio=False):
    if patio:
        c = C(pick(rng, ["white", "forest", "black", "sky", "teal"]))
        s.draw(L(15.5, 5, 15.5, 29, 1), flat(C("chrome").l))
        um = C(pick(rng, ["red", "green", "cream", "navy", "yellow"]))
        s.draw(P((15.5, 1), (29, 8), (2, 8)), lambda x, y, m: um.l if (x // 4) % 2 else um.m)
        s.draw(E(15.5, 18, 11, 2.5), flat(c.l))
        s.draw(R(6, 20, 7, 28) | R(24, 20, 25, 28), flat(c.m))
        s.rect(4, 28, 27, 28, OUT) if False else None
        return
    wood = C(pick(rng, ["teak", "oak", "pine", "walnut", "forest"]))
    s.draw(R(6, 2, 8, 29) | R(23, 2, 25, 29), cylx(wood, 6, 8))
    for y in (4, 8, 12):
        s.draw(R(8, y, 23, y + 2), cyly(wood, y, y + 2))
    s.draw(R(4, 16, 27, 19), bev(wood))
    s.draw(R(4, 20, 6, 29) | R(25, 20, 27, 29), flat(wood.d))


def sh_table(s, rng, name, nest=False):
    wood = C(pick(rng, ["teak", "teak", "walnut", "oak"]))
    if nest:
        for i, (x0, x1, top) in enumerate([(1, 30, 6), (4, 27, 12), (7, 24, 18)]):
            s.draw(R(x0, top, x0 + 1, 29) | R(x1 - 1, top, x1, 29), flat(wood.d))
            s.draw(R(x0 - 1, top - 2, x1 + 1, top), lambda x, y, m: wood.l if y == top - 2 else wood.m)
        return
    s.draw(L(6, 12, 3, 29, 2) | L(25, 12, 28, 29, 2), flat(wood.m))
    s.draw(L(10, 12, 9, 26, 1.6) | L(21, 12, 22, 26, 1.6), flat(wood.d))
    s.draw(R(4, 13, 27, 15), flat(wood.d))
    s.draw(P((5, 7), (26, 7), (30, 11), (1, 11)), lambda x, y, m: wood.l if (y + x // 6) % 3 else wood.m)
    s.draw(R(1, 12, 30, 12), flat(wood.d))
    s.rect(2, 11, 29, 11, wood.l)


def sh_rug(s, rng, name):
    c = C(pick(rng, ["crimson", "navy", "wine", "teal", "forest", "rust"]))
    b = C(pick(rng, ["navy", "cream", "gold", "black"]))
    s.draw(R(3, 6, 28, 25), flat(c.m))
    for (x, y) in R(4, 7, 27, 24) - R(6, 9, 25, 22):
        s.put(x, y, b.m if (x + y) % 3 else b.l)
    s.fill(P((15.5, 10), (22, 15.5), (15.5, 21), (9, 15.5)), C("cream").m)
    s.fill(P((15.5, 12), (19, 15.5), (15.5, 19), (12, 15.5)), c.d)
    s.put(15, 15, C("gold").l)
    s.put(16, 16, C("gold").l)
    for x in range(3, 29, 2):
        s.rect(x, 3, x, 5, C("cream").d)
        s.rect(x, 26, x, 28, C("cream").d)


def sh_vase(s, rng, name, lava=False):
    if lava:
        c = C(pick(rng, ["charcoal", "brown", "walnut", "black"]))
        lava_c = C(pick(rng, ["orange", "red", "amber", "yellow", "lime"]))
    else:
        c = C(pick(rng, ["teal", "blue", "cream", "red", "green", "mustard", "white", "navy", "orange"]))
    prof = [3.5, 3, 2.5, 2.5, 3, 4, 5.5, 7, 8.5, 9.5, 10.5, 11, 11, 11, 10.5, 10, 9.5, 8.5, 7.5, 6.5, 6, 6, 6.5]
    y0 = 4
    m = set()
    for i, hw in enumerate(prof):
        m |= R(int(round(15.5 - hw + 0.5)), y0 + i, int(round(15.5 + hw - 0.5)), y0 + i)
    m |= R(12, 3, 19, 5)

    def shade(r, x, y):
        t = (x - 4.5) / 22.0
        if 0.24 < t < 0.3 and 9 < y < 22:
            return r.e
        if t < 0.35:
            return r.l
        if t > 0.72:
            return r.d
        return r.m

    drips = {7: 4, 11: 6, 16: 3, 20: 5, 24: 3}

    def f(x, y, mm):
        if lava:
            edge = 15 + (1 if x % 3 == 0 else 0) + drips.get(x, 0) + (drips.get(x - 1, 0) // 2)
            if 9 <= y < edge:
                if (x * 5 + y * 7) % 13 == 0:
                    return lava_c.x
                if (x * 3 + y * 11) % 9 == 0:
                    return lava_c.e
                return shade(lava_c, x, y)
            return shade(c, x, y)
        return shade(c, x, y)
    s.draw(m, f)
    s.fill(E(15.5, 3.5, 3, 0.8), c.x)
    if not lava and rng.random() < 0.6:
        fg = C(contrast(rng, c.base, ["white", "gold", "navy", "red", "black"]))
        s.rect(6, 15, 25, 15, fg.m)
        s.rect(6, 17, 25, 17, fg.m)
        for x in range(7, 25, 3):
            s.put(x, 16, fg.l)


def sh_glasses(s, rng, name):
    g = C("glass")
    wine = C(pick(rng, ["wine", "amber", "wine"]))
    for i, (cx, top) in enumerate(((8, 2), (23, 2))):
        cup = E(cx, top + 4, 5, 6) & R(0, top, 31, top + 10) | R(cx - 5, top, cx + 5, top + 4)
        s.draw(cup, lambda x, y, m, cx=cx: C("white").e if x == cx - 3 and y < top + 7 else (g.l if x < cx else g.m))
        if i == 0:
            s.fill(E(cx, top + 5, 4, 4) & R(0, top + 6, 31, 31), wine.m)
            s.fill(R(cx - 4, top + 6, cx + 4, top + 6), wine.l)
        s.draw(R(cx, top + 10, cx, top + 17), flat(g.l))
        s.draw(E(cx, top + 18, 4.5, 1.2), flat(g.m))
    s.draw(R(11, 17, 20, 29), lambda x, y, m: C("white").e if x == 12 else (g.l if x < 16 else g.m))
    s.fill(R(12, 22, 19, 28), C("amber").m)
    s.fill(R(12, 22, 19, 22), C("amber").l)
    s.fill(R(12, 23, 12, 27), C("amber").e)
    s.rect(12, 28, 19, 28, g.d)


def sh_lamp(s, rng, name):
    shade = C(pick(rng, ["cream", "paper", "red", "sky", "mustard", "green", "pink", "white"]))
    base = C(pick(rng, ["brass", "chrome", "teak", "cream", "wine", "teal"]))
    s.draw(E(15.5, 28, 8, 2.2), sph(base, 15.5, 28, 8, spec=False))
    s.draw(R(14, 14, 17, 27), cylx(base, 14, 17))
    s.draw(E(15.5, 21, 4.5, 4), sph(base, 15.5, 21, 4.5))
    s.draw(P((10, 2), (21, 2), (27, 14), (4, 14)), lambda x, y, m: shade.l if x < 12 + (y - 2) * -0.3 + 2 else (shade.d if x > 22 - (14 - y) * 0.2 else shade.m))
    s.rect(5, 14, 26, 14, shade.d)
    s.rect(11, 2, 20, 2, shade.e)


def sh_lantern(s, rng, name):
    c = C(pick(rng, ["red", "green", "black", "blue", "galv"]))
    s.draw(ring(15.5, 6, 6, 4.8, 5, 3.8) & R(0, 0, 31, 6), flat(C("black").m))
    s.draw(E(15.5, 7.5, 5.5, 2) | R(10, 6, 21, 8), bev(c))
    s.draw(E(15.5, 16, 7, 7) & R(0, 9, 31, 22), lambda x, y, m: C("amber").l if 12 < x < 19 else C("glass").l)
    s.draw(E(15.5, 16.5, 1.6, 3), flat(C("yellow").e), ol=False)
    s.put(15, 14, C("white").e)
    for x in (9, 22):
        s.draw(L(x, 8, x, 23), flat(c.d))
    s.draw(E(15.5, 25, 10, 4) | R(6, 22, 25, 25), cylx(c, 6, 25, spec=True))
    s.draw(E(24, 22, 1.5), flat(C("chrome").l))


def sh_clock(s, rng, name, kind="mantel"):
    if kind == "sunburst":
        gold = C("gold")
        for a in range(0, 360, 20):
            ra = math.radians(a)
            ln = 14.5 if (a // 20) % 2 == 0 else 11
            s.draw(L(15.5 + 5 * math.cos(ra), 15.5 + 5 * math.sin(ra), 15.5 + ln * math.cos(ra), 15.5 + ln * math.sin(ra), 1.6), flat(gold.m if (a // 20) % 2 else gold.l))
        s.draw(E(15.5, 15.5, 6.5), sph(gold, 15.5, 15.5, 6.5, spec=False))
        s.draw(E(15.5, 15.5, 5), flat(C("ivory").l))
        s.fill(L(15.5, 15.5, 15.5, 12), OUT)
        s.fill(L(15.5, 15.5, 18, 16), OUT)
        return
    if kind == "carriage":
        br = C("brass")
        s.draw(ring(15.5, 6, 6, 4.5, 3.5, 2.2) & R(0, 0, 31, 6), flat(br.m))
        s.draw(R(6, 7, 25, 9), bev(br))
        s.draw(R(7, 9, 24, 26), flat(br.d))
        s.draw(R(9, 10, 22, 25), lambda x, y, m: C("glass").l if x == 10 else C("glass").d)
        s.draw(R(10, 11, 21, 21), flat(C("ivory").l))
        for (x, y) in [(15, 12), (20, 16), (15, 20), (11, 16)]:
            s.put(x, y, C("black").m)
        s.fill(L(15.5, 16, 15.5, 13), OUT)
        s.fill(L(15.5, 16, 18, 17), OUT)
        s.draw(R(5, 26, 26, 28), bev(br))
        for x in (7, 24):
            s.draw(R(x - 1, 9, x, 26), cylx(br, x - 1, x))
        return
    wood = C(pick(rng, ["walnut", "mahogany", "oak", "teak", "black"]))
    m = R(2, 17, 29, 27) | E(15.5, 17, 13.5, 11) & R(0, 0, 31, 17) | R(4, 27, 8, 29) | R(23, 27, 27, 29)
    s.draw(m, bev(wood))
    s.draw(E(15.5, 16, 8), sph(C("brass"), 15.5, 16, 8, spec=False))
    s.draw(E(15.5, 16, 6.3), flat(C("ivory").l))
    for a in range(0, 360, 30):
        s.put(int(round(15.5 + 5.2 * math.cos(math.radians(a)))), int(round(16 + 5.2 * math.sin(math.radians(a)))), C("black").l)
    s.fill(L(15.5, 16, 15.5, 11.5), OUT)
    s.fill(L(15.5, 16, 19, 18), OUT)
    s.rect(3, 26, 28, 26, wood.d)


def sh_mirror(s, rng, name):
    gilt = C(pick(rng, ["gold", "brass", "walnut"]))
    s.draw(P((15.5, 0), (19, 3), (12, 3)), flat(gilt.l))
    s.draw(E(15.5, 16.5, 11, 14), sph(gilt, 15.5, 16.5, 12))
    for a in range(0, 360, 24):
        s.put(int(round(15.5 + 10 * math.cos(math.radians(a)))), int(round(16.5 + 13 * math.sin(math.radians(a)))), gilt.x)
    s.draw(E(15.5, 16.5, 8, 11), lambda x, y, m: C("white").e if (x + y) in (22, 23, 27) else (C("glass").l if x < 16 else C("glass").m))


def sh_bottle(s, rng, name):
    g = C("glass")
    liq = C(pick(rng, ["amber", "amber", "wine", "glass"]))
    m = RR(6, 11, 25, 29, 3) | R(13, 5, 18, 11)
    s.draw(m, lambda x, y, m: C("white").e if x in (8, 9) and 13 < y < 27 else (g.l if x < 12 else (g.d if x > 21 else g.m)))
    s.fill(RR(7, 17, 24, 28, 2), liq.m)
    s.fill(R(7, 17, 24, 17), liq.l)
    s.rect(8, 18, 9, 26, liq.e)
    for x in (12, 16, 20):
        s.rect(x, 12, x, 28, g.d if x != 12 else g.l)
    s.draw(E(15.5, 3.5, 3.2, 2.8), sph(g, 15.5, 3.5, 3.2))


def sh_mug(s, rng, name, two=False):
    if two:
        c2 = C(pick(rng, BRIGHTS + ["white", "cream"]))
        s.draw(ring(27, 10, 4, 2) & R(27, 0, 31, 31), flat(c2.d))
        s.draw(R(15, 2, 27, 17), cylx(c2, 15, 27))
        s.draw(E(21, 2.5, 6, 1.2), flat(c2.x))
    c = C(pick(rng, ["white", "cream", "blue", "red", "navy", "yellow", "green"]))
    y0 = 11 if two else 7
    s.draw(ring(23, y0 + 10, 6, 3.5, 5.5, 3) & R(23, 0, 31, 31), flat(c.m))
    s.draw(RR(4, y0, 23, 29, 1), cylx(c, 4, 23, spec=True))
    s.draw(E(13.5, y0, 9.5, 1.5), flat(c.x), ol=False)
    s.rect(5, y0 - 1, 22, y0 - 1, OUT) if False else None
    if "commemorative" in name.lower():
        s.fill(P((9, y0 + 11), (10, y0 + 6), (12, y0 + 9), (13.5, y0 + 5), (15, y0 + 9), (17, y0 + 6), (18, y0 + 11)), C("gold").l)
        s.rect(9, y0 + 12, 18, y0 + 13, C("gold").m)
        s.rect(8, y0 + 16, 19, y0 + 16, C("red").m)
        s.rect(8, y0 + 17, 19, y0 + 17, C("blue").m)
    else:
        fg = C(contrast(rng, c.base))
        if rng.random() < 0.5:
            s.rect(5, y0 + 6, 22, y0 + 8, fg.m)
        else:
            s.fill(E(13, y0 + 10, 3.5), fg.m)


def sh_teapot(s, rng, name, set_=False):
    c = C(pick(rng, ["white", "cream", "brown", "sky", "mint", "pink", "navy"]))
    if set_:
        c = C(pick(rng, ["white", "ivory", "cream"]))
    s.draw(ring(24, 17, 5.5, 3, 5.5, 3.5) & R(24, 0, 31, 31), flat(c.m))
    s.draw(PL([(9, 19), (5, 15), (2, 10)], 2.8), flat(c.m))
    s.draw(E(14.5, 19, 10, 8.5) & R(0, 12, 31, 31), sph(c, 14.5, 19, 9.5))
    s.draw(E(14.5, 12, 6, 2), flat(c.l))
    s.draw(E(14.5, 9, 1.8), sph(c, 14.5, 9, 1.8))
    if set_ or rng.random() < 0.6:
        fl = C(pick(rng, ["pink", "blue", "red", "gold", "violet"]))
        for (x, y) in [(10, 19), (15, 21), (19, 18), (13, 24)]:
            s.fill(E(x, y, 1.2), fl.m)
            s.put(x, y, C("yellow").l)
        s.pts([(9, 20), (16, 22)], C("green").m)
        s.rect(6, 15, 23, 15, C("gold").m)
    if set_:
        s.draw(E(25, 28.5, 5.5, 1.8), flat(c.m))
        s.draw(E(25, 25, 3.8, 3.5) & R(0, 23, 31, 31) | R(21, 23, 29, 24), sph(c, 25, 25, 3.8))
        s.put(24, 25, C("pink").m)


def sh_casserole(s, rng, name):
    c = C(pick(rng, ["orange", "red", "blue", "teal", "yellow", "green"]))
    s.draw(R(0, 16, 4, 18) | R(27, 16, 31, 18), flat(C("black").m))
    s.draw(RR(3, 13, 28, 28, 3), lambda x, y, m: c.l if y < 18 else (c.m if y < 23 else (c.d if y < 26 else C("black").l)))
    s.draw(E(15.5, 12, 13, 3.2), lambda x, y, m: c.l if y < 12 else c.m)
    s.draw(RR(12, 6, 19, 9, 1), flat(C("black").m))
    s.rect(4, 15, 27, 15, c.e)


def sh_cutlery(s, rng, name):
    wood = C(pick(rng, ["mahogany", "oak", "walnut"]))
    lining = C(pick(rng, ["wine", "navy", "forest"]))
    s.draw(P((3, 3), (28, 3), (29, 12), (2, 12)), flat(wood.d))
    s.draw(P((5, 5), (26, 5), (27, 11), (4, 11)), flat(lining.l), ol=False)
    s.draw(R(2, 13, 29, 29), bev(wood))
    s.draw(R(4, 14, 27, 23), flat(lining.m))
    sil = C("silver")
    for i, x in enumerate(range(6, 26, 4)):
        kind = i % 3
        if kind == 0:  # fork
            s.draw(R(x, 18, x, 22) | R(x - 1, 15, x + 1, 17), flat(sil.l))
            s.put(x, 15, lining.m)
        elif kind == 1:  # knife
            s.draw(R(x, 15, x + 1, 22), lambda xx, y, m: sil.e if xx == x else sil.m)
        else:  # spoon
            s.draw(E(x, 16, 1.4, 1.8) | R(x, 17, x, 22), flat(sil.l))
    s.draw(R(14, 25, 17, 27), flat(C("brass").l))


def sh_fireside(s, rng, name):
    br = C(pick(rng, ["brass", "brass", "black", "copper"]))
    s.draw(E(15.5, 28, 9, 2.2), sph(br, 15.5, 28, 9, spec=False))
    s.draw(L(15.5, 4, 15.5, 27, 1.6), flat(br.m))
    s.draw(E(15.5, 3, 2), sph(br, 15.5, 3, 2))
    s.draw(L(8, 8, 23, 8, 1.4), flat(br.l))
    # poker, brush, shovel
    s.draw(L(8, 8, 7, 24, 1.2), flat(C("black").m))
    s.draw(L(7, 24, 9, 22), flat(C("black").m))
    s.draw(L(23, 8, 24, 20, 1.2), flat(br.d))
    s.draw(P((21, 20), (27, 20), (26, 26), (22, 26)), flat(C("black").l))
    s.draw(E(8, 9, 1.4), flat(br.l))
    s.draw(E(23, 9, 1.4), flat(br.l))
    s.draw(L(19, 10, 19, 20, 1), flat(br.d))
    s.draw(P((17, 20), (21, 20), (20, 25), (18, 25)), flat(C("walnut").m))


def sh_chest(s, rng, name):
    wood = C(pick(rng, ["oak", "teak", "walnut", "pine", "mahogany"]))
    s.draw(E(15.5, 11, 14, 4) & R(0, 0, 31, 11) | R(1.5, 11, 29.5, 14), lambda x, y, m: wood.l if y < 10 else wood.m)
    s.draw(R(2, 14, 29, 28), bev(wood))
    for y in (19, 24):
        s.rect(3, y, 28, y, wood.d)
    iron = C("jet")
    for x in (6, 24):
        s.rect(x, 8, x + 1, 28, iron.l)
    s.draw(R(13, 12, 18, 18), flat(C("brass").m))
    s.put(15, 15, OUT)
    s.put(15, 16, OUT)
    s.rect(1, 14, 30, 14, OUT)


def sh_frame(s, rng, name, lot=False):
    if lot:
        f2 = C(pick(rng, ["walnut", "black", "gold"]))
        s.draw(R(14, 1, 30, 18), bev(f2))
        s.draw(R(17, 4, 27, 15), flat(C(pick(rng, ["sky", "cream", "pink"])).m))
    x0, y0, x1, y1 = (1, 9, 22, 30) if lot else (2, 3, 29, 28)
    fr = C(pick(rng, ["gold", "walnut", "black", "oak", "brass"]))
    s.draw(R(x0, y0, x1, y1), bev(fr))
    s.draw(R(x0 + 3, y0 + 3, x1 - 3, y1 - 3), flat(C("sky").l))
    mid = (y0 + y1) // 2 + 2
    s.fill(P((x0 + 3, mid), (x0 + 9, y0 + 7), (x0 + 14, mid - 1), (x1 - 5, y0 + 9), (x1 - 3, mid), (x1 - 3, y1 - 3), (x0 + 3, y1 - 3)), C("green").m)
    s.fill(R(x0 + 3, mid + 3, x1 - 3, y1 - 3), C("forest").m)
    s.fill(E(x1 - 7, y0 + 6, 1.6), C("yellow").e)
    s.fill(P((x0 + 9, y0 + 7), (x0 + 11, y0 + 9), (x0 + 7, y0 + 9)), C("white").e)


def sh_mixer(s, rng, name):
    c = C(pick(rng, ["red", "cream", "sky", "mint", "pink", "black", "yellow", "teal"]))
    s.draw(RR(2, 25, 28, 29, 1), bev(c))
    s.draw(R(3, 10, 9, 25), cylx(c, 3, 9))
    s.draw(E(19, 21, 8, 6) & R(0, 18, 31, 31), sph(C("chrome"), 17, 20, 8))
    s.draw(E(19, 18, 8, 1.8), lambda x, y, m: C("chrome").x if y > 17 else C("chrome").l)
    s.draw(R(18, 12, 20, 18), flat(C("chrome").m))
    s.draw(RR(3, 4, 27, 12, 3), cyly(c, 4, 12, spec=True))
    s.draw(E(26, 9.5, 2, 2.5), flat(c.d))
    s.put(7, 8, C("chrome").l)
    s.draw(E(6, 17, 1.5), flat(C("chrome").l))


def sh_bauble(s, rng, name, egg=False):
    if egg:
        c = C(pick(rng, ["pink", "mint", "sky", "yellow", "violet"]))
        c2 = C(contrast(rng, c.base, ["pink", "mint", "sky", "yellow", "violet", "white"]))
        s.draw(E(15.5, 17, 10, 13), lambda x, y, m: c2.m if y in (12, 13, 20, 21) else (C("white").e if (x - 11) ** 2 + (y - 10) ** 2 < 5 else (c.l if x < 14 else (c.d if x > 21 else c.m))))
        for x in range(7, 25, 3):
            s.put(x, 16 + (x % 2), C("white").l)
            s.put(x + 1, 17 - (x % 2), C("white").l)
        return
    c = C(pick(rng, ["red", "gold", "green", "blue", "purple", "silver"]))
    s.draw(ring(15.5, 3, 2.5, 1.2), flat(C("gold").m))
    s.draw(R(12, 5, 19, 8), cylx(C("gold"), 12, 19))
    s.draw(E(15.5, 18.5, 11.5), sph(c, 15.5, 18.5, 11.5))
    s.fill(R(5, 17, 26, 17), C("white").l)
    for x in range(6, 26, 3):
        s.put(x, 18, C("white").l)
    s.pts([(26, 6), (25, 7), (27, 7), (26, 8)], C("white").e)


def sh_chess(s, rng, name):
    wood = C("oak")
    dark = C("walnut")
    top, bot = 17, 27

    def lr(y):
        t = (y - top) / float(bot - top)
        return 6 - 4 * t, 25 + 4 * t

    board = P((6, top), (25, top), (29, bot), (2, bot))

    def f(x, y, m):
        a, b = lr(y)
        u = (x - a) / max(1.0, b - a)
        v = (y - top) / float(bot - top + 1)
        chk = (int(u * 6) + int(v * 4)) % 2
        return dark.m if chk else wood.l
    s.draw(board, f)
    s.draw(R(2, bot + 1, 29, bot + 3), flat(wood.d))
    s.rect(3, bot + 1, 28, bot + 1, wood.m)
    k = C(pick(rng, ["ivory", "black"]))
    s.draw(E(11.5, 21.5, 4.5, 1.6) | P((9, 20), (14, 20), (13, 11), (10, 11)) | E(11.5, 10, 3, 2.2), lambda x, y, m: k.l if x < 11 else k.m)
    s.draw(R(11, 3, 12, 7) | R(9, 4, 14, 5), flat(k.m))
    p = C("black" if k.base == PAL["ivory"] else "ivory")
    s.draw(E(21, 23.5, 3.5, 1.4) | P((19.5, 22), (22.5, 22), (22, 18), (20, 18)) | E(21, 16, 2.5), lambda x, y, m: p.l if x < 21 else p.m)


def sh_jigsaw(s, rng, name):
    piece = R(5, 8, 23, 26) | E(14, 5, 3.4) | E(26, 17, 3.4)
    piece -= E(5, 17, 3.2) | E(14, 26.8, 3.2)
    top = C(pick(rng, ["sky", "sky", "teal", "violet"]))
    bot = C(pick(rng, ["green", "forest", "lime", "orange"]))

    def f(x, y, m):
        t = (x, y - 1) not in m or (x - 1, y) not in m
        b = (x, y + 1) not in m or (x + 1, y) not in m
        base = top if y < 17 - (x > 14) * 2 + (x > 19) * 3 else bot
        if t and not b:
            return base.l
        if b and not t:
            return base.d
        return base.m
    s.draw(piece, f)
    s.fill(E(19, 11, 1.8), C("yellow").e)


def sh_croquet(s, rng, name):
    wood = C(pick(rng, ["pine", "oak", "teak"]))
    band = C(pick(rng, ["red", "blue", "yellow", "black", "green"]))
    s.draw(ring(26, 24, 4.5, 3, 7, 5.5) & R(0, 0, 31, 24), flat(C("white").l))
    s.draw(L(4, 2, 16, 17, 2.2), cylx(wood, 3, 17))
    head = L(13.5, 24, 21.5, 16.5, 6.5)
    s.draw(head, lambda x, y, m: wood.l if (x + y) < 36 else (wood.m if (x + y) < 39 else wood.d))
    for (x, y) in ((14.6, 23), (20.4, 17.6)):
        s.fill(L(x - 2, y - 2.2, x + 2, y + 2.2, 1.6) & head, band.m)
    s.draw(E(7, 25, 4.5), sph(band, 7, 25, 4.5))


def sh_dancemat(s, rng, name):
    c = C(pick(rng, ["black", "navy", "charcoal", "purple"]))
    s.draw(PL([(15, 5), (15, 2), (22, 1), (28, 3)], 1.2), flat(C("black").m))
    s.draw(R(28, 2, 30, 4), flat(C("chrome").m))
    s.draw(RR(2, 5, 29, 29, 1), bev(c))
    cols = {(1, 0): "pink", (0, 1): "sky", (2, 1): "sky", (1, 2): "pink"}
    for j in range(3):
        for i in range(3):
            x0, y0 = 4 + i * 8, 7 + j * 7
            pc = C(cols.get((i, j), "slate"))
            s.draw(R(x0, y0, x0 + 6, y0 + 5), bev(pc) if (i, j) in cols else flat(c.l), ol=False)
            cx, cy = x0 + 3, y0 + 2.5
            w = C("white").e
            if (i, j) == (1, 0):
                s.fill(P((cx, y0 + 1), (cx + 2, y0 + 3), (cx - 2, y0 + 3)) | R(cx, y0 + 3, cx, y0 + 4), w)
            elif (i, j) == (1, 2):
                s.fill(P((cx, y0 + 4), (cx + 2, y0 + 2), (cx - 2, y0 + 2)) | R(cx, y0 + 1, cx, y0 + 2), w)
            elif (i, j) == (0, 1):
                s.fill(P((x0 + 1, cy), (x0 + 3, cy - 2), (x0 + 3, cy + 2)) | R(x0 + 3, int(cy), x0 + 5, int(cy)), w)
            elif (i, j) == (2, 1):
                s.fill(P((x0 + 5, cy), (x0 + 3, cy - 2), (x0 + 3, cy + 2)) | R(x0 + 1, int(cy), x0 + 3, int(cy)), w)


def sh_figure(s, rng, name, kind="action"):
    skin = C(pick(rng, ["skin", "tan", "brown"]))
    if kind == "gnome":
        hat = C(pick(rng, ["red", "red", "blue", "green"]))
        coat = C(pick(rng, ["blue", "green", "navy", "yellow"]))
        s.draw(R(9, 26, 14, 29) | R(17, 26, 22, 29), flat(C("brown").m))
        s.draw(RR(8, 15, 23, 26, 2), bev(coat))
        s.draw(R(8, 21, 23, 22), flat(C("black").m), ol=False)
        s.put(15, 21, C("gold").l)
        s.draw(E(15.5, 12, 4, 3), flat(skin.m))
        s.draw(P((10, 13), (21, 13), (15.5, 23)), flat(C("white").l))
        s.fill(E(15.5, 13, 1.3), C("pink").m)
        s.draw(P((15.5, 0), (21, 11), (10, 11)), lambda x, y, m: hat.l if x < 15 else hat.m)
        s.draw(E(6, 20, 2), flat(skin.m))
        s.draw(E(25, 20, 2), flat(skin.m))
        return
    if kind == "soldier":
        red = C("red")
        s.draw(R(10, 28, 21, 30), flat(C("forest").m))
        s.draw(R(12, 20, 14, 28) | R(17, 20, 19, 28), flat(C("navy").m))
        s.draw(RR(11, 11, 20, 20, 1), bev(red))
        s.fill(L(12, 12, 19, 19), C("white").l)
        s.fill(R(11, 18, 20, 18), C("white").l)
        s.draw(RR(12, 0, 19, 6, 2), bev(C("black")))
        s.draw(R(14, 7, 17, 10), flat(skin.l))
        s.pts([(14, 8), (17, 8)], OUT)
        s.rect(13, 7, 13, 10, C("gold").m)
        s.draw(L(22, 3, 22, 20), flat(C("brown").m))
        s.draw(R(20, 12, 22, 14), flat(red.m))
        s.draw(R(9, 12, 10, 18), flat(red.d))
        return
    if kind == "doll":
        hair = C(pick(rng, ["yellow", "brown", "black", "orange"]))
        dress = C(pick(rng, ["pink", "red", "sky", "violet", "mint"]))
        s.draw(R(13, 24, 14, 29) | R(17, 24, 18, 29), flat(skin.m))
        s.draw(E(15.5, 8, 6, 7) | R(9.5, 8, 21.5, 16), lambda x, y, m: hair.l if x < 14 else hair.m)
        s.draw(P((12, 13), (19, 13), (24, 25), (7, 25)), bev(dress))
        s.draw(E(15.5, 7.5, 3.8, 4), flat(skin.m))
        s.pts([(14, 7), (17, 7)], C("blue").m)
        s.put(15, 10, C("red").m)
        s.put(16, 10, C("red").m)
        s.draw(R(9, 14, 10, 20) | R(21, 14, 22, 20), flat(skin.m))
        s.rect(12, 3, 19, 4, hair.l)
        return
    if kind == "mini":
        c = C(pick(rng, ["grey", "red", "blue", "green", "silver"]))
        s.draw(E(15.5, 28, 10, 2.5), flat(C("black").m))
        s.draw(R(12, 20, 14, 26) | R(17, 20, 19, 26), flat(c.d))
        s.draw(RR(11, 11, 20, 20, 1), bev(c))
        s.draw(E(15.5, 8, 3.2), sph(C("steel"), 15.5, 8, 3.2))
        s.draw(E(8, 17, 4.2, 5), sph(C(pick(rng, ["red", "blue", "gold"])), 8, 17, 4.5))
        s.fill(L(8, 13, 8, 21), C("gold").l)
        s.draw(L(22, 21, 27, 3, 1.4), flat(C("chrome").l))
        s.draw(L(20, 16, 25, 17, 1.2), flat(C("brass").m))
        return
    # action figure
    suit = C(pick(rng, ["blue", "red", "green", "purple", "navy", "orange"]))
    trim = C(contrast(rng, suit.base, ["red", "yellow", "gold", "black", "white"]))
    s.draw(P((9, 9), (22, 9), (26, 26), (5, 26)), flat(trim.d))  # cape
    s.draw(L(12, 19, 10, 29, 3) | L(19, 19, 21, 29, 3), flat(suit.d))
    s.draw(R(8, 28, 12, 29) | R(19, 28, 23, 29), flat(trim.m))
    s.draw(L(10, 10, 4, 17, 2.8) | L(21, 10, 27, 5, 2.8), flat(suit.m))
    s.draw(E(4, 18, 1.8) | E(27, 4, 1.8), flat(skin.m))
    s.draw(P((10, 9), (21, 9), (19, 20), (12, 20)), bev(suit))
    s.fill(P((13, 11), (18, 11), (15.5, 15)), trim.l)
    s.draw(R(12, 19, 19, 20), flat(trim.m))
    s.draw(E(15.5, 5, 3.2, 3.5), flat(skin.m))
    s.fill(E(15.5, 3.5, 3.2, 2) & R(0, 0, 31, 4), C("black").m)
    s.pts([(14, 5), (17, 5)], OUT)


def sh_teddy(s, rng, name, monster=False):
    if monster:
        c = C(pick(rng, ["yellow", "pink", "sky", "mint", "orange", "violet"]))
        s.draw(P((6, 12), (4, 2), (12, 8)) | P((25, 12), (27, 2), (19, 8)), flat(c.d))
        s.draw(E(15.5, 18, 12, 11), sph(c, 15.5, 18, 12, spec=False))
        for cx in (11, 20):
            s.fill(E(cx, 15, 2.6), C("white").e)
            s.fill(E(cx + 0.5, 15.5, 1.3), OUT)
            s.put(int(cx), 14, C("white").e)
        s.fill(E(15.5, 22, 2.5, 1.2), C("red").d)
        s.fill(E(7, 21, 1.5, 1), C("pink").l)
        s.fill(E(24, 21, 1.5, 1), C("pink").l)
        return
    fur = C(pick(rng, ["tan", "brown", "gold", "cream", "walnut"]))
    muz = C("paper")
    for cx in (8, 23):
        s.draw(E(cx, 4.5, 3), sph(fur, cx, 4.5, 3, spec=False))
        s.fill(E(cx, 4.5, 1.4), fur.d)
    s.draw(E(10, 27, 4, 3) | E(21, 27, 4, 3), sph(fur, 15.5, 25, 8, spec=False))
    s.draw(E(15.5, 22, 7.5, 7), sph(fur, 15.5, 21, 7.5, spec=False))
    s.fill(E(15.5, 23, 3.5, 3.5), fur.l)
    for cx in (10, 21):
        s.fill(E(cx, 28, 1.8, 1.3), muz.d)
    s.draw(L(9, 17, 5, 23, 4), flat(fur.m))
    s.draw(L(22, 17, 26, 23, 4), flat(fur.d))
    s.draw(E(15.5, 10, 8, 7), sph(fur, 15.5, 10, 8, spec=False))
    s.fill(E(15.5, 12.5, 3.5, 2.5), muz.m)
    s.fill(E(15.5, 11.5, 1.5, 1), OUT)
    s.pts([(12, 8), (19, 8)], OUT)
    if rng.random() < 0.6:
        bow = C(pick(rng, ["red", "blue", "green", "pink"]))
        s.draw(P((12, 16), (15.5, 18), (19, 16), (19, 20), (15.5, 18.5), (12, 20)), flat(bow.m))


def sh_robot(s, rng, name):
    c = C(pick(rng, ["silver", "red", "blue", "silver", "gold"]))
    s.draw(L(15.5, 1, 15.5, 4), flat(C("chrome").m))
    s.draw(E(15.5, 1.5, 1.2), flat(C("red").l))
    s.draw(R(9, 25, 13, 29) | R(18, 25, 22, 29), bev(c))
    s.draw(R(3, 13, 6, 22) | R(25, 13, 28, 22), bev(c))
    s.draw(R(7, 13, 24, 25), bev(c))
    s.draw(R(10, 16, 21, 22), flat(C("black").m))
    for (x, cn) in ((12, "red"), (16, "yellow"), (19, "lime")):
        s.draw(E(x, 18.5, 1.2), flat(C(cn).l), ol=False)
    s.rect(11, 21, 20, 21, C("chrome").l)
    s.draw(RR(8, 4, 23, 12, 1), bev(c))
    s.draw(R(10, 6, 14, 8), flat(C("yellow").l))
    s.draw(R(17, 6, 21, 8), flat(C("yellow").l))
    s.put(12, 7, OUT)
    s.put(19, 7, OUT)
    for x in range(11, 21, 2):
        s.put(x, 10, OUT)
    for (x, y) in [(8, 14), (23, 14), (8, 24), (23, 24)]:
        s.put(x, y, c.e)


def sh_car(s, rng, name, race=False):
    c = C(pick(rng, ["red", "blue", "green", "yellow", "orange", "sky", "teal", "cream", "forest"]))
    if race:
        s.draw(P((1, 20), (6, 16), (13, 15), (16, 11), (21, 11), (24, 15), (30, 17), (30, 22), (1, 22)), bev(c))
        s.draw(P((16, 15), (17, 12), (20, 12), (22, 15)), flat(C("glass").m))
        s.draw(E(9.5, 18.5, 2.5, 2.2), flat(C("white").e))
        s.rect(9, 18, 10, 19, OUT)
        s.draw(R(26, 12, 29, 16), flat(c.d))
        for x in (7, 24):
            s.draw(E(x, 23, 3.3), sph(C("black"), x, 23, 3.3, spec=False))
            s.fill(E(x, 23, 1.2), C("chrome").l)
        s.draw(R(2, 28, 29, 29), flat(C("slate").m))
        s.rect(2, 28, 29, 28, C("slate").l)
        s.rect(4, 28, 27, 28, OUT) if False else None
        s.fill(R(3, 29, 28, 29), C("slate").d)
        return
    s.draw(P((2, 22), (2, 16), (8, 14), (11, 8), (21, 8), (25, 14), (29, 16), (29, 22)), lambda x, y, m: c.l if y < 12 else (c.m if y < 19 else c.d))
    s.draw(P((12, 9), (15, 9), (15, 13), (10, 13)), flat(C("glass").l))
    s.draw(P((17, 9), (20, 9), (23, 13), (17, 13)), flat(C("glass").m))
    s.rect(2, 19, 29, 19, C("chrome").l)
    s.draw(R(1, 20, 3, 21), flat(C("chrome").m))
    s.draw(R(28, 20, 30, 21), flat(C("chrome").m))
    s.put(28, 17, C("yellow").e)
    for x in (8, 23):
        s.draw(E(x, 23, 3.5), sph(C("black"), x, 23, 3.5, spec=False))
        s.fill(E(x, 23, 1.5), C("chrome").l)


def sh_bus(s, rng, name):
    c = C(pick(rng, ["red", "red", "crimson", "green", "blue"]))
    s.draw(RR(2, 3, 29, 25, 2), lambda x, y, m: c.l if y < 5 else (c.m if y < 23 else c.d))
    for y0 in (6, 14):
        for x in range(4, 27, 5):
            s.draw(R(x, y0, x + 3, y0 + 4), flat(C("glass").l if x < 10 else C("glass").m))
    s.rect(3, 12, 28, 12, C("cream").l)
    s.draw(R(4, 15, 7, 23), flat(C("black").m))
    s.draw(R(3, 3, 12, 4), flat(C("black").m), ol=False)
    s.rect(4, 3, 10, 3, C("yellow").l)
    for x in (8, 23):
        s.draw(E(x, 25, 3.2), sph(C("black"), x, 25, 3.2, spec=False))
        s.fill(E(x, 25, 1.3), C("chrome").l)


def sh_train(s, rng, name):
    c = C(pick(rng, ["green", "forest", "black", "red", "navy", "wine"]))
    s.draw(R(1, 26, 30, 28), lambda x, y, m: C("walnut").m if x % 4 < 2 else C("steel").l)
    s.draw(RR(3, 12, 20, 22, 1), cyly(c, 12, 22, spec=True))
    s.draw(R(5, 6, 8, 12), cylx(C("black"), 5, 8))
    s.draw(R(4, 5, 9, 6), flat(C("black").l))
    s.draw(E(13, 11.5, 2, 1.8), sph(C("brass"), 13, 11.5, 2))
    s.draw(R(19, 6, 29, 22), bev(c))
    s.draw(R(18, 4, 30, 6), flat(C("black").m))
    s.draw(R(22, 9, 26, 13), flat(C("glass").l))
    s.rect(3, 16, 19, 16, C("brass").l)
    s.draw(P((0, 23), (3, 18), (3, 23)), flat(C("red").m))
    for x, r in ((7, 2.8), (13, 2.8), (24, 3.4)):
        s.draw(E(x, 24, r), sph(C("red"), x, 24, r, spec=False))
        s.put(x, 24, C("chrome").l)
    s.draw(L(7, 24, 24, 24), flat(C("chrome").m), ol=False)


def sh_house(s, rng, name):
    wall = C(pick(rng, ["cream", "pink", "white", "yellow", "sky"]))
    roof = C(pick(rng, ["red", "brown", "slate", "navy", "forest"]))
    s.draw(R(21, 3, 24, 9), flat(C("mahogany").m))
    s.draw(R(4, 13, 27, 29), bev(wall))
    s.draw(P((15.5, 2), (30, 13), (1, 13)), lambda x, y, m: roof.l if y < 7 else (roof.m if y < 11 else roof.d))
    for (x, y) in [(7, 15), (20, 15), (7, 22)]:
        s.draw(R(x, y, x + 4, y + 4), lambda xx, yy, m: C("glass").l if (xx + yy) % 3 == 0 else C("glass").m)
        s.rect(x + 2, y, x + 2, y + 4, OUT)
    s.draw(R(19, 22, 23, 29), flat(C(pick(rng, ["red", "green", "blue", "black"])).m))
    s.put(22, 26, C("gold").l)


def sh_ball(s, rng, name):
    w = C("white")
    s.draw(E(15.5, 15.5, 13), sph(w, 15.5, 15.5, 13))
    blk = C("black").m
    s.fill(P((15.5, 11), (19.5, 14), (18, 19), (13, 19), (11.5, 14)), blk)
    for a in (-90, -18, 54, 126, 198):
        ra = math.radians(a)
        cx, cy = 15.5 + 11.2 * math.cos(ra), 15.5 + 11.2 * math.sin(ra)
        s.fill(E(cx, cy, 2.6) & E(15.5, 15.5, 12.4), blk)
        s.fill(L(15.5 + 5 * math.cos(ra), 15.5 + 5 * math.sin(ra), 15.5 + 9 * math.cos(ra), 15.5 + 9 * math.sin(ra)), C("grey").d)
    s.fill(PL([(6, 23), (9, 21), (11, 23), (14, 20), (17, 23)]), C("navy").m)
    s.pts([(9, 7), (10, 6), (8, 8)], C("white").e)


def sh_washline(s, rng, name):
    pole = C("galv")
    s.draw(L(15.5, 9, 15.5, 30, 1.8), cylx(pole, 14, 17))
    s.draw(L(15.5, 9, 2, 3, 1.2) | L(15.5, 9, 29, 3, 1.2), flat(pole.m))
    for t in (0.35, 0.65, 0.95):
        s.fill(L(15.5 - 13.5 * t, 9 - 6 * t, 15.5 + 13.5 * t, 9 - 6 * t), C("white").d)
    for (x, y, cn, w, h) in [(4, 5, "red", 5, 7), (19, 4, "sky", 6, 8), (11, 6, "yellow", 3, 5)]:
        c = C(pick(rng, BRIGHTS))
        s.draw(R(x, y, x + w, y + h), bev(c))
        s.put(x + 1, y, C("brown").l)
        s.put(x + w - 1, y, C("brown").l)
    s.draw(R(12, 28, 19, 30), flat(C("slate").m))


def sh_tent(s, rng, name):
    c = C(pick(rng, ["orange", "forest", "khaki", "olive", "blue", "green", "red"]))
    s.draw(L(1, 29, 6, 10) | L(30, 29, 25, 10), flat(C("paper").d))
    s.draw(P((15.5, 4), (28, 27), (3, 27)), lambda x, y, m: c.l if x < 15.5 - (y - 4) * 0.2 else c.m)
    s.draw(P((15.5, 8), (21, 27), (10, 27)), flat(C("black").d))
    s.draw(P((15.5, 8), (15.5, 27), (11, 27)), flat(c.d))
    s.draw(L(15.5, 1, 15.5, 5), flat(C("walnut").m))
    s.rect(3, 27, 28, 28, c.x)
    s.rect(3, 28, 28, 28, C("green").d)


def sh_trimmer(s, rng, name):
    c = C(pick(rng, ["green", "orange", "yellow", "red", "blue"]))
    blade = R(14, 13, 30, 17)
    s.draw(blade, flat(C("steel").l))
    for x in range(15, 31, 2):
        s.put(x, 12, C("steel").m)
        s.put(x, 18, C("steel").m)
        s.put(x, 11, OUT)
        s.put(x, 19, OUT)
    s.rect(14, 15, 30, 15, C("steel").d)
    s.draw(RR(2, 10, 16, 21, 3), bev(c))
    s.draw(ring(6, 10, 5, 3, 5, 3) & R(0, 0, 31, 10), flat(C("black").m))
    s.draw(R(3, 14, 6, 17), flat(C("black").m), ol=False)
    s.draw(PL([(2, 20), (1, 27), (4, 29)], 1.2), flat(C("orange").m))


def sh_bike(s, rng, name):
    fr = C(pick(rng, ["red", "blue", "teal", "yellow", "white", "green", "orange", "silver"]))
    for cx in (7, 24):
        s.draw(ring(cx, 21, 6.5, 5), flat(C("black").m))
        s.fill(ring(cx, 21, 6.5, 5.8) & R(0, 0, 31, 19), C("black").l)
        s.put(cx, 21, C("chrome").l)
        s.fill(L(cx, 16, cx, 26) | L(cx - 5, 21, cx + 5, 21), C("steel").d)
    frame = PL([(7, 21), (13, 11), (23, 11), (15, 21), (7, 21)], 1.6) | PL([(15, 21), (12, 8)], 1.6) | PL([(23, 11), (24, 21)], 1.6)
    s.draw(frame, flat(fr.m))
    s.draw(R(10, 7, 14, 8), flat(C("black").m))
    s.draw(PL([(23, 11), (22, 7), (26, 7), (27, 10), (25, 11)], 1.2), flat(C("black").l))
    s.draw(E(15, 21, 1.8), flat(C("chrome").m))


def sh_sledge(s, rng, name):
    wood = C(pick(rng, ["pine", "oak", "teak", "red"]))
    run = C(pick(rng, ["chrome", "red", "black"]))
    s.draw(PL([(2, 26), (22, 26), (27, 24), (29, 19), (27, 16)], 1.8), flat(run.m))
    for x in (6, 12, 18):
        s.draw(R(x, 18, x + 1, 25), flat(wood.d))
    for i, y in enumerate((13, 16)):
        s.draw(P((2, y + 1), (24, y), (25, y + 2), (3, y + 3)), lambda x, yy, m: wood.l if yy == y or yy == y + 1 else wood.m)
    s.draw(PL([(25, 14), (29, 8)], 1.2), flat(C("red").m))


def sh_staddle(s, rng, name):
    st = C("stone")
    s.draw(P((10, 29), (13, 14), (18, 14), (21, 29)), lambda x, y, m: st.l if x < 14 else (st.d if x > 18 else st.m))
    s.draw(E(15.5, 12, 14, 5.5), lambda x, y, m: st.l if y < 10 else (st.m if y < 14 else st.d))
    s.fill(E(15.5, 9, 10, 2.5), st.e)
    for (x, y) in [(6, 13), (22, 10), (12, 22), (19, 25)]:
        s.put(x, y, C("green").m)
        s.put(x + 1, y, C("green").d)


def sh_birdbath(s, rng, name):
    st = C(pick(rng, ["stone", "stone", "cream", "galv"]))
    s.draw(R(8, 27, 23, 29), bev(st))
    s.draw(P((12, 26), (13, 15), (18, 15), (19, 26)), lambda x, y, m: st.l if x < 14 else (st.d if x > 17 else st.m))
    s.draw(E(15.5, 12, 14, 3.5) | P((3, 12), (28, 12), (20, 16), (11, 16)), lambda x, y, m: st.l if y < 12 else st.m)
    s.fill(E(15.5, 11.5, 11, 2), C("sky").l)
    s.fill(E(12, 11.3, 3, 0.8), C("white").e)
    b = C(pick(rng, ["red", "brown", "sky"]))
    s.draw(E(23, 7, 3, 2.2), flat(b.m))
    s.draw(E(25.5, 4.5, 1.8), flat(b.m))
    s.put(26, 4, OUT)
    s.draw(L(27, 5, 28, 5), flat(C("amber").l), ol=False)
    s.draw(L(19, 7, 21, 8), flat(b.d))


def sh_pots(s, rng, name):
    tc = C("terracotta")

    def pot(cx, rim_y, rw, body_h, taper):
        body = P((cx - rw + 1.5, rim_y + 3), (cx + rw - 1.5, rim_y + 3), (cx + rw - 1.5 - taper, rim_y + 3 + body_h), (cx - rw + 1.5 + taper, rim_y + 3 + body_h))
        s.draw(body, cylx(tc, cx - rw + 1, cx + rw - 1))
        s.draw(R(int(cx - rw), rim_y, int(cx + rw), rim_y + 3), cylx(tc, cx - rw, cx + rw, spec=True))
        s.fill(R(int(cx - rw) + 1, rim_y + 3, int(cx + rw) - 1, rim_y + 3), tc.x)
    pot(15.5, 3, 7, 5, 1.5)
    pot(15.5, 10, 9.5, 5, 1.5)
    pot(15.5, 17, 12.5, 9, 3.5)


def sh_wateringcan(s, rng, name):
    c = C(pick(rng, ["galv", "galv", "green", "red", "forest"]))
    s.draw(ring(18, 12, 7, 4.5, 6, 3.5) & R(0, 0, 31, 12), flat(c.d))
    s.draw(L(11, 24, 3, 9, 2.4), lambda x, y, m: c.l if x + y < 22 else c.m)
    rose = L(0.5, 9.5, 4, 5, 3.6)
    s.draw(rose, lambda x, y, m: c.x if (x + y) % 2 == 0 and x + y in (10, 12) else c.l)
    s.draw(RR(8, 11, 27, 29, 2), cylx(c, 8, 27, spec=True))
    s.draw(E(17.5, 11.5, 9, 2), flat(c.x))
    for y in (16, 24):
        s.rect(9, y, 26, y, c.d)


# ------------------------------------------------------------------ generic fallback
def sh_generic(s, rng, name):
    c = C("kraft")
    s.draw(R(3, 10, 28, 28), bev(c))
    s.draw(P((3, 10), (6, 4), (25, 4), (28, 10)), flat(c.l))
    s.rect(14, 10, 17, 28, C("tan").l)
    s.fill(E(15.5, 19, 3.5), C("paper").l)
    s.fill(R(15, 17, 16, 20), C("slate").m)


SHAPES = {k[3:]: v for k, v in globals().items() if k.startswith("sh_") and callable(v)}


# ======================================================================= MAPPING
# Ordered keyword rules: (regex on lowercased name, shape, kwargs)
RULES = [
    # --- vinyl & audio media
    (r"picture disc", "picdisc", {}),
    (r"78rpm|shellac", "lp", {"style": "kraft"}),
    (r"white label", "lp", {"style": "whitelabel"}),
    (r"7-inch lot|singles box", "single7", {"lot": True}),
    (r"7-inch", "single7", {}),
    (r"record rack|vinyl record lot", "crate", {"kind": "records"}),
    (r"reel-to-reel tape deck", "reeldeck", {}),
    (r"reel-to-reel", "reel", {}),
    (r"personal cassette", "walkman", {}),
    (r"radio-cassette|boombox", "boombox", {}),
    (r"cassette deck", "component", {"face": "cassette"}),
    (r"computer cassette", "cassette", {"kind": "game"}),
    (r"cassette", "cassette", {}),
    (r"\blp\b|12-inch|box set", "lp", {}),
    (r"portable cd", "discman", {}),
    (r"dvd", "case", {"lot": True, "kind": "dvd"}),
    (r"disc-era", "case", {"kind": "game"}),
    (r"console game bundle", "case", {"lot": True, "kind": "game"}),
    (r"vhs video recorder", "component", {"face": "vcr"}),
    (r"vhs", "vhs", {}),
    # --- trading cards (before generic 'tin', 'box', 'album')
    (r"tin toy robot", "robot", {}),
    (r"graded card|slab", "slab", {}),
    (r"booster box", "crate", {"kind": "packs"}),
    (r"japanese import booster", "booster", {"japanese": True}),
    (r"booster|sticker packs", "booster", {}),
    (r"deck box", "deckbox", {}),
    (r"starter deck", "deckbox", {"starter": True}),
    (r"monster plush", "teddy", {"monster": True}),
    (r"poster", "scroll", {"content": "poster"}),
    (r"playmat", "scroll", {"content": "playmat"}),
    (r"holo", "card", {"holo": True}),
    (r"rookie card", "card", {"sports": True}),
    (r"card game rare|fantasy card", "card", {}),
    (r"cigarette card set", "cardfan", {"vintage": True}),
    (r"bulk common cards", "crate", {"kind": "cards"}),
    (r"display cabinet", "cabinet", {}),
    (r"advent", "advent", {}),
    (r"sticker album", "binder", {"kind": "stickers"}),
    (r"stamp album", "binder", {"kind": "stamps"}),
    (r"cigarette card folder|tea card album", "binder", {"kind": "vintage"}),
    (r"card.*binder|card binder|card album|sports card album", "binder", {"kind": "cards"}),
    (r"trading card tin", "tin", {"motif": "cards"}),
    (r"pin badge tin", "tin", {"motif": "badges"}),
    (r"brooch tin", "tin", {"motif": "brooches"}),
    (r"watch spares tin", "tin", {"motif": "gears"}),
    (r"nuts & bolts", "tin", {"motif": "bolts"}),
    (r"holiday slides", "tin", {"motif": "slides"}),
    # --- books & paper
    (r"\bmap\b", "scroll", {"content": "map"}),
    (r"comic book lot", "comic", {"lot": True}),
    (r"comic annual|children's annuals", "book", {"emblem": "annual"}),
    (r"games magazine|old magazines", "comic", {"lot": True, "style": "magazine"}),
    (r"programme", "comic", {"lot": True, "style": "football"}),
    (r"holiday paperback box", "crate", {"kind": "books"}),
    (r"pulp sci-fi", "book_stack", {"pal": ["yellow", "orange", "red", "sky", "lime", "magenta"]}),
    (r"horror paperbacks", "book_stack", {"pal": ["black", "crimson", "charcoal", "wine", "purple", "forest"]}),
    (r"paperback|cookbook|gardening books|christmas story", "book_stack", {}),
    (r"leather-bound", "books_row", {"uniform": "leather"}),
    (r"encyclopaedia", "books_row", {"uniform": "wine"}),
    (r"condensed books", "books_row", {}),
    (r"bible", "book", {"emblem": "cross", "cover": "black"}),
    (r"photograph album", "book", {"emblem": "album", "cover": "leather"}),
    (r"natural history", "open_book", {"content": "nature"}),
    (r"pop-up", "open_book", {"content": "popup"}),
    (r"picture book", "open_book", {"content": "picture"}),
    (r"poetry", "open_book", {"content": "poetry"}),
    (r"rulebook", "book", {"emblem": "dragon", "cover": "black"}),
    (r"sheet music", "sheet", {}),
    (r"hardback|first edition|autobiography|fantasy novel", "book", {}),
    # --- cameras
    (r"early digital slr", "slr", {"dslr": True}),
    (r"slr|35mm film camera", "slr", {}),
    (r"rangefinder", "compact", {"kind": "rangefinder"}),
    (r"digital compact", "compact", {"kind": "digital"}),
    (r"instant film", "compact", {"kind": "instant"}),
    (r"box camera", "compact", {"kind": "box"}),
    (r"point-and-shoot", "compact", {"kind": "point"}),
    (r"twin-lens", "tlr", {}),
    (r"bellows", "bellows", {}),
    (r"telephoto", "lens", {"tele": True}),
    (r"\blens\b", "lens", {}),
    (r"movie camera", "cine", {}),
    (r"camcorder", "cine", {"camcorder": True}),
    (r"tripod", "tripod", {}),
    (r"cine projector", "projector", {"cine": True}),
    (r"slide projector", "projector", {}),
    (r"camera bag", "bag", {"camera": True}),
    (r"darkroom", "crate", {"kind": "darkroom"}),
    (r"enlarger", "pillar", {"enlarger": True}),
    (r"flashgun", "flashgun", {}),
    (r"light meter", "meter", {}),
    (r"binoculars", "binoculars", {}),
    # --- electronics
    (r"mini hi-fi", "component", {"face": "minihifi"}),
    (r"cable box", "component", {"face": "settop"}),
    (r"hi-fi stereo amplifier", "component", {"face": "amp"}),
    (r"turntable", "turntable", {}),
    (r"calculator", "calculator", {}),
    (r"bluetooth speaker", "speaker", {"kind": "bt"}),
    (r"bookshelf speakers", "speaker", {"kind": "pair"}),
    (r"practice amp", "speaker", {"kind": "smallamp"}),
    (r"vintage amplifier", "speaker", {"kind": "amp"}),
    (r"mobile phone", "phone", {}),
    (r"tablet", "tablet", {}),
    (r"headphones", "headphones", {}),
    (r"christmas lights", "coil", {"lights": True}),
    (r"cables", "coil", {}),
    (r"valve radio", "valve_radio", {}),
    (r"transistor radio", "radio", {}),
    (r"television|\btv\b", "tv", {}),
    (r"8-bit home computer", "computer", {}),
    (r"remote controls", "remote", {}),
    (r"mixed gadgets|accessories box", "crate", {"kind": "gadgets"}),
    # --- games
    (r"dual-screen", "handheld", {"kind": "ds"}),
    (r"lcd handheld", "handheld", {"kind": "gw"}),
    (r"handheld", "handheld", {"kind": "gb"}),
    (r"controller", "gamepad", {}),
    (r"cartridge bundle|retro games bundle", "cartridge", {"lot": True}),
    (r"boxed cartridge", "gamebox", {}),
    (r"pc big box", "gamebox", {"big": True}),
    (r"board game collection", "boardgame", {"stack": True}),
    (r"board game", "boardgame", {}),
    (r"arcade stick", "arcade", {}),
    (r"home console", "console", {}),
    (r"dance mat", "dancemat", {}),
    (r"miniatures", "figure", {"kind": "mini"}),
    (r"chess", "chess", {}),
    (r"jigsaw", "jigsaw", {}),
    (r"croquet", "croquet", {}),
    # --- collectables
    (r"slot car", "car", {"race": True}),
    (r"toy car", "car", {}),
    (r"bus", "bus", {}),
    (r"model train", "train", {}),
    (r"teddy", "teddy", {}),
    (r"coin lot", "coin", {"lot": True}),
    (r"coin pendant", "necklace", {"kind": "coin"}),
    (r"coin", "coin", {}),
    (r"memorabilia", "ball", {}),
    (r"fireworks", "crate", {"kind": "rockets"}),
    (r"gnome", "figure", {"kind": "gnome"}),
    (r"medal", "medal", {"group": True}),
    (r"soldiers", "figure", {"kind": "soldier"}),
    (r"action figure", "figure", {"kind": "action"}),
    (r"fashion doll", "figure", {"kind": "doll"}),
    (r"doll's house", "house", {}),
    (r"banknote", "note", {}),
    (r"commemorative mug", "mug", {}),
    (r"random mugs", "mug", {"two": True}),
    # --- home
    (r"lava vase", "vase", {"lava": True}),
    (r"vase", "vase", {}),
    (r"glassware", "glasses", {}),
    (r"hurricane lamp", "lantern", {}),
    (r"lamp", "lamp", {}),
    (r"sunburst clock", "clock", {"kind": "sunburst"}),
    (r"carriage clock", "clock", {"kind": "carriage"}),
    (r"clock", "clock", {"kind": "mantel"}),
    (r"\brug\b", "rug", {}),
    (r"christmas decorations", "bauble", {}),
    (r"easter", "bauble", {"egg": True}),
    (r"mirror", "mirror", {}),
    (r"decanter", "bottle", {}),
    (r"stand mixer", "mixer", {}),
    (r"casserole", "casserole", {}),
    (r"nest of tables", "table", {"nest": True}),
    (r"side table", "table", {}),
    (r"tea set", "teapot", {"set_": True}),
    (r"cutlery", "cutlery", {}),
    (r"fireside", "fireside", {}),
    (r"blanket box", "chest", {}),
    (r"framed pictures", "frame", {"lot": True}),
    # --- tools
    (r"cordless drill", "drill", {}),
    (r"pillar drill", "pillar", {}),
    (r"tool chest", "drawers", {"kind": "toolchest"}),
    (r"tool box|toolbox", "toolbox", {}),
    (r"tackle box", "toolbox", {"tackle": True}),
    (r"moulding plane", "plane", {"wooden": True}),
    (r"hand plane", "plane", {}),
    (r"socket set", "sockets", {}),
    (r"circular saw", "circsaw", {}),
    (r"panel saw", "saw", {}),
    (r"chisel roll", "toolroll", {"kind": "chisels"}),
    (r"spanner roll", "toolroll", {"kind": "spanners"}),
    (r"router", "router", {}),
    (r"angle grinder", "grinder", {}),
    (r"bench grinder", "benchgrinder", {}),
    (r"wallpaper stripper", "steamer", {}),
    (r"trolley jack", "jack", {}),
    (r"brace & bit", "brace", {}),
    (r"spirit level", "level", {}),
    (r"micrometer", "micrometer", {}),
    (r"vice", "vice", {}),
    (r"anvil", "anvil", {}),
    (r"\baxe\b", "axe", {}),
    (r"hammer", "hammer", {}),
    # --- garden & outdoor
    (r"garden tool", "gardentools", {}),
    (r"patio furniture", "chair", {"patio": True}),
    (r"garden furniture", "chair", {}),
    (r"wheelbarrow", "wheelbarrow", {}),
    (r"camping stove", "stove", {}),
    (r"fishing rod", "rod", {}),
    (r"fishing reel", "fishreel", {}),
    (r"bbq", "bbq", {}),
    (r"paddling pool", "pool", {}),
    (r"lawnmower", "lawnmower", {}),
    (r"windbreak|deckchair", "deckchair", {}),
    (r"bench", "bench", {}),
    (r"staddle", "staddle", {}),
    (r"bird bath", "birdbath", {}),
    (r"pot stack|plant pot", "pots", {}),
    (r"watering can", "wateringcan", {}),
    (r"washing line", "washline", {}),
    (r"tent", "tent", {}),
    (r"hedge trimmer", "trimmer", {}),
    (r"bike", "bike", {}),
    (r"sledge", "sledge", {}),
    # --- instruments
    (r"electric bass", "guitar", {"kind": "bass"}),
    (r"electric guitar", "guitar", {"kind": "electric"}),
    (r"effects pedal", "pedal", {}),
    (r"acoustic guitar", "guitar", {"kind": "acoustic"}),
    (r"ukulele", "guitar", {"kind": "uke"}),
    (r"banjo", "guitar", {"kind": "banjo"}),
    (r"cello", "violin", {"cello": True}),
    (r"violin", "violin", {}),
    (r"trumpet", "trumpet", {}),
    (r"saxophone", "sax", {}),
    (r"clarinet", "woodwind", {"kind": "clarinet"}),
    (r"flute", "woodwind", {"kind": "flute"}),
    (r"recorders", "woodwind", {"kind": "recorders"}),
    (r"harmonica", "harmonica", {}),
    (r"synthesizer", "keyboard", {"synth": True}),
    (r"keyboard", "keyboard", {}),
    (r"drum kit", "drum", {"kit": True}),
    (r"snare", "drum", {}),
    (r"percussion", "tambourine", {}),
    (r"accordion", "accordion", {}),
    (r"handbell", "bell", {}),
    # --- clothing
    (r"football shirt", "tshirt", {"kind": "football"}),
    (r"rugby shirt", "tshirt", {"kind": "rugby"}),
    (r"band t-shirt", "tshirt", {"kind": "band"}),
    (r"old t-shirts", "tshirt_stack", {}),
    (r"christmas jumper", "tshirt", {"kind": "jumper"}),
    (r"hoodie", "tshirt", {"kind": "hoodie"}),
    (r"track jacket", "jacket", {"kind": "track"}),
    (r"workwear", "jacket", {"kind": "work"}),
    (r"leather jacket", "jacket", {"kind": "leather"}),
    (r"denim jacket", "jacket", {"kind": "denim"}),
    (r"wax jacket", "jacket", {"kind": "wax"}),
    (r"ski jacket", "jacket", {"kind": "ski"}),
    (r"tweed", "jacket", {"kind": "tweed"}),
    (r"parka", "jacket", {"kind": "parka", "coat": True}),
    (r"winter coat", "jacket", {"kind": "coat", "coat": True}),
    (r"scarf", "scarf", {}),
    (r"halloween", "hat", {"witch": True}),
    (r"panama|\bhat\b", "hat", {}),
    (r"satchel", "bag", {}),
    (r"trainers", "trainers", {}),
    (r"wellington|boots", "boots", {}),
    (r"jeans", "jeans", {}),
    (r"bin bag", "binbag", {}),
    (r"suitcase", "suitcase", {}),
    # --- jewellery
    (r"pocket watch", "watch", {"kind": "pocket"}),
    (r"digital lcd watch", "watch", {"kind": "digital"}),
    (r"swiss automatic", "watch", {"kind": "steel"}),
    (r"quartz fashion", "watch", {"kind": "fashion"}),
    (r"wristwatch|watch", "watch", {}),
    (r"solitaire", "ring", {"kind": "solitaire"}),
    (r"signet", "ring", {"kind": "signet"}),
    (r"gold ring", "ring", {"kind": "plain"}),
    (r"cufflink", "cufflinks", {}),
    (r"mourning brooch", "brooch", {"kind": "jet"}),
    (r"festive enamel brooch", "brooch", {"kind": "festive"}),
    (r"brooch", "brooch", {}),
    (r"pearl necklace", "necklace", {"kind": "pearl"}),
    (r"locket", "necklace", {"kind": "locket"}),
    (r"chain necklace", "necklace", {"kind": "chain"}),
    (r"jewellery lot", "necklace", {"kind": "lot"}),
    (r"hoop earrings|earrings", "earrings", {}),
    (r"charm bracelet|bracelet", "bracelet", {}),
    (r"tiara", "tiara", {}),
    (r"armoire", "drawers", {"kind": "armoire"}),
]

# sensible per-category fallbacks (used only if no rule matched)
CAT_FALLBACK = {
    "Vinyl": ("lp", {}), "Books": ("book", {}), "Trading Cards": ("card", {}), "Cameras": ("slr", {}),
    "Electronics": ("radio", {}), "Musical Instruments": ("guitar", {}), "Clothing": ("tshirt", {}),
    "Jewellery": ("ring", {}), "Tools": ("toolbox", {}), "Home": ("vase", {}), "Garden & Outdoor": ("pots", {}),
    "Games": ("gamepad", {}), "Collectables": ("generic", {}),
}


def sh_cabinet(s, rng, name):
    wood = C(pick(rng, ["walnut", "black", "oak", "teak"]))
    s.draw(R(4, 1, 27, 29), bev(wood))
    s.draw(R(6, 3, 25, 26), flat(C("glass").d))
    for y0 in (4, 12, 20):
        for i in range(4):
            x = 7 + i * 5
            cc = C(pick(rng, ["yellow", "silver", "sky", "red", "gold"]))
            s.draw(R(x, y0, x + 3, y0 + 5), flat(cc.m), ol=False)
            s.put(x + 1, y0 + 1, C(pick(rng, BRIGHTS)).l)
        s.rect(6, y0 + 6, 25, y0 + 6, C("glass").l)
    s.pts([(7, 4), (8, 5)], C("white").e)
    s.draw(R(5, 29, 7, 30) | R(24, 29, 26, 30), flat(wood.d))


SHAPES = {k[3:]: v for k, v in globals().items() if k.startswith("sh_") and callable(v)}


# ======================================================================= families
def load_families():
    fams = []
    for f in sorted(glob.glob(os.path.join(ROOT, "scripts", "data", "cat_*.gd"))):
        txt = open(f, encoding="utf-8").read()
        for m in re.finditer(r'\{\s*"name"\s*:\s*"((?:[^"\\]|\\.)*)"\s*,\s*"category"\s*:\s*"([^"]+)"', txt):
            fams.append((m.group(1), m.group(2)))
    return fams


def slugify(name):
    s = re.sub(r"[^a-z0-9]", "_", name.lower())
    return s


def map_family(name, cat):
    n = name.lower()
    for rx, shape, kw in RULES:
        if re.search(rx, n):
            return shape, kw, False
    shape, kw = CAT_FALLBACK.get(cat, ("generic", {}))
    return shape, kw, True


def render(name, cat):
    shape, kw, fb = map_family(name, cat)
    seed = int(hashlib.md5(name.encode("utf-8")).hexdigest()[:12], 16)
    rng = random.Random(seed)
    s = Spr()
    SHAPES[shape](s, rng, name, **kw)
    return s.image(), shape, fb


def contact_sheet(items, path, scale=3, cols=12):
    cell_w, cell_h = 32 * scale + 44, 32 * scale + 34
    rows = (len(items) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), hx("12141c"))
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 10)
    except Exception:
        font = ImageFont.load_default()
    for i, (name, im, shape) in enumerate(items):
        cx, cy = (i % cols) * cell_w, (i // cols) * cell_h
        d.rectangle([cx + 20, cy + 4, cx + 20 + 32 * scale - 1, cy + 4 + 32 * scale - 1], fill=hx("1c2030"))
        big = im.resize((32 * scale, 32 * scale), Image.NEAREST)
        sheet.alpha_composite(big, (cx + 20, cy + 4))
        words = name.split()
        lines, cur = [], ""
        for w in words:
            if len(cur) + len(w) + 1 > 22:
                lines.append(cur)
                cur = w
            else:
                cur = (cur + " " + w).strip()
        lines.append(cur)
        for j, ln in enumerate(lines[:2]):
            tw = d.textlength(ln, font=font)
            d.text((cx + (cell_w - tw) / 2, cy + 32 * scale + 6 + j * 11), ln, fill=hx("c8ccd8"), font=font)
    sheet.save(path)
    return sheet.size


def main():
    args = sys.argv[1:]
    sheet_path = "/tmp/item_contact_sheet.png"
    scale = 1
    only = None
    if "--sheet" in args:
        sheet_path = args[args.index("--sheet") + 1]
    if "--scale" in args:
        scale = int(args[args.index("--scale") + 1])
    if "--only" in args:
        only = args[args.index("--only") + 1].lower()
    fams = load_families()
    print("families found:", len(fams))
    os.makedirs(OUTDIR, exist_ok=True)
    used = {}
    art = []
    items = []
    fallbacks = []
    shapes_used = set()
    for name, cat in fams:
        slug = slugify(name)
        if slug in used and used[slug] != name:
            slug = slug + "_" + slugify(cat)   # e.g. "8-bit Home Computer" exists in two categories
        used[slug] = name
        im, shape, fb = render(name, cat)
        shapes_used.add(shape)
        if fb or shape == "generic":
            fallbacks.append((name, cat, shape))
        if only and only not in name.lower() and only != shape:
            continue
        out = im if scale == 1 else im.resize((32 * scale, 32 * scale), Image.NEAREST)
        out.save(os.path.join(OUTDIR, slug + ".png"))
        art.append((name, "res://art/items/%s.png" % slug))
        items.append((name, im, shape))
    if not only:
        with open(GD_OUT, "w", encoding="utf-8") as f:
            f.write("extends RefCounted\n")
            f.write("# GENERATED by tools/gen_item_sprites.py - do not edit by hand.\n")
            f.write("# Item family name -> 32x32 pixel-art sprite (draw with TEXTURE_FILTER_NEAREST).\n")
            f.write("const ITEM_ART = {\n")
            for name, p in art:
                f.write('\t"%s": "%s",\n' % (name.replace("\\", "\\\\").replace('"', '\\"'), p))
            f.write("}\n")
    print("sprites written:", len(art), "| base shapes used:", len(shapes_used))
    print("generic / category fallbacks:", len(fallbacks))
    for n, c, sh in fallbacks:
        print("  FALLBACK:", n, "(%s) ->" % c, sh)
    size = contact_sheet(items, sheet_path)
    print("contact sheet:", sheet_path, size)


if __name__ == "__main__":
    main()
