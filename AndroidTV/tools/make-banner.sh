#!/usr/bin/env bash
# Renders the launcher banner from the Mac game's pixel sprites, so the TV tile matches the in-game art.
set -euo pipefail
TV="$(cd "$(dirname "$0")/.." && pwd)"
PIXEL="$TV/../Sources/AlinaWorld/Game/Pixel"
BIN="$TV/build/banner-renderer"
mkdir -p "$TV/build" "$TV/app/src/main/res/drawable-xhdpi"
swiftc -O -swift-version 5 -module-name BannerRenderer -o "$BIN" \
    "$PIXEL/PixelArt.swift" "$PIXEL/PixelCatalog.swift" "$TV/../Sources/AlinaWorld/Game/WorldTheme.swift" \
    "$TV/tools/BannerRenderer/main.swift"
"$BIN" "$TV/app/src/main/res/drawable-xhdpi/banner.png"
