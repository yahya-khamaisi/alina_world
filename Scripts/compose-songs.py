#!/usr/bin/env python3
"""Composes the Alina World soundtrack and writes it for both apps.

Each song is written as scale degrees over a chord progression, so the shared hook (3 5 1' 7 5)
opens every world's tune in that world's own key. The script expands degrees to note names and
writes Sources/AlinaWorld/Audio/Soundtrack.swift and the Android TV Soundtrack.kt.

Melody tokens: degree 1–7, ' for an octave up, , for an octave down, # to raise a semitone,
. to hold, - to rest. Chords are scale degrees of their root; ^ raises the third (V in minor).
"""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SWIFT = ROOT / "Sources/AlinaWorld/Audio/Soundtrack.swift"
KOTLIN = ROOT / "AndroidTV/app/src/main/java/app/jannat/alinaworld/audio/Soundtrack.kt"

MODES = {
    "major": [0, 2, 4, 5, 7, 9, 11],
    "minor": [0, 2, 3, 5, 7, 8, 10],
    "dorian": [0, 2, 3, 5, 7, 9, 10],
}
NOTE = {"C": 0, "C#": 1, "Db": 1, "D": 2, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "Ab": 8, "A": 9, "Bb": 10, "B": 11}
NAMES = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]


def note_name(midi):
    return f"{NAMES[midi % 12]}{midi // 12 - 1}"


