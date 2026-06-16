package com.gauss.app.ui.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.gauss.app.ui.theme.GaussColors

/**
 * Renders the dataset's markdown-lite + LaTeX content fully natively.
 *  - Inline math:  $ … $
 *  - Display math: $$ … $$
 *  - Markdown:     **bold**, `code`, "- " lists, "---" rules
 * RTL/Persian aware. No WebView, no HTML.
 */
@Composable
fun MathText(
    content: String,
    modifier: Modifier = Modifier,
    fontSize: TextUnit = 17.sp,
    color: Color = GaussColors.Text,
) {
    val blocks = remember(content) { splitDisplayMath(content) }
    Column(modifier = modifier.padding(horizontal = 2.dp, vertical = 2.dp)) {
        blocks.forEach { block ->
            if (block.display) {
                DisplayMath(block.value, fontSize, color)
            } else {
                TextBlock(block.value, fontSize, color)
            }
        }
    }
}

@Composable
private fun DisplayMath(tex: String, fontSize: TextUnit, color: Color) {
    val density = LocalDensity.current
    val px = with(density) { (fontSize * 1.18f).toPx() }
    val img = remember(tex, px, color) { Latex.render(tex, px, color.toArgb()) }
    if (img == null) {
        Text(tex, color = color, fontSize = fontSize)
        return
    }
    val wDp = with(density) { img.widthPx.toDp() }
    val hDp = with(density) { img.heightPx.toDp() }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
            .horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.Center,
    ) {
        Image(bitmap = img.bitmap, contentDescription = null, modifier = Modifier.size(wDp, hDp))
    }
}

private sealed interface Para {
    data class Paragraph(val text: String) : Para
    data class Bullets(val items: List<String>) : Para
    object Rule : Para
    object Gap : Para
}

private fun parseParas(text: String): List<Para> {
    val out = ArrayList<Para>()
    var bullets: ArrayList<String>? = null
    fun flush() { bullets?.let { out.add(Para.Bullets(it)); bullets = null } }
    text.split("\n").forEach { raw ->
        val t = raw.trim()
        val listMatch = Regex("^[-*]\\s+(.*)$").find(t)
        when {
            listMatch != null -> (bullets ?: ArrayList<String>().also { bullets = it })
                .add(listMatch.groupValues[1])
            t.isEmpty() -> { flush(); out.add(Para.Gap) }
            Regex("^---+$").matches(t) -> { flush(); out.add(Para.Rule) }
            else -> { flush(); out.add(Para.Paragraph(raw)) }
        }
    }
    flush()
    return out
}

@Composable
private fun TextBlock(text: String, fontSize: TextUnit, color: Color) {
    val paras = remember(text) { parseParas(text) }
    Column {
        paras.forEach { para ->
            when (para) {
                is Para.Paragraph -> Line(para.text, fontSize, color)
                is Para.Bullets -> Column {
                    para.items.forEach { item ->
                        Row(verticalAlignment = Alignment.Top) {
                            Text("•  ", color = GaussColors.NeonBlue, fontSize = fontSize)
                            Box(Modifier.weight(1f)) { Line(item, fontSize, color) }
                        }
                    }
                }
                Para.Rule -> HorizontalDivider(
                    Modifier.padding(vertical = 10.dp),
                    color = GaussColors.Border,
                )
                Para.Gap -> Spacer(Modifier.height((fontSize.value * 0.5f).dp))
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun Line(content: String, fontSize: TextUnit, color: Color) {
    val parts = remember(content) { splitInlineMath(content) }
    val density = LocalDensity.current

    // Pure-text line → a single Text for proper Persian shaping & wrapping.
    if (parts.all { !it.math }) {
        Text(
            text = inlineMarkdown(content, color),
            fontSize = fontSize,
            color = color,
            textAlign = TextAlign.Right,
            modifier = Modifier.fillMaxWidth(),
        )
        return
    }

    val px = with(density) { fontSize.toPx() }
    FlowRow(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Start,
        verticalArrangement = Arrangement.Center,
    ) {
        parts.forEach { part ->
            if (part.math) {
                val img = Latex.render(part.value, px, color.toArgb())
                if (img == null) {
                    Text(part.value, color = color, fontSize = fontSize)
                } else {
                    val wDp = with(density) { img.widthPx.toDp() }
                    val hDp = with(density) { img.heightPx.toDp() }
                    Image(
                        bitmap = img.bitmap,
                        contentDescription = null,
                        modifier = Modifier
                            .padding(horizontal = 2.dp)
                            .size(wDp, hDp),
                    )
                }
            } else {
                // Split into words so the row can reflow.
                part.value.split(Regex("(?<=\\s)|(?=\\s)")).forEach { word ->
                    if (word.isEmpty()) return@forEach
                    Text(
                        text = inlineMarkdown(word, color),
                        fontSize = fontSize,
                        color = color,
                    )
                }
            }
        }
    }
}

/* ---------------- markdown-lite (bold + code) ---------------- */

private fun inlineMarkdown(src: String, color: Color): AnnotatedString = buildAnnotatedString {
    val re = Regex("(\\*\\*[^*]+\\*\\*|`[^`]+`)")
    var last = 0
    re.findAll(src).forEach { m ->
        if (m.range.first > last) {
            withStyle(SpanStyle(color = color)) { append(src.substring(last, m.range.first)) }
        }
        val tok = m.value
        when {
            tok.startsWith("**") -> withStyle(
                SpanStyle(color = GaussColors.NeonBlue, fontWeight = FontWeight.Bold),
            ) { append(tok.substring(2, tok.length - 2)) }
            tok.startsWith("`") -> withStyle(
                SpanStyle(color = GaussColors.NeonAmber),
            ) { append(" " + tok.substring(1, tok.length - 1) + " ") }
        }
        last = m.range.last + 1
    }
    if (last < src.length) withStyle(SpanStyle(color = color)) { append(src.substring(last)) }
}

/* ---------------- parsing ---------------- */

private data class Block(val display: Boolean, val value: String)
private data class InlinePart(val math: Boolean, val value: String)

private fun splitDisplayMath(src: String): List<Block> {
    val out = ArrayList<Block>()
    val re = Regex("\\$\\$([\\s\\S]+?)\\$\\$")
    var last = 0
    re.findAll(src).forEach { m ->
        if (m.range.first > last) out.add(Block(false, src.substring(last, m.range.first)))
        out.add(Block(true, m.groupValues[1].trim()))
        last = m.range.last + 1
    }
    if (last < src.length) out.add(Block(false, src.substring(last)))
    return if (out.isEmpty()) listOf(Block(false, src)) else out
}

private fun splitInlineMath(line: String): List<InlinePart> {
    val out = ArrayList<InlinePart>()
    val re = Regex("\\$([^$]+?)\\$")
    var last = 0
    re.findAll(line).forEach { m ->
        if (m.range.first > last) out.add(InlinePart(false, line.substring(last, m.range.first)))
        out.add(InlinePart(true, m.groupValues[1].trim()))
        last = m.range.last + 1
    }
    if (last < line.length) out.add(InlinePart(false, line.substring(last)))
    return if (out.isEmpty()) listOf(InlinePart(false, line)) else out
}
