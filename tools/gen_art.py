#!/usr/bin/env python3
"""Draws the 1-bit "desktop" the wallpaper flies over.

Outputs:
  package/contents/images/world.png  - the bitmap (white = paper, black = ink)
  package/contents/ui/scene.js       - the camera moves over it

The desktop is in the style of an early X11 workstation running twm. All of it
is drawn here; nothing is copied from the real programs or their bitmaps.
"""
import json
import math
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
    ((60, 100), (250, 100), -1, RIGHT),   # terminal, start of the quote
    ((260, 160), (70, 160), 1, LEFT),     # terminal, end of the quote
    ((30, 33), (330, 33), 1, RIGHT),      # terminal title bar
    ((576, 40), (576, 250), 1, DOWN),     # bitmap editor grid
    ((400, 140), (700, 140), -1, RIGHT),  # bitmap editor, buttons to previews
    ((50, 322), (300, 322), 1, RIGHT),    # clock and eyes
    ((250, 270), (250, 440), -1, DOWN),   # eyes and load graph
    ((425, 480), (425, 300), 1, UP),      # calculator
    ((720, 340), (540, 340), -1, LEFT),   # second terminal
    ((696, 396), (696, 500), 1, DOWN),    # window manager menu
    ((600, 452), (380, 452), 1, LEFT),    # mailbox and calculator keys
]

# The session in the big terminal, and the word selected in it.
SESSION = [
    "$ uname -sm",
    "Linux i386",
    "$ fortune",
    '"I am not a visionary. I\'m an',
    "engineer. I'm happy with the",
    "people who are wandering around",
    "looking at the stars but I am",
    "looking at the ground and I want",
    "to fix the pothole before I",
    'fall in."',
    "          -- Linus Torvalds",
    "$ ",
]
SELECTED = (8, "pothole")

# The picture being edited in the bitmap editor, 24 x 24.
MUG = [
    "",
    "       X    X    X",
    "      X    X    X",
    "      X    X    X",
    "       X    X    X",
    "        X    X    X",
    "        X    X    X",
    "       X    X    X",
    "",
    "   XXXXXXXXXXXXXXXX",
    "   X              XXXX",
    "   X              X  XX",
    "   X              X   X",
    "   X              X   X",
    "   X              X   X",
    "   X              X   X",
    "   X              X  XX",
    "   X              XXXX",
    "   X              X",
    "    X            X",
    "     XXXXXXXXXXXX",
    "",
    " XXXXXXXXXXXXXXXXXXXXX",
    "",
]

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


def bitmap(x, y, rows):
    for j, row in enumerate(rows):
        for i, c in enumerate(row):
            if c == "X":
                px[x + i, y + j] = INK
            elif c == ".":
                px[x + i, y + j] = PAPER


# --- window chrome -----------------------------------------------------------

TITLE_H = 18


def window(x, y, w, h, title, focused=False):
    """A twm-style frame: iconify button, title, resize button; the title bar
    of the focused window is filled with a stipple."""
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=PAPER, outline=INK, width=2)
    d.line([x, y + TITLE_H, x + w - 1, y + TITLE_H], fill=INK)
    by, lx, rx = y + 4, x + 5, x + w - 16
    d.rectangle([lx, by, lx + 10, by + 10], outline=INK)
    d.rectangle([lx + 4, by + 4, lx + 6, by + 6], fill=INK)
    d.rectangle([rx, by, rx + 10, by + 10], outline=INK)
    d.rectangle([rx, by + 4, rx + 6, by + 10], outline=INK)
    text(x + 21, y + 3, title, BOLD)
    if focused:
        sx = x + 21 + tw(title, BOLD) + 6
        rect_fill([sx, by, rx - 5, by + 10], "gray50")
    return y + TITLE_H + 1  # top of the contents


