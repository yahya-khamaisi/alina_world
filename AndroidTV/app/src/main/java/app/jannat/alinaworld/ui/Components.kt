package app.jannat.alinaworld.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.jannat.alinaworld.game.WorldTheme
import app.jannat.alinaworld.game.WorldThemes
import app.jannat.alinaworld.pixel.PixelArt
import app.jannat.alinaworld.pixel.PixelSprite
import kotlin.math.max
import kotlin.math.roundToInt

/** Design tokens for the menus: cream and white cards, plum ink, Alina pink. Same values as the Mac app. */
object Palette {
    val ink = Color(0xFF2B2148)
    val muted = Color(0xFF6B6386)
    val body = Color(0xFF4E4668)
    val cream = Color(0xFFFFFBF4)
    val sand = Color(0xFFF6F1EA)
    val line = Color(0xFFF1EADF)
    val edge = Color(0xFFE5D3BC)
    val pink = Color(0xFFE84E8A)
    val pinkDeep = Color(0xFFB8306A)
    val pinkText = Color(0xFFC13B73)
    val pinkSoft = Color(0xFFFFEAF2)
    val lavender = Color(0xFFF4F0FF)
    val lavenderEdge = Color(0xFFDED6F7)
    val violet = Color(0xFF6B57C9)
    val gold = Color(0xFFF6C343)
    val goldSoft = Color(0xFFFFF6DE)
    val goldText = Color(0xFF8A5A00)
    val mint = Color(0xFF3DBE8B)
    val mintSoft = Color(0xFFE3F6EC)
    val mintText = Color(0xFF1F7A50)
    val skySoft = Color(0xFFE7F4FD)
    val skyText = Color(0xFF1F5F8C)
    val unearned = Color(0xFFD9D0C3)
}

fun hex(rgb: Int, alpha: Float = 1f) = Color(0xFF000000.toInt() or rgb).copy(alpha = alpha)

fun rounded(size: TextUnit, weight: FontWeight = FontWeight.Bold, color: Color = Palette.ink) =
    TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = weight, fontSize = size, color = color)

/**
 * Lays the UI out on a 1280 × 720 design canvas scaled to the TV, so sizes carried over from the Mac
 * layouts look the same on any panel.
 */
@Composable
fun DesignCanvas(content: @Composable BoxScope.() -> Unit) {
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val outer = LocalDensity.current
        val widthPx = with(outer) { maxWidth.toPx() }
        val heightPx = with(outer) { maxHeight.toPx() }
        val density = minOf(widthPx / 1280f, heightPx / 720f)
        CompositionLocalProvider(LocalDensity provides Density(density, 1f)) {
            Box(Modifier.fillMaxSize(), content = content)
        }
    }
}

/** Crisp pixel sprite: `scale` dp per art pixel, drawn with nearest filtering. */
@Composable
fun Sprite(
    sprite: PixelSprite,
    scale: Float,
    modifier: Modifier = Modifier,
    theme: WorldTheme? = null,
    overrides: Map<Char, Int> = emptyMap(),
    alpha: Float = 1f
) {
    val image = PixelArt.image(sprite, theme, overrides)
    Canvas(modifier.size((image.width * scale).dp, (image.height * scale).dp)) {
        drawImage(
            image, dstSize = IntSize(size.width.roundToInt(), size.height.roundToInt()),
            filterQuality = FilterQuality.None, alpha = alpha
        )
    }
}

fun DrawScope.sprite(sprite: PixelSprite, x: Float, y: Float, scalePx: Float, theme: WorldTheme? = null, alpha: Float = 1f) {
    val image = PixelArt.image(sprite, theme)
    drawImage(
        image, dstOffset = IntOffset(x.roundToInt(), y.roundToInt()),
        dstSize = IntSize((image.width * scalePx).roundToInt(), (image.height * scalePx).roundToInt()),
        filterQuality = FilterQuality.None, alpha = alpha
    )
}

/**
 * The shared pixel environment — banded sky, sun, clouds, two hill layers, trees and textured ground.
 * Mirrors the in-game parallax so menus and levels feel like the same place.
 */
@Composable
fun Backdrop(
    modifier: Modifier = Modifier,
    theme: WorldTheme = WorldThemes.ordered[0],
    dense: Boolean = theme.key == "grove",
    groundHeight: Dp? = null,
    sunPosition: Float = 0.62f
) {
    // Baked once per size into a bitmap, so animated screens don't redraw hundreds of sprites per frame.
    androidx.compose.foundation.layout.Spacer(modifier.drawWithCache {
        val image = androidx.compose.ui.graphics.ImageBitmap(size.width.toInt().coerceAtLeast(1), size.height.toInt().coerceAtLeast(1))
        androidx.compose.ui.graphics.drawscope.CanvasDrawScope().draw(this, layoutDirection, androidx.compose.ui.graphics.Canvas(image), size) {
            drawBackdrop(theme, dense, groundHeight, sunPosition)
        }
        onDrawBehind { drawImage(image) }
    })
}

