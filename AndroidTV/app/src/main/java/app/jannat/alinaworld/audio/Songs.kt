package app.jannat.alinaworld.audio

/**
 * A looping (or one-shot) tune on an eighth-note grid.
 * Tracks use space-separated tokens: a note name (`C5`, `F#4`, `Bb2`) starts a note,
 * `.` holds the previous one, `-` releases it. Drums use `k` kick, `s` snare, `h` hat, `-` rest.
 */
class Song private constructor(
    val name: String,
    val bpm: Double,
    val loops: Boolean,
    val lead: IntArray,
    val harmony: IntArray,
    val bass: IntArray,
    val drums: CharArray,
    /** Sound of the melody and of the harmony line; the bass is always a soft triangle. */
    val leadVoice: Instrument,
    val harmonyVoice: Instrument,
    /** 0…1 drum volume, so gentle worlds keep the beat quiet. */
    val drumLevel: Float,
    /** 0 plays straight eighths; 0.1–0.15 gives a light, bouncy swing. */
    val swing: Double
) {
    val length: Int get() = maxOf(maxOf(lead.size, harmony.size), maxOf(bass.size, drums.size))

    fun withTempo(factor: Double) = Song(
        "$name (guardian)", bpm * factor, loops, lead, harmony, bass, drums, leadVoice, harmonyVoice,
        minOf(1f, drumLevel * 1.3f), swing
    )

    companion object {
        const val HOLD = 0
        const val REST = -1

        operator fun invoke(
            name: String, bpm: Double, loops: Boolean = true,
            leadVoice: Instrument = Instrument.Chip, harmonyVoice: Instrument = Instrument.Chip,
            drumLevel: Float = 1f, swing: Double = 0.0,
            lead: List<String>, harmony: List<String> = emptyList(), bass: List<String>, drums: List<String> = emptyList()
        ) = Song(
            name, bpm, loops, parse(lead), parse(harmony), parse(bass),
            drums.joinToString(" ").split(" ").filter { it.isNotEmpty() }.map { it.first() }.toCharArray(),
            leadVoice, harmonyVoice, drumLevel, swing
        )

        private fun parse(bars: List<String>): IntArray =
            bars.joinToString(" ").split(" ").filter { it.isNotEmpty() }.map {
                when (it) { "." -> HOLD; "-" -> REST; else -> midi(it) }
            }.toIntArray()

        /** `C4` = 60. */
        private fun midi(name: String): Int {
            val letters = mapOf('C' to 0, 'D' to 2, 'E' to 4, 'F' to 5, 'G' to 7, 'A' to 9, 'B' to 11)
            var rest = name.drop(1)
            var pitch = letters[name[0]] ?: 0
            if (rest.startsWith("#")) { pitch += 1; rest = rest.drop(1) }
            if (rest.startsWith("b")) { pitch -= 1; rest = rest.drop(1) }
            val octave = rest.toIntOrNull() ?: 4
            return 12 * (octave + 1) + pitch
        }
    }
}

/** Synth voices: a waveform with its own envelope, so a song can sound like a flute or a music box. */
enum class Instrument(
    val wave: Wave,
    /** Level the note settles to after its attack; 0 lets it ring out like a struck bell. */
    val sustain: Float,
    /** Seconds for the attack to fall to the sustain level. */
    val decay: Double,
    val level: Float,
    /** Pitch wobble depth for breathy voices. */
    val vibrato: Double = 0.0
) {
    Chip(Wave.Pulse25, 0.55f, 0.12, 0.15f),
    SoftSquare(Wave.Pulse50, 0.45f, 0.12, 0.07f),
    Pluck(Wave.Pulse25, 0f, 0.1, 0.1f),
    Flute(Wave.Triangle, 0.7f, 0.12, 0.2f, 0.004),
    Ocarina(Wave.Sine, 0.7f, 0.12, 0.2f, 0.003),
    Whistle(Wave.Sine, 0.85f, 0.12, 0.2f, 0.006),
    Bell(Wave.Bell, 0f, 0.38, 0.24f),
    MusicBox(Wave.Bell, 0f, 0.55, 0.24f),
    Celesta(Wave.Bell, 0f, 0.22, 0.18f),
    Steel(Wave.Steel, 0f, 0.28, 0.24f),
    Organ(Wave.Pulse50, 0.85f, 0.12, 0.07f),
    Pad(Wave.Triangle, 0.85f, 0.5, 0.08f);

    enum class Wave { Pulse50, Pulse25, Triangle, Sine, Bell, Steel }
}

/**
 * Original compositions for Alina World, shared with the Mac app: a theme for the isles and one song per world
 * (see Scripts/compose-songs.py and the generated Soundtrack.kt).
 */
object Songs {
    val title: Song get() = worldSongs.getValue("title")

    val victory = Song(
        name = "Crystal Restored", bpm = 150.0, loops = false, leadVoice = Instrument.Bell, harmonyVoice = Instrument.Pluck,
        lead = listOf("C5 E5 G5 C6 . G5 C6 . . . . -"),
        harmony = listOf("- C5 - E5 . - E5 . . . . -"),
        bass = listOf("C3 . . . . G2 C3 . . . . -"),
        drums = listOf("k - - - - - s - - - - -")
    )

    val defeat = Song(
        name = "Try Again", bpm = 96.0, loops = false, leadVoice = Instrument.Flute,
        lead = listOf("G4 . F#4 . F4 . E4 . . . -"),
        bass = listOf("C3 . B2 . Bb2 . A2 . . . -")
    )

    /** Each world's own song; guardian missions play it a little faster with more drums. */
    fun world(key: String, guardian: Boolean): Song {
        val base = worldSongs[key] ?: title
        return if (guardian) base.withTempo(1.08) else base
    }
}
