package app.jannat.alinaworld.game

import app.jannat.alinaworld.audio.Chiptune
import app.jannat.alinaworld.audio.SoundEffect
import app.jannat.alinaworld.data.GameProgress
import app.jannat.alinaworld.data.Mission
import app.jannat.alinaworld.data.MissionResult
import app.jannat.alinaworld.data.Objective
import kotlin.math.ceil
import kotlin.math.exp
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.random.Random

/** Values the Compose HUD renders; compared before publishing so it only recomposes on change. */
data class HudSnapshot(
    val hearts: Int = 3,
    val maxHearts: Int = 3,
    val petals: Int = 0,
    val shards: Int = 0,
    val shardTarget: Int? = null,
    val bossHits: Int = 0,
    val seconds: Int = 0,
    val countdown: Boolean = false,
    val bloom: Boolean = false,
    val ribbon: Boolean = false,
    val progress: Float = 0f
)

sealed interface GameOutcome {
    class Won(val result: MissionResult) : GameOutcome
    class Lost(val reason: String) : GameOutcome
}

/** One attempt at a mission: the simulation formerly in the SpriteKit scene. */
class GameWorld(val mission: Mission, private val assistMode: Boolean, val ambient: Boolean) {
    val level = LevelBuilder.build(mission)
    val map get() = level.map
    val player = Player()
    val particles = mutableListOf<Particle>()
    val ambientParticles = mutableListOf<Particle>()
    val pops = mutableListOf<PopText>()
    /** Tile indices whose look changed (bumped, emptied or broken), so the renderer can redraw their chunk. */
    val tileChanges = mutableListOf<Int>()

    var onOutcome: ((GameOutcome) -> Unit)? = null
    var onPauseRequested: (() -> Unit)? = null

    private var hearts = if (assistMode) 4 else 3
    private val maxHearts = hearts
    private var petals = 0
    private var shards = 0
    private var hits = 0
    var elapsed = 0f; private set
    var finished = false; private set
    var paused = false; private set
    private var bossDefeated = false
    private var checkpointX = level.playerStartX
    private var checkpointY = level.playerStartY
    private var bloomBlocksOpened = 0
    private var outcomeTimer = -1f
    private var pendingOutcome: GameOutcome? = null

    /** Camera center in world units; `viewWidth` follows the screen's aspect. */
    var cameraX = 0f; private set
    var cameraY = GameConstants.VIEW_HEIGHT / 2; private set
    var viewWidth = GameConstants.VIEW_HEIGHT * 16 / 9
        set(value) { field = value; if (!cameraPlaced) placeCamera() }
    private var cameraPlaced = false
    var cloudDrift = 0f; private set
    private var ambientSpawn = 0f

    private val timeLimit: Float? = mission.timeLimit?.let { it * if (assistMode) 1.3f else 1f }
    private val mapWidth get() = map.worldWidth
    private val parTime get() = mission.parTime

    init {
        player.x = level.playerStartX
        player.y = level.playerStartY
        player.primeJump(Input.jumpHeld)
        Input.autoRun = app.jannat.alinaworld.data.Settings.autoRun
        Input.steering = false
        placeCamera()
        if (ambient) repeat(8 * 30) { updateAmbient(1f / 30f) }
    }

    private fun placeCamera() {
        cameraX = max(viewWidth / 2, player.x + 80)
        cameraY = GameConstants.VIEW_HEIGHT / 2
        cameraPlaced = true
    }

    // Pause

    fun pause() {
        if (paused || finished) return
        paused = true
        Input.steering = false
    }

    fun resume() {
        paused = false
        Input.consumePause()
        player.primeJump(Input.jumpHeld)
    }

    fun restartFromCheckpoint() {
        player.resetForRespawn(checkpointX, checkpointY)
        Input.stopCruise()
        resume()
    }

    // Loop

    fun update(rawDt: Float) {
        if (paused) return
        val dt = min(rawDt, 1f / 30f)
        updateEffects(dt)
        if (finished) {
            if (outcomeTimer >= 0) {
                outcomeTimer -= dt
                if (outcomeTimer < 0) pendingOutcome?.let { onOutcome?.invoke(it) }
            }
            return
        }
        elapsed += dt
        if (!Input.steering) Input.steering = true
        Input.tick(dt)

        if (Input.consumePause() || Input.consumeEscape()) {
            pause()
            onPauseRequested?.invoke()
            return
        }
        Input.consumeEnter(); Input.consumeUp(); Input.consumeDown(); Input.consumeLeft(); Input.consumeRight()

        timeLimit?.let { if (elapsed > it) { fail("The light faded before Alina reached it."); return } }

        updateMovingPlatforms(dt)
        player.update(dt, mission.difficulty)
        moveAndCollide(dt)

        for (enemy in level.enemies) if (enemy.alive) {
            enemy.update(dt)
            handleEnemyCollision(enemy)
        }

        checkCollectibles()
        checkFlag()
        checkHazards()
        checkFallDeath()
        updateCheckpoint()
        updateCamera(dt)

        if (mission.objective == Objective.DefeatBoss && bossDefeated) win()
        else if (mission.objective == Objective.CollectN && shards >= mission.collectRequired) win()
    }

