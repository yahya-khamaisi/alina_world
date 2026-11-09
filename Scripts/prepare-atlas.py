#!/usr/bin/env python3
"""Measure transparent atlas frames without changing the source painting.

Example: python3 Scripts/prepare-atlas.py sheet.png frames.json --columns 4 --rows 2 --largest
Requires Pillow. Frame order is row-major, as documented in design/art-v3/README.md.
"""
import argparse
import json
from collections import deque
from pathlib import Path
from PIL import Image


def bounds(cell, largest):
    alpha = cell.getchannel('A')
    if not largest:
        return alpha.point(lambda value: 255 if value > 80 else 0).getbbox()
    mask = bytearray(1 if value > 80 else 0 for value in alpha.getdata())
    width, height = cell.size
    best = []
    for start in range(width * height):
        if not mask[start]:
            continue
        mask[start] = 0
        queue, component = deque([start]), []
        while queue:
            value = queue.popleft()
            component.append(value)
            x, y = value % width, value // width
            for nx, ny in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]:
                if 0 <= nx < width and 0 <= ny < height:
                    index = ny * width + nx
                    if mask[index]:
                        mask[index] = 0
                        queue.append(index)
        if len(component) > len(best):
            best = component
    if not best:
        return None
    xs, ys = [value % width for value in best], [value // width for value in best]
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('destination', type=Path)
    parser.add_argument('--columns', type=int, required=True)
    parser.add_argument('--rows', type=int, required=True)
    parser.add_argument('--largest', action='store_true', help='Ignore detached halo/noise from neighbouring cells')
    args = parser.parse_args()
    if args.columns < 1 or args.rows < 1:
        parser.error('Grid dimensions must be positive')
    image = Image.open(args.source).convert('RGBA')
    if image.getchannel('A').getextrema()[0] == 255:
        parser.error('Source must have a transparent background')
    frames = []
    for row in range(args.rows):
        for column in range(args.columns):
            x0, y0 = column * image.width // args.columns, row * image.height // args.rows
            x1, y1 = (column + 1) * image.width // args.columns, (row + 1) * image.height // args.rows
            cell = image.crop((x0, y0, x1, y1))
            rect = bounds(cell, args.largest)
            if rect is None:
                parser.error(f'Empty cell at row {row}, column {column}')
            left, top = max(0, rect[0] - 2), max(0, rect[1] - 2)
            right, bottom = min(cell.width, rect[2] + 2), min(cell.height, rect[3] + 2)
            frames.append([x0 + left, y0 + top, right - left, bottom - top])
    args.destination.write_text(json.dumps(frames, indent=2) + '\n')
    print(f'{args.destination}: {len(frames)} frames, source preserved')


if __name__ == '__main__':
    main()
