#!/usr/bin/env python3
"""Dehaze and upscale the painted world backdrops for the game.

Reads the source paintings from design/backdrops-v4/*Distance.png and writes
Sources/AlinaWorld/Resources/Art/<name>.jpg at twice the size:

1. Dark-channel dehaze: estimates the milky veil per pixel (strong on distant mountains and the misty
   lower band, absent on close detail) and removes most of it, keeping a little for depth.
2. Local contrast and a small saturation lift so distant detail reads.
3. Light denoise (median) to calm the generator's grain, then a Lanczos 2x upscale with no sharpening, so the
   GPU no longer stretches a small image on Retina screens and edges stay clean (no halos).

Usage: python3 Scripts/enhance-backdrops.py [names...]   (default: every *.png in the source folder)
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "design/backdrops-v4"
OUT = ROOT / "Sources/AlinaWorld/Resources/Art"

OMEGA = 0.68        # share of the estimated haze to remove (1 = all of it)
T_MIN = 0.42        # never amplify more than 1 / T_MIN
PATCH = 15          # dark-channel neighbourhood, in source pixels
SCALE = 2


def dehaze(img: Image.Image) -> Image.Image:
    rgb = np.asarray(img.convert("RGB"), dtype=np.float32) / 255.0
    h, w, _ = rgb.shape

    def dark_channel(a: np.ndarray) -> np.ndarray:
        m = Image.fromarray((a.min(axis=2) * 255).astype(np.uint8))
        return np.asarray(m.filter(ImageFilter.MinFilter(PATCH)), dtype=np.float32) / 255.0

    dark = dark_channel(rgb)
    # Atmospheric light: the colour of the haziest 0.2% of pixels (brightest dark channel).
    count = max(1, int(h * w * 0.002))
    idx = np.argpartition(dark.ravel(), -count)[-count:]
    airlight = rgb.reshape(-1, 3)[idx].mean(axis=0)
    airlight = np.clip(airlight, 0.75, 1.0)

    t = 1.0 - OMEGA * dark_channel(rgb / airlight)
    # Smooth the transmission so edges do not halo (a cheap stand-in for a guided filter).
    t_img = Image.fromarray((np.clip(t, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(radius=12))
    t = np.maximum(np.asarray(t_img, dtype=np.float32) / 255.0, T_MIN)[..., None]

    out = (rgb - airlight) / t + airlight
    out = np.clip(out, 0, 1)
    # Gentle levels: pull the darkest 0.5% to black-ish and the brightest 0.5% to white.
    lo, hi = np.percentile(out, 0.5), np.percentile(out, 99.85)
    out = np.clip((out - lo) / max(1e-3, hi - lo), 0, 1)
    result = Image.fromarray((out * 255 + 0.5).astype(np.uint8))
    result = ImageEnhance.Color(result).enhance(1.04)
    return result


def enhance(path: Path) -> Path:
    src = Image.open(path).convert("RGB").filter(ImageFilter.MedianFilter(3))
    img = dehaze(src)
    big = img.resize((img.width * SCALE, img.height * SCALE), Image.LANCZOS)
    big = big.filter(ImageFilter.GaussianBlur(radius=0.6))
    target = OUT / (path.stem + ".jpg")
    big.save(target, "JPEG", quality=93, optimize=True, progressive=True, subsampling=0)
    return target


def main() -> None:
    names = sys.argv[1:]
    paths = [SOURCE / f"{n}.png" for n in names] if names else sorted(SOURCE.glob("*Distance.png"))
    for p in paths:
        t = enhance(p)
        print(f"{p.name} -> {t.relative_to(ROOT)} ({t.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
