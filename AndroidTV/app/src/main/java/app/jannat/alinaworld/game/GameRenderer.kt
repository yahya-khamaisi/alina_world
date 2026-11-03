package app.jannat.alinaworld.game

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.RectF
import android.graphics.Typeface
import app.jannat.alinaworld.pixel.PixelArt
import app.jannat.alinaworld.pixel.PixelSprite
import kotlin.math.floor
import kotlin.math.sin

/**
 * Draws the level the way the SpriteKit scene layered it: banded sky, sun, drifting clouds, two parallax hill
 * layers, pit shade, scenery, tiles, items, enemies, Alina, weather, particles and score pops.
 */
class GameRenderer(private val world: GameWorld) {
    private val theme = world.level.theme
    private val map = world.map
    private val paint = Paint().apply { isFilterBitmap = false; isAntiAlias = false; isDither = false }
    private val fill = Paint().apply { isAntiAlias = false }
    private val round = Paint().apply { isAntiAlias = true }
    private val text = Paint().apply {
        isAntiAlias = true; typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD); textAlign = Paint.Align.CENTER
    }
    private val whiteTint = PorterDuffColorFilter(Color.argb(204, 255, 255, 255), PorterDuff.Mode.SRC_ATOP)
    private val dst = RectF()
    private val path = Path()

    private class Placed(val sprite: PixelSprite, val x: Float, val y: Float, val scale: Float, val alpha: Float = 1f)
    private class Layer(val factor: Float, val items: List<Placed>, val baseColor: Int?, val baseY: Float, val baseWidth: Float)

    private val layers: List<Layer>
    private val bloomOverrides = mapOf('K' to 0xF6C343, 'D' to 0xD9901A)

    // Camera, refreshed every frame.
    private var s = 1f
    private var camL = 0f
    private var camT = 0f
    private var visW = 0f

    init {
        val mapWidth = map.worldWidth
        val groundTop = world.level.groundTop
        val viewSpan = 1800f
        val rng = SeededRNG(mapWidth.toLong().toULong() + 7uL)

        val clouds = mutableListOf<Placed>()
        var x = 40f
        while (x < mapWidth * 0.08f + viewSpan + 2400) {
            val scale = listOf(3f, 4f, 5f, 6f)[(rng.next() % 4uL).toInt()]
            clouds += Placed(PixelSprite.Cloud, x, groundTop + 300 + (rng.next() % 170uL).toInt(), scale, if (scale < 4) 0.8f else 1f)
            x += 220 + (rng.next() % 220uL).toInt()
        }
        val far = hills(PixelSprite.HillFar, 10f, 200f, groundTop + 40, mapWidth * 0.22f + viewSpan, rng)
        val near = hills(PixelSprite.HillNear, 9f, 250f, groundTop - 4, mapWidth * 0.45f + viewSpan, rng)
        layers = listOf(
            Layer(0.08f, clouds, null, 0f, 0f),
            Layer(0.22f, far, theme.hills[1], groundTop + 40, mapWidth * 0.22f + viewSpan),
            Layer(0.45f, near, theme.grass[1], groundTop - 4, mapWidth * 0.45f + viewSpan)
        )
    }

    private fun hills(sprite: PixelSprite, scale: Float, spacing: Float, baseY: Float, span: Float, rng: SeededRNG): List<Placed> {
        val out = mutableListOf<Placed>()
        var x = -120f
        while (x < span + 200) {
            out += Placed(sprite, x, baseY, scale)
            x += spacing + (rng.next() % (spacing / 2).toInt().toULong()).toInt()
        }
        return out
    }

    private fun sx(wx: Float) = (wx - camL) * s
    private fun sy(wy: Float) = (camT - wy) * s

    fun draw(canvas: Canvas, width: Int, height: Int) {
        s = height / GameConstants.VIEW_HEIGHT
        visW = width / s
        world.viewWidth = visW
        camL = world.cameraX - visW / 2
        camT = world.cameraY + GameConstants.VIEW_HEIGHT / 2
        val time = world.elapsed + world.cloudDrift / 4

        drawSky(canvas, width, height)
        drawParallax(canvas)

        // Shadowed floor seen through pits, so gaps read as drops rather than more grass.
        rect(canvas, -2000f, world.level.groundTop - 24 - 900, map.worldWidth + 4000, 900f, theme.leaves[1])

        for (sc in world.level.scenery) {
            val w = PixelArt.width(sc.sprite) * sc.scale
            val h = PixelArt.height(sc.sprite) * sc.scale
            if (sc.x + w / 2 < camL || sc.x - w / 2 > camL + visW) continue
            blit(canvas, PixelArt.bitmap(sc.sprite, theme), sc.x, sc.y + h / 2, w, h)
        }

        drawTiles(canvas)
        drawBeacon(canvas, time)
        for (h in world.level.hazards) if (visible(h[0], 32f)) blit(canvas, PixelArt.bitmap(PixelSprite.Thorns, theme), h[0], h[1], 32f, 32f)
        for (p in world.level.platforms) if (visible(p.x, 128f)) blit(canvas, PixelArt.bitmap(PixelSprite.CloudPad), p.x, p.y, 128f, 20f)
        drawItems(canvas, time)
        drawEnemies(canvas)
        drawPlayer(canvas, time)

        for (p in world.ambientParticles) particle(canvas, p)
        for (p in world.particles) particle(canvas, p)
        drawPops(canvas)
    }

    private fun visible(x: Float, w: Float) = x + w > camL && x - w < camL + visW

    private fun drawSky(canvas: Canvas, width: Int, height: Int) {
        val fractions = floatArrayOf(0.2f, 0.16f, 0.14f, 0.13f)
        var top = 0f
        for (i in 0 until 5) {
            val h = if (i < 4) height * fractions[i] else height - top
            fill.color = 0xFF000000.toInt() or theme.sky[i]
            canvas.drawRect(0f, floor(top), width.toFloat(), floor(top + h) + 1, fill)
            top += h
        }
        val sun = PixelArt.bitmap(PixelSprite.Sun)
        val cx = (visW - 300) * s
        val cy = 150 * s
        dst.set(cx - 42 * s, cy - 42 * s, cx + 42 * s, cy + 42 * s)
        paint.alpha = 255
        canvas.drawBitmap(sun, null, dst, paint)
    }

    private fun drawParallax(canvas: Canvas) {
        for ((index, layer) in layers.withIndex()) {
            var offset = camL * (1 - layer.factor)
            if (index == 0) offset -= world.cloudDrift
            layer.baseColor?.let { rect(canvas, offset - 200, layer.baseY + 1 - 800, layer.baseWidth + 400, 800f, it) }
            for (p in layer.items) {
                val bmp = PixelArt.bitmap(p.sprite, theme)
                val w = bmp.width * p.scale
                val h = bmp.height * p.scale
                val x = offset + p.x
                if (x + w < camL || x - w > camL + visW) continue
                if (p.sprite == PixelSprite.Cloud) {
                    blit(canvas, bmp, x, p.y, w, h, alpha = p.alpha)
                } else {
                    blit(canvas, bmp, x + w / 2, p.y + h / 2, w, h)
                }
            }
        }
    }

    /**
     * Terrain is baked into 16-column chunk bitmaps at art resolution (16 px per tile) and drawn with nearest
     * filtering, so a frame costs a few bitmap draws instead of hundreds. Bumping blocks are drawn on their own.
     */
    private val chunkCols = 16
    private val chunks = arrayOfNulls<Bitmap>((map.width + chunkCols - 1) / chunkCols)
    private val chunkDirty = BooleanArray(chunks.size) { true }
    private val chunkCanvas = Canvas()
    private val art = Paint().apply { isFilterBitmap = false; isAntiAlias = false }
    private val artRect = RectF()

    private fun drawTiles(canvas: Canvas) {
        for (i in world.tileChanges) chunkDirty[(i % map.width) / chunkCols] = true
        world.tileChanges.clear()

        val t = GameConstants.TILE
        val first = (camL / t).toInt().coerceAtLeast(0) / chunkCols
        val last = (((camL + visW) / t).toInt() / chunkCols).coerceAtMost(chunks.size - 1)
        paint.alpha = 255
        for (c in first..last) {
            if (chunkDirty[c] || chunks[c] == null) bakeChunk(c)
            val x0 = c * chunkCols * t
            dst.set(Math.round(sx(x0)).toFloat(), Math.round(sy(map.height * t)).toFloat(),
                Math.round(sx(x0 + chunkCols * t)).toFloat(), Math.round(sy(0f)).toFloat())
            canvas.drawBitmap(chunks[c]!!, null, dst, paint)
        }
        for (col in first * chunkCols..minOf(map.width - 1, (last + 1) * chunkCols - 1)) for (row in 0 until map.height) {
            val block = world.level.blocks[row * map.width + col] ?: continue
            if (block.bumpT < 0) continue
            val x = map.tileX(col)
            val by = map.tileY(row) + block.bumpOffset
            dst.set(Math.round(sx(x)).toFloat(), Math.round(sy(by + t)).toFloat(), Math.round(sx(x + t)).toFloat(), Math.round(sy(by)).toFloat())
            canvas.drawBitmap(PixelArt.bitmap(block.sprite, theme), null, dst, paint)
        }
    }

    private fun bakeChunk(c: Int) {
        val px = 16
        val bitmap = chunks[c] ?: Bitmap.createBitmap(chunkCols * px, map.height * px, Bitmap.Config.ARGB_8888).also { chunks[c] = it }
        bitmap.eraseColor(Color.TRANSPARENT)
        chunkCanvas.setBitmap(bitmap)
        for (lc in 0 until chunkCols) {
            val col = c * chunkCols + lc
            if (col >= map.width) break
            for (row in 0 until map.height) {
                val left = (lc * px).toFloat()
                val top = (row * px).toFloat()
                val block = world.level.blocks[row * map.width + col]
                if (block != null) {
                    if (block.bumpT >= 0) continue
                    artRect.set(left, top, left + px, top + px)
                    chunkCanvas.drawBitmap(PixelArt.bitmap(block.sprite, theme), null, artRect, art)
                    continue
                }
                when (val kind = map.kind(col, row)) {
                    Tile.Platform -> {
                        artRect.set(left, top, left + px, top + 6)
                        chunkCanvas.drawBitmap(PixelArt.bitmap(PixelSprite.LeafPad, theme), null, artRect, art)
                    }
                    Tile.SlopeUpRight, Tile.SlopeUpLeft, Tile.SlopeDownRight, Tile.SlopeDownLeft -> bakeSlope(kind, left, top, px.toFloat())
                    else -> Unit
                }
            }
        }
        chunkCanvas.setBitmap(null)
        chunkDirty[c] = false
    }

    private fun bakeSlope(kind: Tile, left: Float, top: Float, size: Float) {
        val right = left + size
        val bottom = top + size
        path.reset()
        when (kind) {
            Tile.SlopeUpRight -> { path.moveTo(left, bottom); path.lineTo(right, top); path.lineTo(right, bottom) }
            Tile.SlopeUpLeft -> { path.moveTo(right, bottom); path.lineTo(left, top); path.lineTo(left, bottom) }
            Tile.SlopeDownRight -> { path.moveTo(left, top); path.lineTo(right, bottom); path.lineTo(left, bottom) }
            else -> { path.moveTo(right, top); path.lineTo(left, bottom); path.lineTo(right, bottom) }
        }
        path.close()
        art.color = 0xFF000000.toInt() or theme.dirt[0]
        art.style = Paint.Style.FILL
        chunkCanvas.drawPath(path, art)
        art.color = 0xFF000000.toInt() or theme.grass[1]
        art.style = Paint.Style.STROKE
        art.strokeWidth = 2f
        chunkCanvas.drawPath(path, art)
        art.style = Paint.Style.FILL
    }

    private fun drawBeacon(canvas: Canvas, time: Float) {
        val flag = world.level.flag ?: return
        if (!visible(flag[0], 64f)) return
        val pulse = 1.025f + 0.125f * sin(time * Math.PI.toFloat() / 0.8f)
        circle(canvas, flag[0], flag[1] + 46, 26 * pulse, 0xFFE98A, 0.35f)
        blit(canvas, PixelArt.bitmap(PixelSprite.Beacon), flag[0], flag[1] - 16 + 32, 32f, 64f)
    }

    private fun drawItems(canvas: Canvas, time: Float) {
        for (item in world.level.items) {
            if (!visible(item.x, 32f)) continue
            val sprite = when (item.kind) {
                ItemKind.Coin -> if ((item.age / 0.22f).toInt() % 2 == 0) PixelSprite.Petal else PixelSprite.PetalTurn
                ItemKind.Crystal -> PixelSprite.Crystal
                ItemKind.Sunbloom -> PixelSprite.Sunbloom
                ItemKind.Ribbon -> PixelSprite.Ribbon
            }
            if (item.kind == ItemKind.Crystal) {
                val glow = 0.7f + 0.3f * sin(time * Math.PI.toFloat() / 0.6f)
                circle(canvas, item.x, item.y, 20 * item.scale, 0xFFE98A, 0.35f * glow * item.alpha)
            }
            val bmp = PixelArt.bitmap(sprite, theme)
            blit(canvas, bmp, item.x, item.y, bmp.width * 3 * item.scale, bmp.height * 3 * item.scale, alpha = item.alpha)
        }
    }

    private fun drawEnemies(canvas: Canvas) {
        for (e in world.level.enemies) {
            if (e.gone || !visible(e.x, 64f)) continue
            val frame = e.frames[if (e.frames.size > 1) (e.age / e.frameTime).toInt() % e.frames.size else 0]
            val bmp = PixelArt.bitmap(frame, theme)
            val w = bmp.width * 3f
            val h = bmp.height * 3f
            var scaleY = 1f
            var scale = 1f
            var y = e.y
            var alpha = 1f
            if (e.frames.size == 1) scaleY = 0.97f + 0.03f * sin(e.age * Math.PI.toFloat() / 0.3f)
            val f = e.flashT
            if (f >= 0) scale = if (f < 0.05f) 1f else if (f < 0.11f) 1 - 0.15f * (f - 0.05f) / 0.06f else (0.85f + 0.15f * ((f - 0.11f) / 0.08f).coerceAtMost(1f))
            if (e.dyingT >= 0) {
                val p = (e.dyingT / 0.12f).coerceAtMost(1f)
                scaleY = 1 - 0.7f * p
                y -= 8 * p
                alpha = 1 - ((e.dyingT - 0.12f) / 0.15f).coerceIn(0f, 1f)
            }
            val tint = f in 0f..0.19f
            blit(canvas, bmp, e.x, y, w, h, flipX = e.direction > 0, scaleX = scale, scaleY = scaleY * scale, alpha = alpha, white = tint)
        }
    }

    private fun drawPlayer(canvas: Canvas, time: Float) {
        val p = world.player
        if (p.alpha <= 0.01f) return
        val alpha = p.alpha
        canvas.save()
        canvas.translate(sx(p.x), sy(p.y + 4 + world.playerLift))
        canvas.rotate(-Math.toDegrees(p.rotation.toDouble()).toFloat())
        val root = p.rootScale.value * s
        canvas.scale(if (p.facingRight) root else -root, root)

        if (p.bloom) {
            val pulse = 1f + 0.1f * sin(time * Math.PI.toFloat() / 0.5f)
            round.color = 0xFFE98A or (((0.3f * alpha) * 255).toInt() shl 24)
            canvas.drawCircle(0f, 0f, 24 * pulse, round)
        }
        paint.alpha = (alpha * 255).toInt()
        if (p.hasRibbon) {
            val (rx, ry) = if (p.gliding) -12f to 10f else -10f to 2f
            canvas.save()
            canvas.translate(rx, -ry)
            canvas.rotate(-Math.toDegrees(p.ribbonRotation.toDouble()).toFloat())
            dst.set(-10f, -8f, 10f, 8f)
            canvas.drawBitmap(PixelArt.bitmap(PixelSprite.Ribbon), null, dst, paint)
            canvas.restore()
        }
        val body = PixelArt.bitmap(p.sprite, overrides = if (p.bloom) bloomOverrides else emptyMap())
        val hy = 18 * p.bodyScaleY.value
        dst.set(-14f, -hy, 14f, hy)
        canvas.drawBitmap(body, null, dst, paint)
        canvas.restore()
    }

    private fun drawPops(canvas: Canvas) {
        text.textSize = 16 * s
        for (pop in world.pops) {
            val rise = 34 * (pop.t / 0.6f).coerceAtMost(1f)
            val alpha = if (pop.t < 0.35f) 1f else (1 - (pop.t - 0.35f) / 0.25f).coerceAtLeast(0f)
            val cx = sx(pop.x)
            val cy = sy(pop.y + rise)
            val w = text.measureText(pop.text) + 14 * s
            round.color = Color.argb((alpha * 255).toInt(), 255, 255, 255)
            dst.set(cx - w / 2, cy - 11 * s, cx + w / 2, cy + 11 * s)
            canvas.drawRoundRect(dst, 7 * s, 7 * s, round)
            text.color = pop.color or ((alpha * 255).toInt() shl 24)
            canvas.drawText(pop.text, cx, cy - (text.descent() + text.ascent()) / 2, text)
        }
    }

    private fun particle(canvas: Canvas, p: Particle) {
        if (p.x < camL - 20 || p.x > camL + visW + 20) return
        fill.color = p.color or ((p.alpha.coerceIn(0f, 1f) * 255).toInt() shl 24)
        canvas.drawRect(sx(p.x - p.w / 2), sy(p.y + p.h / 2), sx(p.x + p.w / 2), sy(p.y - p.h / 2), fill)
    }

    private fun rect(canvas: Canvas, x: Float, y: Float, w: Float, h: Float, color: Int) {
        val left = sx(x).coerceAtLeast(-10f)
        val right = sx(x + w)
        if (right < 0 || left > visW * s) return
        fill.color = 0xFF000000.toInt() or color
        canvas.drawRect(left, sy(y + h).coerceAtLeast(-10f), right, sy(y), fill)
    }

    private fun circle(canvas: Canvas, x: Float, y: Float, r: Float, color: Int, alpha: Float) {
        round.color = color or ((alpha.coerceIn(0f, 1f) * 255).toInt() shl 24)
        canvas.drawCircle(sx(x), sy(y), r * s, round)
    }

    /** Sprite centered on a world point, scaled from that center. */
    private fun blit(
        canvas: Canvas, bmp: Bitmap, cx: Float, cy: Float, w: Float, h: Float,
        flipX: Boolean = false, scaleX: Float = 1f, scaleY: Float = 1f, alpha: Float = 1f, white: Boolean = false
    ) {
        paint.alpha = (alpha.coerceIn(0f, 1f) * 255).toInt()
        paint.colorFilter = if (white) whiteTint else null
        val hw = w / 2 * scaleX * s
        val hh = h / 2 * scaleY * s
        val x = sx(cx)
        val y = sy(cy)
        if (flipX) {
            canvas.save()
            canvas.scale(-1f, 1f, x, y)
        }
        dst.set(x - hw, y - hh, x + hw, y + hh)
        canvas.drawBitmap(bmp, null, dst, paint)
        if (flipX) canvas.restore()
        paint.colorFilter = null
    }
}
