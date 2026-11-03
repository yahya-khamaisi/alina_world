#!/usr/bin/env python3
"""Regenerates the tile rows and flyer placements of every mission in Missions.json.

Layouts are deterministic per mission `layoutSeed`, so re-running the script is safe.
Tile legend (see TileMap.swift):
  = ground   # stone   B mossbrick   ? bloom block   P log pillar   _ leaf-pad
  C petal    * heart shard   E crawler   X guardian   ^ thorns   F beacon
"""
import json
import pathlib
import random

HEIGHT = 14
GROUND_ROWS = (12, 13)
STAND = 11  # row Alina stands in when on the ground
MISSIONS = pathlib.Path(__file__).resolve().parent.parent / "Sources/AlinaWorld/Resources/Missions.json"


class Level:
    def __init__(self, width):
        self.width = width
        self.grid = [["." for _ in range(width)] for _ in range(HEIGHT)]
        for x in range(width):
            for y in GROUND_ROWS:
                self.grid[y][x] = "="

    def set(self, x, y, ch):
        if 0 <= x < self.width and 0 <= y < HEIGHT:
            self.grid[y][x] = ch

    def get(self, x, y):
        return self.grid[y][x]

    def has_ground(self, x):
        return self.grid[GROUND_ROWS[0]][x] == "="

    def column_clear(self, x, top, bottom):
        return all(self.grid[y][x] == "." for y in range(top, bottom + 1))

    def rows(self):
        return ["".join(r) for r in self.grid]


def petal_arc(lv, x, rng):
    n = rng.randint(3, 5)
    for i in range(n):
        peak = 0 < i < n - 1
        lv.set(x + i, 9 if peak else 10, "C")
    return x + n


def block_row(lv, x, rng):
    pattern = rng.choice(["B?B", "?B?B?", "B??B", "?", "BB?BB"])
    for i, ch in enumerate(pattern):
        lv.set(x + i, 8, ch)
    return x + len(pattern)


def pit(lv, x, rng, hard):
    w = rng.randint(2, 2 + hard)
    for i in range(w):
        for y in GROUND_ROWS:
            lv.set(x + i, y, ".")
    if w >= 3:
        lv.set(x + w // 2, 10, "C")
    return x + w


def stairs(lv, x, rng):
    h = rng.randint(2, 3)
    col = x
    for step in range(1, h + 1):
        for y in range(STAND - step + 1, STAND + 1):
            lv.set(col, y, "#")
        col += 1
    for _ in range(2):
        for y in range(STAND - h + 1, STAND + 1):
            lv.set(col, y, "#")
        col += 1
    lv.set(col - 2, STAND - h, "C")
    lv.set(col - 1, STAND - h, "C")
    for step in range(h - 1, 0, -1):
        for y in range(STAND - step + 1, STAND + 1):
            lv.set(col, y, "#")
        col += 1
    return col


def logs(lv, x, rng):
    count = rng.randint(1, 2)
    for i in range(count):
        cx = x + i * 4
        lv.set(cx, 10, "P")
        lv.set(cx, 11, "P")
        lv.set(cx, 9, "C")
    return x + count * 4


def leaf_bridge(lv, x, rng):
    w = rng.randint(5, 6)
    for i in range(w):
        for y in GROUND_ROWS:
            lv.set(x + i, y, ".")
    for i in range(1, w - 1):
        lv.set(x + i, 10, "_")
    for i in range(2, w - 2):
        lv.set(x + i, 8, "C")
    return x + w


def crawlers(lv, x, rng, hard):
    count = 1 + (1 if hard and rng.random() < 0.5 else 0)
    for i in range(count):
        lv.set(x + 3 + i * 3, STAND, "E")
    return x + 4 + count * 3


def thorns(lv, x, rng, hard):
    w = 1 + (1 if hard and rng.random() < 0.6 else 0)
    for i in range(w):
        lv.set(x + i, STAND, "^")
    lv.set(x, 9, "C")
    return x + w


def place_shards(lv, count, start, end, rng):
    placed = 0
    span = (end - start) / count
    for n in range(count):
        lo, hi = int(start + n * span), int(start + (n + 1) * span) - 1
        candidates = [
            (x, y)
            for x in range(lo, max(lo + 1, hi))
            for y in (9, 7, 10)
            if lv.get(x, y) == "." and lv.get(x, STAND) == "."
            and (lv.get(x, y + 1) in "_#B?" or (y >= 9 and lv.has_ground(x)))
        ]
        if candidates:
            x, y = rng.choice(candidates)
            lv.set(x, y, "*")
            placed += 1
    return placed


def flyers(lv, mission, rng, end):
    world_index = (mission["id"] - 1) // 3
    if world_index < 2:
        return []
    out = []
    for _ in range(1 + world_index // 2):
        for _attempt in range(20):
            x = rng.randint(24, end - 4)
            y = rng.choice([7, 8])
            if lv.get(x, y) == "." and lv.get(x, y + 1) == ".":
                out.append({"x": x, "y": y, "kind": "flyer", "patrol": rng.choice([64, 96, 128])})
                break
    return out


def build(mission):
    rng = random.Random(mission["layoutSeed"])
    world_index = (mission["id"] - 1) // 3
    hard = {"easy": 0, "normal": 1, "hard": 2}[mission["difficulty"]]
    objective = mission["objective"]

    width = 96 + mission["id"] * 4
    lv = Level(width)
    arena = 24 if objective == "defeatBoss" else 10
    end = width - arena

    segments = ["petals", "blocks", "pit", "stairs", "logs", "bridge", "crawlers"]
    if world_index >= 3:
        segments.append("thorns")
    weights = [3, 3, 1 + hard, 2, 2, 1 + hard, 2 + hard] + ([1 + hard] if world_index >= 3 else [])

    x, last_gap = 8, -20
    while x < end - 12:
        kind = rng.choices(segments, weights)[0]
        if kind in ("pit", "bridge") and x - last_gap < 10:
            kind = "petals"
        if kind == "petals":
            x = petal_arc(lv, x, rng)
        elif kind == "blocks":
            x = block_row(lv, x, rng)
        elif kind == "pit":
            x = pit(lv, x, rng, hard)
            last_gap = x
        elif kind == "stairs":
            x = stairs(lv, x, rng)
        elif kind == "logs":
            x = logs(lv, x, rng)
        elif kind == "bridge":
            x = leaf_bridge(lv, x, rng)
            last_gap = x
        elif kind == "crawlers":
            x = crawlers(lv, x, rng, hard)
        elif kind == "thorns":
            x = thorns(lv, x, rng, hard)
        x += rng.randint(2, 4)

    if objective == "reachFlag":
        lv.set(width - 5, STAND, "F")
    elif objective == "defeatBoss":
        lv.set(end + 2, 8, "?")
        lv.set(end + 4, 8, "?")
        lv.set(width - 7, STAND, "X")
    elif objective == "collectN":
        place_shards(lv, (mission["collectTarget"] or 1) + 1, 10, end, rng)

    mission["rows"] = lv.rows()
    mission["enemies"] = flyers(lv, mission, rng, end)


def main():
    data = json.loads(MISSIONS.read_text())
    for mission in data["missions"]:
        build(mission)
    MISSIONS.write_text(json.dumps(data, indent=2) + "\n")
    print(f"Rebuilt {len(data['missions'])} missions → {MISSIONS}")


if __name__ == "__main__":
    main()
