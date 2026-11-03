package app.jannat.alinaworld.ui

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import app.jannat.alinaworld.game.SeededRNG
import kotlin.math.hypot
import kotlin.math.roundToInt
import kotlin.math.sqrt

/**
 * The illustrated Lumen Isles, shared with the Mac app's MapArt: one pixel island per world with a landmark
 * showing what's there, joined by a stepping-stone trail that turns gold as worlds are cleared.
 * Drawn in a 900 × 620 design space.
 */
object MapArt {
    const val WIDTH = 900f
    const val HEIGHT = 620f

    class Island(val key: String, val top: Int, val cliff: Int, val cx: Float, val cy: Float, val rw: Float, val rh: Float) {
        val floating get() = key == "starfall"
    }

    val islands = listOf(
        Island("meadow", 0x7FD06B, 0xB98A55, 105f, 530f, 84f, 34f),
        Island("brook", 0x6CCB84, 0xA08A6A, 270f, 455f, 80f, 32f),
        Island("grove", 0x4FAE5A, 0x8E6440, 440f, 535f, 84f, 34f),
        Island("cavern", 0xE3AE88, 0x9C5B3B, 610f, 470f, 82f, 32f),
        Island("ridge", 0xD9C08A, 0x956643, 790f, 525f, 84f, 34f),
        Island("marsh", 0x8CC79A, 0x6E6754, 805f, 345f, 80f, 32f),
        Island("spire", 0xB9A6EC, 0x7C6B98, 625f, 300f, 82f, 34f),
        Island("storm", 0x9DB2CC, 0x646A7C, 440f, 345f, 80f, 32f),
        Island("throne", 0xE8A6C8, 0x5E4660, 255f, 290f, 84f, 34f),
        Island("frost", 0xE8F4FF, 0x8FA0C0, 100f, 150f, 80f, 32f),
        Island("coral", 0xF2E3C0, 0xD9A86C, 340f, 125f, 82f, 32f),
        Island("starfall", 0xFFF6DE, 0xC3B1F0, 620f, 105f, 84f, 30f)
    )

    private val palette = mapOf(
        'o' to 0x3A2230, 'g' to 0x76CF63, 'i' to 0xA6E37E, 'x' to 0x3E9147, 'v' to 0x55B85C, 'V' to 0x2F8A45,
        't' to 0x6B4A30, 'T' to 0x8B6542, 'F' to 0xFF8DBE, 'Y' to 0xF6C343, 'y' to 0xFFE98A, 'O' to 0xFFFFFF,
        'w' to 0x5FB4EE, 'c' to 0xDCEEFF, 'r' to 0x8A8F9C, 'R' to 0x5E6270, 'e' to 0xFFB347, 'E' to 0xE0662E,
        'k' to 0x2A2238, 'q' to 0xC9845A, 'Q' to 0x9C5B3B, 'z' to 0xE8B98C, 'm' to 0x79B87A, 'M' to 0x4A855A,
        'n' to 0xB9D9C9, 'p' to 0xC3B1F0, 'P' to 0x8E72D6, 'L' to 0x5E47A6, 'l' to 0xECE6FB, 's' to 0x7F8AA6,
        'S' to 0x4C5672, 'h' to 0xE8A6C8, 'H' to 0xC77AA5, 'K' to 0x8E4C79, 'a' to 0xE8F4FF, 'A' to 0xA9C9E8,
        'b' to 0x7FA7CF, 'f' to 0xFF7E6B, 'j' to 0xFFB0A0, 'u' to 0xF2E3C0, 'U' to 0xD9C29A, 'd' to 0x2F7F8F
    )

