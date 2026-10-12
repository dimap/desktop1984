#!/usr/bin/env python3
"""Converts a picture to the 1-bit bitmap the wallpaper flies over.

    convert.py input.png output.png [--width N] [--gamma G] [--sharpen PCT] [--threshold]

Mid-tones become an ordered (Bayer) dither, which reads as a regular grid of
tiles; --threshold gives plain black and white instead. The wallpaper can also
convert a picture on its own at run time; this script only gives finer control.
"""
import argparse

from PIL import Image, ImageFilter, ImageOps

BAYER4 = [
    [0, 8, 2, 10],
    [12, 4, 14, 6],
    [3, 11, 1, 9],
    [15, 7, 13, 5],
]


def convert(src, width=None, gamma=1.0, sharpen=120, threshold=False):
    img = Image.open(src).convert("L")
    if width and width != img.width:
        img = img.resize((width, round(img.height * width / img.width)), Image.LANCZOS)
    if sharpen:
        img = img.filter(ImageFilter.UnsharpMask(radius=2, percent=sharpen, threshold=2))
    img = ImageOps.autocontrast(img, cutoff=1)
    lut = [round(255 * (i / 255) ** (1 / gamma)) for i in range(256)]
    img = img.point(lut)

    out = Image.new("1", img.size, 1)
    src_px, out_px = img.load(), out.load()
    for y in range(img.height):
        for x in range(img.width):
            limit = 127.5 if threshold else (BAYER4[y % 4][x % 4] + 0.5) * 255 / 16
            out_px[x, y] = 1 if src_px[x, y] > limit else 0
    return out


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input")
    ap.add_argument("output")
    ap.add_argument("--width", type=int, help="resize to this many cells across")
    ap.add_argument("--gamma", type=float, default=1.0, help="above 1 lightens mid-tones, below 1 darkens")
    ap.add_argument("--sharpen", type=int, default=120, help="unsharp mask strength, percent; 0 to disable")
    ap.add_argument("--threshold", action="store_true", help="plain black and white, no dither")
    args = ap.parse_args()
    convert(args.input, args.width, args.gamma, args.sharpen, args.threshold).save(args.output, optimize=True)
