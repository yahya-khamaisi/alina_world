package app.jannat.alinaworld.game

import app.jannat.alinaworld.data.Mission
import app.jannat.alinaworld.pixel.PixelSprite
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

/** Axis-aligned box in world units, y up. `intersects` is strict, like CGRect. */
class Box(var x: Float, var y: Float, var w: Float, var h: Float) {
    val minX get() = x
    val maxX get() = x + w
    val minY get() = y
    val maxY get() = y + h
    val midX get() = x + w / 2
    val midY get() = y + h / 2
    fun intersects(o: Box) = x < o.x + o.w && o.x < x + w && y < o.y + o.h && o.y < y + h
    fun intersects(ox: Float, oy: Float, ow: Float, oh: Float) = x < ox + ow && ox < x + w && y < oy + oh && oy < y + h
}

enum class Tile(val ch: Char) {
    Empty('.'), Solid('#'), Ground('='), Brick('B'), Question('?'), Pipe('P'), Coin('C'), Crystal('*'), Flag('F'),
    Enemy('E'), Hazard('^'), Boss('X'), SlopeUpRight('/'), SlopeUpLeft('\\'), SlopeDownRight('}'), SlopeDownLeft('{'),
    Platform('_'), Moving('M'), Spring('S');

    val isSolid get() = this in setOf(Solid, Ground, Brick, Question, Pipe, SlopeUpRight, SlopeUpLeft, SlopeDownRight, SlopeDownLeft, Platform, Moving, Spring)
    val isSlope get() = this == SlopeUpRight || this == SlopeUpLeft || this == SlopeDownRight || this == SlopeDownLeft

    companion object {
        private val byChar = entries.associateBy { it.ch }
        fun of(c: Char) = byChar[c] ?: Empty
    }
}

class TileMap(rows: List<String>) {
    val height = rows.size
    val width = rows.maxOf { it.length }
    private val tiles = Array(width * height) { i -> Tile.of(rows[i / width].getOrElse(i % width) { '.' }) }

    fun kind(col: Int, row: Int): Tile =
        if (col < 0 || row < 0 || col >= width || row >= height) Tile.Empty else tiles[row * width + col]

    fun tileX(col: Int) = col * GameConstants.TILE
    fun tileY(row: Int) = (height - 1 - row) * GameConstants.TILE
    val worldWidth get() = width * GameConstants.TILE
}

enum class BlockKind(val sprite: PixelSprite) {
    Solid(PixelSprite.Stone), Ground(PixelSprite.GroundTop), Brick(PixelSprite.Mossbrick),
    Question(PixelSprite.BloomBlock), Pipe(PixelSprite.Log), Spring(PixelSprite.SpringShell)
}

class Block(val kind: BlockKind, val col: Int, val row: Int, val topExposed: Boolean) {
    var hitCount = 0
    var revealed = false
    var used = false
    /** Seconds into the bump animation, or negative when still. */
    var bumpT = -1f
    val sprite: PixelSprite
        get() = when {
            used -> PixelSprite.BloomBlockUsed
            kind == BlockKind.Ground && !topExposed -> PixelSprite.GroundFill
            else -> kind.sprite
        }

    /** Vertical offset of the 0.16 s up-and-down bump. */
    val bumpOffset: Float
        get() = if (bumpT < 0) 0f else if (bumpT < 0.08f) 6 * bumpT / 0.08f else 6 * (1 - (bumpT - 0.08f) / 0.08f).coerceAtLeast(0f)

    fun bump() { bumpT = 0f }
}

enum class ItemKind { Coin, Crystal, Sunbloom, Ribbon }

class Item(val kind: ItemKind, val x: Float, var baseY: Float) {
    var alpha = 1f
    var scale = 1f
    var age = Random.nextFloat()
    private var emergeT = -1f
    private var emergeFrom = 0f
    var collecting = false; private set
    private var collectT = 0f
    var removed = false; private set

    /** Bobbing 5 units up and down every 0.9 s, eased like the SpriteKit action. */
    val y: Float
        get() {
            val p = (age % 0.9f) / 0.45f
            val e = if (p < 1) ease(p) else 1 - ease(p - 1)
            return baseY + 5 * e
        }

    private fun ease(t: Float) = (0.5f - 0.5f * cos(PI.toFloat() * t))

    fun emerge() {
        alpha = 0f
        emergeFrom = baseY - 20
        baseY = emergeFrom
        emergeT = 0f
    }

    fun collect() {
        collecting = true
        collectT = 0f
    }

