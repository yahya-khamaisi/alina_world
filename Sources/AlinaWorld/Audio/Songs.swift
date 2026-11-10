import Foundation

/// A looping (or one-shot) tune on an eighth-note grid.
/// Tracks use space-separated tokens: a note name (`C5`, `F#4`, `Bb2`) starts a note,
/// `.` holds the previous one, `-` releases it. Drums use `k` kick, `s` snare, `h` hat, `-` rest.
struct Song {
    private(set) var name: String
    private(set) var bpm: Double
    let loops: Bool
    let lead: [Int]
    private(set) var harmony: [Int]
    let bass: [Int]
    let drums: [Character]
    /// Sound of the melody and of the harmony line; the bass is always a soft triangle.
    var leadVoice: Instrument = .chip
    var harmonyVoice: Instrument = .chip
    /// 0…1 drum volume, so gentle worlds keep the beat quiet.
    var drumLevel: Float = 1
    /// 0 plays straight eighths; 0.1–0.15 gives a light, bouncy swing.
    var swing: Double = 0
    /// Overall music level for this song (1 = as mixed for menus).
    var gain: Float = 1

    var length: Int { max(lead.count, harmony.count, bass.count, drums.count) }

    static let hold = 0
    static let rest = -1

    init(
        name: String, bpm: Double, loops: Bool = true, leadVoice: Instrument = .chip, harmonyVoice: Instrument = .chip,
        drumLevel: Float = 1, swing: Double = 0,
        lead: [String], harmony: [String] = [], bass: [String], drums: [String] = []
    ) {
        self.name = name
        self.bpm = bpm
        self.loops = loops
        self.leadVoice = leadVoice
        self.harmonyVoice = harmonyVoice
        self.drumLevel = drumLevel
        self.swing = swing
        self.lead = Self.parse(lead)
        self.harmony = Self.parse(harmony)
        self.bass = Self.parse(bass)
        self.drums = drums.joined(separator: " ").split(separator: " ").map { $0.first ?? "-" }
    }

    func withTempo(_ factor: Double) -> Song {
        var copy = self
        copy.name += " (guardian)"
        copy.bpm *= factor
        copy.drumLevel = min(1, drumLevel * 1.3)
        return copy
    }

    /// The in-level arrangement: just the melody on a soft voice over the bass, no harmony line or drums, a little
    /// slower and about half as loud, so the music sits quietly under the game.
    func calm() -> Song {
        var copy = self
        copy.name += " (calm)"
        copy.bpm *= 0.94
        copy.harmony = Array(repeating: Song.rest, count: harmony.count)
        copy.drumLevel = 0
        copy.swing = min(swing, 0.08)
        copy.gain = 0.5
        copy.leadVoice = leadVoice.gentle
        return copy
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

/// Synth voices. Each is a waveform with its own envelope, so a song can sound like a flute or a music box.
enum Instrument {
    case chip, softSquare, pluck, flute, ocarina, whistle, bell, musicBox, celesta, steel, organ, pad

    enum Wave { case pulse50, pulse25, triangle, sine, bell, steel }

    var wave: Wave {
        switch self {
        case .chip, .pluck: return .pulse25
        case .softSquare, .organ: return .pulse50
        case .flute, .pad: return .triangle
        case .ocarina, .whistle: return .sine
        case .bell, .musicBox, .celesta: return .bell
        case .steel: return .steel
        }
    }

    /// Level the note settles to after its attack; 0 lets it ring out like a struck bell.
    var sustain: Float {
        switch self {
        case .chip: return 0.55
        case .softSquare: return 0.45
        case .pluck, .bell, .musicBox, .celesta, .steel: return 0
        case .flute, .ocarina: return 0.7
        case .whistle, .organ, .pad: return 0.85
        }
    }

    /// Seconds for the attack to fall to the sustain level.
    var decay: Double {
        switch self {
        case .pluck: return 0.1
        case .celesta: return 0.22
        case .steel: return 0.28
        case .bell: return 0.38
        case .musicBox: return 0.55
        case .pad: return 0.5
        default: return 0.12
        }
    }

    var level: Float {
        switch self {
        case .chip: return 0.15
        case .softSquare, .organ: return 0.07
        case .pluck: return 0.1
        case .flute: return 0.2
        case .ocarina, .whistle: return 0.2
        case .bell, .musicBox, .steel: return 0.24
        case .celesta: return 0.18
        case .pad: return 0.08
        }
    }

    /// A softer stand-in for buzzy square voices, used by the calm in-level arrangement.
    var gentle: Instrument {
        switch self {
        case .chip, .organ: return .flute
        case .softSquare: return .ocarina
        default: return self
        }
    }

    /// Pitch wobble depth for breathy voices.
    var vibrato: Double {
        switch self {
        case .flute: return 0.004
        case .ocarina: return 0.003
        case .whistle: return 0.006
        default: return 0
        }
    }
}

/// Original compositions for Alina World: a theme for the isles and one song per world
/// (see Scripts/compose-songs.py and the generated Soundtrack.swift).
enum Songs {
    static var title: Song { byKey["title"]! }

    static let victory = Song(
        name: "Crystal Restored",
        bpm: 150,
        loops: false,
        leadVoice: .bell,
        harmonyVoice: .pluck,
        lead: ["C5 E5 G5 C6 . G5 C6 . . . . -"],
        harmony: ["- C5 - E5 . - E5 . . . . -"],
        bass: ["C3 . . . . G2 C3 . . . . -"],
        drums: ["k - - - - - s - - - - -"]
    )

    static let defeat = Song(
        name: "Try Again",
        bpm: 96,
        loops: false,
        leadVoice: .flute,
        lead: ["G4 . F#4 . F4 . E4 . . . -"],
        bass: ["C3 . B2 . Bb2 . A2 . . . -"]
    )

    /// Each world's own song in its calm in-level arrangement; guardian missions play it a little faster.
    static func world(_ key: String, guardian: Bool) -> Song {
        let base = (byKey[key] ?? title).calm()
        guard guardian else { return base }
        var faster = base.withTempo(1.08)
        faster.drumLevel = 0
        return faster
    }
}