def xterm(x, y, w, lines, focused=False, selected=None):
    """A terminal exactly tall enough for its lines."""
    h = TITLE_H + 1 + 4 + len(lines) * 13 + 6
    assert max(tw(line) for line in lines) <= w - 26, "line too long for the terminal"
    top = window(x, y, w, h, "xterm", focused)
    d.line([x + 14, top, x + 14, y + h - 3], fill=INK)  # scrollbar
    rect_fill([x + 3, top + 1, x + 12, top + (h - TITLE_H) * 2 // 3], "gray50")
    for i, line in enumerate(lines):
        text(x + 20, top + 4 + i * 13, line)
    if selected:
        i, word = selected
        sx = x + 20 + tw(lines[i][:lines[i].index(word)])
        invert([sx - 1, top + 4 + i * 13, sx + tw(word), top + 16 + i * 13])
    cx, cy = x + 20 + tw(lines[-1]), top + 4 + (len(lines) - 1) * 13
    d.rectangle([cx, cy + 1, cx + 5, cy + 11], fill=INK)  # block cursor


ARROW = [
    "X", "XX", "X.X", "X..X", "X...X", "X....X", "X.....X", "X......X",
    "X.......X", "X........X", "X.....XXXXX", "X..X..X", "X.X X..X",
    "XX  X..X", "X    X..X", "     X..X", "      XX",
]


def on_circle(cx, cy, r, turn):
    """Point at the given fraction of a turn, clockwise from twelve o'clock."""
    a = 2 * math.pi * turn - math.pi / 2
    return cx + r * math.cos(a), cy + r * math.sin(a)


# --- scene -------------------------------------------------------------------

def root():
    rect_fill([0, 0, W - 1, H - 1], "gray50")
    cx, cy = 344, 248  # the X-shaped root cursor
    for o in (-1, 0, 1):
        d.line([cx - 7 + o, cy - 7, cx + 7 + o, cy + 7], fill=INK)
        d.line([cx - 7 + o, cy + 7, cx + 7 + o, cy - 7], fill=INK)


def terminal():
    xterm(20, 24, 330, SESSION, focused=True, selected=SELECTED)


def bitmap_editor():
    x, y, w, h = 372, 16, 376, 262
    top = window(x, y, w, h, "bitmap")
    for i, name in enumerate(["Clear All", "Set All", "Invert All", "Line",
                              "Circle", "Flood Fill", "Write", "Quit"]):
        by = top + 10 + i * 22
        d.rectangle([x + 10, by, x + 87, by + 16], outline=INK)
        ctext(x + 49, by + 2, name)

    gx, gy, cell, n = x + 100, top + 10, 9, 24
    for i in range(n + 1):  # dotted grid
        for k in range(0, n * cell + 1, 2):
            px[gx + i * cell, gy + k] = INK
            px[gx + k, gy + i * cell] = INK
    for j, row in enumerate(MUG):
        for i, c in enumerate(row):
            if c == "X":
                d.rectangle([gx + i * cell + 1, gy + j * cell + 1,
                             gx + (i + 1) * cell - 1, gy + (j + 1) * cell - 1], fill=INK)

    # actual-size previews, normal and inverted
    for k, inverse in enumerate((False, True)):
        bx, by = x + 330, top + 10 + k * 40
        d.rectangle([bx, by, bx + 29, by + 29], fill=PAPER, outline=INK)
        bitmap(bx + 3, by + 3, MUG)
        if inverse:
            invert([bx + 1, by + 1, bx + 28, by + 28])


def clock():
    x, y, w, h = 24, 246, 130, 150
    top = window(x, y, w, h, "xclock")
    cx, cy, r = x + w // 2, top + (h - TITLE_H) // 2, 56
    for i in range(60):
        px_, py_ = on_circle(cx, cy, r, i / 60)
        qx, qy = on_circle(cx, cy, r - (8 if i % 5 == 0 else 2), i / 60)
        d.line([px_, py_, qx, qy], fill=INK)
    for turn, length, half in ((10.17 / 12, 30, 4), (10 / 60, 46, 3)):  # 10:10
        tip = on_circle(cx, cy, length, turn)
        left = on_circle(cx, cy, half, turn - 0.25)
        right = on_circle(cx, cy, half, turn + 0.25)
        back = on_circle(cx, cy, 6, turn + 0.5)
        d.polygon([tip, left, back, right], fill=INK)


def eyes(look_at):
    x, y, w, h = 176, 240, 150, 110
    top = window(x, y, w, h, "xeyes")
    cy = top + (h - TITLE_H) // 2 - 1
    for cx in (x + 40, x + 110):
        d.ellipse([cx - 30, cy - 40, cx + 30, cy + 40], fill=INK)
        d.ellipse([cx - 24, cy - 34, cx + 24, cy + 34], fill=PAPER)
        dx, dy = look_at[0] - cx, look_at[1] - cy
        dist = math.hypot(dx, dy)
        px_, py_ = cx + dx / dist * 14, cy + dy / dist * 22
        d.ellipse([px_ - 7, py_ - 7, px_ + 7, py_ + 7], fill=INK)


def load():
    x, y, w, h = 176, 366, 150, 84
    top = window(x, y, w, h, "xload")
    text(x + 8, top + 2, "localhost")
    left, right, base, height = x + 4, x + w - 5, y + h - 4, 44
    rnd = random.Random(3)
    level = 0.3
    for bx in range(left, right + 1):
        level = min(1.0, max(0.05, level + rnd.uniform(-0.09, 0.1)))
        d.line([bx, base, bx, base - int(level * height)], fill=INK)
    for frac in (1 / 3, 2 / 3):  # scale lines, drawn through the graph
        ly = base - int(frac * height)
        for bx in range(left, right + 1, 2):
            px[bx, ly] = 1 - px[bx, ly]


def calculator():
    x, y, w, h = 350, 292, 150, 178
    top = window(x, y, w, h, "xcalc")
    d.rectangle([x + 8, top + 6, x + w - 9, top + 27], outline=INK)
    text(x + 13, top + 10, "DEG")
    s = "3.14159"
    text(x + w - 14 - tw(s, BOLD), top + 10, s, BOLD)
    keys = [
        ["1/x", "x^2", "CE", "AC", "INV"],
        ["sin", "cos", "tan", "log", "ln"],
        ["EE", "(", ")", "y^x", "/"],
        ["STO", "7", "8", "9", "*"],
        ["RCL", "4", "5", "6", "-"],
        ["SUM", "1", "2", "3", "+"],
        ["EXC", "0", ".", "+/-", "="],
    ]
    for r, row in enumerate(keys):
        for c, k in enumerate(row):
            bx, by = x + 8 + c * 27, top + 34 + r * 17
            d.rectangle([bx, by, bx + 24, by + 14], outline=INK)
            ctext(bx + 12, by + 1, k)


def second_terminal():
    xterm(522, 292, 226, [
        "$ ls /",
        "bin   dev   home  mnt   root  usr",
        "boot  etc   lib   proc  tmp   var",
        "$ make hello",
        "cc -O2 -o hello hello.c",
        "$ ",
    ])


def mailbox():
    x, y, w, h = 522, 410, 80, 88
    top = window(x, y, w, h, "xbiff")
    cx = x + w // 2
    d.rectangle([cx - 2, top + 40, cx + 2, top + 64], fill=INK)                    # post
    d.rounded_rectangle([x + 12, top + 16, x + 66, top + 42], radius=13, fill=PAPER, outline=INK, width=2)
    d.arc([x + 12, top + 16, x + 38, top + 42], 270, 90, fill=INK)                 # door
    d.line([x + 52, top + 30, x + 52, top + 6], fill=INK, width=2)                 # flag, raised
    d.rectangle([x + 52, top + 6, x + 62, top + 12], fill=INK)


def twm_menu():
    x, y, w, row = 640, 392, 112, 16
    items = ["Iconify", "Resize", "Move", "Raise", "Kill", "Exit"]
    h = (len(items) + 1) * row + 2
    rect_fill([x + 4, y + 4, x + w + 3, y + h + 3], "black")  # menu shadow
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=PAPER, outline=INK)
    ctext(x + w // 2, y + 2, "Twm", BOLD)
    d.line([x, y + row + 1, x + w - 1, y + row + 1], fill=INK)
    for i, item in enumerate(items):
        iy = y + row + 2 + i * row
        if item == "Move":
            d.rectangle([x + 1, iy, x + w - 2, iy + row - 1], fill=INK)
            text(x + 10, iy + 1, item, BOLD, PAPER)
            pointer = (x + 78, iy + 6)
        else:
            text(x + 10, iy + 1, item, BOLD)
    bitmap(pointer[0], pointer[1], ARROW)
    return pointer


def icon():
    """An iconified window, the way twm leaves them on the root."""
    x, y, w, h = 24, 414, 68, 46
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=PAPER, outline=INK, width=2)
    cx = x + w // 2
    d.rectangle([cx - 13, y + 6, cx + 13, y + 26], outline=INK)
    d.line([cx - 9, y + 12, cx - 6, y + 15, cx - 9, y + 18], fill=INK)
    d.line([cx - 3, y + 19, cx + 4, y + 19], fill=INK)
    ctext(cx, y + 30, "xconsole")


root()
terminal()
bitmap_editor()
clock()
load()
calculator()
second_terminal()
mailbox()
icon()
eyes(look_at=twm_menu())

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
