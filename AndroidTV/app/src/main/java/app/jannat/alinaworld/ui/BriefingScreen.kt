package app.jannat.alinaworld.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Timer
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.jannat.alinaworld.data.GameProgress
import app.jannat.alinaworld.data.Mission
import app.jannat.alinaworld.data.Objective
import app.jannat.alinaworld.game.Input
import app.jannat.alinaworld.game.WorldThemes
import app.jannat.alinaworld.pixel.PixelSprite

/** Mission briefing: level preview, goal chips and who Alina will meet. */
@Composable
fun BriefingScreen(mission: Mission) {
    val theme = WorldThemes.theme(mission.world)
    val stars = GameProgress.stars(mission.id)

    Router.Keys {
        if (Input.consumeEnter()) Router.play(mission.id)
        if (Input.consumeEscape()) Router.openMap()
    }

    Box(Modifier.fillMaxSize()) {
        Backdrop(Modifier.fillMaxSize(), theme)
        Box(Modifier.fillMaxSize().background(Palette.cream.copy(alpha = 0.4f)))
        Box(Modifier.padding(start = 48.dp, top = 32.dp)) {
            Tile(TileKind.White, 52.dp, false, width = 52.dp) { fg -> Glyph(Icons.Filled.ChevronLeft, fg, 30.dp) }
        }
        Column(
            Modifier.align(Alignment.Center).width(720.dp).card(32.dp, 24.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Preview(mission)
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                val goal = when (mission.objective) {
                    Objective.CollectN -> "×${mission.collectRequired}"
                    Objective.DefeatBoss -> "×3"
                    Objective.ReachFlag -> ""
                }
                StatChip(goal, Palette.goldSoft, Palette.goldText, 60.dp, 24.sp) {
                    Sprite(mission.goalSprite, if (mission.objective == Objective.DefeatBoss) 2f else 3f, theme = theme)
                    mission.timeLimit?.let {
                        BasicText(
                            formatTime(it.toFloat()), style = rounded(13.sp, FontWeight.ExtraBold, Palette.pinkText),
                            modifier = Modifier.background(Palette.pinkSoft, RoundedCornerShape(50)).padding(horizontal = 6.dp, vertical = 3.dp)
                        )
                    }
                }
                StatChip(formatTime(mission.parTime), Palette.sand, Palette.body, 60.dp) {
                    Glyph(Icons.Filled.Star, if (stars[1]) Palette.gold else Palette.unearned, 20.dp)
                    Glyph(Icons.Filled.Timer, Palette.body, 22.dp)
                }
                StatChip(fill = Palette.sand, height = 60.dp) {
                    Glyph(Icons.Filled.Star, if (stars[2]) Palette.gold else Palette.unearned, 20.dp)
                    Sprite(PixelSprite.Heart, 3f)
                }
                Spacer(Modifier.weight(1f))
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    for (sprite in enemySprites(mission)) {
                        Box(Modifier.size(60.dp).background(Palette.lavender, RoundedCornerShape(16.dp)), contentAlignment = Alignment.Center) {
                            Sprite(sprite, if (sprite == PixelSprite.Guardian) 3f else 3f, theme = theme)
                        }
                    }
                }
            }
            Tile(TileKind.Primary, 72.dp, true, Modifier.fillMaxWidth()) { fg ->
                Glyph(Icons.Filled.PlayArrow, fg, 34.dp)
                BasicText("Go!", style = rounded(30.sp, FontWeight.Black, fg))
            }
        }
    }
}

@Composable
private fun Preview(mission: Mission) {
    val theme = WorldThemes.theme(mission.world)
    Box(Modifier.fillMaxWidth().height(250.dp).clip(RoundedCornerShape(22.dp))) {
        Backdrop(Modifier.fillMaxSize(), theme, groundHeight = 56.dp, sunPosition = 0.8f)
        Row(Modifier.fillMaxSize().padding(bottom = 56.dp, start = 56.dp, end = 56.dp), verticalAlignment = Alignment.Bottom) {
            Sprite(PixelSprite.AlinaRun, 4f)
            Spacer(Modifier.weight(1f))
            if (mission.objective == Objective.CollectN) {
                Sprite(PixelSprite.Crystal, 5f, Modifier.padding(bottom = 80.dp))
                Spacer(Modifier.weight(1f))
            }
            val boss = mission.objective == Objective.DefeatBoss
            Sprite(if (boss) PixelSprite.Guardian else PixelSprite.Gloomling, if (boss) 4f else 4f, theme = theme)
            Spacer(Modifier.weight(1f))
            if (mission.objective == Objective.ReachFlag) Sprite(PixelSprite.Beacon, 4f)
        }
        Row(
            Modifier.padding(16.dp).background(Color.White, RoundedCornerShape(16.dp)).padding(8.dp).padding(end = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Box(Modifier.height(36.dp).background(hex(theme.grass[2]), RoundedCornerShape(10.dp)).padding(horizontal = 10.dp), contentAlignment = Alignment.Center) {
                BasicText(mission.code, style = rounded(18.sp, FontWeight.ExtraBold, Color.White))
            }
            BasicText(mission.title, style = rounded(24.sp, FontWeight.Bold))
        }
    }
}

private fun enemySprites(mission: Mission): List<PixelSprite> {
    val rows = mission.rows.joinToString("")
    val sprites = mutableListOf<PixelSprite>()
    if ('E' in rows) sprites += PixelSprite.Gloomling
    if ('E' in rows && mission.id >= 10) sprites += PixelSprite.Thornbeetle
    if (mission.enemies.any { it.kind.lowercase().startsWith("fl") }) sprites += PixelSprite.Mothwisp
    if (mission.objective == Objective.DefeatBoss) sprites += PixelSprite.Guardian
    return sprites.ifEmpty { listOf(PixelSprite.Gloomling) }
}
