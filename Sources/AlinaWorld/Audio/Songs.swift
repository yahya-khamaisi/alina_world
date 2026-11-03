import Foundation

/// A looping (or one-shot) tune on an eighth-note grid.
/// Tracks use space-separated tokens: a note name (`C5`, `F#4`, `Bb2`) starts a note,
/// `.` holds the previous one, `-` releases it. Drums use `k` kick, `s` snare, `h` hat, `-` rest.
struct Song {
    let name: String
    let bpm: Double
    let loops: Bool
    let lead: [Int]
    let harmony: [Int]
    let bass: [Int]
    let drums: [Character]

    var length: Int { max(lead.count, harmony.count, bass.count, drums.count) }

    static let hold = 0
    static let rest = -1

    init(name: String, bpm: Double, loops: Bool = true, lead: [String], harmony: [String] = [], bass: [String], drums: [String] = []) {
        self.name = name
        self.bpm = bpm
        self.loops = loops
        self.lead = Self.parse(lead)
        self.harmony = Self.parse(harmony)
        self.bass = Self.parse(bass)
        self.drums = drums.joined(separator: " ").split(separator: " ").map { $0.first ?? "-" }
    }

    func withTempo(_ factor: Double) -> Song {
        Song(raw: self, bpm: bpm * factor)
    }

    private init(raw: Song, bpm: Double) {
        name = raw.name
        self.bpm = bpm
        loops = raw.loops
        lead = raw.lead
        harmony = raw.harmony
        bass = raw.bass
        drums = raw.drums
    }

    private static func parse(_ bars: [String]) -> [Int] {
        bars.joined(separator: " ").split(separator: " ").map { token in
            switch token {
            case ".": return hold
            case "-": return rest
            default: return midi(String(token))
            }
        }
    }

    /// `C4` = 60.
    private static func midi(_ name: String) -> Int {
        let letters: [Character: Int] = ["C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11]
        var chars = Array(name)
        var pitch = letters[chars.removeFirst()] ?? 0
        if chars.first == "#" { pitch += 1; chars.removeFirst() }
        if chars.first == "b" { pitch -= 1; chars.removeFirst() }
        let octave = Int(String(chars)) ?? 4
        return 12 * (octave + 1) + pitch
    }
}

/// Original compositions for Alina World. Each world act gets its own mood:
/// bright C major on the menus, a skipping F major for the dawn worlds,
/// a wistful A minor for dusk, and a driving D minor for the Night Crown.
enum Songs {
    static let title = Song(
        name: "Lumen Isles",
        bpm: 112,
        lead: [
            "E5 . G5 . C6 . G5 .", "A5 . . . E5 . C5 .", "F5 . A5 . C6 . A5 .", "G5 . . . D5 . B4 .",
            "E5 . G5 . C6 . D6 .", "E6 . D6 . C6 . A5 .", "A5 . C6 . B5 . G5 .", "C6 . . . - . . ."
        ],
        harmony: [
            "C4 E4 G4 E4 C4 E4 G4 E4", "A3 C4 E4 C4 A3 C4 E4 C4", "F3 A3 C4 A3 F3 A3 C4 A3", "G3 B3 D4 B3 G3 B3 D4 B3",
            "C4 E4 G4 E4 C4 E4 G4 E4", "A3 C4 E4 C4 A3 C4 E4 C4", "F3 A3 C4 A3 G3 B3 D4 B3", "C4 E4 G4 E4 C4 - . ."
        ],
        bass: [
            "C3 . G3 . C3 . G3 .", "A2 . E3 . A2 . E3 .", "F2 . C3 . F2 . C3 .", "G2 . D3 . G2 . D3 .",
            "C3 . G3 . C3 . G3 .", "A2 . E3 . A2 . E3 .", "F2 . C3 . G2 . D3 .", "C3 . G3 . C3 - . ."
        ],
        drums: Array(repeating: "k h s h k h s h", count: 7) + ["k h s h k - - -"]
    )

    static let dawnRun = Song(
        name: "Dawn Run",
        bpm: 150,
        lead: [
            "A4 . C5 . F5 . A5 .", "G5 . E5 . C5 . E5 .", "F5 . A5 . D6 . A5 .", "Bb5 . A5 . G5 . F5 .",
            "A5 . A5 C6 . A5 F5 .", "G5 . G5 Bb5 . G5 E5 .", "D5 F5 Bb5 . C6 . E5 G5", "F5 . . . - . . ."
        ],
        harmony: [
            "- A4 - A4 - A4 - A4", "- G4 - G4 - G4 - G4", "- F4 - F4 - F4 - F4", "- D5 - D5 - D5 - D5",
            "- A4 - A4 - A4 - A4", "- G4 - G4 - G4 - G4", "- D5 - D5 - E5 - E5", "- A4 - A4 - . . ."
        ],
        bass: [
            "F2 F3 F2 F3 F2 F3 F2 F3", "C3 C4 C3 C4 C3 C4 C3 C4", "D3 D4 D3 D4 D3 D4 D3 D4", "Bb2 Bb3 Bb2 Bb3 Bb2 Bb3 Bb2 Bb3",
            "F2 F3 F2 F3 F2 F3 F2 F3", "C3 C4 C3 C4 C3 C4 C3 C4", "Bb2 Bb3 Bb2 Bb3 C3 C4 C3 C4", "F2 F3 F2 F3 F2 . - ."
        ],
        drums: Array(repeating: "k h s h k k s h", count: 7) + ["k h s h k s s s"]
    )

