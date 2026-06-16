package com.gauss.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.gauss.app.ui.theme.GaussColors
import com.gauss.app.ui.theme.soft

private val LABELS = listOf("", "۱", "۲", "۳", "۴")

/**
 * A single answer option. In live mode it highlights the selection in blue; in
 * review mode (`reveal`) it paints the correct option green and a wrong pick red.
 */
@Composable
fun OptionButton(
    index: Int, // 1..4
    text: String,
    selected: Boolean,
    modifier: Modifier = Modifier,
    reveal: Boolean = false,
    correct: Boolean = false,
    onClick: (() -> Unit)? = null,
) {
    var borderColor: Color = GaussColors.Border
    var bg: Color = GaussColors.Card

    if (reveal) {
        if (correct) {
            borderColor = GaussColors.NeonGreen; bg = GaussColors.NeonGreen.soft(0.08f)
        } else if (selected) {
            borderColor = GaussColors.NeonRed; bg = GaussColors.NeonRed.soft(0.08f)
        }
    } else if (selected) {
        borderColor = GaussColors.NeonBlue; bg = GaussColors.NeonBlue.soft(0.08f)
    }

    val filled = selected || (reveal && correct)

    Row(
        modifier
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
                color = if (filled) GaussColors.Bg else GaussColors.Muted,
                fontWeight = FontWeight.Bold,
                fontSize = 14.sp,
            )
        }
        Box(Modifier.weight(1f)) {
            MathText(text, fontSize = 16.sp)
        }
    }
}
