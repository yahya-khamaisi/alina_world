package app.jannat.alinaworld.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.DeleteForever
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Grain
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.jannat.alinaworld.audio.Chiptune
import app.jannat.alinaworld.audio.SoundEffect
import app.jannat.alinaworld.data.GameProgress
import app.jannat.alinaworld.data.Settings
import app.jannat.alinaworld.game.Input
import kotlin.math.roundToInt

private class Option(val icon: ImageVector, val label: String, val kind: Kind) {
    enum class Kind { Music, Effects, AutoRun, Assist, Weather, Hints, Reset }
}

private val options = listOf(
    Option(Icons.Filled.MusicNote, "Music", Option.Kind.Music),
    Option(Icons.Filled.AutoAwesome, "Sounds", Option.Kind.Effects),
    Option(Icons.Filled.DirectionsRun, "Auto-run", Option.Kind.AutoRun),
    Option(Icons.Filled.Favorite, "Assist", Option.Kind.Assist),
    Option(Icons.Filled.Grain, "Weather", Option.Kind.Weather),
    Option(Icons.Filled.Lightbulb, "Hints", Option.Kind.Hints),
    Option(Icons.Filled.DeleteForever, "Reset", Option.Kind.Reset)
)

/** Remote-friendly settings: up and down pick a row, left and right or OK change it. */
@Composable
fun SettingsScreen(back: Route) {
    var focus by remember { mutableIntStateOf(0) }
    var version by remember { mutableIntStateOf(0) }
    var confirmReset by remember { mutableStateOf(false) }

    fun change(kind: Option.Kind, delta: Int) {
        when (kind) {
            Option.Kind.Music -> Settings.musicVolume = ((Settings.musicVolume * 10).roundToInt() + delta).coerceIn(0, 10) / 10f
            Option.Kind.Effects -> { Settings.effectsVolume = ((Settings.effectsVolume * 10).roundToInt() + delta).coerceIn(0, 10) / 10f; Chiptune.play(SoundEffect.Petal) }
            Option.Kind.AutoRun -> Settings.autoRun = !Settings.autoRun
            Option.Kind.Assist -> Settings.assistMode = !Settings.assistMode
            Option.Kind.Weather -> Settings.ambientEffects = !Settings.ambientEffects
            Option.Kind.Hints -> Settings.showHints = !Settings.showHints
            Option.Kind.Reset -> if (delta == 0) {
                if (confirmReset) { GameProgress.reset(); confirmReset = false; Chiptune.play(SoundEffect.Hurt) } else confirmReset = true
            }
        }
        version++
    }

    Router.Keys {
        if (Input.consumeEscape()) { Router.route = back; return@Keys }
        val before = focus
        if (Input.consumeUp()) focus = (focus - 1).coerceAtLeast(0)
        if (Input.consumeDown()) focus = (focus + 1).coerceAtMost(options.size - 1)
        if (focus != before) { Router.select(); confirmReset = false }
        val kind = options[focus].kind
        if (Input.consumeLeft()) change(kind, -1)
        if (Input.consumeRight()) change(kind, 1)
        if (Input.consumeEnter()) change(kind, 0)
    }

    Box(Modifier.fillMaxSize()) {
        Backdrop(Modifier.fillMaxSize())
        Box(Modifier.padding(start = 48.dp, top = 32.dp)) {
            Tile(TileKind.White, 52.dp, false, width = 52.dp) { fg -> Glyph(Icons.Filled.ChevronLeft, fg, 30.dp) }
        }
        Column(
            Modifier.align(Alignment.Center).width(560.dp).card(32.dp, 24.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            @Suppress("UNUSED_EXPRESSION") version
            options.forEachIndexed { i, option ->
                val focused = i == focus
                Row(
                    Modifier.fillMaxWidth().height(60.dp)
                        .background(if (focused) Palette.pinkSoft else Palette.sand, RoundedCornerShape(18.dp))
                        .then(if (focused) Modifier.border(3.dp, Palette.pink, RoundedCornerShape(18.dp)) else Modifier)
                        .padding(horizontal = 18.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    Glyph(option.icon, if (focused) Palette.pinkText else Palette.body, 28.dp)
                    BasicText(option.label, style = rounded(22.sp, FontWeight.Bold))
                    Spacer(Modifier.weight(1f))
                    when (option.kind) {
                        Option.Kind.Music -> Level(Settings.musicVolume)
                        Option.Kind.Effects -> Level(Settings.effectsVolume)
                        Option.Kind.AutoRun -> Switch(Settings.autoRun)
                        Option.Kind.Assist -> Switch(Settings.assistMode)
                        Option.Kind.Weather -> Switch(Settings.ambientEffects)
                        Option.Kind.Hints -> Switch(Settings.showHints)
                        Option.Kind.Reset -> if (confirmReset && focused) {
                            BasicText("OK again", style = rounded(18.sp, FontWeight.ExtraBold, Palette.pinkText))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun Level(value: Float) {
    Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.Bottom) {
        for (i in 1..10) {
            Box(
                Modifier.width(10.dp).height((10 + i * 2).dp)
                    .background(if (i <= (value * 10).roundToInt()) Palette.pink else Palette.unearned, RoundedCornerShape(3.dp))
            )
        }
    }
}

@Composable
private fun Switch(on: Boolean) {
    Box(
        Modifier.width(64.dp).height(36.dp).background(if (on) Palette.mint else Palette.unearned, CircleShape).padding(4.dp),
        contentAlignment = if (on) Alignment.CenterEnd else Alignment.CenterStart
    ) {
        Box(Modifier.size(28.dp).background(Color.White, CircleShape))
    }
}