private fun DrawScope.drawBackdrop(theme: WorldTheme, dense: Boolean, groundHeight: Dp?, sunPosition: Float) {
    run {
        val w = size.width
        val h = size.height
        val u = density
        val gh = groundHeight?.toPx() ?: max(96 * u, h * 0.16f)
        val groundTop = h - gh
        val k = minOf(1f, h / (760 * u))
        fun px(base: Float) = max(2f, (base * k).roundToInt().toFloat()) * u

        val fractions = floatArrayOf(0.21f, 0.17f, 0.145f, 0.13f)
        var top = 0f
        for (i in 0 until 5) {
            val bh = if (i < 4) groundTop * fractions[i] else groundTop - top + 2
            drawRect(hex(theme.sky[i]), Offset(0f, top), Size(w, bh + 1))
            top += bh
        }
        sprite(PixelSprite.Sun, w * sunPosition, 56 * k * u, px(8f))
        sprite(PixelSprite.Cloud, w * 0.09f, h * 0.1f, px(7f))
        sprite(PixelSprite.Cloud, w * 0.44f, h * 0.2f, px(5f))
        sprite(PixelSprite.Cloud, w * 0.67f, h * 0.08f, px(4f))
        sprite(PixelSprite.Cloud, w * 0.26f, h * 0.36f, px(3f))

        val far = px(12f)
        val near = px(14f)
        drawRect(hex(theme.hills[1]), Offset(0f, groundTop - 112 * k * u), Size(w, 112 * k * u))
        val farStep = 24 * far - 8 * u
        for (i in 0..(w / farStep).toInt() + 1) sprite(PixelSprite.HillFar, i * farStep - 60 * k * u, groundTop - 100 * k * u - 8 * far, far, theme)
        drawRect(hex(theme.grass[1]), Offset(0f, groundTop - 16 * u), Size(w, 18 * u))
        val nearStep = 34 * near
        for (i in 0..(w / nearStep).toInt() + 1) sprite(PixelSprite.HillNear, i * nearStep - 100 * k * u, groundTop + 4 * u - 8 * near, near, theme)

        val big = px(8f); val mid = px(6f); val bush = px(5f); val flower = px(4f)
        sprite(PixelSprite.Tree, w * 0.03f, groundTop - 15 * big, big, theme)
        sprite(PixelSprite.Tree, w * 0.135f, groundTop - 15 * mid, mid, theme)
        sprite(PixelSprite.Tree, w * 0.87f, groundTop - 15 * big, big, theme)
        if (dense) {
            val seven = px(7f)
            sprite(PixelSprite.Tree, w * 0.48f, groundTop - 15 * seven, seven, theme)
            sprite(PixelSprite.Tree, w * 0.79f, groundTop - 15 * mid, mid, theme)
        }
        for (f in floatArrayOf(0.33f, 0.58f, 0.75f)) sprite(PixelSprite.Bush, w * f, groundTop - 5 * bush, bush, theme)
        for (f in floatArrayOf(0.235f, 0.257f, 0.44f, 0.69f, 0.712f)) sprite(PixelSprite.Flower, w * f, groundTop - 6 * flower, flower, theme)

        drawRect(hex(theme.grass[0]), Offset(0f, groundTop), Size(w, 6 * u))
        drawRect(hex(theme.grass[1]), Offset(0f, groundTop + 6 * u), Size(w, 14 * u))
        var x = 0f
        while (x < w) {
            drawRect(hex(theme.grass[2]), Offset(x, groundTop + 20 * u), Size(16 * u, 8 * u))
            drawRect(hex(theme.grass[1]), Offset(x + 16 * u, groundTop + 20 * u), Size(8 * u, 8 * u))
            x += 24 * u
        }
        val tile = 16 * 3 * u
        var ty = groundTop + 28 * u
        while (ty < h) {
            var tx = 0f
            while (tx < w) { sprite(PixelSprite.GroundFill, tx, ty, 3 * u, theme); tx += tile }
            ty += tile
        }
    }
}

/** White card with the warm drop edge used across every menu. */
fun Modifier.card(radius: Dp = 28.dp, padding: Dp = 24.dp): Modifier = this
    .drawBehind {
        val r = CornerRadius(radius.toPx())
        drawRoundRect(Palette.ink.copy(alpha = 0.08f), Offset(0f, 16.dp.toPx()), size, r)
        drawRoundRect(Palette.edge, Offset(0f, 8.dp.toPx()), size, r)
        drawRoundRect(Color.White, cornerRadius = r)
    }
    .padding(padding)

