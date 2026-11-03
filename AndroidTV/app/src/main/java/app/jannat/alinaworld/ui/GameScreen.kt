package app.jannat.alinaworld.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.DirectionsWalk
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Timer
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import app.jannat.alinaworld.audio.Chiptune
import app.jannat.alinaworld.audio.SoundEffect
import app.jannat.alinaworld.data.Mission
import app.jannat.alinaworld.data.Objective
import app.jannat.alinaworld.data.Settings
import app.jannat.alinaworld.game.GameOutcome
import app.jannat.alinaworld.game.GameView
import app.jannat.alinaworld.game.GameWorld
import app.jannat.alinaworld.game.HudSnapshot
import app.jannat.alinaworld.game.Input
import app.jannat.alinaworld.pixel.PixelSprite
import kotlinx.coroutines.delay

/**
 * TV remote controls. With auto-run, a tap of ◀ ▶ keeps Alina running and ▼ stops her, so OK is free to jump;
 * without it the arrows must be held. Holding a direction sprints, Back pauses.
 */
private val gameplayControls: List<Pair<String, androidx.compose.ui.graphics.vector.ImageVector>>
    get() = if (Settings.autoRun) listOf(
        "◀ ▶" to Icons.Filled.DirectionsRun,
        "▼" to Icons.Filled.Stop,
        "OK ×2" to Icons.Filled.ArrowUpward,
        "hold ▶" to Icons.Filled.Bolt
    ) else listOf(
        "◀ ▶" to Icons.Filled.DirectionsWalk,
        "OK ×2" to Icons.Filled.ArrowUpward,
        "hold ▶" to Icons.Filled.Bolt
    )

@Composable
fun GameScreen(mission: Mission, attempt: Int) {
    val world = remember(attempt) { GameWorld(mission, Settings.assistMode, Settings.ambientEffects) }
    var hud by remember(attempt) { mutableStateOf(world.hud()) }
    var paused by remember(attempt) { mutableStateOf(false) }
    var showHint by remember(attempt) { mutableStateOf(Settings.showHints) }
    var view by remember(attempt) { mutableStateOf<GameView?>(null) }
    var focus by remember(attempt) { mutableIntStateOf(0) }

    fun pause() {
        focus = 0
        Chiptune.play(SoundEffect.Pause)
        Chiptune.setDucked(true)
        paused = true
    }

    fun resume(checkpoint: Boolean = false) {
        Chiptune.setDucked(false)
        paused = false
        if (checkpoint) world.restartFromCheckpoint() else world.resume()
        view?.resetClock()
    }

    DisposableEffect(world) {
        world.onPauseRequested = { pause() }
        world.onOutcome = { outcome ->
            Router.route = when (outcome) {
                is GameOutcome.Won -> Route.Won(outcome.result)
                is GameOutcome.Lost -> Route.Lost(mission.id, outcome.reason)
            }
        }
        onDispose { world.onOutcome = null; world.onPauseRequested = null; Input.steering = false }
    }
    LaunchedEffect(attempt) {
        delay(6000)
        showHint = false
    }

    val actions = listOf<() -> Unit>({ resume(checkpoint = true) }, { Router.play(mission.id) }, { Router.openMap() })
    Router.Keys {
        if (!paused) return@Keys
        if (Input.consumeEscape() || Input.consumePause()) { resume(); return@Keys }
        val before = focus
        if (Input.consumeUp()) focus = 0
        if (Input.consumeDown() && focus == 0) focus = 1
        if (Input.consumeLeft() && focus > 1) focus--
        if (Input.consumeRight()) focus = (focus + 1).coerceIn(1, actions.size)
        if (focus != before) Router.select()
        if (Input.consumeEnter()) if (focus == 0) resume() else actions[focus - 1]()
    }

    Box(Modifier.fillMaxSize()) {
        AndroidView(
            factory = { context -> GameView(context, world) { hud = it }.also { view = it } },
            modifier = Modifier.fillMaxSize()
        )
        Hud(mission, hud, showHint && !paused)
        if (paused) PauseOverlay(mission, hud, focus)
    }
}

