#!/usr/bin/env python3
"""Draws the 1-bit "desktop" the wallpaper flies over.

Outputs:
  package/contents/images/world.png  - the bitmap (white = paper, black = ink)
  package/contents/ui/scene.js       - the camera moves over it

All artwork here is original; nothing is copied from any real operating system.
"""
import json
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

W, H = 768, 512
INK, PAPER = 0, 1
ROOT = Path(__file__).resolve().parent.parent
OUT_PNG = ROOT / "package/contents/images/world.png"
OUT_JS = ROOT / "package/contents/ui/scene.js"


# Terminus is a true bitmap font, so every glyph sits on the
# pixel grid instead of being rasterised from outlines.
FONTS = Path(__file__).resolve().parent / "fonts"
BOLD = ImageFont.truetype(str(FONTS / "ter-u14b.otb"), 14)
REG = ImageFont.truetype(str(FONTS / "ter-u12n.otb"), 12)

# One camera move per entry: a straight scroll of the view centre along a bitmap
# axis. yaw is the sign of the in-plane rotation, ramp is the direction in which
# the tiles sweep in and out.
RIGHT, LEFT, DOWN, UP = (1, 0), (-1, 0), (0, 1), (0, -1)
SCENES = [
    ((110, 110), (300, 110), -1, RIGHT),  # file window, top row of icons
    ((300, 172), (120, 172), 1, LEFT),    # file window, bottom row
    ((30, 30), (230, 30), 1, RIGHT),      # menu bar and the open menu
    ((404, 50), (404, 250), 1, DOWN),     # paint tools and patterns
    ((470, 170), (700, 170), -1, RIGHT),  # the painted landscape
    ((720, 96), (480, 96), 1, LEFT),      # sun and clouds
    ((170, 296), (380, 296), -1, RIGHT),  # alert
    ((74, 500), (74, 380), 1, UP),        # calculator
    ((180, 440), (370, 440), 1, RIGHT),   # settings
    ((640, 392), (420, 392), -1, LEFT),   # notes
    ((712, 290), (712, 480), -1, DOWN),   # desktop icons
]

# Text of the notes window: lines, the selected (inverted) word as
# (line, word), and the line the text cursor stands at the end of.
NOTES = ([
    '"I am not a visionary. I\'m an',
    "engineer. I'm happy with the",
    "people who are wandering around",
    "looking at the stars but I am",
    "looking at the ground and I want",
    "to fix the pothole before I",
    'fall in."',
    "",
    "             - Linus Torvalds",
], (5, "pothole"), 6)

img = Image.new("1", (W, H), PAPER)
d = ImageDraw.Draw(img)
px = img.load()

PATTERNS = {
    "black": lambda x, y: True,
    "gray75": lambda x, y: not (x % 2 == 0 and y % 2 == 0),
    "gray50": lambda x, y: (x + y) % 2 == 0,
    "gray25": lambda x, y: x % 2 == 0 and y % 2 == 0,
    "gray12": lambda x, y: (x % 4 == 0 and y % 4 == 0) or (x % 4 == 2 and y % 4 == 2),
    "diag": lambda x, y: (x + y) % 4 == 0,
    "brick": lambda x, y: y % 4 == 0 or (x % 8 == 0 and y % 8 < 4) or (x % 8 == 4 and y % 8 >= 4),
    "hlines": lambda x, y: y % 2 == 0,
    "vlines": lambda x, y: x % 3 == 0,
    "grid": lambda x, y: x % 4 == 0 or y % 4 == 0,
    "weave": lambda x, y: (x % 4 == 0 and y % 8 < 4) or (y % 4 == 0 and x % 8 >= 4),
    "white": lambda x, y: False,
}


def text(x, y, s, f=REG, fill=INK):
    d.text((x, y), s, font=f, fill=fill)


def tw(s, f=REG):
    return int(d.textlength(s, font=f))


def ctext(cx, y, s, f=REG, patch=False):
    w = tw(s, f)
    x = cx - w // 2
    if patch:
        d.rectangle([x - 2, y, x + w + 1, y + 12], fill=PAPER)
    text(x, y, s, f)


