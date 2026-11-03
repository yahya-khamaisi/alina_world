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
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.ui.draw.scale
import androidx.compose.runtime.remember
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.asImageBitmap
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
        val w = (world + delta).coerceIn(0, GameProgress.WORLD_COUNT - 1)
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
                    val acts = listOf(
                        Icons.Filled.WbTwilight to Palette.goldText, Icons.Filled.WbSunny to Color(0xFFC9601F),
                        Icons.Filled.NightsStay to Palette.violet, Icons.Filled.AutoAwesome to Color(0xFF4AA8E8)
                    )
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
                    BasicText("${GameProgress.crystalsRestored}/${GameProgress.WORLD_COUNT}", style = rounded(17.sp, FontWeight.ExtraBold))
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

/** The illustrated isles; each island's landmark shows what the world holds. */
@Composable
private fun IslandMap(modifier: Modifier, selectedWorld: Int) {
    val cleared = (0 until GameProgress.WORLD_COUNT).count { GameProgress.isCompleted(it * 3 + 3) }
    val unlocked = (0 until GameProgress.WORLD_COUNT).count { GameProgress.isUnlocked(it * 3 + 1) }
    val image = remember(cleared, unlocked, selectedWorld) { MapArt.bitmap(cleared, unlocked, selectedWorld).asImageBitmap() }
    val shape = RoundedCornerShape(28.dp)
    BoxWithConstraints(modifier, contentAlignment = Alignment.Center) {
        val s = minOf(maxWidth.value / MapArt.WIDTH, maxHeight.value / MapArt.HEIGHT)
        Box(
            Modifier.size((MapArt.WIDTH * s).dp, (MapArt.HEIGHT * s).dp)
                .drawBehind { drawRoundRect(Palette.edge, Offset(0f, 10.dp.toPx()), size, CornerRadius(28.dp.toPx())) }
                .clip(shape)
                .border(6.dp, Color.White, shape)
        ) {
            Canvas(Modifier.fillMaxSize()) {
                drawImage(image, dstSize = IntSize(size.width.toInt(), size.height.toInt()), filterQuality = FilterQuality.None)
            }
            MapArt.islands.forEachIndexed { w, island ->
                WorldPin(w, w == selectedWorld, (island.cx * s).dp, ((island.cy - island.rh - 26) * s).dp)
            }
            val current = MapArt.islands[selectedWorld]
            val ax by animateFloatAsState((current.cx - current.rw * 0.62f) * s, label = "alinaX")
            val ay by animateFloatAsState((current.cy - 26) * s, label = "alinaY")
            Sprite(PixelSprite.AlinaIdle, 3f, Modifier.offset((ax - 21).dp, (ay - 27).dp))
            BasicText(
                WorldThemes.ordered[selectedWorld].name, style = rounded(17.sp, FontWeight.Bold),
                modifier = Modifier
                    .offset((current.cx * s).dp - 90.dp, ((current.cy + current.rh + 22) * s).dp)
                    .width(180.dp)
                    .wrapContentWidth()
                    .background(Color.White, RoundedCornerShape(12.dp))
                    .padding(horizontal = 12.dp, vertical = 6.dp)
            )
        }
    }
}

/** World number with its stars, or a lock. */
@Composable
private fun WorldPin(world: Int, selected: Boolean, x: androidx.compose.ui.unit.Dp, y: androidx.compose.ui.unit.Dp) {
    val first = world * 3 + 1
    val unlocked = GameProgress.isUnlocked(first)
    val stars = (first..first + 2).sumOf { GameProgress.starCount(it) }
    val cleared = GameProgress.isCompleted(first + 2)
    Box(Modifier.offset(x - 50.dp, y - 16.dp).width(100.dp), contentAlignment = Alignment.Center) {
        if (unlocked) {
            Row(
                Modifier.scale(if (selected) 1.12f else 1f).height(32.dp)
                    .drawBehind {
                        val r = CornerRadius(10.dp.toPx())
                        drawRoundRect(if (selected) Palette.pinkDeep else Palette.ink.copy(alpha = 0.25f), Offset(0f, 4.dp.toPx()), size, r)
                        drawRoundRect(if (selected) Palette.pink else if (cleared) Palette.mint else Color(0xFF4AA8E8), cornerRadius = r)
                    }
                    .padding(horizontal = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                BasicText("${world + 1}", style = rounded(17.sp, FontWeight.Black, Color.White))
                Row(horizontalArrangement = Arrangement.spacedBy(1.dp)) {
                    for (i in 0 until 3) Glyph(Icons.Filled.Star, if (i < (stars + 2) / 3) Palette.gold else Color.White.copy(alpha = 0.45f), 11.dp)
                }
            }
        } else {
            Box(Modifier.size(32.dp).background(Color.White.copy(alpha = 0.9f), RoundedCornerShape(10.dp)), contentAlignment = Alignment.Center) {
                Glyph(Icons.Filled.Lock, Palette.muted, 15.dp)
            }
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
