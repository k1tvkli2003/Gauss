package com.gauss.app.ui.components

import android.graphics.Bitmap
import android.graphics.Canvas
import android.util.LruCache
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import ru.noties.jlatexmath.JLatexMathDrawable

/** A rendered LaTeX formula plus its intrinsic pixel size. */
class LatexImage(val bitmap: ImageBitmap, val widthPx: Int, val heightPx: Int)

/**
 * Renders LaTeX to a bitmap via JLaTeXMath — fully native, no WebView. Results
 * are cached because the same formula is drawn repeatedly across recompositions
 * and option/solution cards.
 */
object Latex {
    private val cache = object : LruCache<String, LatexImage>(256) {}

    fun render(latex: String, textSizePx: Float, colorArgb: Int): LatexImage? {
        val key = "${textSizePx.toInt()}|$colorArgb|$latex"
        cache.get(key)?.let { return it }
        return try {
            val drawable = JLatexMathDrawable.builder(latex.trim())
                .textSize(textSizePx)
                .color(colorArgb)
                .align(JLatexMathDrawable.ALIGN_LEFT)
                .build()
            val w = drawable.intrinsicWidth.coerceAtLeast(1)
            val h = drawable.intrinsicHeight.coerceAtLeast(1)
            val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            drawable.setBounds(0, 0, w, h)
            drawable.draw(Canvas(bmp))
            LatexImage(bmp.asImageBitmap(), w, h).also { cache.put(key, it) }
        } catch (_: Throwable) {
            null // unsupported formula — caller falls back to raw text
        }
    }
}