    /** What each world is about, drawn on its island. */
    private val landmarks: Map<String, List<String>> = mapOf(
        "meadow" to listOf(
            "........VVV...........",
            ".......VvivV..........",
            "......VvvvvvV.........",
            "......VvvvvVV.........",
            ".......VVtVV..........",
            ".F.......t.......F.F..",
            "FYF......t......FYFYF.",
            ".x...F...t...F...x.x..",
            ".x..FYF..t..FYF..x.x.."
        ),
        "brook" to listOf(
            ".....rrrrrr.........",
            "....rRrrrrRr........",
            "...rRrwwwrrRr.......",
            "...rRrwOwrrRr.......",
            "...RRrwwwrRRR.......",
            "......wOw.....VV....",
            "......www....VvvV...",
            ".....wwOww...VvvV...",
            "....TTTTTTT...Vt....",
            "....T.www.T....t...."
        ),
        "grove" to listOf(
            "..VV.......VVV.......",
            ".VvvV.....VvivV..VV..",
            "VvivvV...VvvvvvVVvvV.",
            "VvvvvV..VvvvvvvvVvivV",
            ".VvvV...VvvvvvvV.VvV.",
            "..tt.....VVvvVV...t..",
            "..tt.......tt.....t..",
            "..tt..y....tt..y..t.."
        ),
        "cavern" to listOf(
            ".....e..........e.....",
            "........qqqqqq........",
            "......qqzzzzzqqq..e...",
            "....qqzzqqqqqzzqq.....",
            "...qzzqqkkkkkqqzqq....",
            "..qqzqqkkkkkkkqqzqq...",
            ".qqqqqkkkEkkkkkqqqqq..",
            "QQQQQQkkEeEkkkkQQQQQQ."
        ),
        "ridge" to listOf(
            "..........QQQQ........",
            ".........QzzzzQ.......",
            "....QQQ..QzqqzQQQ.....",
            "...QzzzQQzqqqqzzzQ....",
            "..QzqqqzzqqqqqqqqzQ...",
            "..QqqqqqqqqqqqqqqqqQ..",
            ".QQqqQqqqqqQqqqqQqqQQ."
        ),
        "marsh" to listOf(
            ".n.nnnn....nnnnn.n....",
            "......................",
            "..M......M.....M..M...",
            ".MmM..M..mM...MmM.M...",
            ".MmM.MmM.mM.M.MmM.mM..",
            "..m..MmM..m.Mm.m..m...",
            "dddmddmddddmdmddmddmdd",
            ".dddddddddddddddddddd."
        ),
        "spire" to listOf(
            ".........l............",
            "........lp............",
            "........pP....l.......",
            "...l...lpP....pP......",
            "...pP..ppPP..lpP......",
            "..lpP..ppPP..ppPP..lP.",
            "..ppPP.ppPPL.ppPP..pP.",
            ".LppPPLppPPLLppPPLLpPL"
        ),
        "storm" to listOf(
            "....sssss.sss.........",
            "..ssSSSSSsSSSss.......",
            ".sSSSSSSSSSSSSSs......",
            ".SSSSSSYSSSSSSSS......",
            "..b..b.YY.b..b........",
            ".b..b..Y.b..b.........",
            "..TTTTTTTTTTTTTTT.....",
            "..T...T...T...T.T....."
        ),
        "throne" to listOf(
            "..........Y...........",
            ".........YYY..........",
            "....h.....H.....h.....",
            "...hHh...hHh...hHh....",
            "...HHH..hhhhh..HHH....",
            "...HKH.hhKKKhh.HKH....",
            "...HHHhhhhhhhhhHHH....",
            "...HHHhhhKKKhhhHHH....",
            "...HHHhhhKkKhhhHHH...."
        ),
        "frost" to listOf(
            "..........aa..........",
            ".........aaaa.........",
            "........aaAaaa........",
            ".......aaAAbaaa.......",
            "......AaAAbbbAaa......",
            ".....AAAAbbbbbAAa.....",
            "....AAAbbbbbbbbAAA....",
            "...AAbbbbbbbbbbbbAA..."
        ),
        "coral" to listOf(
            ".......V..............",
            "......VvV...V.........",
            ".....V.t.V.VvV........",
            ".......t....t...f..j..",
            ".......t....t..fjf.fj.",
            "...f...t....t...f..j..",
            "..fjf..uuuuuuu..f..j..",
            ".uuuuuuuUUUUUuuuuuuu.."
        ),
        "starfall" to listOf(
            "....y...........y.....",
            "...yYy.....Y........y.",
            "....y.....YYY.........",
            ".........YYOYY....y...",
            ".y.........YYY........",
            "...........Y..........",
            "....OOOOOOOOOOOOOO....",
            "..OOcOOOOcOOOOOcOOOO.."
        )
    )

    private val cloud = listOf(
        "....OOOO........", "..OOOOOOOO.OOO..", ".OOOOOOOOOOOOOO.", "OOOOOOOOOOOOOOOO", "OccOOOOOOcOOOccO", ".cccccccccccccc."
    )

    private val cache = HashMap<String, Bitmap>()

    /**
     * The whole map at `scale` pixels per design point; `cleared` worlds get a gold trail, worlds past
     * `unlocked` are faded with a wisp of fog, and `current` glows.
     */
    fun bitmap(cleared: Int, unlocked: Int, current: Int, scale: Int = 2): Bitmap = cache.getOrPut("$cleared|$unlocked|$current|$scale") {
        val bitmap = Bitmap.createBitmap((WIDTH * scale).toInt(), (HEIGHT * scale).toInt(), Bitmap.Config.ARGB_8888)
        val painter = Painter(Canvas(bitmap).apply { scale(scale.toFloat(), scale.toFloat()) })
        painter.rect(0f, 0f, WIDTH, HEIGHT, 0x8ED2F2)
        painter.rect(0f, 0f, WIDTH, 250f, 0x84CBEE)
        val rng = SeededRNG(3uL)
        repeat(70) {
            val x = (rng.next() % 225uL).toFloat() * 4
            val y = (rng.next() % 155uL).toFloat() * 4
            painter.rect(x, y, listOf(8f, 12f, 16f)[(rng.next() % 3uL).toInt()], 4f, 0xFFFFFF, 0.35f)
        }
        for ((x, y) in listOf(560f to 230f, 20f to 330f, 800f to 40f)) painter.sprite(cloud, x, y, 3f, 0.65f)
        painter.trail(islands.map { it.cx to it.cy + 4 }, cleared)
        islands.forEachIndexed { index, island ->
            if (index == current) painter.ellipse(island.cx, island.cy + 6, island.rw + 24, island.rh + 16, 0xFFE98A, 0.55f)
            painter.faded = index >= unlocked
            painter.island(island)
            painter.faded = false
            if (index >= unlocked) painter.sprite(cloud, island.cx - island.rw - 6, island.cy + 4, 3f, 0.92f)
        }
        bitmap
    }