def pfill(shape, pattern, clip=(0, 0, W - 1, H - 1)):
    """Fills whatever shape(draw) paints with a dither pattern, inside clip."""
    mask = Image.new("1", (W, H), 0)
    shape(ImageDraw.Draw(mask))
    box = mask.getbbox()
    if not box:
        return
    fn = PATTERNS[pattern]
    mp = mask.load()
    for y in range(max(box[1], clip[1]), min(box[3], clip[3] + 1)):
        for x in range(max(box[0], clip[0]), min(box[2], clip[2] + 1)):
            if mp[x, y]:
                px[x, y] = INK if fn(x, y) else PAPER


def rect_fill(box, pattern):
    pfill(lambda m: m.rectangle(box, fill=1), pattern)


def invert(box):
    for y in range(box[1], box[3] + 1):
        for x in range(box[0], box[2] + 1):
            px[x, y] = 1 - px[x, y]


def dashed_rect(box):
    x0, y0, x1, y1 = box
    for x in range(x0, x1 + 1):
        if (x - x0) % 4 < 2:
            px[x, y0] = px[x, y1] = INK
    for y in range(y0, y1 + 1):
        if (y - y0) % 4 < 2:
            px[x0, y] = px[x1, y] = INK


def bitmap(x, y, rows):
    for j, row in enumerate(rows):
        for i, c in enumerate(row):
            if c == "X":
                px[x + i, y + j] = INK
            elif c == ".":
                px[x + i, y + j] = PAPER


# --- window chrome -----------------------------------------------------------

TITLE_H = 18


def window(x, y, w, h, title, scroll=False):
    d.rectangle([x + 1, y + 1, x + w, y + h], fill=INK)  # drop shadow
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=PAPER, outline=INK)
    d.line([x, y + TITLE_H, x + w - 1, y + TITLE_H], fill=INK)
    for ly in range(y + 4, y + TITLE_H - 2, 2):
        d.line([x + 2, ly, x + w - 3, ly], fill=INK)
    d.rectangle([x + 8, y + 3, x + 20, y + TITLE_H - 3], fill=PAPER)
    d.rectangle([x + 9, y + 4, x + 19, y + TITLE_H - 4], outline=INK)
    t = tw(title, BOLD)
    tx = x + (w - t) // 2
    d.rectangle([tx - 6, y + 1, tx + t + 5, y + TITLE_H - 1], fill=PAPER)
    text(tx, y + 2, title, BOLD)
    if scroll:
        sx = x + w - 16
        top, bottom = y + TITLE_H, y + h - 1
        d.line([sx, top, sx, bottom], fill=INK)
        rect_fill([sx + 1, top + 16, x + w - 2, bottom - 31], "gray25")
        for by in (top + 15, bottom - 30, bottom - 15):
            d.line([sx, by, x + w - 1, by], fill=INK)
        d.polygon([(sx + 8, top + 4), (sx + 12, top + 10), (sx + 4, top + 10)], outline=INK)
        d.polygon([(sx + 8, bottom - 19), (sx + 12, bottom - 25), (sx + 4, bottom - 25)], outline=INK)
        d.rectangle([sx, top + 40, x + w - 1, top + 56], fill=PAPER, outline=INK)  # thumb
        d.rectangle([sx + 3, bottom - 12, sx + 9, bottom - 6], outline=INK)  # grow box
        d.rectangle([sx + 6, bottom - 9, sx + 13, bottom - 2], fill=PAPER, outline=INK)