    fun update(dt: Float) {
        age += dt
        if (emergeT >= 0) {
            emergeT += dt
            alpha = (emergeT / 0.25f).coerceAtMost(1f)
            baseY = emergeFrom + 30 * (emergeT / 0.3f).coerceAtMost(1f)
            if (emergeT >= 0.3f) emergeT = -1f
        }
        if (collecting) {
            collectT += dt
            val p = (collectT / 0.12f).coerceAtMost(1f)
            scale = 1 + 0.6f * p
            alpha = 1 - p
            if (p >= 1) removed = true
        }
    }
}

enum class EnemyKind {
    /** Gloomling — walks a patrol, defeated by a stomp. */
    Crawler,
    /** Thornbeetle — spiked shell, hurts Alina if she lands on it. */
    Spiky,
    /** Mothwisp — floats in the air. */
    Flyer,
    /** World guardian — takes three stomps. */
    Boss
}

class Enemy(val kind: EnemyKind, patrol: Int = 80, themeKey: String = "meadow") {
    var x = 0f
    var y = 0f
    private var originX = 0f
    private var originY = 0f
    private val patrolDistance = patrol.toFloat()
    var direction = -1f
    var moveSpeed = when (kind) { EnemyKind.Crawler -> 55f; EnemyKind.Spiky -> 40f; EnemyKind.Flyer -> 70f; EnemyKind.Boss -> 60f }
    var alive = true
    private val stompHitsRequired = if (kind == EnemyKind.Boss) 3 else 1
    var stompHits = 0; private set
    var age = 0f; private set
    var flashT = -1f; private set
    var dyingT = -1f; private set
    val gone get() = dyingT >= 0.27f

    val frames: List<PixelSprite> = when {
        // Act IV worlds dress the crawler and flyer as their own minions.
        kind == EnemyKind.Crawler && themeKey == "frost" -> listOf(PixelSprite.Frostpuff)
        kind == EnemyKind.Crawler && themeKey == "coral" -> listOf(PixelSprite.Shellcrab)
        kind == EnemyKind.Flyer && themeKey == "starfall" -> listOf(PixelSprite.Starwisp)
        else -> defaultFrames(kind)
    }

    private fun defaultFrames(kind: EnemyKind) = when (kind) {
        EnemyKind.Crawler -> listOf(PixelSprite.Gloomling, PixelSprite.GloomlingStep)
        EnemyKind.Spiky -> listOf(PixelSprite.Thornbeetle)
        EnemyKind.Flyer -> listOf(PixelSprite.Mothwisp, PixelSprite.MothwispFlap)
        EnemyKind.Boss -> listOf(PixelSprite.Guardian)
    }
    val frameTime = if (kind == EnemyKind.Flyer) 0.14f else 0.24f

    /** Hitbox, slightly inside the sprite so near-misses feel fair. */
    val hitW = when (kind) { EnemyKind.Crawler -> 30f; EnemyKind.Spiky -> 32f; EnemyKind.Flyer -> 30f; EnemyKind.Boss -> 44f }
    val hitH = when (kind) { EnemyKind.Crawler -> 24f; EnemyKind.Spiky -> 20f; EnemyKind.Flyer -> 20f; EnemyKind.Boss -> 38f }

    /** Places the enemy so its feet rest on the bottom edge of the tile it was authored in. */
    fun configure(centerX: Float, centerY: Float, spriteHeight: Float) {
        val py = if (kind == EnemyKind.Flyer) centerY else centerY - GameConstants.TILE / 2 + spriteHeight / 2
        x = centerX; y = py; originX = centerX; originY = py
    }

    fun update(dt: Float) {
        if (flashT >= 0) { flashT += dt; if (flashT > 0.29f) flashT = -1f }
        if (dyingT >= 0) { dyingT += dt; return }
        if (!alive) return
        age += dt
        x += direction * moveSpeed * dt
        if (x < originX - patrolDistance) direction = 1f else if (x > originX + patrolDistance) direction = -1f
        if (kind == EnemyKind.Flyer) y = originY + sin(age * 2.4f) * 10
    }

    fun stomp(): Boolean {
        stompHits++
        if (stompHits >= stompHitsRequired) {
            alive = false
            dyingT = 0f
            return true
        }
        flashT = 0f
        moveSpeed += 25
        return false
    }
}

class MovingPlatform(val path: List<FloatArray>, val speed: Float) {
    var x = path[0][0]
    var y = path[0][1]
    var index = 0
    var progress = 0f
}