    /** Animations that keep playing after the mission ends. */
    private fun updateEffects(dt: Float) {
        player.updateVisuals(dt)
        for (e in level.enemies) if (!e.alive) e.update(dt)
        level.blocks.forEachIndexed { i, b ->
            if (b != null && b.bumpT >= 0) { b.bumpT += dt; if (b.bumpT > 0.16f) { b.bumpT = -1f; tileChanges += i } }
        }
        level.items.forEach { it.update(dt) }
        level.items.removeAll { it.removed }

        if (player.dustRequest > 0) {
            repeat(minOf(player.dustRequest, 12)) {
                val angle = (Math.PI / 2 + (Random.nextFloat() - 0.5f) * Math.PI / 3).toFloat()
                val speed = 40 + (Random.nextFloat() - 0.5f) * 40
                particles += Particle(
                    player.x + (Random.nextFloat() - 0.5f) * 10, player.y - 14 + (Random.nextFloat() - 0.5f) * 2,
                    kotlin.math.cos(angle) * speed, kotlin.math.sin(angle) * speed, 4f, 4f, 0xFFFFFF, 0.35f, 0.8f, -2.2f
                )
            }
            player.dustRequest = 0
        }
        updateParticles(particles, dt)
        pops.forEach { it.t += dt }
        pops.removeAll { it.t > 0.6f }

        cloudDrift += dt * 4
        if (ambient) updateAmbient(dt)
    }

    private fun updateParticles(list: MutableList<Particle>, dt: Float) {
        val it = list.iterator()
        while (it.hasNext()) {
            val p = it.next()
            p.x += p.vx * dt; p.y += p.vy * dt
            p.life -= dt
            p.alpha += p.alphaSpeed * dt
            if (p.life <= 0 || p.alpha <= 0) it.remove()
        }
    }

    /** Weather drifting through the level, emitted just above the camera like the Mac emitter. */
    private fun updateAmbient(dt: Float) {
        val kind = level.theme.particles
        val rate: Float
        val color: Int
        var w = 6f; var h = 6f
        val angle: Float
        val speed: Float
        var life = 9f
        var alpha = 1f
        var alphaSpeed = -0.05f
        var spreadY = 0f
        when (kind) {
            AmbientParticles.Petals -> { rate = 1.6f; color = 0xFF8DBE; angle = (-Math.PI / 2 - 0.5).toFloat(); speed = 50f }
            AmbientParticles.Leaves -> { rate = 1.8f; color = 0x62BF55; angle = (-Math.PI / 2 - 0.4).toFloat(); speed = 45f }
            AmbientParticles.Rain, AmbientParticles.Storm -> {
                rate = if (kind == AmbientParticles.Storm) 70f else 40f; color = 0xFFFFFF; alpha = 0.55f; w = 2f; h = 12f
                angle = (-Math.PI / 2 - if (kind == AmbientParticles.Storm) 0.25 else 0.1).toFloat(); speed = 520f; life = 1.6f
            }
            AmbientParticles.Embers -> { rate = 3f; color = 0xFFB347; w = 4f; h = 4f; angle = (Math.PI / 2).toFloat(); speed = 30f; spreadY = 500f }
            AmbientParticles.Dust, AmbientParticles.Mist -> { rate = 2f; color = 0xFFFFFF; alpha = 0.5f; w = 4f; h = 4f; angle = 0f; speed = 40f; spreadY = 500f }
            AmbientParticles.Sparkles, AmbientParticles.Motes -> {
                rate = 3f; color = if (kind == AmbientParticles.Sparkles) 0xFFFFFF else 0xFFE98A; w = 4f; h = 4f
                angle = (Math.PI / 2).toFloat(); speed = 14f; alphaSpeed = -0.15f; spreadY = 500f
            }
        }
        ambientSpawn += rate * dt
        val ex = cameraX
        val ey = cameraY + GameConstants.VIEW_HEIGHT / 2 + 20
        while (ambientSpawn >= 1) {
            ambientSpawn -= 1
            ambientParticles += Particle(
                ex + (Random.nextFloat() - 0.5f) * 1200 * 1.4f, ey + (Random.nextFloat() - 0.5f) * spreadY,
                kotlin.math.cos(angle) * speed, kotlin.math.sin(angle) * speed, w, h, color, life, alpha, alphaSpeed
            )
        }
        updateParticles(ambientParticles, dt)
    }

