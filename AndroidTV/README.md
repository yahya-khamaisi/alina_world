# Alina World for Android TV

The Mac game ported to Kotlin for Google TV / Android TV, played with the TV remote. It uses the same
27 missions (read from `../Sources/AlinaWorld/Resources/Missions.json` at build time), pixel sprites,
chiptune soundtrack and icon-first menus. Package `app.jannat.alinaworld`.

## Build and install

`JAVA_HOME` must point at Android Studio's bundled JDK.

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
```

```bash
./gradlew :app:assembleRelease
```

With wireless debugging on and the TV paired, `adb mdns services` shows its address:

```bash
adb connect 192.168.1.10:<port>
```

```bash
adb install -r app/build/outputs/apk/release/app-release.apk
```

Jump straight to a screen while developing (`map`, `story:8`, `play:8`, `settings`):

```bash
adb shell am start -S -n app.jannat.alinaworld/.MainActivity -e route play:8
```

## Remote controls

Made for the standard TCL remote, whose arrows and OK share one ring under the thumb: a direction can't be
held while pressing OK, so Alina auto-runs.

| Press | In a mission | In menus |
|---|---|---|
| ◀ ▶ (tap) | Start running that way; the other arrow turns her around | Move focus / change a setting |
| ◀ ▶ (hold) | Sprint; she keeps sprinting after you let go | |
| ▼ | Stop | Move focus |
| OK or ▲ | Jump at full height, even on a quick tap; hold while falling to glide | Select |
| Back | Pause | Back |

Auto-run can be turned off in Settings, which brings back hold-to-move.

A Bluetooth gamepad also works: stick or D-pad to move, A to jump, X or a shoulder button to sprint,
Start to pause.

## Layout

- `game/` — simulation (`GameWorld`, `Player`, `Level`), the Canvas renderer and the `GameView` frame loop.
- `pixel/` — the sprite catalog shared with the Mac app, rendered to nearest-filtered bitmaps.
- `audio/` — the chiptune synthesizer and songs, streamed through `AudioTrack`.
- `ui/` — Compose screens on a 1280 × 720 design canvas scaled to the TV.
- `tools/make-banner.sh` — renders the launcher banner from the Mac sprites.