@Composable
private fun Hud(mission: Mission, hud: HudSnapshot, showHint: Boolean) {
    Box(Modifier.fillMaxSize().padding(horizontal = 40.dp, vertical = 28.dp)) {
        // Hearts, then any power-ups Alina is carrying.
        val pulse = rememberInfiniteTransition(label = "lastHeart")
        val beat by pulse.animateFloat(1f, 1.08f, infiniteRepeatable(tween(500), RepeatMode.Reverse), label = "beat")
        Row(
            Modifier.align(Alignment.TopStart).height(52.dp).background(Color.White.copy(alpha = 0.92f), RoundedCornerShape(18.dp)).padding(horizontal = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Row(Modifier.scale(if (hud.hearts == 1) beat else 1f), horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                for (i in 0 until hud.maxHearts) Sprite(if (i < hud.hearts) PixelSprite.Heart else PixelSprite.HeartEmpty, 4f)
            }
            if (hud.bloom || hud.ribbon) {
                Box(Modifier.padding(horizontal = 6.dp).size(2.dp, 28.dp).background(Palette.line))
                if (hud.bloom) Sprite(PixelSprite.Sunbloom, 3f)
                if (hud.ribbon) Sprite(PixelSprite.Ribbon, 3f)
            }
        }

        Box(Modifier.align(Alignment.TopCenter)) { Objective(mission, hud) }

        Row(Modifier.align(Alignment.TopEnd), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            HudPill {
                Sprite(PixelSprite.Petal, 3f)
                BasicText("${hud.petals}", style = rounded(21.sp, FontWeight.Bold))
            }
            HudPill {
                val urgent = hud.countdown && hud.seconds <= 15
                Glyph(if (hud.countdown) Icons.Filled.Timer else Icons.Filled.Schedule, if (urgent) Palette.pinkText else Palette.ink, 22.dp)
                BasicText("%d:%02d".format(hud.seconds / 60, hud.seconds % 60), style = rounded(21.sp, FontWeight.Bold, if (urgent) Palette.pinkText else Palette.ink))
            }
        }

        if (mission.objective == Objective.ReachFlag) {
            // Up top on TV, so the ground band stays free for the remote hints.
            Box(Modifier.align(Alignment.TopCenter).padding(top = 14.dp)) { BeaconProgress(hud.progress) }
        }
        AnimatedVisibility(
            // In the dirt below the ground line, clear of where Alina runs.
            showHint, Modifier.align(Alignment.BottomStart).offset(y = 16.dp),
            enter = fadeIn() + slideInVertically { it }, exit = fadeOut(tween(400)) + slideOutVertically { it }
        ) { ControlStrip(gameplayControls + ("Back" to Icons.Filled.Pause)) }
    }
}

@Composable
private fun HudPill(content: @Composable androidx.compose.foundation.layout.RowScope.() -> Unit) {
    Row(
        Modifier.height(52.dp).background(Color.White.copy(alpha = 0.92f), RoundedCornerShape(18.dp)).padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        content = content
    )
}

/** Top-center goal: one crystal per shard, guardian pips, or nothing for the beacon run. */
@Composable
private fun Objective(mission: Mission, hud: HudSnapshot) {
    when (mission.objective) {
        Objective.CollectN -> {
            val target = hud.shardTarget ?: mission.collectRequired
            HudPill {
                for (i in 0 until target) {
                    val got = i < hud.shards
                    val s by animateFloatAsState(if (got) 1f else 0.85f, label = "shard")
                    Sprite(PixelSprite.Crystal, 3f, Modifier.scale(s).alpha(if (got) 1f else 0.3f))
                }
            }
        }
        Objective.DefeatBoss -> HudPill {
            Sprite(PixelSprite.Guardian, 2f)
            for (i in 0 until 3) {
                val hit = i < hud.bossHits
                Box(
                    Modifier.size(16.dp).background(if (hit) Palette.pink else Palette.line, CircleShape)
                        .border(2.dp, if (hit) Palette.pinkDeep else Palette.unearned, CircleShape)
                )
            }
        }
        Objective.ReachFlag -> Unit
    }
}

@Composable
private fun BeaconProgress(progress: Float) {
    Box(Modifier.width(480.dp).height(30.dp)) {
        Canvas(Modifier.fillMaxSize()) {
            val u = density
            val top = size.height - 12 * u
            val w = size.width
            val x = w * progress.coerceIn(0f, 1f)
            drawRoundRect(Palette.ink.copy(alpha = 0.12f), Offset(0f, top + 3 * u), Size(w, 12 * u), CornerRadius(6 * u))
            drawRoundRect(Color.White.copy(alpha = 0.75f), Offset(0f, top), Size(w, 12 * u), CornerRadius(6 * u))
            drawRoundRect(Palette.mint, Offset(0f, top), Size(maxOf(12 * u, x), 12 * u), CornerRadius(6 * u))
            drawRect(Palette.gold, Offset(w / 2 - 2 * u, top - 4 * u), Size(4 * u, 20 * u))
            drawCircle(Color.White, 12 * u, Offset(x, top + 6 * u))
            drawCircle(Palette.pink, 8 * u, Offset(x, top + 6 * u))
        }
        Sprite(PixelSprite.Beacon, 2f, Modifier.align(Alignment.BottomEnd).offset(x = 10.dp, y = (-6).dp))
    }
}

@Composable
private fun PauseOverlay(mission: Mission, hud: HudSnapshot, focus: Int) {
    Box(Modifier.fillMaxSize().background(Palette.ink.copy(alpha = 0.45f)), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(20.dp)) {
            Column(
                Modifier.width(380.dp).card(32.dp, 32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(24.dp)
            ) {
                BasicText("Paused", style = rounded(40.sp, FontWeight.Black))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    if (mission.objective == Objective.CollectN) {
                        StatChip("${hud.shards}/${hud.shardTarget ?: mission.collectRequired}", Palette.goldSoft, Palette.goldText) { Sprite(PixelSprite.Crystal, 2f) }
                    } else {
                        StatChip("${(hud.progress * 100).toInt()}%", Palette.mintSoft, Palette.mintText) { Sprite(mission.goalSprite, 2f) }
                    }
                    StatChip("${hud.petals}", Palette.pinkSoft, Palette.pinkText) { Sprite(PixelSprite.Petal, 2f) }
                    StatChip("%d:%02d".format(hud.seconds / 60, hud.seconds % 60), Palette.skySoft, Palette.skyText) {
                        Glyph(if (hud.countdown) Icons.Filled.Timer else Icons.Filled.Schedule, Palette.skyText, 20.dp)
                    }
                }
                Tile(TileKind.Primary, 72.dp, focus == 0, Modifier.fillMaxWidth()) { fg -> Glyph(Icons.Filled.PlayArrow, fg, 40.dp) }
                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    listOf(
                        Icons.Filled.Flag to TileKind.Secondary,
                        Icons.Filled.Replay to TileKind.Secondary,
                        Icons.Filled.Map to TileKind.Danger
                    ).forEachIndexed { i, (icon, kind) ->
                        Tile(kind, 64.dp, focus == i + 1, width = 64.dp) { fg -> Glyph(icon, fg, 28.dp) }
                    }
                }
            }
            ControlStrip(gameplayControls)
        }
    }
}