    private fun updateMovingPlatforms(dt: Float) {
        for (p in level.platforms) {
            if (p.path.size < 2) continue
            val current = p.path[p.index]
            val nextIndex = (p.index + 1) % p.path.size
            val next = p.path[nextIndex]
            val distance = max(1f, hypot(next[0] - current[0], next[1] - current[1]))
            p.progress += dt / (distance / p.speed)
            if (p.progress >= 1f) { p.progress = 0f; p.index = nextIndex }
            p.x = current[0] + (next[0] - current[0]) * p.progress
            p.y = current[1] + (next[1] - current[1]) * p.progress
        }
    }

    // Collision

    private fun moveAndCollide(dt: Float) {
        val rect = player.box
        rect.x += player.vx * dt
        rect.x = rect.x.coerceIn(0f, mapWidth - rect.w)
        resolveAxis(rect, horizontal = true)

        rect.y += player.vy * dt
        player.onGround = false
        resolveAxis(rect, horizontal = false)
        checkSlopes(rect)
        checkPlatforms(rect)

        player.x = rect.midX
        player.y = rect.midY
        checkHeadBonk()
    }

    private inline fun forTilesNear(rect: Box, action: (col: Int, row: Int) -> Unit) {
        val t = GameConstants.TILE
        val c0 = ((rect.minX / t).toInt() - 1).coerceAtLeast(0)
        val c1 = ((rect.maxX / t).toInt() + 1).coerceAtMost(map.width - 1)
        val r0 = (map.height - 1 - (rect.maxY / t).toInt() - 1).coerceAtLeast(0)
        val r1 = (map.height - 1 - (rect.minY / t).toInt() + 1).coerceAtMost(map.height - 1)
        for (row in r0..r1) for (col in c0..c1) action(col, row)
    }

    private fun resolveAxis(rect: Box, horizontal: Boolean) {
        val t = GameConstants.TILE
        forTilesNear(rect) { col, row ->
            if (!level.solid[row * map.width + col]) return@forTilesNear
            val tx = map.tileX(col); val ty = map.tileY(row)
            if (!rect.intersects(tx, ty, t, t)) return@forTilesNear
            if (horizontal) {
                if (player.vx > 0) rect.x = tx - rect.w else if (player.vx < 0) rect.x = tx + t
                player.vx = 0f
            } else {
                if (player.vy < 0) { rect.y = ty + t; player.onGround = true; player.vy = 0f }
                else if (player.vy > 0) { rect.y = ty - rect.h; player.vy = 0f }
            }
        }
    }

    private fun checkSlopes(rect: Box) {
        if (player.vy > 0) return
        val t = GameConstants.TILE
        forTilesNear(rect) { col, row ->
            val kind = map.kind(col, row)
            if (!kind.isSlope) return@forTilesNear
            val sx = map.tileX(col); val sy = map.tileY(row)
            if (rect.midX <= sx || rect.midX >= sx + t) return@forTilesNear
            val p = (rect.midX - sx) / t
            val rising = kind == Tile.SlopeUpRight || kind == Tile.SlopeDownLeft
            val surface = sy + t * (if (rising) p else 1 - p)
            if (rect.minY <= surface + 4 && rect.minY >= surface - 10) {
                rect.y = surface; player.onGround = true; player.vy = 0f
            }
        }
    }

    private fun checkPlatforms(rect: Box) {
        if (player.vy > 0) return
        val t = GameConstants.TILE
        val feet = rect.minY
        forTilesNear(rect) { col, row ->
            val kind = map.kind(col, row)
            // The Mac game also treats a moving platform's starting tile as a ledge; kept so levels play the same.
            if (kind != Tile.Platform && kind != Tile.Moving) return@forTilesNear
            val px = map.tileX(col); val top = map.tileY(row) + t
            if (rect.maxX > px + 2 && rect.minX < px + t - 2 && feet <= top && feet >= top - 10) {
                rect.y = top; player.onGround = true; player.vy = 0f
            }
        }
        for (p in level.platforms) {
            val top = p.y + 10
            if (rect.maxX > p.x - 64 && rect.minX < p.x + 64 && feet <= top && feet >= top - 12) {
                rect.y = top; player.onGround = true; player.vy = 0f
            }
        }
    }

