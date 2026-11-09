#!/usr/bin/env python3
"""Snap a painted (ChatGPT) image onto a true pixel grid for the game.

The v3 art is painterly with pixel texture but no real grid, so it blurs or shimmers when scaled. This downsamples
to a fixed art resolution, reduces the palette, optionally keys out a flat background colour, and writes a small
PNG the game draws with nearest-neighbour filtering.

    Scripts/pixelate-art.py in.png out.png --width 480 [--colors 64] [--key ff00ff] [--crop x0,y0,x1,y1]
"""
import argparse
from PIL import Image


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--width", type=int, required=True, help="art pixels across")
    ap.add_argument("--colors", type=int, default=64)
    ap.add_argument("--key", help="hex colour to make transparent (chroma key), e.g. ff00ff")
    ap.add_argument("--tolerance", type=int, default=90)
    ap.add_argument("--crop", help="x0,y0,x1,y1 in source pixels")
    args = ap.parse_args()

    im = Image.open(args.src).convert("RGBA")
    if args.crop:
        im = im.crop(tuple(int(v) for v in args.crop.split(",")))
    height = round(im.height * args.width / im.width)

    alpha = None
    if args.key:
        kr, kg, kb = (int(args.key[i:i + 2], 16) for i in (0, 2, 4))
        px = im.load()
        mask = Image.new("L", im.size, 255)
        mp = mask.load()
        for y in range(im.height):
            for x in range(im.width):
                r, g, b, _ = px[x, y]
                if abs(r - kr) + abs(g - kg) + abs(b - kb) < args.tolerance:
                    mp[x, y] = 0
        alpha = mask.resize((args.width, height), Image.BOX).point(lambda a: 255 if a > 140 else 0)

    small = im.convert("RGB").resize((args.width, height), Image.LANCZOS)
    small = small.quantize(colors=args.colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGBA")
    if alpha is not None:
        small.putalpha(alpha)
    small.save(args.dst)
    print(f"{args.dst}: {args.width}x{height}")


if __name__ == "__main__":
    main()
