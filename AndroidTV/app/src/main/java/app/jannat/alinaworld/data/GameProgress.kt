package app.jannat.alinaworld.data

import android.content.Context
import android.content.SharedPreferences

class MissionResult(
    val missionID: Int,
    val petals: Int,
    val time: Float,
    val hits: Int,
    val parTime: Float,
    /** Completed, under par time, no damage. */
    val stars: BooleanArray,
    val newBestTime: Boolean
) {
    val starCount: Int get() = stars.count { it }
}

/** Saved progress, using the same keys as the Mac app. */
object GameProgress {
    const val MISSION_COUNT = 36
    const val WORLD_COUNT = 12
    private lateinit var prefs: SharedPreferences

    fun init(context: Context) {
        prefs = context.getSharedPreferences("alinaWorld", Context.MODE_PRIVATE)
    }

    var unlockedMission: Int
        get() = prefs.getInt("alinaWorld.unlockedMission", 1).coerceAtLeast(1)
        set(value) = prefs.edit().putInt("alinaWorld.unlockedMission", value.coerceAtLeast(1)).apply()

    /** Next mission to play: the furthest unlocked one, capped at the finale. */
    val continueMission: Int get() = minOf(MISSION_COUNT, unlockedMission)

    val totalPetals: Int get() = prefs.getInt("alinaWorld.totalPetals", 0)

    fun stars(id: Int): BooleanArray {
        val mask = prefs.getInt("alinaWorld.stars.$id", 0)
        return BooleanArray(3) { mask and (1 shl it) != 0 }
    }

    fun starCount(id: Int): Int = stars(id).count { it }

    val totalStars: Int get() = (1..MISSION_COUNT).sumOf { starCount(it) }

    fun bestTime(id: Int): Float? = prefs.getFloat("alinaWorld.bestTime.$id", 0f).takeIf { it > 0 }

    fun isCompleted(id: Int): Boolean = stars(id)[0]

    fun isUnlocked(id: Int): Boolean = id <= unlockedMission

    /** Heart Crystals restored: one per world whose guardian mission is complete. */
    val crystalsRestored: Int get() = (0 until WORLD_COUNT).count { isCompleted(it * 3 + 3) }

    fun recordCompletion(result: MissionResult) {
        val id = result.missionID
        if (id >= unlockedMission) unlockedMission = minOf(MISSION_COUNT + 1, id + 1)
        val previous = prefs.getInt("alinaWorld.stars.$id", 0)
        val mask = result.stars.withIndex().fold(0) { acc, s -> if (s.value) acc or (1 shl s.index) else acc }
        val edit = prefs.edit().putInt("alinaWorld.stars.$id", previous or mask)
        if (bestTime(id)?.let { result.time < it } != false) edit.putFloat("alinaWorld.bestTime.$id", result.time)
        edit.putInt("alinaWorld.totalPetals", totalPetals + result.petals)
        edit.apply()
    }

    fun reset() {
        prefs.edit().clear().apply()
    }
}

/** Preferences shown on the Settings screen. */
object Settings {
    private lateinit var prefs: SharedPreferences
    private val listeners = mutableListOf<() -> Unit>()

    fun init(context: Context) {
        prefs = context.getSharedPreferences("settings", Context.MODE_PRIVATE)
    }

    fun onChange(listener: () -> Unit) { listeners += listener }

    var assistMode: Boolean
        get() = prefs.getBoolean("assistMode", false)
        set(v) { prefs.edit().putBoolean("assistMode", v).apply(); listeners.forEach { it() } }
    var ambientEffects: Boolean
        get() = prefs.getBoolean("ambientEffects", true)
        set(v) { prefs.edit().putBoolean("ambientEffects", v).apply(); listeners.forEach { it() } }
    /** Tap ◀ ▶ to keep running, so a TV remote can jump mid-run. */
    var autoRun: Boolean
        get() = prefs.getBoolean("autoRun", true)
        set(v) { prefs.edit().putBoolean("autoRun", v).apply(); listeners.forEach { it() } }
    var showHints: Boolean
        get() = prefs.getBoolean("showHints", true)
        set(v) { prefs.edit().putBoolean("showHints", v).apply(); listeners.forEach { it() } }
    var musicVolume: Float
        get() = prefs.getFloat("musicVolume", 0.6f)
        set(v) { prefs.edit().putFloat("musicVolume", v).apply(); listeners.forEach { it() } }
    var effectsVolume: Float
        get() = prefs.getFloat("effectsVolume", 0.8f)
        set(v) { prefs.edit().putFloat("effectsVolume", v).apply(); listeners.forEach { it() } }
}
