Next task (art only, do NOT edit Swift code - Claude is building a bone rig in SpriteKit that will load this sheet): paint Alina as a CUT-OUT ANIMATION PARTS SHEET, like a professional 2D cut-out / puppet rig, so each body part can be rotated on its own. Exactly the same character, colours and polished hand-painted storybook style as alinaHD (brown wavy hair, big pink bow, pink puff-sleeve dress with white collar, gold belt, white frilly hem, white socks, brown boots, plum contour lines, NOT pixel art).

Every part is painted at ONE SHARED SCALE (as if the assembled character were about 900 px tall), viewed from the side in a 3/4 view facing RIGHT, each part complete and isolated (no missing edges where parts overlap - paint a little extra at every joint so rotated parts still overlap cleanly), genuinely transparent background, no labels, no grid lines, no shadows. STRICT 4-COLUMN by 3-ROW grid of exactly TWELVE parts, each centered in its equal cell with transparent padding, nothing crossing cell borders:

Row 1: (1) HEAD with face and front bangs, smiling, eyes open, no back hair, no bow; (2) the same head with eyes closed (blink); (3) the same head with a big happy open-mouth expression (for jumping); (4) the big pink BOW on its own.
Row 2: (5) BACK HAIR - the long wavy hair mass that hangs behind the head and shoulders, on its own; (6) TORSO - chest with white collar, puff sleeves (shoulders) and gold belt, no arms, no skirt; (7) SKIRT - the flared pink skirt with white frilly hem, on its own, hanging straight down; (8) one loose wavy FRONT HAIR LOCK that falls beside the face.
Row 3: (9) UPPER ARM (skin, hanging straight down); (10) FOREARM with an open hand, hanging straight down; (11) THIGH with the white sock top, hanging straight down; (12) SHIN with brown BOOT, hanging straight down, toe pointing right.

Save as Sources/AlinaWorld/Resources/Art/AlinaRig.png, then run:
python3 Scripts/prepare-atlas.py Sources/AlinaWorld/Resources/Art/AlinaRig.png Sources/AlinaWorld/Resources/Art/AlinaRigFrames.json --columns 4 --rows 3 --largest
Add the prompt to design/art-v3/prompts.json as alinaRigHD and a line in design/art-v3/README.md. Then stop.
