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
    val drums: CharArray
) {
    val length: Int get() = maxOf(maxOf(lead.size, harmony.size), maxOf(bass.size, drums.size))

    fun withTempo(factor: Double) = Song(name, bpm * factor, loops, lead, harmony, bass, drums)

    companion object {
        const val HOLD = 0
        const val REST = -1

        operator fun invoke(
            name: String, bpm: Double, loops: Boolean = true,
            lead: List<String>, harmony: List<String> = emptyList(), bass: List<String>, drums: List<String> = emptyList()
        ) = Song(
            name, bpm, loops, parse(lead), parse(harmony), parse(bass),
            drums.joinToString(" ").split(" ").filter { it.isNotEmpty() }.map { it.first() }.toCharArray()
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

/**
 * Original compositions for Alina World, shared with the Mac app. Bright C major on the menus, a skipping
 * F major for the dawn worlds, a wistful A minor for dusk, and a driving D minor for the Night Crown.
 */
object Songs {
    val title = Song(
        name = "Lumen Isles", bpm = 112.0,
        lead = listOf(
            "E5 . G5 . C6 . G5 .", "A5 . . . E5 . C5 .", "F5 . A5 . C6 . A5 .", "G5 . . . D5 . B4 .",
            "E5 . G5 . C6 . D6 .", "E6 . D6 . C6 . A5 .", "A5 . C6 . B5 . G5 .", "C6 . . . - . . ."
        ),
        harmony = listOf(
            "C4 E4 G4 E4 C4 E4 G4 E4", "A3 C4 E4 C4 A3 C4 E4 C4", "F3 A3 C4 A3 F3 A3 C4 A3", "G3 B3 D4 B3 G3 B3 D4 B3",
            "C4 E4 G4 E4 C4 E4 G4 E4", "A3 C4 E4 C4 A3 C4 E4 C4", "F3 A3 C4 A3 G3 B3 D4 B3", "C4 E4 G4 E4 C4 - . ."
        ),
        bass = listOf(
            "C3 . G3 . C3 . G3 .", "A2 . E3 . A2 . E3 .", "F2 . C3 . F2 . C3 .", "G2 . D3 . G2 . D3 .",
            "C3 . G3 . C3 . G3 .", "A2 . E3 . A2 . E3 .", "F2 . C3 . G2 . D3 .", "C3 . G3 . C3 - . ."
        ),
        drums = List(7) { "k h s h k h s h" } + "k h s h k - - -"
    )

    private val dawnRun = Song(
        name = "Dawn Run", bpm = 150.0,
        lead = listOf(
            "A4 . C5 . F5 . A5 .", "G5 . E5 . C5 . E5 .", "F5 . A5 . D6 . A5 .", "Bb5 . A5 . G5 . F5 .",
            "A5 . A5 C6 . A5 F5 .", "G5 . G5 Bb5 . G5 E5 .", "D5 F5 Bb5 . C6 . E5 G5", "F5 . . . - . . ."
        ),
        harmony = listOf(
            "- A4 - A4 - A4 - A4", "- G4 - G4 - G4 - G4", "- F4 - F4 - F4 - F4", "- D5 - D5 - D5 - D5",
            "- A4 - A4 - A4 - A4", "- G4 - G4 - G4 - G4", "- D5 - D5 - E5 - E5", "- A4 - A4 - . . ."
        ),
        bass = listOf(
            "F2 F3 F2 F3 F2 F3 F2 F3", "C3 C4 C3 C4 C3 C4 C3 C4", "D3 D4 D3 D4 D3 D4 D3 D4", "Bb2 Bb3 Bb2 Bb3 Bb2 Bb3 Bb2 Bb3",
            "F2 F3 F2 F3 F2 F3 F2 F3", "C3 C4 C3 C4 C3 C4 C3 C4", "Bb2 Bb3 Bb2 Bb3 C3 C4 C3 C4", "F2 F3 F2 F3 F2 . - ."
        ),
        drums = List(7) { "k h s h k k s h" } + "k h s h k s s s"
    )

    private val duskTrail = Song(
        name = "Dusk Trail", bpm = 128.0,
        lead = listOf(
            "E5 . A5 . B5 . C6 .", "A5 . . . F5 . A5 .", "G5 . E5 . G5 . C6 .", "B5 . . . G5 . D5 .",
            "C6 . B5 . A5 . E5 .", "F5 . A5 . C6 . A5 .", "D6 . C6 . B5 . G#5 .", "A5 . . . - . . ."
        ),
        harmony = listOf(
            "A4 C5 E5 C5 A4 C5 E5 C5", "F4 A4 C5 A4 F4 A4 C5 A4", "E4 G4 C5 G4 E4 G4 C5 G4", "D4 G4 B4 G4 D4 G4 B4 G4",
            "A4 C5 E5 C5 A4 C5 E5 C5", "F4 A4 C5 A4 F4 A4 C5 A4", "D4 F4 A4 F4 E4 G#4 B4 G#4", "A4 C5 E5 C5 A4 - . ."
        ),
        bass = listOf(
            "A2 . A2 E3 A2 . G2 .", "F2 . F2 C3 F2 . E2 .", "C3 . C3 G3 C3 . B2 .", "G2 . G2 D3 G2 . F#2 .",
            "A2 . A2 E3 A2 . G2 .", "F2 . F2 C3 F2 . E2 .", "D3 . D3 A2 E3 . E2 .", "A2 . E3 . A2 - . ."
        ),
        drums = List(7) { "k - h - s - h h" } + "k - h - s s s s"
    )

    private val nightCrown = Song(
        name = "Night Crown", bpm = 156.0,
        lead = listOf(
            "D5 . F5 . A5 . D6 .", "D6 . C6 . Bb5 . F5 .", "E5 . G5 . C6 . E6 .", "E6 . . . C#6 . A5 .",
            "F6 . E6 . D6 . A5 .", "Bb5 . A5 . F5 . D5 .", "G5 . Bb5 . A5 . C#6 .", "D6 . . . - . . ."
        ),
        harmony = listOf(
            "- F4 - F4 - F4 - F4", "- D4 - D4 - D4 - D4", "- E4 - E4 - E4 - E4", "- C#5 - C#5 - C#5 - C#5",
            "- F4 - F4 - F4 - F4", "- D4 - D4 - D4 - D4", "- Bb4 - Bb4 - C#5 - C#5", "- F4 - F4 - . . ."
        ),
        bass = listOf(
            "D2 D3 D2 D3 D2 D3 D2 D3", "Bb1 Bb2 Bb1 Bb2 Bb1 Bb2 Bb1 Bb2", "C2 C3 C2 C3 C2 C3 C2 C3", "A1 A2 A1 A2 A1 A2 A1 A2",
            "D2 D3 D2 D3 D2 D3 D2 D3", "Bb1 Bb2 Bb1 Bb2 Bb1 Bb2 Bb1 Bb2", "G1 G2 G1 G2 A1 A2 A1 A2", "D2 D3 D2 D3 D2 . - ."
        ),
        drums = List(7) { "k h s h k h s s" } + "k s k s k s s s"
    )

    val victory = Song(
        name = "Crystal Restored", bpm = 150.0, loops = false,
        lead = listOf("C5 E5 G5 C6 . G5 C6 . . . . -"),
        harmony = listOf("- C5 - E5 . - E5 . . . . -"),
        bass = listOf("C3 . . . . G2 C3 . . . . -"),
        drums = listOf("k - - - - - s - - - - -")
    )

    val defeat = Song(
        name = "Try Again", bpm = 96.0, loops = false,
        lead = listOf("G4 . F#4 . F4 . E4 . . . -"),
        bass = listOf("C3 . B2 . Bb2 . A2 . . . -")
    )

    /** Level music by act (worlds 1–3, 4–6, 7–9); guardian missions play it faster. */
    fun level(worldIndex: Int, guardian: Boolean): Song {
        val base = if (worldIndex < 3) dawnRun else if (worldIndex < 6) duskTrail else nightCrown
        return if (guardian) base.withTempo(1.1) else base
    }
}