def button(x, y, w, h, label, default=False):
    d.rounded_rectangle([x, y, x + w - 1, y + h - 1], radius=5, fill=PAPER, outline=INK)
    if default:
        d.rounded_rectangle([x - 4, y - 4, x + w + 3, y + h + 3], radius=8, outline=INK, width=2)
    ctext(x + w // 2, y + (h - 14) // 2, label, BOLD)


# --- icons (cx = horizontal centre, y = top) ---------------------------------

def label(cx, y, s, on_desktop):
    ctext(cx, y, s, REG, patch=on_desktop)


def folder(cx, y, name, on_desktop=False):
    x = cx - 16
    d.polygon([(x, y + 4), (x + 3, y), (x + 12, y), (x + 15, y + 4)], fill=PAPER, outline=INK)
    d.rectangle([x, y + 4, x + 31, y + 23], fill=PAPER, outline=INK)
    d.line([x + 1, y + 4, x + 14, y + 4], fill=PAPER)
    label(cx, y + 27, name, on_desktop)


def document(cx, y, name, on_desktop=False):
    x = cx - 12
    d.polygon([(x, y), (x + 16, y), (x + 23, y + 7), (x + 23, y + 29), (x, y + 29)],
              fill=PAPER, outline=INK)
    d.line([x + 16, y, x + 16, y + 7, x + 23, y + 7], fill=INK)
    for ly in range(y + 11, y + 26, 3):
        d.line([x + 4, ly, x + 19 - (ly % 2) * 5, ly], fill=INK)
    label(cx, y + 33, name, on_desktop)


def floppy(cx, y, name, on_desktop=False):
    x = cx - 14
    d.polygon([(x, y), (x + 23, y), (x + 27, y + 4), (x + 27, y + 27), (x, y + 27)],
              fill=PAPER, outline=INK)
    d.rectangle([x + 7, y, x + 20, y + 9], outline=INK)
    d.rectangle([x + 15, y + 2, x + 17, y + 7], fill=INK)
    d.rectangle([x + 4, y + 14, x + 23, y + 27], outline=INK)
    for ly in range(y + 18, y + 26, 3):
        d.line([x + 7, ly, x + 20, ly], fill=INK)
    label(cx, y + 31, name, on_desktop)


def trash(cx, y, name, on_desktop=False):
    x = cx - 12
    d.rectangle([x + 8, y, x + 15, y + 4], fill=PAPER, outline=INK)
    d.rectangle([x, y + 4, x + 23, y + 7], fill=PAPER, outline=INK)
    d.polygon([(x + 2, y + 8), (x + 21, y + 8), (x + 19, y + 31), (x + 4, y + 31)],
              fill=PAPER, outline=INK)
    for lx in (x + 7, x + 12, x + 16):
        d.line([lx, y + 11, lx, y + 28], fill=INK)
    label(cx, y + 35, name, on_desktop)


def computer(cx, y, name, on_desktop=False):
    x = cx - 16
    d.rounded_rectangle([x + 2, y, x + 29, y + 31], radius=3, fill=PAPER, outline=INK)
    d.rounded_rectangle([x + 6, y + 4, x + 25, y + 19], radius=2, outline=INK)
    for ly in (y + 8, y + 11, y + 14):
        d.line([x + 9, ly, x + 9 + (ly * 5) % 11 + 3, ly], fill=INK)
    d.line([x + 17, y + 25, x + 25, y + 25], fill=INK)
    d.rectangle([x + 6, y + 24, x + 8, y + 26], fill=INK)
    d.rectangle([x + 4, y + 32, x + 27, y + 36], fill=PAPER, outline=INK)
    label(cx, y + 40, name, on_desktop)


ARROW = [
    "X", "XX", "X.X", "X..X", "X...X", "X....X", "X.....X", "X......X",
    "X.......X", "X........X", "X.....XXXXX", "X..X..X", "X.X X..X",
    "XX  X..X", "X    X..X", "     X..X", "      XX",
]


# --- scene -------------------------------------------------------------------

def desktop():
    rect_fill([0, 0, W - 1, H - 1], "gray50")


def menubar():
    d.rectangle([0, 0, W - 1, 19], fill=PAPER)
    d.line([0, 19, W - 1, 19], fill=INK)
    d.polygon([(16, 4), (22, 10), (16, 16), (10, 10)], fill=INK)
    d.polygon([(16, 8), (18, 10), (16, 12), (14, 10)], fill=PAPER)
    x = 36
    for i, m in enumerate(["File", "Edit", "View", "Special"]):
        w = tw(m, BOLD)
        if i == 0:
            d.rectangle([x - 7, 1, x + w + 6, 18], fill=INK)
            text(x, 3, m, BOLD, PAPER)
        else:
            text(x, 3, m, BOLD)
        x += w + 16
    ctext(W - 40, 3, "10:42", BOLD)


def dropdown():
    x, y, w = 29, 20, 108
    items = ["New Folder", "Open", "Close", None, "Get Info", "Duplicate", None, "Quit"]
    h = len(items) * 16 + 3
    d.rectangle([x + 2, y + 2, x + w + 1, y + h + 1], fill=INK)
    d.rectangle([x, y - 1, x + w, y + h], fill=PAPER, outline=INK)
    for i, item in enumerate(items):
        iy = y + 1 + i * 16
        if item is None:
            for lx in range(x + 1, x + w, 2):
                px[lx, iy + 8] = INK
        elif i == 1:
            d.rectangle([x + 1, iy, x + w - 1, iy + 15], fill=INK)
            text(x + 14, iy + 1, item, BOLD, PAPER)
        else:
            text(x + 14, iy + 1, item, BOLD)
    bitmap(x + 84, y + 26, ARROW)


def finder():
    x, y, w, h = 64, 36, 300, 196
    window(x, y, w, h, "System Disk", scroll=True)
    text(x + 130, y + 21, "8 items")
    text(x + 206, y + 21, "312K in use")
    d.line([x, y + 35, x + w - 17, y + 35], fill=INK)
    d.line([x, y + 37, x + w - 17, y + 37], fill=INK)
    cols = [x + 40 + i * 64 for i in range(4)]
    r1, r2 = y + 50, y + 116
    folder(cols[0], r1, "System")
    folder(cols[1], r1, "Tools")
    document(cols[2], r1 - 4, "Read Me")
    folder(cols[3], r1, "Games")
    document(cols[0], r2 - 4, "Letter")
    folder(cols[1], r2, "Fonts")
    floppy(cols[2], r2 - 3, "Archive")
    document(cols[3], r2 - 4, "List")
    invert([cols[1] - 17, r1 - 1, cols[1] + 16, r1 + 24])  # selected folder
    invert([cols[1] - 24, r1 + 27, cols[1] + 24, r1 + 39])


def paint():
    x, y, w, h = 376, 30, 376, 250
    window(x, y, w, h, "Drawing")
    top = y + TITLE_H + 1
    cx0, cy1 = x + 36, y + h - 20  # canvas left edge, canvas bottom edge
    canvas = (cx0 + 1, top, x + w - 2, cy1 - 1)
    d.line([cx0, top, cx0, y + h - 2], fill=INK)
    d.line([cx0, cy1, x + w - 2, cy1], fill=INK)

    # tool palette, 2 x 6
    for i in range(12):
        tx, ty = x + 1 + (i % 2) * 17, top + (i // 2) * 17
        d.rectangle([tx, ty, tx + 17, ty + 17], outline=INK)
        cx, cy = tx + 9, ty + 9
        if i == 0:
            dashed_rect([cx - 5, cy - 4, cx + 5, cy + 4])
        elif i == 1:
            d.ellipse([cx - 5, cy - 4, cx + 5, cy + 4], outline=INK)
            d.line([cx + 3, cy + 3, cx + 6, cy + 6], fill=INK)
        elif i == 2:
            ctext(cx + 1, cy - 7, "A", BOLD)
        elif i == 3:
            d.polygon([(cx - 5, cy + 4), (cx, cy - 5), (cx + 5, cy + 4)], fill=INK)
        elif i == 4:
            for k in range(14):
                px[cx - 5 + (k * 7) % 11, cy - 5 + (k * 5) % 11] = INK
        elif i == 5:
            d.line([cx - 4, cy + 4, cx + 4, cy - 4], fill=INK, width=3)
        elif i == 6:
            d.line([cx - 5, cy + 5, cx + 5, cy - 5], fill=INK)
        elif i == 7:
            d.line([cx - 5, cy, cx + 5, cy], fill=INK)
        elif i == 8:
            d.rectangle([cx - 5, cy - 3, cx + 5, cy + 3], outline=INK)
            d.line([cx - 5, cy + 1, cx + 5, cy + 1], fill=INK)
        elif i == 9:
            d.rectangle([cx - 5, cy - 4, cx + 5, cy + 4], outline=INK)
        elif i == 10:
            rect_fill([cx - 5, cy - 4, cx + 5, cy + 4], "gray50")
            d.rectangle([cx - 5, cy - 4, cx + 5, cy + 4], outline=INK)
        else:
            d.ellipse([cx - 5, cy - 4, cx + 5, cy + 4], outline=INK)
    invert([x + 19, top + 52, x + 34, top + 67])  # the selected tool
    ly = top + 112
    for width in (1, 2, 3, 4):  # line widths
        d.rectangle([x + 7, ly, x + 28, ly + width - 1], fill=INK)
        ly += width + 5

    # pattern strip
    sx = cx0 + 1
    for name in PATTERNS:
        rect_fill([sx, cy1 + 1, sx + 17, y + h - 2], name)
        d.line([sx + 18, cy1, sx + 18, y + h - 2], fill=INK)
        sx += 19

    # the drawing itself
    def outlined(shape_fill, shape_line, pattern):
        pfill(shape_fill, pattern, canvas)
        pfill(shape_line, "black", canvas)

    hill1 = [x + 10, top + 150, x + 250, top + 300]
    hill2 = [x + 170, top + 165, x + 420, top + 320]
    outlined(lambda m: m.ellipse(hill1, fill=1), lambda m: m.ellipse(hill1, outline=1), "gray25")
    outlined(lambda m: m.ellipse(hill2, fill=1), lambda m: m.ellipse(hill2, outline=1), "diag")

    hx, hy = x + 96, top + 118  # house
    rect_fill([hx, hy, hx + 56, hy + 40], "brick")
    d.rectangle([hx, hy, hx + 56, hy + 40], outline=INK)
    d.polygon([(hx - 6, hy), (hx + 28, hy - 24), (hx + 62, hy)], fill=INK)
    d.rectangle([hx + 40, hy - 22, hx + 47, hy - 8], fill=PAPER, outline=INK)
    d.rectangle([hx + 8, hy + 16, hx + 22, hy + 40], fill=PAPER, outline=INK)
    px[hx + 19, hy + 29] = INK
    d.rectangle([hx + 32, hy + 12, hx + 48, hy + 26], fill=PAPER, outline=INK)
    d.line([hx + 40, hy + 12, hx + 40, hy + 26], fill=INK)
    d.line([hx + 32, hy + 19, hx + 48, hy + 19], fill=INK)

    sun_x, sun_y = x + 300, top + 52
    for k in range(12):
        dx, dy = [(0, 1), (0.5, 0.87), (0.87, 0.5), (1, 0), (0.87, -0.5), (0.5, -0.87),
                  (0, -1), (-0.5, -0.87), (-0.87, -0.5), (-1, 0), (-0.87, 0.5), (-0.5, 0.87)][k]
        r0, r1 = 23, 30 if k % 2 else 35
        d.line([sun_x + dx * r0, sun_y + dy * r0, sun_x + dx * r1, sun_y + dy * r1], fill=INK)
    pfill(lambda m: m.ellipse([sun_x - 18, sun_y - 18, sun_x + 18, sun_y + 18], fill=1), "gray12")
    d.ellipse([sun_x - 18, sun_y - 18, sun_x + 18, sun_y + 18], outline=INK)
    dashed_rect([sun_x - 42, sun_y - 42, sun_x + 42, sun_y + 42])

    for cx, cy in ((x + 110, top + 40), (x + 200, top + 76)):  # clouds
        blobs = [(cx - 22, cy - 4, cx + 2, cy + 10), (cx - 10, cy - 12, cx + 14, cy + 8),
                 (cx + 4, cy - 5, cx + 26, cy + 10)]
        for b in blobs:
            d.ellipse([b[0] - 1, b[1] - 1, b[2] + 1, b[3] + 1], fill=INK)
        for b in blobs:
            d.ellipse(b, fill=PAPER)

    rnd = random.Random(7)  # spray can
    for _ in range(160):
        ax, ay = rnd.gauss(0, 9), rnd.gauss(0, 9)
        px[int(x + 64 + ax), int(top + 96 + ay)] = INK


def alert():
    x, y, w, h = 150, 246, 250, 100
    d.rectangle([x + 2, y + 2, x + w + 1, y + h + 1], fill=INK)
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=PAPER, outline=INK)
    d.rectangle([x + 3, y + 3, x + w - 4, y + h - 4], outline=INK, width=2)
    tri = [(x + 34, y + 16), (x + 52, y + 46), (x + 16, y + 46)]
    d.polygon(tri, fill=PAPER, outline=INK)
    d.polygon([(tri[0][0], tri[0][1] + 2), (tri[1][0] - 2, tri[1][1] - 1),
               (tri[2][0] + 2, tri[2][1] - 1)], outline=INK)
    d.rectangle([x + 33, y + 26, x + 35, y + 37], fill=INK)
    d.rectangle([x + 33, y + 40, x + 35, y + 42], fill=INK)
    text(x + 66, y + 18, "Disk is almost full.", BOLD)
    text(x + 66, y + 34, "Save your changes?", BOLD)
    button(x + 106, y + 66, 62, 20, "Cancel")
    button(x + 184, y + 66, 50, 20, "Yes", default=True)


def calculator():
    x, y, w, h = 22, 362, 104, 142
    window(x, y, w, h, "Calc")
    d.rectangle([x + 9, y + 25, x + w - 10, y + 43], outline=INK)
    s = "3.14159"
    text(x + w - 14 - tw(s, BOLD), y + 27, s, BOLD)
    keys = ["C±÷×", "789−", "456+", "123=", "0.%="]
    for r, row in enumerate(keys):
        for c, k in enumerate(row):
            bx, by = x + 10 + c * 22, y + 50 + r * 18
            d.rectangle([bx + 1, by + 1, bx + 18, by + 15], fill=INK)
            d.rectangle([bx, by, bx + 17, by + 14], fill=PAPER, outline=INK)
            ctext(bx + 9, by + 1, k)


def settings():
    x, y, w, h = 150, 372, 236, 124
    window(x, y, w, h, "Settings")
    for i, (name, on) in enumerate([("Sound", True), ("Blink", False), ("Grid", True)]):
        cy = y + 28 + i * 16
        d.rectangle([x + 12, cy, x + 22, cy + 10], outline=INK)
        if on:
            d.line([x + 12, cy, x + 22, cy + 10], fill=INK)
            d.line([x + 12, cy + 10, x + 22, cy], fill=INK)
        text(x + 28, cy - 1, name)
    # clock
    ccx, ccy = x + 40, y + 98
    d.ellipse([ccx - 18, ccy - 18, ccx + 18, ccy + 18], fill=PAPER, outline=INK, width=2)
    for tx, ty in ((0, -14), (14, 0), (0, 14), (-14, 0)):
        d.rectangle([ccx + tx - 1, ccy + ty - 1, ccx + tx, ccy + ty], fill=INK)
    d.line([ccx, ccy, ccx + 7, ccy - 9], fill=INK, width=2)
    d.line([ccx, ccy, ccx - 10, ccy + 3], fill=INK)
    # slider
    text(x + 104, y + 25, "Speed")
    sx0, sx1, sy = x + 104, x + 204, y + 48
    d.rectangle([sx0, sy - 1, sx1, sy + 1], outline=INK)
    for tx in range(sx0, sx1 + 1, 20):
        d.line([tx, sy + 5, tx, sy + 8], fill=INK)
    d.rectangle([sx0 + 56, sy - 7, sx0 + 64, sy + 7], fill=PAPER, outline=INK)
    d.line([sx0 + 60, sy - 4, sx0 + 60, sy + 4], fill=INK)
    # level meter
    for i in range(10):
        bh = 4 + i * 2
        box = [sx0 + i * 10, y + 86 - bh, sx0 + i * 10 + 6, y + 86]
        d.rectangle(box, fill=INK if i < 6 else PAPER, outline=INK)
    # radio buttons
    for i, name in enumerate(["Dark", "Light"]):
        rx = x + 104 + i * 60
        d.ellipse([rx, y + 100, rx + 10, y + 110], outline=INK)
        if i == 0:
            d.ellipse([rx + 3, y + 103, rx + 7, y + 107], fill=INK)
        text(rx + 14, y + 99, name)


def notes():
    x, y, w, h = 400, 300, 250, 190
    window(x, y, w, h, "Notes", scroll=True)
    lines, (sel_line, sel_word), cursor_line = NOTES
    top = y + 28
    for i, line in enumerate(lines):
        text(x + 12, top + i * 15, line)
    sx = x + 12 + tw(lines[sel_line][:lines[sel_line].index(sel_word)])
    invert([sx - 1, top + sel_line * 15, sx + tw(sel_word), top + sel_line * 15 + 13])
    cx = x + 14 + tw(lines[cursor_line])
    d.line([cx, top + cursor_line * 15, cx, top + cursor_line * 15 + 12], fill=INK)


def desktop_icons():
    floppy(712, 300, "Disk", True)
    computer(712, 364, "Computer", True)
    trash(712, 440, "Trash", True)
    folder(30, 180, "Misc", True)
    document(100, 266, "Draft", True)


desktop()
finder()
paint()
alert()
calculator()
settings()
notes()
desktop_icons()
menubar()
dropdown()

scenes = [{"x0": a[0], "y0": a[1], "x1": b[0], "y1": b[1], "yaw": yaw, "rampX": r[0], "rampY": r[1]}
          for a, b, yaw, r in SCENES]

OUT_JS.write_text(
    "// Generated by tools/gen_art.py - do not edit.\n"
    ".pragma library\n\n"
    f"var scenes = {json.dumps(scenes)}\n"
)
OUT_PNG.parent.mkdir(parents=True, exist_ok=True)
img.save(OUT_PNG, optimize=True)
print(f"{OUT_PNG.relative_to(ROOT)}: {W}x{H}, {len(scenes)} scenes")
