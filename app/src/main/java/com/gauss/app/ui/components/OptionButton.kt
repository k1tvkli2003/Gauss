package com.gauss.app.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.gauss.app.ui.theme.GaussColors
import com.gauss.app.ui.theme.soft
import com.gauss.app.data.ContentBlock

private val LABELS = listOf("", "۱", "۲", "۳", "۴")

/**
 * A single answer option. In live mode it highlights the selection in blue; in
 * review mode (`reveal`) it paints the correct option green and a wrong pick red.
 */
@Composable
fun OptionButton(
    index: Int, // 1..4
    text: String,
    blocks: List<ContentBlock>? = null,
    selected: Boolean,
    modifier: Modifier = Modifier,
    reveal: Boolean = false,
    correct: Boolean = false,
    onClick: (() -> Unit)? = null,
) {
    val scheme = MaterialTheme.colorScheme
    var targetBorder: Color = scheme.outline
    var targetBg: Color = scheme.surface

    if (reveal) {
        if (correct) {
            targetBorder = GaussColors.Success; targetBg = GaussColors.Success.soft(0.10f)
        } else if (selected) {
            targetBorder = scheme.error; targetBg = scheme.error.soft(0.10f)
        }
    } else if (selected) {
        targetBorder = scheme.primary; targetBg = scheme.primaryContainer
    }
    val borderColor by animateColorAsState(targetBorder, label = "optionBorder")
    val bg by animateColorAsState(targetBg, label = "optionBackground")

    val filled = selected || (reveal && correct)

    Row(
        modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = 56.dp)
            .padding(bottom = 12.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(bg)
            .border(1.dp, borderColor, RoundedCornerShape(12.dp))
            .then(if (onClick != null && !reveal) Modifier.clickableNoRipple { onClick?.invoke() } else Modifier)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            Modifier
                .padding(end = 12.dp)
                .size(28.dp)
                .clip(CircleShape)
                .background(if (filled) borderColor else Color.Transparent)
                .border(1.dp, borderColor, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                LABELS[index],
                color = if (filled) GaussColors.BackgroundDark else scheme.onSurfaceVariant,
                fontWeight = FontWeight.Bold,
                fontSize = 14.sp,
            )
        }
        Box(Modifier.weight(1f)) {
            if (blocks != null) RichContent(blocks, fontSize = 16.sp) else MathText(text, fontSize = 16.sp)
        }
    }
}
