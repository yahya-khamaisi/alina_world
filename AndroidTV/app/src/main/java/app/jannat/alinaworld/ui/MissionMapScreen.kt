package app.jannat.alinaworld.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
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
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.NightsStay
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material.icons.filled.WbTwilight
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.jannat.alinaworld.data.GameProgress
import app.jannat.alinaworld.data.Mission
import app.jannat.alinaworld.data.Missions
import app.jannat.alinaworld.game.Input
import app.jannat.alinaworld.game.WorldThemes
import app.jannat.alinaworld.pixel.PixelSprite

/** Node centers and islands in an 832 × 600 design space, scaled to the map card. */
private val nodes = listOf(102f to 500f, 252f to 420f, 422f to 480f, 572f to 380f, 732f to 280f, 592f to 170f, 412f to 200f, 252f to 100f, 452f to 40f)
private val islands = listOf(
    floatArrayOf(10f, 400f, 340f, 200f) to 0x7FD06B,
    floatArrayOf(330f, 380f, 300f, 210f) to 0x5DBB7A,
    floatArrayOf(500f, 250f, 290f, 220f) to 0xC9A27E,
    floatArrayOf(190f, 90f, 470f, 200f) to 0x9C86C9,
    floatArrayOf(360f, -20f, 200f, 120f) to 0x6E64A3
)

private fun firstPlayable(world: Int): Int {
    val ids = (world * 3 + 1)..(world * 3 + 3)
    val target = ids.firstOrNull { GameProgress.isUnlocked(it) && !GameProgress.isCompleted(it) }
        ?: ids.lastOrNull { GameProgress.isUnlocked(it) } ?: ids.first
    return target - 1
}

@Composable
fun MissionMapScreen() {
    val index = Router.mapIndex
    val world = index / 3
    val act = world / 3
    val selected = Missions.byId(index + 1)

    fun moveWorld(delta: Int) {
        val w = (world + delta).coerceIn(0, 8)
        if (GameProgress.isUnlocked(w * 3 + 1) && w != world) { Router.mapIndex = firstPlayable(w); Router.select() }
    }

    fun moveMission(delta: Int) {
        val next = (index + delta).coerceIn(0, Missions.all.size - 1)
        if (GameProgress.isUnlocked(next + 1) && next != index) { Router.mapIndex = next; Router.select() }
    }

    Router.Keys {
        if (Input.consumeEscape()) { Router.route = Route.Menu; return@Keys }
        if (Input.consumeLeft()) moveWorld(-1)
        if (Input.consumeRight()) moveWorld(1)
        if (Input.consumeUp()) moveMission(-1)
        if (Input.consumeDown()) moveMission(1)
        if (Input.consumeEnter() && selected != null && GameProgress.isUnlocked(selected.id)) Router.route = Route.Briefing(selected.id)
    }

    Box(Modifier.fillMaxSize()) {
        Backdrop(Modifier.fillMaxSize())
        Column(Modifier.fillMaxSize().padding(horizontal = 48.dp, vertical = 32.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Tile(TileKind.White, 52.dp, false, width = 52.dp) { fg -> Glyph(Icons.Filled.ChevronLeft, fg, 30.dp) }
                Row(
                    Modifier.drawBehind {
                        drawRoundRect(Palette.edge, Offset(0f, 4.dp.toPx()), size, CornerRadius(16.dp.toPx()))
                        drawRoundRect(Color.White, cornerRadius = CornerRadius(16.dp.toPx()))
                    }.padding(4.dp),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    val acts = listOf(Icons.Filled.WbTwilight to Palette.goldText, Icons.Filled.WbSunny to Color(0xFFC9601F), Icons.Filled.NightsStay to Palette.violet)
                    acts.forEachIndexed { i, (icon, tint) ->
                        val unlocked = GameProgress.isUnlocked(i * 9 + 1)
                        Box(
                            Modifier.size(56.dp, 44.dp).background(if (act == i) Palette.pink else Color.Transparent, RoundedCornerShape(12.dp)),
                            contentAlignment = Alignment.Center
                        ) {
                            Glyph(if (unlocked) icon else Icons.Filled.Lock, if (act == i) Color.White else if (unlocked) tint else Palette.muted, 24.dp)
                        }
                    }
                }
                Spacer(Modifier.weight(1f))
                Pill {
                    Sprite(PixelSprite.Crystal, 2f)
                    BasicText("${GameProgress.crystalsRestored}/9", style = rounded(17.sp, FontWeight.ExtraBold))
                }
                Pill {
                    Glyph(Icons.Filled.Star, Palette.gold, 20.dp)
                    BasicText("${GameProgress.totalStars}", style = rounded(17.sp, FontWeight.ExtraBold))
                }
            }
            Row(Modifier.fillMaxSize(), horizontalArrangement = Arrangement.spacedBy(24.dp)) {
                IslandMap(Modifier.weight(1f).fillMaxHeight(), world)
                SidePanel(world, index)
            }
        }
    }
}

