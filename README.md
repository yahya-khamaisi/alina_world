# AlinaWorld

**AlinaWorld** is an original 2D platformer for macOS starring **Alina**, a girl from the Lumen Isles who must reclaim nine stolen Heart Crystals from the Night Crown across **27 missions**.

Inspired by classic side-scrolling platformer feel (acceleration, sprint, variable jump, stomp attacks) — not Nintendo assets or trademarks.

## Story

The Lumen Isles stay awake thanks to nine Heart Crystals. The Night Crown scatters them across nine worlds in three acts. Alina runs, jumps, and stomps through meadow, brook, grove, cavern, ridge, marsh, spire, storm, and the throne — one mission at a time until the finale.

## Controls (keyboard only)

| Key | Action |
|-----|--------|
| ← → or A D | Move (in-game) |
| ↑ ↓ ← → | Navigate menus / mission map |
| Shift | Sprint |
| Space, W, or ↑ | Jump (in-game) |
| Enter | Confirm / start mission / next mission |
| F | Toggle fullscreen |
| Esc | Back / pause |

## Requirements

- macOS 13+
- Swift 5.9+ (Command Line Tools)

## Build & run

```bash
chmod +x Scripts/build-app.sh
./Scripts/build-app.sh --open
```

The app bundle is created at `dist/AlinaWorld.app`.

Development build:

```bash
swift build
swift run
```

## Mission structure

- **27 missions** across 9 worlds (3 per world)
- Objectives: reach beacon, collect crystals, defeat guardians
- Difficulty ramps from Act I (easy) through Act III (hard, timed missions)
- Progress unlocks sequentially; best coin counts are saved per mission

## Project layout

- `Sources/AlinaWorld/App` — SwiftUI shell
- `Sources/AlinaWorld/Game` — SpriteKit scene, physics, entities
- `Sources/AlinaWorld/Data` — missions, story, progress
- `Sources/AlinaWorld/Resources/Missions.json` — all level data

## License

Original work for personal use. Do not redistribute Nintendo-derived assets.
