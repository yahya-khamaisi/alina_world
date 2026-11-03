package app.jannat.alinaworld.ui

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.BasicText
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Timer
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.jannat.alinaworld.data.GameProgress
import app.jannat.alinaworld.data.MissionResult
import app.jannat.alinaworld.data.Missions
import app.jannat.alinaworld.data.Objective
import app.jannat.alinaworld.game.Input
import app.jannat.alinaworld.game.WorldThemes
import app.jannat.alinaworld.pixel.PixelSprite
import kotlinx.coroutines.delay

@Composable
fun MissionCompleteScreen(result: MissionResult) {
    val mission = Missions.byId(result.missionID)
    val next = Missions.byId(result.missionID + 1)
    val finale = result.missionID == GameProgress.MISSION_COUNT
    val crystal = mission?.objective == Objective.DefeatBoss
    val theme = mission?.let { WorldThemes.theme(it.world) } ?: WorldThemes.ordered[0]
    var focus by remember { mutableIntStateOf(0) }
    var revealed by remember { mutableIntStateOf(0) }
    LaunchedEffect(Unit) { for (i in 1..3) { delay(250); revealed = i } }

    fun onNext() {
        val id = result.missionID + 1
        if (id <= GameProgress.MISSION_COUNT && GameProgress.isUnlocked(id)) {
            Router.mapIndex = id - 1
            Router.route = Route.Briefing(id)
        } else Router.openMap()
    }
    val actions = listOf(::onNext, { Router.play(result.missionID) }, { Router.openMap() })

    Router.Keys {
        val before = focus
        if (Input.consumeLeft() || Input.consumeUp()) focus = (focus - 1).coerceAtLeast(0)
        if (Input.consumeRight() || Input.consumeDown()) focus = (focus + 1).coerceAtMost(2)
        if (focus != before) Router.select()
        if (Input.consumeEnter()) actions[focus]()
        if (Input.consumeEscape()) Router.openMap()
    }

    Box(Modifier.fillMaxSize()) {
        Backdrop(Modifier.fillMaxSize(), theme)
        BoxWithConstraints(Modifier.fillMaxSize()) {
            val groundTop = maxHeight - maxOf(96.dp, maxHeight * 0.16f)
            Sprite(PixelSprite.AlinaJump, 7f, Modifier.offset(maxWidth * 0.16f, groundTop - 170.dp))
            Sprite(if (crystal) PixelSprite.Crystal else PixelSprite.Beacon, 7f, Modifier.offset(maxWidth * 0.78f, groundTop - if (crystal) 160.dp else 112.dp))
        }
        Column(
            Modifier.align(Alignment.Center).width(440.dp).card(32.dp, 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(22.dp)
        ) {
            BasicText(if (finale) "The Isles Shine!" else "Clear!", style = rounded(44.sp, FontWeight.Black))
            Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                BigStar(result.stars[0], revealed > 0, 64.dp)
                BigStar(result.stars[1], revealed > 1, 86.dp)
                BigStar(result.stars[2], revealed > 2, 64.dp)
            }
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                StatChip(
                    formatTime(result.time), if (result.stars[1]) Palette.mintSoft else Palette.sand,
                    if (result.stars[1]) Palette.mintText else Palette.body, 52.dp, 22.sp
                ) {
                    Glyph(Icons.Filled.Timer, if (result.stars[1]) Palette.mintText else Palette.body, 22.dp)
                    if (result.newBestTime) Glyph(Icons.Filled.ArrowUpward, Palette.mintText, 18.dp)
                }
                StatChip("+${result.petals}", Palette.pinkSoft, Palette.pinkText, 52.dp, 22.sp) { Sprite(PixelSprite.Petal, 3f) }
                StatChip(if (result.hits == 0) "" else "−${result.hits}", if (result.stars[2]) Palette.goldSoft else Palette.sand, Palette.body, 52.dp, 22.sp) {
                    Sprite(if (result.hits == 0) PixelSprite.Heart else PixelSprite.HeartEmpty, 3f)
                }
                if (crystal) StatChip(fill = Palette.goldSoft, height = 52.dp) { Sprite(PixelSprite.Crystal, 3f) }
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                Tile(TileKind.Primary, 72.dp, focus == 0, Modifier.weight(1f)) { fg ->
                    if (finale) Glyph(Icons.Filled.Map, fg, 32.dp) else {
                        BasicText(next?.code ?: "", style = rounded(29.sp, FontWeight.Black, fg))
                        Glyph(Icons.Filled.ArrowForward, fg, 30.dp)
                    }
                }
                Tile(TileKind.Secondary, 72.dp, focus == 1, width = 72.dp) { fg -> Glyph(Icons.Filled.Replay, fg, 30.dp) }
                Tile(TileKind.Secondary, 72.dp, focus == 2, width = 72.dp) { fg -> Glyph(Icons.Filled.Map, fg, 30.dp) }
            }
        }
    }
}

@Composable
private fun BigStar(earned: Boolean, shown: Boolean, size: Dp) {
    val scale by animateFloatAsState(if (shown) 1f else 0.4f, spring(dampingRatio = 0.5f, stiffness = Spring.StiffnessMediumLow), label = "star")
    Box(Modifier.scale(scale).alpha(if (shown) 1f else 0.5f)) {
        Glyph(Icons.Filled.Star, if (earned && shown) Palette.gold else androidx.compose.ui.graphics.Color(0xFFEDE5D8), size)
    }
}

@Composable
fun DefeatScreen(missionID: Int, reason: String) {
    val mission = Missions.byId(missionID)
    val timedOut = reason.contains("light faded", ignoreCase = true)
    var focus by remember { mutableIntStateOf(0) }

    Router.Keys {
        if (Input.consumeLeft() || Input.consumeUp()) focus = 0
        if (Input.consumeRight() || Input.consumeDown()) focus = 1
        if (Input.consumeEnter()) if (focus == 0) Router.play(missionID) else Router.openMap()
        if (Input.consumeEscape()) Router.openMap()
    }

    Box(Modifier.fillMaxSize()) {
        Backdrop(Modifier.fillMaxSize(), mission?.let { WorldThemes.theme(it.world) } ?: WorldThemes.ordered[0])
        Box(Modifier.fillMaxSize().background(Palette.ink.copy(alpha = 0.25f)))
        Column(
            Modifier.align(Alignment.Center).width(340.dp).card(32.dp, 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(22.dp)
        ) {
            Sprite(PixelSprite.AlinaFall, 6f)
            BasicText("Oops!", style = rounded(40.sp, FontWeight.Black))
            if (timedOut) {
                StatChip("0:00", Palette.skySoft, Palette.skyText, 52.dp, 22.sp) { Glyph(Icons.Filled.Timer, Palette.skyText, 22.dp) }
            } else {
                StatChip(fill = Palette.pinkSoft, height = 52.dp) { repeat(3) { Sprite(PixelSprite.HeartEmpty, 3f) } }
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Tile(TileKind.Primary, 72.dp, focus == 0, Modifier.weight(1f)) { fg -> Glyph(Icons.Filled.Replay, fg, 36.dp) }
                Tile(TileKind.Secondary, 72.dp, focus == 1, width = 72.dp) { fg -> Glyph(Icons.Filled.Map, fg, 30.dp) }
            }
        }
    }
}
