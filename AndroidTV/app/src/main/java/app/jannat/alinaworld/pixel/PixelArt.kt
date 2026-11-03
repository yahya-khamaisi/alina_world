package app.jannat.alinaworld.pixel

import android.graphics.Bitmap
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import app.jannat.alinaworld.game.WorldTheme
import app.jannat.alinaworld.game.WorldThemes

/** Turns [PixelCatalog] character maps into one-pixel-per-cell bitmaps, drawn later with nearest filtering. */
object PixelArt {
    private val bitmaps = HashMap<String, Bitmap>()
    private val images = HashMap<String, ImageBitmap>()

    fun width(sprite: PixelSprite): Int = PixelCatalog.rows(sprite).maxOf { it.length }
    fun height(sprite: PixelSprite): Int = PixelCatalog.rows(sprite).size

    fun bitmap(sprite: PixelSprite, theme: WorldTheme? = null, overrides: Map<Char, Int> = emptyMap()): Bitmap {
        val key = key(sprite, theme, overrides)
        return synchronized(bitmaps) {
            bitmaps.getOrPut(key) { render(PixelCatalog.rows(sprite), palette(theme, overrides)) }
        }
    }

    fun image(sprite: PixelSprite, theme: WorldTheme? = null, overrides: Map<Char, Int> = emptyMap()): ImageBitmap {
        val key = key(sprite, theme, overrides)
        return synchronized(images) {
            images.getOrPut(key) { bitmap(sprite, theme, overrides).asImageBitmap() }
        }
    }

    private fun palette(theme: WorldTheme?, overrides: Map<Char, Int>): Map<Char, Int> =
        PixelCatalog.basePalette + (theme ?: WorldThemes.ordered[0]).spritePalette + overrides

    private fun key(sprite: PixelSprite, theme: WorldTheme?, overrides: Map<Char, Int>): String =
        sprite.name + "|" + (theme?.key ?: "-") + "|" + overrides.entries.sortedBy { it.key }.joinToString("") { "${it.key}${it.value}" }

    private fun render(rows: List<String>, palette: Map<Char, Int>): Bitmap {
        val width = rows.maxOf { it.length }.coerceAtLeast(1)
        val height = rows.size.coerceAtLeast(1)
        val pixels = IntArray(width * height)
        rows.forEachIndexed { r, row ->
            row.forEachIndexed { c, ch ->
                palette[ch]?.let { pixels[r * width + c] = 0xFF000000.toInt() or it }
            }
        }
        return Bitmap.createBitmap(pixels, width, height, Bitmap.Config.ARGB_8888)
    }
}