class Key:
    def __init__(self, tonic, mode, octave=5):
        self.base = 12 * (octave + 1) + NOTE[tonic]
        self.steps = MODES[mode]

    def degree(self, d, octave_shift=0, sharp=0):
        idx = d - 1
        return self.base + 12 * (idx // 7 + octave_shift) + self.steps[idx % 7] + sharp


def melody(key, bars):
    out = []
    for bar in bars:
        for tok in bar.split():
            if tok in (".", "-"):
                out.append(tok)
                continue
            shift = tok.count("'") - tok.count(",")
            sharp = tok.count("#")
            d = int(tok.strip("',#"))
            out.append(note_name(key.degree(d, shift, sharp)))
    return out


def chord_tones(key, chord, octave_shift):
    raise_third = chord.endswith("^")
    root = int(chord.rstrip("^"))
    return [key.degree(root, octave_shift), key.degree(root + 2, octave_shift, 1 if raise_third else 0), key.degree(root + 4, octave_shift)]


def harmony(key, chords, style, steps):
    out = []
    for chord in chords:
        r, t, f = (note_name(n) for n in chord_tones(key, chord, -1))
        pattern = {
            "arp": [r, t, f, t, r, t, f, t],
            "offbeat": ["-", t, "-", f, "-", t, "-", f],
            "pad": [t, ".", ".", ".", f, ".", ".", "."],
            "waltz": ["-", t, f, "-", t, f],
            "bells": [f, ".", t, ".", r, ".", t, "."],
            "pulse": [t, "-", t, "-", t, "-", t, "-"],
        }[style]
        out += pattern[:steps]
    return out


def bass(key, chords, style, steps):
    out = []
    for chord in chords:
        r, t, f = chord_tones(key, chord, -3)
        R, T, F, R2 = note_name(r), note_name(t), note_name(f), note_name(r + 12)
        pattern = {
            "root5": [R, ".", F, ".", R, ".", F, "."],
            "octave": [R, R2, R, R2, R, R2, R, R2],
            "walk": [R, ".", T, ".", F, ".", T, "."],
            "soft": [R, ".", ".", ".", F, ".", ".", "."],
            "waltz": [R, ".", ".", F, ".", "."],
            "bounce": [R, ".", "-", R, F, ".", "-", F],
        }[style]
        out += pattern[:steps]
    return out


SONGS = [
    # id, name, key, mode, bpm, lead, harmony voice, harmony style, bass style, drums, drum level, swing, chords, melody
    ("title", "Lumen Isles", "C", "major", 100, "musicBox", "pad", "arp", "soft", "k - h - s - h -", 0.45, 0.0,
     "1 6 4 5 1 6 5 1",
     ["3 . 5 . 1' . 7 5", "6 . . . 5 . 3 .", "4 . 6 . 1' . 6 .", "5 . . . 2 . 7, .",
      "3 . 5 . 1' . 2' .", "3' . 2' . 1' . 6 .", "6 . 1' . 7 . 5 .", "1' . . . - . . ."]),
    ("meadow", "Petal Path", "G", "major", 116, "flute", "softSquare", "offbeat", "root5", "k - h k s - h -", 0.55, 0.12,
     "1 4 1 5 6 4 5 1",
     ["3 . 5 . 1' . 7 5", "4 . 6 . 5 . 4 3", "3 . 5 . 1' . 2' .", "2' . . . 7 . 5 .",
      "6 . 1' . 6 . 5 3", "4 . 6 . 1' . 6 .", "5 . 4 3 2 . 3 4", "1 . 3 5 1' . - ."]),
    ("brook", "River Skip", "D", "major", 120, "bell", "pluck", "arp", "bounce", "k h h k s h h h", 0.5, 0.08,
     "1 5 6 4 1 5 6 4",
     ["3 5 1' . 7 5 3 .", "2 . 5 . 7 . 5 .", "1 3 6 . 5 3 1 .", "4 . 6 . 1' . 6 .",
      "3 5 1' . 7 5 1' .", "2' . 7 . 5 . 2' .", "1' 7 6 . 5 3 1 .", "4 3 2 . 1 . - ."]),
    ("grove", "Under Leaves", "E", "minor", 104, "ocarina", "pad", "bells", "walk", "k - - h s - h -", 0.4, 0.1,
     "1 6 3 7 1 4 7 1",
     ["3 . 5 . 1' . 7 5", "6 . . . 3 . 1 .", "5 . 3 . 5 . 7 .", "7 . . . 2' . 7 .",
      "1' . 7 . 5 . 3 .", "4 . 6 . 1' . 6 .", "7 . 5 . 2 . 5 .", "1 . . . - . . ."]),
    ("cavern", "Ember Hum", "A", "minor", 96, "ocarina", "softSquare", "pad", "soft", "k - - - s - - h", 0.35, 0.0,
     "1 6 4 5^ 1 6 5^ 1",
     ["3 . 5 . 1' . 7 5", "3 . . . 1 . 3 .", "4 . 6 . 1' . 6 4", "7#, . 2 . 5 . 7# .",
      "3 . 5 . 1' . 2' 3'", "3' . 1' . 6 . 3 .", "2 . 5 . 7# . 2' .", "1' . . . - . . ."]),
    ("ridge", "Copper Wind", "F", "major", 126, "whistle", "softSquare", "offbeat", "root5", "k h s h k k s h", 0.55, 0.1,
     "1 5 4 1 6 4 5 1",
     ["3 . 5 . 1' . 7 5", "5 . 2' . 7 . 5 .", "6 . 4 . 1' . 4 .", "3 5 3 1 5 . . .",
      "6 . 1' . 3' . 1' .", "6 . 4 . 6 . 1' .", "7 . 2' . 5 . 7 .", "1' . 5 . 1' . - ."]),
    ("marsh", "Fog Lantern", "D", "dorian", 92, "flute", "pad", "pad", "soft", "k - - - s - - -", 0.3, 0.0,
     "1 4 1 4 7 1 7 1",
     ["3 . 5 . 1' . 7 5", "6 . . . 4 . 6 .", "5 . . . 3 . 1 .", "2 . 4 . 6 . 4 .",
      "1' . . . 7 . 5 .", "4 . 6 . 1' . . .", "7 . 5 . 2 . 4 .", "3 . 1 . - . . ."]),
    ("spire", "Crystal Clock", "Bb", "major", 132, "celesta", "softSquare", "pulse", "octave", "k h h h s h h h", 0.45, 0.0,
     "1 3 4 5 1 3 4 5",
     ["3 5 1' 5 7 5 3 5", "3 5 7 5 2' 7 5 7", "4 6 1' 6 4 6 1' 6", "5 7 2' 7 5 . . .",
      "3 5 1' 5 3' 2' 1' 7", "7 5 3 5 7 . 5 .", "6 4 1' 6 7 5 2' 7", "1' . 5 . 1 . - ."]),
    ("storm", "Thunder Bridge", "C", "minor", 138, "chip", "softSquare", "offbeat", "octave", "k h s h k k s s", 0.6, 0.0,
     "1 6 7 1 1 4 7 5^",
     ["3 . 5 . 1' . 7 5", "1' . 6 . 3 . 6 .", "7 . 5 . 2 . 4 .", "3 . 1 . 5 . . .",
      "3 5 1' . 3 5 1' .", "4 6 1' . 6 4 1 .", "7 . 2' . 4' . 2' .", "7# . 5 . 2 . 7#, ."]),
    ("throne", "Crown of Night", "D", "minor", 120, "organ", "softSquare", "waltz", "waltz", "k - s - s -", 0.4, 0.0,
     "1 4 5^ 1 6 4 5^ 1",
     ["3 . 5 . 1' .", "6 . . . 4 .", "7# . 5 . 2 .", "1' . . . - .",
      "3' . 1' . 6 .", "4 . 6 . 1' .", "7# . 2' . 5 .", "1' . . . - ."]),
    ("frost", "Snow Globe", "Eb", "major", 108, "bell", "pad", "bells", "soft", "- - h - - - h -", 0.35, 0.08,
     "1 6 2 5 1 6 2 5",
     ["3 . 5 . 1' . 7 5", "6 . 1' . 3' . 1' .", "2' . 1' . 6 . 4 .", "5 . . . 7 . 2' .",
      "3' . 2' . 1' . 5 .", "6 . 5 . 3 . 1 .", "2 . 4 . 6 . 7 .", "1' . . . - . . ."]),
    ("coral", "Shell Song", "F", "major", 112, "steel", "pluck", "offbeat", "bounce", "k - h k - h k h", 0.5, 0.14,
     "1 4 5 1 1 4 5 1",
     ["3 . 5 1' . 7 5 .", "6 . 4 6 . 1' 6 .", "5 . 2 5 . 7 5 .", "3 . 1 . 5 . . .",
      "3 5 1' . 3' . 2' 1'", "6 . 1' . 4' . 1' .", "7 . 2' . 5 . 7 .", "1' . 5 . 1 . - ."]),
    ("starfall", "Wish Upon", "A", "major", 100, "musicBox", "pad", "arp", "soft", "k - h - s - h h", 0.35, 0.0,
     "1 3 6 4 1 5 4 1",
     ["3 . 5 . 1' . 7 5", "7 . . . 5 . 3 .", "6 . 1' . 3' . 1' .", "4' . 3' . 1' . 6 .",
      "5 . 3 . 5 . 1' .", "2' . . . 7 . 5 .", "6 . 1' . 4' . 2' .", "1' . . . - . . ."]),
]


def expand(song):
    sid, name, tonic, mode, bpm, lead_voice, harm_voice, harm_style, bass_style, drums, drum_level, swing, chords, bars = song
    key = Key(tonic, mode)
    chords = chords.split()
    steps = len(bars[0].split())
    return {
        "id": sid, "name": name, "bpm": bpm, "lead_voice": lead_voice, "harm_voice": harm_voice,
        "drum_level": drum_level, "swing": swing,
        "lead": melody(key, bars),
        "harmony": harmony(key, chords, harm_style, steps),
        "bass": bass(key, chords, bass_style, steps),
        "drums": (drums.split() * len(bars)),
    }


def bars_of(tokens, n=8):
    return [" ".join(tokens[i:i + n]) for i in range(0, len(tokens), n)]


def swift_list(tokens):
    return "[\n" + ",\n".join(f'                "{b}"' for b in bars_of(tokens)) + "\n            ]"


def kotlin_list(tokens):
    return "listOf(\n" + ",\n".join(f'            "{b}"' for b in bars_of(tokens)) + "\n        )"


def write_swift(songs):
    lines = [
        "// Generated by Scripts/compose-songs.py — edit the script, not this file.",
        "",
        "extension Songs {",
        "    /// One song per world plus the title theme; every lead opens with the same hook in its own key.",
        "    static let byKey: [String: Song] = [",
    ]
    for s in songs:
        lines.append(f'        "{s["id"]}": Song(')
        lines.append(f'            name: "{s["name"]}", bpm: {s["bpm"]}, leadVoice: .{s["lead_voice"]}, harmonyVoice: .{s["harm_voice"]},')
        lines.append(f'            drumLevel: {s["drum_level"]}, swing: {s["swing"]},')
        lines.append(f'            lead: {swift_list(s["lead"])},')
        lines.append(f'            harmony: {swift_list(s["harmony"])},')
        lines.append(f'            bass: {swift_list(s["bass"])},')
        lines.append(f'            drums: {swift_list(s["drums"])}')
        lines.append("        ),")
    lines += ["    ]", "}", ""]
    SWIFT.write_text("\n".join(lines))


def write_kotlin(songs):
    lines = [
        "// Generated by Scripts/compose-songs.py — edit the script, not this file.",
        "package app.jannat.alinaworld.audio",
        "",
        "/** One song per world plus the title theme; every lead opens with the same hook in its own key. */",
        "val worldSongs: Map<String, Song> = mapOf(",
    ]
    for s in songs:
        lines.append(f'    "{s["id"]}" to Song(')
        lines.append(f'        name = "{s["name"]}", bpm = {s["bpm"]}.0, leadVoice = Instrument.{s["lead_voice"][0].upper() + s["lead_voice"][1:]},')
        lines.append(f'        harmonyVoice = Instrument.{s["harm_voice"][0].upper() + s["harm_voice"][1:]}, drumLevel = {s["drum_level"]}f, swing = {s["swing"]},')
        lines.append(f'        lead = {kotlin_list(s["lead"])},')
        lines.append(f'        harmony = {kotlin_list(s["harmony"])},')
        lines.append(f'        bass = {kotlin_list(s["bass"])},')
        lines.append(f'        drums = {kotlin_list(s["drums"])}')
        lines.append("    ),")
    lines[-1] = "    )"
    lines += [")", ""]
    KOTLIN.write_text("\n".join(lines))


if __name__ == "__main__":
    songs = [expand(s) for s in SONGS]
    write_swift(songs)
    write_kotlin(songs)
    print(f"Wrote {len(songs)} songs to {SWIFT.name} and {KOTLIN.name}")
