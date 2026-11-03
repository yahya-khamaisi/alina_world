#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/Sources/AlinaWorld/Resources/AppIcon-1024.png"
ICONSET="$ROOT/Sources/AlinaWorld/Resources/AppIcon.iconset"
OUT="$ROOT/Sources/AlinaWorld/Resources/AppIcon.icns"

# Render the icon from the game's pixel sprites so it always matches the in-game art.
PIXEL="$ROOT/Sources/AlinaWorld/Game/Pixel"
RENDERER="$ROOT/.build/icon-renderer"
mkdir -p "$ROOT/.build"
swiftc -O -swift-version 5 -module-name IconRenderer -o "$RENDERER" \
    "$PIXEL/PixelArt.swift" "$PIXEL/PixelCatalog.swift" "$ROOT/Sources/AlinaWorld/Game/WorldTheme.swift" \
    "$ROOT/Scripts/IconRenderer/main.swift"
"$RENDERER" "$SRC"
cp "$SRC" "$ROOT/Sources/AlinaWorld/Resources/icon.png"

mkdir -p "$ICONSET"
sips -z 16 16     "$SRC" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32     "$SRC" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32     "$SRC" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64     "$SRC" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128   "$SRC" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256   "$SRC" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$SRC" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512   "$SRC" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$SRC" --out "$ICONSET/icon_512x512.png" >/dev/null
cp "$SRC" "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o "$OUT"
echo "Created $OUT"