class Scenery(val sprite: PixelSprite, val scale: Float, val x: Float, val y: Float)

class BuiltLevel(
    val map: TileMap,
    val theme: WorldTheme,
    val blocks: Array<Block?>,
    val solid: BooleanArray,
    val playerStartX: Float,
    val playerStartY: Float,
    val flag: FloatArray?,
    val items: MutableList<Item>,
    val enemies: List<Enemy>,
    val hazards: List<FloatArray>,
    val platforms: List<MovingPlatform>,
    val scenery: List<Scenery>,
    val groundTop: Float
)

object LevelBuilder {
    fun build(mission: Mission): BuiltLevel {
        val theme = WorldThemes.theme(mission.world)
        val width = mission.rows.maxOf { it.length }
        val rows = mission.rows.map { it.padEnd(width, '.') }
        val map = TileMap(rows)
        val t = GameConstants.TILE
        val blocks = arrayOfNulls<Block>(map.width * map.height)
        val solid = BooleanArray(map.width * map.height)
        val items = mutableListOf<Item>()
        val enemies = mutableListOf<Enemy>()
        val hazards = mutableListOf<FloatArray>()
        val platforms = mutableListOf<MovingPlatform>()
        var flag: FloatArray? = null
        var crawlerCount = 0
        val spikyEnabled = mission.id >= 10

        for (row in 0 until map.height) for (col in 0 until map.width) {
            val kind = map.kind(col, row)
            val cx = map.tileX(col) + t / 2
            val cy = map.tileY(row) + t / 2
            // Leaf-pads are one-way: Alina jumps up through them and lands on top.
            if (kind.isSolid && !kind.isSlope && kind != Tile.Moving && kind != Tile.Platform) solid[row * map.width + col] = true
            when (kind) {
                Tile.Solid, Tile.Ground, Tile.Brick, Tile.Question, Tile.Pipe, Tile.Spring -> {
                    val topExposed = !map.kind(col, row - 1).isSolid
                    val bk = when (kind) {
                        Tile.Solid -> BlockKind.Solid; Tile.Brick -> BlockKind.Brick
                        Tile.Question -> BlockKind.Question; Tile.Pipe -> BlockKind.Pipe; Tile.Spring -> BlockKind.Spring
                        else -> BlockKind.Ground
                    }
                    blocks[row * map.width + col] = Block(bk, col, row, topExposed)
                }
                Tile.Coin -> items += Item(ItemKind.Coin, cx, cy)
                Tile.Crystal -> items += Item(ItemKind.Crystal, cx, cy)
                Tile.Flag -> flag = floatArrayOf(cx, cy)
                Tile.Enemy -> {
                    crawlerCount++
                    val spiky = spikyEnabled && crawlerCount % 3 == 0
                    enemies += Enemy(if (spiky) EnemyKind.Spiky else EnemyKind.Crawler, themeKey = theme.key).also { it.configure(cx, cy, spriteHeight(it)) }
                }
                Tile.Boss -> enemies += Enemy(EnemyKind.Boss, 120, theme.key).also { it.configure(cx, cy, spriteHeight(it)) }
                Tile.Hazard -> hazards += floatArrayOf(cx, cy)
                Tile.Moving -> platforms += MovingPlatform(platformPath(col, row, rows), 50 + Random.nextFloat() * 30)
                else -> Unit
            }
        }

        for (p in mission.enemies) {
            val kind = when (p.kind.lowercase()) {
                "flyer", "fly" -> EnemyKind.Flyer; "boss" -> EnemyKind.Boss; "spiky" -> EnemyKind.Spiky; else -> EnemyKind.Crawler
            }
            val e = Enemy(kind, p.patrol ?: 80, theme.key)
            e.configure(map.tileX(p.x) + t / 2, map.tileY(p.y) + t / 2, spriteHeight(e))
            enemies += e
        }

        val (sx, sy) = startPoint(map)
        return BuiltLevel(
            map, theme, blocks, solid, sx, sy, flag, items, enemies, hazards, platforms,
            scenery(map, mission.layoutSeed), groundTop(map)
        )
    }

    private fun spriteHeight(e: Enemy) = app.jannat.alinaworld.pixel.PixelArt.height(e.frames[0]) * 3f

