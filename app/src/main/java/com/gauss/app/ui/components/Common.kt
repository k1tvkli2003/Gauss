package com.gauss.app.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.gauss.app.data.Difficulty
import com.gauss.app.ui.theme.GaussColors
import com.gauss.app.ui.theme.soft

/** Clickable with no ripple — used for compact custom controls. */
fun Modifier.clickableNoRipple(enabled: Boolean = true, onClick: () -> Unit): Modifier = composed {
    val source = remember { MutableInteractionSource() }
    clickable(interactionSource = source, indication = null, enabled = enabled, onClick = onClick)
}

/** A small pill showing the question difficulty with its accent colour. */
@Composable
fun DifficultyBadge(difficulty: Difficulty, modifier: Modifier = Modifier) {
    Row(
        modifier
            .clip(CircleShape)
            .background(difficulty.color.soft())
            .border(1.dp, difficulty.color, CircleShape)
            .padding(horizontal = 12.dp, vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(7.dp).clip(CircleShape).background(difficulty.color))
        Text(
            difficulty.faLabel,
            color = difficulty.color,
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(start = 6.dp),
        )
    }
}

/** Selectable chip used throughout the setup screen. */
@Composable
fun Chip(
    label: String,
    active: Boolean,
    color: Color,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    Box(
        modifier
            .clip(RoundedCornerShape(12.dp))
            .background(if (active) color.soft(0.12f) else GaussColors.Card)
            .border(
                BorderStroke(1.dp, if (active) color else GaussColors.Border),
                RoundedCornerShape(12.dp),
            )
            .clickableNoRipple(enabled, onClick)
            .padding(horizontal = 16.dp, vertical = 11.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            label,
            color = when {
                !enabled -> GaussColors.Muted
                active -> color
                else -> GaussColors.Text
            },
            fontSize = 14.sp,
            fontWeight = FontWeight.SemiBold,
        )
    }
}
