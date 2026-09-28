#!/usr/bin/env python3
"""Procedural pixel-art generator for Car Boot Reseller.

Generates:
  art/premises_0..4.png   (160x72 drawn, x4 -> 640x288)
  art/vehicle_0..4.png    (160x72 drawn, x4 -> 640x288)
  cat_icons/cat_trading_cards.png (64x64 drawn, x8 -> 512x512, RGBA)

Run from anywhere:  python3 tools/gen_art.py
Requires Pillow.  Deterministic (fixed RNG seeds).
"""
import os
import random
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "art")
ICONS = os.path.join(ROOT, "cat_icons")

W, H = 160, 72
SCALE = 4


def hx(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


# ---------------------------------------------------------------- palette
OUT = hx("141018")        # outline
NIGHT = [hx("0a0e1f"), hx("111833"), hx("1a2447"), hx("26305a"), hx("3a3a6a")]
DUSK_GLOW = hx("5a3f6e")
DAWN = [hx("111a36"), hx("1f2c55"), hx("3b3f73"), hx("6b5286"), hx("b7727f"), hx("e8a57a")]
STAR = hx("cfd8ff")
STAR2 = hx("7d88b8")
MOON = hx("f2eccf")

WARM = hx("ffd27a")
WARM2 = hx("f5a847")
WARM3 = hx("b8672d")
WARM_DIM = hx("5e3a2a")

GOLD = hx("e0b04a")
TEAL = hx("2fb3a6")
TEAL_D = hx("1d6e6a")
RED = hx("c8413a")
RED_D = hx("7f2530")
GREEN = hx("4f9a4a")
GREEN_D = hx("2d5a36")
BLUE = hx("3f6fc4")
BLUE_D = hx("27417a")
CREAM = hx("efe3c4")
CREAM_D = hx("bfae8a")
CARD = hx("b88a55")       # cardboard
CARD_D = hx("8a6238")
CARD_L = hx("d4a86c")
SKIN = hx("e2b08a")
SKIN_D = hx("b77e5e")
HAIR = hx("4a2e22")

GREY0 = hx("1c1d26")
GREY1 = hx("2c2e3a")
GREY2 = hx("444757")
GREY3 = hx("646878")
GREY4 = hx("8d91a0")
GREY5 = hx("b8bcc8")
WHITE = hx("e6e8ee")

BRICK = hx("6a3a34")
BRICK_D = hx("4c2828")
BRICK_L = hx("80493e")

BAYER4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


class Canvas:
    def __init__(self, w=W, h=H, bg=(0, 0, 0, 0)):
        self.w, self.h = w, h
        self.im = Image.new("RGBA", (w, h), bg)
        self.px = self.im.load()

    def p(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h and c is not None:
            if len(c) == 4 and c[3] < 255:
                # alpha blend
                r, g, b, a = self.px[x, y]
                t = c[3] / 255.0
                self.px[x, y] = (int(r + (c[0] - r) * t), int(g + (c[1] - g) * t),
                                 int(b + (c[2] - b) * t), max(a, c[3]))
            else:
                self.px[x, y] = c

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[x, y]
        return None

    def rect(self, x0, y0, x1, y1, c):
        """Filled rect, inclusive coords."""
        for y in range(max(0, y0), min(self.h, y1 + 1)):
            for x in range(max(0, x0), min(self.w, x1 + 1)):
                self.p(x, y, c)

    def box(self, x0, y0, x1, y1, fill, line=OUT):
        self.rect(x0, y0, x1, y1, line)
        if x1 - x0 >= 2 and y1 - y0 >= 2:
            self.rect(x0 + 1, y0 + 1, x1 - 1, y1 - 1, fill)

    def hline(self, x0, x1, y, c):
        self.rect(min(x0, x1), y, max(x0, x1), y, c)

    def vline(self, x, y0, y1, c):
        self.rect(x, min(y0, y1), x, max(y0, y1), c)

    def line(self, x0, y0, x1, y1, c):
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx + dy
        while True:
            self.p(x0, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def disc(self, cx, cy, r, c):
        for y in range(int(cy - r - 1), int(cy + r + 2)):
            for x in range(int(cx - r - 1), int(cx + r + 2)):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r + 0.3:
                    self.p(x, y, c)

    def vgrad(self, x0, y0, x1, y1, cols, dither=True):
        """Vertical gradient through cols with Bayer dithering."""
        hgt = max(1, y1 - y0)
        n = len(cols) - 1
        for y in range(y0, y1 + 1):
            t = (y - y0) / hgt * n
            i = min(int(t), n - 1)
            f = t - i
            for x in range(x0, x1 + 1):
                th = (BAYER4[y % 4][x % 4] + 0.5) / 16.0
                c = cols[i + 1] if (dither and f > th) or (not dither and f > .5) else cols[i]
                self.p(x, y, c)

    def glow(self, cx, cy, r, c, strength=0.5, clip=None):
        """Soft radial light as concentric banded alpha rings (pixel-art style).
        clip=(x0,y0,x1,y1) limits the area affected."""
        x0, y0, x1, y1 = clip if clip else (0, 0, self.w - 1, self.h - 1)
        for y in range(max(y0, int(cy - r)), min(y1, int(cy + r)) + 1):
            for x in range(max(x0, int(cx - r)), min(x1, int(cx + r)) + 1):
                d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 / r
                if d < 1:
                    a = (1 - d) * strength
                    a = int(a * 5 + 0.5) / 5.0          # band into 5 steps
                    if a > 0:
                        self.p(x, y, c[:3] + (int(255 * min(0.85, a)),))

    def poly(self, pts, c):
        """Scanline fill polygon."""
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            xs = []
            n = len(pts)
            for i in range(n):
                (xa, ya), (xb, yb) = pts[i], pts[(i + 1) % n]
                if (ya <= y < yb) or (yb <= y < ya):
                    xs.append(xa + (y - ya) * (xb - xa) / (yb - ya))
            xs.sort()
            for j in range(0, len(xs) - 1, 2):
                for x in range(int(round(xs[j])), int(round(xs[j + 1])) + 1):
                    self.p(x, y, c)

    def save(self, path, scale):
        big = self.im.resize((self.w * scale, self.h * scale), Image.NEAREST)
        big.save(path)
        print("wrote", os.path.relpath(path, ROOT), big.size)


# tiny 3x5 font (only letters needed)
FONT = {
    "R": ["110", "101", "110", "101", "101"],
    "E": ["111", "100", "110", "100", "111"],
    "S": ["011", "100", "010", "001", "110"],
    "L": ["100", "100", "100", "100", "111"],
    "O": ["010", "101", "101", "101", "010"],
    "P": ["110", "101", "110", "100", "100"],
    "N": ["101", "111", "111", "101", "101"],
    " ": ["000", "000", "000", "000", "000"],
}


def text(cv, x, y, s, c):
    for ch in s:
        g = FONT[ch]
        for j, row in enumerate(g):
            for i, b in enumerate(row):
                if b == "1":
                    cv.p(x + i, y + j, c)
        x += 4


# ------------------------------------------------------------ shared bits
def night_sky(cv, y1, seed, moon=None, glow=True):
    cols = NIGHT[:] + ([DUSK_GLOW] if glow else [])
    cv.vgrad(0, 0, cv.w - 1, y1, cols)
    rnd = random.Random(seed)
    for _ in range(38):
        x, y = rnd.randrange(cv.w), rnd.randrange(0, max(1, int(y1 * 0.65)))
        cv.p(x, y, STAR if rnd.random() < 0.3 else STAR2)
    if moon:
        mx, my = moon
        cv.glow(mx, my, 9, hx("8a90c0"), 0.35)
        cv.disc(mx, my, 3.2, MOON)
        cv.disc(mx + 1.6, my - 1, 2.6, None)  # no-op placeholder
        cv.p(mx - 1, my - 1, hx("d8d0b0"))
        cv.p(mx + 1, my + 1, hx("d8d0b0"))


def dawn_sky(cv, y1, seed):
    cv.vgrad(0, 0, cv.w - 1, y1, DAWN)
    rnd = random.Random(seed)
    for _ in range(18):
        x, y = rnd.randrange(cv.w), rnd.randrange(0, int(y1 * 0.35))
        cv.p(x, y, STAR2)
    # low sun glow near horizon
    cv.glow(28, y1 - 4, 20, hx("ffb070"), 0.35)
    cv.disc(28, y1 - 5, 3.6, hx("ffe2a8"))
    cv.disc(28, y1 - 5, 2.4, hx("fff4d8"))
    # a few wispy clouds
    for cx, cy, ln in ((70, 14, 18), (118, 22, 24), (40, 26, 14)):
        cv.hline(cx, cx + ln, cy, hx("7a5a8a"))
        cv.hline(cx + 3, cx + ln - 4, cy - 1, hx("8e6a92"))
        cv.hline(cx + 2, cx + ln + 2, cy + 1, hx("5b4a7a"))


def boot_field(cv, horizon, seed):
    """Grass field with distant gazebos & cars at dawn."""
    # distant tree line
    rnd = random.Random(seed)
    for x in range(cv.w):
        h = 2 + int(2 * abs(((x * 7) % 11) - 5) / 5) + rnd.randrange(2)
        cv.vline(x, horizon - h, horizon, hx("1e2a3a"))
    # field
    cv.vgrad(0, horizon, cv.w - 1, cv.h - 1,
             [hx("2c4a3a"), hx("355c3e"), hx("3f6b40"), hx("4a7a44")])
    # gazebos (distant) and tiny cars
    def haze(c, t=0.4, to=hx("3b4a6a")):
        return tuple(int(c[i] + (to[i] - c[i]) * t) for i in range(3)) + (255,)

    gz = [(8, hx("c8413a")), (46, hx("e6e8ee")), (98, hx("2fb3a6")), (132, hx("e0b04a"))]
    for gx, gc in gz:
        gc = haze(gc)
        y = horizon + 3
        cv.poly([(gx, y), (gx + 5, y - 4), (gx + 10, y)], gc)
        cv.hline(gx, gx + 10, y, haze(OUT))
        cv.vline(gx + 1, y, y + 4, haze(GREY1))
        cv.vline(gx + 9, y, y + 4, haze(GREY1))
        cv.rect(gx + 2, y + 2, gx + 8, y + 3, hx("5a4a3a"))  # table
    for cx, cc in ((26, hx("5a6a8a")), (62, hx("7a3a3a")), (80, hx("8a8a90")), (116, hx("3a5a7a"))):
        cc = haze(cc, 0.3)
        y = horizon + 5
        cv.rect(cx, y - 2, cx + 7, y, cc)
        cv.rect(cx + 2, y - 3, cx + 5, y - 3, cc)
        cv.p(cx + 1, y + 1, OUT)
        cv.p(cx + 6, y + 1, OUT)
    # grass tufts
    for _ in range(120):
        x = rnd.randrange(cv.w)
        y = rnd.randrange(horizon + 8, cv.h)
        cv.p(x, y, hx("5c8c4c") if rnd.random() < .6 else hx("2a4632"))
        if rnd.random() < 0.4:
            cv.p(x, y - 1, hx("6a9c56"))
    # dew / light on grass near sun
    cv.glow(28, horizon + 2, 20, hx("e8c68a"), 0.2, clip=(0, horizon + 1, cv.w - 1, cv.h - 1))


def box_item(cv, x, y, w, h, tape=True, col=CARD):
    cv.box(x, y, x + w - 1, y + h - 1, col)
    if w > 3:
        cv.hline(x + 1, x + w - 2, y + 1, CARD_L if col == CARD else col)
    if tape and w >= 5:
        cv.vline(x + w // 2, y + 1, y + h - 2, CREAM_D)


def wheel(cv, cx, cy, r=3.5):
    cv.disc(cx, cy, r, OUT)
    cv.disc(cx, cy, r - 1.2, GREY2)
    cv.disc(cx, cy, max(0.6, r - 2.4), GREY4)


# ============================================================== PREMISES
def premises_box_room():
    cv = Canvas()
    # wallpaper: muted plum with dithered vertical stripes
    cv.vgrad(0, 0, W - 1, 58, [hx("2a2140"), hx("33294d"), hx("3c2f55")])
    for x in range(0, W, 6):
        for y in range(0, 58):
            if (y + x) % 2 == 0:
                cv.p(x, y, hx("43365e"))
    # skirting and floorboards
    cv.rect(0, 57, W - 1, 58, hx("5a4a5a"))
    cv.hline(0, W - 1, 56, OUT)
    cv.vgrad(0, 59, W - 1, H - 1, [hx("5a3a2a"), hx("4a2e22"), hx("3a2218")])
    for y in (62, 66, 70):
        cv.hline(0, W - 1, y, hx("32201a"))
    for i, y in enumerate((59, 63, 67)):
        for x in range(i * 7 % 23, W, 23):
            cv.vline(x, y, y + 2, hx("32201a"))

    # window with night sky
    wx0, wy0, wx1, wy1 = 62, 8, 98, 38
    cv.rect(wx0 - 2, wy0 - 2, wx1 + 2, wy1 + 2, OUT)
    cv.rect(wx0 - 1, wy0 - 1, wx1 + 1, wy1 + 1, hx("d8d2c0"))
    sub = Canvas(wx1 - wx0 + 1, wy1 - wy0 + 1)
    night_sky(sub, sub.h - 1, 7, moon=(26, 8))
    # distant rooftops silhouette in window
    for x in range(sub.w):
        hh = 5 + (3 if 4 <= x % 14 <= 10 else 0)
        sub.vline(x, sub.h - hh, sub.h - 1, hx("0c0f1c"))
        if x % 14 == 7 and sub.h - hh - 2 >= 0:
            sub.vline(x, sub.h - hh - 3, sub.h - hh, hx("0c0f1c"))
    sub.p(5, sub.h - 3, WARM)
    sub.p(20, sub.h - 6, WARM2)
    cv.im.alpha_composite(sub.im, (wx0, wy0))
    cv.vline((wx0 + wx1) // 2, wy0, wy1, hx("d8d2c0"))
    cv.hline(wx0, wx1, (wy0 + wy1) // 2, hx("d8d2c0"))
    # sill + curtains
    cv.box(wx0 - 4, wy1 + 2, wx1 + 4, wy1 + 4, hx("d8d2c0"))
    for cx in (wx0 - 8, wx1 + 2):
        cv.box(cx, wy0 - 4, cx + 6, wy1 + 1, TEAL_D)
        for y in range(wy0 - 3, wy1 + 1):
            cv.p(cx + 2, y, TEAL)
            if y % 3 == 0:
                cv.p(cx + 4, y, hx("165450"))
    cv.hline(wx0 - 10, wx1 + 10, wy0 - 5, OUT)

    # bed edge on the left
    cv.box(-2, 38, 44, 56, hx("3d5a8a"))          # duvet
    for x in range(2, 44, 6):
        cv.vline(x, 40, 55, hx("33507c"))
    cv.box(-2, 34, 20, 42, CREAM)                 # pillow
    cv.hline(0, 18, 36, WHITE)
    cv.box(-2, 26, 3, 58, hx("6a4a36"))            # headboard post
    cv.box(40, 44, 46, 60, hx("6a4a36"))           # footboard
    cv.box(-2, 54, 46, 58, hx("5a3a2a"))           # bed base
    # clothes pile on bed
    cv.box(26, 35, 37, 39, hx("7a3a52"))
    cv.box(29, 33, 35, 36, hx("c8a24a"))

    # bedside table + lamp
    cv.box(48, 44, 60, 58, hx("7a5238"))
    cv.hline(49, 59, 50, hx("5a3a2a"))
    cv.p(54, 47, GOLD)
    cv.glow(54, 34, 24, hx("ffc060"), 0.32, clip=(0, 0, 60, 56))
    cv.box(52, 38, 56, 44, GREY2)                  # lamp base
    cv.poly([(49, 38), (51, 30), (57, 30), (59, 38)], WARM2)
    cv.hline(49, 59, 38, OUT)
    cv.line(51, 30, 49, 38, OUT)
    cv.line(57, 30, 59, 38, OUT)
    cv.hline(51, 57, 30, OUT)
    cv.hline(51, 57, 37, WARM)
    # light pool on floor
    cv.glow(54, 59, 18, hx("ffb050"), 0.3, clip=(0, 57, W - 1, H - 1))

    # wobbly shelf w/ boxes on right wall
    cv.line(104, 22, 150, 25, OUT)
    cv.line(104, 23, 150, 26, hx("8a6238"))
    cv.line(104, 24, 150, 27, OUT)
    cv.box(110, 25, 112, 30, GREY3)                # bracket
    cv.box(142, 27, 144, 32, GREY3)
    box_item(cv, 106, 13, 10, 10)
    box_item(cv, 117, 16, 8, 8)
    box_item(cv, 126, 11, 12, 14, col=hx("a07a4a"))
    box_item(cv, 139, 18, 9, 8)
    cv.box(129, 7, 136, 12, hx("3a6aa0"))          # small tin
    # second shelf
    cv.hline(106, 148, 40, OUT)
    cv.hline(106, 148, 41, hx("8a6238"))
    cv.hline(106, 148, 42, OUT)
    for i, c in enumerate((RED, TEAL, GOLD, GREEN, BLUE, RED_D, CREAM)):
        cv.box(108 + i * 4, 32, 111 + i * 4, 39, c)   # books / vinyl
    box_item(cv, 138, 31, 10, 9)
    # floor boxes stacked
    box_item(cv, 100, 46, 16, 12)
    box_item(cv, 117, 49, 14, 9)
    box_item(cv, 104, 38, 11, 8, col=hx("a07a4a"))
    box_item(cv, 134, 44, 20, 14)
    box_item(cv, 138, 36, 12, 8)
    # stuff poking out
    cv.box(122, 45, 124, 49, TEAL)
    cv.box(126, 46, 128, 49, GOLD)
    return cv


def premises_garage():
    cv = Canvas()
    night_sky(cv, 44, 11, moon=(136, 10))
    # far houses silhouette
    for x in range(W):
        hh = 8 + (4 if (x // 12) % 2 else 0)
        cv.vline(x, 44 - hh, 44, hx("10152a"))
    for x in range(5, W, 24):
        cv.rect(x, 38, x + 1, 39, WARM_DIM)
    # tarmac
    cv.vgrad(0, 55, W - 1, H - 1, [hx("24242e"), hx("2c2c38"), hx("22222c")])
    rnd = random.Random(3)
    for _ in range(90):
        cv.p(rnd.randrange(W), rnd.randrange(56, H), hx("363644"))
    # neighbour garages (closed), then ours
    for gx, col in ((0, hx("3a5470")), (104, hx("5a3a4a"))):
        cv.box(gx, 22, gx + 55, 56, BRICK)
        cv.box(gx + 8, 30, gx + 47, 56, col)
        for y in range(32, 56, 3):
            cv.hline(gx + 9, gx + 46, y, OUT[:3] + (90,))
        cv.rect(gx - 1, 19, gx + 56, 22, GREY3)
        cv.hline(gx - 1, gx + 56, 19, OUT)
    # our garage (centre)
    gx0, gx1 = 52, 108
    cv.box(gx0, 18, gx1, 56, BRICK_L)
    cv.rect(gx0 - 2, 14, gx1 + 2, 18, GREY4)
    cv.hline(gx0 - 2, gx1 + 2, 14, OUT)
    cv.hline(gx0 - 2, gx1 + 2, 18, OUT)
    # brick texture on all brick
    for y in range(20, 56, 3):
        for x in range(0, W):
            c = cv.get(x, y)
            if c in (BRICK, BRICK_L):
                cv.p(x, y, BRICK_D)
    # interior (lit)
    ix0, ix1, iy0, iy1 = gx0 + 7, gx1 - 7, 25, 56
    cv.rect(ix0, iy0, ix1, iy1, hx("6e6450"))
    cv.vgrad(ix0, iy0, ix1, iy1, [hx("8a7c5c"), hx("6e6450"), hx("50483c")])
    # back wall pegboard
    for y in range(iy0 + 12, iy0 + 22, 2):
        for x in range(ix0 + 2, ix0 + 20, 2):
            cv.p(x, y, hx("5a5040"))
    cv.line(ix0 + 5, iy0 + 13, ix0 + 8, iy0 + 18, GREY3)   # hanging tools
    cv.vline(ix0 + 12, iy0 + 13, iy0 + 19, RED)
    cv.box(ix0 + 15, iy0 + 13, ix0 + 18, iy0 + 16, GREY4)
    # workbench
    cv.box(ix0 + 1, 44, ix0 + 24, 46, hx("8a5a36"))
    cv.vline(ix0 + 3, 47, 55, OUT)
    cv.vline(ix0 + 22, 47, 55, OUT)
    cv.box(ix0 + 4, 40, ix0 + 10, 44, TEAL)       # toolbox
    cv.hline(ix0 + 5, ix0 + 9, 39, OUT)
    cv.box(ix0 + 14, 38, ix0 + 17, 44, hx("4a6aa0"))  # radio / thing
    cv.p(ix0 + 15, 40, GOLD)
    # boxes
    box_item(cv, ix0 + 26, 44, 12, 12)
    box_item(cv, ix0 + 29, 35, 10, 9)
    box_item(cv, ix0 + 30, 29, 7, 6, col=hx("a07a4a"))
    box_item(cv, ix1 - 6, 47, 7, 9)
    cv.box(ix0 + 8, 49, ix0 + 18, 55, hx("3a5a8a"))   # crate under bench
    # half-open up-and-over door (occupies top)
    dy1 = 36
    cv.box(ix0 - 1, iy0 - 1, ix1 + 1, dy1, hx("9aa0aa"))
    for y in range(iy0 + 1, dy1, 2):
        cv.hline(ix0, ix1, y, hx("7a808c"))
    cv.hline(ix0, ix1, dy1 - 1, GREY3)
    cv.box((ix0 + ix1) // 2 - 2, dy1 - 3, (ix0 + ix1) // 2 + 2, dy1 - 1, GREY2)  # handle
    # strip light (under door edge, glowing)
    cv.hline(ix0 + 8, ix1 - 8, dy1 + 1, hx("fffbe6"))
    cv.hline(ix0 + 8, ix1 - 8, dy1 + 2, hx("c8e8f0"))
    cv.glow((ix0 + ix1) // 2, dy1 + 3, 26, hx("f8f0c8"), 0.35, clip=(ix0, dy1 + 1, ix1, 56))
    # door jambs
    cv.vline(ix0 - 1, iy0, 56, OUT)
    cv.vline(ix1 + 1, iy0, 56, OUT)
    # light spill onto tarmac
    for y in range(57, H):
        spread = (y - 56) * 2
        c = hx("5c5646") if y < 61 else (hx("4a473e") if y < 66 else hx("3a3934"))
        for x in range(ix0 - spread, ix1 + spread + 1):
            cv.p(x, y, c)
    cv.hline(0, W - 1, 56, OUT)
    # garage number
    cv.box(gx0 + 2, 20, gx0 + 5, 23, CREAM)
    cv.p(gx0 + 3, 21, OUT)
    cv.p(gx0 + 4, 22, OUT)
    # wheelie bin
    cv.box(110, 46, 117, 56, hx("2d5a36"))
    cv.box(109, 44, 118, 46, hx("244a2c"))
    cv.p(111, 57, OUT)
    cv.p(116, 57, OUT)
    return cv


def premises_industrial():
    cv = Canvas()
    night_sky(cv, 40, 21, moon=(20, 9))
    for x in range(W):
        if x % 30 < 18:
            cv.vline(x, 32, 40, hx("10152a"))
    cv.rect(96, 18, 99, 40, hx("10152a"))           # chimney/stack
    cv.p(97, 17, hx("c8413a"))                      # aviation light
    # ground: concrete apron + road
    cv.vgrad(0, 58, W - 1, H - 1, [hx("2e2e38"), hx("33333e"), hx("262630")])
    cv.hline(0, W - 1, 58, OUT)
    for x in range(0, W, 12):
        cv.hline(x, x + 5, 67, hx("c8b050"))          # road line
    # unit body
    ux0, ux1 = 4, 128
    cv.poly([(ux0 - 2, 24), ((ux0 + ux1) // 2, 16), (ux1 + 2, 24)], GREY3)
    cv.line(ux0 - 2, 24, (ux0 + ux1) // 2, 16, OUT)
    cv.line((ux0 + ux1) // 2, 16, ux1 + 2, 24, OUT)
    cv.box(ux0, 24, ux1, 58, hx("46607a"))
    for x in range(ux0 + 1, ux1):
        c = [hx("52708c"), hx("46607a"), hx("3a5068")][x % 3]
        cv.vline(x, 25, 57, c)
    cv.hline(ux0, ux1, 24, OUT)
    cv.rect(ux0, 25, ux1, 26, hx("2a3a4c"))           # fascia
    # unit number strip
    cv.box(ux0 + 4, 28, ux0 + 22, 33, CREAM)
    text(cv, ux0 + 6, 29, "S", TEAL_D)
    cv.rect(ux0 + 10, 29, ux0 + 20, 32, TEAL)
    # roller shutter opening
    sx0, sx1, sy0 = 30, 92, 30
    cv.rect(sx0, sy0, sx1, 57, hx("6e6650"))
    cv.vgrad(sx0, sy0, sx1, 57, [hx("8c8062"), hx("746a52"), hx("5a5242")])
    # shutter rolled up at top
    cv.box(sx0 - 2, sy0 - 4, sx1 + 2, sy0 + 1, GREY4)
    cv.hline(sx0 - 1, sx1 + 1, sy0 - 2, GREY5)
    cv.hline(sx0 - 1, sx1 + 1, sy0, GREY3)
    cv.vline(sx0 - 1, sy0, 57, OUT)
    cv.vline(sx1 + 1, sy0, 57, OUT)
    # racking (3 bays)
    for bx in (sx0 + 3, sx0 + 23, sx0 + 43):
        cv.vline(bx, sy0 + 3, 57, hx("2f6fb0"))
        cv.vline(bx + 17, sy0 + 3, 57, hx("2f6fb0"))
        for sy in (sy0 + 10, sy0 + 18, sy0 + 26):
            cv.hline(bx, bx + 17, sy, hx("e07a2a"))
    rnd = random.Random(5)
    stock_cols = [CARD, CARD_L, hx("a07a4a"), TEAL, RED, GOLD, BLUE, CREAM, GREEN]
    for bx in (sx0 + 4, sx0 + 24, sx0 + 44):
        for sy in (sy0 + 10, sy0 + 18, sy0 + 26):
            x = bx
            while x < bx + 15:
                w = rnd.randrange(3, 7)
                h = rnd.randrange(3, 7)
                if x + w > bx + 16:
                    break
                c = rnd.choice(stock_cols)
                if c in (CARD, CARD_L, hx("a07a4a")):
                    box_item(cv, x, sy - h, w, h, tape=w >= 5, col=c)
                else:
                    cv.box(x, sy - h, x + w - 1, sy - 1, c)
                x += w
    box_item(cv, sx0 + 8, 49, 12, 8)
    box_item(cv, sx0 + 34, 51, 9, 6)
    # inside light
    cv.glow((sx0 + sx1) // 2, sy0 + 2, 34, hx("fff0c0"), 0.3, clip=(sx0, sy0 + 1, sx1, 57))
    cv.hline(sx0 + 10, sx1 - 10, sy0 + 2, hx("fffbe6"))
    # light spill
    for y in range(59, 66):
        c = hx("4a4638") if y < 62 else hx("3c3a34")
        for x in range(sx0 - (y - 58) * 2, sx1 + (y - 58) * 2):
            cv.p(x, y, c)
    # personnel door + kettle sign
    cv.box(100, 38, 112, 58, hx("2a3a4c"))
    cv.box(103, 41, 109, 48, hx("e8c070"))            # lit door glass
    cv.p(110, 49, GOLD)
    cv.box(113, 32, 127, 46, CREAM)                    # sign
    k = TEAL_D
    cv.rect(119, 37, 121, 37, k)                       # lid
    cv.p(120, 36, k)                                   # knob
    cv.rect(118, 38, 122, 38, k)
    cv.rect(117, 39, 123, 43, k)                       # body
    cv.rect(116, 44, 124, 44, k)                       # base
    cv.p(116, 40, k)                                   # spout
    cv.p(115, 39, k)
    cv.p(124, 38, k)                                   # handle
    cv.vline(125, 39, 42, k)
    cv.p(124, 43, k)
    cv.p(119, 40, TEAL)                                # shine
    cv.p(119, 41, TEAL)
    cv.p(114, 37, GREY4)                               # steam
    cv.p(115, 36, GREY4)
    cv.p(114, 35, GREY4)
    cv.glow(120, 30, 12, WARM, 0.3, clip=(110, 28, 130, 46))
    cv.box(118, 29, 122, 31, GREY2)                    # sign lamp
    # parked car (hatchback) right side
    car(cv, 128, 58, hx("7a3a3a"), hx("5a2a2e"))
    return cv


def car(cv, x, gy, body, body_d):
    """Small generic hatchback, facing left, wheels on ground line gy."""
    cv.poly([(x + 2, gy - 6), (x + 5, gy - 7), (x + 9, gy - 12), (x + 21, gy - 12),
             (x + 25, gy - 7), (x + 28, gy - 6), (x + 28, gy - 2), (x + 1, gy - 2)], OUT)
    cv.poly([(x + 3, gy - 6), (x + 6, gy - 7), (x + 10, gy - 11), (x + 20, gy - 11),
             (x + 24, gy - 7), (x + 27, gy - 6), (x + 27, gy - 3), (x + 2, gy - 3)], body)
    cv.poly([(x + 7, gy - 7), (x + 10, gy - 10), (x + 15, gy - 10), (x + 15, gy - 7)], hx("7890b0"))
    cv.poly([(x + 17, gy - 7), (x + 17, gy - 10), (x + 20, gy - 10), (x + 23, gy - 7)], hx("7890b0"))
    cv.hline(x + 3, x + 27, gy - 4, body_d)
    cv.p(x + 2, gy - 5, WARM)
    cv.p(x + 27, gy - 5, RED)
    wheel(cv, x + 7, gy - 1, 2.6)
    wheel(cv, x + 22, gy - 1, 2.6)


def premises_shop():
    cv = Canvas()
    night_sky(cv, 34, 31, moon=(150, 8))
    # road + kerb + pavement
    cv.vgrad(0, 58, W - 1, 63, [hx("6a6a74"), hx("5a5a66")])
    for x in range(0, W, 5):
        cv.vline(x, 58, 63, hx("4c4c58"))
    cv.hline(0, W - 1, 57, OUT)
    cv.rect(0, 64, W - 1, 65, GREY4)
    cv.hline(0, W - 1, 66, OUT)
    cv.vgrad(0, 67, W - 1, H - 1, [hx("26262e"), hx("1e1e26")])
    # neighbouring terraced buildings
    cv.box(-1, 12, 22, 57, hx("4a3a4a"))
    cv.box(3, 18, 18, 30, hx("1e2238"))
    cv.box(3, 38, 18, 56, hx("1e2238"))
    cv.box(126, 16, 160, 57, hx("3a4a44"))
    cv.box(131, 22, 150, 34, hx("e8b060"))                  # lit upstairs window
    cv.vline(140, 23, 33, hx("3a4a44"))
    cv.box(131, 40, 154, 56, hx("262a36"))                  # shuttered shop
    for y in range(42, 56, 2):
        cv.hline(132, 153, y, GREY2)
    # our shop building
    bx0, bx1 = 22, 126
    cv.box(bx0, 6, bx1, 57, BRICK)
    for y in range(8, 30, 3):
        for x in range(bx0 + 1, bx1):
            if (x + (y // 3) * 3) % 8 == 0:
                cv.p(x, y, BRICK_D)
            if y % 3 == 2:
                pass
        cv.hline(bx0 + 1, bx1 - 1, y, BRICK_D)
    cv.rect(bx0 - 2, 4, bx1 + 2, 6, GREY4)                  # parapet
    cv.hline(bx0 - 2, bx1 + 2, 4, OUT)
    # upstairs sash windows
    for wx in (36, 66, 96):
        cv.box(wx - 1, 9, wx + 16, 25, CREAM)
        cv.rect(wx, 10, wx + 15, 24, hx("1a2040"))
        if wx == 66:
            cv.rect(wx, 10, wx + 15, 24, hx("d89a50"))
            cv.rect(wx + 2, 12, wx + 13, 17, hx("f0c070"))
        cv.hline(wx, wx + 15, 17, CREAM)
        cv.vline(wx + 7, 10, 24, CREAM)
        cv.hline(wx - 2, wx + 17, 26, CREAM_D)
    # fascia sign board
    cv.box(bx0 + 2, 28, bx1 - 2, 35, hx("1b3a3c"))
    cv.hline(bx0 + 3, bx1 - 3, 29, TEAL_D)
    text(cv, (bx0 + bx1) // 2 - 16, 30, "RESELLER", GOLD)
    cv.p(bx0 + 6, 31, GOLD)
    cv.p(bx1 - 6, 31, GOLD)
    # striped awning
    ay0, ay1 = 36, 41
    cv.poly([(bx0 + 2, ay0), (bx1 - 2, ay0), (bx1 + 2, ay1), (bx0 - 2, ay1)], OUT)
    for x in range(bx0 - 1, bx1 + 2):
        c = TEAL if (x // 4) % 2 == 0 else CREAM
        for y in range(ay0 + 1, ay1):
            lx = bx0 + 2 - (y - ay0) * 4 / (ay1 - ay0)
            rx = bx1 - 2 + (y - ay0) * 4 / (ay1 - ay0)
            if lx <= x <= rx:
                cv.p(x, y, c)
    for x in range(bx0 - 2, bx1 + 3):          # scalloped edge
        cv.p(x, ay1, OUT)
        if (x // 4) % 2 == 0:
            cv.p(x, ay1 + 1, TEAL_D)
    # shop window
    wx0, wx1, wy0, wy1 = bx0 + 4, 96, 43, 55
    cv.box(wx0 - 1, wy0 - 1, wx1 + 1, wy1 + 2, hx("2a2020"))
    cv.vgrad(wx0, wy0, wx1, wy1, [hx("f8dc98"), hx("f0c070"), hx("d89a50")])
    cv.rect(wx0, wy1 - 1, wx1, wy1, hx("7a3a52"))           # display plinth cloth
    # display goods
    cv.box(wx0 + 3, 46, wx0 + 5, wy1 - 2, GREY2)             # standard lamp
    cv.poly([(wx0 + 1, 46), (wx0 + 3, 43), (wx0 + 5, 43), (wx0 + 7, 46)], RED)
    cv.box(wx0 + 10, 48, wx0 + 20, 53, hx("6a4028"))         # vintage radio
    cv.rect(wx0 + 11, 49, wx0 + 15, 52, CREAM_D)
    cv.p(wx0 + 17, 50, GOLD)
    cv.p(wx0 + 19, 50, GOLD)
    cv.box(wx0 + 24, 47, wx0 + 28, 53, TEAL)                 # vase
    cv.box(wx0 + 25, 45, wx0 + 27, 47, TEAL_D)
    cv.disc(wx0 + 35, 50, 3.2, OUT)                          # vinyl record
    cv.disc(wx0 + 35, 50, 2.2, GREY1)
    cv.p(wx0 + 35, 50, RED)
    cv.box(wx0 + 41, 46, wx0 + 48, 53, hx("8a5a36"))         # picture frame
    cv.rect(wx0 + 43, 48, wx0 + 46, 51, hx("4f9a8a"))
    cv.box(wx0 + 52, 49, wx0 + 57, 53, hx("c8914a"))         # teddy
    cv.disc(wx0 + 54.5, 47.5, 2, hx("c8914a"))
    cv.p(wx0 + 53, 46, OUT)
    cv.p(wx0 + 56, 46, OUT)
    cv.box(wx0 + 61, 50, wx0 + 67, 53, GOLD)                 # brass thing
    cv.box(wx0 + 63, 47, wx0 + 65, 50, GOLD)
    cv.hline(wx0, wx1, wy0, hx("fff4d8"))                    # glass highlight
    for i in range(4):
        cv.p(wx1 - 6 + i, wy0 + 2 + i, hx("fff4d8"))
    # door
    dx0, dx1 = 100, 121
    cv.box(dx0, 42, dx1, 57, hx("1b3a3c"))
    cv.rect(dx0 + 3, 44, dx1 - 3, 52, hx("e8b868"))
    cv.hline(dx0 + 3, dx1 - 3, 48, hx("1b3a3c"))
    cv.p(dx1 - 3, 54, GOLD)
    cv.box(dx0 + 6, 45, dx1 - 6, 47, CREAM)                  # "open" card
    cv.hline(dx0 + 7, dx1 - 7, 46, RED)
    # light spill on pavement
    cv.glow(60, 58, 34, hx("f8d890"), 0.3, clip=(0, 58, W - 1, 65))
    # lamppost
    lx = 142
    cv.vline(lx, 18, 63, OUT)
    cv.vline(lx + 1, 18, 63, GREY2)
    cv.rect(lx - 1, 60, lx + 2, 63, OUT)
    cv.hline(lx - 6, lx + 1, 17, OUT)
    cv.box(lx - 9, 17, lx - 4, 20, GREY2)
    cv.hline(lx - 8, lx - 5, 20, hx("fff0b8"))
    cv.glow(lx - 6, 22, 8, hx("ffe7a0"), 0.35)
    cv.glow(lx - 6, 62, 12, hx("ffe7a0"), 0.3, clip=(0, 58, W - 1, 65))
    # bin + A-board
    cv.poly([(10, 63), (12, 54), (18, 54), (20, 63)], OUT)
    cv.poly([(11, 62), (13, 55), (17, 55), (19, 62)], hx("2a2a2a"))
    cv.poly([(104, 62), (106, 57), (110, 57), (112, 62)], OUT)
    cv.poly([(105, 61), (107, 58), (109, 58), (111, 61)], hx("2a3438"))
    cv.hline(106, 110, 59, GOLD)
    return cv


def premises_warehouse():
    cv = Canvas()
    night_sky(cv, 30, 41, moon=(12, 7))
    # yard
    cv.vgrad(0, 56, W - 1, H - 1, [hx("303038"), hx("2a2a32"), hx("202028")])
    cv.hline(0, W - 1, 56, OUT)
    for x in range(4, W, 16):
        cv.line(x, 70, x + 6, 58, hx("c8b050"))         # bay markings
    # big shed
    wx0, wx1 = -2, 124
    cv.box(wx0, 12, wx1, 56, hx("5a6470"))
    for x in range(wx0 + 1, wx1):
        if x % 4 == 0:
            cv.vline(x, 13, 55, hx("4a525e"))
    cv.rect(wx0, 12, wx1, 15, hx("2f4a6a"))
    cv.hline(wx0, wx1, 12, OUT)
    cv.hline(wx0, wx1, 16, OUT)
    cv.rect(wx0 + 1, 18, wx1 - 1, 19, TEAL_D)           # colour band
    # roof lights (tiny)
    for x in range(8, 120, 20):
        cv.rect(x, 13, x + 6, 14, hx("8aa0c0"))
    # big doorway
    dx0, dx1, dy0 = 6, 56, 22
    cv.rect(dx0, dy0, dx1, 55, hx("7a7058"))
    cv.vgrad(dx0, dy0, dx1, 55, [hx("a09070"), hx("8a7c60"), hx("6a604c")])
    cv.box(dx0 - 1, dy0 - 3, dx1 + 1, dy0, GREY4)
    cv.vline(dx0 - 1, dy0, 55, OUT)
    cv.vline(dx1 + 1, dy0, 55, OUT)
    # racking inside, receding (two tiers)
    for rx in (dx0 + 1, dx0 + 17, dx0 + 33):
        cv.vline(rx, dy0 + 3, 55, hx("2f6fb0"))
        cv.vline(rx + 16, dy0 + 3, 55, hx("2f6fb0"))
        for ry in (dy0 + 10, dy0 + 19, dy0 + 28):
            cv.hline(rx, rx + 16, ry, hx("e07a2a"))
            cv.hline(rx + 1, rx + 15, ry + 1, hx("6a4a30"))  # pallet
    rnd = random.Random(9)
    for rx in (dx0 + 2, dx0 + 18, dx0 + 34):
        for ry in (dy0 + 10, dy0 + 19, dy0 + 28):
            x = rx
            while x < rx + 13:
                w = rnd.randrange(4, 8)
                if x + w > rx + 15:
                    break
                h = rnd.randrange(4, 8)
                if rnd.random() < 0.8:
                    box_item(cv, x, ry - h, w, h, tape=w >= 5,
                             col=rnd.choice([CARD, CARD_L, hx("a07a4a")]))
                else:
                    cv.box(x, ry - h, x + w - 1, ry - 1, rnd.choice([TEAL, WHITE, BLUE]))
                x += w
    cv.glow((dx0 + dx1) // 2, dy0 + 2, 36, hx("fff0c0"), 0.3, clip=(dx0, dy0, dx1, 55))
    for x in range(dx0 + 6, dx1 - 4, 14):
        cv.hline(x, x + 7, dy0 + 1, hx("fffbe6"))
    # forklift carrying a pallet, on the yard, facing left
    fx, fy = 64, 57
    cv.vline(fx, fy - 24, fy - 1, OUT)                       # mast
    cv.vline(fx + 1, fy - 24, fy - 1, GREY3)
    cv.vline(fx + 2, fy - 24, fy - 1, OUT)
    cv.hline(fx - 9, fx, fy - 6, OUT)                        # forks
    cv.box(fx - 10, fy - 8, fx - 1, fy - 7, hx("8a6a44"))    # pallet
    box_item(cv, fx - 10, fy - 16, 9, 8)
    cv.hline(fx - 9, fx - 2, fy - 13, hx("c8d4dc"))          # shrink-wrap glint
    cv.box(fx + 3, fy - 11, fx + 17, fy - 3, GOLD)           # body
    cv.hline(fx + 4, fx + 16, fy - 10, hx("f4d070"))
    cv.box(fx + 14, fy - 15, fx + 18, fy - 8, hx("a07a2a"))  # counterweight
    cv.vline(fx + 4, fy - 22, fy - 11, OUT)                  # guard posts
    cv.vline(fx + 13, fy - 22, fy - 11, OUT)
    cv.hline(fx + 3, fx + 14, fy - 22, OUT)                  # roof
    cv.hline(fx + 3, fx + 14, fy - 21, GREY2)
    cv.box(fx + 8, fy - 15, fx + 11, fy - 11, GREY1)         # seat
    cv.box(fx + 6, fy - 18, fx + 9, fy - 12, TEAL_D)         # driver body
    cv.box(fx + 6, fy - 20, fx + 8, fy - 18, SKIN)           # driver head
    cv.hline(fx + 6, fx + 8, fy - 21, hx("ff9a3a"))          # hi-vis hat
    cv.p(fx + 14, fy - 23, hx("ff9a3a"))                     # beacon
    wheel(cv, fx + 6, fy - 2, 3)
    wheel(cv, fx + 15, fy - 2, 2.4)
    # loading dock with lorry trailer at right
    cv.box(84, 34, 108, 56, hx("3a3e48"))                    # dock door (closed-ish)
    cv.rect(85, 35, 107, 44, hx("e8c070"))
    for y in range(45, 56, 2):
        cv.hline(85, 107, y, hx("4a505a"))
    cv.box(82, 32, 110, 34, hx("1e2028"))                    # dock seal
    cv.rect(80, 50, 112, 56, hx("222228"))                   # dock well
    cv.hline(80, 112, 50, GOLD)
    for x in range(80, 113, 4):
        cv.rect(x, 50, x + 1, 50, OUT)
    # lorry trailer backed on
    tx = 110
    cv.box(tx, 22, W + 2, 50, hx("d8dce4"))
    for x in range(tx + 3, W, 6):
        cv.vline(x, 23, 49, hx("b8bcc8"))
    cv.rect(tx + 1, 23, W, 25, TEAL)
    cv.box(tx, 50, W + 2, 53, GREY1)
    wheel(cv, tx + 22, 54, 3.5)
    wheel(cv, tx + 31, 54, 3.5)
    cv.p(tx + 1, 48, RED)
    cv.p(tx + 1, 47, hx("ff9a3a"))
    cv.glow(96, 38, 14, WARM, 0.3, clip=(85, 35, 107, 44))
    return cv


# ============================================================== VEHICLES
HORIZON = 44


def vehicle_base(seed):
    cv = Canvas()
    dawn_sky(cv, HORIZON, seed)
    boot_field(cv, HORIZON, seed + 1)
    return cv


def shadow(cv, x0, x1, y):
    for x in range(x0, x1 + 1):
        for yy in (y, y + 1):
            if (x + yy) % 2 == 0 or yy == y:
                cv.p(x, yy, hx("1e3a2a"))


def person(cv, x, gy, coat=hx("3f6fc4"), coat_d=hx("27417a"), hat=RED, hat_d=RED_D):
    """~30px tall person standing, facing right. x = left of body (10 wide)."""
    # legs + boots
    cv.box(x + 2, gy - 10, x + 4, gy - 1, hx("2a2e44"))
    cv.box(x + 5, gy - 10, x + 7, gy - 1, hx("2a2e44"))
    cv.box(x + 1, gy - 2, x + 4, gy, OUT)
    cv.box(x + 5, gy - 2, x + 9, gy, OUT)
    # coat
    cv.box(x, gy - 20, x + 9, gy - 8, coat)
    cv.hline(x + 1, x + 8, gy - 9, coat_d)
    cv.vline(x + 6, gy - 19, gy - 9, coat_d)
    cv.p(x + 7, gy - 16, GOLD)
    cv.p(x + 7, gy - 13, GOLD)
    # head
    cv.box(x + 1, gy - 27, x + 8, gy - 19, SKIN)
    cv.rect(x + 2, gy - 26, x + 3, gy - 22, HAIR)     # hair at back
    cv.p(x + 6, gy - 24, OUT)                          # eye
    cv.p(x + 8, gy - 22, SKIN_D)                       # nose
    cv.p(x + 6, gy - 21, SKIN_D)                       # smile
    # beanie with bobble
    cv.box(x + 1, gy - 30, x + 8, gy - 26, hat)
    cv.hline(x + 1, x + 8, gy - 26, OUT)
    cv.hline(x + 2, x + 7, gy - 27, hat_d)
    cv.p(x + 4, gy - 29, tuple(min(255, k + 40) for k in hat[:3]) + (255,))
    cv.box(x + 3, gy - 32, x + 5, gy - 30, CREAM)
    # scarf
    cv.rect(x + 1, gy - 19, x + 8, gy - 18, TEAL)
    cv.vline(x + 7, gy - 17, gy - 14, TEAL)
    cv.vline(x + 8, gy - 17, gy - 15, TEAL_D)


def v_on_foot():
    cv = vehicle_base(51)
    x, gy = 72, 66
    shadow(cv, x - 4, x + 20, gy)
    person(cv, x, gy)
    # tote hanging at the hip from the shoulder
    bx0, by0, bx1, by1 = x + 3, gy - 12, x + 16, gy - 2
    cv.line(x + 4, gy - 19, bx0 + 1, by0, OUT)          # back strap
    cv.line(x + 5, gy - 19, bx1 - 2, by0, OUT)          # front strap
    cv.line(x + 5, gy - 18, bx1 - 3, by0, CREAM_D)
    # items poking out
    cv.box(bx0 + 2, by0 - 5, bx0 + 5, by0, hx("2a2a2a"))   # record sleeve
    cv.p(bx0 + 3, by0 - 3, RED)
    cv.box(bx0 + 6, by0 - 4, bx0 + 8, by0, TEAL)           # book
    cv.box(bx0 + 9, by0 - 3, bx0 + 11, by0, GOLD)          # brass thing
    cv.box(bx0, by0, bx1, by1, CREAM)
    cv.hline(bx0 + 1, bx1 - 1, by0 + 1, hx("fff4dc"))
    cv.vline(bx1 - 1, by0 + 2, by1 - 1, CREAM_D)
    cv.box(bx0 + 4, by0 + 3, bx0 + 9, by0 + 7, TEAL_D)     # printed motif
    cv.p(bx0 + 6, by0 + 5, GOLD)
    cv.p(bx0 + 7, by0 + 5, GOLD)
    # arm resting on strap
    cv.box(x + 3, gy - 19, x + 6, gy - 11, OUT)
    cv.rect(x + 4, gy - 18, x + 5, gy - 12, hx("27417a"))
    cv.rect(x + 4, gy - 11, x + 6, gy - 10, SKIN)
    # a vase just bought, on the grass
    cv.box(x - 8, gy - 6, x - 4, gy, RED)
    cv.box(x - 7, gy - 8, x - 5, gy - 6, RED)
    cv.hline(x - 7, x - 5, gy - 8, OUT)
    cv.vline(x - 7, gy - 5, gy - 2, hx("e86a5a"))
    return cv


def v_trolley():
    cv = vehicle_base(61)
    x, gy = 56, 66
    shadow(cv, x - 2, x + 42, gy)
    # trolley drawn first (behind arm)
    hxp, hyp = x + 15, gy - 17                         # handle grip
    cv.hline(hxp - 1, hxp + 2, hyp, OUT)
    cv.line(hxp + 1, hyp, x + 26, gy - 3, OUT)         # frame
    cv.line(hxp + 2, hyp, x + 27, gy - 3, GREY4)
    # tartan bag
    bx0, by0, bx1, by1 = x + 21, gy - 22, x + 37, gy - 4
    cv.box(bx0, by0, bx1, by1, RED)
    for y in range(by0 + 1, by1):
        for xx in range(bx0 + 1, bx1):
            c = RED
            vx, hy = (xx - bx0) % 6, (y - by0) % 6
            if vx in (0, 1) and hy in (0, 1):
                c = hx("1a2a3a")
            elif vx in (0, 1) or hy in (0, 1):
                c = hx("2d5a36") if (xx + y) % 2 else RED_D
            elif vx == 4 or hy == 4:
                c = GOLD if (xx + y) % 3 == 0 else RED
            cv.p(xx, y, c)
    # stuff poking out top, then lid
    cv.box(bx0 + 2, by0 - 6, bx0 + 5, by0 - 1, CARD)
    cv.box(bx0 + 10, by0 - 7, bx0 + 12, by0 - 1, TEAL)
    cv.disc(bx0 + 14, by0 - 3, 1.6, GOLD)
    cv.box(bx0 - 1, by0 - 2, bx1 + 1, by0 + 1, hx("1a2a3a"))
    cv.box(bx0 + 7, by0, bx0 + 9, by0 + 4, hx("1a2a3a"))
    cv.p(bx0 + 8, by0 + 3, GOLD)
    cv.hline(bx0 + 2, bx1 + 2, by1 + 1, OUT)           # foot plate
    wheel(cv, x + 26, gy - 2, 3.2)
    wheel(cv, x + 35, gy - 2, 2.2)
    person(cv, x, gy, coat=hx("6a4a7a"), coat_d=hx("4a3056"), hat=TEAL, hat_d=TEAL_D)
    # arm reaching forward to grip
    cv.line(x + 5, gy - 19, hxp - 1, hyp - 1, OUT)
    cv.line(x + 5, gy - 18, hxp - 1, hyp, hx("6a4a7a"))
    cv.line(x + 5, gy - 17, hxp - 1, hyp + 1, hx("6a4a7a"))
    cv.line(x + 5, gy - 16, hxp - 2, hyp + 2, OUT)
    cv.box(hxp - 1, hyp - 1, hxp + 1, hyp + 1, SKIN)
    return cv


def v_estate():
    cv = vehicle_base(71)
    x, gy = 26, 64
    shadow(cv, x, x + 104, gy + 1)
    body, body_d, body_l = hx("5a7a52"), hx("3e5a3a"), hx("7a9a6a")
    # body silhouette (facing left) - boxy estate
    pts = [(x + 2, gy - 12), (x + 8, gy - 14), (x + 22, gy - 15), (x + 32, gy - 27),
           (x + 80, gy - 27), (x + 82, gy - 24), (x + 82, gy - 5), (x + 1, gy - 5)]
    cv.poly(pts, OUT)
    inner = [(x + 3, gy - 11), (x + 9, gy - 13), (x + 23, gy - 14), (x + 33, gy - 26),
             (x + 79, gy - 26), (x + 81, gy - 23), (x + 81, gy - 6), (x + 2, gy - 6)]
    cv.poly(inner, body)
    cv.hline(x + 2, x + 81, gy - 12, body_l)
    cv.hline(x + 2, x + 81, gy - 7, body_d)
    # windows
    cv.poly([(x + 26, gy - 15), (x + 34, gy - 24), (x + 46, gy - 24), (x + 46, gy - 15)], hx("8aa8c8"))
    cv.poly([(x + 49, gy - 15), (x + 49, gy - 24), (x + 62, gy - 24), (x + 62, gy - 15)], hx("8aa8c8"))
    cv.poly([(x + 65, gy - 15), (x + 65, gy - 24), (x + 79, gy - 24), (x + 79, gy - 15)], hx("3a3228"))
    # boxes visible through rear window (load)
    box_item(cv, x + 66, gy - 21, 7, 6)
    box_item(cv, x + 72, gy - 19, 7, 4, col=hx("a07a4a"))
    cv.rect(x + 66, gy - 23, x + 69, gy - 22, TEAL)
    for wx in (x + 47, x + 63):
        cv.vline(wx, gy - 25, gy - 6, OUT)
    cv.vline(x + 48, gy - 15, gy - 6, body_d)
    cv.hline(x + 40, x + 43, gy - 11, OUT)              # door handles
    cv.hline(x + 55, x + 58, gy - 11, OUT)
    cv.line(x + 36, gy - 22, x + 33, gy - 18, hx("b8d0ec"))
    # headlights / bumper
    cv.box(x + 1, gy - 11, x + 4, gy - 9, WARM)
    cv.hline(x, x + 10, gy - 5, GREY3)
    cv.hline(x + 70, x + 83, gy - 5, GREY3)
    # tailgate raised above rear
    tg = [(x + 79, gy - 28), (x + 93, gy - 40), (x + 98, gy - 36), (x + 84, gy - 24)]
    cv.poly(tg, OUT)
    cv.poly([(x + 81, gy - 28), (x + 93, gy - 38), (x + 96, gy - 36), (x + 84, gy - 26)], body)
    cv.poly([(x + 84, gy - 29), (x + 92, gy - 36), (x + 94, gy - 35), (x + 86, gy - 28)], hx("8aa8c8"))
    cv.p(x + 96, gy - 36, RED)
    cv.p(x + 95, gy - 35, RED)
    cv.line(x + 82, gy - 22, x + 89, gy - 30, GREY4)    # strut
    # rear boot sill with boxes spilling / on the ground behind
    box_item(cv, x + 82, gy - 14, 8, 8)
    box_item(cv, x + 88, gy - 9, 12, 9)
    box_item(cv, x + 100, gy - 6, 9, 6, col=hx("a07a4a"))
    cv.box(x + 91, gy - 13, x + 97, gy - 10, TEAL)       # item on box
    cv.box(x + 102, gy - 9, x + 105, gy - 7, GOLD)
    # wheels
    wheel(cv, x + 16, gy - 3, 5)
    wheel(cv, x + 68, gy - 3, 5)
    # wheel arches
    for cx in (x + 16, x + 68):
        for dx in range(-6, 7):
            cv.p(cx + dx, gy - 9 + (dx * dx) // 12, OUT)
    # pasting table with a few bits beside
    cv.box(x + 108, gy - 10, x + 130, gy - 9, CREAM_D)
    cv.line(x + 110, gy - 8, x + 116, gy, OUT)
    cv.line(x + 116, gy - 8, x + 110, gy, OUT)
    cv.line(x + 122, gy - 8, x + 128, gy, OUT)
    cv.line(x + 128, gy - 8, x + 122, gy, OUT)
    cv.box(x + 110, gy - 14, x + 114, gy - 11, BLUE)
    cv.disc(x + 120, gy - 12, 2, OUT)
    cv.p(x + 120, gy - 12, RED)
    cv.box(x + 124, gy - 15, x + 126, gy - 11, GOLD)
    return cv


def v_panel_van():
    cv = vehicle_base(81)
    x, gy = 18, 64
    shadow(cv, x, x + 110, gy + 1)
    body, body_d, body_l = hx("d4d8e0"), hx("a8aebc"), hx("eef0f4")
    pts = [(x + 1, gy - 7), (x + 2, gy - 16), (x + 10, gy - 19), (x + 18, gy - 33),
           (x + 104, gy - 33), (x + 106, gy - 31), (x + 106, gy - 5), (x + 1, gy - 5)]
    cv.poly(pts, OUT)
    inner = [(x + 2, gy - 7), (x + 3, gy - 15), (x + 11, gy - 18), (x + 19, gy - 32),
             (x + 103, gy - 32), (x + 105, gy - 30), (x + 105, gy - 6), (x + 2, gy - 6)]
    cv.poly(inner, body)
    cv.hline(x + 20, x + 104, gy - 31, body_l)
    cv.hline(x + 2, x + 105, gy - 8, body_d)
    cv.hline(x + 2, x + 105, gy - 14, body_d)
    # cab window
    cv.poly([(x + 12, gy - 18), (x + 20, gy - 30), (x + 30, gy - 30), (x + 30, gy - 18)], hx("7890b0"))
    cv.line(x + 20, gy - 28, x + 16, gy - 21, hx("aac8e8"))
    cv.vline(x + 31, gy - 31, gy - 6, OUT)             # cab door line
    cv.hline(x + 24, x + 27, gy - 15, OUT)
    cv.box(x + 8, gy - 21, x + 11, gy - 19, GREY2)     # mirror
    # sliding door open: dark interior with boxes, door slid back over rear panel
    ox0, ox1 = x + 34, x + 62
    cv.rect(ox0, gy - 30, ox1, gy - 7, hx("2a2c36"))
    cv.vgrad(ox0, gy - 30, ox1, gy - 7, [hx("3a3a44"), hx("2a2c36"), hx("202228")])
    cv.vline(ox0 - 1, gy - 31, gy - 6, OUT)
    cv.vline(ox1 + 1, gy - 31, gy - 6, OUT)
    cv.hline(ox0, ox1, gy - 6, GREY3)                  # step
    box_item(cv, ox0 + 2, gy - 17, 11, 10)
    box_item(cv, ox0 + 13, gy - 14, 9, 7, col=hx("a07a4a"))
    box_item(cv, ox0 + 4, gy - 25, 8, 8)
    box_item(cv, ox0 + 14, gy - 23, 12, 9)
    cv.box(ox0 + 22, gy - 13, ox0 + 27, gy - 8, TEAL)
    cv.box(ox0 + 17, gy - 28, ox0 + 22, gy - 24, RED)
    cv.glow(ox0 + 14, gy - 26, 10, WARM, 0.25)         # dome light
    cv.hline(ox0 + 11, ox0 + 16, gy - 30, WARM)
    # slid door panel (overlapping rear) with rail
    cv.hline(x + 34, x + 100, gy - 20, GREY3)
    cv.box(ox1 + 3, gy - 31, ox1 + 31, gy - 6, body)
    cv.hline(ox1 + 4, ox1 + 30, gy - 30, body_l)
    cv.hline(ox1 + 4, ox1 + 30, gy - 14, body_d)
    cv.hline(ox1 + 6, ox1 + 9, gy - 17, OUT)
    # rear doors seam + lights
    cv.vline(x + 101, gy - 31, gy - 6, body_d)
    cv.box(x + 104, gy - 16, x + 106, gy - 12, RED)
    cv.box(x + 1, gy - 13, x + 4, gy - 10, WARM)       # headlight
    cv.hline(x, x + 12, gy - 5, GREY2)
    cv.hline(x + 96, x + 107, gy - 5, GREY2)
    # grime/rust touch for charm
    cv.p(x + 80, gy - 9, hx("8a6a50"))
    cv.p(x + 81, gy - 9, hx("8a6a50"))
    cv.p(x + 88, gy - 10, hx("8a6a50"))
    wheel(cv, x + 18, gy - 3, 5)
    wheel(cv, x + 88, gy - 3, 5)
    for cx in (x + 18, x + 88):
        for dx in range(-6, 7):
            cv.p(cx + dx, gy - 9 + (dx * dx) // 12, OUT)
    # sack truck beside
    cv.line(x + 118, gy - 18, x + 122, gy, OUT)
    cv.line(x + 119, gy - 18, x + 123, gy, GREY4)
    cv.hline(x + 122, x + 128, gy, OUT)
    box_item(cv, x + 122, gy - 8, 8, 8)
    wheel(cv, x + 122, gy, 2)
    return cv


def v_luton():
    cv = vehicle_base(91)
    x, gy = 8, 64
    shadow(cv, x, x + 140, gy + 1)
    body, body_d, body_l = hx("e0e2e8"), hx("b0b4c0"), hx("f4f5f8")
    # cab
    cab = [(x + 1, gy - 6), (x + 2, gy - 16), (x + 8, gy - 19), (x + 12, gy - 30),
           (x + 26, gy - 30), (x + 26, gy - 6)]
    cv.poly([(x, gy - 5), (x + 1, gy - 17), (x + 7, gy - 20), (x + 11, gy - 31),
             (x + 27, gy - 31), (x + 27, gy - 5)], OUT)
    cv.poly(cab, hx("c8ccd4"))
    cv.hline(x + 2, x + 25, gy - 9, hx("a8aebc"))
    cv.poly([(x + 10, gy - 19), (x + 14, gy - 28), (x + 24, gy - 28), (x + 24, gy - 19)], hx("7890b0"))
    cv.line(x + 14, gy - 26, x + 12, gy - 21, hx("aac8e8"))
    cv.hline(x + 19, x + 22, gy - 15, OUT)
    cv.box(x + 1, gy - 13, x + 4, gy - 10, WARM)
    cv.box(x + 6, gy - 22, x + 9, gy - 19, GREY2)      # mirror
    cv.hline(x, x + 14, gy - 5, GREY2)
    # box body (with luton over-cab)
    bx0, bx1, by0, by1 = x + 13, x + 104, gy - 42, gy - 8
    cv.box(bx0, by0, x + 26, gy - 31, body)            # luton peak
    cv.box(x + 26, by0, bx1, by1, body)
    cv.rect(x + 14, by0 + 1, x + 26, gy - 32, body)
    cv.hline(bx0 + 1, bx1 - 1, by0 + 1, body_l)
    for xx in range(x + 30, bx1, 10):
        cv.vline(xx, by0 + 2, by1 - 2, body_d)
    cv.rect(x + 27, by1 - 5, bx1 - 1, by1 - 4, TEAL)    # generic stripe
    cv.rect(x + 27, by1 - 3, bx1 - 1, by1 - 3, GOLD)
    # chassis
    cv.rect(x + 26, by1 + 1, bx1, gy - 5, GREY1)
    cv.hline(x + 26, bx1, gy - 5, OUT)
    # open rear: roller door up, interior visible from the side? show rear end
    cv.box(bx1 - 1, by0, bx1 + 2, by1, GREY2)
    cv.box(bx1 + 3, by1 + 2, bx1 + 6, gy - 4, RED)     # tail light cluster
    # tail lift down on ground at rear
    lx0, lx1 = bx1 + 2, bx1 + 30
    cv.box(lx0, gy - 2, lx1, gy, GREY3)
    cv.hline(lx0 + 1, lx1 - 1, gy - 2, GREY5)
    for xx in range(lx0 + 2, lx1, 3):
        cv.p(xx, gy - 1, GREY2)
    cv.p(lx1, gy - 3, GOLD)
    cv.line(bx1 + 3, by1 + 1, lx0 + 2, gy - 3, OUT)    # lift arm
    cv.line(bx1 + 4, by1 + 1, lx0 + 3, gy - 3, GREY3)
    # cargo on the tail lift
    box_item(cv, lx0 + 6, gy - 12, 10, 10)
    box_item(cv, lx0 + 8, gy - 18, 7, 6, col=hx("a07a4a"))
    cv.box(lx0 + 17, gy - 16, lx0 + 24, gy - 3, hx("7a5238"))   # wardrobe/chest
    cv.hline(lx0 + 18, lx0 + 23, gy - 11, hx("5a3a2a"))
    cv.p(lx0 + 20, gy - 13, GOLD)
    cv.p(lx0 + 20, gy - 7, GOLD)
    # wheels
    wheel(cv, x + 16, gy - 3, 5)
    wheel(cv, x + 84, gy - 3, 5)
    wheel(cv, x + 95, gy - 3, 5)
    return cv


# ============================================================== ICON
def icon_trading_cards():
    cv = Canvas(64, 64)
    rot = __import__("math")

    def card(cx, cy, angle, border, border_d, art_bg, motif, holo=False):
        """Draw a rotated card (w=22, h=30) centred at cx,cy on its own layer."""
        layer = Canvas(64, 64)
        cw, ch = 22, 30
        a = rot.radians(angle)
        ca, sa = rot.cos(a), rot.sin(a)
        for y in range(64):
            for x in range(64):
                dx, dy = x + 0.5 - cx, y + 0.5 - cy
                u = dx * ca + dy * sa + cw / 2
                v = -dx * sa + dy * ca + ch / 2
                if not (0 <= u < cw and 0 <= v < ch):
                    continue
                iu, iv = int(u), int(v)
                # rounded corners
                if (iu in (0, cw - 1)) and (iv in (0, ch - 1)):
                    continue
                if iu == 0 or iv == 0 or iu == cw - 1 or iv == ch - 1:
                    c = OUT
                elif iu <= 2 or iv <= 2 or iu >= cw - 3 or iv >= ch - 3:
                    c = border if (iu > 1 and iv > 1) else hx("ffffff")[:3] + (255,)
                    if iu == 1 or iv == 1:
                        c = tuple(min(255, k + 50) for k in border[:3]) + (255,)
                    if iu == cw - 2 or iv == ch - 2:
                        c = border_d
                elif 4 <= iv <= 16 and 3 <= iu <= cw - 4:
                    # art window
                    if iv == 4 or iv == 16 or iu == 3 or iu == cw - 4:
                        c = border_d
                    else:
                        c = motif(iu, iv, art_bg, holo)
                elif iv in (19, 22, 25) and 4 <= iu <= cw - 5 - (iv == 25) * 5:
                    c = hx("8a8472")                     # text lines
                elif iv == 18 and 4 <= iu <= 9:
                    c = border_d                         # name bar
                else:
                    c = hx("f4ecd4")
                    if holo:
                        k = ((iu + iv) // 3) % 4
                        c = [hx("f4ecd4"), hx("d6f4f0"), hx("e8def8"), hx("fff4c8")][k]
                layer.p(x, y, c)
        cv.im.alpha_composite(layer.im)

    import math as _m
    star_pts = []
    for k in range(10):
        ang = -_m.pi / 2 + k * _m.pi / 5
        rr = 5.6 if k % 2 == 0 else 2.4
        star_pts.append((11 + rr * _m.cos(ang), 10.5 + rr * _m.sin(ang)))

    def in_poly(px, py, pts):
        inside = False
        n = len(pts)
        for i in range(n):
            (xa, ya), (xb, yb) = pts[i], pts[(i + 1) % n]
            if (ya > py) != (yb > py) and px < xa + (py - ya) * (xb - xa) / (yb - ya):
                inside = not inside
        return inside

    HOLO = [hx("7fd8e8"), hx("98b0f0"), hx("c89ae8"), hx("f0a0c8"), hx("f8e088"), hx("a0e8a0")]

    def star(iu, iv, bg, holo):
        cx_, cy_ = iu + 0.5, iv + 0.5
        if in_poly(cx_, cy_, star_pts):
            if (cx_ - 11) ** 2 + (cy_ - 10.5) ** 2 < 2.5:
                return hx("fff4c0")
            return GOLD if cx_ < 11.5 else hx("c8962a")
        # outline for the star
        for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if in_poly(cx_ + ox, cy_ + oy, star_pts):
                return hx("7a5418")
        if holo:
            return HOLO[((iu + iv) // 2) % len(HOLO)]
        return bg

    def flame(iu, iv, bg, holo):
        u, v = iu - 11, iv - 5
        # teardrop flame shape pointing up
        width = [0, 1, 1, 2, 2, 3, 3, 4, 4, 4, 3][v] if 0 <= v <= 10 else -1
        if width >= 0 and abs(u + (1 if v < 4 else 0)) <= width:
            if abs(u) <= width - 2 and v >= 5:
                return hx("fff0a0")
            if abs(u) <= width - 1 and v >= 3:
                return hx("ffa040")
            return RED
        return bg

    def leaf(iu, iv, bg, holo):
        u, v = iu - 11, iv - 10
        # diagonal leaf: ellipse along 45deg
        a, b = (u + v) / 1.414, (u - v) / 1.414
        if (a / 5.2) ** 2 + (b / 2.6) ** 2 <= 1:
            if abs(b) < 0.6:
                return hx("2d5a36")
            return hx("7ac860") if b > 0 else GREEN
        if -6 <= a <= -4.5 and abs(b) < 0.8:
            return hx("2d5a36")                          # stem
        return bg

    card(18, 36, -24, hx("3f6fc4"), hx("27417a"), hx("cdeec0"), leaf)
    card(46, 36, 24, hx("c8413a"), hx("7f2530"), hx("f8d8a0"), flame)
    card(32, 31, 0, hx("8a6ad0"), hx("4a3a8a"), hx("2a2a5a"), star, holo=True)
    # sparkles on holo card
    for sx, sy in ((45, 12), (17, 18)):
        cv.p(sx, sy, WHITE)
        for d in (1, 2):
            cv.p(sx + d, sy, hx("fff4c0"))
            cv.p(sx - d, sy, hx("fff4c0"))
            cv.p(sx, sy + d, hx("fff4c0"))
            cv.p(sx, sy - d, hx("fff4c0"))
    return cv


def main():
    os.makedirs(ART, exist_ok=True)
    prem = [premises_box_room, premises_garage, premises_industrial, premises_shop, premises_warehouse]
    for i, fn in enumerate(prem):
        cv = fn()
        cv.im = cv.im.convert("RGB").convert("RGBA")
        cv.save(os.path.join(ART, "premises_%d.png" % i), SCALE)
    veh = [v_on_foot, v_trolley, v_estate, v_panel_van, v_luton]
    for i, fn in enumerate(veh):
        cv = fn()
        cv.save(os.path.join(ART, "vehicle_%d.png" % i), SCALE)
    icon_trading_cards().save(os.path.join(ICONS, "cat_trading_cards.png"), 8)


if __name__ == "__main__":
    main()