    private fun platformPath(col: Int, row: Int, rows: List<String>): List<FloatArray> {
        val t = GameConstants.TILE
        val baseX = col * t
        val baseY = (rows.size - 1 - row) * t
        val path = mutableListOf(floatArrayOf(baseX, baseY))
        var current = col
        var direction = 1
        repeat(10) {
            current += direction
            val c = rows[row].getOrNull(current)
            if (current < 0 || current >= rows[row].length || (c != '_' && c != 'M')) {
                direction *= -1
                current += direction * 2
            }
            path += floatArrayOf(current * t, baseY)
            if (path.size >= 4) return path
        }
        if (path.size < 2) path += floatArrayOf(baseX + 100, baseY)
        return path
    }

    /** Spawn above the highest solid tile in column 2, so floating blocks never become the start. */
    private fun startPoint(map: TileMap): Pair<Float, Float> {
        val col = minOf(2, map.width - 1)
        for (row in 0 until map.height) if (map.kind(col, row).isSolid) {
            return Pair(map.tileX(col) + GameConstants.TILE / 2, map.tileY(row) + GameConstants.TILE + GameConstants.PLAYER_HEIGHT / 2)
        }
        return Pair(GameConstants.TILE * 2, GameConstants.TILE * 3)
    }

    private fun groundTop(map: TileMap): Float {
        for (row in 0 until map.height) if (map.kind(0, row) == Tile.Ground) return map.tileY(row) + GameConstants.TILE
        return GameConstants.TILE * 2
    }

    /** Trees, bushes and flowers planted behind the tiles on exposed ground. */
    private fun scenery(map: TileMap, seed: Int): List<Scenery> {
        val rng = SeededRNG(seed.toULong() * 2654435761uL)
        val out = mutableListOf<Scenery>()
        var col = 4
        while (col < map.width - 3) {
            val row = surfaceRow(map, col)
            if (row == null) { col++; continue }
            val x = map.tileX(col) + GameConstants.TILE / 2
            val y = map.tileY(row) - 2
            val roll = (rng.next() % 100uL).toInt()
            val clear = (1..3).all { map.kind(col, row - it) == Tile.Empty }
            when {
                roll < 14 && clear && surfaceRow(map, col + 1) == row -> { out += Scenery(PixelSprite.Tree, 4f, x, y); col += 4 }
                roll < 30 -> { out += Scenery(PixelSprite.Bush, 3f, x, y); col += 2 }
                roll < 52 -> { out += Scenery(PixelSprite.Flower, 3f, x, y); col += 1 }
                else -> col += 1
            }
        }
        return out
    }

    /** Row of the first empty tile directly above ground in this column. */
    private fun surfaceRow(map: TileMap, col: Int): Int? {
        for (row in 1 until map.height) if (map.kind(col, row) == Tile.Ground) {
            return if (map.kind(col, row - 1) == Tile.Empty) row - 1 else null
        }
        return null
    }
}

class SeededRNG(seed: ULong) {
    private var state = if (seed == 0uL) 1uL else seed
    fun next(): ULong {
        state = state xor (state shl 13)
        state = state xor (state shr 7)
        state = state xor (state shl 17)
        return state
    }
}

/** Short keyframed value, standing in for SpriteKit's scale and move actions. */
class Tween(var value: Float = 1f) {
    private val steps = ArrayDeque<Pair<Float, Float>>()
    private var from = value
    private var t = 0f

    fun run(vararg targets: Pair<Float, Float>) {
        steps.clear(); steps.addAll(targets); from = value; t = 0f
    }

    fun update(dt: Float) {
        val step = steps.firstOrNull() ?: return
        t += dt
        val p = (t / step.second).coerceAtMost(1f)
        value = from + (step.first - from) * p
        if (p >= 1) { steps.removeFirst(); from = value; t = 0f }
    }
}

class Particle(
    var x: Float, var y: Float, val vx: Float, val vy: Float, val w: Float, val h: Float,
    val color: Int, var life: Float, var alpha: Float, val alphaSpeed: Float
)

class PopText(val text: String, val color: Int, val x: Float, val y: Float) {
    var t = 0f
}

fun burstParticles(out: MutableList<Particle>, x: Float, y: Float, colors: IntArray, count: Int = 10, speed: Float = 140f) {
    for (i in 0 until count) {
        val angle = i.toFloat() / count * 2 * PI.toFloat() + (Random.nextFloat() * 0.6f - 0.3f)
        val distance = speed * (0.5f + Random.nextFloat() * 0.5f)
        val dx = cos(angle) * distance * 0.5f
        val dy = sin(angle) * distance * 0.5f + 20
        out += Particle(x, y, dx / 0.45f, dy / 0.45f, 6f, 6f, colors[i % colors.size], 0.45f, 1f, -1f / 0.45f)
    }
}
