# Illustrated 2D production art

Latest direction: sharp, high-quality 2D illustration with smooth contours and rich shading. Keep the warm pink/gold/green storybook palette. Do not quantize, pixelate, or use nearest-neighbour sampling for these assets.

Generated using the built-in image generation tool. The exact final prompt set is in [prompts.json](prompts.json). Earlier mockups remain composition references; the production art is newly generated and contains no baked-in UI.

## Assets

All final paintings are saved in `Sources/AlinaWorld/Resources/Art/`:

| File | Use |
| --- | --- |
| `TitleMeadow.png` | Title scene with blossom tree, village, waterfalls and sunset |
| `LumenIsles.png` | Twelve-island world map, without labels or trails |
| `MeadowDistance.png` | Meadow parallax panorama |
| `MeadowTerrain.png` | Continuous grass/soil painting sampled into adjacent terrain tiles |
| `TerrainEdges.png` | Transparent 2-column, 2-row atlas of left grass overhang, earth side wall, hanging roots and flowering vine; bounds in `TerrainEdgesFrames.json` |
| `AlinaIllustrated.png` | Transparent 4-column, 2-row character animation sheet |
| `AlinaRig.png` | Transparent 4-column, 3-row cut-out puppet sheet with twelve Alina parts at a shared anatomical scale; bounds in `AlinaRigFrames.json` |
| `SceneryIllustrated.png` | Transparent 3-column, 2-row prop sheet |
| `CreaturesIllustrated.png` | Transparent 3-column, 3-row creature sheet |
| `CreatureRig.png` | Transparent 4-column, 4-row cut-out creature rig sheet with sixteen parts at a shared scale; bounds in `CreatureRigFrames.json` |
| `LevelObjects.png` | Transparent 4-column, 3-row atlas of twelve illustrated level blocks, hazards, platforms, collectibles and power-ups; bounds in `LevelObjectsFrames.json` |

Frame bounds are `[x, y, width, height]` in source image coordinates, ordered left-to-right, then top-to-bottom. The game crops the source PNGs at runtime and caches textures. Source paintings remain unchanged.

- Alina: idle, blink, run A, run B, jump, double jump, fall, glide.
- Scenery: blossom tree, flowering bush, mossy boulder, fence, wildflowers, lantern beacon.
- Creatures: Gloomling, Gloomling step, Thornbeetle, Mothwisp, Mothwisp folded wings, guardian, Frostpuff, Shellcrab, Starwisp.

The character uses a common source scale and foot baseline across all poses. The glide frame has a wider canvas to include its ribbon. Collision geometry stays independent from artwork.

To regenerate metadata (requires Pillow):

```bash
python3 Scripts/prepare-atlas.py Sources/AlinaWorld/Resources/Art/AlinaIllustrated.png Sources/AlinaWorld/Resources/Art/AlinaFrames.json --columns 4 --rows 2 --largest
python3 Scripts/prepare-atlas.py Sources/AlinaWorld/Resources/Art/SceneryIllustrated.png Sources/AlinaWorld/Resources/Art/SceneryIllustratedFrames.json --columns 3 --rows 2
python3 Scripts/prepare-atlas.py Sources/AlinaWorld/Resources/Art/CreaturesIllustrated.png Sources/AlinaWorld/Resources/Art/CreaturesIllustratedFrames.json --columns 3 --rows 3 --largest
```

The older `Scripts/pixelate-art.py` belongs to the abandoned pixel-style direction and is not part of this pipeline.