/** Small white pill with a drop edge, used for stats over the scenery. */
@Composable
fun Pill(height: Dp = 52.dp, content: @Composable RowScope.() -> Unit) {
    Row(
        Modifier
            .height(height)
            .drawBehind {
                val r = CornerRadius(size.height / 2)
                drawRoundRect(Palette.edge, Offset(0f, 4.dp.toPx()), size, r)
                drawRoundRect(Color.White, cornerRadius = r)
            }
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        content = content
    )
}

/** Tinted chip holding an icon and a short value, e.g. a crystal and "3/5". */
@Composable
fun StatChip(
    value: String = "",
    fill: Color = Color.White,
    text: Color = Palette.ink,
    height: Dp = 48.dp,
    size: TextUnit = 20.sp,
    icon: @Composable RowScope.() -> Unit
) {
    Row(
        Modifier.height(height).background(fill, RoundedCornerShape(16.dp)).padding(horizontal = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        icon()
        if (value.isNotEmpty()) androidx.compose.foundation.text.BasicText(value, style = rounded(size, FontWeight.Bold, text))
    }
}

enum class TileKind(val fill: Color, val edge: Color, val fg: Color) {
    Primary(Palette.pink, Palette.pinkDeep, Color.White),
    Secondary(Palette.lavender, Palette.lavenderEdge, Palette.violet),
    Danger(Palette.pinkSoft, Color(0xFFF5C6D9), Palette.pinkText),
    White(Color.White, Palette.edge, Palette.ink)
}

/** Big icon tile with a drop edge; the focused one gets an ink ring and grows a touch. */
@Composable
fun Tile(
    kind: TileKind,
    size: Dp,
    focused: Boolean,
    modifier: Modifier = Modifier,
    width: Dp? = null,
    enabled: Boolean = true,
    content: @Composable RowScope.(Color) -> Unit
) {
    val edge = if (size >= 64.dp) 6.dp else 4.dp
    val shape = RoundedCornerShape(size * 0.31f)
    val grow by animateFloatAsState(if (focused) 1.06f else 1f, label = "tileFocus")
    Box(modifier.scale(grow).padding(bottom = edge)) {
        Row(
            Modifier
                .height(size)
                .then(if (width != null) Modifier.width(width) else Modifier.fillMaxWidth())
                .drawBehind {
                    val r = CornerRadius((size * 0.31f).toPx())
                    drawRoundRect(kind.edge, Offset(0f, edge.toPx()), this.size, r)
                    drawRoundRect(kind.fill, cornerRadius = r)
                }
                .then(if (focused) Modifier.border(4.dp, Palette.ink.copy(alpha = 0.85f), shape) else Modifier)
                .padding(horizontal = if (width != null && width <= size) 0.dp else 18.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterHorizontally)
        ) {
            content(if (enabled) kind.fg else kind.fg.copy(alpha = 0.4f))
        }
    }
}

@Composable
fun Glyph(icon: ImageVector, color: Color, size: Dp) {
    androidx.compose.foundation.Image(icon, null, Modifier.size(size), colorFilter = androidx.compose.ui.graphics.ColorFilter.tint(color))
}

/** Three stars in a row; earned ones are gold. */
@Composable
fun Stars(stars: BooleanArray, size: Dp = 16.dp) {
    Row(horizontalArrangement = Arrangement.spacedBy(1.dp)) {
        for (i in 0 until 3) Glyph(Icons.Filled.Star, if (stars[i]) Palette.gold else Palette.unearned, size)
    }
}

/** Remote buttons paired with a symbol for what they do, in place of a written controls list. */
@Composable
fun ControlStrip(entries: List<Pair<String, ImageVector>>) {
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        for ((key, icon) in entries) {
            Row(
                Modifier.height(42.dp).background(Color.White.copy(alpha = 0.92f), RoundedCornerShape(12.dp))
                    .padding(start = 6.dp, end = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Box(
                    Modifier.height(30.dp).widthIn(min = 30.dp).background(Palette.ink, RoundedCornerShape(8.dp)).padding(horizontal = 7.dp),
                    contentAlignment = Alignment.Center
                ) { androidx.compose.foundation.text.BasicText(key, style = rounded(13.sp, FontWeight.ExtraBold, Color.White)) }
                Glyph(icon, Palette.ink, 18.dp)
            }
        }
    }
}

/** Round code badge used for mission codes. */
@Composable
fun CodeBadge(code: String, fill: Color, size: TextUnit = 15.sp) {
    Box(Modifier.background(fill, RoundedCornerShape(10.dp)).padding(horizontal = 10.dp, vertical = 5.dp)) {
        androidx.compose.foundation.text.BasicText(code, style = rounded(size, FontWeight.ExtraBold, Color.White))
    }
}

@Composable
fun Dot(color: Color, size: Dp, ring: Color? = null) {
    Box(Modifier.size(size).background(color, CircleShape).then(if (ring != null) Modifier.border(2.dp, ring, CircleShape) else Modifier))
}

fun formatTime(seconds: Float): String {
    val total = seconds.toInt()
    return "%d:%02d".format(total / 60, total % 60)
}

