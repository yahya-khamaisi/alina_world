package app.jannat.alinaworld.data

import android.content.Context
import app.jannat.alinaworld.game.WorldThemes
import app.jannat.alinaworld.pixel.PixelSprite
import org.json.JSONObject

enum class Objective { ReachFlag, CollectN, DefeatBoss }
enum class Difficulty { Easy, Normal, Hard }

class EnemyPlacement(val x: Int, val y: Int, val kind: String, val patrol: Int?)

class Mission(
    val id: Int,
    val world: String,
    val act: Int,
    val title: String,
    val difficulty: Difficulty,
    val objective: Objective,
    val collectTarget: Int?,
    val timeLimit: Int?,
    val layoutSeed: Int,
    val rows: List<String>,
    val enemies: List<EnemyPlacement>
) {
    val collectRequired: Int get() = collectTarget ?: 0

    /** World-mission code such as "3-2". */
    val code: String get() = "${WorldThemes.index(world) + 1}-${(id - 1) % 3 + 1}"

    val goalSprite: PixelSprite
        get() = when (objective) {
            Objective.ReachFlag -> PixelSprite.Beacon
            Objective.CollectN -> PixelSprite.Crystal
            Objective.DefeatBoss -> PixelSprite.Guardian
        }

    val objectiveLabel: String
        get() = when (objective) {
            Objective.ReachFlag -> "Reach the beacon"
            Objective.CollectN -> "Collect $collectRequired Heart Shards"
            Objective.DefeatBoss -> "Defeat the guardian"
        }

    /** Par time for the second star; mirrors the Mac game. */
    val parTime: Float
        get() = timeLimit?.let { it * 0.75f } ?: ((rows.firstOrNull()?.length ?: 100) * 0.3f + 10f)
}

object Missions {
    private var cached: List<Mission> = emptyList()

    val all: List<Mission> get() = cached

    fun load(context: Context) {
        if (cached.isNotEmpty()) return
        val text = context.assets.open("Missions.json").bufferedReader().use { it.readText() }
        val array = JSONObject(text).getJSONArray("missions")
        cached = (0 until array.length()).map { i ->
            val m = array.getJSONObject(i)
            val rows = m.getJSONArray("rows").let { r -> (0 until r.length()).map { r.getString(it) } }
            val enemies = m.optJSONArray("enemies")?.let { e ->
                (0 until e.length()).map {
                    val o = e.getJSONObject(it)
                    EnemyPlacement(o.getInt("x"), o.getInt("y"), o.getString("kind"), if (o.isNull("patrol")) null else o.optInt("patrol"))
                }
            } ?: emptyList()
            Mission(
                id = m.getInt("id"),
                world = m.getString("world"),
                act = m.getInt("act"),
                title = m.getString("title"),
                difficulty = Difficulty.valueOf(m.getString("difficulty").replaceFirstChar { it.uppercase() }),
                objective = Objective.valueOf(m.getString("objective").replaceFirstChar { it.uppercase() }),
                collectTarget = if (m.isNull("collectTarget")) null else m.getInt("collectTarget"),
                timeLimit = if (m.isNull("timeLimit")) null else m.getInt("timeLimit"),
                layoutSeed = m.getInt("layoutSeed"),
                rows = rows,
                enemies = enemies
            )
        }.sortedBy { it.id }
    }

    fun byId(id: Int): Mission? = cached.firstOrNull { it.id == id }
}
