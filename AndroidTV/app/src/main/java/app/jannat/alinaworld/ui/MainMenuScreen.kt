package app.jannat.alinaworld.ui

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.BasicText
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.PowerSettingsNew
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Star
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.zIndex
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.jannat.alinaworld.data.GameProgress
import app.jannat.alinaworld.data.Missions
import app.jannat.alinaworld.game.Input
import app.jannat.alinaworld.pixel.PixelSprite

private enum class MenuItem { Play, Map, Settings, Quit }

@Composable
fun MainMenuScreen() {
    var focus by remember { mutableIntStateOf(0) }
    val bobTransition = rememberInfiniteTransition(label = "bob")
    val bob by bobTransition.animateFloat(0f, 1f, infiniteRepeatable(tween(1100), RepeatMode.Reverse), label = "bob")
    val mission = Missions.byId(GameProgress.continueMission)

    fun activate(item: MenuItem) = when (item) {
        MenuItem.Play -> Router.route = Route.Briefing(GameProgress.continueMission)
        MenuItem.Map -> Router.openMap()
        MenuItem.Settings -> Router.route = Route.Settings(Route.Menu)
        MenuItem.Quit -> Router.onExit()
    }

    Router.Keys {
        val before = focus
        if (Input.consumeUp()) focus = 0
        if (Input.consumeDown() && focus == 0) focus = 1
        if (Input.consumeLeft() && focus > 1) focus--
        if (Input.consumeRight()) focus = (focus + 1).coerceIn(1, 3)
        if (focus != before) Router.select()
        if (Input.consumeEnter()) activate(MenuItem.entries[focus])
        if (Input.consumeEscape()) Router.onExit()
    }

    Box(Modifier.fillMaxSize()) {
        Backdrop(Modifier.fillMaxSize(), sunPosition = 0.8f)
        Sprite(PixelSprite.Crystal, 6f, Modifier.offset(x = 880.dp, y = 300.dp).graphicsLayer { translationY = -16 * bob * density })
        Sprite(PixelSprite.Petal, 5f, Modifier.offset(x = 340.dp, y = 300.dp).graphicsLayer { translationY = 12 * bob * density })
        Sprite(PixelSprite.Petal, 4f, Modifier.offset(x = 900.dp, y = 370.dp).graphicsLayer { translationY = -8 * bob * density })

        Column(
            Modifier.fillMaxSize().padding(horizontal = 48.dp, vertical = 36.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.End)) {
                Pill(44.dp) {
                    Sprite(PixelSprite.Crystal, 2f)
                    BasicText("${GameProgress.crystalsRestored}/${GameProgress.WORLD_COUNT}", style = rounded(17.sp, FontWeight.ExtraBold))
                }
                Pill(44.dp) {
                    Glyph(Icons.Filled.Star, Palette.gold, 20.dp)
                    BasicText("${GameProgress.totalStars}", style = rounded(17.sp, FontWeight.ExtraBold))
                }
                Pill(44.dp) {
                    Sprite(PixelSprite.Petal, 2f)
                    BasicText("${GameProgress.totalPetals}", style = rounded(17.sp, FontWeight.ExtraBold))
                }
            }
            BasicText(
                buildAnnotatedString {
                    withStyle(SpanStyle(color = Palette.ink)) { append("Alina ") }
                    withStyle(SpanStyle(color = Palette.pink)) { append("World") }
                },
                style = rounded(88.sp, FontWeight.Black).copy(shadow = Shadow(Palette.edge, Offset(0f, 9f), 0f)),
                modifier = Modifier.padding(top = 4.dp)
            )
            Spacer(Modifier.weight(1f))

            // Alina stands on the Play button like a platform.
            Sprite(PixelSprite.AlinaIdle, 9f, Modifier.offset(y = 6.dp).zIndex(1f))
            Tile(TileKind.Primary, 84.dp, focus == 0, width = 320.dp) { fg ->
                Glyph(Icons.Filled.PlayArrow, fg, 40.dp)
                BasicText("Play", style = rounded(34.sp, FontWeight.Black, fg))
                if (mission != null) CodeBadge(mission.code, Palette.pinkText)
            }
            Spacer(Modifier.padding(top = 20.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                listOf(Icons.Filled.Map, Icons.Filled.Settings, Icons.Filled.PowerSettingsNew).forEachIndexed { i, icon ->
                    Tile(TileKind.White, 64.dp, focus == i + 1, width = 64.dp) { fg -> Glyph(icon, fg, 30.dp) }
                }
            }
            Spacer(Modifier.padding(top = 24.dp))
        }
    }
}