    private class Painter(val canvas: Canvas) {
        var faded = false
        private val paint = Paint().apply { isAntiAlias = false }

        fun rect(x: Float, y: Float, w: Float, h: Float, hex: Int, alpha: Float = 1f) {
            var color = hex
            if (faded) {
                // Locked worlds: mostly grey, a little lighter, so the landmark still reads.
                val r = (hex shr 16 and 0xFF).toDouble(); val g = (hex shr 8 and 0xFF).toDouble(); val b = (hex and 0xFF).toDouble()
                val grey = 0.3 * r + 0.59 * g + 0.11 * b
                fun mix(c: Double) = minOf(255, ((c * 0.3 + grey * 0.7) * 1.05 + 10).toInt())
                color = (mix(r) shl 16) or (mix(g) shl 8) or mix(b)
            }
            paint.color = color or ((alpha * 255).roundToInt() shl 24)
            canvas.drawRect(x, y, x + w, y + h, paint)
        }

        fun ellipse(cx: Float, cy: Float, rw: Float, rh: Float, hex: Int, alpha: Float = 1f, unit: Float = 4f) {
            var dy = -kotlin.math.floor(rh / unit) * unit
            while (dy <= rh) {
                val t = 1 - (dy / rh) * (dy / rh)
                if (t > 0) {
                    val half = (rw * sqrt(t) / unit).roundToInt() * unit
                    rect(cx - half, cy + dy, 2 * half, unit, hex, alpha)
                }
                dy += unit
            }
        }

        fun sprite(rows: List<String>, x: Float, y: Float, unit: Float, alpha: Float = 1f) {
            rows.forEachIndexed { r, row ->
                row.forEachIndexed { c, ch -> palette[ch]?.let { rect(x + c * unit, y + r * unit, unit, unit, it, alpha) } }
            }
        }

        fun island(island: Island) {
            val (cx, cy, rw, rh) = listOf(island.cx, island.cy, island.rw, island.rh)
            if (island.floating) {
                ellipse(cx, cy + 58, rw - 14, 8f, 0x2B2148, 0.12f)
                ellipse(cx, cy + 22, rw - 8, rh, 0xC3B1F0)
                ellipse(cx, cy + 14, rw, rh, 0xFFFFFF)
            } else {
                ellipse(cx, cy + 16, rw + 14, rh + 10, 0xFFFFFF, 0.5f)
                ellipse(cx, cy + 18, rw, rh, 0x2B2148, 0.25f)
                ellipse(cx, cy + 14, rw, rh, island.cliff)
                ellipse(cx, cy, rw + 4, rh + 2, 0xF6E3B4)
            }
            ellipse(cx, cy - 2, rw, rh, island.top)
            ellipse(cx - rw / 5, cy - rh / 2, rw / 2, rh / 3, 0xFFFFFF, 0.18f)
            landmarks[island.key]?.let { rows ->
                val unit = 6f
                val width = rows.maxOf { it.length } * unit
                sprite(rows, cx - width / 2, cy + 8 - rows.size * unit, unit)
            }
        }

        /** Square stepping stones between islands; the first `golden` legs are gold. */
        fun trail(points: List<Pair<Float, Float>>, golden: Int) {
            points.zipWithNext().forEachIndexed { leg, (a, b) ->
                val steps = (hypot(b.first - a.first, b.second - a.second) / 20).toInt()
                if (steps <= 1) return@forEachIndexed
                for (s in 1 until steps) {
                    val t = s.toFloat() / steps
                    val x = ((a.first + (b.first - a.first) * t) / 2).roundToInt() * 2f
                    val y = ((a.second + (b.second - a.second) * t) / 2).roundToInt() * 2f
                    val done = leg < golden
                    rect(x - 4, y - 2, 8f, 8f, if (done) 0xD9901A else 0xCDB98E)
                    rect(x - 4, y - 4, 8f, 6f, if (done) 0xF6C343 else 0xF6E3B4)
                }
            }
        }
    }
}