    private fun checkHeadBonk() {
        if (!(player.vy > 0 || !player.onGround)) return
        val head = Box(player.x - 8, player.y + 12, 16f, 6f)
        val t = GameConstants.TILE
        forTilesNear(head) { col, row ->
            val index = row * map.width + col
            val block = level.blocks[index] ?: return@forTilesNear
            if (block.kind != BlockKind.Question && block.kind != BlockKind.Brick) return@forTilesNear
            if (!head.intersects(map.tileX(col), map.tileY(row), t, t) || player.vy < 0) return@forTilesNear
            val cx = map.tileX(col) + t / 2; val cy = map.tileY(row) + t / 2
            tileChanges += index
            if (block.kind == BlockKind.Question) {
                if (block.revealed) return@forTilesNear
                block.bump(); block.revealed = true; block.used = true
                player.vy = 0f
                Chiptune.play(SoundEffect.Bump)
                openBloomBlock(cx, cy)
            } else {
                player.vy = 0f
                block.hitCount++
                if (block.hitCount >= 2 || player.bloom) {
                    burstParticles(particles, cx, cy, intArrayOf(0xE09466, 0xB0643F, 0x76CF63), 8, 200f)
                    Chiptune.play(SoundEffect.BrickBreak)
                    level.blocks[index] = null
                    level.solid[index] = false
                } else {
                    Chiptune.play(SoundEffect.Bump)
                    block.bump()
                }
            }
        }
    }

    /** The first bloom block and every third one after it hold a power-up; the rest pop petals. */
    private fun openBloomBlock(cx: Float, cy: Float) {
        val holdsPowerUp = bloomBlocksOpened % 3 == 0
        bloomBlocksOpened++
        val kind = if (!holdsPowerUp) null else if (!player.bloom) ItemKind.Sunbloom else if (!player.hasRibbon) ItemKind.Ribbon else null
        if (kind != null) {
            level.items += Item(kind, cx, cy + 32).also { it.emerge() }
        } else {
            petals++
            Chiptune.play(SoundEffect.Petal)
            pops += PopText("+1", 0xC13B73, cx, cy + 30)
        }
    }

    private fun handleEnemyCollision(enemy: Enemy) {
        val ex = enemy.x - enemy.hitW / 2
        val ey = enemy.y - enemy.hitH / 2
        val box = player.box
        if (!box.intersects(ex, ey, enemy.hitW, enemy.hitH)) return
        val stomping = player.vy < 0 && box.minY >= ey + enemy.hitH - 12
        if (stomping && enemy.kind != EnemyKind.Spiky) {
            val defeated = enemy.stomp()
            player.applyBounce()
            Chiptune.play(SoundEffect.Stomp)
            burstParticles(particles, enemy.x, enemy.y, intArrayOf(0x5E52A0, 0xFFFFFF), 8)
            if (defeated) {
                val boss = enemy.kind == EnemyKind.Boss
                petals += if (boss) 10 else 2
                pops += PopText(if (boss) "+10" else "+2", 0xC13B73, enemy.x, enemy.y + 24)
                if (boss) bossDefeated = true
            }
        } else if (player.stompGraceTimer <= 0) {
            takeHit(enemy.x)
        }
    }

    private fun takeHit(fromX: Float) {
        if (player.hurtCooldown > 0) return
        hits++
        Chiptune.play(SoundEffect.Hurt)
        val shielded = player.absorbHit()
        player.knockback(fromX)
        if (!shielded) loseHeart()
    }

    private fun loseHeart() {
        hearts--
        if (hearts <= 0) fail("Alina ran out of hearts.")
    }

    private fun checkCollectibles() {
        val box = player.box.apply { x -= 4; y -= 4; w += 8; h += 8 }
        for (item in level.items) {
            if (item.collecting || item.alpha <= 0.5f) continue
            if (!box.intersects(item.x - 12, item.y - 12, 24f, 24f)) continue
            item.collect()
            when (item.kind) {
                ItemKind.Coin -> {
                    petals++
                    Chiptune.play(SoundEffect.Petal)
                    burstParticles(particles, item.x, item.y, intArrayOf(0xFF8DBE, 0xF6C343), 6, 90f)
                }
                ItemKind.Crystal -> {
                    shards++
                    Chiptune.play(SoundEffect.Shard)
                    burstParticles(particles, item.x, item.y, intArrayOf(0xF6C343, 0xFFFFFF), 12)
                    pops += PopText("Shard $shards", 0xA86A00, item.x, item.y + 26)
                }
                ItemKind.Sunbloom -> {
                    player.grantBloom()
                    Chiptune.play(SoundEffect.PowerUp)
                    pops += PopText("Sunbloom!", 0xA86A00, item.x, item.y + 26)
                }
                ItemKind.Ribbon -> {
                    player.grantRibbon()
                    Chiptune.play(SoundEffect.PowerUp)
                    pops += PopText("Glow Ribbon!", 0xC13B73, item.x, item.y + 26)
                }
            }
        }
    }

