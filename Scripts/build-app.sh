#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

chmod +x "$ROOT/Scripts/make-icon.sh"
"$ROOT/Scripts/make-icon.sh"

echo "Building AlinaWorld (release)..."
swift build -c release

APP="$ROOT/dist/AlinaWorld.app"
BIN="$ROOT/.build/release/AlinaWorld"
RES_BUNDLE="$ROOT/.build/release/AlinaWorld_AlinaWorld.bundle"

if [[ ! -f "$BIN" ]]; then
    BIN="$ROOT/.build/out/Release/AlinaWorld"
    RES_BUNDLE="$ROOT/.build/out/Release/AlinaWorld_AlinaWorld.bundle"
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/AlinaWorld"
cp "$ROOT/Scripts/Info.plist" "$APP/Contents/Info.plist"

if [[ -d "$RES_BUNDLE" ]]; then
    cp -R "$RES_BUNDLE" "$APP/Contents/Resources/AlinaWorld_AlinaWorld.bundle"
fi

if [[ -f "$ROOT/Sources/AlinaWorld/Resources/Missions.json" ]]; then
    cp "$ROOT/Sources/AlinaWorld/Resources/Missions.json" "$APP/Contents/Resources/"
elif [[ -f "$RES_BUNDLE/Contents/Resources/Missions.json" ]]; then
    cp "$RES_BUNDLE/Contents/Resources/Missions.json" "$APP/Contents/Resources/"
fi

if [[ -f "$ROOT/Sources/AlinaWorld/Resources/AlinaArt.png" ]]; then
    cp "$ROOT/Sources/AlinaWorld/Resources/AlinaArt.png" "$APP/Contents/Resources/"
fi

if [[ -f "$ROOT/Sources/AlinaWorld/Resources/AppIcon.icns" ]]; then
    cp "$ROOT/Sources/AlinaWorld/Resources/AppIcon.icns" "$APP/Contents/Resources/"
fi

echo "Built: $APP"

if [[ "${1:-}" == "--open" ]]; then
    open "$APP"
fi