    static let duskTrail = Song(
        name: "Dusk Trail",
        bpm: 128,
        lead: [
            "E5 . A5 . B5 . C6 .", "A5 . . . F5 . A5 .", "G5 . E5 . G5 . C6 .", "B5 . . . G5 . D5 .",
            "C6 . B5 . A5 . E5 .", "F5 . A5 . C6 . A5 .", "D6 . C6 . B5 . G#5 .", "A5 . . . - . . ."
        ],
        harmony: [
            "A4 C5 E5 C5 A4 C5 E5 C5", "F4 A4 C5 A4 F4 A4 C5 A4", "E4 G4 C5 G4 E4 G4 C5 G4", "D4 G4 B4 G4 D4 G4 B4 G4",
            "A4 C5 E5 C5 A4 C5 E5 C5", "F4 A4 C5 A4 F4 A4 C5 A4", "D4 F4 A4 F4 E4 G#4 B4 G#4", "A4 C5 E5 C5 A4 - . ."
        ],
        bass: [
            "A2 . A2 E3 A2 . G2 .", "F2 . F2 C3 F2 . E2 .", "C3 . C3 G3 C3 . B2 .", "G2 . G2 D3 G2 . F#2 .",
            "A2 . A2 E3 A2 . G2 .", "F2 . F2 C3 F2 . E2 .", "D3 . D3 A2 E3 . E2 .", "A2 . E3 . A2 - . ."
        ],
        drums: Array(repeating: "k - h - s - h h", count: 7) + ["k - h - s s s s"]
    )

    static let nightCrown = Song(
        name: "Night Crown",
        bpm: 156,
        lead: [
            "D5 . F5 . A5 . D6 .", "D6 . C6 . Bb5 . F5 .", "E5 . G5 . C6 . E6 .", "E6 . . . C#6 . A5 .",
            "F6 . E6 . D6 . A5 .", "Bb5 . A5 . F5 . D5 .", "G5 . Bb5 . A5 . C#6 .", "D6 . . . - . . ."
        ],
        harmony: [
            "- F4 - F4 - F4 - F4", "- D4 - D4 - D4 - D4", "- E4 - E4 - E4 - E4", "- C#5 - C#5 - C#5 - C#5",
            "- F4 - F4 - F4 - F4", "- D4 - D4 - D4 - D4", "- Bb4 - Bb4 - C#5 - C#5", "- F4 - F4 - . . ."
        ],
        bass: [
            "D2 D3 D2 D3 D2 D3 D2 D3", "Bb1 Bb2 Bb1 Bb2 Bb1 Bb2 Bb1 Bb2", "C2 C3 C2 C3 C2 C3 C2 C3", "A1 A2 A1 A2 A1 A2 A1 A2",
            "D2 D3 D2 D3 D2 D3 D2 D3", "Bb1 Bb2 Bb1 Bb2 Bb1 Bb2 Bb1 Bb2", "G1 G2 G1 G2 A1 A2 A1 A2", "D2 D3 D2 D3 D2 . - ."
        ],
        drums: Array(repeating: "k h s h k h s s", count: 7) + ["k s k s k s s s"]
    )

    static let victory = Song(
        name: "Crystal Restored",
        bpm: 150,
        loops: false,
        lead: ["C5 E5 G5 C6 . G5 C6 . . . . -"],
        harmony: ["- C5 - E5 . - E5 . . . . -"],
        bass: ["C3 . . . . G2 C3 . . . . -"],
        drums: ["k - - - - - s - - - - -"]
    )

    static let defeat = Song(
        name: "Try Again",
        bpm: 96,
        loops: false,
        lead: ["G4 . F#4 . F4 . E4 . . . -"],
        bass: ["C3 . B2 . Bb2 . A2 . . . -"]
    )

    /// Level music by act (worlds 1–3, 4–6, 7–9); guardian missions play it faster.
    static func level(worldIndex: Int, guardian: Bool) -> Song {
        let base = worldIndex < 3 ? dawnRun : (worldIndex < 6 ? duskTrail : nightCrown)
        return guardian ? base.withTempo(1.1) : base
    }
}