@Composable
private fun IslandMap(modifier: Modifier, selectedWorld: Int) {
    val shape = RoundedCornerShape(28.dp)
    BoxWithConstraints(
        modifier
            .drawBehind { drawRoundRect(Palette.edge, Offset(0f, 10.dp.toPx()), size, CornerRadius(28.dp.toPx())) }
            .clip(shape)
            .border(6.dp, Color.White, shape)
    ) {
        val sx = maxWidth.value / 832f
        val sy = maxHeight.value / 600f
        Canvas(Modifier.fillMaxSize()) {
            val u = density
            drawRect(Color(0xFF8ED2F2))
            val cell = 32 * u
            for (row in 0..(size.height / cell).toInt()) for (col in 0..(size.width / cell).toInt()) {
                if ((row + col) % 2 == 0) drawRect(Color(0xFF84CBEE), Offset(col * cell, row * cell), Size(cell, cell))
            }
            for ((r, color) in islands) {
                val w = r[2] * sx * u; val h = r[3] * sy * u
                val corner = CornerRadius(minOf(w, h) * 0.44f)
                drawRoundRect(hex(color), Offset(r[0] * sx * u, r[1] * sy * u), Size(w, h), corner)
                drawRoundRect(Color(0xFFF6E3B4), Offset(r[0] * sx * u + 5 * u, r[1] * sy * u + 5 * u), Size(w - 10 * u, h - 10 * u), corner, style = Stroke(10 * u))
            }
            for (i in 0 until nodes.size - 1) {
                drawLine(
                    Color.White, Offset(nodes[i].first * sx * u, nodes[i].second * sy * u),
                    Offset(nodes[i + 1].first * sx * u, nodes[i + 1].second * sy * u), 6 * u,
                    StrokeCap.Round, PathEffect.dashPathEffect(floatArrayOf(2 * u, 14 * u))
                )
            }
        }
        for (w in 0 until 9) WorldNode(w, w == selectedWorld, (nodes[w].first * sx).dp, (nodes[w].second * sy + 24).dp)
        val cx by animateFloatAsState(nodes[selectedWorld].first * sx - 48, label = "alinaX")
        val cy by animateFloatAsState(nodes[selectedWorld].second * sy - 6, label = "alinaY")
        Sprite(PixelSprite.AlinaIdle, 3f, Modifier.offset((cx - 21).dp, (cy - 27).dp))
    }
}

