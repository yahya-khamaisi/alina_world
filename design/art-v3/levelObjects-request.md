Next task (art only, please do NOT edit any Swift code - Claude is wiring the code in parallel in this same repo): generate ONE new transparent sprite atlas for the level objects that are still pixel art, in exactly the same polished hand-painted storybook style as propsHD / enemiesHD (smooth plum contours, rich shading, warm golden highlights, NOT pixel art). STRICT 4-COLUMN by 3-ROW grid of exactly TWELVE isolated objects, each centered inside equal cells with clear transparent padding, nothing crossing cell borders, genuinely transparent background, no labels, no grid lines, no shadows or ground patches. Front-on orthographic side view.

Row 1: (1) golden Bloom Block - a perfect square gold treasure block with an embossed pink five-petal flower and a sparkle, straight square edges so blocks tile side by side; (2) the same block after use - dull lavender-grey stone square with a faded flower imprint, straight square edges; (3) mossy brick block - perfect square of warm terracotta bricks with moss along the top, straight edges; (4) upright wooden log segment that fills a perfect square, bark texture, stackable top and bottom.

Row 2: (5) thorn bramble hazard - a low wide row of sharp curved thorns on dark red-brown vines, flat bottom, about 2:1 wide; (6) coral spring shell bouncer - pink scallop shell on a small sand mound, square; (7) floating grassy island platform segment - wide about 2:1, lush grass top edge, rounded earth underside with hanging vines and tiny white flowers; (8) fluffy cloud platform - wide about 3:1, soft pink-tinted cumulus with a flat walkable top.

Row 3: (9) pink petal collectible with a tiny sparkle; (10) Heart Crystal - faceted violet heart gem in a gold setting; (11) Sunbloom power-up - glowing golden sunflower; (12) Glow Ribbon power-up - a looped glowing pink ribbon.

Save it as Sources/AlinaWorld/Resources/Art/LevelObjects.png, then run:
python3 Scripts/prepare-atlas.py Sources/AlinaWorld/Resources/Art/LevelObjects.png Sources/AlinaWorld/Resources/Art/LevelObjectsFrames.json --columns 4 --rows 3 --largest
Add the prompt to design/art-v3/prompts.json as levelObjectsHD and a line to design/art-v3/README.md. Then stop.