    private fun checkFlag() {
        if (mission.objective != Objective.ReachFlag) return
        val flag = level.flag ?: return
        if (player.box.intersects(flag[0] - 16, flag[1] - 16, 32f, 64f)) win()
    }

    private fun checkHazards() {
        val box = player.box
        for (h in level.hazards) {
            if (box.intersects(h[0] - 13, h[1] - 16, 26f, 14f)) {
                takeHit(h[0])
                if (player.hurtCooldown > 0 && player.vy < 300) player.vy = 420f
                return
            }
        }
    }

    private fun checkFallDeath() {
        if (player.y >= -48) return
        hits++
        Chiptune.play(SoundEffect.Hurt)
        loseHeart()
        if (!finished) {
            player.resetForRespawn(checkpointX, checkpointY)
            Input.stopCruise()
        }
    }

    /** Halfway through the level, the next safe landing becomes the respawn point. */
    private fun updateCheckpoint() {
        if (!player.onGround || player.x <= mapWidth * 0.5f || checkpointX >= mapWidth * 0.5f) return
        checkpointX = player.x
        checkpointY = player.y
        Chiptune.play(SoundEffect.Checkpoint)
        pops += PopText("Checkpoint", 0x1F7A50, player.x, player.y + 40)
    }

    // Outcome

    private fun win() {
        if (finished) return
        finished = true
        Input.steering = false
        val previousBest = GameProgress.bestTime(mission.id)
        val result = MissionResult(
            missionID = mission.id,
            petals = petals,
            time = elapsed,
            hits = hits,
            parTime = parTime,
            stars = booleanArrayOf(true, elapsed <= parTime, hits == 0),
            newBestTime = previousBest?.let { elapsed < it } ?: true
        )
        GameProgress.recordCompletion(result)
        burstParticles(particles, player.x, player.y, intArrayOf(0xF6C343, 0xFF8DBE, 0xFFFFFF), 24, 260f)
        pendingOutcome = GameOutcome.Won(result)
        outcomeTimer = 0.9f
    }

    private fun fail(reason: String) {
        if (finished) return
        finished = true
        Input.steering = false
        player.failT = 0f
        pendingOutcome = GameOutcome.Lost(reason)
        outcomeTimer = 0.7f
    }

    /** Fail animation offset: Alina rises 30 units over 0.2 s. */
    val playerLift get() = if (player.failT < 0) 0f else 30 * (player.failT / 0.2f).coerceAtMost(1f)

    private fun updateCamera(dt: Float) {
        var targetX = player.x + 80
        targetX = if (mapWidth <= viewWidth) mapWidth / 2 else targetX.coerceIn(viewWidth / 2, mapWidth - viewWidth / 2)
        val targetY = max(GameConstants.VIEW_HEIGHT / 2, player.y + 60)
        val factor = 1f - exp(-10f * dt)
        cameraX += (targetX - cameraX) * factor
        cameraY += (targetY - cameraY) * factor
    }

    // HUD

    val boss: Enemy? = level.enemies.firstOrNull { it.kind == EnemyKind.Boss }

    fun hud(): HudSnapshot {
        val progress = when (mission.objective) {
            Objective.ReachFlag -> (player.x / max(1f, level.flag?.get(0) ?: mapWidth)).coerceIn(0f, 1f)
            Objective.CollectN -> shards.toFloat() / max(1, mission.collectRequired)
            Objective.DefeatBoss -> (boss?.stompHits ?: 0) / 3f
        }
        val seconds = timeLimit?.let { max(0, ceil(it - elapsed).toInt()) } ?: elapsed.toInt()
        return HudSnapshot(
            hearts = max(0, hearts),
            maxHearts = maxHearts,
            petals = petals,
            shards = shards,
            shardTarget = if (mission.objective == Objective.CollectN) mission.collectRequired else null,
            bossHits = boss?.stompHits ?: 0,
            seconds = seconds,
            countdown = timeLimit != null,
            bloom = player.bloom,
            ribbon = player.hasRibbon,
            progress = (progress * 50).toInt() / 50f
        )
    }
}