@Composable
private fun WorldNode(world: Int, selected: Boolean, x: androidx.compose.ui.unit.Dp, y: androidx.compose.ui.unit.Dp) {
    val theme = WorldThemes.ordered[world]
    val first = world * 3 + 1
    val unlocked = GameProgress.isUnlocked(first)
    val stars = (first..first + 2).sumOf { GameProgress.starCount(it) }
    Column(Modifier.offset(x - 37.dp, y - 37.dp).width(74.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            Modifier.size(74.dp).then(if (selected) Modifier.border(4.dp, Palette.pink, CircleShape) else Modifier).padding(7.dp)
                .drawBehind { drawCircle(if (selected) Palette.pinkDeep else Palette.ink.copy(alpha = 0.2f), center = center.copy(y = center.y + 5.dp.toPx())) }
                .background(if (unlocked) hex(theme.grass[1]) else Color(0xFFB9AFA3), CircleShape)
                .border(5.dp, Color.White, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            if (unlocked) BasicText("${world + 1}", style = rounded(22.sp, FontWeight.Black, Color.White))
            else Glyph(Icons.Filled.Lock, Color.White, 20.dp)
        }
        Row(
            Modifier.padding(top = 2.dp).alpha(if (unlocked) 1f else 0f).background(Color.White, CircleShape).padding(horizontal = 8.dp, vertical = 3.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(3.dp)
        ) {
            Glyph(Icons.Filled.Star, Palette.gold, 14.dp)
            BasicText("$stars", style = rounded(12.sp, FontWeight.ExtraBold, Palette.goldText))
        }
    }
}

@Composable
private fun SidePanel(world: Int, index: Int) {
    val theme = WorldThemes.ordered[world]
    val missions = Missions.all.filter { WorldThemes.index(it.world) == world }
    val selected = Missions.byId(index + 1)
    Column(Modifier.width(328.dp).fillMaxHeight().card(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Box(Modifier.fillMaxWidth().height(130.dp).clip(RoundedCornerShape(18.dp)), contentAlignment = Alignment.BottomStart) {
            Backdrop(Modifier.fillMaxSize(), theme, groundHeight = 26.dp, sunPosition = 0.72f)
            BasicText(
                theme.name, style = rounded(19.sp, FontWeight.Bold),
                modifier = Modifier.padding(12.dp).background(Color.White, RoundedCornerShape(12.dp)).padding(horizontal = 12.dp, vertical = 6.dp)
            )
        }
        for (m in missions) MissionRow(m, m.id == index + 1)
        Spacer(Modifier.weight(1f))
        Tile(TileKind.Primary, 64.dp, true, Modifier.fillMaxWidth()) { fg ->
            Glyph(Icons.Filled.PlayArrow, fg, 32.dp)
            BasicText(selected?.code ?: "", style = rounded(26.sp, FontWeight.Black, fg))
        }
    }
}

@Composable
private fun MissionRow(mission: Mission, selected: Boolean) {
    val unlocked = GameProgress.isUnlocked(mission.id)
    val stars = GameProgress.stars(mission.id)
    Row(
        Modifier.fillMaxWidth().height(60.dp)
            .background(if (selected) Palette.pinkSoft else Palette.sand, RoundedCornerShape(18.dp))
            .then(if (selected) Modifier.border(3.dp, Palette.pink, RoundedCornerShape(18.dp)) else Modifier)
            .padding(horizontal = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            Modifier.size(48.dp, 40.dp).background(
                if (!unlocked) Color(0xFFE4DDD2) else if (selected) Palette.pink else if (stars[0]) Palette.mint else Color(0xFF4AA8E8),
                RoundedCornerShape(10.dp)
            ),
            contentAlignment = Alignment.Center
        ) {
            if (unlocked) BasicText(mission.code, style = rounded(15.sp, FontWeight.ExtraBold, Color.White))
            else Glyph(Icons.Filled.Lock, Palette.muted, 16.dp)
        }
        Box(Modifier.size(40.dp).background(Color.White, RoundedCornerShape(10.dp)).alpha(if (unlocked) 1f else 0.45f), contentAlignment = Alignment.Center) {
            Sprite(mission.goalSprite, if (mission.goalSprite == PixelSprite.Beacon) 2f else 2f)
        }
        Spacer(Modifier.weight(1f))
        if (unlocked) Stars(stars, 16.dp)
    }
}
